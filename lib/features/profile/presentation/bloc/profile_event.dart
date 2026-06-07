import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
}

class LoadProfile extends ProfileEvent {
  final String? username;
  const LoadProfile({this.username});

  @override
  List<Object> get props => username != null ? [username!] : [];
}

class SwitchProfileTab extends ProfileEvent {
  final int tabIndex;
  const SwitchProfileTab(this.tabIndex);

  @override
  List<Object> get props => [tabIndex];
}

class RedeemPoints extends ProfileEvent {
  final String rewardId;
  const RedeemPoints(this.rewardId);

  @override
  List<Object> get props => [rewardId];
}
