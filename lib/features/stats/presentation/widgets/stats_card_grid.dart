import 'package:flutter/material.dart';

import '../bloc/stats_state.dart';
import 'kategori_card.dart';
import 'monthly_trend_card.dart';
import 'responsivitas_card.dart';
import 'stat_count_card.dart';
import 'top_penanganan_card.dart';

class StatsCardGrid extends StatelessWidget {
  final StatsLoaded state;
  final bool showHeader;
  final bool showHint;

  const StatsCardGrid({
    super.key,
    required this.state,
    this.showHeader = false,
    this.showHint = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final percentage = (state.completionRate * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) ...[
          Text(
            'Statistik Laporan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
        ],
        ResponsivitasCard(
          responsifRate: state.responsifRate,
          apatisRate: state.apatisRate,
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: StatCountCard(
                  label: 'Laporan Aktif',
                  value: '${state.activeCount}',
                  subtitle: 'Total aduan berjalan',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCountCard(
                  label: 'Laporan Macet',
                  value: '${state.stuckCount}',
                  valueColor: state.stuckCount > 0
                      ? const Color(0xFFF59E0B)
                      : null,
                  borderColor: state.stuckCount > 0
                      ? const Color(0xFFF59E0B)
                      : null,
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
                child: StatCountCard(
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
                child: StatCountCard(
                  label: 'Rerata Respons',
                  value: '— ',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (state.kota == null) ...[
          if (state.topResolution.isNotEmpty) ...[
            TopPenangananCard(
              title: state.provinsi != null
                  ? 'Top Penanganan Kota/Kabupaten'
                  : 'Top Penanganan Provinsi',
              items: state.topResolution,
            ),
            const SizedBox(height: 12),
          ] else if (showHint && state.provinsi == null) ...[
            _TopResolutionHint(),
            const SizedBox(height: 12),
          ],
        ],
        if (state.regionCounts != null && state.regionCounts!.isNotEmpty) ...[
          KategoriCard(
            title: state.provinsi != null
                ? 'Laporan per Kota/Kabupaten'
                : 'Laporan per Provinsi',
            counts: state.regionCounts!,
          ),
          const SizedBox(height: 12),
        ],
        if (state.categoryCounts.isNotEmpty) ...[
          KategoriCard(
            title: 'Kerusakan per Kategori',
            counts: state.categoryCounts,
          ),
          const SizedBox(height: 12),
        ],
        if (state.monthlyTrend.isNotEmpty)
          MonthlyTrendCard(monthlyTrend: state.monthlyTrend),
      ],
    );
  }
}

class _TopResolutionHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
