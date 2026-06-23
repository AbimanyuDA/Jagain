import 'package:flutter/material.dart';
import '../../domain/models/user_profile.dart';
import 'profile_theme.dart';

class ImpactStatsCard extends StatelessWidget {
  final UserProfile profile;

  const ImpactStatsCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outline, width: 0.5),
          bottom: BorderSide(color: colorScheme.outline, width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            _StatColumn(
              value: formatNumber(profile.civicPoints),
              label: 'Civic Points',
              icon: Icons.stars_rounded,
              iconColor: const Color(0xFFFFB300),
              isHighlighted: true,
              colorScheme: colorScheme,
            ),
            _Divider(colorScheme: colorScheme),
            _StatColumn(
              value: profile.reportsSolved.toString(),
              label: 'Laporan Solved',
              icon: Icons.check_circle_rounded,
              iconColor: const Color(0xFF00A550),
              colorScheme: colorScheme,
            ),
            _Divider(colorScheme: colorScheme),
            _StatColumn(
              value: profile.upvotesGiven.toString(),
              label: 'Upvotes Given',
              icon: Icons.thumb_up_rounded,
              iconColor: const Color(0xFF2E5BFF),
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;
  final bool isHighlighted;
  final ColorScheme colorScheme;

  const _StatColumn({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.colorScheme,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlighted ? 18 : 16,
              fontWeight: FontWeight.w900,
              color: isHighlighted
                  ? ProfileColors.primary
                  : colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant,
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
  final ColorScheme colorScheme;
  const _Divider({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 1, height: 40, color: colorScheme.outlineVariant);
  }
}
