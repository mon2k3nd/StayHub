import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'core/components/internet_connectivity_wrapper.dart';
import 'core/components/backend_connectivity_diagnostic.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_router.dart';
import 'core/providers/session_expired_notifier.dart';
import 'core/utils/toast_utils.dart';
import 'core/providers/core_providers.dart';
import 'core/services/zalo_auth_service.dart';
import 'core/security/bank_grade_app_lock_wrapper.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'dart:async' show unawaited;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase init failed (maybe missing google-services.json): $e');
  }

  // Ép viền tràn màn hình Edge-to-Edge
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0x00000000), // Transparent
      systemNavigationBarColor: Color(0x00000000),
      systemNavigationBarDividerColor: Color(0x00000000),
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));

  await LiquidGlassWidgets.initialize();

  runApp(
    LiquidGlassWidgets.wrap(
      adaptiveQuality: true,
      respectSystemAccessibility: true,
      // Stronger glass effect to make it more visible and satisfying, but keep thickness reasonable to avoid excessive jelly bounce
      theme: GlassThemeData.simple(
        blur: 16,
        thickness: 15,
        quality: GlassQuality.standard,
      ),
      child: const ProviderScope(child: StayHubApp()),
    ),
  );
}

class StayHubApp extends ConsumerStatefulWidget {
  const StayHubApp({super.key});

  @override
  ConsumerState<StayHubApp> createState() => _StayHubAppState();
}

class _StayHubAppState extends ConsumerState<StayHubApp> {
  AppLinks? _appLinks;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final apiClient = ref.read(apiClientProvider);
        await apiClient.initCache();
        unawaited(ref.read(fcmServiceProvider).init(apiClient));
      } catch (e) {
        debugPrint('App Init skipped: $e');
      }
    });
    _initDeepLinks();
  }

  /// Lắng nghe deep link để bắt callback OAuth của Zalo (`stayhub://zalo-auth`).
  void _initDeepLinks() {
    try {
      _appLinks = AppLinks();
      // Deep link khi app đang chạy (foreground/background).
      _appLinks!.uriLinkStream.listen(
        (uri) => ZaloAuthService.handleRedirect(uri),
        onError: (Object e) => debugPrint('Deep link error: $e'),
      );
      // Deep link khi app được mở từ trạng thái tắt (cold start).
      unawaited(
        _appLinks!.getInitialLink().then((uri) {
          if (uri != null) ZaloAuthService.handleRedirect(uri);
        }),
      );
    } catch (e) {
      debugPrint('Deep link init skipped: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionExpiredProvider, (previous, next) {
      if (next == true) {
        // Reset the state to false
        ref.read(sessionExpiredProvider.notifier).reset();
        // Redirect
        final navContext = AppRouter.navigatorKey.currentContext;
        if (navContext != null) {
          ToastUtils.show(
            navContext,
            'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
            isError: true,
          );
        }
        AppRouter.router.go('/login');
      }
    });

    return CupertinoApp.router(
      title: 'StayHub',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        DefaultMaterialLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      theme: AppTheme.lightTheme, // Force Light Mode
      routerConfig: AppRouter.router,
      // Web: dùng scrollBehavior mượt cho chuột/cảm ứng, tránh khựng khi cuộn.
      scrollBehavior: const _StayHubScrollBehavior(),
      builder: (context, child) => BankGradeAppLockWrapper(
        child: GlassNavigationShell(
          child: _SmartUnfocusWrapper(
            child: Theme(
              // QUAN TRỌNG: KHÔNG override `fontFamily` trên một ThemeData rỗng.
              // Việc đó làm mất binding font của MaterialIcons/CupertinoIcons khiến
              // TOÀN BỘ Icon trong app render thành ô trống.
              // Thay vào đó kế thừa theme gốc và chỉ bổ sung iconTheme an toàn.
              data: ThemeData(
                useMaterial3: true,
                iconTheme: const IconThemeData(color: AppTheme.kTextPrimary),
              ),
              // DefaultTextStyle toàn cục: đảm bảo MỌI widget Text — kể cả khi khai
              // báo TextStyle riêng mà không set fontFamily — đều kế thừa CustomRoboto.
              // Đây là chốt chặn cuối giúp font tiếng Việt đồng nhất trên mọi màn hình.
              // Font chỉ áp cho Text, KHÔNG áp cho Icon → icon luôn hiển thị đúng.
              child: DefaultTextStyle(
                style: const TextStyle(
                  fontFamily: AppTheme.kFontFamily,
                  decoration: TextDecoration.none,
                ),
                child: InternetConnectivityWrapper(
                  child: Stack(
                    children: [
                      ResponsiveBreakpoints.builder(
                        child: child!,
                        breakpoints: [
                          const Breakpoint(start: 0, end: 450, name: MOBILE),
                          const Breakpoint(start: 451, end: 800, name: TABLET),
                          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
                          const Breakpoint(
                            start: 1921,
                            end: double.infinity,
                            name: '4K',
                          ),
                        ],
                      ),
                      // Hiển thị lỗi kết nối backend ngay trên màn hình (chẩn đoán).
                      const BackendConnectivityDiagnostic(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bọc toàn app để tự động ẩn bàn phím khi chạm ra vùng trống.
///
/// TRƯỚC ĐÂY dùng `GestureDetector(onTapUp: unfocus)` bọc ngoài cùng → nó
/// tranh chấp gesture arena với MỌI widget con, kể cả `TextField`. Hệ quả:
/// chạm vào ô nhập thì `onTapUp` của wrapper chạy và `unfocus()` ngay lập tức
/// → không thể gõ được, và mỗi lần gõ lại bị hit-test toàn cây → "giật giật".
///
/// CÁCH ĐÚNG: dùng [TapRegion]. `TextField` (và mọi widget nhập liệu của
/// Flutter) tự đăng ký một `TapRegion` bao quanh chính nó. Khi người dùng
/// chạm, Flutter chỉ gọi `onTapOutside` cho các vùng KHÔNG chứa điểm chạm.
/// Nhờ vậy:
///   • Chạm vào ô nhập → KHÔNG unfocus (giữ bàn phím, gõ bình thường).
///   • Chạm ra ngoài (vùng trống) → unfocus mượt, không tranh chấp arena.
///   • Không còn hit-test lại toàn cây mỗi lần gõ → hết giật.
class _SmartUnfocusWrapper extends StatelessWidget {
  const _SmartUnfocusWrapper({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      // Chỉ chạy khi chạm RA NGOÀI mọi vùng nhập liệu.
      onTapOutside: (_) {
        final focus = FocusManager.instance.primaryFocus;
        if (focus != null && focus.hasFocus) {
          focus.unfocus();
        }
      },
      child: child,
    );
  }
}

/// ScrollBehavior tuỳ biến cho StayHub.
///
/// Trên web, mặc định Flutter chỉ cho phép kéo bằng cảm ứng (touch) và chặn
/// chuột/kéo-thanh-cuộn → cảm giác "khựng". Bật [PointerDeviceKind.mouse] và
/// [PointerDeviceKind.trackpad] giúp cuộn mượt bằng chuột, đồng thời giữ
/// thanh cuộn hiển thị để người dùng biết vị trí.
class _StayHubScrollBehavior extends MaterialScrollBehavior {
  const _StayHubScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}
