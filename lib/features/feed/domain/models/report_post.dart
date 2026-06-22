import '../../../../core/utils/time_ago.dart';

enum ReportPostStatus { waitingReview, inProgress, solved, rejected }

extension ReportPostStatusX on ReportPostStatus {
  String get key {
    switch (this) {
      case ReportPostStatus.waitingReview:
        return 'waiting_review';
      case ReportPostStatus.inProgress:
        return 'in_progress';
      case ReportPostStatus.solved:
        return 'solved';
      case ReportPostStatus.rejected:
        return 'rejected';
    }
  }

  String get label {
    switch (this) {
      case ReportPostStatus.waitingReview:
        return 'Menunggu Review';
      case ReportPostStatus.inProgress:
        return 'Diproses';
      case ReportPostStatus.solved:
        return 'Selesai';
      case ReportPostStatus.rejected:
        return 'Ditolak';
    }
  }

  static ReportPostStatus fromKey(String? key) {
    switch (key) {
      case 'in_progress':
        return ReportPostStatus.inProgress;
      case 'solved':
        return ReportPostStatus.solved;
      case 'rejected':
        return ReportPostStatus.rejected;
      case 'waiting_review':
      default:
        return ReportPostStatus.waitingReview;
    }
  }
}

class ReportPost {
  final String id;
  final String authorId;
  final String userName;
  final String userAvatarUrl;
  final String userBadge;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String title;
  final String description;
  final String imageUrl;
  final List<String>? imageUrls;
  final String category;
  final String urgency;
  final ReportPostStatus status;
  final String wilayah;
  final int upvotes;
  final int updatesCount;
  final int repliesCount;
  final bool isUpvoted;
  final bool isDownvoted;

  // Location coordinates for validation feature
  final double? latitude;
  final double? longitude;

  const ReportPost({
    required this.id,
    required this.authorId,
    required this.userName,
    required this.userAvatarUrl,
    required this.userBadge,
    required this.createdAt,
    required this.updatedAt,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.imageUrls,
    required this.category,
    required this.urgency,
    this.status = ReportPostStatus.waitingReview,
    this.wilayah = '',
    required this.upvotes,
    required this.updatesCount,
    required this.repliesCount,
    this.isUpvoted = false,
    this.isDownvoted = false,
    this.latitude,
    this.longitude,
  });

  String get timeAgo => timeAgoText(createdAt);

  ReportPost copyWith({
    int? upvotes,
    bool? isUpvoted,
    bool? isDownvoted,
    int? repliesCount,
  }) {
    return ReportPost(
      id: id,
      authorId: authorId,
      userName: userName,
      userAvatarUrl: userAvatarUrl,
      userBadge: userBadge,
      createdAt: createdAt,
      updatedAt: updatedAt,
      title: title,
      description: description,
      imageUrl: imageUrl,
      imageUrls: imageUrls,
      category: category,
      urgency: urgency,
      status: status,
      wilayah: wilayah,
      upvotes: upvotes ?? this.upvotes,
      updatesCount: updatesCount,
      repliesCount: repliesCount ?? this.repliesCount,
      isUpvoted: isUpvoted ?? this.isUpvoted,
      isDownvoted: isDownvoted ?? this.isDownvoted,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
