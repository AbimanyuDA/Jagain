import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum UserRole { citizen, official, admin }

class UserModel extends Equatable {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? wilayah;
  final bool isVerified;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.wilayah,
    required this.isVerified,
    required this.createdAt,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'],
      role: UserRole.values.byName(map['role'] ?? 'citizen'),
      wilayah: map['wilayah'],
      isVerified: map['isVerified'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role.name,
      'wilayah': wilayah,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  @override
  List<Object?> get props => [uid, name, email, role, wilayah, isVerified, createdAt];
}