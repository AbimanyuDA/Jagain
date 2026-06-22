import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/indonesia_regions.dart';
import '../../../feed/data/report_repository.dart';
import '../../../stats/presentation/bloc/stats_state.dart';
import '../../data/pejabat_dashboard_repository.dart';
import 'pejabat_dashboard_event.dart';
import 'pejabat_dashboard_state.dart';

class PejabatDashboardBloc
    extends Bloc<PejabatDashboardEvent, PejabatDashboardState> {
  static const int kTrendMonths = 6;

  PejabatDashboardBloc({
    PejabatDashboardRepository? repository,
    ReportRepository? reportRepository,
  })  : _repository = repository ?? PejabatDashboardRepository(),
        _reportRepository = reportRepository ?? ReportRepository(),
        super(PejabatDashboardInitial()) {
    on<LoadDashboardStats>(_onLoadStats);
  }

  final PejabatDashboardRepository _repository;
  final ReportRepository _reportRepository;

  Future<void> _onLoadStats(
    LoadDashboardStats event,
    Emitter<PejabatDashboardState> emit,
  ) async {
    emit(PejabatDashboardLoading());
    try {
      final parsed = _repository.parseWilayah(event.pejabatWilayah);

      final results = await Future.wait([
        _repository.loadStats(
          event.pejabatWilayah,
          currentUserId: event.currentUserId,
        ),
        _loadMonthlyTrend(parsed.provinsi, parsed.kota),
        if (parsed.level == 'provinsi')
          _repository.getTopResolutionKota(parsed.provinsi!)
        else
          Future.value(const <KotaResolutionStat>[]),
      ]);

      final stats = results[0] as DashboardStats;
      final monthlyTrend = results[1] as List<MonthlyReportCount>;
      final topKota = results[2] as List<KotaResolutionStat>;

      emit(PejabatDashboardLoaded(
        statusCounts: stats.statusCounts,
        stuckCount: stats.stuckCount,
        topStuckReports: stats.topStuckReports,
        categoryCounts: stats.categoryCounts,
        cityCounts: stats.cityCounts,
        monthlyTrend: monthlyTrend,
        topKota: topKota,
      ));
    } catch (e) {
      emit(PejabatDashboardError(e.toString()));
    }
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
