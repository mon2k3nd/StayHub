import 'package:flutter/cupertino.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/services/biometric_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async' show unawaited;

class BiometricLockScreen extends ConsumerStatefulWidget {
  final String destinationRoute;

  const BiometricLockScreen({super.key, required this.destinationRoute});

  @override
  ConsumerState<BiometricLockScreen> createState() =>
      _BiometricLockScreenState();
}

class _BiometricLockScreenState extends ConsumerState<BiometricLockScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isAuthenticating = false;
  String _statusText = 'Chạm để xác thực';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    unawaited(_pulseController.repeat(reverse: true));
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _statusText = 'Đang xác thực...';
    });

    // Gọi xác thực sinh trắc học THẬT thay vì giả lập thành công.
    bool success = false;
    try {
      final isAvailable = await BiometricService().isBiometricAvailable();
      if (!isAvailable) {
        if (!mounted) return;
        setState(() {
          _isAuthenticating = false;
          _statusText = 'Thiết bị không hỗ trợ sinh trắc học';
        });
        return;
      }
      success = await BiometricService().authenticate();
    } catch (_) {
      success = false;
    }

    if (!mounted) return;

    if (success) {
      setState(() {
        _statusText = 'Xác thực thành công!';
        _isAuthenticating = false;
      });

      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        context.go(widget.destinationRoute);
      }
    } else {
      // Xác thực thất bại/hủy → KHÔNG được điều hướng vào app.
      setState(() {
        _isAuthenticating = false;
        _statusText = 'Xác thực thất bại. Vui lòng thử lại.';
      });
    }
  }

  void _usePassword() {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Đăng nhập bằng mật khẩu'),
          content: const Text(
            'Tính năng này yêu cầu bạn đăng nhập lại. Vui lòng quay về màn hình đăng nhập.',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Hủy'),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(ctx);
                // KHÔNG bypass vào destinationRoute. Bắt buộc quay về đăng nhập
                // để xác thực lại bằng mật khẩu (trước đây là lỗ hổng bảo mật).
                context.go('/login');
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
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      child: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // Lock icon + pulse animation
            ScaleTransition(
              scale: _pulseAnimation,
              child: GestureDetector(
                onTap: _authenticate,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.kBrand, AppTheme.kBrand],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.kBrand.withValues(alpha: 0.5),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: _isAuthenticating
                      ? const CupertinoActivityIndicator(
                          color: CupertinoColors.white,
                          radius: 20,
                        )
                      : const Icon(
                          CupertinoIcons.lock_fill,
                          color: CupertinoColors.white,
                          size: 52,
                        ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // App name
            const Text(
              'StayHub',
              style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            // Status text
            Text(
              _statusText,
              style: TextStyle(
                color: _statusText.contains('thành công')
                    ? CupertinoColors.systemGreen
                    : AppTheme.kTextSecondary,
                fontSize: 16,
              ),
            ),

            const Spacer(),

            // Biometric hint
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.lock_shield_fill,
                  color: AppTheme.kTextMuted,
                  size: 16,
                ),
                SizedBox(width: 8),
                Text(
                  'Vân tay / Face ID',
                  style: TextStyle(color: AppTheme.kTextMuted, fontSize: 14),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Use password fallback
            CupertinoButton(
              onPressed: _usePassword,
              child: const Text(
                'Dùng mật khẩu thay thế',
                style: TextStyle(
                  color: CupertinoColors.systemBlue,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
