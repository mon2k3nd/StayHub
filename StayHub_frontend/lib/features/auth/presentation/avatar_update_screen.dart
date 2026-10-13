import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:async' show unawaited;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/components/liquid_animated_background.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../../core/utils/toast_utils.dart';
import '../application/auth_notifier.dart';

class AvatarUpdateScreen extends ConsumerStatefulWidget {
  const AvatarUpdateScreen({super.key});

  @override
  ConsumerState<AvatarUpdateScreen> createState() => _AvatarUpdateScreenState();
}

class _AvatarUpdateScreenState extends ConsumerState<AvatarUpdateScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  bool _isUploading = false;
  File? _previewImage;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile == null) return;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Căn chỉnh ảnh',
            toolbarColor: CupertinoColors.black,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Căn chỉnh ảnh',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile == null) return;

      setState(() => _isUploading = true);

      final tmpDir = await Directory.systemTemp.createTemp();
      final targetPath = '${tmpDir.path}/avatar_compressed.jpg';
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        croppedFile.path,
        targetPath,
        quality: 85,
        minWidth: 512,
        minHeight: 512,
      );

      if (compressedFile == null) {
        setState(() => _isUploading = false);
        return;
      }

      setState(() {
        _previewImage = File(compressedFile.path);
      });

      await ref.read(authProvider.notifier).uploadAvatar(compressedFile.path);

      if (mounted) {
        ToastUtils.show(context, 'Cập nhật ảnh đại diện thành công');
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) context.go('/marketplace');
        });
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.show(context, 'Lỗi tải ảnh: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showAvatarMenu() {
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: const Text('Chọn ảnh đại diện'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                unawaited(_pickAndUploadAvatar(ImageSource.camera));
              },
              child: const Text('📸 Chụp ảnh mới'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                unawaited(_pickAndUploadAvatar(ImageSource.gallery));
              },
              child: const Text('🖼️ Chọn từ thư viện'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      background: const LiquidAnimatedBackground(
        child: SizedBox.expand(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Premium Icon Header
              const Center(
                child: ClipOval(
                  child: GlassCard(
                    padding: EdgeInsets.all(16),
                    child: Icon(CupertinoIcons.sparkles, color: AppTheme.kBrand, size: 32),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Hoàn thiện hồ sơ',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: AppTheme.kTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Tạo thiện cảm với mọi người trên StayHub\nbằng một bức ảnh đại diện thật đẹp.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: AppTheme.kTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              Center(
                child: GestureDetector(
                  onTap: _showAvatarMenu,
                  child: AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Animated Glow
                          Transform.scale(
                            scale: 1.0 + (_pulseCtrl.value * 0.1),
                            child: Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.kBrand.withValues(alpha: 0.15 + (_pulseCtrl.value * 0.1)),
                                    blurRadius: 60,
                                    spreadRadius: 20 * _pulseCtrl.value,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Avatar Container - Pure Glass
                          ClipOval(
                            child: GlassCard(
                              width: 180,
                              height: 180,
                              padding: EdgeInsets.zero,
                            child: _previewImage != null
                                ? Image.file(_previewImage!, fit: BoxFit.cover, width: 180, height: 180)
                                : Container(
                                    width: 180,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          CupertinoColors.white.withValues(alpha: 0.4),
                                          CupertinoColors.white.withValues(alpha: 0.1),
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        CupertinoIcons.person_fill,
                                        size: 80,
                                        color: AppTheme.kBrand.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                          if (_isUploading)
                            Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: CupertinoColors.black.withValues(alpha: 0.4),
                              ),
                              child: const Center(
                                child: CupertinoActivityIndicator(radius: 20, color: CupertinoColors.white),
                              ),
                            ),
                          if (!_isUploading)
                            const Positioned(
                              bottom: 4,
                              right: 12,
                              child: ClipOval(
                                child: GlassCard(
                                  padding: EdgeInsets.all(12),
                                  child: Icon(
                                    CupertinoIcons.camera_fill,
                                    color: AppTheme.kBrand,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const Spacer(),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _isUploading ? null : _showAvatarMenu,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4DA0FF), AppTheme.kBrand],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.kBrand.withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isUploading
                        ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                        : const Text(
                            'Cập nhật ngay',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CupertinoButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final user = ref.read(authProvider).value;
                    if (user != null) {
                      await prefs.setInt('last_avatar_prompt_${user.id}', DateTime.now().millisecondsSinceEpoch);
                      if (!context.mounted) return;
                      final role = user.role;
                      if (role == 'ADMIN') {
                        context.go('/admin-panel');
                      } else if (role == 'OWNER') {
                        context.go('/owner-dashboard');
                      } else if (role == 'STAFF') {
                        context.go('/staff-dashboard');
                      } else {
                        context.go('/marketplace');
                      }
                    } else {
                      if (context.mounted) context.go('/marketplace');
                    }
                  },
                  child: const Text(
                    'Bỏ qua, để sau',
                    style: TextStyle(
                      color: AppTheme.kTextSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      );
  }
}
