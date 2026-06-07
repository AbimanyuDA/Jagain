import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/report_post.dart';

/// PostCard — menampilkan detail postingan warga.
/// Mendukung multi-image carousel (slide seperti Instagram) jika data memiliki multiple images.
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUrgent = widget.post.urgency == 'URGENT';

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: User Info (Padded) ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      context.push('/profile/${widget.post.userName}');
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: NetworkImage(widget.post.userAvatarUrl),
                          child: const Icon(Icons.person, color: Colors.grey),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.post.userName,
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
                                    widget.post.userBadge,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: widget.post.userBadge == 'Verified'
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

          // ── Post Image (Edge-to-Edge, Aspect Ratio 4:5) ──────────────────
          AspectRatio(
            aspectRatio: 4 / 5,
            child: Stack(
              children: [
                if (widget.post.imageUrls != null && widget.post.imageUrls!.length > 1)
                  PageView.builder(
                    itemCount: widget.post.imageUrls!.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Image.network(
                        widget.post.imageUrls![index],
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  )
                else
                  Image.network(
                    widget.post.imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                      ),
                    ),
                  ),

                // Category & Urgency Tag Overlay
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isUrgent ? const Color(0xFFD32F2F) : const Color(0xFF2E5BFF),
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

                // Carousel Dots Indicator (Only if multiple images)
                if (widget.post.imageUrls != null && widget.post.imageUrls!.length > 1)
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
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Actions & Text content below image (Padded) ──────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Actions: Vote, Updates, Replies
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Upvote & Downvote Capsule
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
                              color: widget.post.isUpvoted ? theme.colorScheme.primary : Colors.black87,
                            ),
                            onPressed: widget.onUpvotePressed,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                              color: widget.post.isDownvoted ? Colors.red : Colors.black87,
                            ),
                            onPressed: widget.onDownvotePressed,
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ],
                      ),
                    ),

                    // Updates Indicator
                    Flexible(
                      child: InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.build_circle_outlined, size: 18, color: Colors.black54),
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

                    // Replies Indicator
                    Flexible(
                      child: InkWell(
                        onTap: () => _showCommentBottomSheet(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.black54),
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

                // Post Title
                Text(
                  widget.post.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F1E36), // Deep Navy text color
                  ),
                ),
                const SizedBox(height: 6),

                // Post Description
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
      isScrollControlled: true, // Keyboard pushes bottom sheet
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

// ── Comment Sheet Component ──────────────────────────────────────────────────
class _CommentSheetContent extends StatefulWidget {
  final ReportPost post;
  const _CommentSheetContent({required this.post});

  @override
  State<_CommentSheetContent> createState() => _CommentSheetContentState();
}

class _CommentSheetContentState extends State<_CommentSheetContent> {
  final TextEditingController _commentController = TextEditingController();
  
  // Model data komentar yang presisi sesuai dengan screenshot referensi
  final List<Map<String, dynamic>> _mockComments = [
    {
      'username': 'gabrielrey99',
      'avatarUrl': 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      'comment': 'lhsg senin gimana nih',
      'timeAgo': '1 hari',
      'likeCount': 163,
      'isVerified': true,
      'isLiked': false,
      'hasReplies': true,
    },
    {
      'username': 'widhi.sudariani',
      'avatarUrl': 'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=150',
      'comment': 'Kereen 🔥',
      'timeAgo': '1 hari',
      'likeCount': 1,
      'isVerified': false,
      'isLiked': false,
    },
    {
      'username': 'rifans.official',
      'avatarUrl': 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=150',
      'comment': 'Ku kira 19 jt lapangan ternyata 19 rupiah di depan 😢 Keren banget pak 🥲👏 @prabowo',
      'timeAgo': '21 jam',
      'likeCount': 1,
      'isVerified': false,
      'isLiked': false,
      'showTranslation': true,
    },
    {
      'username': 'gthaannnn',
      'avatarUrl': 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150',
      'comment': 'wkwkwk',
      'timeAgo': '1 hari',
      'likeCount': 1,
      'isVerified': false,
      'isLiked': false,
    },
    {
      'username': 'mhzulkrnn',
      'avatarUrl': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      'comment': '@prabowo @pur.bayayudisadewa',
      'timeAgo': '1 hari',
      'likeCount': 3,
      'isVerified': false,
      'isLiked': false,
    },
    {
      'username': 'zaidanilhami',
      'avatarUrl': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
      'comment': 'Apakah prediksi Noel untuk bulan Juni - Juli beneran terjadi? 😢😂',
      'timeAgo': '1 hari',
      'likeCount': 76,
      'isVerified': false,
      'isLiked': false,
    },
  ];

