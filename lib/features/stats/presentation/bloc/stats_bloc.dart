import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/stats_repository.dart';
import 'stats_event.dart';
import 'stats_state.dart';

class StatsBloc extends Bloc<StatsEvent, StatsState> {
  StatsBloc({
    StatsRepository? statsRepository,
  }) : _statsRepository = statsRepository ?? StatsRepository(),
       super(StatsInitial()) {
    on<LoadStats>(_onLoadStats);
  }

  final StatsRepository _statsRepository;

  Future<void> _onLoadStats(LoadStats event, Emitter<StatsState> emit) async {
    emit(StatsLoading());
    try {
      final stats = await _statsRepository.loadStats(
        provinsi: event.kota == null ? event.provinsi : null,
        wilayah: event.kota,
      );

      emit(
        StatsLoaded(
          provinsi: event.provinsi,
          kota: event.kota,
          statusCounts: stats.statusCounts,
          stuckCount: stats.stuckCount,
          topResolution: stats.topResolution,
          monthlyTrend: stats.monthlyTrend,
          categoryCounts: stats.categoryCounts,
          regionCounts: stats.regionCounts,
        ),
      );
    } catch (e) {
      emit(StatsError('Gagal memuat statistik: $e'));
    }
  }
}
