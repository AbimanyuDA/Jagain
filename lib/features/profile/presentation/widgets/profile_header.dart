import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes.dart';
import '../../domain/models/user_profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfile profile;
  final bool isOwnProfile;

  const ProfileHeader({
    super.key,
    required this.profile,
    this.isOwnProfile = true,
  });

  void _toggleFollow(BuildContext context) {
    final bloc = context.read<ProfileBloc>();
    final colorScheme = Theme.of(context).colorScheme;
    if (profile.isFollowing) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: colorScheme.surface,
          title: Text(
            'Batal mengikuti @${profile.username}?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Anda tidak akan menerima update laporan dari warga ini di feed lagi.',
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Batal',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                bloc.add(const ToggleFollow());
              },
              child: const Text(
                'Batal Mengikuti',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    } else {
      bloc.add(const ToggleFollow());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      width: double.infinity,
      color: scaffoldBg,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar – centered
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.outline, width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: colorScheme.surfaceContainer,
                  backgroundImage: profile.avatarUrl.isNotEmpty
                      ? CachedNetworkImageProvider(profile.avatarUrl)
                      : null,
                  child: profile.avatarUrl.isEmpty
                      ? Text(
                          profile.displayName.isNotEmpty
                              ? profile.displayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        )
                      : null,
                ),
              ),
              if (profile.isVerifiedCitizen)
                Positioned(
                  bottom: 3,
                  right: 3,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF00A550),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Display name – centered
          Text(
            profile.displayName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 17,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 2),

          // Username – centered
          Text(
            '@${profile.username}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 10),

          // Badges – centered
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
              if (profile.domicile.isNotEmpty)
                _BadgeChip(
                  label: profile.domicile,
                  icon: Icons.location_on_rounded,
                  color: colorScheme.onSurfaceVariant,
                  bgColor: colorScheme.surfaceContainer,
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Stats row – centered
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatItem(
                count: '${profile.totalReports}',
                label: 'Laporan',
                colorScheme: colorScheme,
              ),
              _StatDivider(colorScheme: colorScheme),
              _StatItem(
                count: '${profile.followersCount}',
                label: 'Pengikut',
                colorScheme: colorScheme,
              ),
              _StatDivider(colorScheme: colorScheme),
              _StatItem(
                count: '${profile.followingCount}',
                label: 'Mengikuti',
                colorScheme: colorScheme,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Action buttons
          if (isOwnProfile)
            SizedBox(
              width: double.infinity,
              height: 36,
              child: OutlinedButton(
                onPressed: () async {
                  final updated = await context.push<bool>(AppRoutes.editProfile);
                  if (updated == true && context.mounted) {
                    context.read<ProfileBloc>().add(const LoadProfile());
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.onSurface,
                  side: BorderSide(color: colorScheme.outline),
                  backgroundColor: colorScheme.surfaceContainer,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Edit Profil'),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: profile.isFollowing
                        ? OutlinedButton(
                            onPressed: () => _toggleFollow(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.onSurface,
                              side: BorderSide(color: colorScheme.outline),
                              backgroundColor: colorScheme.surfaceContainer,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              textStyle: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            child: const Text('Mengikuti'),
                          )
                        : ElevatedButton(
                            onPressed: () => _toggleFollow(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              textStyle: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                            child: const Text('Ikuti'),
                          ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.onSurface,
                        side: BorderSide(color: colorScheme.outline),
                        backgroundColor: colorScheme.surfaceContainer,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      child: const Text('Kirim Pesan'),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String count;
  final String label;
  final ColorScheme colorScheme;

  const _StatItem({
    required this.count,
    required this.label,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  final ColorScheme colorScheme;
  const _StatDivider({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: colorScheme.outlineVariant,
    );
  }
}

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
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
