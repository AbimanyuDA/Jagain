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
  final String? parentCommentId;
  final int replyCount;

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
    this.parentCommentId,
    this.replyCount = 0,
  });

  String get timeAgo => timeAgoText(createdAt);
  int get likeCount => likedBy.length;
  bool get isReply => parentCommentId != null;
  bool isLikedBy(String? userId) => userId != null && likedBy.contains(userId);
}
