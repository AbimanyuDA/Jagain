import '../../../core/data/indonesia_regions.dart';
import '../../feed/domain/models/report_post.dart';
import '../../feed/data/report_repository.dart';

class PejabatDashboardRepository {
  PejabatDashboardRepository({
    ReportRepository? reportRepository,
  }) : _reportRepository = reportRepository ?? ReportRepository();

  final ReportRepository _reportRepository;

  // Parses pejabat wilayah string "Kota Surabaya -> Jawa Timur -> Pusat"
  // into level and region components.
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

  // FR-1.2: city-level
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

  // FR-1.2: province-level
  Future<Map<ReportPostStatus, int>> getStatusCountsByProvinsi(
      String provinsi) async {
    final cities = IndonesiaRegions.getKota(provinsi);
    final cityResults = await Future.wait(
      cities.map((city) => getStatusCounts(city)),
    );
    final totals = {for (final s in ReportPostStatus.values) s: 0};
    for (final cityCount in cityResults) {
      for (final s in ReportPostStatus.values) {
        totals[s] = totals[s]! + (cityCount[s] ?? 0);
      }
    }
    return totals;
  }

  // FR-1.3: city-level
  Future<({int count, List<ReportPost> topReports})> getStuckReports(
    String wilayah, {String? currentUserId}
  ) async {
    final results = await Future.wait([
      _reportRepository.countStuckByWilayah(wilayah),
      _reportRepository.getStuckByWilayah(wilayah, currentUserId: currentUserId),
    ]);
    return (count: results[0] as int, topReports: results[1] as List<ReportPost>);
  }

  // FR-1.3: province-level
  Future<({int count, List<ReportPost> topReports})> getStuckReportsByProvinsi(
    String provinsi, {String? currentUserId}
  ) async {
    final cities = IndonesiaRegions.getKota(provinsi);
    final cityResults = await Future.wait(
      cities.map((c) => getStuckReports(c, currentUserId: currentUserId)),
    );
    final totalCount = cityResults.fold<int>(0, (sum, r) => sum + r.count);
    final allReports = cityResults.expand((r) => r.topReports).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return (count: totalCount, topReports: allReports.take(5).toList());
  }

  // FR-1.2: pusat-level (no wilayah filter)
  Future<Map<ReportPostStatus, int>> getStatusCountsAll() async {
    final results = await Future.wait(
      ReportPostStatus.values.map(
        (s) => _reportRepository.countByStatus(s),
      ),
    );
    return {
      for (var i = 0; i < ReportPostStatus.values.length; i++)
        ReportPostStatus.values[i]: results[i],
    };
  }

  // FR-1.3: pusat-level (no wilayah filter)
  Future<({int count, List<ReportPost> topReports})> getStuckReportsAll({
    String? currentUserId,
  }) async {
    final results = await Future.wait([
      _reportRepository.countStuck(),
      _reportRepository.getStuck(currentUserId: currentUserId),
    ]);
    return (count: results[0] as int, topReports: results[1] as List<ReportPost>);
  }

  /// Ranking kota di sebuah provinsi berdasarkan tingkat penyelesaian laporan.
  /// Kota tanpa laporan sama sekali tidak dimasukkan ke ranking.
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

  /// Loads FR-1.2 + FR-1.3 data based on pejabat's wilayah.
  Future<({
    Map<ReportPostStatus, int> statusCounts,
    int stuckCount,
    List<ReportPost> topStuckReports,
  })> loadStats(String pejabatWilayah, {String? currentUserId}) async {
    final parsed = parseWilayah(pejabatWilayah);

    final Map<ReportPostStatus, int> statusCounts;
    final ({int count, List<ReportPost> topReports}) stuck;

    if (parsed.level == 'kota') {
      final results = await Future.wait([
        getStatusCounts(parsed.kota!),
        getStuckReports(parsed.kota!, currentUserId: currentUserId),
      ]);
      statusCounts = results[0] as Map<ReportPostStatus, int>;
      stuck = results[1] as ({int count, List<ReportPost> topReports});
    } else if (parsed.level == 'provinsi') {
      final results = await Future.wait([
        getStatusCountsByProvinsi(parsed.provinsi!),
        getStuckReportsByProvinsi(parsed.provinsi!, currentUserId: currentUserId),
      ]);
      statusCounts = results[0] as Map<ReportPostStatus, int>;
      stuck = results[1] as ({int count, List<ReportPost> topReports});
    } else {
      statusCounts = await getStatusCountsAll();
      stuck = await getStuckReportsAll(currentUserId: currentUserId);
    }

    return (
      statusCounts: statusCounts,
      stuckCount: stuck.count,
      topStuckReports: stuck.topReports,
    );
  }
}