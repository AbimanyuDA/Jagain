import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/profile_bloc.dart';
import 'bloc/profile_event.dart';
import 'bloc/profile_state.dart';
import 'widgets/profile_header.dart';
import 'widgets/impact_stats_card.dart';
import 'widgets/my_reports_tab.dart';
import 'widgets/supported_reports_tab.dart';
import 'widgets/achievements_tab.dart';
import 'widgets/profile_theme.dart';

/// ProfileScreen — halaman profil warga/pelapor JAGAIN.
///
/// Arsitektur:
///  - BlocProvider menyediakan ProfileBloc
///  - CustomScrollView + SliverPersistentHeader untuk sticky tab bar
///  - Tab content menggunakan IndexedStack agar state tidak reset
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileBloc()..add(const LoadProfile()),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const List<_TabItem> _tabs = [
    _TabItem(label: 'Laporanku', icon: Icons.campaign_rounded),
    _TabItem(label: 'Jejak Dukungan', icon: Icons.favorite_rounded),
    _TabItem(label: 'Pencapaian', icon: Icons.military_tech_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context
            .read<ProfileBloc>()
            .add(SwitchProfileTab(_tabController.index));
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (previous, current) =>
          current is ProfileLoaded &&
          (current).redeemSuccessMessage != null,
      listener: (context, state) {
        if (state is ProfileLoaded && state.redeemSuccessMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.celebration_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Text(state.redeemSuccessMessage!),
                ],
              ),
              backgroundColor: ProfileColors.statusSolved,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is ProfileLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ProfileError) {
          return Scaffold(
            body: Center(child: Text(state.message)),
          );
        }

        if (state is ProfileLoaded) {
          final profile = state.profile;

          return Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                // ── SliverAppBar: Header profil + Stats Card ─────────────
                SliverAppBar(
                  expandedHeight: 380,
                  pinned: true,
                  floating: false,
                  backgroundColor: const Color(0xFF0F1E36),
                  elevation: 0,
                  // Title yang muncul saat header ter-collapse
                  title: AnimatedOpacity(
                    opacity: innerBoxIsScrolled ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(profile.avatarUrl),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          profile.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    // Gunakan ClampingScrollPhysics agar tidak ada efek parallax
                    collapseMode: CollapseMode.pin,
                    background: Stack(
                      children: [
                        // ── Layer 1: Gradient header mengisi full area ──
                        Positioned.fill(
                          child: ProfileHeader(profile: profile),
                        ),
                        // ── Layer 2: Stats card anchor di bagian bawah ──
                        // Margin bottom memberi ruang agar card tidak terpotong
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: ImpactStatsCard(profile: profile),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── SliverPersistentHeader: Sticky Tab Bar ────────────────
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyTabBarDelegate(
                    child: _ProfileTabBar(
                      controller: _tabController,
                      tabs: _tabs,
                    ),
                  ),
                ),
              ],

              // ── Tab Content ───────────────────────────────────────────────
              body: TabBarView(
                controller: _tabController,
                children: [
                  MyReportsTab(reports: profile.myReports),
                  SupportedReportsTab(reports: profile.supportedReports),
                  AchievementsTab(
                    badges: profile.badges,
                    availablePoints: profile.availablePointsForRedeem,
                  ),
                ],
              ),
            ),
          );
        }

        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

// ── Tab Bar Component ─────────────────────────────────────────────────────────
class _TabItem {
  final String label;
  final IconData icon;
  const _TabItem({required this.label, required this.icon});
}

class _ProfileTabBar extends StatelessWidget {
  final TabController controller;
  final List<_TabItem> tabs;

  const _ProfileTabBar({
    required this.controller,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            controller: controller,
            indicatorColor: ProfileColors.primary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: ProfileColors.primary,
            unselectedLabelColor: Colors.grey.shade500,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            tabs: tabs
                .map((t) => Tab(
                      height: 44,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(t.icon, size: 16),
                          const SizedBox(width: 6),
                          Text(t.label),
                        ],
                      ),
                    ))
                .toList(),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
        ],
      ),
    );
  }
}

// ── Sticky Tab Bar Delegate ───────────────────────────────────────────────────
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyTabBarDelegate({required this.child});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      elevation: overlapsContent ? 2 : 0,
      shadowColor: Colors.black12,
      child: child,
    );
  }

  @override
  double get maxExtent => 48;

  @override
  double get minExtent => 48;

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
