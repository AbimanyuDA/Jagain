import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/time_ago.dart';
import '../../auth/domain/user_model.dart';
import '../domain/models/user_profile.dart';

class ProfileRepository {
  ProfileRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _reports =>
      _firestore.collection('reports');
  CollectionReference<Map<String, dynamic>> get _follows =>
      _firestore.collection('follows');

  static const List<RedeemReward> rewards = [
    RedeemReward(
      id: 'rw1',
      name: 'Voucher Grab 25K',
      description: 'Tukar 500 poin untuk voucher transportasi',
      pointsCost: 500,
      icon: '🚗',
      isAvailable: true,
    ),
    RedeemReward(
      id: 'rw2',
      name: 'Sertifikat Digital',
      description: 'Pengakuan resmi sebagai Warga Aktif JAGAIN',
      pointsCost: 300,
      icon: '📜',
      isAvailable: true,
    ),
    RedeemReward(
      id: 'rw3',
      name: 'Diskon PDAM 10%',
      description: 'Diskon tagihan air bulan ini',
      pointsCost: 1000,
      icon: '💧',
      isAvailable: true,
    ),
    RedeemReward(
      id: 'rw4',
      name: 'Token Listrik 50K',
      description: 'Tukar 2000 poin untuk token listrik',
      pointsCost: 2000,
      icon: '⚡',
      isAvailable: false,
    ),
  ];

