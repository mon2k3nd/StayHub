import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';

import '../../../core/glass/glass_bottom_navigation.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../tenant/presentation/business_landing_screen.dart';
import 'guest_home_screen.dart';
import 'guest_landing_screen.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'dart:async' show unawaited;

/// Notifier để điều khiển Tab hiện tại của Guest Mode từ bất kỳ đâu.
class GuestTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) => state = index;
}

final guestTabIndexProvider = NotifierProvider<GuestTabNotifier, int>(
  GuestTabNotifier.new,
);

/// Scroll-driven collapse signal for the Liquid Glass nav bar.
///
/// 0.0 = fully visible, 1.0 = fully sunk (scrolling down).
final navCollapseProvider = NotifierProvider<NavCollapseNotifier, double>(
  NavCollapseNotifier.new,
);

class NavCollapseNotifier extends Notifier<double> {
  @override
  double build() => 0.0;

  void set(double value) => state = value.clamp(0.0, 1.0);
}

/// Root scaffold for Guest Mode.
///
/// Hosts the 4 primary tabs behind a floating Liquid-Glass nav bar.
/// Uses [IndexedStack] for state preservation plus a cross-dissolve +
/// shared-element transition when switching tabs.
///
/// [initialTab] – tab index to show on first render (default 0 = Khám phá).
/// Dùng bởi route `/guest-search` để mở thẳng tab Tìm phòng (index 1).
class GuestMainScaffold extends ConsumerStatefulWidget {
  final int initialTab;

  const GuestMainScaffold({super.key, this.initialTab = 0});

  @override
  ConsumerState<GuestMainScaffold> createState() => _GuestMainScaffoldState();
}

