import 'dart:async' show unawaited;
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/deep_link_memory_service.dart';
import '../../../../core/services/google_auth_service.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../application/auth_notifier.dart';

/// BottomSheet đăng nhập nhanh (Quick Auth) theo chuẩn Liquid Glass.
///
/// Hỗ trợ:
/// 1. Đăng nhập 1-chạm trực tiếp bằng Google (không chuyển trang, giữ nguyên ngữ cảnh phòng đang xem).
/// 2. Đăng nhập bằng SĐT / Mật khẩu (lưu pendingRoute và chuyển hướng sang /login).
class GuestAuthBottomSheet extends ConsumerStatefulWidget {
  final String? currentPath;
  const GuestAuthBottomSheet({super.key, this.currentPath});

  static Future<void> show(BuildContext context) {
    String pendingPath = '/marketplace';
    try {
      final router = GoRouter.of(context);
      final config = router.routerDelegate.currentConfiguration;
      pendingPath = config.uri.toString();
    } catch (_) {}

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GuestAuthBottomSheet(currentPath: pendingPath),
    );
  }

  @override
  ConsumerState<GuestAuthBottomSheet> createState() =>
      _GuestAuthBottomSheetState();
}

class _GuestAuthBottomSheetState extends ConsumerState<GuestAuthBottomSheet> {
  bool _isLoadingGoogle = false;

  Future<void> _handleOneTapGoogle() async {
    unawaited(HapticFeedback.lightImpact());
    setState(() => _isLoadingGoogle = true);

    try {
      final idToken = await GoogleAuthService.signIn();
      if (!mounted) return;

      await ref.read(authProvider.notifier).loginWithGoogle(idToken);
      if (!mounted) return;

      unawaited(HapticFeedback.mediumImpact());
      Navigator.of(context).pop();
      ToastUtils.show(context, 'Chào mừng bạn đến với StayHub!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingGoogle = false);
      final msg = e.toString();
      if (!msg.contains('huỷ') && !msg.contains('canceled') && !msg.contains('cancelled')) {
        ToastUtils.show(context, 'Đăng nhập Google thất bại. Vui lòng thử lại.', isError: true);
      }
    }
  }

  Future<void> _handleNavigateToLogin() async {
    unawaited(HapticFeedback.lightImpact());
    await DeepLinkMemoryService.savePendingRoute(
      widget.currentPath ?? '/marketplace',
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    try {
      unawaited(context.push('/login'));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 34),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(
            color: const Color(0xFF69B1FF).withValues(alpha: 0.25),
            width: 1.2,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1469B1FF),
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grabber Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Icon Header
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF69B1FF), Color(0xFF2563EB)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x2869B1FF),
                      blurRadius: 16,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.sparkles,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Title & Subtitle
              const Text(
                'Mở khoá toàn bộ tính năng',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'Đăng nhập chỉ 5 giây để trải nghiệm tìm phòng và liên hệ chủ nhà mượt mà nhất.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Value Props Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _buildFeatureItem(
                      icon: CupertinoIcons.heart_fill,
                      color: CupertinoColors.systemPink,
                      text: 'Lưu phòng yêu thích & đồng bộ mọi thiết bị',
                    ),
                    const Divider(height: 14, color: Color(0xFFF1F5F9)),
                    _buildFeatureItem(
                      icon: CupertinoIcons.chat_bubble_2_fill,
                      color: const Color(0xFF2563EB),
                      text: 'Trò chuyện & đặt lịch xem phòng trực tiếp',
                    ),
                    const Divider(height: 14, color: Color(0xFFF1F5F9)),
                    _buildFeatureItem(
                      icon: CupertinoIcons.shield_fill,
                      color: const Color(0xFF10B981),
                      text: 'Bảo chứng cọc & Hợp đồng thuê minh bạch',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Nút 1: Đăng nhập 1-chạm Google (One-Tap)
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: const Color(0xFFCBD5E1),
                      width: 1.2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0C000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    borderRadius: BorderRadius.circular(50),
                    onPressed: _isLoadingGoogle ? null : _handleOneTapGoogle,
                    child: _isLoadingGoogle
                        ? const CupertinoActivityIndicator(radius: 10)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
                                width: 20,
                                height: 20,
                                errorBuilder: (_, __, ___) => const Icon(
                                  CupertinoIcons.globe,
                                  size: 20,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Tiếp tục với Google (1-chạm)',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Nút 2: Đăng nhập bằng Mật khẩu / SĐT
              SizedBox(
                width: double.infinity,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF69B1FF), Color(0xFF2563EB)],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x3269B1FF),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    borderRadius: BorderRadius.circular(50),
                    onPressed: _handleNavigateToLogin,
                    child: const Text(
                      'Đăng nhập bằng Mật khẩu / SĐT',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Nút 3: Bỏ qua
              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 10),
                onPressed: () {
                  unawaited(HapticFeedback.selectionClick());
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Để sau',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }
}
