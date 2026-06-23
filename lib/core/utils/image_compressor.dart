import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Utility class to resize and compress images before uploading.
/// Produces files with max 1080px on longest side at 85% JPEG quality,
/// matching the behaviour of Instagram / most modern social apps.
class ImageCompressor {
  ImageCompressor._();

  static const int _maxDimension = 1080;
  static const int _quality = 85;

  /// Compresses [file] and returns a new [File] with smaller size.
  /// The original file is NOT modified.
  static Future<File> compress(File file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final outPath =
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        outPath,
        quality: _quality,
        minWidth: _maxDimension,
        minHeight: _maxDimension,
        format: CompressFormat.jpeg,
        keepExif: false,
      );

      if (result == null) {
        debugPrint('ImageCompressor: compression returned null, using original');
        return file;
      }

      final compressedFile = File(result.path);
      final originalSize = await file.length();
      final compressedSize = await compressedFile.length();
      debugPrint(
        'ImageCompressor: '
        '${(originalSize / 1024).toStringAsFixed(0)}KB → '
        '${(compressedSize / 1024).toStringAsFixed(0)}KB '
        '(${((1 - compressedSize / originalSize) * 100).toStringAsFixed(0)}% reduction)',
      );

      return compressedFile;
    } catch (e) {
      debugPrint('ImageCompressor: error — $e. Using original file.');
      return file;
    }
  }

  /// Compresses a list of image files concurrently.
  static Future<List<File>> compressAll(List<File> files) async {
    return Future.wait(files.map(compress));
  }
}
