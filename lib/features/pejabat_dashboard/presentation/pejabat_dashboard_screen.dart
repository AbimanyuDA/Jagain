import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../../feed/domain/models/report_post.dart';
import 'bloc/pejabat_dashboard_bloc.dart';
import 'bloc/pejabat_dashboard_event.dart';
import 'bloc/pejabat_dashboard_state.dart';

class PejabatDashboardScreen extends StatelessWidget {
  const PejabatDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = PejabatDashboardBloc();
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          bloc.add(LoadDashboardStats(
            pejabatWilayah: authState.user.wilayah ?? 'Pusat',
            currentUserId: authState.user.uid,
          ));
        }
        return bloc;
      },
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Pejabat - Jagain'),
      ),
      body: BlocBuilder<PejabatDashboardBloc, PejabatDashboardState>(
        builder: (context, state) {
          if (state is PejabatDashboardLoading ||
              state is PejabatDashboardInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PejabatDashboardError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          final loaded = state as PejabatDashboardLoaded;
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildProfileSection(context),
                const SizedBox(height: 24),
                _buildStatsGrid(context, loaded),
                const SizedBox(height: 24),
                _buildStatusCounters(context, loaded),
                const SizedBox(height: 32),
                _buildCrisisMapCard(context),
                const SizedBox(height: 32),
                _buildKategoriKerusakan(context),
                const SizedBox(height: 24),
                _buildTopKecamatan(context),
                const SizedBox(height: 32),
                _buildTindakanSegera(context, loaded),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
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
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      foregroundDecoration: leftBorderColor != null
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(color: leftBorderColor, width: 4),
              ),
            )
          : null,
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

  Widget _buildStatsGrid(BuildContext context, PejabatDashboardLoaded state) {
    final colorScheme = Theme.of(context).colorScheme;
    final percentage = (state.completionRate * 100).toStringAsFixed(1);

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildStatCard(
                  context: context,
                  label: 'Aduan Stuck',
                  value: '${state.stuckCount}',
                  valueColor: const Color(0xFFF59E0B),
                  leftBorderColor: const Color(0xFFF59E0B),
                  subtitle: '> 7 hari tanpa update',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context: context,
                  label: 'Laporan Aktif',
                  value: '${state.activeCount}',
                  subtitle: 'Total aduan berjalan',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildStatCard(
                  context: context,
                  label: 'Penyelesaian',
                  value: '$percentage%',
                trailing: SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    value: state.completionRate,
                    strokeWidth: 4,
                    backgroundColor: colorScheme.outlineVariant,
                    valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Placeholder for FR-1.1 (Rerata Respons)
            Expanded(
              child: _buildStatCard(
                context: context,
                label: 'Rerata Respons',
                value: '— ',
                subtitle: 'Segera hadir',
              ),
            ),
          ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCounters(
      BuildContext context, PejabatDashboardLoaded state) {
    final colorScheme = Theme.of(context).colorScheme;
    final counts = state.statusCounts;

    final items = [
      ('Menunggu', counts[ReportPostStatus.waitingReview] ?? 0,
          Colors.orange, Colors.orange.withValues(alpha: 0.15)),
      ('Diproses', counts[ReportPostStatus.inProgress] ?? 0,
          Colors.blue, Colors.blue.withValues(alpha: 0.15)),
      ('Selesai', counts[ReportPostStatus.solved] ?? 0,
          Colors.green, Colors.green.withValues(alpha: 0.15)),
      ('Ditolak', counts[ReportPostStatus.rejected] ?? 0,
          colorScheme.error, colorScheme.error.withValues(alpha: 0.15)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status Laporan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: items[i].$4,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${items[i].$2}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: items[i].$3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i].$1,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: items[i].$3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                        valueColor:
                            AlwaysStoppedAnimation(colorScheme.primary),
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
                    ? Border(
                        bottom:
                            BorderSide(color: colorScheme.outlineVariant))
                    : null,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: isTop
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isTop
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
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
                      color: isTop
                          ? colorScheme.error
                          : colorScheme.onSurfaceVariant,
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

  Widget _buildTindakanSegera(
      BuildContext context, PejabatDashboardLoaded state) {
    final colorScheme = Theme.of(context).colorScheme;

    if (state.topStuckReports.isEmpty) {
      return const SizedBox.shrink();
    }

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
        ...state.topStuckReports.map((report) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildUrgentCard(
                context: context,
                priority: report.urgency,
                priorityColor: colorScheme.error,
                priorityBgColor: colorScheme.errorContainer,
                borderColor: colorScheme.error,
                title: report.title,
                timeAgo: report.timeAgo,
                upvotes: report.upvotes,
                status: report.status.label,
              ),
            )),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
