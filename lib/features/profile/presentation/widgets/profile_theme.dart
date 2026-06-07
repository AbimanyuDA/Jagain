import 'package:flutter/material.dart';
import '../../domain/models/user_profile.dart';

// ── Centralized styling helpers untuk Profile feature ────────────────────────

class ProfileColors {
  // Brand colors (harus konsisten dengan AppTheme)
  static const Color primary = Color(0xFF2E5BFF);
  static const Color navyDark = Color(0xFF0F1E36);
  static const Color accent = Color(0xFFFFA000);

  // Status Colors — kontras & aksesibel
  static const Color statusSolved = Color(0xFF00A550);
  static const Color statusSolvedBg = Color(0xFFE6F8EF);
  static const Color statusInProgress = Color(0xFF2E5BFF);
  static const Color statusInProgressBg = Color(0xFFEEF2FF);
  static const Color statusWaiting = Color(0xFFFF8C00);
  static const Color statusWaitingBg = Color(0xFFFFF3E0);
  static const Color statusRejected = Color(0xFFD32F2F);
  static const Color statusRejectedBg = Color(0xFFFFEBEE);

  // Rarity Colors untuk badge
  static const Color rarityCommon = Color(0xFF78909C);
  static const Color rarityRare = Color(0xFF1E88E5);
  static const Color rarityEpic = Color(0xFF7B1FA2);
  static const Color rarityLegendary = Color(0xFFFF8F00);
}

// ── Status Color Resolver ─────────────────────────────────────────────────────
class StatusStyle {
  final Color color;
  final Color backgroundColor;
  final IconData icon;

  const StatusStyle({
    required this.color,
    required this.backgroundColor,
    required this.icon,
  });

  static StatusStyle fromStatus(ReportStatus status) {
    switch (status) {
      case ReportStatus.solved:
        return const StatusStyle(
          color: ProfileColors.statusSolved,
          backgroundColor: ProfileColors.statusSolvedBg,
          icon: Icons.check_circle_rounded,
        );
      case ReportStatus.inProgress:
        return const StatusStyle(
          color: ProfileColors.statusInProgress,
          backgroundColor: ProfileColors.statusInProgressBg,
          icon: Icons.engineering_rounded,
        );
      case ReportStatus.waitingReview:
        return const StatusStyle(
          color: ProfileColors.statusWaiting,
          backgroundColor: ProfileColors.statusWaitingBg,
          icon: Icons.hourglass_top_rounded,
        );
      case ReportStatus.rejected:
        return const StatusStyle(
          color: ProfileColors.statusRejected,
          backgroundColor: ProfileColors.statusRejectedBg,
          icon: Icons.cancel_rounded,
        );
    }
  }
}

// ── Category Color Resolver ───────────────────────────────────────────────────
class CategoryStyle {
  static Color backgroundColor(String category) {
    switch (category.toUpperCase()) {
      case 'JALAN':
        return const Color(0xFFFFECB3);
      case 'PJU':
        return const Color(0xFFFFF9C4);
      case 'DRAINASE':
        return const Color(0xFFB3E5FC);
      case 'TROTOAR':
        return const Color(0xFFD7CCC8);
      case 'BANJIR':
        return const Color(0xFFBBDEFB);
      case 'POHON':
        return const Color(0xFFC8E6C9);
      default:
        return const Color(0xFFE8EAF6);
    }
  }

  static Color textColor(String category) {
    switch (category.toUpperCase()) {
      case 'JALAN':
        return const Color(0xFFE65100);
      case 'PJU':
        return const Color(0xFFF57F17);
      case 'DRAINASE':
        return const Color(0xFF01579B);
      case 'TROTOAR':
        return const Color(0xFF4E342E);
      case 'BANJIR':
        return const Color(0xFF1565C0);
      case 'POHON':
        return const Color(0xFF1B5E20);
      default:
        return const Color(0xFF283593);
    }
  }
}

// ── Rarity Color Resolver ────────────────────────────────────────────────────
class RarityStyle {
  static Color color(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.common:
        return ProfileColors.rarityCommon;
      case BadgeRarity.rare:
        return ProfileColors.rarityRare;
      case BadgeRarity.epic:
        return ProfileColors.rarityEpic;
      case BadgeRarity.legendary:
        return ProfileColors.rarityLegendary;
    }
  }

  static List<Color> gradient(BadgeRarity rarity) {
    switch (rarity) {
      case BadgeRarity.common:
        return [const Color(0xFF90A4AE), const Color(0xFF607D8B)];
      case BadgeRarity.rare:
        return [const Color(0xFF42A5F5), const Color(0xFF1565C0)];
      case BadgeRarity.epic:
        return [const Color(0xFFAB47BC), const Color(0xFF6A1B9A)];
      case BadgeRarity.legendary:
        return [const Color(0xFFFFCA28), const Color(0xFFFF8F00)];
    }
  }
}

// ── Number Formatter ─────────────────────────────────────────────────────────
String formatNumber(int n) {
  if (n >= 1000) {
    return '${(n / 1000).toStringAsFixed(1)}K';
  }
  return n.toString();
}
