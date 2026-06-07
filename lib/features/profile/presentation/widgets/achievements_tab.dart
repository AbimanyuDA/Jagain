import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/user_profile.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';
import 'profile_theme.dart';

/// Tab 3: Pencapaian & Reward — badge collection + redeem poin.
class AchievementsTab extends StatelessWidget {
  final List<Badge> badges;
  final int availablePoints;
  final bool isOwnProfile;

  const AchievementsTab({
    super.key,
    required this.badges,
    required this.availablePoints,
    this.isOwnProfile = true,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProfileBloc>();
    final rewards = bloc.rewards;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Lencana Digital Section ─────────────────────────────────────
          _SectionHeader(
            title: 'Koleksi Lencana',
            subtitle: '${badges.where((b) => b.isUnlocked).length}/${badges.length} terbuka',
          ),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: badges.length,
            itemBuilder: (context, index) {
              return _BadgeCard(badge: badges[index]);
            },
          ),

          if (isOwnProfile) ...[
            const SizedBox(height: 28),
            // ── Tukar Poin Section ──────────────────────────────────────────
            _SectionHeader(
              title: 'Tukar Poin Kontribusi',
              subtitle: null,
            ),
            const SizedBox(height: 6),

            // Points balance chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stars_rounded,
                      color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${formatNumber(availablePoints)} poin tersedia',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Reward list
            ...rewards.map((reward) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RewardCard(
                    reward: reward,
                    availablePoints: availablePoints,
                    onRedeem: () {
                      context
                          .read<ProfileBloc>()
                          .add(RedeemPoints(reward.id));
                    },
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

// ── Badge Card ────────────────────────────────────────────────────────────────
class _BadgeCard extends StatelessWidget {
  final Badge badge;

  const _BadgeCard({required this.badge});

  @override
  Widget build(BuildContext context) {
    final gradientColors = RarityStyle.gradient(badge.rarity);
    final rarityColor = RarityStyle.color(badge.rarity);

    return Opacity(
      opacity: badge.isUnlocked ? 1.0 : 0.45,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: badge.isUnlocked
                ? rarityColor.withAlpha(77)
                : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: badge.isUnlocked
              ? [
                  BoxShadow(
                    color: rarityColor.withAlpha(38),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon in gradient circle
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: badge.isUnlocked
                    ? LinearGradient(colors: gradientColors)
                    : const LinearGradient(
                        colors: [Color(0xFFBDBDBD), Color(0xFF9E9E9E)],
                      ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: badge.isUnlocked
                    ? Text(
                        badge.icon,
                        style: const TextStyle(fontSize: 26),
                      )
                    : const Icon(Icons.lock_rounded,
                        color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(height: 8),

            // Badge name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                badge.name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: badge.isUnlocked
                      ? ProfileColors.navyDark
                      : Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),

            // Rarity label
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: rarityColor.withAlpha(26),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge.rarity.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: rarityColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reward Card ───────────────────────────────────────────────────────────────
class _RewardCard extends StatelessWidget {
  final RedeemReward reward;
  final int availablePoints;
  final VoidCallback onRedeem;

  const _RewardCard({
    required this.reward,
    required this.availablePoints,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    final canAfford = availablePoints >= reward.pointsCost;
    final isAvailable = reward.isAvailable && canAfford;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon bubble
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isAvailable
                  ? const Color(0xFFF0F4FF)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                reward.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isAvailable
                        ? ProfileColors.navyDark
                        : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  reward.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.stars_rounded,
                        size: 14, color: Color(0xFFFFB300)),
                    const SizedBox(width: 3),
                    Text(
                      '${formatNumber(reward.pointsCost)} poin',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: canAfford
                            ? const Color(0xFFFFB300)
                            : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Redeem button
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: isAvailable ? onRedeem : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isAvailable
                    ? ProfileColors.primary
                    : Colors.grey.shade200,
                foregroundColor:
                    isAvailable ? Colors.white : Colors.grey.shade400,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: Text(
                !reward.isAvailable
                    ? 'Habis'
                    : (!canAfford ? 'Kurang' : 'Tukar'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionHeader({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: ProfileColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: ProfileColors.navyDark,
          ),
        ),
        if (subtitle != null) ...[
          const Spacer(),
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF9E9E9E),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
