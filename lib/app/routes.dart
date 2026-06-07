import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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

class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRoutes {
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

  static final GoRouter router = GoRouter(
    initialLocation: feed,
    refreshListenable: _GoRouterRefreshStream(
      FirebaseAuth.instance.authStateChanges(),
    ),
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final isAuthRoute =
          state.matchedLocation == login || state.matchedLocation == register;

      if (!isLoggedIn) return isAuthRoute ? null : login;
      if (isAuthRoute) {
        final isAdding = state.uri.queryParameters['adding'] == 'true';
        if (isAdding) return null;
        return feed;
      }
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
