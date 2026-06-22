import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/indonesia_regions.dart';
import '../../../core/widgets/region_selector_bottom_sheet.dart';
import 'bloc/stats_bloc.dart';
import 'bloc/stats_event.dart';
import 'bloc/stats_state.dart';
import 'widgets/kategori_card.dart';
import 'widgets/monthly_trend_card.dart';
import 'widgets/responsivitas_card.dart';
import 'widgets/stat_count_card.dart';
import 'widgets/top_penanganan_kota_card.dart';

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
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.add, color: colorScheme.onSurface),
          onPressed: () => context.push('/create-report'),
        ),
        automaticallyImplyLeading: false,
        title: Text(
          'Statistik',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: BlocBuilder<StatsBloc, StatsState>(
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
    final colorScheme = Theme.of(context).colorScheme;
    final percentage = (state.completionRate * 100).toStringAsFixed(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsivitasCard(
          responsifRate: state.responsifRate,
          apatisRate: state.apatisRate,
        ),
        const SizedBox(height: 16),
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
        const SizedBox(height: 16),
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
                      valueColor:
                          AlwaysStoppedAnimation(colorScheme.primary),
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
        const SizedBox(height: 16),
        if (state.monthlyTrend.isNotEmpty) ...[
          MonthlyTrendCard(monthlyTrend: state.monthlyTrend),
          const SizedBox(height: 16),
        ],
        if (state.categoryCounts.isNotEmpty) ...[
          KategoriCard(
            title: 'Kerusakan per Kategori',
            counts: state.categoryCounts,
          ),
          const SizedBox(height: 16),
        ],
        if (state.cityCounts != null && state.cityCounts!.isNotEmpty) ...[
          KategoriCard(
            title: 'Laporan per Kota',
            counts: state.cityCounts!,
          ),
          const SizedBox(height: 16),
        ],
        if (state.provinsi != null && state.kota == null) ...[
          if (state.topKota.isNotEmpty)
            TopPenangananKotaCard(topKota: state.topKota)
          else
            _TopResolutionKotaHint(),
        ] else if (state.provinsi == null)
          _TopResolutionKotaHint(),
      ],
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