  Future<UserProfile> loadProfile({String? username, String? viewerId}) async {
    final userDoc = await _resolveUserDoc(
      username: username,
      viewerId: viewerId,
    );
    if (userDoc == null) {
      throw Exception('Pengguna tidak ditemukan');
    }

    final uid = userDoc.id;
    final user = UserModel.fromMap(uid, userDoc.data()!);

    final countResults = await Future.wait([
      _reports.where('authorId', isEqualTo: uid).count().get(),
      _reports
          .where('authorId', isEqualTo: uid)
          .where('status', isEqualTo: 'solved')
          .count()
          .get(),
      _reports.where('upvoterIds', arrayContains: uid).count().get(),
      _follows.where('followeeId', isEqualTo: uid).count().get(),
      _follows.where('followerId', isEqualTo: uid).count().get(),
    ]);

    final totalReports = countResults[0].count ?? 0;
    final reportsSolved = countResults[1].count ?? 0;
    final upvotesGiven = countResults[2].count ?? 0;
    final followersCount = countResults[3].count ?? 0;
    final followingCount = countResults[4].count ?? 0;

    final civicPoints =
        reportsSolved * 100 + upvotesGiven * 5 + totalReports * 10;
    final redeemedPoints = await _totalRedeemedPoints(uid);
    final availablePoints = (civicPoints - redeemedPoints).clamp(
      0,
      civicPoints,
    );

    final myReportsSnapshot = await _reports
        .where('authorId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    final supportedSnapshot = await _reports
        .where('upvoterIds', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .get();

    var isFollowing = false;
    if (viewerId != null && viewerId != uid) {
      final followDoc = await _follows.doc('${viewerId}_$uid').get();
      isFollowing = followDoc.exists;
    }

    return UserProfile(
      id: uid,
      username: user.username,
      displayName: user.name,
      avatarUrl: user.avatarUrl,
      domicile: user.domicile ?? user.wilayah ?? '',
      isVerifiedCitizen: user.isVerified,
      gamificationTitle: _titleForPoints(civicPoints),
      civicPoints: civicPoints,
      reportsSolved: reportsSolved,
      upvotesGiven: upvotesGiven,
      totalReports: totalReports,
      followersCount: followersCount,
      followingCount: followingCount,
      isFollowing: isFollowing,
      myReports: myReportsSnapshot.docs.map(_mapToUserReport).toList(),
      supportedReports: supportedSnapshot.docs
          .map(_mapToSupportedReport)
          .toList(),
      badges: _resolveBadges(
        totalReports: totalReports,
        reportsSolved: reportsSolved,
        upvotesGiven: upvotesGiven,
        civicPoints: civicPoints,
      ),
      availablePointsForRedeem: availablePoints,
    );
  }

  Future<void> toggleFollow({
    required String followerId,
    required String followeeId,
  }) async {
    final ref = _follows.doc('${followerId}_$followeeId');
    final snapshot = await ref.get();
    if (snapshot.exists) {
      await ref.delete();
    } else {
      await ref.set({
        'followerId': followerId,
        'followeeId': followeeId,
        'createdAt': Timestamp.now(),
      });
    }
  }

  Future<void> redeemReward({
    required String userId,
    required String rewardId,
    required int pointsCost,
  }) {
    return _users.doc(userId).collection('redemptions').add({
      'rewardId': rewardId,
      'pointsCost': pointsCost,
      'redeemedAt': Timestamp.now(),
    });
  }

  Future<DocumentSnapshot<Map<String, dynamic>>?> _resolveUserDoc({
    String? username,
    String? viewerId,
  }) async {
    if (username != null) {
      final query = await _users
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      return query.docs.first;
    }

    if (viewerId == null) return null;
    final doc = await _users.doc(viewerId).get();
    return doc.exists ? doc : null;
  }

  Future<int> _totalRedeemedPoints(String uid) async {
    final snapshot = await _users.doc(uid).collection('redemptions').get();
    return snapshot.docs.fold<int>(
      0,
      (total, doc) =>
          total + ((doc.data()['pointsCost'] as num?)?.toInt() ?? 0),
    );
  }

  String _titleForPoints(int civicPoints) {
    if (civicPoints >= 5000) return 'Legenda Kota';
    if (civicPoints >= 2000) return 'Pahlawan Aspal';
    if (civicPoints >= 500) return 'Warga Aktif';
    return 'Citizen Reporter';
  }

  List<Badge> _resolveBadges({
    required int totalReports,
    required int reportsSolved,
    required int upvotesGiven,
    required int civicPoints,
  }) {
    return [
      Badge(
        id: 'b1',
        name: 'Pelopor Pertama',
        description: 'Buat laporan pertamamu',
        icon: '🏅',
        rarity: BadgeRarity.common,
        isUnlocked: totalReports >= 1,
      ),
      Badge(
        id: 'b2',
        name: 'Pahlawan Aspal',
        description: 'Selesaikan 5 laporan yang kamu buat',
        icon: '🛣️',
        rarity: BadgeRarity.rare,
        isUnlocked: reportsSolved >= 5,
      ),
      Badge(
        id: 'b3',
        name: 'Warga Aktif',
        description: 'Berikan 50 dukungan ke laporan lain',
        icon: '🤝',
        rarity: BadgeRarity.rare,
        isUnlocked: upvotesGiven >= 50,
      ),
      Badge(
        id: 'b4',
        name: 'Suara Kota',
        description: 'Kumpulkan 1.000 Civic Points',
        icon: '📣',
        rarity: BadgeRarity.epic,
        isUnlocked: civicPoints >= 1000,
      ),
      Badge(
        id: 'b5',
        name: 'Pelapor Senior',
        description: 'Selesaikan 10 laporan yang kamu buat',
        icon: '💡',
        rarity: BadgeRarity.epic,
        isUnlocked: reportsSolved >= 10,
      ),
      Badge(
        id: 'b6',
        name: 'Legenda Kota',
        description: 'Kumpulkan 5.000 Civic Points dan selesaikan 20 laporan',
        icon: '👑',
        rarity: BadgeRarity.legendary,
        isUnlocked: civicPoints >= 5000 && reportsSolved >= 20,
      ),
    ];
  }

  UserReport _mapToUserReport(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final imageUrls = List<String>.from(data['imageUrls'] ?? const []);
    return UserReport(
      id: doc.id,
      title: data['title'] ?? '',
      category: data['category'] ?? 'LAINNYA',
      imageUrl: imageUrls.isNotEmpty ? imageUrls.first : '',
      timeAgo: timeAgoText(
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ),
      upvotes: _netUpvotes(data),
      status: _statusFromKey(data['status'] as String?),
    );
  }

  SupportedReport _mapToSupportedReport(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final imageUrls = List<String>.from(data['imageUrls'] ?? const []);
    return SupportedReport(
      id: doc.id,
      title: data['title'] ?? '',
      authorName: data['authorName'] ?? 'Warga',
      authorAvatarUrl: data['authorAvatarUrl'] ?? '',
      category: data['category'] ?? 'LAINNYA',
      imageUrl: imageUrls.isNotEmpty ? imageUrls.first : '',
      timeAgo: timeAgoText(
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ),
      upvotes: _netUpvotes(data),
      status: _statusFromKey(data['status'] as String?),
      isSaved: false,
    );
  }

  int _netUpvotes(Map<String, dynamic> data) {
    final up = (data['upvoterIds'] as List?)?.length ?? 0;
    final down = (data['downvoterIds'] as List?)?.length ?? 0;
    return up - down;
  }

  ReportStatus _statusFromKey(String? key) {
    switch (key) {
      case 'in_progress':
        return ReportStatus.inProgress;
      case 'solved':
        return ReportStatus.solved;
      case 'rejected':
        return ReportStatus.rejected;
      case 'waiting_review':
      default:
        return ReportStatus.waitingReview;
    }
  }
}
