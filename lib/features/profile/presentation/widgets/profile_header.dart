import 'package:flutter/material.dart';
import '../../domain/models/user_profile.dart';

/// ProfileHeader — compact, no top bar (username sudah ada di AppBar).
class ProfileHeader extends StatelessWidget {
  final UserProfile profile;

  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Top Bar (Username & Menu) ──────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 48), // Menyeimbangkan icon menu di kanan agar username tetap center
                Expanded(
                  child: Text(
                    '@${profile.username}',
                    style: const TextStyle(
                      color: Color(0xFF0F1E36),
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      letterSpacing: -0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F1E36)),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Avatar center ──────────────────────────────────────────
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1.5,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: NetworkImage(profile.avatarUrl),
                  ),
                ),
                if (profile.isVerifiedCitizen)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00A550),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Nama Lengkap ───────────────────────────────────────────
            Text(
              profile.displayName,
              style: const TextStyle(
                color: Color(0xFF0F1E36),
                fontWeight: FontWeight.w800,
                fontSize: 17,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // ── Lokasi ─────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on_rounded,
                    size: 12, color: Colors.grey.shade400),
                const SizedBox(width: 2),
                Text(
                  profile.domicile,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ── Badge chips ────────────────────────────────────────────
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                if (profile.isVerifiedCitizen)
                  _BadgeChip(
                    label: 'Verified Citizen',
                    icon: Icons.shield_rounded,
                    color: const Color(0xFF00A550),
                    bgColor: const Color(0xFFE6F8EF),
                  ),
                _BadgeChip(
                  label: profile.gamificationTitle,
                  icon: Icons.military_tech_rounded,
                  color: const Color(0xFFB45309),
                  bgColor: const Color(0xFFFEF3C7),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Edit Profil button ─────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 32,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade300, width: 1),
                  foregroundColor: const Color(0xFF0F1E36),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Edit Profil'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badge Chip ─────────────────────────────────────────────────────────────────
class _BadgeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _BadgeChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
