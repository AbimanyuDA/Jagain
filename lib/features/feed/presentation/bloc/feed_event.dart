import 'package:equatable/equatable.dart';

abstract class FeedEvent extends Equatable {
  const FeedEvent();

  @override
  List<Object?> get props => [];
}

class LoadFeed extends FeedEvent {}

class ToggleUpvote extends FeedEvent {
  final String postId;

  const ToggleUpvote(this.postId);

  @override
  List<Object?> get props => [postId];
}

class ToggleDownvote extends FeedEvent {
  final String postId;

  const ToggleDownvote(this.postId);

  @override
  List<Object?> get props => [postId];
}
