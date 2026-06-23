import '../../feed/domain/models/report_post.dart';
import '../../feed/data/report_repository.dart';

typedef RegionResolutionStat = ({
  String name,
  int totalReports,
  double resolvedRate,
});

typedef MonthlyReportCount = ({DateTime month, int count});

class StatsResult {
  final Map<ReportPostStatus, int> statusCounts;
  final int stuckCount;
  final Map<String, int> categoryCounts;
  final Map<String, int>? regionCounts;
  final List<RegionResolutionStat> topResolution;
  final List<MonthlyReportCount> monthlyTrend;

  const StatsResult({
    required this.statusCounts,
    required this.stuckCount,
    required this.categoryCounts,
    this.regionCounts,
    this.topResolution = const [],
    this.monthlyTrend = const [],
  });
}

class StatsRepository {
  static const int kTrendMonths = 6;

  StatsRepository({
    ReportRepository? reportRepository,
  }) : _reportRepository = reportRepository ?? ReportRepository();

  final ReportRepository _reportRepository;

  ({
    Map<String, int> categoryCounts,
    Map<String, int>? regionCounts,
    List<RegionResolutionStat> topResolution,
    List<MonthlyReportCount> monthlyTrend,
  }) _computeStats(
    List<ReportPost> reports, {
    required String level,
  }) {
    final categoryCounts = <String, int>{};
    final regionCountsMap = <String, int>{};
    final regionSolvedMap = <String, int>{};

    final now = DateTime.now();
    final months = List.generate(kTrendMonths, (i) {
      final shifted = DateTime(now.year, now.month - (kTrendMonths - 1 - i));
      return DateTime(shifted.year, shifted.month);
    });
    final monthlyCounts = {for (final m in months) m: 0};

    for (final report in reports) {
      categoryCounts[report.category] =
          (categoryCounts[report.category] ?? 0) + 1;

      if (level == 'pusat' && report.provinsi.isNotEmpty) {
        regionCountsMap[report.provinsi] =
            (regionCountsMap[report.provinsi] ?? 0) + 1;
        if (report.status == ReportPostStatus.solved) {
          regionSolvedMap[report.provinsi] =
              (regionSolvedMap[report.provinsi] ?? 0) + 1;
        }
      } else if (level == 'provinsi' && report.wilayah.isNotEmpty) {
        regionCountsMap[report.wilayah] =
            (regionCountsMap[report.wilayah] ?? 0) + 1;
        if (report.status == ReportPostStatus.solved) {
          regionSolvedMap[report.wilayah] =
              (regionSolvedMap[report.wilayah] ?? 0) + 1;
        }
      }

      final bucket = DateTime(report.createdAt.year, report.createdAt.month);
      if (monthlyCounts.containsKey(bucket)) {
        monthlyCounts[bucket] = monthlyCounts[bucket]! + 1;
      }
    }

    List<RegionResolutionStat> topResolution = const [];
    if (level != 'kota' && regionCountsMap.isNotEmpty) {
      final stats = regionCountsMap.entries.map((e) {
        final total = e.value;
        final solved = regionSolvedMap[e.key] ?? 0;
        return (
          name: e.key,
          totalReports: total,
          resolvedRate: total == 0 ? 0.0 : solved / total,
        );
      }).where((r) => r.totalReports > 0).toList()
        ..sort((a, b) => b.resolvedRate.compareTo(a.resolvedRate));
      topResolution = stats.take(4).toList();
    }

    return (
      categoryCounts: categoryCounts,
      regionCounts: level != 'kota' ? regionCountsMap : null,
      topResolution: topResolution,
      monthlyTrend:
          months.map((m) => (month: m, count: monthlyCounts[m] ?? 0)).toList(),
    );
  }

  Future<StatsResult> loadStats({
    String? provinsi,
    String? wilayah,
    String? currentUserId,
  }) async {
    final String level;
    if (wilayah != null) {
      level = 'kota';
    } else if (provinsi != null) {
      level = 'provinsi';
    } else {
      level = 'pusat';
    }

    final results = await Future.wait([
      ...ReportPostStatus.values.map(
        (s) => _reportRepository.countByStatus(
          s,
          provinsi: provinsi,
          wilayah: wilayah,
        ),
      ),
      _reportRepository.countStuck(provinsi: provinsi, wilayah: wilayah),
      _reportRepository.getReports(
        provinsi: provinsi,
        wilayah: wilayah,
        currentUserId: currentUserId,
      ),
    ]);

    final statusCounts = {
      for (var i = 0; i < ReportPostStatus.values.length; i++)
        ReportPostStatus.values[i]: results[i] as int,
    };
    final stuckCount = results[ReportPostStatus.values.length] as int;
    final reports =
        results[ReportPostStatus.values.length + 1] as List<ReportPost>;

    final computed = _computeStats(reports, level: level);

    return StatsResult(
      statusCounts: statusCounts,
      stuckCount: stuckCount,
      categoryCounts: computed.categoryCounts,
      regionCounts: computed.regionCounts,
      topResolution: computed.topResolution,
      monthlyTrend: computed.monthlyTrend,
    );
  }
}
