import 'package:flutter/material.dart';

class PejabatDashboardScreen extends StatelessWidget {
  const PejabatDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Pejabat - Jagain'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildProfileSection(context),
            const SizedBox(height: 24),
            _buildStatsGrid(context),
            const SizedBox(height: 32),
            _buildCrisisMapCard(context),
            const SizedBox(height: 32),
            _buildKategoriKerusakan(context),
            const SizedBox(height: 24),
            _buildTopKecamatan(context),
            const SizedBox(height: 32),
            _buildTindakanSegera(context),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: implement
        },
        backgroundColor: colorScheme.primary,
        child: Icon(Icons.add, color: colorScheme.onPrimary),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(Icons.account_balance, color: colorScheme.onPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Pemerintah Kota Surabaya',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.verified, size: 18, color: colorScheme.primary),
                ],
              ),
              Text(
                'Verified Institutional Authority',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required String label,
    required String value,
    String? subtitle,
    Color? valueColor,
    Color? leftBorderColor,
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: leftBorderColor != null
            ? Border(left: BorderSide(color: leftBorderColor, width: 4))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? colorScheme.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context: context,
                label: 'Rerata Respons',
                value: '1.8 Hari',
                subtitle: '↓ 0.4 hari lebih cepat',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context: context,
                label: 'Penyelesaian',
                value: '84.5%',
                trailing: SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    value: 0.845,
                    strokeWidth: 4,
                    backgroundColor: colorScheme.outlineVariant,
                    valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context: context,
                label: 'Aduan Stuck',
                value: '12',
                valueColor: const Color(0xFFF59E0B),
                leftBorderColor: const Color(0xFFF59E0B),
                subtitle: '> 3 hari tanpa update',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context: context,
                label: 'Laporan Aktif',
                value: '142',
                subtitle: 'Total aduan berjalan',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCrisisMapCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Peta Krisis\nInfrastruktur',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Surabaya Scope Locked',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 200,
            color: colorScheme.surfaceContainerHigh,
            child: Center(
              child: Icon(
                Icons.location_on,
                size: 32,
                color: colorScheme.primary,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: implement
                },
                icon: const Icon(Icons.map, size: 20),
                label: const Text('Buka Peta Krisis Penuh'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKategoriKerusakan(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final categories = [
      ('Jalan Raya', 0.45),
      ('PJU (Lampu Jalan)', 0.30),
      ('Drainase', 0.25),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kategori Kerusakan Terbanyak',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          ...categories.map((cat) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          cat.$1,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${(cat.$2 * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: cat.$2,
                        minHeight: 8,
                        backgroundColor: colorScheme.surfaceContainer,
                        valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTopKecamatan(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final kecamatanData = [
      ('Sukolilo', '42 Laporan', true),
      ('Gubeng', '35 Laporan', false),
      ('Wonokromo', '20 Laporan', false),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top 3 Kecamatan Krisis',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          ...kecamatanData.asMap().entries.map((entry) {
            final index = entry.key;
            final (name, count, isTop) = entry.value;

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: index < kecamatanData.length - 1
                    ? Border(bottom: BorderSide(color: colorScheme.outlineVariant))
                    : null,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor:
                        isTop ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isTop ? colorScheme.onPrimary : colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    count,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isTop ? colorScheme.error : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTindakanSegera(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.warning, color: colorScheme.error),
            const SizedBox(width: 8),
            Text(
              'Tindakan Segera (Terlama)',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildUrgentCard(
          context: context,
          priority: 'High Priority',
          priorityColor: colorScheme.error,
          priorityBgColor: colorScheme.errorContainer,
          borderColor: colorScheme.error,
          title: 'Jalan Berlubang Dalam - Menur Pumpungan',
          timeAgo: '4 hari lalu',
          upvotes: 84,
          status: 'Menunggu Verifikasi',
        ),
        const SizedBox(height: 16),
        _buildUrgentCard(
          context: context,
          priority: 'Medium Priority',
          priorityColor: colorScheme.secondary,
          priorityBgColor: const Color(0xFFFFDAD7),
          borderColor: colorScheme.secondary,
          title: 'Saluran Buntu - Kalijudan',
          timeAgo: '3 hari lalu',
          upvotes: 62,
          status: 'Menunggu Verifikasi',
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              // TODO: implement
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Lihat Semua Laporan Aktif'),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUrgentCard({
    required BuildContext context,
    required String priority,
    required Color priorityColor,
    required Color priorityBgColor,
    required Color borderColor,
    required String title,
    required String timeAgo,
    required int upvotes,
    required String status,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: priorityBgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  priority,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: priorityColor,
                  ),
                ),
              ),
              Text(
                timeAgo,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.thumb_up, size: 16, color: colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                '$upvotes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.sync, size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}