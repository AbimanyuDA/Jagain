import 'package:equatable/equatable.dart';

enum UserRole { citizen, official, admin }

abstract class AuthState extends Equatable {
  const AuthState();
  
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String userId;
  final String email;
  final UserRole role;

  const AuthAuthenticated({
    required this.userId,
    required this.email,
    required this.role,
  });

  @override
  List<Object?> get props => [userId, email, role];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
