import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return await getUser(firebaseUser.uid);
    });
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? wilayah,
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
        email: email,
        role: role,
        wilayah: wilayah,
        isVerified: false,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(uid)
          .set(newUser.toMap());

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
}
