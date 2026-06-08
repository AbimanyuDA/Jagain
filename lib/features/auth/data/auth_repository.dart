import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> isUsernameAvailable(String username) async {
    final query = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    return query.docs.isEmpty;
  }

  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return await getUser(firebaseUser.uid);
    });
  }

  Future<UserModel> register({
    required String username,
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? wilayah,
    String? address,
    String? phoneNumber,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      final newUser = UserModel(
        uid: uid,
        name: name,
        username: username,
        email: email,
        role: role,
        wilayah: wilayah,
        address: address,
        phoneNumber: phoneNumber,
        isVerified: false,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set(newUser.toMap());

      return newUser;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      final userModel = await getUser(uid);

      if (userModel == null) {
        throw Exception('Data profil user tidak ditemukan di database.');
      }

      return userModel;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists || doc.data() == null) return null;

      return UserModel.fromMap(uid, doc.data()!);
    } catch (e) {
      return null;
    }
  }

  Future<UserModel> updateProfile({
    required String uid,
    String? name,
    String? username,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (username != null) updates['username'] = username;
    if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(uid).update(updates);
    }

    final updated = await getUser(uid);
    if (updated == null) {
      throw Exception('Gagal memuat ulang data profil setelah pembaruan.');
    }

    if (updates.isNotEmpty) {
      try {
        final reportsQuery = await _firestore
            .collection('reports')
            .where('authorId', isEqualTo: uid)
            .get();

        final commentsQuery = await _firestore
            .collectionGroup('comments')
            .where('authorId', isEqualTo: uid)
            .get();

        if (reportsQuery.docs.isNotEmpty || commentsQuery.docs.isNotEmpty) {
          final batch = _firestore.batch();
          
          String badge = 'Citizen Reporter';
          if (updated.role == UserRole.official) {
            badge = 'Pejabat';
          } else if (updated.role == UserRole.admin) {
            badge = 'Admin';
          } else if (updated.isVerified) {
            badge = 'Verified';
          }

          for (final doc in reportsQuery.docs) {
            batch.update(doc.reference, {
              'authorName': updated.name,
              'authorUsername': updated.username,
              'authorAvatarUrl': updated.avatarUrl,
              'authorBadge': badge,
            });
          }

          for (final doc in commentsQuery.docs) {
            batch.update(doc.reference, {
              'authorName': updated.name,
              'authorUsername': updated.username,
              'authorAvatarUrl': updated.avatarUrl,
            });
          }

          await batch.commit();
        }
      } catch (e) {
        print('Error syncing reports/comments: $e');
      }
    }

    return updated;
  }

  Future<UserModel?> getUserByUsername(String username) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      final doc = query.docs.first;
      return UserModel.fromMap(doc.id, doc.data());
    } catch (e) {
      return null;
    }
  }
}
