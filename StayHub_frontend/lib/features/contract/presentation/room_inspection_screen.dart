import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/liquid_background.dart';
import '../../../core/components/glass_button.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/image_picker_utils.dart';
import 'package:dio/dio.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/application/auth_notifier.dart';
import '../../../core/components/responsive_file_image.dart';
import 'dart:async' show unawaited;

// Top-level function for Isolate
Future<List<int>> compressImageInIsolate(String path) async {
  final result = await FlutterImageCompress.compressWithFile(
    path,
    minWidth: 1080,
    minHeight: 1080,
    quality: 70, // Giảm dung lượng
  );
  return result ?? <int>[];
}

class RoomInspectionScreen extends ConsumerStatefulWidget {
  final int roomId;
  const RoomInspectionScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomInspectionScreen> createState() =>
      _RoomInspectionScreenState();
}

class _RoomInspectionScreenState extends ConsumerState<RoomInspectionScreen> {
  final List<File> _images = [];
  final _noteCtrl = TextEditingController();
  bool _isCompressing = false;

  Future<void> _pickImages() async {
    unawaited(
      ImagePickerUtils.showPicker(
        context: context,
        limit: 10,
        onPicked: (pickedFiles) async {
          if (pickedFiles.isNotEmpty) {
            setState(() => _isCompressing = true);

            for (var file in pickedFiles) {
              // Chạy compute (Isolate) để không block UI thread
              final compressedBytes = await compute(
                compressImageInIsolate,
                file.path,
              );

              if (compressedBytes.isNotEmpty) {
                final tempFile = File('${file.path}_compressed.jpg');
                await tempFile.writeAsBytes(compressedBytes);
                setState(() {
                  _images.add(tempFile);
                });
              }
            }
            setState(() => _isCompressing = false);
          }
        },
      ),
    );
  }

  Future<void> _submitInspection() async {
    if (_images.isEmpty) {
      _showDialog('Vui lòng chụp ít nhất 1 ảnh hiện trạng phòng.');
      return;
    }

    setState(() => _isCompressing = true);

    try {
      final apiClient = ref.read(apiClientProvider);

      // 1. Get active contract for room
      final contractRes = await apiClient.get(
        '/v1/contracts/room/${widget.roomId}/active',
      );
      if (contractRes['success'] != true || contractRes['data'] == null) {
        _showDialog('Không tìm thấy hợp đồng hợp lệ cho phòng này.');
        setState(() => _isCompressing = false);
        return;
      }

      final contractId = contractRes['data']['id'];

      // 2. Upload images via multipart form data
      final formData = FormData();
      for (var file in _images) {
        formData.files.add(
          MapEntry(
            'inspectionImages',
            await MultipartFile.fromFile(
              file.path,
              filename: file.path.split('/').last,
            ),
          ),
        );
      }

      final verifyRes = await apiClient.uploadFile(
        '/v1/contracts/$contractId/verify',
        formData,
      );

      if (verifyRes['success'] == true) {
        // 3. Refresh user role
        ref.invalidate(authProvider);

        if (!mounted) return;
        _showDialog(
          'Lưu nghiệm thu thành công! Chào mừng bạn đến với StayHub.',
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) context.go('/tenant-dashboard');
        });
      } else {
        _showDialog('Lỗi: ${verifyRes['message']}');
      }
    } catch (e) {
      _showDialog('Đã xảy ra lỗi hệ thống: $e');
    }

    if (mounted) {
      setState(() => _isCompressing = false);
    }
  }

  void _showDialog(String msg) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Thông báo'),
          content: Text(msg),
          actions: [
            CupertinoDialogAction(
              child: const Text('Đóng'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Nghiệm thu phòng'),
      ),
      child: LiquidBackground(
        colors: AppTheme.kBackgroundLight,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '1. Ghi chú hiện trạng',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                GlassContainer(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: CupertinoTextField(
                    controller: _noteCtrl,
                    maxLines: 4,
                    placeholder: 'Ghi chú các hư hỏng hoặc hiện trạng phòng...',
                    decoration: null,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '2. Hình ảnh nghiệm thu',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: _images.length + 1,
                    itemBuilder: (ctx, i) {
                      if (i == _images.length) {
                        return GestureDetector(
                          onTap: _isCompressing ? null : _pickImages,
                          child: GlassContainer(
                            child: Center(
                              child: _isCompressing
                                  ? const CupertinoActivityIndicator()
                                  : const Icon(
                                      CupertinoIcons.camera,
                                      color: LiquidGlassColors.tenantAccent,
                                    ),
                            ),
                          ),
                        );
                      }
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ResponsiveFileImage(
                          _images[i],
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),
                ),
                GlassButton(
                  text: 'Hoàn tất Nghiệm Thu',
                  color: LiquidGlassColors.tenantAccent,
                  onPressed: _isCompressing ? null : _submitInspection,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
