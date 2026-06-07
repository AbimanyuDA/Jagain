import '../../../../core/utils/time_ago.dart';

class Comment {
  final String id;
  final String authorId;
  final String authorUsername;
  final String authorName;
  final String authorAvatarUrl;
  final String text;
  final bool isPinned;
  final bool isOfficial;
  final DateTime createdAt;
  final List<String> likedBy;

  const Comment({
    required this.id,
    required this.authorId,
    required this.authorUsername,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.text,
    required this.isPinned,
    required this.isOfficial,
    required this.createdAt,
    required this.likedBy,
  });

  String get timeAgo => timeAgoText(createdAt);
  int get likeCount => likedBy.length;
  bool isLikedBy(String? userId) => userId != null && likedBy.contains(userId);
}
