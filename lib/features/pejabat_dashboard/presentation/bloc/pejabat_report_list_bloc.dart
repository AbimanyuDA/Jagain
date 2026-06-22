import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../feed/data/report_repository.dart';
import '../../../feed/domain/models/report_post.dart';
import '../../data/pejabat_dashboard_repository.dart';
import '../pejabat_report_list_screen.dart';
import 'pejabat_report_list_event.dart';
import 'pejabat_report_list_state.dart';

class PejabatReportListBloc
    extends Bloc<PejabatReportListEvent, PejabatReportListState> {
  PejabatReportListBloc({
    ReportRepository? reportRepository,
  })  : _reportRepository = reportRepository ?? ReportRepository(),
        super(PejabatReportListInitial()) {
    on<LoadReports>(_onLoadReports);
    on<ChangeSortOption>(_onChangeSortOption);
    on<_ReportsUpdated>(_onReportsUpdated);
  }

  final ReportRepository _reportRepository;
  StreamSubscription<List<ReportPost>>? _subscription;
  List<ReportPost> _allReports = [];
  ReportSortOption _currentSort = ReportSortOption.newest;

  Future<void> _onLoadReports(
    LoadReports event,
    Emitter<PejabatReportListState> emit,
  ) async {
    emit(PejabatReportListLoading());
    try {
      final parsed =
          PejabatDashboardRepository.parseWilayah(event.pejabatWilayah);

      final stream = _reportRepository.watchReports(
        provinsi: parsed.level == 'provinsi' ? parsed.provinsi : null,
        wilayah: parsed.level == 'kota' ? parsed.kota : null,
        currentUserId: event.currentUserId,
      );

      await _subscription?.cancel();
      _subscription = stream.listen(
        (reports) => add(_ReportsUpdated(reports)),
      );
    } catch (e) {
      emit(PejabatReportListError(e.toString()));
    }
  }

  void _onReportsUpdated(
    _ReportsUpdated event,
    Emitter<PejabatReportListState> emit,
  ) {
    _allReports = event.reports;
    emit(_buildLoaded());
  }

  void _onChangeSortOption(
    ChangeSortOption event,
    Emitter<PejabatReportListState> emit,
  ) {
    _currentSort = event.sortOption;
    if (_allReports.isNotEmpty) {
      emit(_buildLoaded());
    }
  }

  PejabatReportListLoaded _buildLoaded() {
    final grouped = <ReportPostStatus, List<ReportPost>>{};
    for (final status in ReportPostStatus.values) {
      final filtered =
          _allReports.where((r) => r.status == status).toList();
      _applySort(filtered);
      grouped[status] = filtered;
    }
    return PejabatReportListLoaded(
      reportsByStatus: grouped,
      sortOption: _currentSort,
    );
  }

  void _applySort(List<ReportPost> reports) {
    switch (_currentSort) {
      case ReportSortOption.newest:
        reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case ReportSortOption.oldest:
        reports.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case ReportSortOption.mostUpvoted:
        reports.sort((a, b) => b.upvotes.compareTo(a.upvotes));
      case ReportSortOption.mostCommented:
        reports.sort((a, b) => b.repliesCount.compareTo(a.repliesCount));
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

class _ReportsUpdated extends PejabatReportListEvent {
  final List<ReportPost> reports;

  const _ReportsUpdated(this.reports);

  @override
  List<Object?> get props => [reports];
}
