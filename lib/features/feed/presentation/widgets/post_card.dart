import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../../core/widgets/app_network_image.dart';
import '../../../auth/domain/user_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/models/report_post.dart';
import 'comments_section.dart';

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
        debugPrint('Error fetching fallback avatar: $e');
      } finally {
        _isFetchingAvatar = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUrgent = widget.post.urgency == 'URGENT';

    final authState = context.watch<AuthBloc>().state;
    final currentUser = authState is AuthAuthenticated ? authState.user : null;
    final isCurrentUser =
        currentUser != null && currentUser.uid == widget.post.authorId;

    final displayUserName = isCurrentUser
        ? currentUser.username
        : widget.post.userName;
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
      color: colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 8),
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
                          backgroundColor: colorScheme.surfaceContainer,
                          backgroundImage: displayUserAvatar.isNotEmpty
                              ? CachedNetworkImageProvider(displayUserAvatar)
                              : null,
                          child: displayUserAvatar.isEmpty
                              ? Icon(
                                  Icons.person,
                                  color: colorScheme.onSurfaceVariant,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayUserName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    widget.post.timeAgo,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '•',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    displayUserBadge,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: displayUserBadge == 'Verified'
                                          ? Colors.green.shade600
                                          : colorScheme.primary,
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
                  icon: Icon(
                    Icons.more_horiz,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: () => context.push('/report-detail', extra: widget.post),
            child: AspectRatio(
              aspectRatio: 4 / 5,
              child: Stack(
                children: [
                  if (widget.post.imageUrls != null &&
                      widget.post.imageUrls!.length > 1)
                    GestureDetector(
                      // Claim horizontal drag early so the inner image swipe
                      // is handled here, not by the outer navigation PageView.
                      onHorizontalDragEnd: (details) {
                        final velocity = details.primaryVelocity ?? 0;
                        if (velocity < -300 &&
                            _currentImageIndex <
                                widget.post.imageUrls!.length - 1) {
                          setState(() => _currentImageIndex++);
                        } else if (velocity > 300 && _currentImageIndex > 0) {
                          setState(() => _currentImageIndex--);
                        }
                      },
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, animation) {
                          final isForward =
                              (child.key as ValueKey<int>).value >=
                              _currentImageIndex;
                          final begin = Offset(isForward ? 1.0 : -1.0, 0.0);
                          return SlideTransition(
                            position:
                                Tween<Offset>(
                                  begin: begin,
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOut,
                                  ),
                                ),
                            child: child,
                          );
                        },
                        child:
                            widget
                                .post
                                .imageUrls![_currentImageIndex]
                                .isNotEmpty
                            ? KeyedSubtree(
                                key: ValueKey(_currentImageIndex),
                                child: AppNetworkImage(
                                  url: widget
                                      .post
                                      .imageUrls![_currentImageIndex],
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : KeyedSubtree(
                                key: ValueKey(_currentImageIndex),
                                child: _brokenImagePlaceholder(colorScheme),
                              ),
                      ),
                    )
                  else
                    widget.post.imageUrl.isNotEmpty
                        ? AppNetworkImage(
                            url: widget.post.imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : _brokenImagePlaceholder(colorScheme),

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
                            : colorScheme.primary,
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
                        color: colorScheme.primaryContainer,
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
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
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
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.arrow_downward,
                              size: 20,
                              color: widget.post.isDownvoted
                                  ? Colors.red
                                  : colorScheme.onSurface,
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
                        onTap: () =>
                            context.push('/report-detail', extra: widget.post),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.build_circle_outlined,
                                size: 18,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${widget.post.updatesCount} Updates',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.onSurface,
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
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 18,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${widget.post.repliesCount} Replies',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.onSurface,
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

                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () =>
                      context.push('/report-detail', extra: widget.post),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),

                      Text(
                        widget.post.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _brokenImagePlaceholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.surfaceContainer,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 48,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  void _showCommentBottomSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _CommentSheetContent(post: widget.post);
      },
    );
  }
}

class _CommentSheetContent extends StatelessWidget {
  final ReportPost post;
  const _CommentSheetContent({required this.post});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const SizedBox(width: 40),
                Expanded(
                  child: Center(
                    child: Text(
                      'Komentar',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: CommentsSection(post: post)),
        ],
      ),
    );
  }
}
