import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/bloc/auth_bloc.dart';
import '../../auth/presentation/bloc/auth_state.dart';
import '../../feed/domain/models/report_post.dart';
import 'bloc/pejabat_report_list_bloc.dart';
import 'bloc/pejabat_report_list_event.dart';
import 'bloc/pejabat_report_list_state.dart';

enum ReportSortOption {
  newest('Terbaru'),
  oldest('Terlama'),
  mostUpvoted('Upvote Terbanyak'),
  mostCommented('Komentar Terbanyak');

  final String label;
  const ReportSortOption(this.label);
}

class PejabatReportListScreen extends StatefulWidget {
  final ReportPostStatus? initialStatus;

  const PejabatReportListScreen({super.key, this.initialStatus});

  @override
  State<PejabatReportListScreen> createState() =>
      _PejabatReportListScreenState();
}

class _PejabatReportListScreenState extends State<PejabatReportListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = ReportPostStatus.values;

  @override
  void initState() {
    super.initState();
    final initialIndex =
        widget.initialStatus != null ? _tabs.indexOf(widget.initialStatus!) : 0;
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: initialIndex >= 0 ? initialIndex : 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = PejabatReportListBloc();
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          bloc.add(LoadReports(
            pejabatWilayah: authState.user.wilayah ?? 'Pusat',
            currentUserId: authState.user.uid,
          ));
        }
        return bloc;
      },
      child: _ReportListBody(
        tabController: _tabController,
      ),
    );
  }
}

class _ReportListBody extends StatelessWidget {
  final TabController tabController;

  const _ReportListBody({required this.tabController});

  static const _tabs = ReportPostStatus.values;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Laporan'),
        bottom: TabBar(
          controller: tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _tabs.map((s) => Tab(text: s.label)).toList(),
        ),
      ),
      body: BlocBuilder<PejabatReportListBloc, PejabatReportListState>(
        builder: (context, state) {
          if (state is PejabatReportListLoading ||
              state is PejabatReportListInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is PejabatReportListError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          final loaded = state as PejabatReportListLoaded;
          return Column(
            children: [
              _SortBar(currentSort: loaded.sortOption),
              Expanded(
                child: TabBarView(
                  controller: tabController,
                  children: _tabs
                      .map((status) => _ReportListTab(
                            reports: loaded.forStatus(status),
                            status: status,
                          ))
                      .toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SortBar extends StatelessWidget {
  final ReportSortOption currentSort;

  const _SortBar({required this.currentSort});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.sort, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ReportSortOption.values.map((option) {
                  final selected = option == currentSort;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(
                        option.label,
                        style: TextStyle(
                          color: selected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      selected: selected,
                      selectedColor: colorScheme.primary,
                      checkmarkColor: colorScheme.onPrimary,
                      onSelected: (_) {
                        context
                            .read<PejabatReportListBloc>()
                            .add(ChangeSortOption(option));
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportListTab extends StatelessWidget {
  final List<ReportPost> reports;
  final ReportPostStatus status;

  const _ReportListTab({required this.reports, required this.status});

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'Tidak ada laporan ${status.label.toLowerCase()}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reports.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _ReportCard(report: reports[index]),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportPost report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        context.push('/report-detail', extra: report);
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
                    _UrgencyBadge(urgency: report.urgency),
                    const SizedBox(width: 8),
                    _CategoryChip(category: report.category),
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
                Icon(Icons.sync, size: 16, color: colorScheme.onSurfaceVariant),
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

class _UrgencyBadge extends StatelessWidget {
  final String urgency;

  const _UrgencyBadge({required this.urgency});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (Color bg, Color fg) = switch (urgency) {
      'URGENT' => (colorScheme.error, colorScheme.onError),
      _ => (colorScheme.primary, colorScheme.onPrimary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        urgency,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String category;

  const _CategoryChip({required this.category});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
