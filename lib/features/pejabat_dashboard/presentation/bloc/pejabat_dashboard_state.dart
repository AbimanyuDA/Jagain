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
  final Map<ReportPostStatus, int> statusCounts;
  final int stuckCount;
  final List<ReportPost> topStuckReports;

  const PejabatDashboardLoaded({
    required this.statusCounts,
    required this.stuckCount,
    required this.topStuckReports,
  });

  int get activeCount =>
      (statusCounts[ReportPostStatus.waitingReview] ?? 0) +
      (statusCounts[ReportPostStatus.inProgress] ?? 0);

  @override
  List<Object?> get props => [statusCounts, stuckCount, topStuckReports];
}

class PejabatDashboardError extends PejabatDashboardState {
  final String message;

  const PejabatDashboardError(this.message);

  @override
  List<Object?> get props => [message];
}