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
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade100, width: 1),
          bottom: BorderSide(color: Colors.grey.shade100, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8), // Diperkecil dari 12 ke 8
        child: Row(
          children: [
            _StatColumn(
              value: formatNumber(profile.civicPoints),
              label: 'Civic Points',
              icon: Icons.stars_rounded,
              iconColor: const Color(0xFFFFB300),
              valueColor: const Color(0xFF0F1E36),
              isHighlighted: true,
            ),
            _Divider(),
            _StatColumn(
              value: profile.reportsSolved.toString(),
              label: 'Laporan Solved',
              icon: Icons.check_circle_rounded,
              iconColor: const Color(0xFF00A550),
              valueColor: const Color(0xFF0F1E36),
            ),
            _Divider(),
            _StatColumn(
              value: profile.upvotesGiven.toString(),
              label: 'Upvotes Given',
              icon: Icons.thumb_up_rounded,
              iconColor: const Color(0xFF2E5BFF),
              valueColor: const Color(0xFF0F1E36),
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
            width: 28, // Diperkecil dari 36 ke 28
            height: 28,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(26),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 14), // Diperkecil dari 18 ke 14
          ),
          const SizedBox(height: 4), // Diperkecil dari 6 ke 4

          // Value
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlighted ? 18 : 16, // Diperkecil dari 22/20 ke 18/16
              fontWeight: FontWeight.w900,
              color: isHighlighted ? ProfileColors.primary : valueColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 1), // Diperkecil dari 3 ke 1

          // Label
          Text(
            label,
            style: const TextStyle(
              fontSize: 10, // Diperkecil dari 11 ke 10
              color: Color(0xFF9E9E9E),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
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
      height: 40, // Diperkecil dari 56 ke 40
      color: Colors.grey.shade100,
    );
  }
}
