import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/pejabat_dashboard_repository.dart';
import 'pejabat_dashboard_event.dart';
import 'pejabat_dashboard_state.dart';

class PejabatDashboardBloc
    extends Bloc<PejabatDashboardEvent, PejabatDashboardState> {
  PejabatDashboardBloc({
    PejabatDashboardRepository? repository,
  })  : _repository = repository ?? PejabatDashboardRepository(),
        super(PejabatDashboardInitial()) {
    on<LoadDashboardStats>(_onLoadStats);
  }

  final PejabatDashboardRepository _repository;

  Future<void> _onLoadStats(
    LoadDashboardStats event,
    Emitter<PejabatDashboardState> emit,
  ) async {
    emit(PejabatDashboardLoading());
    try {
      final stats = await _repository.loadStats(
        event.pejabatWilayah,
        currentUserId: event.currentUserId,
      );
      emit(PejabatDashboardLoaded(
        statusCounts: stats.statusCounts,
        stuckCount: stats.stuckCount,
        topStuckReports: stats.topStuckReports,
        categoryCounts: stats.categoryCounts,
        cityCounts: stats.cityCounts,
      ));
    } catch (e) {
      emit(PejabatDashboardError(e.toString()));
    }
  }
}