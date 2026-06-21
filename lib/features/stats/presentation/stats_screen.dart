import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/data/indonesia_regions.dart';
import '../../../core/widgets/region_selector_bottom_sheet.dart';
import 'bloc/stats_bloc.dart';
import 'bloc/stats_event.dart';
import 'bloc/stats_state.dart';

const _monthAbbreviations = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StatsBloc()..add(const LoadStats()),
      child: const _StatsView(),
    );
  }
}

class _StatsView extends StatefulWidget {
  const _StatsView();

  @override
  State<_StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<_StatsView> {
  Future<void> _pickRegion(BuildContext context) async {
    final provinsi = await showRegionSelectorSheet(
      context: context,
      title: 'Pilih Provinsi',
      items: IndonesiaRegions.provinsi,
    );
    if (provinsi == null || !context.mounted) return;

    const allKota = 'Semua Kota/Kabupaten';
    final kotaItems = [allKota, ...IndonesiaRegions.getKota(provinsi)];
    final kota = await showRegionSelectorSheet(
      context: context,
      title: 'Pilih Kota/Kabupaten',
      items: kotaItems,
    );
    if (!context.mounted) return;

    context.read<StatsBloc>().add(
      LoadStats(provinsi: provinsi, kota: kota == allKota ? null : kota),
    );
  }

  void _resetRegion(BuildContext context) {
    context.read<StatsBloc>().add(const LoadStats());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: BlocBuilder<StatsBloc, StatsState>(
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Statistik',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _RegionSelectorRow(
                    state: state,
                    onTap: () => _pickRegion(context),
                    onReset: () => _resetRegion(context),
                  ),
                  const SizedBox(height: 16),
                  if (state is StatsError)
                    Column(
                      children: [
                        Text(
                          state.message,
                          style: TextStyle(color: colorScheme.error),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () =>
                              context.read<StatsBloc>().add(const LoadStats()),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    )
                  else if (state is StatsLoaded)
                    _StatsContent(state: state)
                  else
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RegionSelectorRow extends StatelessWidget {
  final StatsState state;
  final VoidCallback onTap;
  final VoidCallback onReset;

  const _RegionSelectorRow({
    required this.state,
    required this.onTap,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = state is StatsLoaded
        ? (state as StatsLoaded).regionLabel
        : 'Seluruh Indonesia';
    final hasFilter = state is StatsLoaded &&
        ((state as StatsLoaded).provinsi != null);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on, color: colorScheme.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Region',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimaryContainer.withAlpha(180),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            if (hasFilter)
              IconButton(
                icon: Icon(Icons.close, color: colorScheme.primary, size: 18),
                onPressed: onReset,
              ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsContent extends StatelessWidget {
  final StatsLoaded state;

  const _StatsContent({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CivicScoreCard(state: state),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _CountCard(
                icon: Icons.description_outlined,
                label: 'Total Reports',
                value: '${state.total}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _CountCard(
                icon: Icons.check_circle_outline,
                label: 'Resolved',
                value: '${state.resolved}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _MonthlyTrendCard(state: state),
        const SizedBox(height: 16),
        if (state.provinsi != null && state.kota == null)
          _TopResolutionKotaCard(state: state)
        else
          _TopResolutionKotaHint(),
      ],
    );
  }
}

class _CivicScoreCard extends StatelessWidget {
  final StatsLoaded state;

  const _CivicScoreCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final responsifPct = (state.responsifRate * 100).toStringAsFixed(0);
    final apatisPct = (state.apatisRate * 100).toStringAsFixed(0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Civic Engagement Score',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
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
                        value: state.apatisRate == 0 ? 0.0001 : state.apatisRate,
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
                  color: state.isHighPriority
                      ? colorScheme.errorContainer
                      : const Color(0xFF00A550).withAlpha(30),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  state.isHighPriority ? 'High Priority' : 'Stabil',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: state.isHighPriority
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
}

class _CountCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CountCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.primary, size: 22),
          const SizedBox(height: 10),
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
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyTrendCard extends StatelessWidget {
  final StatsLoaded state;

  const _MonthlyTrendCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final maxCount = state.monthlyTrend
        .map((m) => m.count)
        .fold<int>(0, (max, v) => v > max ? v : max);
    final maxY = maxCount == 0 ? 5.0 : (maxCount * 1.2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bulanan Report Trends',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
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
}

class _TopResolutionKotaCard extends StatelessWidget {
  final StatsLoaded state;

  const _TopResolutionKotaCard({required this.state});

  static const _medals = [
    (Icons.workspace_premium, Color(0xFFFFB300), 'Gold'),
    (Icons.workspace_premium, Color(0xFFB0BEC5), 'Silver'),
    (Icons.workspace_premium, Color(0xFFA1887F), 'Bronze'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (state.topKota.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Text(
          'Belum ada data laporan di provinsi ini.',
          style: TextStyle(color: colorScheme.onSurfaceVariant),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Resolution Kota/Kabupaten',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
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
                    '${(state.topKota[i].resolvedRate * 100).toStringAsFixed(1)}% Resolved',
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
}

class _TopResolutionKotaHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Pilih provinsi pada Selected Region untuk lihat ranking kota/kabupaten.',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
