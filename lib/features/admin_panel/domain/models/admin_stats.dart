class AdminStats {
  final int totalUsers;
  final int totalReports;
  final int reportsSolved;
  final int reportsPendingModeration;
  final int pendingOfficialVerifications;

  const AdminStats({
    required this.totalUsers,
    required this.totalReports,
    required this.reportsSolved,
    required this.reportsPendingModeration,
    required this.pendingOfficialVerifications,
  });
}
