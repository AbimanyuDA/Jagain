class ReportPost {
  final String id;
  final String userName;
  final String userAvatarUrl;
  final String userBadge; // e.g., "Verified", "Citizen Reporter"
  final String timeAgo;
  final String title;
  final String description;
  final String imageUrl;
  final List<String>? imageUrls; // List of image URLs for carousel
  final String category; // e.g., "JALAN", "PJU"
  final String urgency; // e.g., "URGENT", "NORMAL"
  final int upvotes;
  final int updatesCount;
  final int repliesCount;
  final bool isUpvoted;
  final bool isDownvoted;

  const ReportPost({
    required this.id,
    required this.userName,
    required this.userAvatarUrl,
    required this.userBadge,
    required this.timeAgo,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.imageUrls,
    required this.category,
    required this.urgency,
    required this.upvotes,
    required this.updatesCount,
    required this.repliesCount,
    this.isUpvoted = false,
    this.isDownvoted = false,
  });

  ReportPost copyWith({
    int? upvotes,
    bool? isUpvoted,
    bool? isDownvoted,
  }) {
    return ReportPost(
      id: id,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      userBadge: userBadge,
      timeAgo: timeAgo,
      title: title,
      description: description,
      imageUrl: imageUrl,
      imageUrls: imageUrls,
      category: category,
      urgency: urgency,
      upvotes: upvotes ?? this.upvotes,
      updatesCount: updatesCount,
      repliesCount: repliesCount,
      isUpvoted: isUpvoted ?? this.isUpvoted,
      isDownvoted: isDownvoted ?? this.isDownvoted,
    );
  }
}
