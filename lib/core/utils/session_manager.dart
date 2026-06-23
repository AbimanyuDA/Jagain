import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../features/auth/domain/user_model.dart';

class SessionManager {
  static const _secureStorage = FlutterSecureStorage();

  static String _passwordKey(String uid) => 'session_password_$uid';

  // Use the app's persistent documents directory so sessions survive
  // OS temp-folder cleanups (fixes the account-switch bug on iOS).
  static Future<File> _sessionFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/jagain_sessions.json');
  }

  static Future<List<Map<String, dynamic>>> getSessions() async {
    try {
      final file = await _sessionFile();
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('SessionManager: Error reading sessions — $e');
    }
    return [];
  }

  /// Kredensial login (password) untuk akun yang tersimpan, dibaca dari
  /// secure storage (Keychain di iOS, EncryptedSharedPreferences di Android).
  /// Tidak semua akun punya ini — hanya akun yang pernah login lewat form
  /// login/register di perangkat ini.
  static Future<String?> getPassword(String uid) {
    return _secureStorage.read(key: _passwordKey(uid));
  }

  static Future<void> addSession(
    UserModel user, {
    String? email,
    String? password,
  }) async {
    try {
      final sessions = await getSessions();

      String? savedEmail = email;

      final existingIndex = sessions.indexWhere((s) => s['uid'] == user.uid);
      if (existingIndex != -1) {
        final existing = sessions[existingIndex];
        savedEmail ??= existing['email'] as String?;
        sessions.removeAt(existingIndex);
      }

      sessions.insert(0, {
        'uid': user.uid,
        'username': user.username,
        'name': user.name,
        'avatarUrl': user.avatarUrl,
        'email': savedEmail ?? user.email,
        'role': user.role.name,
        'isVerified': user.isVerified,
      });

      final file = await _sessionFile();
      await file.writeAsString(jsonEncode(sessions));

      // Password disimpan terenkripsi terpisah dari metadata akun, dan hanya
      // ditulis ulang jika ada nilai baru (mis. saat login/register/switch).
      if (password != null) {
        await _secureStorage.write(
          key: _passwordKey(user.uid),
          value: password,
        );
      }
    } catch (e) {
      debugPrint('SessionManager: Error saving session — $e');
    }
  }

  static Future<void> removeSession(String uid) async {
    try {
      final sessions = await getSessions();
      sessions.removeWhere((s) => s['uid'] == uid);
      final file = await _sessionFile();
      await file.writeAsString(jsonEncode(sessions));
      await _secureStorage.delete(key: _passwordKey(uid));
    } catch (e) {
      debugPrint('SessionManager: Error removing session — $e');
    }
  }
}
