import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../data/auth_repository.dart';

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
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void _onAuthRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await _repository.register(
        name: event.name,
        username: event.username,
        email: event.email,
        password: event.password,
        role: event.role,
        wilayah: event.wilayah,
      );
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

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }
}
