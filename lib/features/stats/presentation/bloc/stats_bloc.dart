import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/indonesia_regions.dart';
import '../../../feed/data/report_repository.dart';
import '../../../feed/domain/models/report_post.dart';
import '../../../pejabat_dashboard/data/pejabat_dashboard_repository.dart';
import 'stats_event.dart';
import 'stats_state.dart';

class StatsBloc extends Bloc<StatsEvent, StatsState> {
  static const int kTrendMonths = 6;

  StatsBloc({
    PejabatDashboardRepository? dashboardRepository,
    ReportRepository? reportRepository,
  }) : _dashboardRepository = dashboardRepository ?? PejabatDashboardRepository(),
       _reportRepository = reportRepository ?? ReportRepository(),
       super(StatsInitial()) {
    on<LoadStats>(_onLoadStats);
  }

  final PejabatDashboardRepository _dashboardRepository;
  final ReportRepository _reportRepository;

  Future<void> _onLoadStats(LoadStats event, Emitter<StatsState> emit) async {
    emit(StatsLoading());
    try {
      final wilayahString = _buildWilayahString(event.provinsi, event.kota);

      final results = await Future.wait([
        _dashboardRepository.loadStats(wilayahString),
        if (event.provinsi != null && event.kota == null)
          _dashboardRepository.getTopResolutionKota(event.provinsi!)
        else
          Future.value(const <KotaResolutionStat>[]),
        _loadMonthlyTrend(event.provinsi, event.kota),
      ]);

      final stats = results[0]
          as ({
            Map<ReportPostStatus, int> statusCounts,
            int stuckCount,
            List<ReportPost> topStuckReports,
          });
      final topKota = results[1] as List<KotaResolutionStat>;
      final monthlyTrend = results[2] as List<MonthlyReportCount>;

      emit(
        StatsLoaded(
          provinsi: event.provinsi,
          kota: event.kota,
          statusCounts: stats.statusCounts,
          stuckCount: stats.stuckCount,
          topKota: topKota,
          monthlyTrend: monthlyTrend,
        ),
      );
    } catch (e) {
      emit(StatsError('Gagal memuat statistik: $e'));
    }
  }

  String _buildWilayahString(String? provinsi, String? kota) {
    if (kota != null && provinsi != null) return '$kota -> $provinsi -> Pusat';
    if (provinsi != null) return provinsi;
    return '';
  }

  Future<List<MonthlyReportCount>> _loadMonthlyTrend(
    String? provinsi,
    String? kota,
  ) async {
    final now = DateTime.now();
    final months = List.generate(kTrendMonths, (i) {
      final shifted = DateTime(now.year, now.month - (kTrendMonths - 1 - i));
      return DateTime(shifted.year, shifted.month);
    });
    final since = months.first;

    final reports = await _reportRepository.getReportsSince(since);

    final kotaFilter = kota != null
        ? {kota}
        : provinsi != null
        ? IndonesiaRegions.getKota(provinsi).toSet()
        : null;

    final filtered = kotaFilter == null
        ? reports
        : reports.where((r) => kotaFilter.contains(r.wilayah)).toList();

    final counts = {for (final m in months) m: 0};
    for (final report in filtered) {
      final bucket = DateTime(report.createdAt.year, report.createdAt.month);
      if (counts.containsKey(bucket)) {
        counts[bucket] = counts[bucket]! + 1;
      }
    }

    return months.map((m) => (month: m, count: counts[m] ?? 0)).toList();
  }
}
