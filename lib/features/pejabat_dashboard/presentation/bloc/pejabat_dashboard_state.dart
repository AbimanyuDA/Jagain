import 'package:equatable/equatable.dart';

import '../../../feed/domain/models/report_post.dart';
import '../../../stats/presentation/bloc/stats_state.dart';

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
  final Map<String, int> categoryCounts;
  final Map<String, int>? cityCounts;
  final List<MonthlyReportCount> monthlyTrend;
  final List<KotaResolutionStat> topKota;

  const PejabatDashboardLoaded({
    required this.statusCounts,
    required this.stuckCount,
    required this.topStuckReports,
    required this.categoryCounts,
    this.cityCounts,
    this.monthlyTrend = const [],
    this.topKota = const [],
  });

  int get total => statusCounts.values.fold<int>(0, (sum, v) => sum + v);

  int get activeCount =>
      (statusCounts[ReportPostStatus.waitingReview] ?? 0) +
      (statusCounts[ReportPostStatus.inProgress] ?? 0);

  double get completionRate {
    if (total == 0) return 0;
    return (statusCounts[ReportPostStatus.solved] ?? 0) / total;
  }

  double get apatisRate => total == 0 ? 0 : stuckCount / total;

  double get responsifRate => 1 - apatisRate;

  @override
  List<Object?> get props =>
      [statusCounts, stuckCount, topStuckReports, categoryCounts, cityCounts, monthlyTrend, topKota];
}

class PejabatDashboardError extends PejabatDashboardState {
  final String message;

  const PejabatDashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
