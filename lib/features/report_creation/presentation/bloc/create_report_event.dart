import 'dart:io';

import 'package:equatable/equatable.dart';

import '../../../auth/domain/user_model.dart';

abstract class CreateReportEvent extends Equatable {
  const CreateReportEvent();

  @override
  List<Object?> get props => [];
}

class SubmitReportRequested extends CreateReportEvent {
  final UserModel author;
  final String title;
  final String description;
  final String category;
  final String urgency;
  final List<File> images;
  final double latitude;
  final double longitude;
  final String wilayah;
  final String provinsi;

  const SubmitReportRequested({
    required this.author,
    required this.title,
    required this.description,
    required this.category,
    required this.urgency,
    required this.images,
    required this.latitude,
    required this.longitude,
    required this.wilayah,
    required this.provinsi,
  });

  @override
  List<Object?> get props => [
    author,
    title,
    description,
    category,
    urgency,
    images,
    latitude,
    longitude,
    wilayah,
    provinsi,
  ];
}
