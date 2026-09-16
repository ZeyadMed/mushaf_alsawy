import 'dart:developer';
import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageCompressHelper {
  Future<File> compressFile(
    File file, {
    int quality = 88,
    int rotate = 0,
  }) async {
    try {
      final inputPath = file.absolute.path;

      final filename = file.uri.pathSegments.isNotEmpty
          ? file.uri.pathSegments.last
          : 'image_${DateTime.now().millisecondsSinceEpoch}';
      final targetPath =
          '${Directory.systemTemp.path}/${DateTime.now().millisecondsSinceEpoch}_$filename';

      final result = await FlutterImageCompress.compressAndGetFile(
        inputPath,
        targetPath,
        quality: quality,
        rotate: rotate,
      );

      // If compression returned null, fall back to the original file   
      if (result == null) return file;

      // The plugin may return different file-like types (File, XFile). Normalize to File.
      String resultPath;
      try {
        // Prefer .path if available
        final dynamic r = result;
        resultPath = (r.path ?? r.name ?? '').toString();
      } catch (_) {
        // Fallback to targetPath
        resultPath = targetPath;
      }

      final outFile = File(resultPath);

      log('Original size: ${file.lengthSync()} bytes');
      log('Compressed size: ${outFile.lengthSync()} bytes');

      return outFile;
    } catch (e) {
      // On any error return the original file so callers can continue
      log('Image compression failed: $e');
      return file;
    }
  }
}
