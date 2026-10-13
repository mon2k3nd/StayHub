import 'dart:async';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:screen_protector/screen_protector.dart';

import '../services/biometric_service.dart';
import '../theme/app_theme.dart';
import 'security_settings_provider.dart';
import '../../features/auth/application/auth_notifier.dart';

/// Lớp bảo vệ toàn cục chuẩn ngân hàng (Bank-grade App Lock Wrapper).
///
/// Quản lý:
/// 1. Tự động kích hoạt chống nhìn trộm đa nhiệm (Privacy Shield / Task Switcher Blur).
/// 2. Khóa ứng dụng khi người dùng rời app (Instant Lock On Exit) - CHỈ khi:
///    - Ứng dụng chạy trên thiết bị di động (không áp dụng trên Web/Desktop).
///    - Thiết bị CÓ hỗ trợ cảm biến sinh trắc học (Face ID / Vân tay).
///    - Người dùng đã chủ động bật tính năng này trong Cài đặt.
class BankGradeAppLockWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const BankGradeAppLockWrapper({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<BankGradeAppLockWrapper> createState() =>
      _BankGradeAppLockWrapperState();
}

class _BankGradeAppLockWrapperState extends ConsumerState<BankGradeAppLockWrapper>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  bool _isLocked = false;
  bool _isAuthenticating = false;
  String _statusMessage = 'Chạm để mở khóa';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    unawaited(_pulseController.repeat(reverse: true));
    _pulseAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Trên nền tảng Web hoặc môi trường không hỗ trợ, không can thiệp vòng đời
    if (kIsWeb) return;

    final settings = ref.read(securitySettingsProvider);
    final user = ref.read(authProvider).value;

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // 1. Chống nhìn trộm đa nhiệm (chỉ hỗ trợ Mobile native)
        if (settings.protectDataLeakage) {
          try {
            unawaited(ScreenProtector.protectDataLeakageOn());
          } catch (e) {
            debugPrint('ScreenProtector leakage ON failed: $e');
          }
        }

        // 2. Chỉ khóa khi người dùng đã đăng nhập, thiết bị hỗ trợ và ĐÃ BẬT tính năng
        if (user != null &&
            settings.instantLockOnExit &&
            settings.biometricEnabled) {
          unawaited(_checkAndLock());
        }
        break;

      case AppLifecycleState.resumed:
        // 1. Tắt lớp bảo vệ chống nhìn trộm khi quay lại
        if (settings.protectDataLeakage) {
          try {
            unawaited(ScreenProtector.protectDataLeakageWithColorOff());
          } catch (e) {
            debugPrint('ScreenProtector leakage OFF failed: $e');
          }
        }

        // 2. Nếu đang bị khóa, tự động bật xác thực sinh trắc học ngay
        if (_isLocked && !_isAuthenticating) {
          unawaited(_authenticate());
        }
        break;

      case AppLifecycleState.detached:
        break;
    }
  }

  Future<void> _checkAndLock() async {
    try {
      final isAvailable = await BiometricService().isBiometricAvailable();
      // Nếu thiết bị KHÔNG hỗ trợ sinh trắc học -> TUYỆT ĐỐI KHÔNG KHÓA APP
      if (!isAvailable) return;

      if (!_isLocked && mounted) {
        setState(() {
          _isLocked = true;
          _statusMessage = 'Chạm để mở khóa';
        });
      }
    } catch (_) {}
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _statusMessage = 'Đang quét sinh trắc học...';
    });

    bool success = false;
    try {
      final isAvailable = await BiometricService().isBiometricAvailable();
      if (!isAvailable) {
        // Thiết bị không có sinh trắc học -> Tự động giải phóng màn hình khóa ngay
        if (!mounted) return;
        setState(() {
          _isLocked = false;
          _isAuthenticating = false;
        });
        return;
      }
      success = await BiometricService().authenticate();
    } catch (e) {
      debugPrint('BankGradeAppLock authenticate error: $e');
      success = false;
    }

    if (!mounted) return;

    if (success) {
      setState(() {
        _isLocked = false;
        _isAuthenticating = false;
        _statusMessage = 'Xác thực thành công!';
      });
    } else {
      setState(() {
        _isAuthenticating = false;
        _statusMessage = 'Xác thực không thành công. Chạm để thử lại.';
      });
    }
  }

  void _unlockDirectly() {
    setState(() {
      _isLocked = false;
      _isAuthenticating = false;
    });
  }

  void _fallbackToLogin() {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Đăng nhập lại'),
          content: const Text(
            'Bạn có muốn đăng xuất và đăng nhập lại bằng mật khẩu?',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Hủy'),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() {
                  _isLocked = false;
                  _isAuthenticating = false;
                });
                await ref.read(authProvider.notifier).logout();
                if (mounted) {
                  context.go('/login');
                }
              },
              child: const Text('Đăng nhập lại'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Trên nền tảng Web, hoàn toàn bỏ qua lớp khóa để tránh bị nảy màn hình khi chuyển tab
    if (kIsWeb) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        if (_isLocked) _buildLockScreen(),
      ],
    );
  }

  Widget _buildLockScreen() {
    return Positioned.fill(
      child: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: AppTheme.kFontFamily,
          decoration: TextDecoration.none,
        ),
        child: Stack(
          children: [
            // Liquid Glass Backdrop Blur
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                color: const Color(0xFF0F172A).withValues(alpha: 0.88),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    // Nút đóng góc trên
                    Align(
                      alignment: Alignment.topRight,
                      child: CupertinoButton(
                        padding: const EdgeInsets.all(8),
                        onPressed: _unlockDirectly,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: CupertinoColors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.xmark,
                            color: CupertinoColors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Animated Shield Icon with Sky Blue glow
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: GestureDetector(
                        onTap: _authenticate,
                        child: Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF69B1FF),
                                Color(0xFF3B82F6),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF69B1FF).withValues(alpha: 0.45),
                                blurRadius: 36,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isAuthenticating
                                ? const CupertinoActivityIndicator(
                                    color: CupertinoColors.white,
                                    radius: 18,
                                  )
                                : const Icon(
                                    CupertinoIcons.lock_shield_fill,
                                    color: CupertinoColors.white,
                                    size: 50,
                                  ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Title
                    const Text(
                      'StayHub Bảo mật',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Subtitle
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _statusMessage.contains('thành công')
                            ? CupertinoColors.systemGreen
                            : const Color(0xFF94A3B8),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // Pill-shaped Primary Unlock Button
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF69B1FF),
                            Color(0xFF2563EB),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF69B1FF).withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        borderRadius: BorderRadius.circular(50),
                        onPressed: _authenticate,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.viewfinder,
                              color: CupertinoColors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Mở khóa Face ID / Vân tay',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Nút tiếp tục vào ứng dụng (Direct unlock fallback)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _unlockDirectly,
                      child: const Text(
                        'Tiếp tục vào ứng dụng',
                        style: TextStyle(
                          color: Color(0xFF69B1FF),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Fallback to Re-login
                    CupertinoButton(
                      onPressed: _fallbackToLogin,
                      child: const Text(
                        'Đăng nhập lại bằng mật khẩu',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}