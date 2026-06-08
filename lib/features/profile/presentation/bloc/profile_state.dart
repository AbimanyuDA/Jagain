import 'package:equatable/equatable.dart';
import '../../domain/models/user_profile.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final UserProfile profile;
  final int activeTabIndex;
  final String? redeemSuccessMessage;

  const ProfileLoaded({
    required this.profile,
    this.activeTabIndex = 0,
    this.redeemSuccessMessage,
  });

  ProfileLoaded copyWith({
    UserProfile? profile,
    int? activeTabIndex,
    String? redeemSuccessMessage,
  }) {
    return ProfileLoaded(
      profile: profile ?? this.profile,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      redeemSuccessMessage: redeemSuccessMessage,
    );
  }

  @override
  List<Object?> get props => [profile, activeTabIndex, redeemSuccessMessage];
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}
