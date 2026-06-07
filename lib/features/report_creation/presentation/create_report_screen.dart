import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/domain/user_model.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import 'bloc/create_report_bloc.dart';
import 'bloc/create_report_event.dart';
import 'bloc/create_report_state.dart';

const _categories = ['JALAN', 'PJU', 'DRAINASE', 'TROTOAR', 'POHON', 'LAINNYA'];
const _urgencyLevels = ['NORMAL', 'URGENT'];

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
  final _wilayahController = TextEditingController();
  final _picker = ImagePicker();

  final List<File> _images = [];
  String _category = _categories.first;
  String _urgency = _urgencyLevels.first;

  Position? _position;
  bool _isFetchingLocation = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _wilayahController.dispose();
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

  Future<void> _detectLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        throw Exception(
          'Izin lokasi ditolak. Aktifkan izin lokasi di pengaturan.',
        );
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Layanan lokasi (GPS) tidak aktif.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() => _position = position);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mendapatkan lokasi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
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

    if (_position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tentukan lokasi kerusakan terlebih dahulu.'),
        ),
      );
      return;
    }

    context.read<CreateReportBloc>().add(
      SubmitReportRequested(
        author: author,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        urgency: _urgency,
        images: _images,
        latitude: _position!.latitude,
        longitude: _position!.longitude,
        wilayah: _wilayahController.text.trim(),
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
                      TextFormField(
                        controller: _wilayahController,
                        decoration: const InputDecoration(
                          labelText: 'Wilayah / Kota (contoh: Surabaya)',
                          helperText:
                              'Dipakai untuk meneruskan laporan ke pejabat wilayah terkait',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => (val == null || val.trim().isEmpty)
                            ? 'Wilayah wajib diisi'
                            : null,
                      ),
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

  Widget _buildLocationPicker() {
    return ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      leading: const Icon(Icons.location_on, color: Colors.red),
      title: Text(
        _position == null
            ? 'Pilih Lokasi Kerusakan'
            : 'Lokasi: ${_position!.latitude.toStringAsFixed(5)}, ${_position!.longitude.toStringAsFixed(5)}',
      ),
      subtitle: Text(
        _position == null
            ? 'Tekan untuk mengambil koordinat GPS Anda saat ini'
            : 'Koordinat GPS berhasil diambil',
      ),
      trailing: _isFetchingLocation
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.my_location),
      onTap: _isFetchingLocation ? null : _detectLocation,
    );
  }
}
