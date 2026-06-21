import 'package:equatable/equatable.dart';

abstract class StatsEvent extends Equatable {
  const StatsEvent();

  @override
  List<Object?> get props => [];
}

/// Memuat statistik untuk region terpilih.
/// [provinsi] dan [kota] null berarti seluruh Indonesia (pusat).
class LoadStats extends StatsEvent {
  final String? provinsi;
  final String? kota;

  const LoadStats({this.provinsi, this.kota});

  @override
  List<Object?> get props => [provinsi, kota];
}
