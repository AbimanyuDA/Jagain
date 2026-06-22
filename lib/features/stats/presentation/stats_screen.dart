import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/indonesia_regions.dart';
import '../../../core/widgets/region_selector_bottom_sheet.dart';
import 'bloc/stats_bloc.dart';
import 'bloc/stats_event.dart';
import 'bloc/stats_state.dart';
import 'widgets/stats_card_grid.dart';

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
    return StatsCardGrid(state: state, showHint: true);
  }
}
