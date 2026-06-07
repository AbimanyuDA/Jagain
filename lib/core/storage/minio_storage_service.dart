import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:minio/minio.dart';
import 'package:uuid/uuid.dart';

class MinioFolder {
  static const String reportPhotos = 'reports';
  static const String avatars = 'avatars';
  static const String statusProofs = 'proofs';

  const MinioFolder._();
}

class MinioStorageService {
  MinioStorageService._internal()
    : _minio = Minio(
        endPoint: dotenv.env['MINIO_ENDPOINT'] ?? '',
        port: int.tryParse(dotenv.env['MINIO_PORT'] ?? ''),
        accessKey: dotenv.env['MINIO_ACCESS_KEY'] ?? '',
        secretKey: dotenv.env['MINIO_SECRET_KEY'] ?? '',
        useSSL: (dotenv.env['MINIO_USE_SSL'] ?? 'true').toLowerCase() == 'true',
      ),
      _bucket = dotenv.env['MINIO_BUCKET'] ?? '',
      _publicUrlBase = dotenv.env['MINIO_PUBLIC_URL_BASE'] ?? '';

  static final MinioStorageService instance = MinioStorageService._internal();

  final Minio _minio;
  final String _bucket;
  final String _publicUrlBase;
  final Uuid _uuid = const Uuid();

  Future<String> uploadImage({
    required File file,
    required String folder,
    required String ownerId,
  }) async {
    final extension = _extractExtension(file.path);
    final objectName = '$folder/$ownerId/${_uuid.v4()}$extension';

    final bytes = await file.readAsBytes();
    await _minio.putObject(
      _bucket,
      objectName,
      Stream.value(bytes),
      size: bytes.length,
      metadata: {'Content-Type': _contentTypeFor(extension)},
    );

    return '$_publicUrlBase/$objectName';
  }

  Future<List<String>> uploadImages({
    required List<File> files,
    required String folder,
    required String ownerId,
  }) async {
    final urls = <String>[];
    for (final file in files) {
      urls.add(await uploadImage(file: file, folder: folder, ownerId: ownerId));
    }
    return urls;
  }

  String _extractExtension(String path) {
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == path.length - 1) return '.jpg';
    return path.substring(dotIndex).toLowerCase();
  }

  String _contentTypeFor(String extension) {
    switch (extension) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.heic':
        return 'image/heic';
      case '.jpg':
      case '.jpeg':
      default:
        return 'image/jpeg';
    }
  }
}
