import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/session_manager.dart';
import '../domain/models/user_profile.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_event.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import 'bloc/profile_bloc.dart';
import 'bloc/profile_event.dart';
import 'bloc/profile_state.dart';
import 'widgets/profile_header.dart';
import 'widgets/impact_stats_card.dart';
import 'widgets/my_reports_tab.dart';
import 'widgets/supported_reports_tab.dart';
import 'widgets/achievements_tab.dart';
import 'widgets/profile_theme.dart';

class ProfileScreen extends StatelessWidget {
  final String? targetUsername;

  const ProfileScreen({super.key, this.targetUsername});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final currentUserId = authState is AuthAuthenticated ? authState.user.uid : null;

    return BlocProvider(
      key: ValueKey('${currentUserId}_$targetUsername'),
      create: (context) =>
          ProfileBloc()..add(LoadProfile(username: targetUsername)),
      child: _ProfileView(targetUsername: targetUsername),
    );
  }
}

class _ProfileView extends StatefulWidget {
  final String? targetUsername;

  const _ProfileView({this.targetUsername});

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const List<_TabItem> _tabs = [
    _TabItem(label: 'Laporan', icon: Icons.article_outlined),
    _TabItem(label: 'Dukungan', icon: Icons.favorite_outline_rounded),
    _TabItem(label: 'Pencapaian', icon: Icons.emoji_events_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<ProfileBloc>().add(SwitchProfileTab(_tabController.index));
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
          current is ProfileLoaded && (current).redeemSuccessMessage != null,
      listener: (context, state) {
        if (state is ProfileLoaded && state.redeemSuccessMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(
                    Icons.celebration_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(state.redeemSuccessMessage!),
                ],
              ),
              backgroundColor: ProfileColors.statusSolved,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      builder: (context, state) {
        final authState = context.watch<AuthBloc>().state;
        if (state is ProfileLoading || authState is AuthLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ProfileError) {
          return Scaffold(body: Center(child: Text(state.message)));
        }

        if (state is ProfileLoaded) {
          final profile = state.profile;
          final isOwnProfile =
              profile.id == FirebaseAuth.instance.currentUser?.uid;

          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              top: true,
              bottom: false,
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _ProfileHeaderDelegate(
                      profile: profile,
                      isOwnProfile: isOwnProfile,
                      tabController: _tabController,
                      tabs: _tabs,
                    ),
                  ),
                ],

                body: Container(
                  color: const Color(0xFFF8F9FA),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      MyReportsTab(reports: profile.myReports),
                      SupportedReportsTab(reports: profile.supportedReports),
                      AchievementsTab(
                        badges: profile.badges,
                        availablePoints: profile.availablePointsForRedeem,
                        isOwnProfile: isOwnProfile,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  const _TabItem({required this.label, required this.icon});
}

class _ProfileTabBar extends StatelessWidget {
  final TabController controller;
  final List<_TabItem> tabs;

  const _ProfileTabBar({required this.controller, required this.tabs});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: controller,
        indicatorColor: ProfileColors.primary,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: ProfileColors.primary,
        unselectedLabelColor: Colors.grey.shade500,
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        tabs: tabs
            .map(
              (t) => Tab(
                height: 44,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.icon, size: 15),
                    const SizedBox(width: 5),
                    Text(t.label),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  final UserProfile profile;
  final bool isOwnProfile;
  final TabController tabController;
  final List<_TabItem> tabs;

  _ProfileHeaderDelegate({
    required this.profile,
    required this.isOwnProfile,
    required this.tabController,
    required this.tabs,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double visibleThreshold = maxExtent - minExtent;
    final double percent = (shrinkOffset / visibleThreshold).clamp(0.0, 1.0);
    final double detailsOpacity = 1.0 - percent;

    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          Positioned(
            top: 46 - (shrinkOffset * 0.8),
            left: 0,
            right: 0,
            child: Opacity(
              opacity: detailsOpacity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ProfileHeader(profile: profile, isOwnProfile: isOwnProfile),
                  ImpactStatsCard(profile: profile),
                ],
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 46,
            child: Container(
              color: Colors.white.withAlpha((percent * 255).round()),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (isOwnProfile) ...[
                      IconButton(
                        icon: const Icon(Icons.add, color: Color(0xFF0F1E36)),
                        onPressed: () => context.push('/create-report'),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const Spacer(),
                    ] else ...[
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Color(0xFF0F1E36),
                          size: 20,
                        ),
                        onPressed: () => context.pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (isOwnProfile)
                      GestureDetector(
                        onTap: () => _showAccountSwitcher(context, profile),
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              profile.username,
                              style: const TextStyle(
                                color: Color(0xFF0F1E36),
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                letterSpacing: -0.4,
                              ),
                            ),
                            if (profile.isVerifiedCitizen) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.verified_rounded,
                                color: Color(0xFF2E5BFF),
                                size: 14,
                              ),
                            ],
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF0F1E36),
                              size: 18,
                            ),
                          ],
                        ),
                      )
                    else ...[
                      Text(
                        profile.username,
                        style: const TextStyle(
                          color: Color(0xFF0F1E36),
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          letterSpacing: -0.4,
                        ),
                      ),
                      if (profile.isVerifiedCitizen) ...[
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF2E5BFF),
                          size: 15,
                        ),
                      ],
                    ],
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        isOwnProfile
                            ? Icons.menu_rounded
                            : Icons.more_horiz_rounded,
                        color: const Color(0xFF0F1E36),
                      ),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 49,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                ),
              ),
              child: _ProfileTabBar(controller: tabController, tabs: tabs),
            ),
          ),
        ],
      ),
    );
  }

  void _showAccountSwitcher(BuildContext context, UserProfile profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: SessionManager.getSessions(),
            builder: (futureContext, snapshot) {
              final allSessions = snapshot.data ?? [];
              final otherSessions = allSessions
                  .where((s) => s['username'] != profile.username)
                  .toList();

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Akun Aktif (Real User dari backend)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: profile.avatarUrl.isNotEmpty
                          ? NetworkImage(profile.avatarUrl)
                          : null,
                      backgroundColor: Colors.grey.shade200,
                      child: profile.avatarUrl.isEmpty
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),
                    title: Text(
                      profile.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F1E36),
                      ),
                    ),
                    trailing: const Icon(Icons.check_circle_rounded, color: Color(0xFF00A550)),
                    onTap: () {
                      Navigator.pop(sheetContext);
                    },
                  ),
                  
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    ...otherSessions.map((session) {
                      final username = session['username'] ?? 'warga';
                      final name = session['name'] ?? '';
                      final avatarUrl = session['avatarUrl'] ?? '';
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : null,
                          backgroundColor: Colors.grey.shade200,
                          child: avatarUrl.isEmpty
                              ? Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F1E36),
                          ),
                        ),
                        subtitle: Text(
                          name,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          context.read<AuthBloc>().add(AuthSwitchAccountRequested(session['uid'] ?? ''));
                        },
                      );
                    }).toList(),
                  
                  const Divider(),
                  
                  // Tambah Akun
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_rounded, color: Color(0xFF0F1E36)),
                    ),
                    title: const Text(
                      'Tambah Akun Jagain',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F1E36),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      context.push('/login?adding=true');
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  double get maxExtent => 390;

  @override
  double get minExtent => 95;

  @override
  bool shouldRebuild(_ProfileHeaderDelegate oldDelegate) {
    return oldDelegate.profile != profile ||
        oldDelegate.isOwnProfile != isOwnProfile ||
        oldDelegate.tabController != tabController ||
        oldDelegate.tabs != tabs;
  }
}
