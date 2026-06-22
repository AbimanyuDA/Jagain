import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/data/indonesia_regions.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../../../core/utils/image_compressor.dart';
import 'bloc/create_report_bloc.dart';
import 'bloc/create_report_event.dart';
import 'bloc/create_report_state.dart';
import '../../admin_panel/data/admin_repository.dart';

const _fallbackCategories = ['JALAN', 'PJU', 'DRAINASE', 'TROTOAR', 'POHON', 'LAINNYA'];
const _urgencyLevels = ['NORMAL', 'URGENT'];
const _defaultLocation = LatLng(-6.2088, 106.8456);

class CreateReportScreen extends StatelessWidget {
  const CreateReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CreateReportBloc(),
      child: const _CreateReportView(),
    );
  }
}

class _CreateReportView extends StatefulWidget {
  const _CreateReportView();

  @override
  State<_CreateReportView> createState() => _CreateReportViewState();
}

class _CreateReportViewState extends State<_CreateReportView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _wilayahController = TextEditingController();
  final _provinsiController = TextEditingController();
  final _picker = ImagePicker();

  final List<File> _images = [];
  List<String> _categories = _fallbackCategories;
  String _category = _fallbackCategories.first;
  String _urgency = _urgencyLevels.first;

  LatLng? _selectedLocation;
  Timer? _debounceTimer;
  bool _isLocating = false;
  bool _isCompressing = false;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final repo = AdminRepository();
      repo.watchCategories().first.then((items) {
        final active = items
            .where((c) => c.isActive)
            .map((c) => c.name)
            .toList();
        if (active.isNotEmpty && mounted) {
          setState(() {
            _categories = active;
            _category = active.first;
          });
        }
      });
    } catch (_) {
      // TODO: fallback if firesstore failed
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _wilayahController.dispose();
    _provinsiController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await showModalBottomSheet<XFile?>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Ambil Foto dari Kamera'),
              onTap: () async {
                final file = await _picker.pickImage(
                  source: ImageSource.camera,
                );
                if (sheetContext.mounted) Navigator.of(sheetContext).pop(file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari Galeri'),
              onTap: () async {
                final file = await _picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (sheetContext.mounted) Navigator.of(sheetContext).pop(file);
              },
            ),
          ],
        ),
      ),
    );

    if (picked != null) {
      setState(() => _isCompressing = true);
      try {
        final compressed = await ImageCompressor.compress(File(picked.path));
        if (mounted) setState(() => _images.add(compressed));
      } finally {
        if (mounted) setState(() => _isCompressing = false);
      }
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Layanan lokasi (GPS) tidak aktif.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak secara permanen.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLocation = latLng;
        _isLocating = false;
      });

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: latLng, zoom: 15)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mendapatkan lokasi: $e')));
      }
      setState(() {
        _selectedLocation = _defaultLocation;
        _isLocating = false;
      });
    }
  }

  Future<Map<String, String?>> _reverseGeocode(double lat, double lng) async {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    final client = HttpClient();
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey&language=id',
      );
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = json.decode(responseBody);
        if (data['status'] == 'OK' &&
            data['results'] != null &&
            data['results'].isNotEmpty) {
            final components = data['results'][0]['address_components'] as List;
            final wilayahComponent = components.firstWhere(
              (c) => (c['types'] as List).contains('administrative_area_level_2'),
              orElse: () => null,
            );
            final provinsiComponent = components.firstWhere(
              (c) => (c['types'] as List).contains('administrative_area_level_1'),
              orElse: () => null,
            );
          return {
            'address': data['results'][0]['formatted_address'] as String?,
            'wilayah': wilayahComponent?['long_name'] as String?,
            'provinsi': provinsiComponent?['long_name'] as String?,
          };
        }
      }
    } catch (e) {
      debugPrint('Error performing reverse geocoding: $e');
    } finally {
      client.close();
    }
    return {'address': null, 'wilayah': null, 'provinsi': null};
  }

  Future<void> _confirmLocation() async {
    if (_selectedLocation == null) return;
    setState(() => _isLocating = true);

    final result = await _reverseGeocode(
      _selectedLocation!.latitude,
      _selectedLocation!.longitude,
    );

    setState(() {
      _addressController.text = result['address'] ?? '';
      final rawWilayah = result['wilayah'] ?? '';
      _wilayahController.text = rawWilayah.isNotEmpty
          ? IndonesiaRegions.normalizeGmapsWilayah(rawWilayah)
          : '';
      _provinsiController.text = result['provinsi'] ?? '';
      _isLocating = false;
    });
  }

  // FOR FUTURE USE! save map as image for reducing API call
  // Future<File?> _takeMapSnapshot() async {
  //   if (_mapController == null) return null;
  //   final snapshot = await _mapController!.takeSnapshot();
  //   if (snapshot == null) return null;
  //   final tempDir = await Directory.systemTemp.createTemp();
  //   final file = File('${tempDir.path}/map_snapshot.png');
  //   await file.writeAsBytes(snapshot);
  //   return file;
  // }

  void _submit(UserModel author) {
    if (!_formKey.currentState!.validate()) return;

    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal satu foto kerusakan.')),
      );
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tentukan lokasi kerusakan terlebih dahulu.'),
        ),
      );
      return;
    }

    if (_wilayahController.text.isEmpty || _provinsiController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wilayah belum terdeteksi. Geser peta dan coba lagi.'),
        ),
      );
      return;
    }

    // final snapshotFile = await _takeMapSnapshot();
    // if (snapshotFile != null) {
    //   setState(() {
    //     _images.removeWhere((f) => f.path.contains('map_snapshot'));
    //     _images.insert(0, snapshotFile);
    //   });
    // }

    context.read<CreateReportBloc>().add(
      SubmitReportRequested(
        author: author,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        urgency: _urgency,
        images: _images,
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        wilayah: _wilayahController.text.trim(),
        provinsi: _provinsiController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final author = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Laporan Baru')),
      body: BlocConsumer<CreateReportBloc, CreateReportState>(
        listener: (context, state) {
          if (state is CreateReportSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Laporan berhasil dikirim! Menunggu review.'),
              ),
            );
            context.pop();
          } else if (state is CreateReportError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final isSubmitting = state is CreateReportSubmitting;

          return AbsorbPointer(
            absorbing: isSubmitting,
            child: Opacity(
              opacity: isSubmitting ? 0.6 : 1,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTitleField(),
                        const SizedBox(height: 16),
                        _buildDescriptionField(),
                        const SizedBox(height: 16),
                        _buildCategoryDropdown(),
                        const SizedBox(height: 16),
                        _buildUrgencySegmented(),
                        const SizedBox(height: 16),
                        _buildImagePicker(),
                        const SizedBox(height: 16),
                        _buildLocationPicker(),
                        const SizedBox(height: 32),

                        ElevatedButton(
                          onPressed: author == null ? null : () => _submit(author),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Kirim Laporan'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitleField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Judul Laporan',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            hintText: 'Judul Laporan',
            border: OutlineInputBorder(),
          ),
          validator: (val) => (val == null || val.trim().isEmpty)
              ? 'Judul wajib diisi'
              : null,
        ),
      ]
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Deskripsi Kerusakan',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            hintText: 'Deskripsi Kerusakan',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 4,
          validator: (val) => (val == null || val.trim().isEmpty)
              ? 'Deskripsi wajib diisi'
              : null,
        ),
      ]
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategori',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _category,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: _categories
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(c),
                ),
              )
              .toList(),
          onChanged: (val) =>
              setState(() => _category = val ?? _category),
        ),
      ]
    );
  }

  Widget _buildUrgencySegmented() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Urgensi',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          expandedInsets: EdgeInsets.zero,
          segments: const [
            ButtonSegment(value: 'NORMAL', label: Text('Normal')),
            ButtonSegment(value: 'URGENT', label: Text('Urgent')),
          ],
          selected: {_urgency},
          onSelectionChanged: (val) => setState(() => _urgency = val.first),
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.selected)) {
                return Theme.of(context).colorScheme.primary;
              }
              return null;
            }),
            foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.white;
              }
              return null;
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Foto Kerusakan',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ..._images.asMap().entries.map((entry) {
                final index = entry.key;
                final file = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          file,
                          width: 100,
                          height: 110,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.black54,
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (_isCompressing)
                Container(
                  width: 100,
                  height: 110,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Mengoptimasi...',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              GestureDetector(
                onTap: _isCompressing ? null : _pickImages,
                child: Opacity(
                  opacity: _isCompressing ? 0.5 : 1.0,
                  child: Container(
                    width: 100,
                    height: 110,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, color: Colors.grey),
                        SizedBox(height: 6),
                        Text(
                          'Tambah Foto',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lokasi Kejadian',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              Container(
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _selectedLocation == null
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _selectedLocation!,
                          zoom: 17,
                        ),
                        onMapCreated: (controller) => _mapController = controller,
                        onCameraMove: (position) {
                          setState(() {
                            _selectedLocation = position.target;
                            _addressController.text = '';
                            _wilayahController.text = '';
                            _provinsiController.text = '';
                          });
                          _debounceTimer?.cancel();
                          _debounceTimer = Timer(const Duration(milliseconds: 800), () {
                            _confirmLocation();
                          });
                        },
                        gestureRecognizers: {
                          Factory<OneSequenceGestureRecognizer>(
                            () => EagerGestureRecognizer(),
                          ),
                        },
                      ),
                      Center(
                        child: Transform.translate(
                          offset: const Offset(0, -24),
                          child: Icon(
                            Icons.location_pin,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      if (_isLocating)
                        const Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(),
                        ),
                    ],
                  ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _addressController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Alamat',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _wilayahController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Wilayah',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _provinsiController,
          readOnly: true,
          decoration: const InputDecoration(
            labelText: 'Provinsi',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}
