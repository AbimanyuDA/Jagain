import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/report_repository.dart';
import '../../domain/models/report_post.dart';
import 'feed_event.dart';
import 'feed_state.dart';

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  FeedBloc({ReportRepository? repository})
    : _repository = repository ?? ReportRepository(),
      super(FeedInitial()) {
    on<LoadFeed>(_onLoadFeed);
    on<ToggleUpvote>(_onToggleUpvote);
    on<ToggleDownvote>(_onToggleDownvote);
  }

  final ReportRepository _repository;

  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _onLoadFeed(LoadFeed event, Emitter<FeedState> emit) async {
    emit(FeedLoading());
    await emit.forEach<List<ReportPost>>(
      _repository.watchFeed(currentUserId: _currentUserId),
      onData: (posts) => FeedLoaded(posts),
      onError: (error, _) => FeedError('Gagal memuat laporan: $error'),
    );
  }

  Future<void> _onToggleUpvote(
    ToggleUpvote event,
    Emitter<FeedState> emit,
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
    ToggleDownvote event,
    Emitter<FeedState> emit,
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
