import 'dart:convert';
import 'package:flutter/cupertino.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart' as signature_pkg;
import '../../../core/components/glass_container.dart';
import '../../../core/components/liquid_background.dart';
import '../../../core/components/glass_button.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/components/premium_text_field.dart';
import '../../tenant/presentation/bank_config_screen.dart';
import '../../../core/components/premium_badge.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';
import '../../../core/utils/toast_utils.dart';
import '../application/auth_notifier.dart';
import '../../../core/providers/biometric_provider.dart';
import '../../../core/security/security_settings_provider.dart';
import 'dart:async' show unawaited;

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isUploadingAvatar = false;

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

      setState(() => _isUploadingAvatar = true);

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
        setState(() => _isUploadingAvatar = false);
        return;
      }

      await ref.read(authProvider.notifier).uploadAvatar(compressedFile.path);

      if (mounted) {
        ToastUtils.show(context, 'Cập nhật ảnh đại diện thành công');
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.show(context, 'Lỗi tải ảnh: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  void _showAvatarMenu() {
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: const Text('Cập nhật ảnh đại diện'),
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
            if (ref.read(authProvider).value?.avatar != null &&
                ref.read(authProvider).value!.avatar!.isNotEmpty)
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(ctx);
                  // Implementation for viewing full screen avatar could go here
                  ToastUtils.show(context, 'Tính năng đang phát triển');
                },
                child: const Text('👁️ Xem ảnh đại diện'),
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
    final authState = ref.watch(authProvider);
    final user = authState.value;
    final isOwner = user?.role == 'OWNER';
    final isDark = ref.watch(themeProvider);

    // Subtle premium sky blue accents
    const skyBlueAccent = AppTheme.kBrand;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor:
            (isDark ? CupertinoColors.black : CupertinoColors.white).withValues(
              alpha: 0.7,
            ),
        middle: Text(
          'Cài Đặt Tài Khoản',
          style: TextStyle(
            color: isDark ? Colors.white : CupertinoColors.black,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.back,
            color: isDark ? Colors.white : CupertinoColors.black,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      child: LiquidBackground(
        colors: isDark ? AppTheme.kBackgroundDark : AppTheme.kBackgroundLight,
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(context).padding.bottom > 0
                  ? MediaQuery.of(context).padding.bottom + 24
                  : 34,
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // ── Premium Hero Profile ────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _showAvatarMenu,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer glowing ring
                            Container(
                              width: 116,
                              height: 116,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    skyBlueAccent.withValues(alpha: 0.5),
                                    AppTheme.kBrandLight.withValues(alpha: 0.1),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                            // Avatar
                            Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF1F5F9),
                                image: DecorationImage(
                                  image: NetworkImage(
                                    (user?.avatar != null &&
                                            user!.avatar!.isNotEmpty)
                                        ? user.avatar!
                                        : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(user?.fullName ?? 'U')}&background=0EA5E9&color=fff&size=200',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : Colors.white,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: skyBlueAccent.withValues(
                                      alpha: 0.15,
                                    ),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                            ),
                            if (_isUploadingAvatar)
                              Container(
                                width: 104,
                                height: 104,
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const CupertinoActivityIndicator(
                                  radius: 14,
                                  color: Colors.white,
                                ),
                              ),
                            // Camera Icon
                            Positioned(
                              bottom: 4,
                              right: 4,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: skyBlueAccent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : Colors.white,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  CupertinoIcons.camera_fill,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.fullName ?? 'Người dùng',
                        style: TextStyle(
                          color: isDark
                              ? AppTheme.kTextPrimaryDark
                              : CupertinoColors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (user?.role == 'OWNER' && user?.planType != 'FREE')
                        PremiumBadge(
                          text: user?.planType == 'VIP'
                              ? 'CHỦ NHÀ (VIP)'
                              : 'CHỦ NHÀ (PRO)',
                          isPro: user?.planType != 'VIP',
                        )
                      else
                        Text(
                          user?.role == 'OWNER' ? 'Chủ nhà' : 'Khách thuê',
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.kTextSecondaryDark
                                : AppTheme.kTextSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // ── THÔNG TIN CHI TIẾT ──────────────────────────────────────
                _buildSectionTitle('THÔNG TIN CHI TIẾT', isDark),
                const SizedBox(height: 12),
                GlassContainer(
                  padding: const EdgeInsets.all(0),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        CupertinoIcons.phone_fill,
                        'Số điện thoại',
                        user?.phoneNumber ?? 'Chưa cập nhật',
                        isDark,
                        true,
                      ),
                      _buildDetailRow(
                        CupertinoIcons.mail_solid,
                        'Email',
                        user?.email ?? 'Chưa cập nhật',
                        isDark,
                        true,
                      ),
                      _buildDetailRow(
                        CupertinoIcons.layers_alt_fill,
                        'Gói dịch vụ',
                        user?.planType ?? 'FREE',
                        isDark,
                        false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── TÀI KHOẢN ─────────────────────────────────────────────
                _buildSectionTitle('TÀI KHOẢN', isDark),
                const SizedBox(height: 12),
                GlassContainer(
                  padding: const EdgeInsets.all(0),
                  child: Column(
                    children: [
                      _buildActionRow(
                        icon: CupertinoIcons.person_crop_circle_fill,
                        iconColor: skyBlueAccent,
                        title: 'Chỉnh sửa thông tin',
                        subtitle: 'Cập nhật hồ sơ cá nhân',
                        isDark: isDark,
                        showDivider: isOwner,
                        onTap: () {
                          unawaited(
                            context.push(
                              '/profile-update',
                              extra: {'nextRoute': null},
                            ),
                          );
                        },
                      ),
                      if (isOwner) ...[
                        _buildActionRow(
                          icon: CupertinoIcons.creditcard_fill,
                          iconColor: AppTheme.kSuccess,
                          title: 'Thiết lập Ngân hàng',
                          subtitle: 'Kết nối thanh toán VietQR',
                          isDark: isDark,
                          showDivider: true,
                          onTap: () => Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (c) => const BankConfigScreen(),
                            ),
                          ),
                        ),
                        _buildActionRow(
                          icon: CupertinoIcons.signature,
                          iconColor: AppTheme.kWarning,
                          title: 'Chữ ký điện tử',
                          subtitle: 'Dùng cho hợp đồng và duyệt khách',
                          isDark: isDark,
                          showDivider: false,
                          onTap: () => showCupertinoModalPopup(
                            context: context,
                            builder: (ctx) => const SettingsSignatureDialog(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // ── BẢO MẬT CẤP NGÂN HÀNG ───────────────────────────────────────────────
                _buildSectionTitle('BẢO MẬT CẤP NGÂN HÀNG', isDark),
                const SizedBox(height: 12),
                Consumer(
                  builder: (context, ref, _) {
                    final securitySettings = ref.watch(securitySettingsProvider);
                    return GlassContainer(
                      borderRadius: 20,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Column(
                        children: [
                          // Switch 1: Khóa ứng dụng bằng Sinh trắc học
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  CupertinoIcons.lock_shield_fill,
                                  color: Color(0xFF8B5CF6),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Khóa ứng dụng bằng Sinh trắc học',
                                      style: TextStyle(
                                        color: isDark
                                            ? AppTheme.kTextPrimaryDark
                                            : CupertinoColors.black,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Bảo vệ tài khoản bằng Face ID / Vân tay',
                                      style: TextStyle(
                                        color: isDark
                                            ? AppTheme.kTextSecondaryDark
                                            : AppTheme.kTextSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              CupertinoSwitch(
                                value: securitySettings.biometricEnabled,
                                activeTrackColor: const Color(0xFF8B5CF6),
                                onChanged: (val) {
                                  ref.read(securitySettingsProvider.notifier).setBiometricEnabled(val);
                                  final bioCurrent = ref.read(biometricEnabledProvider);
                                  if (bioCurrent != val) {
                                    ref.read(biometricEnabledProvider.notifier).toggle();
                                  }
                                },
                              ),
                            ],
                          ),

                          if (securitySettings.biometricEnabled) ...[
                            const Divider(height: 24),

                            // Switch 2: Khóa tức thì khi thoát ứng dụng
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.shield_fill,
                                    color: Color(0xFF2563EB),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Khóa tức thì khi thoát app',
                                        style: TextStyle(
                                          color: isDark
                                              ? AppTheme.kTextPrimaryDark
                                              : CupertinoColors.black,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Chuẩn ngân hàng: mở lại yêu cầu Face ID ngay',
                                        style: TextStyle(
                                          color: isDark
                                              ? AppTheme.kTextSecondaryDark
                                              : AppTheme.kTextSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                CupertinoSwitch(
                                  value: securitySettings.instantLockOnExit,
                                  activeTrackColor: const Color(0xFF2563EB),
                                  onChanged: (val) {
                                    ref.read(securitySettingsProvider.notifier).setInstantLockOnExit(val);
                                  },
                                ),
                              ],
                            ),

                            const Divider(height: 24),

                            // Switch 3: Chống nhìn trộm đa nhiệm (Privacy Shield)
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.eye_slash_fill,
                                    color: Color(0xFF10B981),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Chống nhìn trộm đa nhiệm',
                                        style: TextStyle(
                                          color: isDark
                                              ? AppTheme.kTextPrimaryDark
                                              : CupertinoColors.black,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Che mờ màn hình ở thanh chuyển ứng dụng',
                                        style: TextStyle(
                                          color: isDark
                                              ? AppTheme.kTextSecondaryDark
                                              : AppTheme.kTextSecondary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                CupertinoSwitch(
                                  value: securitySettings.protectDataLeakage,
                                  activeTrackColor: const Color(0xFF10B981),
                                  onChanged: (val) {
                                    ref.read(securitySettingsProvider.notifier).setProtectDataLeakage(val);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),

                // ── ĐĂNG XUẤT ─────────────────────────────────────────────
                GlassButton(
                  text: 'Đăng xuất',
                  icon: CupertinoIcons.square_arrow_right,
                  color: AppTheme.kError,
                  onPressed: () async {
                    final confirm = await showCupertinoDialog<bool>(
                      context: context,
                      builder: (ctx) => CupertinoAlertDialog(
                        title: const Text('Đăng xuất'),
                        content: const Text(
                          'Bạn có chắc muốn đăng xuất khỏi tài khoản này?',
                        ),
                        actions: [
                          CupertinoDialogAction(
                            child: const Text('Hủy'),
                            onPressed: () => Navigator.pop(ctx, false),
                          ),
                          CupertinoDialogAction(
                            isDestructiveAction: true,
                            child: const Text('Đăng xuất'),
                            onPressed: () => Navigator.pop(ctx, true),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      await ref.read(authProvider.notifier).logout();
                      if (context.mounted) context.go('/login');
                    }
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'StayHub v1.0.0',
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.kTextSecondaryDark
                        : const Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Text(
          title,
          style: TextStyle(
            color: isDark
                ? AppTheme.kTextSecondaryDark
                : AppTheme.kTextSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    bool isDark,
    bool showDivider,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.kBrand.withValues(alpha: 0.15),
                      AppTheme.kBrandLight.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.kBrand.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(icon, color: AppTheme.kBrand, size: 20),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  color: isDark
                      ? AppTheme.kTextSecondaryDark
                      : AppTheme.kTextSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    color: isDark
                        ? AppTheme.kTextPrimaryDark
                        : AppTheme.kTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 68),
            child: Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
      ],
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required bool showDivider,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            highlightColor: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            splashColor: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.kTextPrimaryDark
                                : AppTheme.kTextPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: isDark
                                ? AppTheme.kTextSecondaryDark
                                : AppTheme.kTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    CupertinoIcons.chevron_right,
                    color: isDark ? Colors.white30 : const Color(0xFFCBD5E1),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 68),
            child: Divider(
              height: 1,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
            ),
          ),
      ],
    );
  }
}

class _BankInfoDialog extends ConsumerStatefulWidget {
  final dynamic user;
  const _BankInfoDialog({required this.user});

  @override
  ConsumerState<_BankInfoDialog> createState() => _BankInfoDialogState();
}

class _BankInfoDialogState extends ConsumerState<_BankInfoDialog> {
  late final TextEditingController _bankNameCtrl;
  late final TextEditingController _accountNumCtrl;
  late final TextEditingController _accountNameCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _bankNameCtrl = TextEditingController(text: widget.user.bankName ?? '');
    _accountNumCtrl = TextEditingController(
      text: widget.user.bankAccountNumber ?? '',
    );
    _accountNameCtrl = TextEditingController(
      text: widget.user.bankAccountName ?? '',
    );
  }

  @override
  void dispose() {
    _bankNameCtrl.dispose();
    _accountNumCtrl.dispose();
    _accountNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.put(
        '/v1/users/${widget.user.id}/profile',
        data: {
          'bankName': _bankNameCtrl.text.trim(),
          'bankAccountNumber': _accountNumCtrl.text.trim(),
          'bankAccountName': _accountNameCtrl.text.trim().toUpperCase(),
        },
      );
      // Giả lập lấy lại profile hoặc yêu cầu reload.
      // Vì không có api lấy profile riêng trong authNotifier nên tạm reload ứng dụng.
      if (mounted) {
        Navigator.pop(context);
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Thành công'),
              content: const Text(
                'Đã cập nhật thông tin ngân hàng. Vui lòng đăng nhập lại để cập nhật.',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Lỗi'),
              content: Text(e.toString()),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thông tin Ngân hàng',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(
                  CupertinoIcons.xmark_circle_fill,
                  color: AppTheme.kTextSecondary,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          PremiumTextField(
            controller: _bankNameCtrl,
            placeholder: 'Tên Ngân Hàng (VD: Vietcombank, MBBank)',
          ),
          const SizedBox(height: 16),
          PremiumTextField(
            controller: _accountNumCtrl,
            placeholder: 'Số Tài Khoản',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          PremiumTextField(
            controller: _accountNameCtrl,
            placeholder: 'Tên Chủ Tài Khoản (Không dấu)',
          ),
          const Spacer(),
          _isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : GlassButton(
                  text: 'Lưu Cài Đặt',
                  color: CupertinoColors.activeGreen,
                  onPressed: _submit,
                ),
        ],
      ),
    );
  }
}

class SettingsOtpDialog extends StatefulWidget {
  final String target;
  final String channel;
  final Function(String) onSubmit;
  const SettingsOtpDialog({
    super.key,
    required this.target,
    required this.channel,
    required this.onSubmit,
  });

  @override
  State<SettingsOtpDialog> createState() => _SettingsOtpDialogState();
}

class _SettingsOtpDialogState extends State<SettingsOtpDialog> {
  final _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: const Text('Nhập mã OTP'),
      content: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Column(
          children: [
            Text(
              'Mã OTP đã được gửi đến ${widget.channel == 'sms' ? 'số điện thoại' : 'email'} ${widget.target}.',
            ),
            const SizedBox(height: 12),
            PremiumTextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              placeholder: 'Nhập mã 6 chữ số',
              maxLength: 6,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        CupertinoDialogAction(
          child: const Text('Hủy'),
          onPressed: () => Navigator.pop(context),
        ),
        CupertinoDialogAction(
          child: const Text('Xác nhận'),
          onPressed: () {
            if (_ctrl.text.length == 6) {
              Navigator.pop(context);
              widget.onSubmit(_ctrl.text);
            }
          },
        ),
      ],
    );
  }
}

class SettingsSignatureDialog extends ConsumerStatefulWidget {
  const SettingsSignatureDialog({super.key});

  @override
  ConsumerState<SettingsSignatureDialog> createState() =>
      _SettingsSignatureDialogState();
}

class _SettingsSignatureDialogState
    extends ConsumerState<SettingsSignatureDialog> {
  late final signature_pkg.SignatureController _signatureController;
  bool _isLoading = false;

  List<dynamic> _history = [];
  bool _isUpdating = false;
  String? _currentSignatureBase64;

  @override
  void initState() {
    super.initState();
    _signatureController = signature_pkg.SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black, // Dark ink for realism
      exportBackgroundColor: Colors.transparent, // Export with transparent BG
    );
    unawaited(_fetchHistory());
  }

  Future<void> _fetchHistory() async {
    try {
      final user = ref.read(authProvider).value;
      if (user != null) {
        // Also fallback to user.signature if it exists
        _currentSignatureBase64 =
            (user.signature != null && user.signature!.isNotEmpty)
            ? user.signature
            : null;

        final api = ref.read(apiClientProvider);
        final res = await api.get('/v1/users/${user.id}/signature-history');
        if (res['success'] == true && mounted) {
          // BUGFIX (data): tránh `as List<dynamic>` ném TypeError khi `data`
          // null/không phải List — trả [] để màn hình không vỡ.
          final raw = res['data'];
          final data = raw is List ? raw : const <dynamic>[];
          setState(() {
            _history = data;

            // Try extracting signature from history if user.signature was empty
            if (_currentSignatureBase64 == null && data.isNotEmpty) {
              final first = data.first;
              if (first is Map &&
                  first['signature'] != null &&
                  first['signature'].toString().isNotEmpty) {
                _currentSignatureBase64 = first['signature'];
              }
            }
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_signatureController.isEmpty) {
      _showError('Vui lòng ký tên trước khi lưu.');
      return;
    }

    final user = ref.read(authProvider).value;
    if (user == null) return;

    if (_currentSignatureBase64 != null) {
      // Đã có chữ ký, cần OTP
      _showOtpChannelSelection(user);
    } else {
      // Chưa có chữ ký, unawaited(lưu trực tiếp)
      unawaited(_saveSignature(user, null));
    }
  }

  void _showError(String msg) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Lỗi'),
          content: Text(msg),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showOtpChannelSelection(dynamic user) {
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: const Text('Xác thực bảo mật'),
          message: const Text(
            'Vui lòng chọn phương thức nhận mã OTP để thay đổi chữ ký.',
          ),
          actions: [
            CupertinoActionSheetAction(
              child: Text(
                'Gửi SMS đến ${user.phoneNumber ?? user.phone ?? "số điện thoại"}',
              ),
              onPressed: () {
                Navigator.pop(ctx);
                unawaited(
                  _sendOtpAndVerify(
                    user,
                    user.phoneNumber ?? user.phone ?? '',
                    'sms',
                  ),
                );
              },
            ),
            if (user.email != null && user.email!.isNotEmpty)
              CupertinoActionSheetAction(
                child: Text('Gửi Email đến ${user.email}'),
                onPressed: () {
                  Navigator.pop(ctx);
                  unawaited(_sendOtpAndVerify(user, user.email!, 'email'));
                },
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: const Text('Hủy'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ),
      ),
    );
  }

  Future<void> _sendOtpAndVerify(
    dynamic user,
    String target,
    String channel,
  ) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).sendOtp(target, channel);
      if (mounted) {
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) => SettingsOtpDialog(
              target: target,
              channel: channel,
              onSubmit: (otp) {
                unawaited(_saveSignature(user, otp));
              },
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Không thể gửi mã OTP: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSignature(dynamic user, String? otp) async {
    setState(() => _isLoading = true);
    try {
      final bytes = await _signatureController.toPngBytes();
      if (bytes == null) return;

      final base64Signature = base64Encode(bytes);

      final api = ref.read(apiClientProvider);
      await api.put(
        '/v1/users/${user.id}/signature',
        data: {'signature': base64Signature, if (otp != null) 'otp': otp},
      );

      // Refresh auth state
      ref.invalidate(authProvider);

      if (mounted) {
        Navigator.pop(context);
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Thành công'),
              content: const Text('Đã cập nhật chữ ký điện tử.'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Không thể lưu chữ ký: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showExisting = _currentSignatureBase64 != null && !_isUpdating;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppTheme.kTextPrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kBrandLight.withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.only(
              top: 16,
              left: 24,
              right: 16,
              bottom: 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chữ Ký Điện Tử',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.xmark,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Chữ ký này sẽ được sử dụng mặc định khi bạn phê duyệt yêu cầu thuê phòng và tạo hợp đồng.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Signature Canvas
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: AppTheme
                          .kBackgroundLight, // Off-white for realistic paper feel
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.kBrandLight.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.kBrandLight.withValues(alpha: 0.15),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: showExisting
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Image.memory(
                                  base64Decode(_currentSignatureBase64!),
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Text(
                                    'Lỗi hiển thị chữ ký',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ),
                            )
                          : signature_pkg.Signature(
                              controller: _signatureController,
                              backgroundColor: Colors
                                  .transparent, // Uses the container's background
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (!showExisting)
                    Align(
                      alignment: Alignment.centerRight,
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.trash,
                              color: AppTheme.kError,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Xóa chữ ký',
                              style: TextStyle(
                                color: AppTheme.kError,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        onPressed: () => _signatureController.clear(),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // History Section
                  if (_history.isNotEmpty) ...[
                    const Text(
                      'LỊCH SỬ CẬP NHẬT',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Colors.white54,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        itemCount: _history.length,
                        itemBuilder: (ctx, i) {
                          final h = _history[i];
                          final dateStr = h['createdAt'] != null
                              ? DateFormat('HH:mm dd/MM/yyyy').format(
                                  DateTime.parse(h['createdAt']).toLocal(),
                                )
                              : 'N/A';
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.kSuccess.withValues(
                                      alpha: 0.2,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.checkmark_seal_fill,
                                    size: 14,
                                    color: AppTheme.kSuccess,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Cập nhật lúc $dateStr',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Action Button
                  _isLoading
                      ? const Center(
                          child: CupertinoActivityIndicator(
                            color: Colors.white,
                          ),
                        )
                      : showExisting
                      ? Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF8B5CF6,
                                ).withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            onPressed: () {
                              setState(() {
                                _isUpdating = true;
                                _signatureController.clear();
                              });
                            },
                            child: const Text(
                              'CẬP NHẬT CHỮ KÝ MỚI',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.white,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [AppTheme.kBrand, Color(0xFF3B82F6)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.kBrand.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            onPressed: _submit,
                            child: const Text(
                              'LƯU CHỮ KÝ NÀY',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.white,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
