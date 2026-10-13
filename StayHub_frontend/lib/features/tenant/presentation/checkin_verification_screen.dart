import 'package:flutter/material.dart' show LinearProgressIndicator;
import 'package:flutter/cupertino.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:dio/dio.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/providers/core_providers.dart';
import '../application/tenant_dashboard_notifier.dart';
import '../../../core/components/responsive_file_image.dart';
import 'package:stayhub_frontend/core/components/stayhub_logo_icon.dart';
import 'dart:async' show unawaited;

Future<String?> _compressTask(String path) async {
  final targetPath = '${path}_compressed.jpg';
  final result = await FlutterImageCompress.compressAndGetFile(
    path,
    targetPath,
    quality: 70,
    minWidth: 1024,
    minHeight: 1024,
  );
  return result?.path;
}

class FurnitureItem {
  final XFile file;
  final String note;
  FurnitureItem(this.file, this.note);
}

class CheckinVerificationScreen extends ConsumerStatefulWidget {
  final dynamic room;
  const CheckinVerificationScreen({super.key, required this.room});

  @override
  ConsumerState<CheckinVerificationScreen> createState() =>
      _CheckinVerificationScreenState();
}

class _CheckinVerificationScreenState
    extends ConsumerState<CheckinVerificationScreen> {
  final List<XFile> _contractImages = [];
  bool _hasPaperContract = false;
  XFile? _electricityImage;
  XFile? _waterImage;
  final List<XFile> _conditionImages = [];
  final List<FurnitureItem> _furnitureItems = [];
  bool _hasMeters = false;
  bool _hasFurniture = true;
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  String _uploadStatusText = '';

  @override
  Widget build(BuildContext context) {
    if (widget.room == null) {
      return _buildGuideView();
    }

    return LiquidGlassScaffold(
      title: 'Nghiệm thu',
      backgroundColors: AppTheme.kBackgroundLight,
      child: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              children: [
                _buildRoomInfoBanner(),
                const SizedBox(height: 24),
                _buildContractUploadSection(),
                const SizedBox(height: 24),
                _buildMeterUploadSection(),
                const SizedBox(height: 24),
                _buildConditionUploadSection(),
                const SizedBox(height: 24),
                _buildFurnitureUploadSection(),
                const SizedBox(height: 40),
                _buildCompleteButton(),
              ],
            ),
          ),
          // Upload Progress Overlay
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: CupertinoColors.black.withValues(alpha: 0.6),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.cloud_upload_fill,
                          size: 40,
                          color: AppTheme.kBrand,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Đang tải lên ảnh...',
                          style: TextStyle(
                            color: Color(0xFF111827),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _uploadStatusText,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _uploadProgress > 0 ? _uploadProgress : null,
                            backgroundColor: const Color(0xFFE5E7EB),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.kBrand,
                            ),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_uploadProgress > 0)
                          Text(
                            '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: AppTheme.kBrand,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoomInfoBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.kBrand.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const StayHubLogoIcon(color: AppTheme.kBrand, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.room is Map
                      ? (widget.room['roomName'] ?? 'Phòng')
                      : widget.room.roomName,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Đang trong quá trình bàn giao',
                  style: TextStyle(color: Color(0xFF4B5563), fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractUploadSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1. Hợp đồng',
                      style: TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Chợp ảnh hợp đồng giấy (nếu có).',
                      style: TextStyle(color: Color(0xFF4B5563), fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Nút Xem Hợp đồng PDF
              CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                onPressed: _viewContractPdf,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.kBrand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.kBrand.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.doc_text_fill,
                        color: AppTheme.kBrand,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Xem HĐ',
                        style: TextStyle(
                          color: AppTheme.kBrand,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Toggle hợp đồng cứng
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _hasPaperContract
                  ? AppTheme.kBrand.withValues(alpha: 0.05)
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hasPaperContract
                    ? AppTheme.kBrand.withValues(alpha: 0.3)
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _hasPaperContract
                      ? CupertinoIcons.doc_fill
                      : CupertinoIcons.doc,
                  color: _hasPaperContract
                      ? AppTheme.kBrand
                      : const Color(0xFF9CA3AF),
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Có hợp đồng cứng (giấy)?',
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Bật để chụp ảnh các trang hợp đồng giấy đã ký.',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoSwitch(
                  value: _hasPaperContract,
                  onChanged: (val) => setState(() => _hasPaperContract = val),
                  activeTrackColor: AppTheme.kBrand,
                ),
              ],
            ),
          ),
          if (_hasPaperContract) ...[
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _contractImages.length + 1,
              itemBuilder: (ctx, index) {
                if (index == _contractImages.length) {
                  return CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _pickImage(
                      (f) => setState(() => _contractImages.add(f!)),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Center(
                        child: Icon(
                          CupertinoIcons.plus,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  );
                }
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: getResponsiveFileImageProvider(
                        _contractImages[index].path,
                      ),
                      fit: BoxFit.cover,
                    ),
                    color: const Color(0xFFE5E7EB),
                  ),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () =>
                          setState(() => _contractImages.removeAt(index)),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: CupertinoColors.black,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.xmark,
                          color: CupertinoColors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _viewContractPdf() async {
    final room = widget.room;
    if (room == null) return;
    try {
      setState(() => _isLoading = true);
      final dio = ref.read(apiClientProvider);
      final roomId = room is Map ? room['id'] : room.id;
      final contractRes = await dio.get('/v1/contracts/room/$roomId/active');
      if (contractRes['success'] == true && contractRes['data'] != null) {
        final cId = contractRes['data']['id'];
        setState(() {
          _isLoading = false;
        });
        if (!mounted) return;
        // unawaited(Navigate to contract preview)
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (dctx) => CupertinoAlertDialog(
              title: const Text('Xem Hợp Đồng'),
              content: Text(
                'Hợp đồng #$cId. Bạn có muốn mở trang xem hợp đồng không?',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Đóng'),
                  onPressed: () => Navigator.pop(dctx),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('Xem ngay'),
                  onPressed: () {
                    Navigator.pop(dctx);
                    // Push to contract screen with contractId
                    Navigator.of(
                      context,
                    ).pop(); // close verification temporarily
                  },
                ),
              ],
            ),
          ),
        );
      } else {
        setState(() => _isLoading = false);
        _showDialog(
          'Thông báo',
          'Chưa tìm thấy hợp đồng. Vui lòng đợi chủ nhà tạo hợp đồng.',
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showDialog('Lỗi', 'Không thể tải hợp đồng: $e');
    }
  }

  Widget _buildMeterUploadSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '2. Tình trạng Đồng hồ',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              CupertinoSwitch(
                value: _hasMeters,
                onChanged: (val) => setState(() => _hasMeters = val),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Có công tơ điện/nước riêng không? Bật lên để chụp.',
            style: TextStyle(color: Color(0xFF4B5563), fontSize: 13),
          ),
          if (_hasMeters) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSingleImagePicker(
                    file: _electricityImage,
                    onTap: () => _pickImage(
                      (f) => setState(() => _electricityImage = f),
                    ),
                    label: 'Đồng hồ điện',
                    icon: CupertinoIcons.bolt_fill,
                    compact: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSingleImagePicker(
                    file: _waterImage,
                    onTap: () =>
                        _pickImage((f) => setState(() => _waterImage = f)),
                    label: 'Đồng hồ nước',
                    icon: CupertinoIcons.drop_fill,
                    compact: true,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSingleImagePicker({
    required XFile? file,
    required VoidCallback onTap,
    required String label,
    IconData? icon,
    bool compact = false,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: compact ? 16 : 24),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: file != null ? AppTheme.kBrand : const Color(0xFFE5E7EB),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(
              file != null
                  ? CupertinoIcons.checkmark_alt_circle_fill
                  : (icon ?? CupertinoIcons.camera_fill),
              color: file != null ? AppTheme.kBrand : const Color(0xFF9CA3AF),
              size: compact ? 24 : 32,
            ),
            const SizedBox(height: 8),
            Text(
              file != null ? 'Đã tải lên' : label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: file != null ? AppTheme.kBrand : const Color(0xFF4B5563),
                fontSize: compact ? 12 : 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionUploadSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '3. Hiện trạng Phòng trọ',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Chụp ảnh hiện trạng phòng, sàn, tường, trần... (Tối đa 10 ảnh).',
            style: TextStyle(color: Color(0xFF4B5563), fontSize: 13),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _conditionImages.length < 10
                ? _conditionImages.length + 1
                : 10,
            itemBuilder: (ctx, index) {
              if (index == _conditionImages.length) {
                return CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => _pickImage(
                    (f) => setState(() => _conditionImages.add(f!)),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: const Center(
                      child: Icon(
                        CupertinoIcons.plus,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                );
              }

              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: getResponsiveFileImageProvider(
                      _conditionImages[index].path,
                    ),
                    fit: BoxFit.cover,
                  ),
                  color: const Color(0xFFE5E7EB),
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () =>
                        setState(() => _conditionImages.removeAt(index)),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: CupertinoColors.black,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.xmark,
                        color: CupertinoColors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFurnitureUploadSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '4. Nội thất bàn giao',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              CupertinoSwitch(
                value: _hasFurniture,
                onChanged: (val) => setState(() => _hasFurniture = val),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Có bàn giao nội thất không? (Bật lên để thêm ảnh và ghi chú).',
            style: TextStyle(color: Color(0xFF4B5563), fontSize: 13),
          ),
          if (_hasFurniture) ...[
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85, // cao hơn 1 chút để chứa text
              ),
              itemCount: _furnitureItems.length < 10
                  ? _furnitureItems.length + 1
                  : 10,
              itemBuilder: (ctx, index) {
                if (index == _furnitureItems.length) {
                  return CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _pickFurnitureImage(),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.camera_fill,
                              color: Color(0xFF9CA3AF),
                              size: 32,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Thêm ảnh',
                              style: TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final item = _furnitureItems[index];
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: getResponsiveFileImageProvider(item.file.path),
                          fit: BoxFit.cover,
                        ),
                        color: const Color(0xFFE5E7EB),
                      ),
                    ),
                    // Lớp phủ đen nhạt ở dưới để chữ nổi bật
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                          color: CupertinoColors.black.withValues(alpha: 0.6),
                        ),
                        child: Text(
                          item.note.isEmpty ? 'Không có ghi chú' : item.note,
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () =>
                            setState(() => _furnitureItems.removeAt(index)),
                        child: Container(
                          margin: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: CupertinoColors.black,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.xmark,
                            color: CupertinoColors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickFurnitureImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera);
    if (file != null) {
      // Hiện dialog điền note
      if (!mounted) return;
      final TextEditingController noteCtrl = TextEditingController();
      unawaited(
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Ghi chú nội thất'),
            content: Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: CupertinoTextField(
                controller: noteCtrl,
                placeholder: 'Tủ lạnh xước, điều hòa cũ...',
                minLines: 2,
                maxLines: 4,
              ),
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Bỏ qua'),
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() => _furnitureItems.add(FurnitureItem(file, '')));
                },
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Lưu'),
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(
                    () => _furnitureItems.add(
                      FurnitureItem(file, noteCtrl.text.trim()),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildCompleteButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _isLoading ? null : _submitVerification,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: AppTheme.kBrand,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.kBrand.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: _isLoading
                ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                : const Text(
                    'Hoàn tất Nghiệm thu',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(Function(XFile?) onPicked) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera);
    if (file != null) onPicked(file);
  }

  Future<void> _submitVerification() async {
    if (_contractImages.isEmpty) {
      _showDialog('Lỗi', 'Vui lòng chụp ít nhất 1 ảnh minh chứng Hợp đồng.');
      return;
    }
    if (_hasMeters && (_electricityImage == null || _waterImage == null)) {
      _showDialog('Lỗi', 'Vui lòng chụp ảnh đồng hồ điện và nước.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dio = ref.read(apiClientProvider);

      // Nén ảnh (không dùng compute vì thư viện native tự chạy background)
      List<MultipartFile> compressedContracts = [];
      for (var file in _contractImages) {
        final cPath = await _compressTask(file.path);
        if (cPath != null) {
          compressedContracts.add(await MultipartFile.fromFile(cPath));
        }
      }

      List<MultipartFile> compressedInspections = [];
      for (var file in _conditionImages) {
        final cPath = await _compressTask(file.path);
        if (cPath != null) {
          compressedInspections.add(await MultipartFile.fromFile(cPath));
        }
      }

      List<MultipartFile> compressedFurnitures = [];
      List<String> furnitureNotes = [];
      if (_hasFurniture) {
        for (var item in _furnitureItems) {
          final cPath = await _compressTask(item.file.path);
          if (cPath != null) {
            compressedFurnitures.add(await MultipartFile.fromFile(cPath));
            furnitureNotes.add(item.note);
          }
        }
      }

      MultipartFile? elecF;
      if (_hasMeters && _electricityImage != null) {
        final cPath = await _compressTask(_electricityImage!.path);
        if (cPath != null) elecF = await MultipartFile.fromFile(cPath);
      }

      MultipartFile? waterF;
      if (_hasMeters && _waterImage != null) {
        final cPath = await _compressTask(_waterImage!.path);
        if (cPath != null) waterF = await MultipartFile.fromFile(cPath);
      }

      final formData = FormData();
      for (var file in compressedContracts) {
        formData.files.add(MapEntry('contractImages', file));
      }
      if (elecF != null) {
        formData.files.add(MapEntry('electricityMeterImage', elecF));
      }
      if (waterF != null) {
        formData.files.add(MapEntry('waterMeterImage', waterF));
      }
      for (var file in compressedInspections) {
        formData.files.add(MapEntry('inspectionImages', file));
      }
      for (var i = 0; i < compressedFurnitures.length; i++) {
        formData.files.add(
          MapEntry('furnitureImages', compressedFurnitures[i]),
        );
      }
      for (var note in furnitureNotes) {
        // Dio supports adding primitive values to fields too
        formData.fields.add(MapEntry('furnitureNotes', note));
      }

      final roomId = widget.room is Map ? widget.room['id'] : widget.room.id;
      if (roomId == null) throw Exception('Không tìm thấy ID phòng');

      // 1. Lấy Contract ID từ Room ID
      final contractRes = await dio.get('/v1/contracts/room/$roomId/active');
      if (contractRes['success'] != true || contractRes['data'] == null) {
        throw Exception(
          'Chưa có hợp đồng nào được tạo cho phòng này. Vui lòng đợi chủ nhà tạo hợp đồng!',
        );
      }
      final contractId = contractRes['data']['id'];

      // 2. Gửi request verify
      setState(() {
        _uploadProgress = 0.0;
        _uploadStatusText = 'Đang nén và gửi ảnh lên server...';
      });
      final response = await dio.uploadFile(
        '/v1/contracts/$contractId/verify',
        formData,
        onSendProgress: (sent, total) {
          if (!mounted) return;
          setState(() {
            _uploadProgress = total > 0 ? sent / total : 0;
            _uploadStatusText =
                'Đã gửi ${(sent / 1024).toStringAsFixed(0)} KB / ${(total / 1024).toStringAsFixed(0)} KB';
          });
        },
      );

      if (response['success'] == true) {
        // Cập nhật State thành Đang thuê (linked) ngay lập tức
        ref.read(tenantDashboardProvider.notifier).completeVerification();

        if (!mounted) return;
        setState(() => _isLoading = false);

        // Đóng màn hình nghiệm thu (Đã được chuyển tab ở trên, không cần pop router)
      } else {
        throw Exception('API trả về lỗi');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showDialog('Lỗi', 'Đã xảy ra lỗi: $e');
    }
  }

  void _showDialog(String title, String message) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(title),
          content: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(message),
          ),
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

  Widget _buildGuideView() {
    return LiquidGlassScaffold(
      title: 'Hướng dẫn Nghiệm thu',
      backgroundColors: AppTheme.kBackgroundLight,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner giới thiệu
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.kBrand.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.kBrand.withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    CupertinoIcons.shield_lefthalf_fill,
                    color: AppTheme.kBrand,
                    size: 40,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bảo vệ quyền lợi của bạn',
                          style: TextStyle(
                            color: AppTheme.kBrand,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Nghiệm thu đúng cách giúp tránh tranh chấp về sau.',
                          style: TextStyle(
                            color: Color(0xFF4B5563),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Các bước nghiệm thu
            const Text(
              'Quy trình Nghiệm thu chuẩn',
              style: TextStyle(
                color: CupertinoColors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildGuideStep(
              '1',
              'Kiểm tra Hợp đồng',
              'Đọc kỹ các điều khoản, giá thuê, cọc và các khoản phí dịch vụ trước khi ký.',
            ),
            _buildGuideStep(
              '2',
              'Chốt số Điện/Nước',
              'Chụp ảnh rõ nét chỉ số đồng hồ điện và nước tại thời điểm nhận phòng.',
            ),
            _buildGuideStep(
              '3',
              'Ghi nhận Hiện trạng',
              'Chụp ảnh toàn cảnh phòng, các vết nứt, ố tường hoặc hư hỏng có sẵn.',
            ),
            _buildGuideStep(
              '4',
              'Kiểm tra Nội thất',
              'Đối chiếu danh sách nội thất bàn giao và ghi chú rõ tình trạng (mới/cũ/xước).',
            ),

            const SizedBox(height: 32),

            // Tính năng nổi bật
            const Text(
              'Khám phá StayHub',
              style: TextStyle(
                color: CupertinoColors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureCard(
              CupertinoIcons.money_dollar_circle_fill,
              'Thanh toán 1 chạm',
              'Nhận và thanh toán hóa đơn hàng tháng dễ dàng qua mã QR.',
              CupertinoColors.systemGreen,
              imagePath: 'assets/images/features/one_tap_payment.png',
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              CupertinoIcons.doc_text_fill,
              'Hợp đồng điện tử',
              'Lưu trữ hợp đồng an toàn, tra cứu mọi lúc mọi nơi.',
              CupertinoColors.systemIndigo,
              imagePath: 'assets/images/features/smart_contract.png',
            ),
            const SizedBox(height: 12),
            _buildFeatureCard(
              CupertinoIcons.wrench_fill,
              'Yêu cầu hỗ trợ',
              'Gửi báo cáo sửa chữa, sự cố trực tiếp đến chủ nhà nhanh chóng.',
              CupertinoColors.systemOrange,
              imagePath: 'assets/images/features/video_maintenance.png',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideStep(String step, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF111827),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    IconData icon,
    String title,
    String desc,
    Color color, {
    String? imagePath,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(imagePath == null ? 10 : 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: imagePath == null
                ? Icon(icon, color: color, size: 24)
                : Image.asset(
                    imagePath,
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    isAntiAlias: true,
                    errorBuilder: (_, __, ___) =>
                        Icon(icon, color: color, size: 24),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
