import 'package:equatable/equatable.dart';

import '../../../feed/domain/models/report_post.dart';

abstract class PejabatDashboardState extends Equatable {
  const PejabatDashboardState();

  @override
  List<Object?> get props => [];
}

class PejabatDashboardInitial extends PejabatDashboardState {}

class PejabatDashboardLoading extends PejabatDashboardState {}

class PejabatDashboardLoaded extends PejabatDashboardState {
  final List<ReportPost> topStuckReports;

  const PejabatDashboardLoaded({
    required this.topStuckReports,
  });

  @override
  List<Object?> get props => [topStuckReports];
}

class PejabatDashboardError extends PejabatDashboardState {
  final String message;

  const PejabatDashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
