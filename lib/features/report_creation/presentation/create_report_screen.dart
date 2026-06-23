import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/domain/user_model.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import 'bloc/create_report_bloc.dart';
import 'bloc/create_report_event.dart';
import 'bloc/create_report_state.dart';
import '../../admin_panel/data/admin_repository.dart';
import '../../../core/data/indonesia_regions.dart';
import '../../../core/widgets/region_selector_bottom_sheet.dart';

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
  final _picker = ImagePicker();

  final List<File> _images = [];
  List<String> _categories = _fallbackCategories;
  String _category = _fallbackCategories.first;
  String _urgency = _urgencyLevels.first;

  // Wilayah region selector state
  String? _selectedProvinsi;
  String? _selectedKota;

  LatLng? _selectedLocation;
  String? _confirmedAddress;
  bool _isLocating = false;
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
      // Gunakan fallback hardcoded jika Firestore gagal
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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
                  imageQuality: 80,
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
                  imageQuality: 80,
                );
                if (sheetContext.mounted) Navigator.of(sheetContext).pop(file);
              },
            ),
          ],
        ),
      ),
    );

    if (picked != null) {
      setState(() => _images.add(File(picked.path)));
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

  Future<String> _reverseGeocode(double lat, double lng) async {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
    final client = HttpClient();
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey',
      );
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = json.decode(responseBody);
        if (data['status'] == 'OK' &&
            data['results'] != null &&
            data['results'].isNotEmpty) {
          return data['results'][0]['formatted_address'] as String;
        }
      }
    } catch (e) {
      debugPrint('Error performing reverse geocoding: $e');
    } finally {
      client.close();
    }
    return 'Gagal mendapatkan alamat.';
  }

  Future<void> _confirmLocation() async {
    if (_selectedLocation == null) return;
    setState(() => _isLocating = true);
    final address = await _reverseGeocode(
      _selectedLocation!.latitude,
      _selectedLocation!.longitude,
    );
    setState(() {
      _confirmedAddress = address;
      _isLocating = false;
    });
  }

  Future<void> _pickProvinsi() async {
    final result = await showRegionSelectorSheet(
      context: context,
      title: 'Pilih Provinsi',
      items: IndonesiaRegions.provinsi,
      selected: _selectedProvinsi,
    );
    if (result != null) {
      setState(() {
        _selectedProvinsi = result;
        _selectedKota = null;
      });
    }
  }

  Future<void> _pickKota() async {
    if (_selectedProvinsi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih provinsi terlebih dahulu')),
      );
      return;
    }
    final kota = IndonesiaRegions.getKota(_selectedProvinsi!);
    final result = await showRegionSelectorSheet(
      context: context,
      title: 'Pilih Kota / Kabupaten',
      items: kota,
      selected: _selectedKota,
    );
    if (result != null) {
      setState(() => _selectedKota = result);
    }
  }

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

    if (_selectedKota == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih kota / kabupaten laporan terlebih dahulu.'),
        ),
      );
      return;
    }

    // Format: "Kota Surabaya -> Jawa Timur -> Pusat"
    final wilayah = '${_selectedKota!} -> ${_selectedProvinsi!} -> Pusat';

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
        wilayah: wilayah,
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildImagePicker(),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Judul Laporan',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Judul wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi Kerusakan',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Deskripsi wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _category,
                              decoration: const InputDecoration(
                                labelText: 'Kategori',
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
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _urgency,
                              decoration: const InputDecoration(
                                labelText: 'Urgensi',
                                border: OutlineInputBorder(),
                              ),
                              items: _urgencyLevels
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _urgency = val ?? _urgency),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildWilayahSelector(),
                      const SizedBox(height: 16),
                      _buildLocationPicker(),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: author == null
                            ? null
                            : () => _submit(author),
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
          );
        },
      ),
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
              GestureDetector(
                onTap: _pickImages,
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWilayahSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Wilayah Laporan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 4),
        Text(
          'Dipakai untuk meneruskan laporan ke pejabat wilayah terkait',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 10),

        // Provinsi
        const Text(
          'Provinsi',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        _buildRegionTile(
          icon: Icons.map_outlined,
          label: _selectedProvinsi ?? 'Pilih Provinsi',
          isPlaceholder: _selectedProvinsi == null,
          onTap: _pickProvinsi,
        ),

        const SizedBox(height: 12),

        // Kota / Kabupaten
        const Text(
          'Kota / Kabupaten',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 6),
        _buildRegionTile(
          icon: Icons.location_city_outlined,
          label: _selectedKota ?? 'Pilih Kota / Kabupaten',
          isPlaceholder: _selectedKota == null,
          onTap: _pickKota,
          disabled: _selectedProvinsi == null,
        ),

        // Preview
        if (_selectedKota != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border.all(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.route, color: Colors.blue.shade700, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_selectedKota!} → ${_selectedProvinsi!} → Pusat',
                    style: TextStyle(
                        fontSize: 12, color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRegionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPlaceholder = false,
    bool disabled = false,
  }) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: disabled
                ? Colors.grey.shade300
                : isPlaceholder
                    ? Colors.grey.shade400
                    : const Color(0xFF1B3564),
          ),
          borderRadius: BorderRadius.circular(8),
          color: disabled ? Colors.grey.shade100 : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: disabled
                  ? Colors.grey.shade400
                  : isPlaceholder
                      ? Colors.grey.shade500
                      : const Color(0xFF1B3564),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: disabled
                      ? Colors.grey.shade400
                      : isPlaceholder
                          ? Colors.grey.shade500
                          : Colors.black87,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down,
                color: disabled
                    ? Colors.grey.shade400
                    : Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lokasi Kejadian',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          height: 250,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: _selectedLocation == null
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _selectedLocation!,
                        zoom: 15,
                      ),
                      onMapCreated: (controller) => _mapController = controller,
                      markers: {
                        Marker(
                          markerId: const MarkerId('pinpoint'),
                          position: _selectedLocation!,
                          draggable: true,
                          onDragEnd: (newPosition) {
                            setState(() {
                              _selectedLocation = newPosition;
                              _confirmedAddress = null;
                            });
                          },
                        ),
                      },
                      onTap: (latLng) {
                        setState(() {
                          _selectedLocation = latLng;
                          _confirmedAddress = null;
                        });
                      },
                    ),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: ElevatedButton.icon(
                        onPressed: _isLocating ? null : _confirmLocation,
                        icon: const Icon(Icons.gps_fixed, size: 18),
                        label: const Text('Konfirmasi Lokasi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: const Color(0xFF1B3564),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        if (_confirmedAddress != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border.all(color: Colors.blue.shade100),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: Color(0xFF1B3564)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _confirmedAddress!,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
