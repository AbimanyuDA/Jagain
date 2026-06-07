// Domain model for User Profile feature
// Handles credibility, gamification, and civic contribution data

class UserProfile {
  final String id;
  final String username;       // e.g. 'abimanyudans' (no spaces)
  final String displayName;   // e.g. 'Budi Santoso'
  final String avatarUrl;
  final String domicile;
  final bool isVerifiedCitizen; // NIK verified
  final String gamificationTitle; // e.g. "Pahlawan Aspal"
  final int civicPoints;
  final int reportsSolved;
  final int upvotesGiven;
  final int totalReports;
  final int followersCount;
  final int followingCount;
  final List<UserReport> myReports;
  final List<SupportedReport> supportedReports;
  final List<Badge> badges;
  final int availablePointsForRedeem;

  const UserProfile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    required this.domicile,
    required this.isVerifiedCitizen,
    required this.gamificationTitle,
    required this.civicPoints,
    required this.reportsSolved,
    required this.upvotesGiven,
    required this.totalReports,
    required this.followersCount,
    required this.followingCount,
    required this.myReports,
    required this.supportedReports,
    required this.badges,
    required this.availablePointsForRedeem,
  });
}

// Status laporan yang jelas dan bertingkat
enum ReportStatus {
  waitingReview,
  inProgress,
  solved,
  rejected,
}

extension ReportStatusExtension on ReportStatus {
  String get label {
    switch (this) {
      case ReportStatus.waitingReview:
        return 'Menunggu Review';
      case ReportStatus.inProgress:
        return 'Diproses Dinas PU';
      case ReportStatus.solved:
        return 'Selesai Diperbaiki';
      case ReportStatus.rejected:
        return 'Ditolak';
    }
  }
}

class UserReport {
  final String id;
  final String title;
  final String category;
  final String imageUrl;
  final String timeAgo;
  final int upvotes;
  final ReportStatus status;

  const UserReport({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.timeAgo,
    required this.upvotes,
    required this.status,
  });
}

class SupportedReport {
  final String id;
  final String title;
  final String authorName;
  final String authorAvatarUrl;
  final String category;
  final String imageUrl;
  final String timeAgo;
  final int upvotes;
  final ReportStatus status;
  final bool isSaved; // bookmarked vs upvoted

  const SupportedReport({
    required this.id,
    required this.title,
    required this.authorName,
    required this.authorAvatarUrl,
    required this.category,
    required this.imageUrl,
    required this.timeAgo,
    required this.upvotes,
    required this.status,
    required this.isSaved,
  });
}

// Gamification Badges
class Badge {
  final String id;
  final String name;
  final String description;
  final String icon; // emoji or asset path
  final BadgeRarity rarity;
  final bool isUnlocked;
  final String? unlockedAt;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.rarity,
    required this.isUnlocked,
    this.unlockedAt,
  });
}

enum BadgeRarity { common, rare, epic, legendary }

extension BadgeRarityExtension on BadgeRarity {
  String get label {
    switch (this) {
      case BadgeRarity.common:
        return 'Biasa';
      case BadgeRarity.rare:
        return 'Langka';
      case BadgeRarity.epic:
        return 'Epik';
      case BadgeRarity.legendary:
        return 'Legendaris';
    }
  }
}

// Reward/Insentif digital yang bisa ditukar poin
class RedeemReward {
  final String id;
  final String name;
  final String description;
  final int pointsCost;
  final String icon;
  final bool isAvailable;

  const RedeemReward({
    required this.id,
    required this.name,
    required this.description,
    required this.pointsCost,
    required this.icon,
    required this.isAvailable,
  });
}
