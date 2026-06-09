import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/theme_cubit.dart';
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
    final currentUserId = authState is AuthAuthenticated
        ? authState.user.uid
        : (authState is AuthSwitching ? authState.previousUser.uid : null);

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

  void _showAccountSwitcher(BuildContext context, UserProfile profile) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
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
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: profile.avatarUrl.isNotEmpty
                          ? NetworkImage(profile.avatarUrl)
                          : null,
                      backgroundColor: colorScheme.surfaceContainer,
                      child: profile.avatarUrl.isEmpty
                          ? Icon(Icons.person,
                              color: colorScheme.onSurfaceVariant)
                          : null,
                    ),
                    title: Text(
                      profile.username,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface),
                    ),
                    trailing: const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF00A550)),
                    onTap: () => Navigator.pop(sheetContext),
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
                          backgroundColor: colorScheme.surfaceContainer,
                          child: avatarUrl.isEmpty
                              ? Text(
                                  name.isNotEmpty
                                      ? name[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(username,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface)),
                        subtitle: Text(name,
                            style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12)),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          context.read<AuthBloc>().add(
                              AuthSwitchAccountRequested(
                                  session['uid'] ?? ''));
                        },
                      );
                    }),
                  Divider(
                      color: colorScheme.outline,
                      height: 1,
                      thickness: 0.5),
                  ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.outline),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add_rounded,
                          color: colorScheme.onSurface),
                    ),
                    title: Text('Tambah Akun Jagain',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface)),
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

  void _showOwnProfileSettings(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final themeCubit = context.read<ThemeCubit>();
    final authBloc = context.read<AuthBloc>();

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: themeCubit),
            BlocProvider.value(value: authBloc),
          ],
          child: _ProfileSettingsSheet(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listenWhen: (previous, current) =>
          current is ProfileLoaded && current.redeemSuccessMessage != null,
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
        final authState = context.watch<AuthBloc>().state;
        if (state is ProfileLoading ||
            authState is AuthLoading ||
            authState is AuthSwitching) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (state is ProfileError) {
          return Scaffold(body: Center(child: Text(state.message)));
        }
        if (state is ProfileLoaded) {
          return _buildLoadedView(context, state.profile);
        }
        return const Scaffold(
            body: Center(child: CircularProgressIndicator()));
      },
    );
  }

  Widget _buildLoadedView(BuildContext context, UserProfile profile) {
    final colorScheme = Theme.of(context).colorScheme;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final isOwnProfile =
        profile.id == FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        leading: isOwnProfile
            ? IconButton(
                icon: Icon(Icons.add, color: colorScheme.onSurface),
                onPressed: () => context.push('/create-report'),
                padding: EdgeInsets.zero,
              )
            : IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    color: colorScheme.onSurface, size: 20),
                onPressed: () => context.pop(),
                padding: EdgeInsets.zero,
              ),
        title: isOwnProfile
            ? GestureDetector(
                onTap: () => _showAccountSwitcher(context, profile),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      profile.username,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (profile.isVerifiedCitizen) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.verified_rounded,
                          color: colorScheme.primary, size: 16),
                    ],
                    const SizedBox(width: 2),
                    Icon(Icons.keyboard_arrow_down_rounded,
                        color: colorScheme.onSurface, size: 20),
                  ],
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    profile.username,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      letterSpacing: -0.4,
                    ),
                  ),
                  if (profile.isVerifiedCitizen) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.verified_rounded,
                        color: colorScheme.primary, size: 16),
                  ],
                ],
              ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isOwnProfile ? Icons.menu_rounded : Icons.more_horiz_rounded,
              color: colorScheme.onSurface,
            ),
            onPressed: () =>
                isOwnProfile ? _showOwnProfileSettings(context) : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final profileBloc = context.read<ProfileBloc>();
          profileBloc.add(LoadProfile(username: widget.targetUsername));
          await profileBloc.stream
              .firstWhere((s) => s is ProfileLoaded || s is ProfileError);
        },
        child: NestedScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    ProfileHeader(
                        profile: profile, isOwnProfile: isOwnProfile),
                    ImpactStatsCard(profile: profile),
                  ],
                ),
              ),
            ];
          },
          body: Column(
            children: [
              ColoredBox(
                color: scaffoldBg,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: colorScheme.primary,
                  indicatorWeight: 2.5,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: colorScheme.primary,
                  unselectedLabelColor: colorScheme.onSurfaceVariant,
                  dividerColor: colorScheme.outline,
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.1,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: _tabs
                      .map((t) => Tab(
                            height: 44,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(t.icon, size: 15),
                                const SizedBox(width: 5),
                                Text(t.label),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
              Expanded(
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
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  const _TabItem({required this.label, required this.icon});
}


// ── Settings bottom sheet ────────────────────────────────────────────────────

class _ProfileSettingsSheet extends StatelessWidget {
  const _ProfileSettingsSheet();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pengaturan',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, themeMode) {
                final isDark = themeMode == ThemeMode.dark;
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20),
                  leading: Icon(
                    isDark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    color: colorScheme.onSurface,
                  ),
                  title: Text(
                    'Mode Gelap',
                    style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                        fontSize: 15),
                  ),
                  trailing: Switch(
                    value: isDark,
                    activeThumbColor: colorScheme.primary,
                    activeTrackColor: colorScheme.primaryContainer,
                    onChanged: (_) =>
                        context.read<ThemeCubit>().toggle(),
                  ),
                );
              },
            ),
            Divider(
                color: colorScheme.outline, thickness: 0.5, height: 8),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20),
              leading: Icon(Icons.edit_outlined,
                  color: colorScheme.onSurface),
              title: Text(
                'Edit Profil',
                style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                    fontSize: 15),
              ),
              onTap: () {
                Navigator.pop(context);
                context.push('/edit-profile');
              },
            ),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20),
              leading:
                  const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text(
                'Keluar',
                style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                    fontSize: 15),
              ),
              onTap: () {
                Navigator.pop(context);
                context.read<AuthBloc>().add(AuthLogoutRequested());
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
