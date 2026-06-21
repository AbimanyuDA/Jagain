import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/storage/minio_storage_service.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/domain/user_model.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_event.dart';
import '../../auth/presentation/bloc/auth_state.dart';

enum _UsernameCheckStatus { idle, checking, available, taken, invalid }

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _picker = ImagePicker();
  final _authRepository = AuthRepository();

  UserModel? _currentUser;
  String _originalUsername = '';
  File? _avatarFile;
  _UsernameCheckStatus _usernameStatus = _UsernameCheckStatus.idle;
  Timer? _usernameDebounce;
  int _usernameCheckToken = 0;
  bool _isSaving = false;
  bool _isLoadingUser = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final authState = context.read<AuthBloc>().state;
    UserModel? user = authState is AuthAuthenticated ? authState.user : null;

    if (user == null) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        user = await _authRepository.getUser(uid);
      }
    }

    if (!mounted) return;

    if (user == null) {
      setState(() {
        _isLoadingUser = false;
        _loadError = 'Gagal memuat data profil. Coba lagi nanti.';
      });
      return;
    }

    setState(() {
      _currentUser = user;
      _originalUsername = user!.username;
      _nameController.text = user.name;
      _usernameController.text = user.username;
      _usernameStatus = _UsernameCheckStatus.available;
      _isLoadingUser = false;
    });
  }

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    _usernameDebounce?.cancel();

    final normalized = value.trim().toLowerCase();
    if (normalized == _originalUsername) {
      setState(() => _usernameStatus = _UsernameCheckStatus.available);
      return;
    }
    if (normalized.isEmpty) {
      setState(() => _usernameStatus = _UsernameCheckStatus.idle);
      return;
    }
    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(normalized)) {
      setState(() => _usernameStatus = _UsernameCheckStatus.invalid);
      return;
    }

    setState(() => _usernameStatus = _UsernameCheckStatus.checking);

    final token = ++_usernameCheckToken;
    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      final isAvailable = await _authRepository.isUsernameAvailable(normalized);
      if (!mounted || token != _usernameCheckToken) return;
      setState(() {
        _usernameStatus = isAvailable
            ? _UsernameCheckStatus.available
            : _UsernameCheckStatus.taken;
      });
    });
  }

  String? _usernameFieldError() {
    switch (_usernameStatus) {
      case _UsernameCheckStatus.invalid:
        return 'Gunakan 3-20 huruf kecil, angka, atau garis bawah (_)';
      case _UsernameCheckStatus.taken:
        return 'Username sudah dipakai, coba yang lain';
      default:
        return null;
    }
  }

  Widget? _usernameStatusIcon() {
    switch (_usernameStatus) {
      case _UsernameCheckStatus.checking:
        return const SizedBox(
          height: 18,
          width: 18,
          child: Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case _UsernameCheckStatus.available:
        return const Icon(Icons.check_circle, color: Colors.green);
      case _UsernameCheckStatus.taken:
      case _UsernameCheckStatus.invalid:
        return const Icon(Icons.cancel, color: Colors.redAccent);
      case _UsernameCheckStatus.idle:
        return null;
    }
  }

  Future<void> _pickAvatar() async {
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
                  maxWidth: 720,
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
                  maxWidth: 720,
                );
                if (sheetContext.mounted) Navigator.of(sheetContext).pop(file);
              },
            ),
          ],
        ),
      ),
    );

    if (picked != null) {
      setState(() => _avatarFile = File(picked.path));
    }
  }

  Future<void> _onSavePressed() async {
    final user = _currentUser;
    if (user == null) return;
    if (!_formKey.currentState!.validate()) return;
    if (_usernameStatus != _UsernameCheckStatus.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Periksa kembali username Anda.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      String? avatarUrl;
      if (_avatarFile != null) {
        avatarUrl = await MinioStorageService.instance.uploadImage(
          file: _avatarFile!,
          folder: MinioFolder.avatars,
          ownerId: user.uid,
        );
      }

      final newName = _nameController.text.trim();
      final newUsername = _usernameController.text.trim().toLowerCase();

      final updatedUser = await _authRepository.updateProfile(
        uid: user.uid,
        name: newName != user.name ? newName : null,
        username: newUsername != _originalUsername ? newUsername : null,
        avatarUrl: avatarUrl,
      );

      if (!mounted) return;

      context.read<AuthBloc>().add(AuthUserRefreshed(updatedUser));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui profil: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profil')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final user = _currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profil')),
        body: Center(
          child: Text(_loadError ?? 'Gagal memuat data profil.'),
        ),
      );
    }

    final avatarImage = _avatarFile != null
        ? FileImage(_avatarFile!) as ImageProvider
        : (user.avatarUrl.isNotEmpty
            ? CachedNetworkImageProvider(user.avatarUrl)
            : null);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: avatarImage,
                    child: avatarImage == null
                        ? const Icon(Icons.person, size: 48, color: Colors.grey)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickAvatar,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2E5BFF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _usernameController,
              onChanged: _onUsernameChanged,
              decoration: InputDecoration(
                labelText: 'Username',
                prefixText: '@',
                border: const OutlineInputBorder(),
                suffixIcon: _usernameStatusIcon(),
                errorText: _usernameFieldError(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Username tidak boleh kosong';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _onSavePressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F1E36),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Simpan Perubahan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
