import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/security/secure_storage_service.dart';
import '../../../core/services/biometric_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../application/auth_notifier.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';
import 'package:flutter/services.dart';
import '../../marketplace/application/location_provider.dart';
import 'dart:async' show unawaited;

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  final _storage = const SecureStorageService(FlutterSecureStorage());

  @override
  void initState() {
    super.initState();
    unawaited(_checkAuth());
  }

  Future<void> _checkAuth() async {
    bool jailbroken = false;
    if (!kIsWeb) {
      try {
        jailbroken = await FlutterJailbreakDetection.jailbroken;
      } on PlatformException {
        // Plugin không khả dụng trên một số thiết bị/emulator → KHÔNG được
        // coi là jailbreak (trước đây = true gây khoá app oan cho user hợp lệ).
        jailbroken = false;
      } catch (e) {
        jailbroken = false;
      }
    }

    if (jailbroken) {
      if (mounted) {
        unawaited(
          showCupertinoDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => CupertinoAlertDialog(
              title: const Text(
                'Cảnh báo bảo mật',
                style: TextStyle(color: CupertinoColors.systemRed),
              ),
              content: const Text(
                'Thiết bị của bạn đã bị root hoặc jailbreak. Để bảo vệ dữ liệu, ứng dụng không thể chạy trên thiết bị này.',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Thoát'),
                  onPressed: () {
                    unawaited(SystemNavigator.pop());
                  },
                ),
              ],
            ),
          ),
        );
      }
      return;
    }

    // ── Version-based onboarding reset ──────────────────────────────────────
    // Khi cài APK mới (version code thay đổi), reset isFirstTime = true để
    // user luôn thấy Onboarding — đồng bộ hành vi với web dev server.
    // SharedPreferences tồn tại qua các lần reinstall nên PHẢI check version.
    if (!kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        const currentBuildNumber = String.fromEnvironment(
          'BUILD_NUMBER',
          defaultValue: '1',
        );
        final lastSeenVersion = prefs.getString('lastSeenVersion');
        // Chỉ reset onboarding khi build number THỰC SỰ thay đổi (cài APK mới).
        // Trước đây điều kiện bị hardcode `if (true)` → mỗi lần mở app đều
        // reset isFirstTime = true, khiến user cũ luôn bị đẩy về Onboarding.
        if (lastSeenVersion != currentBuildNumber) {
          await prefs.setBool('isFirstTime', true);
          await prefs.setString('lastSeenVersion', currentBuildNumber);
          debugPrint(
            '[Splash] New build $currentBuildNumber → reset onboarding',
          );
        }
      } catch (e) {
        debugPrint('[Splash] Version check skipped: $e');
      }
    }

    try {
      final token = await _storage.getAccessToken();
      if (token != null) {
        // Wait for the authProvider to finish its initial tryAutoLogin (which handles offline fallback gracefully)
        final user = await ref.read(authProvider.future);

        if (user != null) {
          final role = user.role;

          if (!mounted) return;

          final prefs = await SharedPreferences.getInstance();
          if (!mounted) return;
          final biometricEnabled = prefs.getBool('biometric_enabled') ?? false;

          String destination = '/marketplace';
          if (role == 'ADMIN') {
            destination = '/admin-panel';
          } else if (role == 'OWNER') {
            destination = '/owner-dashboard';
          } else if (role == 'STAFF') {
            final status = user.status;
            if (status == 'PENDING_VERIFICATION') {
              unawaited(
                context.push(
                  '/profile-update',
                  extra: {'nextRoute': '/staff-dashboard'},
                ),
              );
              return;
            } else {
              destination = '/staff-dashboard';
            }
          }

          if (biometricEnabled) {
            final isAvailable = await BiometricService().isBiometricAvailable();
            if (!mounted) return;
            if (isAvailable) {
              final authSuccess = await BiometricService().authenticate();
              if (!mounted) return;

              if (authSuccess) {
                context.go(destination);
              } else {
                // Người dùng huỷ/sai vân tay → chỉ quay về màn đăng nhập,
                // KHÔNG xoá phiên (trước đây logout() khiến user phải nhập
                // lại mật khẩu mỗi lần lỡ tay huỷ hộp thoại sinh trắc học).
                if (!mounted) return;
                context.go('/login');
              }
            } else {
              context.go(destination);
            }
          } else {
            context.go(destination);
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('[Splash] Auth check error: $e');
      // DO NOT clear session here on random errors to prevent kicking user out on timeout
    }

    if (mounted) {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final isFirstTime = prefs.getBool('isFirstTime') ?? true;
      if (isFirstTime) {
        // Lần đầu tiên mở app → vào Onboarding để giới thiệu và xin quyền vị trí
        context.go('/onboarding');
      } else {
        // Khách cũ → pre-unawaited(fetch nearby branches ngay nếu đã có quyền)
        unawaited(
          ref.read(locationProvider.notifier).checkExistingPermission(),
        );
        context.go('/marketplace');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF298FFF), Color(0xFF1A6FD4)], // Premium Sky Blue
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Placeholder - in a real app, use an asset or the custom painter
              Icon(
                CupertinoIcons.house_fill,
                color: CupertinoColors.white,
                size: 80,
              ),
              SizedBox(height: 24),
              Text(
                'StayHub',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