class _GuestMainScaffoldState extends ConsumerState<GuestMainScaffold>
    with TickerProviderStateMixin {
  static const _tabs = <Widget>[
    GuestLandingScreen(),
    GuestHomeScreen(),
    BusinessLandingScreen(),
    ProfileScreen(),
  ];

  static const _navItems = <GlassNavItem>[
    GlassNavItem(
      icon: CupertinoIcons.house,
      activeIcon: CupertinoIcons.house_fill,
      label: 'Khám phá',
      semanticLabel: 'Trang chủ',
    ),
    // Tab 2 = chợ phòng (GuestMarketplaceScreen) — nhãn phải phản ánh đúng
    // nội dung "tìm & lọc phòng", không phải "Giải trí".
    GlassNavItem(
      icon: CupertinoIcons.search,
      activeIcon: CupertinoIcons.search_circle_fill,
      label: 'Tìm phòng',
      semanticLabel: 'Tìm phòng',
    ),
    // Tab 3 = landing cho chủ nhà (BusinessLandingScreen) — nhãn "Cho thuê"
    // thay vì "Lịch đặt" vốn gây hiểu nhầm.
    GlassNavItem(
      icon: CupertinoIcons.briefcase,
      activeIcon: CupertinoIcons.briefcase_fill,
      label: 'Cho thuê',
      semanticLabel: 'Cho thuê',
    ),
    GlassNavItem(
      icon: CupertinoIcons.person,
      activeIcon: CupertinoIcons.person_fill,
      label: 'Cá nhân',
      semanticLabel: 'Cá nhân',
    ),
  ];

  /// Drives the nav bar's scroll-aware sink/dim behaviour.
  final ValueNotifier<double> _collapse = ValueNotifier<double>(0.0);

  /// Approximate luminance (0..1) of the content behind the nav bar, used by
  /// the Liquid Glass material for its adaptive tint. Updated from scroll
  /// notifications so the glass brightens over dark content and darkens over
  /// bright content without any expensive per-frame backdrop sampling.
  final ValueNotifier<double> _backdropLuminance = ValueNotifier<double>(0.5);

  /// Drives the cross-dissolve between tab screens.
  late final AnimationController _fadeCtrl;

  /// Drives the smooth hide/show animation of the bottom nav bar.
  late final AnimationController _navAnimCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    _navAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _navAnimCtrl.addListener(() {
      _collapse.value = _navAnimCtrl.value;
    });

    // Áp initialTab sau khi frame đầu render xong để tránh setState during build.
    if (widget.initialTab != 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(guestTabIndexProvider.notifier).setTab(widget.initialTab);
        }
      });
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _navAnimCtrl.dispose();
    _collapse.dispose();
    _backdropLuminance.dispose();
    super.dispose();
  }

  // BUGFIX (race khi bấm tab nhanh): trước đây mỗi lần bấm lại tạo một chuỗi
  // reverse().then(...) mới. Bấm liên tiếp khiến nhiều chuỗi chồng nhau, các
  // callback .then chạy sai thứ tự → setTab nhầm tab và/hoặc _fadeCtrl kẹt ở
  // giá trị giữa (màn hình mờ dần không hồi). Dùng cờ _isSwitching để chỉ cho
  // một transition chạy tại một thời điểm; tab mới nhất được ghi nhận.
  bool _isSwitching = false;
  int? _pendingTab;

  void _onTabSelected(int index) {
    final current = ref.read(guestTabIndexProvider);
    if (index == current) return;

    // Nếu đang chuyển tab, chỉ ghi nhận đích mới nhất rồi để transition hiện
    // tại xử lý tiếp — tránh chồng chuỗi animation.
    if (_isSwitching) {
      _pendingTab = index;
      return;
    }

    _isSwitching = true;
    _pendingTab = null;

    // Cross-dissolve: fade out → swap → fade in (250ms total).
    unawaited(
      _fadeCtrl.reverse().then((_) async {
        if (!mounted) {
          _isSwitching = false;
          return;
        }
        ref.read(guestTabIndexProvider.notifier).setTab(index);
        await _fadeCtrl.forward();
        _isSwitching = false;
        // Nếu người dùng đã bấm tab khác trong lúc chuyển, chạy tiếp.
        final next = _pendingTab;
        _pendingTab = null;
        if (next != null && mounted) {
          _onTabSelected(next);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(guestTabIndexProvider);
    ref.listen<double>(navCollapseProvider, (_, next) {
      if (next == 1.0) {
        _navAnimCtrl.forward();
      } else if (next == 0.0) {
        _navAnimCtrl.reverse();
      } else {
        _navAnimCtrl.value = next;
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.kBackgroundLight,
      body: NotificationListener<ScrollNotification>(
        onNotification: _handleScroll,
        child: Stack(
          children: [
            // Cross-dissolve + subtle shared-element lift between tabs.
            Positioned.fill(
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _fadeCtrl,
                  curve: Curves.easeOut,
                ),
                child: AnimatedBuilder(
                  animation: _fadeCtrl,
                  builder: (context, child) {
                    final t = Curves.easeOutCubic.transform(_fadeCtrl.value);
                    return Transform.translate(
                      offset: Offset(0, (1 - t) * 8),
                      child: Transform.scale(
                        scale: 0.995 + t * 0.005,
                        child: child,
                      ),
                    );
                  },
                  child: IndexedStack(index: currentIndex, children: _tabs),
                ),
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: GlassBottomNavigationBar(
                currentIndex: currentIndex,
                items: _navItems,
                onTap: _onTabSelected,
                collapse: _collapse,
                backdropLuminance: _backdropLuminance,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _handleScroll(ScrollNotification notification) {
    if (ref.read(navCollapseProvider) > 0.0) return false;

    if (notification is UserScrollNotification) {
      if (notification.metrics.axis != Axis.vertical) return false;
      if (notification.direction == ScrollDirection.reverse) {
        // Scrolling down sinks the bar smoothly
        _navAnimCtrl.forward();
      } else if (notification.direction == ScrollDirection.forward) {
        // Scrolling up returns the bar smoothly
        _navAnimCtrl.reverse();
      }
    }

    if (notification is ScrollUpdateNotification) {
      if (notification.metrics.axis != Axis.vertical) return false;

      // Light adaptation: derive an approximate luminance for the content
      // currently sitting behind the glass from the scroll offset. This is a
      // cheap proxy — no per-frame backdrop sampling — that still lets the
      // material brighten over dark regions and darken over bright ones.
      final metrics = notification.metrics;
      if (metrics.maxScrollExtent > 0) {
        final progress = (metrics.pixels / metrics.maxScrollExtent).clamp(
          0.0,
          1.0,
        );
        // Content tends to get richer/darker as you scroll into the feed.
        _backdropLuminance.value = (0.72 - progress * 0.44).clamp(0.15, 0.9);
      }
    }
    return false;
  }
}
