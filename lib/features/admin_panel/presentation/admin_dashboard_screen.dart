import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../data/admin_repository.dart';
import '../domain/models/admin_stats.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminRepository _repository = AdminRepository();
  late Future<AdminStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _repository.loadGlobalStats();
  }

  Future<void> _refresh() async {
    final future = _repository.loadGlobalStats();
    setState(() => _statsFuture = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Panel - Jagain')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<AdminStats>(
          future: _statsFuture,
          builder: (context, snapshot) {
            final stats = snapshot.data;

            return GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16.0),
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.85,
              children: [
                _buildAdminCard(
                  context,
                  icon: Icons.rate_review,
                  title: 'Moderasi Laporan',
                  subtitle: stats == null
                      ? 'Memuat...'
                      : '${stats.reportsPendingModeration} Menunggu Review',
                  onTap: () => context.push(AppRoutes.adminModeration),
                ),
                _buildAdminCard(
                  context,
                  icon: Icons.supervised_user_circle,
                  title: 'Kelola Akun Pejabat',
                  subtitle: stats == null
                      ? 'Memuat...'
                      : '${stats.pendingOfficialVerifications} Pengajuan Baru',
                  onTap: () => context.push(AppRoutes.adminOfficials),
                ),
                _buildAdminCard(
                  context,
                  icon: Icons.category,
                  title: 'Kelola Kategori',
                  subtitle: 'Tambah & atur kategori laporan',
                  onTap: () => context.push(AppRoutes.adminCategories),
                ),
                _buildAdminCard(
                  context,
                  icon: Icons.analytics,
                  title: 'Analitik Sistem',
                  subtitle: stats == null
                      ? 'Memuat...'
                      : '${stats.totalUsers} pengguna • ${stats.totalReports} laporan',
                  onTap: () => context.push(AppRoutes.adminAnalytics),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAdminCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.indigo),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
