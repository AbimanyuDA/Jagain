import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import 'pejabat_report_detail_screen.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../../feed/domain/models/report_post.dart';
import 'bloc/pejabat_dashboard_bloc.dart';
import 'bloc/pejabat_dashboard_event.dart';
import 'bloc/pejabat_dashboard_state.dart';

const _monthAbbreviations = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

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
                _buildJurisdictionHeader(context),
                const SizedBox(height: 24),
                _buildStatusCounters(context, loaded),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push(AppRoutes.pejabatReportList),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.list_alt, size: 18),
                    label: const Text('Lihat Semua Laporan'),
                  ),
                ),
                const SizedBox(height: 24),
                _buildStatsGrid(context, loaded),
                const SizedBox(height: 32),
                // _buildHeatMapCard(context),
                // const SizedBox(height: 32),
                _buildTindakanSegera(context, loaded),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildJurisdictionHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authState = context.read<AuthBloc>().state;
    final user = (authState as AuthAuthenticated).user;
    final wilayah = user.wilayah ?? 'Pusat';

    final parts = wilayah.split(' -> ');
    final String jurisdictionTitle;
    final String jurisdictionSubtitle;

    if (parts.length >= 3) {
      jurisdictionTitle = 'Pemerintah ${parts[0]}';
      jurisdictionSubtitle = parts[1];
    } else if (parts.length == 2) {
      jurisdictionTitle = 'Pemerintah Provinsi ${parts[0]}';
      jurisdictionSubtitle = 'Tingkat Provinsi';
    } else {
      jurisdictionTitle = 'Pemerintah Pusat';
      jurisdictionSubtitle = 'Seluruh Indonesia';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.onPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.account_balance,
              size: 28,
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jurisdictionTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  jurisdictionSubtitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.verified,
            size: 22,
            color: colorScheme.onPrimary.withValues(alpha: 0.8),
          ),
        ],
      ),
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
        color: Colors.white,
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
        _buildResponsivitasCard(context, state),
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
        if (state.topKota.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildTopResolutionKota(context, state),
        ],
        if (state.cityCounts != null) ...[
          const SizedBox(height: 12),
          _buildCityCounts(context, state),
        ],
        _buildKategoriKerusakan(context, state),
        if (state.monthlyTrend.isNotEmpty) ...[
          _buildMonthlyTrendCard(context, state),
          const SizedBox(height: 12),
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
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: GestureDetector(
                    onTap: () => context.push(
                      AppRoutes.pejabatReportList,
                      extra: ReportPostStatus.values[i],
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
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
                ),
              ],
            ],
          ),
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
            color: Colors.white,
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
        color: Colors.white,
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
        color: Colors.white,
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

  Widget _buildResponsivitasCard(
      BuildContext context, PejabatDashboardLoaded state) {
    final colorScheme = Theme.of(context).colorScheme;
    final responsifPct = (state.responsifRate * 100).toStringAsFixed(0);
    final apatisPct = (state.apatisRate * 100).toStringAsFixed(0);
    final isHighPriority = state.apatisRate > 0.10;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Skor Responsivitas',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            width: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    centerSpaceRadius: 60,
                    sectionsSpace: 0,
                    sections: [
                      PieChartSectionData(
                        value: state.responsifRate,
                        color: colorScheme.primary,
                        showTitle: false,
                        radius: 22,
                      ),
                      PieChartSectionData(
                        value: state.apatisRate == 0
                            ? 0.0001
                            : state.apatisRate,
                        color: colorScheme.outlineVariant,
                        showTitle: false,
                        radius: 22,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$responsifPct%',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'RESPONSIF',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$apatisPct%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Apatis',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isHighPriority
                      ? colorScheme.error.withAlpha(30)
                      : const Color(0xFF00A550).withAlpha(30),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  isHighPriority ? 'High Priority' : 'Stabil',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isHighPriority
                        ? colorScheme.error
                        : const Color(0xFF00A550),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyTrendCard(
      BuildContext context, PejabatDashboardLoaded state) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxCount = state.monthlyTrend
        .map((m) => m.count)
        .fold<int>(0, (max, v) => v > max ? v : max);
    final maxY = maxCount == 0 ? 5.0 : (maxCount * 1.2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tren Laporan Bulanan',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= state.monthlyTrend.length) {
                          return const SizedBox.shrink();
                        }
                        final month = state.monthlyTrend[index].month;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _monthAbbreviations[month.month - 1],
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < state.monthlyTrend.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: state.monthlyTrend[i].count.toDouble(),
                          color: colorScheme.primary,
                          width: 18,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _medals = [
    (Icons.workspace_premium, Color(0xFFFFB300)),
    (Icons.workspace_premium, Color(0xFFB0BEC5)),
    (Icons.workspace_premium, Color(0xFFA1887F)),
  ];

  Widget _buildTopResolutionKota(
      BuildContext context, PejabatDashboardLoaded state) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Penanganan Kota/Kabupaten',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < state.topKota.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  if (i < _medals.length)
                    Icon(_medals[i].$1, color: _medals[i].$2, size: 22)
                  else
                    SizedBox(
                      width: 22,
                      child: Text(
                        '${i + 1}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      state.topKota[i].kota,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    '${(state.topKota[i].resolvedRate * 100).toStringAsFixed(1)}% Selesai',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
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
              child: _buildReportCard(context, report),
            )),
      ],
    );
  }

  Widget _buildReportCard(BuildContext context, ReportPost report) {
    final colorScheme = Theme.of(context).colorScheme;

    final (Color urgencyBg, Color urgencyFg) = switch (report.urgency) {
      'URGENT' => (colorScheme.error, colorScheme.onError),
      _ => (colorScheme.primary, colorScheme.onPrimary),
    };

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PejabatReportDetailScreen(post: report),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: urgencyBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        report.urgency,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: urgencyFg,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        report.category,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  report.timeAgo,
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
              report.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  report.upvotes < 0 ? Icons.thumb_down : Icons.thumb_up,
                  size: 16,
                  color: report.upvotes < 0 ? colorScheme.error : colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${report.upvotes.abs()}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: report.upvotes < 0 ? colorScheme.error : colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.chat_bubble_outline,
                    size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  '${report.repliesCount}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.sync,
                    size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  report.status.label,
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
      ),
    );
  }
}
