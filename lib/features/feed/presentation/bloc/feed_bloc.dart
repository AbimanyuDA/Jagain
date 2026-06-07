import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/report_post.dart';
import 'feed_event.dart';
import 'feed_state.dart';

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  // Simpan data di memori untuk demo / sebelum integrasi database
  final List<ReportPost> _mockPosts = [
    const ReportPost(
      id: 'post_1',
      userName: 'aditya_wijaya',
      userAvatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
      userBadge: 'Verified',
      timeAgo: '2h ago',
      title: 'Lubang Jalan di Jalan Merdeka',
      description: 'Large pothole causing significant traffic delays near the central square. Motorists...',
      imageUrl: 'https://images.unsplash.com/photo-1515162305285-0293e4767cc2?w=600',
      imageUrls: [
        'https://images.unsplash.com/photo-1515162305285-0293e4767cc2?w=600',
        'https://images.unsplash.com/photo-1599740831146-80cf84dd141b?w=600',
        'https://images.unsplash.com/photo-1584467541268-b040f83be3fd?w=600',
      ],
      category: 'JALAN',
      urgency: 'URGENT',
      upvotes: 142,
      updatesCount: 12,
      repliesCount: 8,
    ),
    const ReportPost(
      id: 'post_2',
      userName: 'sitiaminah',
      userAvatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      userBadge: 'Citizen Reporter',
      timeAgo: '5h ago',
      title: 'Lampu PJU Padam di Gatsu',
      description: 'Three street lamps are out in a row on Gatot Subroto street, creating a dark zon...',
      imageUrl: 'https://images.unsplash.com/photo-1509024640742-b67bf6b45084?w=600',
      category: 'PJU',
      urgency: 'NORMAL',
      upvotes: 45,
      updatesCount: 3,
      repliesCount: 2,
    ),
  ];

  FeedBloc() : super(FeedInitial()) {
    on<LoadFeed>(_onLoadFeed);
    on<ToggleUpvote>(_onToggleUpvote);
    on<ToggleDownvote>(_onToggleDownvote);
  }

  void _onLoadFeed(LoadFeed event, Emitter<FeedState> emit) async {
    emit(FeedLoading());
    // Simulasi loading jaringan
    await Future.delayed(const Duration(milliseconds: 500));
    emit(FeedLoaded(List.from(_mockPosts)));
  }

  void _onToggleUpvote(ToggleUpvote event, Emitter<FeedState> emit) {
    if (state is FeedLoaded) {
      final currentPosts = (state as FeedLoaded).posts;
      final updatedPosts = currentPosts.map((post) {
        if (post.id == event.postId) {
          final isUpvoted = !post.isUpvoted;
          final isDownvoted = false; // Mematikan downvote jika upvote dinyalakan
          
          int diff = 0;
          if (isUpvoted) {
            diff += 1;
            if (post.isDownvoted) diff += 0; // Downvote tidak mengurangi upvote secara absolut, atau sesuaikan aturan bisnis
          } else {
            diff -= 1;
          }

          return post.copyWith(
            upvotes: post.upvotes + diff,
            isUpvoted: isUpvoted,
            isDownvoted: isDownvoted,
          );
        }
        return post;
      }).toList();
      emit(FeedLoaded(updatedPosts));
    }
  }

  void _onToggleDownvote(ToggleDownvote event, Emitter<FeedState> emit) {
    if (state is FeedLoaded) {
      final currentPosts = (state as FeedLoaded).posts;
      final updatedPosts = currentPosts.map((post) {
        if (post.id == event.postId) {
          final isDownvoted = !post.isDownvoted;
          final isUpvoted = false; // Mematikan upvote jika downvote dinyalakan
          
          int diff = 0;
          if (post.isUpvoted) {
            diff -= 1;
          }

          return post.copyWith(
            upvotes: post.upvotes + diff,
            isUpvoted: isUpvoted,
            isDownvoted: isDownvoted,
          );
        }
        return post;
      }).toList();
      emit(FeedLoaded(updatedPosts));
    }
  }
}
