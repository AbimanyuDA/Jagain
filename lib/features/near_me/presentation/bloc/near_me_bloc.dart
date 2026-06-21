import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../../feed/data/report_repository.dart';
import '../../../feed/domain/models/report_post.dart';
import 'near_me_event.dart';
import 'near_me_state.dart';

class NearMeBloc extends Bloc<NearMeEvent, NearMeState> {
  static const double kNearMeRadiusMeters = 10000;

  NearMeBloc({ReportRepository? repository})
    : _repository = repository ?? ReportRepository(),
      super(NearMeInitial()) {
    on<LoadNearMe>(_onLoadNearMe);
    on<ToggleNearMeUpvote>(_onToggleUpvote);
    on<ToggleNearMeDownvote>(_onToggleDownvote);
  }

  final ReportRepository _repository;

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _onLoadNearMe(
    LoadNearMe event,
    Emitter<NearMeState> emit,
  ) async {
    emit(NearMeLoadingLocation());

    double userLat;
    double userLng;
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        emit(NearMeLocationDenied());
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 8));
      userLat = pos.latitude;
      userLng = pos.longitude;
    } catch (_) {
      emit(NearMeLocationDenied());
      return;
    }

    await emit.forEach<List<ReportPost>>(
      _repository.watchFeed(currentUserId: _currentUserId),
      onData: (posts) {
        final nearby = posts
            .where((p) => p.latitude != null && p.longitude != null)
            .map((p) {
              final distance = Geolocator.distanceBetween(
                userLat,
                userLng,
                p.latitude!,
                p.longitude!,
              );
              return NearMePost(post: p, distanceMeters: distance);
            })
            .where((np) => np.distanceMeters <= kNearMeRadiusMeters)
            .toList()
          ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

        return NearMeLoaded(
          userLat: userLat,
          userLng: userLng,
          posts: nearby,
        );
      },
      onError: (error, _) => NearMeError('Gagal memuat laporan terdekat: $error'),
    );
  }

  Future<void> _onToggleUpvote(
    ToggleNearMeUpvote event,
    Emitter<NearMeState> emit,
  ) async {
    final userId = _currentUserId;
    if (userId == null) return;
    await _repository.toggleVote(
      reportId: event.postId,
      userId: userId,
      action: VoteAction.upvote,
    );
  }

  Future<void> _onToggleDownvote(
    ToggleNearMeDownvote event,
    Emitter<NearMeState> emit,
  ) async {
    final userId = _currentUserId;
    if (userId == null) return;
    await _repository.toggleVote(
      reportId: event.postId,
      userId: userId,
      action: VoteAction.downvote,
    );
  }
}
