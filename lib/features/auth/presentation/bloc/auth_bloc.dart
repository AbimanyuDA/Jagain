import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
  }

  void _onAuthCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    // TODO: Implement actual Firebase Auth persistence check
    await Future.delayed(const Duration(milliseconds: 500));
    emit(AuthUnauthenticated()); // Default for now
  }

  void _onAuthLoginRequested(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // TODO: Implement actual Firebase Sign In & fetch role from Firestore
      await Future.delayed(const Duration(seconds: 1));
      
      // Temporary stub for demonstration
      if (event.email.contains('admin')) {
        emit(AuthAuthenticated(
          userId: 'admin_123',
          email: event.email,
          role: UserRole.admin,
        ));
      } else if (event.email.contains('pejabat')) {
        emit(AuthAuthenticated(
          userId: 'pejabat_123',
          email: event.email,
          role: UserRole.official,
        ));
      } else {
        emit(AuthAuthenticated(
          userId: 'user_123',
          email: event.email,
          role: UserRole.citizen,
        ));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  void _onAuthLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    // TODO: Implement actual Firebase Sign Out
    await Future.delayed(const Duration(milliseconds: 500));
    emit(AuthUnauthenticated());
  }
}
