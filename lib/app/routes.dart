import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/feed/presentation/feed_screen.dart';
import '../features/report_creation/presentation/create_report_screen.dart';
import '../features/pejabat_dashboard/presentation/pejabat_dashboard_screen.dart';
import '../features/admin_panel/presentation/admin_dashboard_screen.dart';
import '../features/profile/presentation/profile_screen.dart';

class AppRoutes {
  // Routes Names
  static const String login = '/login';
  static const String register = '/register';
  static const String feed = '/';
  static const String createReport = '/create-report';
  static const String pejabatDashboard = '/pejabat';
  static const String adminDashboard = '/admin';
  static const String profile = '/profile';

  static final GoRouter router = GoRouter(
    initialLocation: feed,
    routes: [
      GoRoute(
        path: feed,
        builder: (BuildContext context, GoRouterState state) => const FeedScreen(),
      ),
      GoRoute(
        path: login,
        builder: (BuildContext context, GoRouterState state) => const LoginScreen(),
      ),
      GoRoute(
        path: register,
        builder: (BuildContext context, GoRouterState state) => const RegisterScreen(),
      ),
      GoRoute(
        path: createReport,
        builder: (BuildContext context, GoRouterState state) => const CreateReportScreen(),
      ),
      GoRoute(
        path: pejabatDashboard,
        builder: (BuildContext context, GoRouterState state) => const PejabatDashboardScreen(),
      ),
      GoRoute(
        path: adminDashboard,
        builder: (BuildContext context, GoRouterState state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: profile,
        builder: (BuildContext context, GoRouterState state) => const ProfileScreen(),
      ),
    ],
  );
}
