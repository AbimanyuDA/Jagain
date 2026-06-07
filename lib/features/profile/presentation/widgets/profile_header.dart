import 'package:flutter/material.dart';
import '../../domain/models/user_profile.dart';

/// ProfileHeader — menampilkan avatar, nama, domisili, badge verifikasi,
/// dan title gamifikasi pengguna. Ini adalah komponen kredibilitas utama.
class ProfileHeader extends StatelessWidget {
  final UserProfile profile;

  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F1E36), Color(0xFF1A3360), Color(0xFF2E5BFF)],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          // bottom: 120 memberi ruang untuk ImpactStatsCard (tinggi ~110px) yang
          // di-overlay di bagian bawah Stack oleh profile_screen
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          child: Column(
            children: [
              // ── Top bar: Pengaturan ──────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profil Saya',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 0.3,
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.settings_outlined,
                        color: Colors.white70),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Avatar + Identity ────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar dengan border premium
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withAlpha(204),
                              Colors.white.withAlpha(77),
                            ],
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor: Colors.white24,
                          backgroundImage: NetworkImage(profile.avatarUrl),
                        ),
                      ),
                      // Verified badge overlay
                      if (profile.isVerifiedCitizen)
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFF00A550),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.verified_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Nama, lokasi, badges
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nama Pengguna
                        Text(
                          profile.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Lokasi Domisili
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 14, color: Colors.white60),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                profile.domicile,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Badge row: Verified Citizen + Gamification Title
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (profile.isVerifiedCitizen)
                              _BadgeChip(
                                label: 'Verified Citizen',
                                icon: Icons.shield_rounded,
                                color: const Color(0xFF00A550),
                                bgColor: const Color(0x3300A550),
                              ),
                            _BadgeChip(
                              label: profile.gamificationTitle,
                              icon: Icons.military_tech_rounded,
                              color: const Color(0xFFFFD54F),
                              bgColor: const Color(0x33FFD54F),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Internal helper widget ────────────────────────────────────────────────────
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(102), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
