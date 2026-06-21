import 'package:equatable/equatable.dart';

abstract class PejabatDashboardEvent extends Equatable {
  const PejabatDashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboardStats extends PejabatDashboardEvent {
  final String pejabatWilayah;
  final String? currentUserId;

  const LoadDashboardStats({
    required this.pejabatWilayah,
    this.currentUserId,
  });

  @override
  List<Object?> get props => [pejabatWilayah, currentUserId];
}