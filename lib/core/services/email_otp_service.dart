import 'dart:convert';
import 'dart:math';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class EmailOtpService {
  EmailOtpService._internal();

  static final EmailOtpService instance = EmailOtpService._internal();

  static const String _endpoint = 'https://api.emailjs.com/api/v1.0/email/send';

  final Random _random = Random.secure();

  String generateCode() {
    return _random.nextInt(1000000).toString().padLeft(6, '0');
  }

  Future<void> sendVerificationCode({
    required String toEmail,
    required String toName,
    required String code,
    required DateTime expiresAt,
  }) async {
    final serviceId = dotenv.env['EMAILJS_SERVICE_ID'] ?? '';
    final templateId = dotenv.env['EMAILJS_TEMPLATE_ID'] ?? '';
    final publicKey = dotenv.env['EMAILJS_PUBLIC_KEY'] ?? '';
    final privateKey = dotenv.env['EMAILJS_PRIVATE_KEY'] ?? '';

    if (serviceId.isEmpty || templateId.isEmpty || publicKey.isEmpty) {
      throw Exception(
        'Konfigurasi EmailJS belum lengkap. Isi EMAILJS_SERVICE_ID, '
        'EMAILJS_TEMPLATE_ID, EMAILJS_PUBLIC_KEY, dan EMAILJS_PRIVATE_KEY di .env',
      );
    }

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': publicKey,
        'accessToken': privateKey,
        'template_params': {
          'to_email': toEmail,
          'to_name': toName,
          'code': code,
          'time': _formatTime(expiresAt),
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal mengirim kode verifikasi (${response.statusCode}): ${response.body}',
      );
    }
  }

  static const Duration _wibOffset = Duration(hours: 7);

  String _formatTime(DateTime time) {
    final wibTime = time.toUtc().add(_wibOffset);
    final hour = wibTime.hour.toString().padLeft(2, '0');
    final minute = wibTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute WIB';
  }
}
