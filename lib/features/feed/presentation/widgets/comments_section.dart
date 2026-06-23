import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/domain/user_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../data/comment_repository.dart';
import '../../domain/models/comment.dart';
import '../../domain/models/report_post.dart';

final RegExp _mentionRegex = RegExp(r'@([a-zA-Z0-9_.]+)');

/// Daftar komentar + balasan bertingkat (mirip Instagram) lengkap dengan
/// input @mention autocomplete. Dipakai bersama oleh report_detail_screen
/// (tab "Replies") dan post_card (bottom sheet komentar feed) supaya logic
/// tidak diduplikasi di dua tempat.
class CommentsSection extends StatefulWidget {
  final ReportPost post;
  final bool showQuickEmojis;

  const CommentsSection({
    super.key,
    required this.post,
    this.showQuickEmojis = true,
  });

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final CommentRepository _repository = CommentRepository();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final Set<String> _expandedReplies = {};

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

  Comment? _replyingTo;
  List<UserModel> _mentionSuggestions = [];
  int? _mentionStart;

  Timer? _mentionDebounce;
  int _mentionRequestId = 0;

  late final Stream<List<Comment>> _commentsStream = _repository.watchComments(
    widget.post.id,
  );

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _mentionDebounce?.cancel();
    super.dispose();
  }

  void _onTextChanged(String text) {
    setState(() {});

    final cursor = _controller.selection.baseOffset;
    if (cursor < 0) {
      _clearMentionSuggestions();
      return;
    }

    final atIndex = text.substring(0, cursor).lastIndexOf('@');
    if (atIndex == -1) {
      _clearMentionSuggestions();
      return;
    }

    final query = text.substring(atIndex + 1, cursor);
    if (query.contains(' ') || query.contains('\n')) {
      _clearMentionSuggestions();
      return;
    }

    _mentionStart = atIndex;

    // Debounce + tandai request supaya hasil query karakter sebelumnya yang
    // baru selesai belakangan tidak menimpa hasil query terbaru (race
    // condition ini yang sebelumnya membuat kotak saran berkedip-kedip).
    _mentionDebounce?.cancel();
    final requestId = ++_mentionRequestId;
    _mentionDebounce = Timer(const Duration(milliseconds: 250), () async {
      final users = await _repository.searchUsersByUsernamePrefix(query);
      if (!mounted || requestId != _mentionRequestId) return;
      setState(() => _mentionSuggestions = users);
    });
  }

  void _clearMentionSuggestions() {
    _mentionDebounce?.cancel();
    _mentionRequestId++;
    if (_mentionSuggestions.isEmpty && _mentionStart == null) return;
    setState(() {
      _mentionSuggestions = [];
      _mentionStart = null;
    });
  }

  void _selectMention(UserModel user) {
    final start = _mentionStart;
    if (start == null) return;
    final text = _controller.text;
    final cursor = _controller.selection.baseOffset;
    final end = cursor < 0 ? text.length : cursor;

    final newText =
        '${text.substring(0, start)}@${user.username} '
        '${text.substring(end)}';
    final newCursor = start + user.username.length + 2;

    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );

    _mentionDebounce?.cancel();
    _mentionRequestId++;
    setState(() {
      _mentionSuggestions = [];
      _mentionStart = null;
    });
  }

  void _startReply(Comment comment) {
    setState(() {
      _replyingTo = comment;
      _controller.text = '@${comment.authorUsername} ';
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    _mentionDebounce?.cancel();
    _mentionRequestId++;
    setState(() {
      _replyingTo = null;
      _controller.clear();
      _mentionSuggestions = [];
      _mentionStart = null;
    });
  }

  void _submit(UserModel? author) {
    final text = _controller.text.trim();
    if (text.isEmpty || author == null) return;

    final replyingTo = _replyingTo;
    final parentCommentId = replyingTo == null
        ? null
        : (replyingTo.parentCommentId ?? replyingTo.id);

    _controller.clear();
    _mentionDebounce?.cancel();
    _mentionRequestId++;
    setState(() {
      _replyingTo = null;
      _mentionSuggestions = [];
      _mentionStart = null;
    });

    _repository.addComment(
      reportId: widget.post.id,
      author: author,
      text: text,
      parentCommentId: parentCommentId,
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

  void _openMentionedProfile(String username) {
    context.push('/profile/$username');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authState = context.watch<AuthBloc>().state;
    final currentUser = authState is AuthAuthenticated ? authState.user : null;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Comment>>(
            stream: _commentsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Gagal memuat komentar: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
                );
              }

              final all = snapshot.data ?? const [];
              if (all.isEmpty) {
                return Center(
                  child: Text(
                    'Belum ada komentar. Jadilah yang pertama!',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                );
              }

              final topLevel = all.where((c) => !c.isReply).toList();
              final repliesByParent = <String, List<Comment>>{};
              for (final c in all.where((c) => c.isReply)) {
                repliesByParent
                    .putIfAbsent(c.parentCommentId!, () => [])
                    .add(c);
              }
              for (final replies in repliesByParent.values) {
                replies.sort((a, b) => a.createdAt.compareTo(b.createdAt));
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: topLevel.length,
                itemBuilder: (context, index) {
                  final comment = topLevel[index];
                  final replies = repliesByParent[comment.id] ?? const [];
                  final isExpanded = _expandedReplies.contains(comment.id);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CommentRow(
                          comment: comment,
                          currentUser: currentUser,
                          currentUserId: currentUserId,
                          colorScheme: colorScheme,
                          onToggleLike: () =>
                              _toggleLike(comment, currentUserId),
                          onReply: () => _startReply(comment),
                          onTapMention: _openMentionedProfile,
                        ),
                        if (replies.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.only(left: 42),
                            child: GestureDetector(
                              onTap: () => setState(() {
                                if (isExpanded) {
                                  _expandedReplies.remove(comment.id);
                                } else {
                                  _expandedReplies.add(comment.id);
                                }
                              }),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 1,
                                    color: colorScheme.outlineVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isExpanded
                                        ? 'Sembunyikan balasan'
                                        : 'Lihat ${replies.length} balasan',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (isExpanded)
                          ...replies.map(
                            (reply) => Padding(
                              padding: const EdgeInsets.only(left: 42, top: 12),
                              child: _CommentRow(
                                comment: reply,
                                currentUser: currentUser,
                                currentUserId: currentUserId,
                                colorScheme: colorScheme,
                                compact: true,
                                onToggleLike: () =>
                                    _toggleLike(reply, currentUserId),
                                onReply: () => _startReply(reply),
                                onTapMention: _openMentionedProfile,
                              ),
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

        if (_replyingTo != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: colorScheme.surfaceContainerLow,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Membalas @${_replyingTo!.authorUsername}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _cancelReply,
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

        if (_mentionSuggestions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 180),
            color: colorScheme.surface,
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _mentionSuggestions.length,
              itemBuilder: (context, index) {
                final user = _mentionSuggestions[index];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: colorScheme.surfaceContainer,
                    backgroundImage: user.avatarUrl.isNotEmpty
                        ? CachedNetworkImageProvider(user.avatarUrl)
                        : null,
                    child: user.avatarUrl.isEmpty
                        ? Text(
                            user.username.isNotEmpty
                                ? user.username[0].toUpperCase()
                                : '?',
                            style: const TextStyle(fontSize: 11),
                          )
                        : null,
                  ),
                  title: Text(
                    '@${user.username}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    user.name,
                    style: const TextStyle(fontSize: 11),
                  ),
                  onTap: () => _selectMention(user),
                );
              },
            ),
          ),

        Divider(height: 1, color: colorScheme.outlineVariant),

        if (widget.showQuickEmojis)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: colorScheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _quickEmojis.map((emoji) {
                return GestureDetector(
                  onTap: () {
                    setState(() => _controller.text += emoji);
                  },
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                );
              }).toList(),
            ),
          ),

        Container(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            MediaQuery.of(context).viewInsets.bottom + 12,
          ),
          color: colorScheme.surface,
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.surfaceContainer,
                backgroundImage: (currentUser?.avatarUrl.isNotEmpty ?? false)
                    ? CachedNetworkImageProvider(currentUser!.avatarUrl)
                    : null,
                child: (currentUser?.avatarUrl.isEmpty ?? true)
                    ? Text(
                        currentUser?.name.isNotEmpty == true
                            ? currentUser!.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 12),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: colorScheme.outline),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    onChanged: _onTextChanged,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submit(currentUser),
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: _replyingTo == null
                          ? 'Tulis komentar... (@untuk tag)'
                          : 'Tulis balasan...',
                      hintStyle: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _controller.text.trim().isNotEmpty
                    ? () => _submit(currentUser)
                    : null,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _controller.text.trim().isNotEmpty
                        ? colorScheme.primary
                        : colorScheme.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send_rounded,
                    size: 16,
                    color: _controller.text.trim().isNotEmpty
                        ? Colors.white
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentRow extends StatelessWidget {
  final Comment comment;
  final UserModel? currentUser;
  final String? currentUserId;
  final ColorScheme colorScheme;
  final VoidCallback onToggleLike;
  final VoidCallback onReply;
  final ValueChanged<String> onTapMention;
  final bool compact;

  const _CommentRow({
    required this.comment,
    required this.currentUser,
    required this.currentUserId,
    required this.colorScheme,
    required this.onToggleLike,
    required this.onReply,
    required this.onTapMention,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isLiked = comment.isLikedBy(currentUserId);
    final isCommentMine =
        currentUser != null && currentUser!.uid == comment.authorId;
    final avatar = isCommentMine
        ? currentUser!.avatarUrl
        : comment.authorAvatarUrl;
    final username = isCommentMine
        ? currentUser!.username
        : comment.authorUsername;
    final radius = compact ? 13.0 : 16.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: colorScheme.surfaceContainer,
          backgroundImage: avatar.isNotEmpty
              ? CachedNetworkImageProvider(avatar)
              : null,
          child: avatar.isEmpty
              ? Text(
                  username.isNotEmpty ? username[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 12),
                )
              : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    username,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (comment.isOfficial) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.verified_rounded,
                      color: colorScheme.primary,
                      size: 13,
                    ),
                  ],
                  const SizedBox(width: 8),
                  Text(
                    comment.timeAgo,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (comment.isPinned) ...[
                    const SizedBox(width: 6),
                    Text(
                      '•  Disematkan',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              _MentionText(
                text: comment.text,
                style: TextStyle(
                  fontSize: 13.5,
                  color: colorScheme.onSurface,
                  height: 1.35,
                ),
                mentionStyle: TextStyle(
                  fontSize: 13.5,
                  height: 1.35,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
                onTapMention: onTapMention,
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onReply,
                child: Text(
                  'Balas',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onToggleLike,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLiked ? Icons.favorite : Icons.favorite_border_rounded,
                size: 14,
                color: isLiked ? Colors.red : colorScheme.onSurfaceVariant,
              ),
              if (comment.likeCount > 0)
                Text(
                  '${comment.likeCount}',
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Render teks komentar dengan @mention yang bisa di-tap, mirip Instagram.
class _MentionText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextStyle mentionStyle;
  final ValueChanged<String> onTapMention;

  const _MentionText({
    required this.text,
    required this.style,
    required this.mentionStyle,
    required this.onTapMention,
  });

  @override
  State<_MentionText> createState() => _MentionTextState();
}

class _MentionTextState extends State<_MentionText> {
  final List<TapGestureRecognizer> _recognizers = [];

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();

    final spans = <InlineSpan>[];
    var lastEnd = 0;
    for (final match in _mentionRegex.allMatches(widget.text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: widget.text.substring(lastEnd, match.start)));
      }
      final username = match.group(1)!;
      final recognizer = TapGestureRecognizer()
        ..onTap = () => widget.onTapMention(username);
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: '@$username',
          style: widget.mentionStyle,
          recognizer: recognizer,
        ),
      );
      lastEnd = match.end;
    }
    if (lastEnd < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(lastEnd)));
    }

    return Text.rich(TextSpan(style: widget.style, children: spans));
  }
}
