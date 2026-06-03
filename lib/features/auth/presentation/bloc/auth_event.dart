import 'package:equatable/equatable.dart';
import '../../domain/user_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final UserRole role;
  final String? wilayah;

  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.wilayah,
  });

  @override
  List<Object?> get props => [name, email, password, role, wilayah];
}

class AuthLogoutRequested extends AuthEvent {}
