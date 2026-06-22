import 'package:equatable/equatable.dart';

import '../pejabat_report_list_screen.dart';

abstract class PejabatReportListEvent extends Equatable {
  const PejabatReportListEvent();

  @override
  List<Object?> get props => [];
}

class LoadReports extends PejabatReportListEvent {
  final String pejabatWilayah;
  final String? currentUserId;

  const LoadReports({
    required this.pejabatWilayah,
    this.currentUserId,
  });

  @override
  List<Object?> get props => [pejabatWilayah, currentUserId];
}

class ChangeSortOption extends PejabatReportListEvent {
  final ReportSortOption sortOption;

  const ChangeSortOption(this.sortOption);

  @override
  List<Object?> get props => [sortOption];
}
