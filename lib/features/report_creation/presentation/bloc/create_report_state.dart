import 'package:equatable/equatable.dart';

abstract class CreateReportState extends Equatable {
  const CreateReportState();

  @override
  List<Object?> get props => [];
}

class CreateReportInitial extends CreateReportState {}

class CreateReportSubmitting extends CreateReportState {}

class CreateReportSuccess extends CreateReportState {
  final String reportId;

  const CreateReportSuccess(this.reportId);

  @override
  List<Object?> get props => [reportId];
}

class CreateReportError extends CreateReportState {
  final String message;

  const CreateReportError(this.message);

  @override
  List<Object?> get props => [message];
}
