import '../../../core/data/indonesia_regions.dart';
import '../../feed/domain/models/report_post.dart';
import '../../feed/data/report_repository.dart';

class DashboardStats {
  final Map<ReportPostStatus, int> statusCounts;
  final int stuckCount;
  final List<ReportPost> topStuckReports;
  final Map<String, int> categoryCounts;
  final Map<String, int>? cityCounts;

  const DashboardStats({
    required this.statusCounts,
    required this.stuckCount,
    required this.topStuckReports,
    required this.categoryCounts,
    this.cityCounts,
  });
}

class PejabatDashboardRepository {
  PejabatDashboardRepository({
    ReportRepository? reportRepository,
  }) : _reportRepository = reportRepository ?? ReportRepository();

  final ReportRepository _reportRepository;

  ({String level, String? provinsi, String? kota}) parseWilayah(
      String wilayah) {
    final parts = wilayah.split(' -> ');
    switch (parts.length) {
      case >= 3:
        return (level: 'kota', provinsi: parts[1], kota: parts[0]);
      case 2:
        return (level: 'provinsi', provinsi: parts[0], kota: null);
      default:
        return (level: 'pusat', provinsi: null, kota: null);
    }
  }

  DashboardStats _computeStats(
    List<ReportPost> reports, {
    bool groupByCity = false,
  }) {
    final statusCounts = {for (final s in ReportPostStatus.values) s: 0};
    final categoryCounts = <String, int>{};
    final cityCountsMap = <String, int>{};
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final stuckReports = <ReportPost>[];

    for (final report in reports) {
      statusCounts[report.status] = statusCounts[report.status]! + 1;
      categoryCounts[report.category] =
          (categoryCounts[report.category] ?? 0) + 1;
      if (groupByCity) {
        cityCountsMap[report.wilayah] =
            (cityCountsMap[report.wilayah] ?? 0) + 1;
      }

      final isOpen = report.status == ReportPostStatus.waitingReview ||
          report.status == ReportPostStatus.inProgress;
      if (isOpen && report.updatedAt.isBefore(cutoff)) {
        stuckReports.add(report);
      }
    }

    stuckReports.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return DashboardStats(
      statusCounts: statusCounts,
      stuckCount: stuckReports.length,
      topStuckReports: stuckReports.take(5).toList(),
      categoryCounts: categoryCounts,
      cityCounts: groupByCity ? cityCountsMap : null,
    );
  }

  // --- Legacy methods kept for stats_bloc compatibility ---

  Future<Map<ReportPostStatus, int>> getStatusCounts(String wilayah) async {
    final results = await Future.wait(
      ReportPostStatus.values.map(
        (s) => _reportRepository.countByStatusAndWilayah(s, wilayah),
      ),
    );
    return {
      for (var i = 0; i < ReportPostStatus.values.length; i++)
        ReportPostStatus.values[i]: results[i],
    };
  }

  Future<List<({String kota, int totalReports, double resolvedRate})>>
      getTopResolutionKota(String provinsi, {int limit = 4}) async {
    final cities = IndonesiaRegions.getKota(provinsi);
    final results = await Future.wait(cities.map((kota) async {
      final counts = await getStatusCounts(kota);
      final total = counts.values.fold<int>(0, (sum, v) => sum + v);
      final resolved = counts[ReportPostStatus.solved] ?? 0;
      final rate = total == 0 ? 0.0 : resolved / total;
      return (kota: kota, totalReports: total, resolvedRate: rate);
    }));

    final withData = results.where((r) => r.totalReports > 0).toList()
      ..sort((a, b) => b.resolvedRate.compareTo(a.resolvedRate));
    return withData.take(limit).toList();
  }

  // --- End legacy methods ---

  Future<DashboardStats> loadStats(
    String pejabatWilayah, {
    String? currentUserId,
  }) async {
    final parsed = parseWilayah(pejabatWilayah);

    final List<ReportPost> reports;
    if (parsed.level == 'kota') {
      reports = await _reportRepository.getReportsByWilayah(
        parsed.kota!,
        currentUserId: currentUserId,
      );
    } else if (parsed.level == 'provinsi') {
      final cities = IndonesiaRegions.getKota(parsed.provinsi!).toSet();
      final all = await _reportRepository.getAllReports(
        currentUserId: currentUserId,
      );
      reports = all.where((r) => cities.contains(r.wilayah)).toList();
      return _computeStats(reports, groupByCity: true);
    } else {
      reports = await _reportRepository.getAllReports(
        currentUserId: currentUserId,
      );
    }

    return _computeStats(reports);
  }
}
