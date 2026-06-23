import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../feed/data/report_repository.dart';
import '../../data/pejabat_dashboard_repository.dart';
import 'pejabat_dashboard_event.dart';
import 'pejabat_dashboard_state.dart';

class PejabatDashboardBloc
    extends Bloc<PejabatDashboardEvent, PejabatDashboardState> {
  PejabatDashboardBloc({
    ReportRepository? reportRepository,
  })  : _reportRepository = reportRepository ?? ReportRepository(),
        super(PejabatDashboardInitial()) {
    on<LoadStuckReports>(_onLoadStats);
  }

  final ReportRepository _reportRepository;

  Future<void> _onLoadStats(
    LoadStuckReports event,
    Emitter<PejabatDashboardState> emit,
  ) async {
    emit(PejabatDashboardLoading());
    try {
      final parsed =
          PejabatDashboardRepository.parseWilayah(event.pejabatWilayah);
      final stuckReports = await _reportRepository.getStuck(
        provinsi: parsed.level == 'provinsi' ? parsed.provinsi : null,
        wilayah: parsed.level == 'kota' ? parsed.kota : null,
        currentUserId: event.currentUserId,
      );
      emit(PejabatDashboardLoaded(
        topStuckReports: stuckReports,
      ));
    } catch (e) {
      emit(PejabatDashboardError(e.toString()));
    }
  }
}
