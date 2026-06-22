import 'package:equatable/equatable.dart';

import '../../../feed/domain/models/report_post.dart';

typedef KotaResolutionStat = ({
  String kota,
  int totalReports,
  double resolvedRate,
});

typedef MonthlyReportCount = ({DateTime month, int count});

abstract class StatsState extends Equatable {
  const StatsState();

  @override
  List<Object?> get props => [];
}

class StatsInitial extends StatsState {}

class StatsLoading extends StatsState {}

class StatsLoaded extends StatsState {
  final String? provinsi;
  final String? kota;
  final Map<ReportPostStatus, int> statusCounts;
  final int stuckCount;
  final List<KotaResolutionStat> topKota;
  final List<MonthlyReportCount> monthlyTrend;
  final Map<String, int> categoryCounts;
  final Map<String, int>? cityCounts;

  const StatsLoaded({
    required this.statusCounts,
    required this.stuckCount,
    required this.topKota,
    required this.monthlyTrend,
    this.categoryCounts = const {},
    this.cityCounts,
    this.provinsi,
    this.kota,
  });

  String get regionLabel {
    if (kota != null && provinsi != null) return '$kota, $provinsi';
    if (provinsi != null) return provinsi!;
    return 'Seluruh Indonesia';
  }

  int get total => statusCounts.values.fold<int>(0, (sum, v) => sum + v);

  int get resolved => statusCounts[ReportPostStatus.solved] ?? 0;

  int get activeCount =>
      (statusCounts[ReportPostStatus.waitingReview] ?? 0) +
      (statusCounts[ReportPostStatus.inProgress] ?? 0);

  double get completionRate {
    if (total == 0) return 0;
    return resolved / total;
  }

  double get apatisRate => total == 0 ? 0 : stuckCount / total;

  double get responsifRate => 1 - apatisRate;

  @override
  List<Object?> get props => [
    provinsi,
    kota,
    statusCounts,
    stuckCount,
    topKota,
    monthlyTrend,
    categoryCounts,
    cityCounts,
  ];
}

class StatsError extends StatsState {
  final String message;

  const StatsError(this.message);

  @override
  List<Object?> get props => [message];
}
