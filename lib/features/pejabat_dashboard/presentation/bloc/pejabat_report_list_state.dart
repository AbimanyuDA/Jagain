import 'package:equatable/equatable.dart';

import '../../../feed/domain/models/report_post.dart';
import '../pejabat_report_list_screen.dart';

abstract class PejabatReportListState extends Equatable {
  const PejabatReportListState();

  @override
  List<Object?> get props => [];
}

class PejabatReportListInitial extends PejabatReportListState {}

class PejabatReportListLoading extends PejabatReportListState {}

class PejabatReportListLoaded extends PejabatReportListState {
  final Map<ReportPostStatus, List<ReportPost>> reportsByStatus;
  final ReportSortOption sortOption;

  const PejabatReportListLoaded({
    required this.reportsByStatus,
    required this.sortOption,
  });

  List<ReportPost> forStatus(ReportPostStatus status) =>
      reportsByStatus[status] ?? const [];

  @override
  List<Object?> get props => [reportsByStatus, sortOption];
}

class PejabatReportListError extends PejabatReportListState {
  final String message;

  const PejabatReportListError(this.message);

  @override
  List<Object?> get props => [message];
}
