import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../auth/presentation/bloc/auth_bloc.dart';
import 'pejabat_report_detail_screen.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../../feed/domain/models/report_post.dart';
import '../../stats/presentation/bloc/stats_bloc.dart';
import '../../stats/presentation/bloc/stats_event.dart';
import '../../stats/presentation/bloc/stats_state.dart';
import '../../stats/presentation/widgets/kategori_card.dart';
import '../../stats/presentation/widgets/monthly_trend_card.dart';
import '../../stats/presentation/widgets/responsivitas_card.dart';
import '../../stats/presentation/widgets/stat_count_card.dart';
import '../../stats/presentation/widgets/top_penanganan_kota_card.dart';
import '../data/pejabat_dashboard_repository.dart';
import 'bloc/pejabat_dashboard_bloc.dart';
import 'bloc/pejabat_dashboard_event.dart';
import 'bloc/pejabat_dashboard_state.dart';

class PejabatDashboardScreen extends StatelessWidget {
  const PejabatDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: Text('Not authenticated')),
      );
    }

    final user = authState.user;
    final wilayah = user.wilayah ?? 'Pusat';
    final parsed = PejabatDashboardRepository.parseWilayah(wilayah);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => StatsBloc()
            ..add(LoadStats(provinsi: parsed.provinsi, kota: parsed.kota)),
        ),
        BlocProvider(
          create: (_) => PejabatDashboardBloc()
            ..add(LoadDashboardStats(
              pejabatWilayah: wilayah,
              currentUserId: user.uid,
            )),
        ),
      ],
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Dashboard Pejabat',
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
        builder: (context, statsState) {
          if (statsState is StatsError) {
            return Center(child: Text('Error: ${statsState.message}'));
          }
          if (statsState is! StatsLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildJurisdictionHeader(context),
                const SizedBox(height: 24),
                _buildStatusCounters(context, statsState),
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
                _buildStatsGrid(context, statsState),
                const SizedBox(height: 32),
                BlocBuilder<PejabatDashboardBloc, PejabatDashboardState>(
                  builder: (context, dashState) {
                    if (dashState is PejabatDashboardLoaded) {
                      return _buildTindakanSegera(context, dashState);
                    }
                    if (dashState is PejabatDashboardError) {
                      return Text(
                        'Gagal memuat laporan macet: ${dashState.message}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      );
                    }
                    if (dashState is PejabatDashboardLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
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

  Widget _buildStatsGrid(BuildContext context, StatsLoaded state) {
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
        const SizedBox(height: 12),
        if (state.topKota.isNotEmpty) ...[
          TopPenangananKotaCard(topKota: state.topKota),
          const SizedBox(height: 12),
        ],
        if (state.cityCounts != null && state.cityCounts!.isNotEmpty) ...[
          KategoriCard(
            title: 'Laporan per Kota',
            counts: state.cityCounts!,
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

  Widget _buildStatusCounters(BuildContext context, StatsLoaded state) {
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
