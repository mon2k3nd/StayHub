import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/dashboard_refresh.dart';
import '../../../core/components/responsive_file_image.dart';
import '../../../core/utils/image_picker_utils.dart';
import 'dart:async' show unawaited;

class OfflineContractVerifyScreen extends ConsumerStatefulWidget {
  final int roomId;
  final int? contractId;

  const OfflineContractVerifyScreen({
    super.key,
    required this.roomId,
    this.contractId,
  });

  @override
  ConsumerState<OfflineContractVerifyScreen> createState() =>
      _OfflineContractVerifyScreenState();
}

class _OfflineContractVerifyScreenState
    extends ConsumerState<OfflineContractVerifyScreen> {
  final List<XFile> _contractImages = [];
  final List<XFile> _cccdImages = [];
  bool _isLoading = false;

  Future<void> _pickImage(bool isContract) async {
    unawaited(
      ImagePickerUtils.showPicker(
        context: context,
        limit: 10,
        onPicked: (pickedFiles) {
          if (pickedFiles.isNotEmpty) {
            setState(() {
              if (isContract) {
                _contractImages.addAll(pickedFiles);
              } else {
                _cccdImages.addAll(pickedFiles);
              }
            });
          }
        },
      ),
    );
  }

  void _removeImage(int index, bool isContract) {
    setState(() {
      if (isContract) {
        _contractImages.removeAt(index);
      } else {
        _cccdImages.removeAt(index);
      }
    });
  }

  Future<void> _submit() async {
    if (_contractImages.isEmpty || _cccdImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng upload ảnh Hợp đồng và CCCD!')),
      );
      return;
    }

    // Tạm thời nếu contractId = null, ta phải query hợp đồng pending theo roomId
    int targetContractId = widget.contractId ?? 0;

    // Nếu chưa truyền contractId thì phải xử lý lỗi
    if (targetContractId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không tìm thấy ID hợp đồng. Vui lòng thử lại.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioProvider);
      FormData formData = FormData();

      for (var file in _contractImages) {
        formData.files.add(
          MapEntry(
            'contractImages',
            await MultipartFile.fromFile(file.path, filename: file.name),
          ),
        );
      }

      for (var file in _cccdImages) {
        formData.files.add(
          MapEntry(
            'cccdImages',
            await MultipartFile.fromFile(file.path, filename: file.name),
          ),
        );
      }

      await dio.post(
        '/v1/contracts/$targetContractId/offline-verify',
        data: formData,
      );

      refreshOwnerDashboardFromWidget(ref);

      if (mounted) {
        await showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('🎉 Kích Hoạt Thành Công!'),
            content: const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                'Phòng đã được kích hoạt và chuyển sang trạng thái Đang Cho Thuê. Hợp đồng có hiệu lực ngay bây giờ.',
              ),
            ),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/contract');
                },
                child: const Text('Xem Danh sách Hợp Đồng'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _cancel() async {
    int targetContractId = widget.contractId ?? 0;
    if (targetContractId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy ID hợp đồng.')),
      );
      return;
    }

    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Hủy Hợp Đồng'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            'Bạn có chắc chắn muốn hủy hợp đồng này? Phòng sẽ được trả về trạng thái Trống.',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Không'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Có, Hủy'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/v1/contracts/$targetContractId/cancel');
      refreshOwnerDashboardFromWidget(ref);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã hủy hợp đồng chờ kích hoạt.')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.kBackgroundLight,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        border: null,
        middle: const Text('Kích hoạt Hợp đồng Offline'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(
            CupertinoIcons.back,
            color: CupertinoColors.activeBlue,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Vui lòng tải lên ảnh chụp Hợp đồng bản cứng đã ký và CCCD (2 mặt) của khách để hoàn tất quy trình.',
                  style: TextStyle(fontSize: 14, color: CupertinoColors.black),
                ),
              ),
              const SizedBox(height: 24),
              _buildUploadSection('Ảnh Hợp Đồng / Biên bản đã ký', true),
              const SizedBox(height: 24),
              _buildUploadSection('Ảnh CCCD/CMND Khách hàng', false),
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kAccentColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Hoàn tất & Kích hoạt Phòng',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _cancel,
                child: const Text(
                  'Hủy Hợp Đồng Này',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadSection(String title, bool isContract) {
    final images = isContract ? _contractImages : _cccdImages;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            TextButton.icon(
              icon: const Icon(CupertinoIcons.camera_fill, size: 18),
              label: const Text('Thêm ảnh'),
              onPressed: () => _pickImage(isContract),
            ),
          ],
        ),
        if (images.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (ctx, i) {
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      width: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: getResponsiveFileImageProvider(images[i].path),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => _removeImage(i, isContract),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          )
        else
          GestureDetector(
            onTap: () => _pickImage(isContract),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFD1D5DB),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.photo_on_rectangle,
                    color: Colors.grey.shade400,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Chạm để tải ảnh lên',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
