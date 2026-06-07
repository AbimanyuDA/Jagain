import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/storage/minio_storage_service.dart';
import '../../auth/domain/user_model.dart';
import '../domain/models/report_post.dart';

enum VoteAction { upvote, downvote }

class ReportRepository {
  ReportRepository({FirebaseFirestore? firestore, MinioStorageService? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _storage = storage ?? MinioStorageService.instance;

  final FirebaseFirestore _firestore;
  final MinioStorageService _storage;

  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('reports');

  Stream<List<ReportPost>> watchFeed({String? currentUserId}) {
    return _reports
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _mapToReportPost(doc, currentUserId))
              .toList(),
        );
  }

  Stream<List<ReportPost>> watchReportsByWilayah(
    String wilayah, {
    String? currentUserId,
  }) {
    return _reports
        .where('wilayah', isEqualTo: wilayah)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _mapToReportPost(doc, currentUserId))
              .toList(),
        );
  }

  Stream<List<ReportPost>> watchReportsByStatus(
    ReportPostStatus status, {
    String? currentUserId,
  }) {
    return _reports
        .where('status', isEqualTo: status.key)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _mapToReportPost(doc, currentUserId))
              .toList(),
        );
  }

  Future<ReportPost?> getReportById(
    String reportId, {
    String? currentUserId,
  }) async {
    final doc = await _reports.doc(reportId).get();
    if (!doc.exists || doc.data() == null) return null;
    return _mapToReportPost(doc, currentUserId);
  }

  Future<void> toggleVote({
    required String reportId,
    required String userId,
    required VoteAction action,
  }) async {
    final docRef = _reports.doc(reportId);

    await _firestore.runTransaction((tx) async {
      final snapshot = await tx.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final upvoters = List<String>.from(data['upvoterIds'] ?? const []);
      final downvoters = List<String>.from(data['downvoterIds'] ?? const []);

      if (action == VoteAction.upvote) {
        if (upvoters.contains(userId)) {
          upvoters.remove(userId);
        } else {
          upvoters.add(userId);
          downvoters.remove(userId);
        }
      } else {
        if (downvoters.contains(userId)) {
          downvoters.remove(userId);
        } else {
          downvoters.add(userId);
          upvoters.remove(userId);
        }
      }

      tx.update(docRef, {'upvoterIds': upvoters, 'downvoterIds': downvoters});
    });
  }

  Future<String> submitReport({
    required UserModel author,
    required String title,
    required String description,
    required String category,
    required String urgency,
    required List<File> images,
    required double latitude,
    required double longitude,
    required String wilayah,
  }) async {
    final docRef = _reports.doc();

    final imageUrls = await _storage.uploadImages(
      files: images,
      folder: MinioFolder.reportPhotos,
      ownerId: docRef.id,
    );

    final now = DateTime.now();

    await docRef.set({
      'authorId': author.uid,
      'authorUsername': author.username,
      'authorName': author.name,
      'authorAvatarUrl': author.avatarUrl,
      'authorBadge': _badgeForAuthor(author),
      'title': title,
      'description': description,
      'category': category,
      'urgency': urgency,
      'imageUrls': imageUrls,
      'location': GeoPoint(latitude, longitude),
      'wilayah': wilayah,
      'status': ReportPostStatus.waitingReview.key,
      'upvoterIds': <String>[],
      'downvoterIds': <String>[],
      'commentCount': 0,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    return docRef.id;
  }

  String _badgeForAuthor(UserModel author) {
    if (author.role == UserRole.official) return 'Pejabat';
    if (author.role == UserRole.admin) return 'Admin';
    if (author.isVerified) return 'Verified';
    return 'Citizen Reporter';
  }

  ReportPost _mapToReportPost(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String? currentUserId,
  ) {
    final data = doc.data() ?? {};

    final upvoters = List<String>.from(data['upvoterIds'] ?? const []);
    final downvoters = List<String>.from(data['downvoterIds'] ?? const []);
    final imageUrls = List<String>.from(data['imageUrls'] ?? const []);

    return ReportPost(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      userName: data['authorUsername'] ?? data['authorName'] ?? 'warga',
      userAvatarUrl: data['authorAvatarUrl'] ?? '',
      userBadge: data['authorBadge'] ?? 'Citizen Reporter',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: imageUrls.isNotEmpty ? imageUrls.first : '',
      imageUrls: imageUrls.isNotEmpty ? imageUrls : null,
      category: data['category'] ?? 'LAINNYA',
      urgency: data['urgency'] ?? 'NORMAL',
      status: ReportPostStatusX.fromKey(data['status'] as String?),
      wilayah: data['wilayah'] ?? '',
      upvotes: upvoters.length - downvoters.length,
      updatesCount: (data['statusUpdateCount'] as int?) ?? 0,
      repliesCount: (data['commentCount'] as int?) ?? 0,
      isUpvoted: currentUserId != null && upvoters.contains(currentUserId),
      isDownvoted: currentUserId != null && downvoters.contains(currentUserId),
    );
  }
}
