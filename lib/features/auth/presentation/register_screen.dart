import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/email_otp_service.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/auth_state.dart';

enum _UsernameCheckStatus { idle, checking, available, taken, invalid }

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const int _stepCount = 4;
  static const Duration _resendCooldown = Duration(seconds: 60);
  static const Duration _codeValidity = Duration(minutes: 10);

  final AuthRepository _authRepository = AuthRepository();
  final PageController _pageController = PageController();

  final _usernameFormKey = GlobalKey<FormState>();
  final _profileFormKey = GlobalKey<FormState>();
  final _credentialsFormKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _wilayahController = TextEditingController();
  final _codeController = TextEditingController();

  int _currentStep = 0;
  UserRole _selectedRole = UserRole.citizen;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  _UsernameCheckStatus _usernameStatus = _UsernameCheckStatus.idle;
  Timer? _usernameDebounce;
  int _usernameCheckToken = 0;

  String? _generatedCode;
  DateTime? _codeSentAt;
  bool _isSendingCode = false;
  bool _isVerifying = false;
  String? _verificationError;
  Timer? _resendTimer;
  Duration _resendRemaining = Duration.zero;

  @override
  void dispose() {
    _usernameDebounce?.cancel();
    _resendTimer?.cancel();
    _pageController.dispose();
    _usernameController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _wilayahController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _onNextPressed() async {
    switch (_currentStep) {
      case 0:
        if (!_usernameFormKey.currentState!.validate()) return;
        if (_usernameStatus != _UsernameCheckStatus.available) {
          setState(() {});
          return;
        }
        _goToStep(1);
        break;
      case 1:
        if (!_profileFormKey.currentState!.validate()) return;
        _goToStep(2);
        break;
      case 2:
        if (!_credentialsFormKey.currentState!.validate()) return;
        _goToStep(3);
        await _sendVerificationCode();
        break;
    }
  }

  void _onBackPressed() {
    if (_currentStep == 0) {
      context.pop();
      return;
    }
    _goToStep(_currentStep - 1);
  }

  void _onUsernameChanged(String value) {
    _usernameDebounce?.cancel();

    final normalized = value.trim().toLowerCase();
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

  Future<void> _sendVerificationCode() async {
    setState(() {
      _isSendingCode = true;
      _verificationError = null;
    });

    final code = EmailOtpService.instance.generateCode();
    final sentAt = DateTime.now();
    try {
      await EmailOtpService.instance.sendVerificationCode(
        toEmail: _emailController.text.trim(),
        toName: _nameController.text.trim(),
        code: code,
        expiresAt: sentAt.add(_codeValidity),
      );
      if (!mounted) return;
      setState(() {
        _generatedCode = code;
        _codeSentAt = sentAt;
        _codeController.clear();
      });
      _startResendCooldown();
    } catch (e) {
      if (!mounted) return;
      setState(() => _verificationError = 'Gagal mengirim kode verifikasi: $e');
    } finally {
      if (mounted) setState(() => _isSendingCode = false);
    }
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendRemaining = _resendCooldown);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendRemaining -= const Duration(seconds: 1);
        if (_resendRemaining <= Duration.zero) {
          _resendRemaining = Duration.zero;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _onVerifyPressed() async {
    final enteredCode = _codeController.text.trim();
    if (_generatedCode == null || _codeSentAt == null) {
      setState(
        () => _verificationError = 'Kirim kode verifikasi terlebih dahulu',
      );
      return;
    }
    if (enteredCode.isEmpty) {
      setState(
        () => _verificationError =
            'Masukkan kode verifikasi yang dikirim ke email Anda',
      );
      return;
    }
    if (DateTime.now().difference(_codeSentAt!) > _codeValidity) {
      setState(
        () => _verificationError =
            'Kode sudah kedaluwarsa, kirim ulang kode baru',
      );
      return;
    }
    if (enteredCode != _generatedCode) {
      setState(() => _verificationError = 'Kode verifikasi salah, coba lagi');
      return;
    }

    setState(() {
      _isVerifying = true;
      _verificationError = null;
    });

    context.read<AuthBloc>().add(
      AuthRegisterRequested(
        username: _usernameController.text.trim().toLowerCase(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: _selectedRole,
        wilayah: _selectedRole == UserRole.official
            ? _wilayahController.text.trim()
            : null,
        address: _addressController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Akun - Jagain'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _onBackPressed,
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go('/');
          } else if (state is AuthError) {
            setState(() => _isVerifying = false);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: List.generate(_stepCount, (index) {
                  final isActive = index <= _currentStep;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        right: index == _stepCount - 1 ? 0 : 6,
                      ),
                      height: 4,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Langkah ${_currentStep + 1} dari $_stepCount',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildUsernameStep(),
                  _buildProfileStep(),
                  _buildCredentialsStep(),
                  _buildVerificationStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepScaffold({
    required String title,
    required String subtitle,
    required Widget child,
    required Widget primaryAction,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          child,
          const SizedBox(height: 24),
          primaryAction,
        ],
      ),
    );
  }

  Widget _buildUsernameStep() {
    return _stepScaffold(
      title: 'Pilih Nama Pengguna',
      subtitle:
          'Username ini bersifat unik dan akan terlihat oleh pengguna lain.',
      child: Form(
        key: _usernameFormKey,
        child: TextFormField(
          controller: _usernameController,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: 'Nama Pengguna (Username)',
            prefixIcon: const Icon(Icons.alternate_email),
            suffixIcon: _usernameStatusIcon(),
            helperText: 'Contoh: budi_santoso',
            errorText: _usernameFieldError(),
          ),
          onChanged: _onUsernameChanged,
          validator: (val) {
            if (val == null || val.trim().isEmpty)
              return 'Username wajib diisi';
            return null;
          },
        ),
      ),
      primaryAction: ElevatedButton(
        onPressed: _onNextPressed,
        child: const Text('Lanjut'),
      ),
    );
  }

  Widget _buildProfileStep() {
    return _stepScaffold(
      title: 'Data Diri',
      subtitle: 'Lengkapi informasi diri Anda.',
      child: Form(
        key: _profileFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap',
                prefixIcon: Icon(Icons.person_outlined),
              ),
              validator: (val) => (val == null || val.trim().isEmpty)
                  ? 'Nama wajib diisi'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Alamat',
                prefixIcon: Icon(Icons.home_outlined),
              ),
              validator: (val) => (val == null || val.trim().isEmpty)
                  ? 'Alamat wajib diisi'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor Telepon',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty)
                  return 'Nomor telepon wajib diisi';
                if (!RegExp(r'^[0-9+\-\s]{8,15}$').hasMatch(val.trim())) {
                  return 'Format nomor telepon tidak valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<UserRole>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Daftar sebagai',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              items: const [
                DropdownMenuItem(value: UserRole.citizen, child: Text('Warga')),
                DropdownMenuItem(
                  value: UserRole.official,
                  child: Text('Pejabat'),
                ),
              ],
              onChanged: (val) =>
                  setState(() => _selectedRole = val ?? UserRole.citizen),
            ),
            if (_selectedRole == UserRole.official) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _wilayahController,
                decoration: const InputDecoration(
                  labelText: 'Wilayah Kerja (contoh: Surabaya)',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (val) =>
                    (_selectedRole == UserRole.official &&
                        (val == null || val.trim().isEmpty))
                    ? 'Wilayah wajib diisi untuk pejabat'
                    : null,
              ),
            ],
          ],
        ),
      ),
      primaryAction: ElevatedButton(
        onPressed: _onNextPressed,
        child: const Text('Lanjut'),
      ),
    );
  }

  Widget _buildCredentialsStep() {
    return _stepScaffold(
      title: 'Email & Kata Sandi',
      subtitle:
          'Email ini akan dipakai untuk masuk dan menerima kode verifikasi.',
      child: Form(
        key: _credentialsFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty)
                  return 'Email wajib diisi';
                if (!RegExp(
                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                ).hasMatch(val.trim())) {
                  return 'Format email tidak valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Password wajib diisi';
                if (val.length < 6) return 'Password minimal 6 karakter';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              decoration: InputDecoration(
                labelText: 'Ulangi Password',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                  onPressed: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                ),
              ),
              validator: (val) {
                if (val == null || val.isEmpty)
                  return 'Konfirmasi password wajib diisi';
                if (val != _passwordController.text)
                  return 'Password tidak sama';
                return null;
              },
            ),
          ],
        ),
      ),
      primaryAction: ElevatedButton(
        onPressed: _onNextPressed,
        child: const Text('Lanjut'),
      ),
    );
  }

  Widget _buildVerificationStep() {
    final email = _emailController.text.trim();
    final hasSentCode = _generatedCode != null;
    final canResend = _resendRemaining == Duration.zero && !_isSendingCode;

    return _stepScaffold(
      title: 'Verifikasi Email',
      subtitle: hasSentCode
          ? 'Kami telah mengirim kode 6-digit ke $email. Masukkan kode tersebut untuk menyelesaikan pendaftaran.'
          : 'Kami akan mengirim kode verifikasi 6-digit ke $email.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasSentCode) ...[
            TextFormField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Kode Verifikasi',
                prefixIcon: Icon(Icons.password_outlined),
                counterText: '',
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: canResend ? _sendVerificationCode : null,
                child: Text(
                  canResend
                      ? 'Kirim ulang kode'
                      : 'Kirim ulang dalam ${_resendRemaining.inSeconds}d',
                ),
              ),
            ),
          ],
          if (_verificationError != null) ...[
            const SizedBox(height: 8),
            Text(
              _verificationError!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
        ],
      ),
      primaryAction: hasSentCode
          ? BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final isLoading = _isVerifying || state is AuthLoading;
                return ElevatedButton(
                  onPressed: isLoading ? null : _onVerifyPressed,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verifikasi & Daftar'),
                );
              },
            )
          : ElevatedButton(
              onPressed: _isSendingCode ? null : _sendVerificationCode,
              child: _isSendingCode
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Kirim Kode Verifikasi'),
            ),
    );
  }
}
