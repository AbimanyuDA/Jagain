import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/storage/minio_storage_service.dart';
import '../../auth/domain/user_model.dart';
import '../domain/models/report_post.dart';
import '../domain/models/report_update.dart';

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
        .snapshots()
        .map(
          (snapshot) {
            final posts = snapshot.docs
                .map((doc) => _mapToReportPost(doc, currentUserId))
                .toList();
            posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return posts;
          },
        );
  }

  Stream<List<ReportPost>> watchReportsByStatus(
    ReportPostStatus status, {
    String? currentUserId,
  }) {
    return _reports
        .where('status', isEqualTo: status.key)
        .snapshots()
        .map(
          (snapshot) {
            final posts = snapshot.docs
                .map((doc) => _mapToReportPost(doc, currentUserId))
                .toList();
            posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return posts;
          },
        );
  }

  /// Laporan berdasarkan wilayah pejabat, dengan optional filter status
  Stream<List<ReportPost>> watchReportsByWilayahFiltered(
    String wilayah, {
    ReportPostStatus? status,
    String? currentUserId,
  }) {
    // Wildcard match: pejabat kota mendapat laporan kecamatannya juga
    // Gunakan prefix matching di client side setelah fetch by wilayah field
    Query<Map<String, dynamic>> query = _reports;

    if (status != null) {
      query = query.where('status', isEqualTo: status.key);
    }

    return query.snapshots().map((snapshot) {
      final posts = snapshot.docs
          .map((doc) => _mapToReportPost(doc, currentUserId))
          .where((post) {
            // Cocokkan semua laporan yang wilayahnya mengandung wilayah pejabat
            // Contoh: pejabat "Kota Surabaya -> Jawa Timur -> Pusat"
            // akan melihat laporan dari Kecamatan X -> Kota Surabaya -> ...
            return post.wilayah.contains(wilayah) || post.wilayah == wilayah;
          })
          .toList();
      posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return posts;
    });
  }

  /// Update status laporan oleh pejabat
  Future<void> updateReportStatus({
    required String reportId,
    required ReportPostStatus newStatus,
    String? officialNote,
  }) async {
    final now = DateTime.now();
    final updateData = <String, dynamic>{
      'status': newStatus.key,
      'updatedAt': Timestamp.fromDate(now),
      'statusUpdateCount': FieldValue.increment(1),
    };
    if (officialNote != null && officialNote.isNotEmpty) {
      updateData['officialNote'] = officialNote;
    }
    await _reports.doc(reportId).update(updateData);
  }


  Future<ReportPost?> getReportById(
    String reportId, {
    String? currentUserId,
  }) async {
    final doc = await _reports.doc(reportId).get();
    if (!doc.exists || doc.data() == null) return null;
    return _mapToReportPost(doc, currentUserId);
  }

  /// Stream of status updates for a report (subcollection `updates`).
  Stream<List<ReportUpdate>> watchUpdates(String reportId) {
    return _reports
        .doc(reportId)
        .collection('updates')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ReportUpdate.fromMap(d.id, d.data()))
              .toList(),
        );
  }

  Future<void> addUpdate({
    required String reportId,
    required String title,
    required String description,
    List<File>? images,
    ReportPostStatus? newStatus,
  }) async {
    List<String>? imageUrls;
    if (images != null && images.isNotEmpty) {
      imageUrls = await _storage.uploadImages(
        files: images,
        folder: MinioFolder.statusProofs,
        ownerId: reportId,
      );
    }

    await _reports.doc(reportId).collection('updates').add({
      'title': title,
      'description': description,
      'isDone': true,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.now(),
    });

    await _reports.doc(reportId).update({
      'statusUpdateCount': FieldValue.increment(1),
      'updatedAt': Timestamp.now(),
    });

    if (newStatus != null) {
      await updateReportStatus(reportId: reportId, newStatus: newStatus);
    }
  }

  Future<void> editUpdate({
    required String reportId,
    required String updateId,
    required String title,
    required String description,
    List<File>? newImages,
    List<String>? existingImageUrls,
  }) async {
    final data = <String, dynamic>{
      'title': title,
      'description': description,
    };

    if (newImages != null && newImages.isNotEmpty) {
      final uploaded = await _storage.uploadImages(
        files: newImages,
        folder: MinioFolder.statusProofs,
        ownerId: reportId,
      );
      data['imageUrls'] = [...?existingImageUrls, ...uploaded];
    } else if (existingImageUrls != null) {
      data['imageUrls'] = existingImageUrls;
    }

    await _reports
        .doc(reportId)
        .collection('updates')
        .doc(updateId)
        .update(data);
  }

  Future<void> deleteUpdate({
    required String reportId,
    required String updateId,
  }) async {
    await _reports
        .doc(reportId)
        .collection('updates')
        .doc(updateId)
        .delete();

    await _reports.doc(reportId).update({
      'statusUpdateCount': FieldValue.increment(-1),
    });
  }

  /// Returns the set of validation type this user has already cast.
  Future<String?> getUserValidation(String reportId, String userId) async {
    final doc = await _reports
        .doc(reportId)
        .collection('validations')
        .doc(userId)
        .get();
    if (!doc.exists) return null;
    return doc.data()?['type'] as String?;
  }

  /// Submits or updates a validation from [userId] for this report.
  /// type: 'darurat' | 'berisiko' | 'mengganggu'
  Future<void> submitValidation({
    required String reportId,
    required String userId,
    required String type,
  }) async {
    await _reports
        .doc(reportId)
        .collection('validations')
        .doc(userId)
        .set({'type': type, 'createdAt': FieldValue.serverTimestamp()});
  }

  /// Real-time count of all validations for a report.
  Stream<int> watchValidationCount(String reportId) {
    return _reports
        .doc(reportId)
        .collection('validations')
        .snapshots()
        .map((snap) => snap.size);
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

    // Auto-create first timeline entry "Reported"
    await docRef.collection('updates').add({
      'title': 'Laporan Dibuat',
      'description':
          'Laporan diterima dan sedang menunggu review dari moderator.',
      'isDone': true,
      'createdAt': Timestamp.fromDate(now),
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

    // Parse GeoPoint for validation proximity check
    final geoPoint = data['location'] as GeoPoint?;

    return ReportPost(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      userName: data['authorUsername'] ?? data['authorName'] ?? 'warga',
      userAvatarUrl: data['authorAvatarUrl'] ?? '',
      userBadge: data['authorBadge'] ?? 'Citizen Reporter',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
      latitude: geoPoint?.latitude,
      longitude: geoPoint?.longitude,
    );
  }

  Future<List<ReportPost>> getReportsByWilayah(
    String wilayah, {
    String? currentUserId,
  }) async {
    final snapshot = await _reports
        .where('wilayah', isEqualTo: wilayah)
        .get();
    return snapshot.docs
        .map((doc) => _mapToReportPost(doc, currentUserId))
        .toList();
  }

  Future<List<ReportPost>> getAllReports({String? currentUserId}) async {
    final snapshot = await _reports.get();
    return snapshot.docs
        .map((doc) => _mapToReportPost(doc, currentUserId))
        .toList();
  }

  Future<int> countByStatus(ReportPostStatus status) async {
    final result = await _reports
        .where('status', isEqualTo: status.key)
        .count()
        .get();
    return result.count ?? 0;
  }

  Future<int> countStuck({int days = 7}) async {
    final cutoff = Timestamp.fromDate(
      DateTime.now().subtract(Duration(days: days)),
    );
    final result = await _reports
        .where('status', whereIn: ['waiting_review', 'in_progress'])
        .where('updatedAt', isLessThan: cutoff)
        .count()
        .get();
    return result.count ?? 0;
  }

  Future<List<ReportPost>> getStuck({
    int days = 7,
    int limit = 5,
    String? currentUserId,
  }) async {
    final cutoff = Timestamp.fromDate(
      DateTime.now().subtract(Duration(days: days)),
    );
    final snapshot = await _reports
        .where('status', whereIn: ['waiting_review', 'in_progress'])
        .where('updatedAt', isLessThan: cutoff)
        .orderBy('updatedAt')
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => _mapToReportPost(doc, currentUserId))
        .toList();
  }

  Future<int> countByStatusAndWilayah(
    ReportPostStatus status,
    String wilayah,
  ) async {
    final result = await _reports
        .where('wilayah', isEqualTo: wilayah)
        .where('status', isEqualTo: status.key)
        .count()
        .get();
    return result.count ?? 0;
  }

  Future<int> countStuckByWilayah(String wilayah, {int days = 7}) async {
    final cutoff = Timestamp.fromDate(
      DateTime.now().subtract(Duration(days: days)),
    );
    final result = await _reports
        .where('wilayah', isEqualTo: wilayah)
        .where('status', whereIn: ['waiting_review', 'in_progress'])
        .where('updatedAt', isLessThan: cutoff)
        .count()
        .get();
    return result.count ?? 0;
  }

  /// Mengambil seluruh laporan yang dibuat sejak [since].
  /// Hanya memfilter pada satu field (createdAt) agar tidak butuh
  /// composite index Firestore baru; filter wilayah/bulan dilakukan
  /// di client side oleh pemanggil.
  Future<List<ReportPost>> getReportsSince(DateTime since) async {
    final snapshot = await _reports
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
        .get();
    return snapshot.docs.map((doc) => _mapToReportPost(doc, null)).toList();
  }

  Future<List<ReportPost>> getStuckByWilayah(
    String wilayah, {
    int days = 7,
    int limit = 5,
    String? currentUserId,
  }) async {
    final cutoff = Timestamp.fromDate(
      DateTime.now().subtract(Duration(days: days)),
    );
    final snapshot = await _reports
        .where('wilayah', isEqualTo: wilayah)
        .where('status', whereIn: ['waiting_review', 'in_progress'])
        .where('updatedAt', isLessThan: cutoff)
        .orderBy('updatedAt')
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => _mapToReportPost(doc, currentUserId))
        .toList();
  }

}
