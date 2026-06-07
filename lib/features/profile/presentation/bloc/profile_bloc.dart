import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/profile_repository.dart';
import '../../domain/models/user_profile.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({ProfileRepository? repository})
    : _repository = repository ?? ProfileRepository(),
      super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<SwitchProfileTab>(_onSwitchProfileTab);
    on<RedeemPoints>(_onRedeemPoints);
    on<ToggleFollow>(_onToggleFollow);
  }

  final ProfileRepository _repository;

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _onLoadProfile(
    LoadProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    try {
      final profile = await _repository.loadProfile(
        username: event.username,
        viewerId: _currentUserId,
      );
      emit(ProfileLoaded(profile: profile));
    } catch (e) {
      emit(ProfileError('Gagal memuat profil: $e'));
    }
  }

  void _onSwitchProfileTab(SwitchProfileTab event, Emitter<ProfileState> emit) {
    if (state is ProfileLoaded) {
      emit((state as ProfileLoaded).copyWith(activeTabIndex: event.tabIndex));
    }
  }

  Future<void> _onToggleFollow(
    ToggleFollow event,
    Emitter<ProfileState> emit,
  ) async {
    final viewerId = _currentUserId;
    if (state is! ProfileLoaded || viewerId == null) return;

    final currentState = state as ProfileLoaded;
    final profile = currentState.profile;
    if (profile.id == viewerId) return;

    final wasFollowing = profile.isFollowing;
    final optimisticProfile = profile.copyWith(
      isFollowing: !wasFollowing,
      followersCount: profile.followersCount + (wasFollowing ? -1 : 1),
    );
    emit(currentState.copyWith(profile: optimisticProfile));

    try {
      await _repository.toggleFollow(
        followerId: viewerId,
        followeeId: profile.id,
      );
    } catch (_) {
      emit(currentState.copyWith(profile: profile));
    }
  }

  Future<void> _onRedeemPoints(
    RedeemPoints event,
    Emitter<ProfileState> emit,
  ) async {
    final userId = _currentUserId;
    if (state is! ProfileLoaded || userId == null) return;

    final currentState = state as ProfileLoaded;
    final reward = ProfileRepository.rewards.firstWhere(
      (r) => r.id == event.rewardId,
    );
    final newPoints =
        currentState.profile.availablePointsForRedeem - reward.pointsCost;
    if (newPoints < 0) return;

    final updatedProfile = currentState.profile.copyWith(
      availablePointsForRedeem: newPoints,
    );
    emit(
      currentState.copyWith(
        profile: updatedProfile,
        redeemSuccessMessage: '${reward.name} berhasil ditukar! 🎉',
      ),
    );

    try {
      await _repository.redeemReward(
        userId: userId,
        rewardId: reward.id,
        pointsCost: reward.pointsCost,
      );
    } catch (_) {
      emit(
        currentState.copyWith(
          profile: currentState.profile,
          redeemSuccessMessage: null,
        ),
      );
    }
  }

  List<RedeemReward> get rewards => ProfileRepository.rewards;
}
