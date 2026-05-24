import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel - Jagain'),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16.0),
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        children: [
          _buildAdminCard(
            context,
            icon: Icons.rate_review,
            title: 'Moderasi Laporan',
            subtitle: '5 Menunggu Review',
            onTap: () {},
          ),
          _buildAdminCard(
            context,
            icon: Icons.supervised_user_circle,
            title: 'Kelola Akun Pejabat',
            subtitle: '2 Pengajuan Baru',
            onTap: () {},
          ),
          _buildAdminCard(
            context,
            icon: Icons.category,
            title: 'Kelola Kategori',
            subtitle: '6 Kategori Aktif',
            onTap: () {},
          ),
          _buildAdminCard(
            context,
            icon: Icons.analytics,
            title: 'Analitik Sistem',
            subtitle: 'Grafik & Metrik',
            onTap: () {},
          ),
        ],
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
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
