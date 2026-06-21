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
  final String username;
  final String name;
  final String email;
  final String password;
  final UserRole role;
  final String? wilayah;
  final String? address;
  final String? phoneNumber;

  const AuthRegisterRequested({
    required this.username,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.wilayah,
    this.address,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [
    username,
    name,
    email,
    password,
    role,
    wilayah,
    address,
    phoneNumber,
  ];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthUserRefreshed extends AuthEvent {
  final UserModel user;

  const AuthUserRefreshed(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthSwitchAccountRequested extends AuthEvent {
  final String uid;

  const AuthSwitchAccountRequested(this.uid);

  @override
  List<Object?> get props => [uid];
}

class AuthUpgradeToOfficialRequested extends AuthEvent {
  final String wilayah;

  const AuthUpgradeToOfficialRequested({
    required this.wilayah,
  });

  @override
  List<Object?> get props => [wilayah];
}
