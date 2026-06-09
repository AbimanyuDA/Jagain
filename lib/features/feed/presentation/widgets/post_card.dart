import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../data/comment_repository.dart';
import '../../domain/models/comment.dart';
import '../../domain/models/report_post.dart';

class PostCard extends StatefulWidget {
  final ReportPost post;
  final VoidCallback onUpvotePressed;
  final VoidCallback onDownvotePressed;

  const PostCard({
    super.key,
    required this.post,
    required this.onUpvotePressed,
    required this.onDownvotePressed,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  int _currentImageIndex = 0;
  String? _fetchedAvatarUrl;
  bool _isFetchingAvatar = false;

  @override
  void initState() {
    super.initState();
    _fetchAvatarIfNeeded();
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.post.userAvatarUrl != oldWidget.post.userAvatarUrl ||
        widget.post.authorId != oldWidget.post.authorId) {
      _fetchedAvatarUrl = null;
      _fetchAvatarIfNeeded();
    }
  }

  Future<void> _fetchAvatarIfNeeded() async {
    if (widget.post.userAvatarUrl.isEmpty && !_isFetchingAvatar) {
      _isFetchingAvatar = true;
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.post.authorId)
            .get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (mounted) {
            setState(() {
              _fetchedAvatarUrl = data['avatarUrl'] ?? '';
            });
          }
        }
      } catch (e) {
        print('Error fetching fallback avatar: $e');
      } finally {
        _isFetchingAvatar = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUrgent = widget.post.urgency == 'URGENT';

    final authState = context.watch<AuthBloc>().state;
    final currentUser = authState is AuthAuthenticated ? authState.user : null;
    final isCurrentUser = currentUser != null && currentUser.uid == widget.post.authorId;

    final displayUserName = isCurrentUser ? currentUser.username : widget.post.userName;
    final displayUserAvatar = isCurrentUser 
        ? currentUser.avatarUrl 
        : (widget.post.userAvatarUrl.isNotEmpty 
            ? widget.post.userAvatarUrl 
            : (_fetchedAvatarUrl ?? ''));

    String displayUserBadge = widget.post.userBadge;
    if (isCurrentUser) {
      if (currentUser.role == UserRole.official) {
        displayUserBadge = 'Pejabat';
      } else if (currentUser.role == UserRole.admin) {
        displayUserBadge = 'Admin';
      } else if (currentUser.isVerified) {
        displayUserBadge = 'Verified';
      } else {
        displayUserBadge = 'Citizen Reporter';
      }
    }

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      context.push('/profile/$displayUserName');
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: displayUserAvatar.isNotEmpty
                              ? NetworkImage(displayUserAvatar)
                              : null,
                          child: displayUserAvatar.isEmpty
                              ? const Icon(Icons.person, color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayUserName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    widget.post.timeAgo,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '•',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    displayUserBadge,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: displayUserBadge == 'Verified'
                                          ? Colors.green.shade700
                                          : Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.grey),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          AspectRatio(
            aspectRatio: 4 / 5,
            child: Stack(
              children: [
                if (widget.post.imageUrls != null &&
                    widget.post.imageUrls!.length > 1)
                  PageView.builder(
                    itemCount: widget.post.imageUrls!.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return widget.post.imageUrls![index].isNotEmpty
                          ? Image.network(
                              widget.post.imageUrls![index],
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                    },
                  )
                else
                  widget.post.imageUrl.isNotEmpty
                      ? Image.network(
                          widget.post.imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        ),

                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isUrgent
                          ? const Color(0xFFD32F2F)
                          : const Color(0xFF2E5BFF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${widget.post.category} • ${widget.post.urgency}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                if (widget.post.imageUrls != null &&
                    widget.post.imageUrls!.length > 1)
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.post.imageUrls!.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: _currentImageIndex == index ? 8 : 5,
                          height: _currentImageIndex == index ? 8 : 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentImageIndex == index
                                ? Colors.white
                                : Colors.white.withAlpha(128),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(26),
                                blurRadius: 1,
                                offset: const Offset(0, 0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_upward,
                              size: 20,
                              color: widget.post.isUpvoted
                                  ? theme.colorScheme.primary
                                  : Colors.black87,
                            ),
                            onPressed: widget.onUpvotePressed,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                          Text(
                            '${widget.post.upvotes}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: widget.post.isUpvoted
                                  ? theme.colorScheme.primary
                                  : Colors.black87,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.arrow_downward,
                              size: 20,
                              color: widget.post.isDownvoted
                                  ? Colors.red
                                  : Colors.black87,
                            ),
                            onPressed: widget.onDownvotePressed,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Flexible(
                      child: InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.build_circle_outlined,
                                size: 18,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${widget.post.updatesCount} Updates',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    Flexible(
                      child: InkWell(
                        onTap: () => _showCommentBottomSheet(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.chat_bubble_outline,
                                size: 18,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${widget.post.repliesCount} Replies',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Text(
                  widget.post.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F1E36),
                  ),
                ),
                const SizedBox(height: 6),

                Text(
                  widget.post.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCommentBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _CommentSheetContent(post: widget.post);
      },
    );
  }
}

class _CommentSheetContent extends StatefulWidget {
  final ReportPost post;
  const _CommentSheetContent({required this.post});

  @override
  State<_CommentSheetContent> createState() => _CommentSheetContentState();
}

class _CommentSheetContentState extends State<_CommentSheetContent> {
  final TextEditingController _commentController = TextEditingController();

  final CommentRepository _repository = CommentRepository();

  static const List<String> _quickEmojis = [
    '❤️',
    '🙌',
    '🔥',
    '👏',
    '😢',
    '😍',
    '😮',
    '😂',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment(UserModel? author) {
    final text = _commentController.text.trim();
    if (text.isEmpty || author == null) return;

    _commentController.clear();
    setState(() {});
    _repository.addComment(
      reportId: widget.post.id,
      author: author,
      text: text,
    );
  }

  void _toggleLike(Comment comment, String? userId) {
    if (userId == null) return;
    _repository.toggleLike(
      reportId: widget.post.id,
      commentId: comment.id,
      userId: userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final currentUser = authState is AuthAuthenticated ? authState.user : null;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: const [
                SizedBox(width: 40),
                Expanded(
                  child: Center(
                    child: Text(
                      'Komentar',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 40),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: StreamBuilder<List<Comment>>(
              stream: _repository.watchComments(widget.post.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data ?? const [];
                if (comments.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada komentar. Jadilah yang pertama!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final isLiked = comment.isLikedBy(currentUserId);
                    final isCommentAuthorCurrentUser = currentUser != null && currentUser.uid == comment.authorId;

                    final commentAuthorUsername = isCommentAuthorCurrentUser ? currentUser.username : comment.authorUsername;
                    final commentAuthorAvatar = isCommentAuthorCurrentUser ? currentUser.avatarUrl : comment.authorAvatarUrl;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: commentAuthorAvatar.isNotEmpty
                                ? NetworkImage(commentAuthorAvatar)
                                : null,
                            child: commentAuthorAvatar.isEmpty
                                ? Text(
                                    commentAuthorUsername.isNotEmpty
                                        ? commentAuthorUsername[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      commentAuthorUsername,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    if (comment.isOfficial) ...[
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.verified_rounded,
                                        color: Color(0xFF2E5BFF),
                                        size: 13,
                                      ),
                                    ],
                                    const SizedBox(width: 8),
                                    Text(
                                      comment.timeAgo,
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (comment.isPinned) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        '•  Disematkan',
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  comment.text,
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    color: Colors.black87,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () =>
                                      _toggleLike(comment, currentUserId),
                                  child: Icon(
                                    isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border_rounded,
                                    size: 14,
                                    color: isLiked
                                        ? Colors.red
                                        : Colors.grey.shade400,
                                  ),
                                ),
                                if (comment.likeCount > 0) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '${comment.likeCount}',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Divider(height: 1, color: Colors.grey.shade200, thickness: 0.5),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _quickEmojis.map((emoji) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _commentController.text += emoji;
                    });
                  },
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                );
              }).toList(),
            ),
          ),

          Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            color: Colors.white,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: (currentUser?.avatarUrl.isNotEmpty ?? false)
                      ? NetworkImage(currentUser!.avatarUrl)
                      : null,
                  child: (currentUser?.avatarUrl.isEmpty ?? true)
                      ? Text(
                          (currentUser?.name.isNotEmpty ?? false)
                              ? currentUser!.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            onChanged: (text) {
                              setState(() {});
                            },
                            style: const TextStyle(fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Gabung dengan percakapan...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                            ),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _submitComment(currentUser),
                          ),
                        ),
                        if (_commentController.text.trim().isEmpty)
                          Icon(
                            Icons.sentiment_satisfied_alt_rounded,
                            color: Colors.grey.shade600,
                            size: 20,
                          )
                        else
                          GestureDetector(
                            onTap: () => _submitComment(currentUser),
                            child: const Text(
                              'Kirim',
                              style: TextStyle(
                                color: Color(0xFF2E5BFF),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
