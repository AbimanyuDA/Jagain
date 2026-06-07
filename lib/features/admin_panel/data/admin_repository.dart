import 'package:cloud_firestore/cloud_firestore.dart';

import '../../auth/domain/user_model.dart';
import '../../feed/data/report_repository.dart';
import '../../feed/domain/models/report_post.dart';
import '../domain/models/admin_stats.dart';
import '../domain/models/category_item.dart';

class AdminRepository {
  AdminRepository({
    FirebaseFirestore? firestore,
    ReportRepository? reportRepository,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _reportRepository = reportRepository ?? ReportRepository();

  final FirebaseFirestore _firestore;
  final ReportRepository _reportRepository;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('reports');
  CollectionReference<Map<String, dynamic>> get _categories =>
      _firestore.collection('categories');

  Stream<List<ReportPost>> watchPendingReports() {
    return _reportRepository.watchReportsByStatus(
      ReportPostStatus.waitingReview,
    );
  }

  Future<void> moderateReport({
    required String reportId,
    required bool approve,
  }) {
    return _reports.doc(reportId).update({
      'status':
          (approve ? ReportPostStatus.inProgress : ReportPostStatus.rejected)
              .key,
      'updatedAt': Timestamp.now(),
    });
  }

  Stream<List<UserModel>> watchPendingOfficials() {
    return _users
        .where('role', isEqualTo: UserRole.official.name)
        .where('isVerified', isEqualTo: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> verifyOfficial(String uid) async {
    await _users.doc(uid).update({'isVerified': true});
    await _syncUserReportsAndComments(uid);
  }

  Future<void> rejectOfficial(String uid) async {
    await _users.doc(uid).update({
      'role': UserRole.citizen.name,
      'isVerified': false,
    });
    await _syncUserReportsAndComments(uid);
  }

  Future<void> _syncUserReportsAndComments(String uid) async {
    try {
      final userSnap = await _users.doc(uid).get();
      if (!userSnap.exists || userSnap.data() == null) return;
      final user = UserModel.fromMap(uid, userSnap.data()!);

      final reportsQuery = await _reports
          .where('authorId', isEqualTo: uid)
          .get();

      final commentsQuery = await _firestore
          .collectionGroup('comments')
          .where('authorId', isEqualTo: uid)
          .get();

      if (reportsQuery.docs.isNotEmpty || commentsQuery.docs.isNotEmpty) {
        final batch = _firestore.batch();

        String badge = 'Citizen Reporter';
        if (user.role == UserRole.official) {
          badge = 'Pejabat';
        } else if (user.role == UserRole.admin) {
          badge = 'Admin';
        } else if (user.isVerified) {
          badge = 'Verified';
        }

        for (final doc in reportsQuery.docs) {
          batch.update(doc.reference, {
            'authorName': user.name,
            'authorUsername': user.username,
            'authorAvatarUrl': user.avatarUrl,
            'authorBadge': badge,
          });
        }

        for (final doc in commentsQuery.docs) {
          batch.update(doc.reference, {
            'authorName': user.name,
            'authorUsername': user.username,
            'authorAvatarUrl': user.avatarUrl,
          });
        }

        await batch.commit();
      }
    } catch (e) {
      print('Error syncing reports/comments on role change: $e');
    }
  }

  Stream<List<CategoryItem>> watchCategories() {
    return _categories
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => CategoryItem(
                  id: doc.id,
                  name: doc.data()['name'] ?? '',
                  isActive: doc.data()['isActive'] ?? true,
                ),
              )
              .toList(),
        );
  }

  Future<void> addCategory(String name) {
    return _categories.add({'name': name, 'isActive': true});
  }

  Future<void> setCategoryActive({
    required String categoryId,
    required bool isActive,
  }) {
    return _categories.doc(categoryId).update({'isActive': isActive});
  }

  Future<void> deleteCategory(String categoryId) {
    return _categories.doc(categoryId).delete();
  }

  Future<AdminStats> loadGlobalStats() async {
    final results = await Future.wait([
      _users.count().get(),
      _reports.count().get(),
      _reports
          .where('status', isEqualTo: ReportPostStatus.solved.key)
          .count()
          .get(),
      _reports
          .where('status', isEqualTo: ReportPostStatus.waitingReview.key)
          .count()
          .get(),
      _users
          .where('role', isEqualTo: UserRole.official.name)
          .where('isVerified', isEqualTo: false)
          .count()
          .get(),
    ]);

    return AdminStats(
      totalUsers: results[0].count ?? 0,
      totalReports: results[1].count ?? 0,
      reportsSolved: results[2].count ?? 0,
      reportsPendingModeration: results[3].count ?? 0,
      pendingOfficialVerifications: results[4].count ?? 0,
    );
  }
}
