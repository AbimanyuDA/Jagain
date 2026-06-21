import 'package:equatable/equatable.dart';

import '../../../feed/domain/models/report_post.dart';

class NearMePost {
  final ReportPost post;
  final double distanceMeters;

  const NearMePost({required this.post, required this.distanceMeters});
}

abstract class NearMeState extends Equatable {
  const NearMeState();

  @override
  List<Object?> get props => [];
}

class NearMeInitial extends NearMeState {}

class NearMeLoadingLocation extends NearMeState {}

class NearMeLocationDenied extends NearMeState {}

class NearMeLoaded extends NearMeState {
  final double userLat;
  final double userLng;
  final List<NearMePost> posts;

  const NearMeLoaded({
    required this.userLat,
    required this.userLng,
    required this.posts,
  });

  @override
  List<Object?> get props => [userLat, userLng, posts];
}

class NearMeError extends NearMeState {
  final String message;

  const NearMeError(this.message);

  @override
  List<Object?> get props => [message];
}
