import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum UserRole { citizen, official, admin }

class UserModel extends Equatable {
  final String uid;
  final String name;
  final String username;
  final String email;
  final UserRole role;
  final String? wilayah;
  final String? domicile;
  final String? address;
  final String? phoneNumber;
  final String avatarUrl;
  final bool isVerified;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.username,
    required this.email,
    required this.role,
    this.wilayah,
    this.domicile,
    this.address,
    this.phoneNumber,
    this.avatarUrl = '',
    required this.isVerified,
    required this.createdAt,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      username: map['username'] ?? uid,
      email: map['email'],
      role: UserRole.values.byName(map['role'] ?? 'citizen'),
      wilayah: map['wilayah'],
      domicile: map['domicile'],
      address: map['address'],
      phoneNumber: map['phoneNumber'],
      avatarUrl: map['avatarUrl'] ?? '',
      isVerified: map['isVerified'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'username': username,
      'email': email,
      'role': role.name,
      'wilayah': wilayah,
      'domicile': domicile,
      'address': address,
      'phoneNumber': phoneNumber,
      'avatarUrl': avatarUrl,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  UserModel copyWith({
    String? name,
    String? username,
    String? wilayah,
    String? domicile,
    String? address,
    String? phoneNumber,
    String? avatarUrl,
    bool? isVerified,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      username: username ?? this.username,
      email: email,
      role: role,
      wilayah: wilayah ?? this.wilayah,
      domicile: domicile ?? this.domicile,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    name,
    username,
    email,
    role,
    wilayah,
    domicile,
    address,
    phoneNumber,
    avatarUrl,
    isVerified,
    createdAt,
  ];
}
