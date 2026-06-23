import 'package:equatable/equatable.dart';

abstract class NearMeEvent extends Equatable {
  const NearMeEvent();

  @override
  List<Object?> get props => [];
}

class LoadNearMe extends NearMeEvent {}

class ToggleNearMeUpvote extends NearMeEvent {
  final String postId;

  const ToggleNearMeUpvote(this.postId);

  @override
  List<Object?> get props => [postId];
}

class ToggleNearMeDownvote extends NearMeEvent {
  final String postId;

  const ToggleNearMeDownvote(this.postId);

  @override
  List<Object?> get props => [postId];
}
