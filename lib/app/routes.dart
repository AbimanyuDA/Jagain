import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/feed/presentation/feed_screen.dart';
import '../features/report_creation/presentation/create_report_screen.dart';
import '../features/admin_panel/presentation/admin_dashboard_screen.dart';
import '../features/admin_panel/presentation/category_management_screen.dart';
import '../features/admin_panel/presentation/official_verification_screen.dart';
import '../features/admin_panel/presentation/report_moderation_screen.dart';
import '../features/admin_panel/presentation/system_analytics_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';
import '../features/auth/presentation/bloc/auth_state.dart';
import '../features/auth/domain/user_model.dart';
import '../features/pejabat_dashboard/presentation/pejabat_dashboard_screen.dart';

// Halaman-halaman yang boleh diakses tanpa login
const _publicRoutes = ['/login', '/register'];

/// Menjembatani BLoC stream ke ChangeNotifier agar GoRouter
/// otomatis re-evaluasi redirect setiap kali auth state berubah.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

class AppRoutes {
  // Routes Names
  static const String login = '/login';
  static const String register = '/register';
  static const String feed = '/';
  static const String createReport = '/create-report';
  static const String pejabatDashboard = '/pejabat';
  static const String adminDashboard = '/admin';
  static const String adminModeration = '/admin/moderation';
  static const String adminOfficials = '/admin/officials';
  static const String adminCategories = '/admin/categories';
  static const String adminAnalytics = '/admin/analytics';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';

  static GoRouter createRouter(BuildContext context) {
    final authBloc = context.read<AuthBloc>();

    return GoRouter(
      initialLocation: feed,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
      redirect: (BuildContext ctx, GoRouterState state) {
        final authState = authBloc.state;
        final isPublicRoute = _publicRoutes.contains(state.matchedLocation);

        if (authState is AuthSwitching) {
          return null;
        }

        // Masih loading → tunggu, jangan redirect dulu
        if (authState is AuthLoading || authState is AuthInitial) {
          return isPublicRoute ? null : login;
        }

        final isLoggedIn = authState is AuthAuthenticated;

        // Belum login dan bukan halaman publik → paksa ke login
        if (!isLoggedIn && !isPublicRoute) return login;

        // Sudah login tapi masih di halaman login/register → arahkan ke feed (kecuali jika sedang menambah akun baru)
        if (isLoggedIn && isPublicRoute) {
          final isAdding = state.uri.queryParameters['adding'] == 'true';
          if (isAdding) return null;
          return feed;
        }

        // Role guard: cek akses halaman terproteksi
        if (authState is AuthAuthenticated) {
          final user = authState.user;
          final loc = state.matchedLocation;

          // Hanya admin yang boleh akses /admin
          if (loc == adminDashboard && user.role != UserRole.admin) return feed;

          // Hanya official yang boleh akses /pejabat
          if (loc == pejabatDashboard && user.role != UserRole.official) return feed;
        }

        // Lainnya → tidak ada redirect
        return null;
      },
      routes: [
        GoRoute(
          path: feed,
          builder: (BuildContext context, GoRouterState state) =>
              const FeedScreen(),
        ),
        GoRoute(
          path: login,
          builder: (BuildContext context, GoRouterState state) =>
              const LoginScreen(),
        ),
        GoRoute(
          path: register,
          builder: (BuildContext context, GoRouterState state) =>
              const RegisterScreen(),
        ),
        GoRoute(
          path: createReport,
          builder: (BuildContext context, GoRouterState state) =>
              const CreateReportScreen(),
        ),
        GoRoute(
          path: pejabatDashboard,
          builder: (BuildContext context, GoRouterState state) =>
              const PejabatDashboardScreen(),
        ),
        GoRoute(
          path: adminDashboard,
          builder: (BuildContext context, GoRouterState state) =>
              const AdminDashboardScreen(),
        ),
        GoRoute(
          path: adminModeration,
          builder: (BuildContext context, GoRouterState state) =>
              const ReportModerationScreen(),
        ),
        GoRoute(
          path: adminOfficials,
          builder: (BuildContext context, GoRouterState state) =>
              const OfficialVerificationScreen(),
        ),
        GoRoute(
          path: adminCategories,
          builder: (BuildContext context, GoRouterState state) =>
              const CategoryManagementScreen(),
        ),
        GoRoute(
          path: adminAnalytics,
          builder: (BuildContext context, GoRouterState state) =>
              const SystemAnalyticsScreen(),
        ),
        GoRoute(
          path: profile,
          builder: (BuildContext context, GoRouterState state) =>
              const ProfileScreen(),
        ),
        GoRoute(
          path: editProfile,
          builder: (BuildContext context, GoRouterState state) =>
              const EditProfileScreen(),
        ),
        GoRoute(
          path: '/profile/:username',
          builder: (BuildContext context, GoRouterState state) {
            final username = state.pathParameters['username'];
            return ProfileScreen(targetUsername: username);
          },
        ),
      ],
    );
  }
}
