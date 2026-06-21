import 'package:flutter/material.dart';

import '../data/admin_repository.dart';
import '../domain/models/admin_stats.dart';

const _navy = Color(0xFF0F1E36);

class SystemAnalyticsScreen extends StatefulWidget {
  const SystemAnalyticsScreen({super.key});

  @override
  State<SystemAnalyticsScreen> createState() => _SystemAnalyticsScreenState();
}

class _SystemAnalyticsScreenState extends State<SystemAnalyticsScreen> {
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
      appBar: AppBar(title: const Text('Analitik Sistem')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<AdminStats>(
          future: _statsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Text('Gagal memuat statistik: ${snapshot.error}'),
                  ),
                ],
              );
            }

            final stats = snapshot.data!;
            final cards = [
              _StatCardData(
                'Total Pengguna',
                stats.totalUsers,
                Icons.group_rounded,
                const Color(0xFF2E5BFF),
              ),
              _StatCardData(
                'Total Laporan',
                stats.totalReports,
                Icons.article_rounded,
                const Color(0xFF7B1FA2),
              ),
              _StatCardData(
                'Laporan Selesai',
                stats.reportsSolved,
                Icons.check_circle_rounded,
                const Color(0xFF00A550),
              ),
              _StatCardData(
                'Menunggu Moderasi',
                stats.reportsPendingModeration,
                Icons.rate_review_rounded,
                const Color(0xFFFF8C00),
              ),
              _StatCardData(
                'Pengajuan Pejabat',
                stats.pendingOfficialVerifications,
                Icons.supervised_user_circle_rounded,
                const Color(0xFFD32F2F),
              ),
            ];

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.15,
              ),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                return Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(card.icon, color: card.color, size: 28),
                        const Spacer(),
                        Text(
                          '${card.value}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: _navy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card.label,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _StatCardData {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCardData(this.label, this.value, this.icon, this.color);
}
