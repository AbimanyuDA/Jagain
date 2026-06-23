import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../data/auth_repository.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../../core/services/notification_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;
  StreamSubscription? _authSubscription;

  AuthBloc({required AuthRepository repository})
    : _repository = repository,
      super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthUserRefreshed>(_onAuthUserRefreshed);
    on<AuthSwitchAccountRequested>(_onAuthSwitchAccountRequested);
    on<AuthUpgradeToOfficialRequested>(_onUpgradeToOfficial);
  }

  void _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    await emit.forEach(
      _repository.authStateChanges,
      onData: (user) {
        if (user == null) return AuthUnauthenticated();
        SessionManager.addSession(user);
        return AuthAuthenticated(user: user);
      },
      onError: (_, _) => AuthUnauthenticated(),
    );
  }

  void _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _repository.signIn(
        identifier: event.email,
        password: event.password,
      );
      // Simpan email asli hasil resolve (event.email bisa berupa username),
      // bukan apa yang diketik user, supaya switch akun berikutnya benar.
      await SessionManager.addSession(
        user,
        email: user.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user: user));
      // Simpan FCM token setelah login berhasil
      await NotificationService.instance.saveTokenToFirestore(user.uid);
    } catch (e) {
      emit(const AuthError('Email/username atau password salah.'));
    }
  }

  void _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _repository.register(
        username: event.username,
        name: event.name,
        email: event.email,
        password: event.password,
        role: event.role,
        wilayah: event.wilayah,
        address: event.address,
        phoneNumber: event.phoneNumber,
      );
      await SessionManager.addSession(
        user,
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(user: user));
      // Simpan FCM token setelah register berhasil
      await NotificationService.instance.saveTokenToFirestore(user.uid);
    } catch (e) {
      emit(
        const AuthError(
          'Pendaftaran gagal. Periksa koneksi internet Anda dan coba lagi.',
        ),
      );
    }
  }

  void _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _repository.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void _onUpgradeToOfficial(
    AuthUpgradeToOfficialRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;

    emit(AuthLoading());
    try {
      final updatedUser = await _repository.requestUpgradeToOfficial(
        uid: currentState.user.uid,
        wilayah: event.wilayah,
      );
      emit(AuthAuthenticated(user: updatedUser));
    } catch (e) {
      // Kembalikan state sebelumnya + emit error
      emit(AuthAuthenticated(user: currentState.user));
      emit(AuthError(e.toString()));
    }
  }

  void _onAuthUserRefreshed(
    AuthUserRefreshed event,
    Emitter<AuthState> emit,
  ) async {
    await SessionManager.addSession(event.user);
    emit(AuthAuthenticated(user: event.user));
  }

  void _onAuthSwitchAccountRequested(
    AuthSwitchAccountRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      emit(AuthSwitching(previousUser: currentState.user));
    } else {
      emit(AuthLoading());
    }
    try {
      final sessions = await SessionManager.getSessions();
      final session = sessions.firstWhere((s) => s['uid'] == event.uid);
      final email = session['email'];
      // Coba secure storage dulu; fallback ke field 'password' lama di JSON
      // (format sebelum migrasi ke secure storage) supaya akun yang sudah
      // tersimpan sebelum perbaikan ini tidak tiba-tiba kehilangan akses.
      final password =
          await SessionManager.getPassword(event.uid) ??
          session['password'] as String?;

      if (email != null && password != null) {
        final user = await _repository.signIn(
          identifier: email,
          password: password,
        );
        await SessionManager.addSession(user, email: email, password: password);
        emit(AuthAuthenticated(user: user));
      } else {
        emit(
          const AuthError(
            'Kredensial sesi tidak ditemukan untuk login otomatis.',
          ),
        );
        _restorePreviousUser(currentState, emit);
      }
    } catch (e) {
      emit(AuthError('Gagal berganti akun: ${e.toString()}'));
      _restorePreviousUser(currentState, emit);
    }
  }

  /// Setelah switch akun gagal, kembalikan bloc ke state semula (akun yang
  /// sedang aktif sebelum switch dicoba) supaya UI tidak "menggantung" di
  /// AuthError dan router tidak menganggap user logout.
  void _restorePreviousUser(AuthState previousState, Emitter<AuthState> emit) {
    if (previousState is AuthAuthenticated) {
      emit(AuthAuthenticated(user: previousState.user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
