import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/domain/user_model.dart';
import '../domain/models/comment.dart';

class CommentRepository {
  CommentRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _commentsRef(String reportId) =>
      _firestore.collection('reports').doc(reportId).collection('comments');

  Stream<List<Comment>> watchComments(String reportId) {
    return _commentsRef(reportId)
        .orderBy('isPinned', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_mapToComment).toList());
  }

  Future<void> addComment({
    required String reportId,
    required UserModel author,
    required String text,
  }) async {
    final isOfficial =
        author.role == UserRole.official || author.role == UserRole.admin;

    await _commentsRef(reportId).add({
      'authorId': author.uid,
      'authorUsername': author.username,
      'authorName': author.name,
      'authorAvatarUrl': author.avatarUrl,
      'text': text,
      'isPinned': false,
      'isOfficial': isOfficial,
      'likedBy': <String>[],
      'createdAt': Timestamp.now(),
    });

    await _firestore.collection('reports').doc(reportId).update({
      'commentCount': FieldValue.increment(1),
    });
  }

  Future<void> toggleLike({
    required String reportId,
    required String commentId,
    required String userId,
  }) async {
    final ref = _commentsRef(reportId).doc(commentId);

    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(ref);
      if (!snapshot.exists) return;

      final likedBy = List<String>.from(
        snapshot.data()?['likedBy'] ?? const [],
      );
      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
      }

      tx.update(ref, {'likedBy': likedBy});
    });
  }

  Future<void> setPinned({
    required String reportId,
    required String commentId,
    required bool isPinned,
  }) {
    return _commentsRef(reportId).doc(commentId).update({'isPinned': isPinned});
  }

  Comment _mapToComment(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Comment(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorUsername: data['authorUsername'] ?? 'warga',
      authorName: data['authorName'] ?? '',
      authorAvatarUrl: data['authorAvatarUrl'] ?? '',
      text: data['text'] ?? '',
      isPinned: data['isPinned'] ?? false,
      isOfficial: data['isOfficial'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likedBy: List<String>.from(data['likedBy'] ?? const []),
    );
  }
}