  static const List<String> _quickEmojis = [
    '❤️', '🙌', '🔥', '👏', '😢', '😍', '😮', '😂'
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _mockComments.insert(0, {
        'username': 'budisantoso_jkt',
        'avatarUrl': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300',
        'comment': text,
        'timeAgo': 'Baru saja',
        'likeCount': 0,
        'isVerified': true,
        'isLiked': false,
      });
      _commentController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Komentar berhasil diposting!'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleLikeComment(int index) {
    setState(() {
      final comment = _mockComments[index];
      final isLiked = comment['isLiked'] as bool;
      comment['isLiked'] = !isLiked;
      int likeCount = comment['likeCount'] as int;
      if (!isLiked) {
        comment['likeCount'] = likeCount + 1;
      } else {
        comment['likeCount'] = likeCount - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
          // Drag handle
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

          // Header: Centered title + direct plane icon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const SizedBox(width: 40), // Balance the send button
                const Expanded(
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
                IconButton(
                  icon: const Icon(Icons.near_me_outlined, color: Colors.black87, size: 22),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Comments List
          Expanded(
            child: _mockComments.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada komentar. Jadilah yang pertama!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _mockComments.length,
                    itemBuilder: (context, index) {
                      final item = _mockComments[index];
                      final isLiked = item['isLiked'] as bool;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 16, // Diperkecil agar lebih ramping
                              backgroundImage: NetworkImage(item['avatarUrl']!),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Baris 1: Username + verified + time ago
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        item['username']!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600, // Semi-bold khas IG
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      if (item['isVerified'] as bool) ...[
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.verified_rounded,
                                          color: Color(0xFF2E5BFF),
                                          size: 13,
                                        ),
                                      ],
                                      const SizedBox(width: 8),
                                      Text(
                                        item['timeAgo']!,
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (item['showTranslation'] == true) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          '•  Diedit',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  // Baris 2: Comment text
                                  Text(
                                    item['comment']!,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      color: Colors.black87,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Baris 3: Balas & Lihat Terjemahan
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {},
                                        child: Text(
                                          'Balas',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (item['showTranslation'] == true) ...[
                                        const SizedBox(width: 12),
                                        GestureDetector(
                                          onTap: () {},
                                          child: Text(
                                            'Lihat terjemahan',
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  
                                  // Balasan Bersarang (Lihat 36 balasan lainnya)
                                  if (item['hasReplies'] == true) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Container(
                                          width: 24,
                                          height: 1,
                                          color: Colors.grey.shade300,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Lihat 36 balasan lainnya',
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Bagian Kanan: Tombol Love + Jumlah Like (di-center vertikal kecil)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () => _toggleLikeComment(index),
                                    child: Icon(
                                      isLiked ? Icons.favorite : Icons.favorite_border_rounded,
                                      size: 14,
                                      color: isLiked ? Colors.red : Colors.grey.shade400,
                                    ),
                                  ),
                                  if (item['likeCount'] as int > 0) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item['likeCount']}',
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
                  ),
          ),

          Divider(height: 1, color: Colors.grey.shade200, thickness: 0.5),

          // Quick Emoji Bar
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
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                );
              }).toList(),
            ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            color: Colors.white,
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16, // Radius disamakan (32px diameter) agar profesional
                  backgroundImage: NetworkImage(
                    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=300', // Budi avatar
                  ),
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
                              contentPadding: EdgeInsets.symmetric(vertical: 10),
                            ),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _submitComment(),
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
                            onTap: _submitComment,
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
