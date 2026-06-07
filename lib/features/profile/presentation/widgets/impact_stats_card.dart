import 'package:flutter/material.dart';
import '../../domain/models/user_profile.dart';
import 'profile_theme.dart';

/// ImpactStatsCard — 3 kolom metrik scannable yang menampilkan
/// Civic Points, Laporan Solved, dan Upvotes Given.
/// Didesain sebagai floating card di atas konten bawah.
class ImpactStatsCard extends StatelessWidget {
  final UserProfile profile;

  const ImpactStatsCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F1E36).withAlpha(26),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        child: Row(
          children: [
            _StatColumn(
              value: formatNumber(profile.civicPoints),
              label: 'Civic Points',
              icon: Icons.stars_rounded,
              iconColor: const Color(0xFFFFB300),
              valueColor: ProfileColors.navyDark,
              isHighlighted: true,
            ),
            _Divider(),
            _StatColumn(
              value: profile.reportsSolved.toString(),
              label: 'Laporan Solved',
              icon: Icons.check_circle_rounded,
              iconColor: ProfileColors.statusSolved,
              valueColor: ProfileColors.navyDark,
            ),
            _Divider(),
            _StatColumn(
              value: profile.upvotesGiven.toString(),
              label: 'Upvotes Given',
              icon: Icons.thumb_up_rounded,
              iconColor: ProfileColors.primary,
              valueColor: ProfileColors.navyDark,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-components ────────────────────────────────────────────────────────────

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color valueColor;
  final bool isHighlighted;

  const _StatColumn({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.valueColor,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          // Icon bubble
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 10),

          // Value
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlighted ? 22 : 20,
              fontWeight: FontWeight.w900,
              color: isHighlighted ? ProfileColors.primary : valueColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),

          // Label
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9E9E9E),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 56,
      color: Colors.grey.shade100,
    );
  }
}
