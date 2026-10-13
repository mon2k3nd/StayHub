import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class ImageCompressHelper {
  /// Nén một ảnh (File) về kích thước mục tiêu (tối đa ~2MB).
  /// Nếu ảnh nhỏ hơn dung lượng mục tiêu thì giữ nguyên.
  static Future<File?> compressImage(
    File file, {
    int quality = 80,
    int minWidth = 1920,
    int minHeight = 1920,
  }) async {
    if (kIsWeb) return file;
    try {
      final fileSize = await file.length();
      // Nếu dung lượng ảnh nhỏ hơn 1MB thì không cần nén thêm để giữ chất lượng gốc.
      if (fileSize < 1024 * 1024) {
        return file;
      }

      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.absolute.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg';

      var result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        final compressedFile = File(result.path);
        final compressedSize = await compressedFile.length();
        debugPrint(
          '[ImageCompressHelper] Nén thành công: ${fileSize / 1024 / 1024}MB -> ${compressedSize / 1024 / 1024}MB',
        );
        return compressedFile;
      }
      return file; // Trả về ảnh gốc nếu nén thất bại
    } catch (e) {
      debugPrint('[ImageCompressHelper] Lỗi khi nén ảnh: $e');
      return file; // Trả về ảnh gốc nếu có lỗi
    }
  }

  /// Nén XFile và trả về XFile
  static Future<XFile> compressXFile(XFile xFile) async {
    if (kIsWeb) return xFile;
    final file = File(xFile.path);
    final compressedFile = await compressImage(file);
    if (compressedFile != null) {
      return XFile(compressedFile.path);
    }
    return xFile;
  }
}
