import 'dart:convert';
import 'dart:io';
import '../../features/auth/domain/user_model.dart';

class SessionManager {
  static final File _file = File('${Directory.systemTemp.path}/jagain_sessions.json');

  static Future<List<Map<String, dynamic>>> getSessions() async {
    try {
      if (!await _file.exists()) return [];
      final content = await _file.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Error reading sessions: $e');
    }
    return [];
  }

  static Future<void> addSession(UserModel user, {String? email, String? password}) async {
    try {
      final sessions = await getSessions();
      
      String? savedEmail = email;
      String? savedPassword = password;
      
      final existingIndex = sessions.indexWhere((s) => s['uid'] == user.uid);
      if (existingIndex != -1) {
        final existing = sessions[existingIndex];
        savedEmail ??= existing['email'];
        savedPassword ??= existing['password'];
        sessions.removeAt(existingIndex);
      }

      sessions.insert(0, {
        'uid': user.uid,
        'username': user.username,
        'name': user.name,
        'avatarUrl': user.avatarUrl,
        'email': savedEmail ?? user.email,
        'password': savedPassword,
        'role': user.role.name,
        'isVerified': user.isVerified,
      });
      await _file.writeAsString(jsonEncode(sessions));
    } catch (e) {
      print('Error saving session: $e');
    }
  }

  static Future<void> removeSession(String uid) async {
    try {
      final sessions = await getSessions();
      sessions.removeWhere((s) => s['uid'] == uid);
      await _file.writeAsString(jsonEncode(sessions));
    } catch (e) {
      print('Error removing session: $e');
    }
  }
}
