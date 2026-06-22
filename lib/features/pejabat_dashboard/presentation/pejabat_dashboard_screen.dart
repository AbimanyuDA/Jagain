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
                _buildStatusCounters(context, loaded),
                const SizedBox(height: 24),
                _buildStatsGrid(context, loaded),
                const SizedBox(height: 32),
                _buildHeatMapCard(context),
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
    final authState = context.read<AuthBloc>().state;
    final user = (authState as AuthAuthenticated).user;

    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: user.avatarUrl.isNotEmpty
              ? NetworkImage(user.avatarUrl)
              : null,
          child: user.avatarUrl.isEmpty
              ? Text(
                  user.name.isNotEmpty
                      ? user.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(fontSize: 24),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.verified, size: 18, color: colorScheme.primary),
                ],
              ),
              Text(
                '@${user.username}',
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
    Color? borderColor,
    bool showWarning = false,
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor ?? colorScheme.outlineVariant,
          width: borderColor != null ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (showWarning) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.warning_amber_rounded, size: 14, color: borderColor),
                    ],
                  ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistik Laporan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
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
                  label: 'Laporan Aktif',
                  value: '${state.activeCount}',
                  subtitle: 'Total aduan berjalan',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context: context,
                  label: 'Laporan Macet',
                  value: '${state.stuckCount}',
                  valueColor: state.stuckCount > 0 ? const Color(0xFFF59E0B) : null,
                  borderColor: state.stuckCount > 0 ? const Color(0xFFF59E0B) : null,
                  showWarning: state.stuckCount > 0,
                  subtitle: '> 7 hari tanpa update',
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
            Expanded(
              child: _buildStatCard(
                context: context,
                label: 'Rerata Respons',
                value: '— ',
              ),
            ),
          ],
          ),
        ),
        const SizedBox(height: 12),
        _buildKategoriKerusakan(context, state),
        if (state.cityCounts != null) ...[
          const SizedBox(height: 12),
          _buildCityCounts(context, state),
        ],
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

  Widget _buildHeatMapCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Heatmap Laporan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                height: 200,
                color: colorScheme.surfaceContainerHigh,
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
                    label: const Text('Buka Heatmap'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKategoriKerusakan(
      BuildContext context, PejabatDashboardLoaded state) {
    final colorScheme = Theme.of(context).colorScheme;
    final counts = state.categoryCounts;

    if (counts.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = counts.values.fold<int>(0, (sum, v) => sum + v);
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kerusakan per Kategori',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ...sorted.map((entry) {
            final pct = total > 0 ? entry.value / total : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${(pct * 100).toInt()}%  |  ${entry.value}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: colorScheme.surfaceContainer,
                      valueColor:
                          AlwaysStoppedAnimation(colorScheme.primary),
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

  Widget _buildCityCounts(
      BuildContext context, PejabatDashboardLoaded state) {
    final colorScheme = Theme.of(context).colorScheme;
    final counts = state.cityCounts!;

    if (counts.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = counts.values.fold<int>(0, (sum, v) => sum + v);
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Laporan per Kota',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          ...sorted.map((entry) {
            final pct = total > 0 ? entry.value / total : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${(pct * 100).toInt()}%  |  ${entry.value}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: colorScheme.surfaceContainer,
                      valueColor:
                          AlwaysStoppedAnimation(colorScheme.primary),
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
              'Perlu Tindakan! (Terlama)',
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
                priorityColor: colorScheme.onError,
                priorityBgColor: colorScheme.error,
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
        border: Border.all(color: colorScheme.outlineVariant),
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
