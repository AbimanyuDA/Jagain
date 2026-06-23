import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

/// Handler untuk notifikasi yang diterima saat app TERTUTUP / background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM Background] Pesan diterima: ${message.notification?.title}');
}

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotif =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'jagain_high_importance',
    'Jagain Notifikasi',
    description: 'Notifikasi penting dari aplikasi Jagain',
    importance: Importance.high,
  );

  // Cache access token agar tidak request ulang setiap kali
  String? _cachedAccessToken;
  DateTime? _tokenExpiry;

  // Router untuk navigasi saat notif ditekan
  GoRouter? _router;

  // Pending route jika router belum siap saat notif ditekan
  String? _pendingRoute;

  /// Set router dari main.dart agar bisa navigate saat notif ditekan.
  void setRouter(GoRouter router) {
    _router = router;

    // Eksekusi pending route jika ada (notif ditekan sebelum router siap)
    if (_pendingRoute != null) {
      final route = _pendingRoute!;
      _pendingRoute = null;
      Future.microtask(() => _router!.go(route));
    }
  }

  /// Handle notif yang ditekan saat app TERTUTUP (terminated).
  /// Panggil dari initState di _AppViewState.
  Future<void> handleInitialMessage() async {
    await Future.delayed(const Duration(milliseconds: 500));

    // 1. Cek FCM notification tap (notif diterima saat app background)
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message != null && message.data.isNotEmpty) {
      debugPrint('[FCM] App dibuka dari FCM terminated: ${message.data}');
      _navigateFromData(message.data);
      return;
    }

    // 2. Cek local notification tap (notif foreground flutter_local_notifications)
    final launchDetails = await _localNotif.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final payload = launchDetails?.notificationResponse?.payload;
      debugPrint('[FCM] App dibuka dari local notif: $payload');
      if (payload != null) {
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          _navigateFromData(data);
        } catch (e) {
          debugPrint('[FCM] Error parse payload: $e');
        }
      }
    }
  }

  /// Navigate ke halaman yang tepat berdasarkan data notifikasi.
  /// Jika router belum siap, simpan sebagai pending.
  void _navigateFromData(Map<String, dynamic> data) {
    // Semua notif arahkan ke /settings — aman untuk semua role
    const route = '/settings';

    if (_router != null) {
      debugPrint('[FCM] Navigate ke: $route');
      _router!.go(route);
    } else {
      debugPrint('[FCM] Router belum siap, simpan pending route: $route');
      _pendingRoute = route;
    }
  }

  /// Inisialisasi FCM + local notifications. Panggil sekali di main().
  Future<void> initialize() async {
    // Setup listener onMessageOpenedApp SEBELUM router siap
    // (event bisa fire sebelum build() dipanggil)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] App dibuka dari notif background: ${message.data}');
      _navigateFromData(message.data);
    });
    // 1. Setup Android notification channel
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 2. Init flutter_local_notifications dengan tap handler
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _localNotif.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Notif ditekan saat app FOREGROUND
        debugPrint('[FCM] Notif foreground ditekan: ${response.payload}');
        if (response.payload != null) {
          try {
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            _navigateFromData(data);
          } catch (_) {}
        }
      },
    );

    // 3. Request permission dari user
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4. Background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 5. Foreground handler — tampilkan notif lokal saat app terbuka
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null && !kIsWeb) {
        // Encode data sebagai payload untuk bisa navigate saat ditekan
        final payload = jsonEncode(message.data);
        _localNotif.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          payload: payload,
        );
      }
    });

    debugPrint('[FCM] NotificationService initialized');
  }

  /// Simpan FCM token ke Firestore user document.
  Future<void> saveTokenToFirestore(String uid) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': token,
      });
      debugPrint('[FCM] Token saved for uid: $uid');
    } catch (e) {
      debugPrint('[FCM] Error saving token: $e');
    }
  }

  /// Dapatkan OAuth2 access token dari Google menggunakan service account.
  Future<String?> _getAccessToken() async {
    if (_cachedAccessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _cachedAccessToken;
    }

    try {
      final clientEmail = dotenv.env['FCM_CLIENT_EMAIL'] ?? '';
      final privateKeyRaw = dotenv.env['FCM_PRIVATE_KEY'] ?? '';

      if (clientEmail.isEmpty || privateKeyRaw.isEmpty) {
        debugPrint('[FCM] FCM_CLIENT_EMAIL atau FCM_PRIVATE_KEY belum diatur di .env');
        return null;
      }

      final privateKey = privateKeyRaw.replaceAll('\\n', '\n');

      final now = DateTime.now();
      final exp = now.add(const Duration(hours: 1));

      final jwt = JWT({
        'iss': clientEmail,
        'sub': clientEmail,
        'aud': 'https://oauth2.googleapis.com/token',
        'iat': now.millisecondsSinceEpoch ~/ 1000,
        'exp': exp.millisecondsSinceEpoch ~/ 1000,
        'scope': 'https://www.googleapis.com/auth/firebase.messaging',
      });

      final token = jwt.sign(
        RSAPrivateKey(privateKey),
        algorithm: JWTAlgorithm.RS256,
      );

      final response = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
          'assertion': token,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _cachedAccessToken = data['access_token'] as String?;
        _tokenExpiry = DateTime.now().add(const Duration(minutes: 55));
        debugPrint('[FCM] Access token berhasil didapat');
        return _cachedAccessToken;
      } else {
        debugPrint('[FCM] Gagal dapat access token (${response.statusCode}): ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('[FCM] Error mendapatkan access token: $e');
      return null;
    }
  }

  /// Kirim notifikasi push ke satu FCM token via FCM V1 API.
  Future<void> sendNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        debugPrint('[FCM] Tidak bisa kirim notif: access token null');
        return;
      }

      final projectId = dotenv.env['FIREBASE_PROJECT_ID'] ?? 'jagain-fppbb';
      final url = 'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'token': fcmToken,
            'notification': {'title': title, 'body': body},
            'android': {
              'priority': 'high',
              'notification': {'sound': 'default'},
            },
            'data': data ?? {},
          },
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('[FCM] Notifikasi terkirim ke $fcmToken');
      } else {
        debugPrint('[FCM] Gagal kirim notif (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      debugPrint('[FCM] Error mengirim notifikasi: $e');
    }
  }

  /// Kirim notifikasi ke semua admin.
  Future<void> sendToAdmins({
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      for (final doc in snapshot.docs) {
        final token = doc.data()['fcmToken'] as String?;
        if (token != null && token.isNotEmpty) {
          await sendNotification(fcmToken: token, title: title, body: body, data: data);
        }
      }
    } catch (e) {
      debugPrint('[FCM] Error kirim notif ke admin: $e');
    }
  }

  /// Kirim notifikasi ke satu user berdasarkan UID.
  Future<void> sendToUser({
    required String uid,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final token = doc.data()?['fcmToken'] as String?;
      if (token != null && token.isNotEmpty) {
        await sendNotification(fcmToken: token, title: title, body: body, data: data);
      }
    } catch (e) {
      debugPrint('[FCM] Error kirim notif ke user $uid: $e');
    }
  }
}
