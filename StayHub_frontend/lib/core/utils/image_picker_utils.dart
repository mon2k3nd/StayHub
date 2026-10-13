import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'image_compress_helper.dart';
import 'toast_utils.dart';
import 'dart:async' show unawaited;

class ImagePickerUtils {
  static final ImagePicker _picker = ImagePicker();

  /// Đọc bytes an toàn từ XFile (hoạt động cả trên Web — nơi path là blob URL).
  static Future<Uint8List?> _readBytes(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      return bytes.isEmpty ? null : bytes;
    } catch (_) {
      return null;
    }
  }

  static Future<void> showPicker({
    required BuildContext context,
    int? limit,
    required Function(List<XFile>) onPicked,
  }) async {
    if (limit != null && limit <= 0) return;

    unawaited(
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return Material(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SafeArea(
                bottom: true,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      limit != null
                          ? 'Chọn ảnh (tối đa $limit ảnh)'
                          : 'Chọn ảnh',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(
                        CupertinoIcons.camera,
                        color: Color(0xFF298FFF),
                      ),
                      title: const Text(
                        'Chụp ảnh mới',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onTap: () async {
                        Navigator.pop(ctx);
                        final picked = await _picker.pickImage(
                          source: ImageSource.camera,
                          imageQuality: 70,
                        );
                        if (picked == null) return;
                        // Đọc bytes TRƯỚC khi nén: trên Web path là blob URL,
                        // đọc sau khi nén có thể rỗng → ảnh trắng.
                        final rawBytes = await _readBytes(picked);
                        if (rawBytes == null) return;
                        final compressed =
                            await ImageCompressHelper.compressXFile(picked);
                        final bytes = await _readBytes(compressed) ?? rawBytes;
                        onPicked([
                          XFile.fromData(
                            bytes,
                            name: picked.name,
                            mimeType: picked.mimeType,
                          ),
                        ]);
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        CupertinoIcons.photo_on_rectangle,
                        color: Color(0xFF298FFF),
                      ),
                      title: const Text(
                        'Chọn từ thư viện',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onTap: () async {
                        Navigator.pop(ctx);
                        final pickedList = await _picker.pickMultiImage(
                          imageQuality: 70,
                          limit: limit,
                        );
                        if (pickedList.isNotEmpty) {
                          List<XFile> finalFiles = pickedList;
                          if (limit != null && pickedList.length > limit) {
                            if (context.mounted) {
                              ToastUtils.show(
                                context,
                                'Chỉ được chọn tối đa $limit ảnh. Các ảnh thừa đã bị bỏ qua.',
                                isError: true,
                              );
                            }
                            finalFiles = pickedList.sublist(0, limit);
                          }

                          // Đọc bytes TRƯỚC khi nén (Web path là blob URL) rồi nén,
                          // đảm bảo XFile trả về luôn có bytes hợp lệ để hiển thị.
                          List<XFile> resultFiles = [];
                          for (var f in finalFiles) {
                            final rawBytes = await _readBytes(f);
                            if (rawBytes == null) continue;
                            final compressed =
                                await ImageCompressHelper.compressXFile(f);
                            final bytes =
                                await _readBytes(compressed) ?? rawBytes;
                            resultFiles.add(
                              XFile.fromData(
                                bytes,
                                name: f.name,
                                mimeType: f.mimeType,
                              ),
                            );
                          }
                          if (resultFiles.isNotEmpty) onPicked(resultFiles);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
