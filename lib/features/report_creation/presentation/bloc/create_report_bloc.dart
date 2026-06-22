import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../feed/data/report_repository.dart';
import 'create_report_event.dart';
import 'create_report_state.dart';

class CreateReportBloc extends Bloc<CreateReportEvent, CreateReportState> {
  CreateReportBloc({ReportRepository? repository})
    : _repository = repository ?? ReportRepository(),
      super(CreateReportInitial()) {
    on<SubmitReportRequested>(_onSubmitRequested);
  }

  final ReportRepository _repository;

  Future<void> _onSubmitRequested(
    SubmitReportRequested event,
    Emitter<CreateReportState> emit,
  ) async {
    emit(CreateReportSubmitting());
    try {
      final reportId = await _repository.submitReport(
        author: event.author,
        title: event.title,
        description: event.description,
        category: event.category,
        urgency: event.urgency,
        images: event.images,
        latitude: event.latitude,
        longitude: event.longitude,
        wilayah: event.wilayah,
        provinsi: event.provinsi,
      );
      emit(CreateReportSuccess(reportId));
    } catch (e) {
      emit(CreateReportError('Gagal mengirim laporan: $e'));
    }
  }
}
