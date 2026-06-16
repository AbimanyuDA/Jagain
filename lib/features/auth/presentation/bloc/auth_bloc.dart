import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../data/auth_repository.dart';
import '../../../../core/utils/session_manager.dart';

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
        email: event.email,
        password: event.password,
      );
      await SessionManager.addSession(user, email: event.email, password: event.password);
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(const AuthError('Email atau password salah.'));
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
      await SessionManager.addSession(user, email: event.email, password: event.password);
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(e.toString()));
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

  void _onAuthUserRefreshed(AuthUserRefreshed event, Emitter<AuthState> emit) async {
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
      final password = session['password'];
      
      if (email != null && password != null) {
        final user = await _repository.signIn(email: email, password: password);
        await SessionManager.addSession(user, email: email, password: password);
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthError('Kredensial sesi tidak ditemukan untuk login otomatis.'));
      }
    } catch (e) {
      emit(AuthError('Gagal berganti akun: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
