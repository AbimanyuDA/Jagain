
/// Represents a status update entry in the report's timeline.
class ReportUpdate {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final bool isDone; // true = step completed, false = pending/future step

  const ReportUpdate({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.isDone = true,
  });

  String get timeFormatted {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inDays == 0) {
      return 'Hari ini, ${_padZero(createdAt.hour)}:${_padZero(createdAt.minute)}';
    }
    return '${createdAt.day} ${_monthName(createdAt.month)} ${createdAt.year}';
  }

  String _padZero(int n) => n.toString().padLeft(2, '0');

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return months[month];
  }

  factory ReportUpdate.fromMap(String id, Map<String, dynamic> data) {
    return ReportUpdate(
      id: id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      isDone: data['isDone'] as bool? ?? true,
    );
  }
}
