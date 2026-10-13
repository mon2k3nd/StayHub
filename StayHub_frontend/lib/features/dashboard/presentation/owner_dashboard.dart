import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../application/suggested_features_provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_notifier.dart';
import '../../notification/data/unread_notifications_count_provider.dart';
import '../../room/presentation/rent_out_room_screen.dart';
import '../../room/presentation/record_utilities_screen.dart';
import 'expense_management_screen.dart';
import 'vehicle_management_screen.dart';
import 'ct01_export_screen.dart';
import '../../notification/presentation/broadcast_screen.dart';
import '../../ticket/presentation/maintenance_screen.dart';
import '../../iot/presentation/iot_management_screen.dart';
import 'package:stayhub_frontend/core/components/stayhub_logo_icon.dart';
import '../../../core/utils/toast_utils.dart';
import 'owner_archive_tab.dart';
import '../../analytics/presentation/owner_analytics_screen.dart';
import '../../search/presentation/owner_search_tab.dart';
import 'widgets/owner_home_tab.dart';
import 'dart:async' show unawaited;
import '../../tenant/presentation/business_landing_screen.dart';
import '../application/owner_demo_mode_provider.dart';
// removed unused in_app_notification_banner

// ─── Main Owner Dashboard ────────────────────────────────────────────────────

class OwnerDashboard extends ConsumerStatefulWidget {
  const OwnerDashboard({super.key});

  @override
  ConsumerState<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends ConsumerState<OwnerDashboard> {
  int _currentIndex = 0;
  final List<int> _visitedTabs = [0];

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(unreadNotificationsCountProvider).value ?? 0;
    final user = ref.watch(authProvider).value;
    final isDemoMode = ref.watch(ownerDemoModeProvider);

    // Chặn người thuê / tài khoản chưa được cấp quyền Chủ nhà (trừ khi đang mở Chế độ Trải nghiệm thử)
    if (user != null && user.role != 'OWNER' && !isDemoMode) {
      return _buildUnauthorizedHostView(context, user);
    }

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.kBackgroundLight,
      child: Stack(
        children: [
          // Light Mode Background
          Positioned.fill(child: Container(color: AppTheme.kBackgroundLight)),
          // Top Sky Blue Gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 350,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.kBrand.withValues(alpha: 0.15),
                    AppTheme.kBrand.withValues(alpha: 0.05),
                    AppTheme.kBackgroundLight.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // Background Orbs for Premium feel
          Positioned(
            top: -50,
            right: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.kBrand.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          Positioned(
            top: 150,
            left: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.kBrandDeep.withValues(alpha: 0.2), // Sky 600
                ),
              ),
            ),
          ),
          IndexedStack(
            index: _currentIndex,
            children: [
              const OwnerHomeTab(),
              if (user != null)
                _visitedTabs.contains(1)
                    ? SafeArea(
                        bottom: false,
                        child: OwnerAnalyticsScreen(ownerId: user.id),
                      )
                    : const SizedBox()
              else
                const SizedBox(),
              const SizedBox(), // FAB placeholder
              _visitedTabs.contains(3)
                  ? const SafeArea(bottom: false, child: OwnerArchiveTab())
                  : const SizedBox(),
              _visitedTabs.contains(4)
                  ? const SafeArea(bottom: false, child: OwnerSearchTab())
                  : const SizedBox(),
            ],
          ),
          // ─── Floating Liquid Glass Nav ────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _OwnerFloatingNav(
              currentIndex: _currentIndex,
              unreadCount: unreadCount,
              onTap: (i) {
                setState(() {
                  _currentIndex = i;
                  if (!_visitedTabs.contains(i)) {
                    _visitedTabs.add(i);
                  }
                });
              },
              onCenterTap: () {
                _showQuickActionSheet(context);
              },
            ),
          ),
          // ─── Banner Chế độ Demo Sandbox (Nếu đang trải nghiệm) ───
          if (isDemoMode)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: _buildDemoSandboxBanner(context),
              ),
            ),
        ],
      ),
    );
  }

  void _showQuickActionSheet(BuildContext context) {
    unawaited(HapticFeedback.lightImpact());
    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => const LiquidBottomSheet(),
      ),
    );
  }

  Widget _buildUnauthorizedHostView(BuildContext context, dynamic user) {
    final name =
        (user.fullName != null && user.fullName.toString().trim().isNotEmpty)
            ? user.fullName
            : user.phoneNumber;

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.kBackgroundLight,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.kBrand.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.kBrand.withValues(alpha: 0.35),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    CupertinoIcons.lock_shield_fill,
                    color: AppTheme.kBrand,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Yêu cầu quyền Chủ nhà',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Tài khoản hiện tại ($name) chưa được kích hoạt quyền Quản trị phòng trọ. Để truy cập bảng điều khiển, bạn cần hoàn tất đăng ký đối tác kinh doanh.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  unawaited(
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => const BusinessLandingScreen(),
                      ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF69B1FF), Color(0xFF4A90E2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x3369B1FF),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.sparkles,
                          color: CupertinoColors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '👑 Đăng ký làm Chủ nhà ngay',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Nút Trải nghiệm thử Demo Sandbox
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  ref.read(ownerDemoModeProvider.notifier).setDemoMode(true);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.6),
                      width: 1.2,
                    ),
                  ),
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.sparkles,
                          color: Color(0xFFD97706),
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '✨ Khám phá thử Dashboard (Xem trước)',
                          style: TextStyle(
                            color: Color(0xFFB45309),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => context.go('/guest'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Center(
                    child: Text(
                      'Quay lại giao diện Khám phá',
                      style: TextStyle(
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Banner Liquid Glass hiển thị trên đỉnh màn hình khi đang ở Chế độ Trải nghiệm thử
  Widget _buildDemoSandboxBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1AF59E0B),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFDE68A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              CupertinoIcons.sparkles,
              size: 16,
              color: Color(0xFFB45309),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CHẾ ĐỘ TRẢI NGHIỆM THỬ',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF92400E),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Dữ liệu mẫu 50 phòng trọ StayHub',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF78350F),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            color: const Color(0xFFD97706),
            borderRadius: BorderRadius.circular(50),
            minimumSize: const Size(0, 28),
            onPressed: () {
              unawaited(
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => const BusinessLandingScreen(),
                  ),
                ),
              );
            },
            child: const Text(
              'Đăng ký thật',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: CupertinoColors.white,
              ),
            ),
          ),
          const SizedBox(width: 6),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 28),
            onPressed: () {
              ref.read(ownerDemoModeProvider.notifier).setDemoMode(false);
              context.go('/guest');
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.xmark,
                size: 13,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Liquid Drop Bottom Navigation Bar ────────────────────────────────────────
// Drag + Tap: Giọt nước 48px glassmorphism trượt giữa các tab
// ──────────────────────────────────────────────────────────────────────────────
class _OwnerFloatingNav extends StatefulWidget {
  final int currentIndex;
  final int unreadCount;
  final ValueChanged<int> onTap;
  final VoidCallback onCenterTap;

  const _OwnerFloatingNav({
    required this.currentIndex,
    required this.unreadCount,
    required this.onTap,
    required this.onCenterTap,
  });

  @override
  State<_OwnerFloatingNav> createState() => _OwnerFloatingNavState();
}

class _OwnerFloatingNavState extends State<_OwnerFloatingNav>
    with TickerProviderStateMixin {
  // ─── FAB Animation ───
  late AnimationController _fabCtrl;
  bool _fabPressed = false;

  // ─── Spring Animation for Tap ───
  late AnimationController _springCtrl;
  late CurvedAnimation _springCurve;

  // ─── Bounce Animation for Tap ───
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  // ─── Stretch Animation for Drag Release ───
  late AnimationController _stretchResetCtrl;
  late Animation<double> _stretchResetAnim;

  // ─── Idle Wobble Animation ───
  late AnimationController _idleCtrl;

  // ─── Drop Position ───
  double _dropFraction = 0.0; // 0.0–1.0 normalized position across nav bar
  double _fromFraction = 0.0; // Start fraction for spring animation
  double _toFraction = 0.0; // End fraction for spring animation

  // ─── Drag State ───
  bool _isDragging = false;
  double _dragStretch = 1.0; // scaleX for liquid stretch effect (1.0–1.3)

  // ─── Tab Configuration ───
  // Fraction positions for each nav item within the bar (excluding FAB gap)
  // Layout: [Tab0][Tab1]---[FAB 80px gap]---[Tab2][Tab3]
  // Each side takes (totalWidth - 80) / 2, each tab = side / 2
  static const _navItems = [
    (
      icon: CupertinoIcons.square_grid_2x2_fill,
      label: 'Tổng quan',
      idx: 0,
      image: 'assets/images/features/feat_home.png',
    ),
    (
      icon: CupertinoIcons.chart_pie_fill,
      label: 'Thống kê',
      idx: 1,
      image: 'assets/images/features/feat_analytics.png',
    ),
    (
      icon: CupertinoIcons.folder_solid,
      label: 'Hồ sơ',
      idx: 3,
      image: 'assets/images/features/document_vault.png',
    ),
    (
      icon: CupertinoIcons.search,
      label: 'Tra cứu',
      idx: 4,
      image: 'assets/images/features/feat_search.png',
    ),
  ];

  List<double> _tabFractions(double navWidth) {
    if (navWidth <= 0) return [0.0, 0.25, 0.75, 1.0];
    const padding = 16.0;
    final sideWidth = (navWidth - 80 - (padding * 2)) / 2;
    final tabWidth = sideWidth / 2;
    return [
      (padding + tabWidth / 2) / navWidth,
      (padding + tabWidth + tabWidth / 2) / navWidth,
      (padding + sideWidth + 80 + tabWidth / 2) / navWidth,
      (padding + sideWidth + 80 + tabWidth + tabWidth / 2) / navWidth,
    ];
  }

  int _tabVisualIndex(int pageIdx) {
    switch (pageIdx) {
      case 0:
        return 0;
      case 1:
        return 1;
      case 3:
        return 2;
      case 4:
        return 3;
      default:
        return 0;
    }
  }

  int _pageIndex(int visualIdx) {
    switch (visualIdx) {
      case 0:
        return 0;
      case 1:
        return 1;
      case 2:
        return 3;
      case 3:
        return 4;
      default:
        return 0;
    }
  }

  @override
  void initState() {
    super.initState();

    // FAB press animation
    _fabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    // Spring controller for tap-to-jump
    _springCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _springCurve = CurvedAnimation(
      parent: _springCtrl,
      curve: Curves.easeOutCubic,
    );
    _springCtrl.addListener(() {
      if (!_isDragging) {
        setState(() {
          _dropFraction = lerpDouble(
            _fromFraction,
            _toFraction,
            _springCurve.value,
          )!;
        });
      }
    });

    // Bounce controller for scale pop on tap
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceAnim = TweenSequence<double>(
      [
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 25),
        TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.12), weight: 40),
        TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 35),
      ],
    ).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeOutCubic));

    // Stretch reset after drag release
    _stretchResetCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _stretchResetAnim = const AlwaysStoppedAnimation(1.0);
    _stretchResetCtrl.addListener(() {
      setState(() {
        _dragStretch = _stretchResetAnim.value;
      });
    });

    // Idle Wobble for organic shape
    _idleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _idleCtrl.addListener(() => setState(() {}));
    unawaited(_idleCtrl.repeat(reverse: true));
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    _springCtrl.dispose();
    _bounceCtrl.dispose();
    _stretchResetCtrl.dispose();
    _idleCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _OwnerFloatingNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    // External index change (e.g., from parent) — animate drop to new tab
    if (oldWidget.currentIndex != widget.currentIndex && !_isDragging) {
      final targetVisualIdx = _tabVisualIndex(widget.currentIndex);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final screenWidth = MediaQuery.of(context).size.width;
        final effectiveNavWidth = screenWidth - 32;
        final fractions = _tabFractions(effectiveNavWidth);
        // Only trigger animation if not already heading there (prevents drag duplicate trigger)
        if ((_toFraction - fractions[targetVisualIdx]).abs() > 0.01) {
          _performAnimation(targetVisualIdx, effectiveNavWidth);
        }
      });
    }
  }

  void _performAnimation(int visualIdx, double navWidth) {
    if (!mounted) return;
    final fractions = _tabFractions(navWidth);
    _fromFraction = _dropFraction;
    _toFraction = fractions[visualIdx];
    _springCtrl.duration = const Duration(milliseconds: 250);
    unawaited(_springCtrl.forward(from: 0.0));
    unawaited(_bounceCtrl.forward(from: 0.0));
  }

  void _onTabTap(int visualIdx, double navWidth) {
    unawaited(HapticFeedback.selectionClick());
    // Only notify parent. didUpdateWidget will smoothly trigger the animation
    widget.onTap(_pageIndex(visualIdx));
  }

  int _nearestTab(double fraction, double navWidth) {
    final fractions = _tabFractions(navWidth);
    int nearest = 0;
    double minDist = double.infinity;
    for (int i = 0; i < fractions.length; i++) {
      final dist = (fraction - fractions[i]).abs();
      if (dist < minDist) {
        minDist = dist;
        nearest = i;
      }
    }
    return nearest;
  }

  // ─── Drag Handlers ───
  void _onDragStart(DragStartDetails details, double navWidth) {
    _springCtrl.stop();
    setState(() {
      _isDragging = true;
      _dragStretch = 1.0;
    });
  }

  void _onDragUpdate(DragUpdateDetails details, double navWidth) {
    final dx = details.delta.dx;
    final fractionDelta = dx / navWidth;
    setState(() {
      _dropFraction = (_dropFraction + fractionDelta).clamp(0.0, 1.0);
      // Stretch proportional to drag velocity — max 1.45x
      _dragStretch = (1.0 + (dx.abs() / 150).clamp(0.0, 0.45));
    });
  }

  void _onDragEnd(DragEndDetails details, double navWidth) {
    final velocity = details.velocity.pixelsPerSecond.dx;
    int snapIdx = _nearestTab(_dropFraction, navWidth);

    // Fling: if velocity > 300, snap to next tab in drag direction
    if (velocity.abs() > 300) {
      final currentNearest = _nearestTab(_dropFraction, navWidth);
      if (velocity > 0 && currentNearest < 3) {
        snapIdx = currentNearest + 1;
      } else if (velocity < 0 && currentNearest > 0) {
        snapIdx = currentNearest - 1;
      }
    }

    setState(() => _isDragging = false);

    // Animate stretch back to 1.0
    final capturedStretch = _dragStretch;
    _stretchResetAnim = Tween<double>(begin: capturedStretch, end: 1.0).animate(
      CurvedAnimation(parent: _stretchResetCtrl, curve: Curves.easeOutCubic),
    );
    unawaited(_stretchResetCtrl.forward(from: 0.0));

    // Spring to nearest tab (faster 400ms for snap)
    final fractions = _tabFractions(navWidth);
    _fromFraction = _dropFraction;
    _toFraction = fractions[snapIdx];

    _springCtrl.duration = const Duration(milliseconds: 250);
    unawaited(
      _springCtrl.forward(from: 0.0).then((_) {
        if (mounted) {
          _springCtrl.duration = const Duration(
            milliseconds: 300,
          ); // Reset to tap duration
        }
      }),
    );

    unawaited(HapticFeedback.selectionClick());
    widget.onTap(_pageIndex(snapIdx));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.only(bottom: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final navWidth = constraints.maxWidth - 32; // margin 16 each side
          final fractions = _tabFractions(navWidth);

          // Initialize drop position on first build
          if (_dropFraction == 0.0 &&
              !_isDragging &&
              !_springCtrl.isAnimating) {
            final initIdx = _tabVisualIndex(widget.currentIndex);
            _dropFraction = fractions[initIdx];
          }

          // Activation is dynamically calculated in the item builder for true lens effect

          // Idle Wobble values (organic water drop shape)
          final idleVal = _idleCtrl.value;
          final tl = lerpDouble(26, 22, idleVal)!;
          final tr = lerpDouble(26, 28, idleVal)!;
          final bl = lerpDouble(26, 24, idleVal)!;
          final br = lerpDouble(26, 27, idleVal)!;
          final dropRadius = BorderRadius.only(
            topLeft: Radius.circular(tl),
            topRight: Radius.circular(tr),
            bottomLeft: Radius.circular(bl),
            bottomRight: Radius.circular(br),
          );
          const dropHeight = 54.0;
          const dropWidth = 64.0; // Reduced to prevent clipping at edges
          final dropX = _dropFraction * navWidth;

          // Compute Liquid stretch during tap transit
          double currentStretch = 1.0;
          if (_isDragging || _stretchResetCtrl.isAnimating) {
            currentStretch = _dragStretch;
          } else if (_springCtrl.isAnimating) {
            final distance = (_toFraction - _fromFraction).abs();
            final stretchMagnitude = (distance * 1.5).clamp(0.0, 0.45);
            final t = _springCtrl.value; // goes 0 to 1
            final parabola = 4 * t * (1 - t);
            currentStretch = 1.0 + (parabola * stretchMagnitude);
          }

          // FAB Zone Dip
          final distToCenter = (_dropFraction - 0.5).abs();
          final dipZone = navWidth > 0 ? (50 / navWidth) : 0.2;
          double dipFactor = 1.0;
          double dipTranslateY = 0.0;
          if (distToCenter < dipZone) {
            final normalizedDist = distToCenter / dipZone;
            final curve = Curves.easeOut.transform(normalizedDist);
            dipFactor = lerpDouble(0.4, 1.0, curve)!;
            dipTranslateY = lerpDouble(16.0, 0.0, curve)!;
          }

          return Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              // ─── Nav Bar Background ───
              Container(
                height: 72,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    36,
                  ), // Makes the shadow pill-shaped
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.kBrandDeep.withValues(alpha: 0.15),
                      blurRadius: 30,
                      spreadRadius: -2,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipPath(
                  clipper: _LiquidNavClipper(),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.kBrandLight.withValues(
                              alpha: 0.65,
                            ), // Lighter blue
                            AppTheme.kBrand.withValues(alpha: 0.75),
                          ],
                        ),
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.45),
                            width: 0.8,
                          ),
                        ),
                      ),
                      child: Stack(
                        children: [
                          // ─── LIQUID DROP (LENS) ───
                          Positioned(
                            left: dropX - (dropWidth / 2),
                            top: (72 - dropHeight) / 2,
                            child: Transform.translate(
                              offset: Offset(0, dipTranslateY),
                              child: AnimatedScale(
                                scale: _isDragging ? 1.15 : 1.0,
                                duration: const Duration(milliseconds: 150),
                                curve: Curves.easeOutBack,
                                child: Transform.scale(
                                  scaleX: currentStretch * dipFactor,
                                  scaleY:
                                      (currentStretch > 1.0
                                          ? (2.0 - currentStretch).clamp(
                                              0.85,
                                              1.0,
                                            )
                                          : 1.0) *
                                      dipFactor,
                                  child: Transform.scale(
                                    scale: _bounceCtrl.isAnimating
                                        ? _bounceAnim.value
                                        : 1.0,
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      width: dropWidth,
                                      height: dropHeight,
                                      decoration: BoxDecoration(
                                        borderRadius: dropRadius,
                                        boxShadow: [
                                          // Drop shadow for the water droplet
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.15,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 8),
                                          ),
                                          // Inner soft color shadow to simulate liquid caustic
                                          BoxShadow(
                                            color: const Color(
                                              0xFF1A6FD4,
                                            ).withValues(alpha: 0.3),
                                            blurRadius: 15,
                                            spreadRadius: 2,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: dropRadius,
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(
                                            sigmaX: 3.0,
                                            sigmaY: 3.0,
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius: dropRadius,
                                              border: Border.all(
                                                color: Colors.white.withValues(
                                                  alpha: 0.6,
                                                ), // crisp edge
                                                width: 1.0,
                                              ),
                                              // Glassy/Watery body
                                              gradient: RadialGradient(
                                                center: const Alignment(
                                                  -0.2,
                                                  -0.4,
                                                ),
                                                radius: 1.2,
                                                colors: [
                                                  Colors.white.withValues(
                                                    alpha: 0.5,
                                                  ), // Highlight at top-left
                                                  Colors.white.withValues(
                                                    alpha: 0.05,
                                                  ), // Transparent core
                                                  Colors.black.withValues(
                                                    alpha: 0.15,
                                                  ), // Shaded edge at bottom-right
                                                ],
                                                stops: const [0.0, 0.5, 1.0],
                                              ),
                                            ),
                                            child: Stack(
                                              children: [
                                                // Primary specular highlight (curved top edge reflection)
                                                Positioned(
                                                  top: 3,
                                                  left: 10,
                                                  right: 10,
                                                  child: Container(
                                                    height: 14,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          const BorderRadius.vertical(
                                                            top:
                                                                Radius.elliptical(
                                                                  40,
                                                                  20,
                                                                ),
                                                            bottom:
                                                                Radius.elliptical(
                                                                  50,
                                                                  10,
                                                                ),
                                                          ),
                                                      gradient: LinearGradient(
                                                        begin:
                                                            Alignment.topCenter,
                                                        end: Alignment
                                                            .bottomCenter,
                                                        colors: [
                                                          Colors.white
                                                              .withValues(
                                                                alpha: 0.8,
                                                              ),
                                                          Colors.white
                                                              .withValues(
                                                                alpha: 0.0,
                                                              ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                // Secondary specular highlight (bottom edge glow)
                                                Positioned(
                                                  bottom: 2,
                                                  left: 18,
                                                  right: 18,
                                                  child: Container(
                                                    height: 6,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          const BorderRadius.all(
                                                            Radius.elliptical(
                                                              30,
                                                              10,
                                                            ),
                                                          ),
                                                      gradient: LinearGradient(
                                                        begin: Alignment
                                                            .bottomCenter,
                                                        end:
                                                            Alignment.topCenter,
                                                        colors: [
                                                          Colors.white
                                                              .withValues(
                                                                alpha: 0.5,
                                                              ),
                                                          Colors.white
                                                              .withValues(
                                                                alpha: 0.0,
                                                              ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // ─── TABS ───
                          Positioned.fill(
                            child: Row(
                              children: [
                                const SizedBox(width: 16),
                                for (int i = 0; i < 2; i++)
                                  Expanded(
                                    child: _buildNavItem(
                                      _navItems[i],
                                      i,
                                      fractions[i],
                                      navWidth,
                                    ),
                                  ),
                                const SizedBox(width: 80), // FAB gap
                                for (int i = 2; i < 4; i++)
                                  Expanded(
                                    child: _buildNavItem(
                                      _navItems[i],
                                      i,
                                      fractions[i],
                                      navWidth,
                                    ),
                                  ),
                                const SizedBox(width: 16),
                              ],
                            ),
                          ),

                          // ─── 3. DRAG GESTURE LAYER ───
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onHorizontalDragStart: (d) =>
                                  _onDragStart(d, navWidth),
                              onHorizontalDragUpdate: (d) =>
                                  _onDragUpdate(d, navWidth),
                              onHorizontalDragEnd: (d) =>
                                  _onDragEnd(d, navWidth),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ─── Center Giant Action Button ───
              Positioned(
                top: -16,
                left: 0,
                right: 0,
                child: Center(child: _buildCenterButton()),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavItem(
    dynamic item,
    int visualIndex,
    double itemFraction,
    double navWidth,
  ) {
    // Check how close this item is to the drop
    final distance = (_dropFraction - itemFraction).abs();
    // Activation threshold (how close the drop needs to be to start magnifying)
    final threshold = navWidth > 0 ? (60 / navWidth) : 0.15;

    // Calculate activation percentage (0.0 to 1.0)
    double activation = 0.0;
    if (distance < threshold) {
      activation = 1.0 - (distance / threshold);
      // Smooth curve for natural magnification
      activation = Curves.easeOutCubic.transform(activation);
    }

    return GestureDetector(
      onTap: () => _onTabTap(visualIndex, navWidth),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 72,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: lerpDouble(0.55, 1.0, activation) ?? 1.0,
              child: Image.asset(
                item.image,
                width: lerpDouble(30, 24, activation) ?? 24.0,
                height: lerpDouble(30, 24, activation) ?? 24.0,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => Icon(
                  item.icon,
                  color: Color.lerp(
                    Colors.white.withValues(alpha: 0.5),
                    Colors.white,
                    activation,
                  ),
                  size: lerpDouble(28, 20, activation),
                ),
              ),
            ),
            ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: activation.clamp(0.0, 1.0),
                child: Opacity(
                  opacity: activation.clamp(0.0, 1.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    return GestureDetector(
      onTapDown: (_) {
        unawaited(_fabCtrl.forward());
        setState(() => _fabPressed = true);
      },
      onTapUp: (_) {
        unawaited(_fabCtrl.reverse());
        setState(() => _fabPressed = false);
        unawaited(HapticFeedback.heavyImpact());
        widget.onCenterTap();
      },
      onTapCancel: () {
        unawaited(_fabCtrl.reverse());
        setState(() => _fabPressed = false);
      },
      child: AnimatedScale(
        scale: _fabPressed ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Vầng sáng tỏa rộng
              Positioned(
                bottom: 8,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  width: _fabPressed ? 56 : 50,
                  height: _fabPressed ? 56 : 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.kBrandGlow.withValues(
                          alpha: _fabPressed ? 0.45 : 0.25,
                        ),
                        blurRadius: _fabPressed ? 44 : 36,
                        spreadRadius: _fabPressed ? 10 : 6,
                      ),
                      BoxShadow(
                        color: AppTheme.kBrandLight.withValues(
                          alpha: _fabPressed ? 0.5 : 0.30,
                        ),
                        blurRadius: _fabPressed ? 28 : 22,
                        spreadRadius: _fabPressed ? 4 : 2,
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(
                          alpha: _fabPressed ? 0.35 : 0.18,
                        ),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
              StayHubLogoIcon(
                useWhite: true,
                size: 64,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiquidNavClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const cornerRadius = 36.0; // Perfect pill shape (72 / 2)

    // Start at top left
    path.moveTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);

    // Draw top edge to the notch
    final center = size.width / 2;

    // Smooth Sexy Notch
    path.lineTo(center - 54, 0);

    // First half of the U-notch
    path.cubicTo(
      center - 26,
      0, // Pull right smoothly
      center - 24,
      40, // Pull down smoothly
      center,
      40, // Bottom center
    );

    // Second half of the U-notch
    path.cubicTo(
      center + 24,
      40, // Pull up
      center + 26,
      0, // Pull left smoothly
      center + 54,
      0, // Top edge
    );

    // Draw top edge to right
    path.lineTo(size.width - cornerRadius, 0);
    path.quadraticBezierTo(size.width, 0, size.width, cornerRadius);

    // Draw right edge
    path.lineTo(size.width, size.height - cornerRadius);

    // Bottom right corner
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - cornerRadius,
      size.height,
    );

    // Bottom edge to left
    path.lineTo(cornerRadius, size.height);

    // Bottom left corner
    path.quadraticBezierTo(0, size.height, 0, size.height - cornerRadius);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ─── Liquid Twin-Tab Bottom Sheet ───────────────────────────────────────────
class LiquidBottomSheet extends ConsumerStatefulWidget {
  const LiquidBottomSheet({super.key});

  @override
  ConsumerState<LiquidBottomSheet> createState() => _LiquidBottomSheetState();
}

class _LiquidBottomSheetState extends ConsumerState<LiquidBottomSheet> {
  int _activeTab = 0; // 0: Tiện ích & Quản lý, 1: AI Support
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    final isPendingKYC = user != null && user.kycStatus == 'PENDING';

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
              child: Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.white.withValues(alpha: 0.85),
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppTheme.kTextMuted,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Twin Tabs
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              left: _activeTab == 0
                                  ? 4
                                  : (MediaQuery.of(context).size.width - 48) /
                                        2,
                              top: 4,
                              bottom: 4,
                              width:
                                  (MediaQuery.of(context).size.width - 48) / 2 -
                                  8,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _activeTab == 0
                                        ? [AppTheme.kBrandDeep, AppTheme.kBrand]
                                        : [
                                            const Color(0xFF8B5CF6),
                                            const Color(0xFF6D28D9),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          (_activeTab == 0
                                                  ? AppTheme.kBrandDeep
                                                  : const Color(0xFF8B5CF6))
                                              .withValues(alpha: 0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Tab Labels
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      unawaited(
                                        HapticFeedback.selectionClick(),
                                      );
                                      setState(() => _activeTab = 0);
                                    },
                                    behavior: HitTestBehavior.opaque,
                                    child: Center(
                                      child: AnimatedDefaultTextStyle(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: _activeTab == 0
                                              ? FontWeight.w700
                                              : FontWeight.w600,
                                          color: _activeTab == 0
                                              ? Colors.white
                                              : AppTheme.kTextSecondary,
                                        ),
                                        child: const Text('🗂️ Quản lý'),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      unawaited(
                                        HapticFeedback.selectionClick(),
                                      );
                                      setState(() => _activeTab = 1);
                                    },
                                    behavior: HitTestBehavior.opaque,
                                    child: Center(
                                      child: AnimatedDefaultTextStyle(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: _activeTab == 1
                                              ? FontWeight.w800
                                              : FontWeight.w600,
                                          color: _activeTab == 1
                                              ? Colors.white
                                              : AppTheme.kTextSecondary,
                                        ),
                                        child: const Text('✨ AI Support'),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ShaderMask(
                        shaderCallback: (Rect bounds) {
                          return const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white, Colors.transparent],
                            stops: [0.95, 1.0],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.dstIn,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _activeTab == 0
                              ? _buildManageTab(
                                  context,
                                  user,
                                  isPendingKYC,
                                  scrollController,
                                )
                              : _buildAITab(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAITab(BuildContext context) {
    return const _AiChatTab();
  }

  Widget _buildManageTab(
    BuildContext context,
    dynamic user,
    bool isPendingKYC,
    ScrollController scrollController,
  ) {
    final categories = getOwnerActionCategories(context, user, isPendingKYC);

    // Filter logic
    final filteredCategories = categories
        .map((cat) {
          // BUGFIX (data): trước đây ép `as List<ActionItem>` — nếu `items`
          // không đúng kiểu thì ném TypeError và cả màn hình dashboard không
          // render. Guard an toàn.
          final rawItems = cat['items'];
          final items = rawItems is List<ActionItem>
              ? rawItems
              : <ActionItem>[];
          final filteredItems = items
              .where(
                (item) => item.label.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();
          return {'title': cat['title'], 'items': filteredItems};
        })
        // BUGFIX (data): tránh `as List` ném TypeError khi `items` không phải List.
        .where(
          (cat) => (cat['items'] is List) && (cat['items'] as List).isNotEmpty,
        )
        .toList();

    return SingleChildScrollView(
      key: const ValueKey(0),
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 64, top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mâm tìm kiếm xịn xò
          CupertinoSearchTextField(
            placeholder: 'Tìm kiếm tính năng (Vd: Khách, Điện nước)...',
            onChanged: (value) => setState(() => _searchQuery = value),
            style: const TextStyle(fontSize: 14, color: AppTheme.kTextPrimary),
            backgroundColor: Colors.black.withValues(alpha: 0.04),
          ),
          const SizedBox(height: 24),

          if (filteredCategories.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'Không tìm thấy tính năng nào',
                  style: TextStyle(color: AppTheme.kTextSecondary),
                ),
              ),
            ),

          ...filteredCategories.map((cat) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: _buildActionCategory(
                cat['title']?.toString() ?? '',
                cat['items'] is List<ActionItem>
                    ? cat['items'] as List<ActionItem>
                    : <ActionItem>[],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionCategory(String title, List<ActionItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF298FFF), AppTheme.kBrand],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 3 * 12) / 4;
            return Wrap(
              spacing: 12,
              runSpacing: 16,
              children: items.asMap().entries.map((e) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 280 + (e.key * 40)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Transform.translate(
                    offset: Offset(0, 12 * (1 - value)),
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  ),
                  child: SizedBox(
                    width: itemWidth,
                    child: _QuickActionButton(item: e.value),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class ActionItem {
  final String label;
  final IconData? icon;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;
  final bool hasShadow;

  /// Optional premium 3D isometric icon asset. When provided, the UI renders
  /// this image instead of the flat [icon] glyph.
  final String? imagePath;

  ActionItem(
    this.label,
    this.icon,
    this.iconColor,
    this.bgColor,
    this.onTap, {
    this.hasShadow = false,
    this.imagePath,
  });
}

class _QuickActionButton extends ConsumerStatefulWidget {
  final ActionItem item;
  const _QuickActionButton({required this.item});

  @override
  ConsumerState<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends ConsumerState<_QuickActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        unawaited(HapticFeedback.lightImpact());
        unawaited(_animCtrl.forward());
      },
      onTapUp: (_) {
        unawaited(_animCtrl.reverse());
        unawaited(
          ref
              .read(suggestedFeaturesProvider.notifier)
              .prioritizeFeature(widget.item.label),
        );
        Navigator.pop(context);
        widget.item.onTap();
      },
      onTapCancel: () => _animCtrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: widget.item.iconColor == const Color(0xFF111827)
                    ? const LinearGradient(
                        colors: [Color(0xFF1F2937), Color(0xFF374151)],
                      )
                    : LinearGradient(
                        colors: [widget.item.bgColor, widget.item.bgColor],
                      ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color:
                        (widget.item.iconColor == const Color(0xFF111827)
                                ? const Color(0xFF1F2937)
                                : widget.item.iconColor)
                            .withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                widget.item.icon,
                color: widget.item.iconColor == const Color(0xFF111827)
                    ? Colors.white
                    : widget.item.iconColor,
                size: 26,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.item.label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Home Tab ────────────────────────────────────────────────────────────────

// ─── Inline AI Chat for Bottom Sheet ────────────────────────────────────────
class _AiChatTab extends StatefulWidget {
  const _AiChatTab();
  @override
  State<_AiChatTab> createState() => _AiChatTabState();
}

class _AiChatTabState extends State<_AiChatTab> {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  static const String _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  late final GenerativeModel _model;
  late final ChatSession _chat;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: _apiKey);
    _chat = _model.startChat(
      history: [
        Content.text(
          '''Bạn là AI Giám Đốc Vận Hành của StayHub, được thiết kế riêng để phục vụ Chủ nhà.
Dữ liệu hiện tại: 50 phòng, đang thuê 45, trống 5. Doanh thu dự kiến 185tr, đã thu 140tr, còn nợ 45tr.
Hãy trả lời ngắn gọn, súc tích bằng tiếng Việt.''',
        ),
      ],
    );

    _messages.add({
      'role': 'ai',
      'text':
          '👋 Xin chào Sếp! Sếp cần xem báo cáo dòng tiền, công nợ hay tình hình phòng trống hôm nay ạ?',
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await _chat.sendMessage(Content.text(text));
      final reply = response.text ?? 'Xin lỗi Sếp, hệ thống vừa gặp sự cố nhỏ.';
      if (mounted) {
        setState(() {
          _messages.add({'role': 'ai', 'text': reply});
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'ai',
            'text': 'Xin lỗi Sếp, kết nối bị gián đoạn.',
          });
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        unawaited(
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey(1),
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isAi = msg['role'] == 'ai';
              return _buildChatBubble(msg['text']!, isAi);
            },
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: CupertinoActivityIndicator(),
          ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildChatBubble(String text, bool isAi) {
    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isAi ? CupertinoColors.white : const Color(0xFF8B5CF6),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isAi ? 4 : 20),
            bottomRight: Radius.circular(isAi ? 20 : 4),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.kTextSecondary.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          text,
          style: TextStyle(
            color: isAi ? CupertinoColors.black : CupertinoColors.white,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 24),
      decoration: BoxDecoration(
        color: CupertinoColors.white.withValues(alpha: 0.5),
        border: const Border(top: BorderSide(color: AppTheme.kBorderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: CupertinoTextField(
              controller: _textCtrl,
              placeholder: 'Hỏi AI...',
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.kBorderColor),
              ),
              onSubmitted: (_) => _sendMessage(),
              style: const TextStyle(fontSize: 15),
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {},
            child: const Icon(
              CupertinoIcons.bell_fill,
              color: Color(0xFF8B5CF6),
              size: 22,
            ),
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _isLoading ? null : _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFF8B5CF6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.paperplane_fill,
                color: CupertinoColors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<Map<String, dynamic>> getOwnerActionCategories(
  BuildContext context,
  dynamic user,
  bool isPendingKYC,
) {
  return [
    {
      'title': 'KHỞI TẠO & LƯU TRÚ',
      'items': [
        ActionItem(
          'Thêm Chi Nhánh',
          CupertinoIcons.building_2_fill,
          AppTheme.kBrand,
          const Color(0xFFE3F0FF),
          imagePath: 'assets/images/features/multi_property.png',
          () {
            if (isPendingKYC) {
              ToastUtils.show(
                context,
                'Bạn chưa được Admin phê duyệt để dùng tính năng này',
                isError: true,
              );
              return;
            }
            if (user == null ||
                user.cccdNumber == null ||
                user.cccdNumber!.isEmpty) {
              ToastUtils.show(
                context,
                'Vui lòng bổ sung thông tin định danh KYC!',
                isError: true,
              );
              unawaited(
                context.push('/profile-update', extra: {'nextRoute': '/'}),
              );
              return;
            }
            unawaited(context.push('/branch/wizard'));
          },
        ),
        ActionItem(
          'Quản lý Chi Nhánh',
          CupertinoIcons.list_bullet_below_rectangle,
          AppTheme.kBrand,
          const Color(0xFFE3F0FF),
          () => context.push('/branch'),
          imagePath: 'assets/images/features/multi_property.png',
        ),
        ActionItem(
          'Tạo Hợp Đồng',
          CupertinoIcons.person_crop_circle_badge_plus,
          AppTheme.kBrand,
          const Color(0xFFE3F0FF),
          () => Navigator.push(
            context,
            CupertinoPageRoute(builder: (c) => const RentOutRoomScreen()),
          ),
          imagePath: 'assets/images/features/smart_contract.png',
        ),
        ActionItem(
          'Duyệt Khách Thuê',
          CupertinoIcons.person_3_fill,
          AppTheme.kBrand,
          const Color(0xFFE3F0FF),
          () => context.push('/rental-requests'),
          imagePath: 'assets/images/features/tenant_bg_check.png',
        ),
        ActionItem(
          'Biểu Mẫu Hợp Đồng',
          CupertinoIcons.doc_text_fill,
          AppTheme.kBrand,
          const Color(0xFFE3F0FF),
          () => context.push('/contract-template-edit'),
          imagePath: 'assets/images/features/auto_pdf_gen.png',
        ),
        ActionItem(
          'Quản lý Tài Sản',
          CupertinoIcons.cube_box_fill,
          AppTheme.kBrand,
          const Color(0xFFE3F0FF),
          () => context.push('/asset-management'),
          imagePath: 'assets/images/features/inventory_management.png',
        ),
        ActionItem(
          'Danh sách Khách',
          CupertinoIcons.person_2_fill,
          AppTheme.kBrand,
          const Color(0xFFE3F0FF),
          () => context.push('/tenant-management'),
          imagePath: 'assets/images/features/feat_roommate.png',
        ),
        ActionItem(
          'Nội Quy Khu Trọ',
          CupertinoIcons.text_badge_checkmark,
          AppTheme.kBrand,
          const Color(0xFFE3F0FF),
          () => context.push('/branch-rules'),
          imagePath: 'assets/images/features/document_vault.png',
        ),
      ],
    },
    {
      'title': 'VẬN HÀNH & TÀI CHÍNH',
      'items': [
        ActionItem(
          'Quét QR Tra Cứu',
          CupertinoIcons.qrcode_viewfinder,
          AppTheme.kWarning,
          const Color(0xFFFEF3C7),
          () => context.push('/qr-scanner'),
          imagePath: 'assets/images/features/ocr_meter.png',
        ),
        ActionItem(
          'Quét Mã Nhận Tiền',
          CupertinoIcons.qrcode_viewfinder,
          AppTheme.kBrand,
          const Color(0xFFE3F0FF),
          () => context.push('/qr_cash_receiver'),
          imagePath: 'assets/images/features/one_tap_payment.png',
        ),
        ActionItem(
          'Chốt Điện Nước',
          CupertinoIcons.gauge,
          AppTheme.kBrand,
          const Color(0xFFE3F0FF),
          () => Navigator.push(
            context,
            CupertinoPageRoute(builder: (c) => const RecordUtilitiesScreen()),
          ),
          imagePath: 'assets/images/features/utilities_dashboard.png',
        ),
        ActionItem(
          'Quản lý Hóa Đơn',
          CupertinoIcons.money_dollar_circle_fill,
          AppTheme.kBrand,
          const Color(0xFFE3F0FF),
          () => context.push('/bill'),
          imagePath: 'assets/images/features/feat_payments.png',
        ),
        ActionItem(
          'Sổ Quỹ Thu Chi',
          CupertinoIcons.chart_pie_fill,
          AppTheme.kSuccess,
          const Color(0xFFD1FAE5),
          () => Navigator.push(
            context,
            CupertinoPageRoute(builder: (c) => const ExpenseManagementScreen()),
          ),
          imagePath: 'assets/images/features/expense_scanner.png',
        ),
        ActionItem(
          'Theo Dõi Công Nợ',
          CupertinoIcons.exclamationmark_triangle_fill,
          AppTheme.kError,
          const Color(0xFFFEE2E2),
          () => context.push('/debt-management'),
          imagePath: 'assets/images/features/multilevel_debt.png',
        ),
        ActionItem(
          'Thanh Lý Hợp Đồng',
          CupertinoIcons.arrow_right_square_fill,
          AppTheme.kBrand,
          const Color(0xFFE3F0FF),
          () => context.push('/owner/checkout-list'),
          imagePath: 'assets/images/features/moveout_settlement.png',
        ),
        ActionItem(
          'Phiếu Vi Phạm',
          CupertinoIcons.exclamationmark_octagon_fill,
          AppTheme.kError,
          const Color(0xFFFEE2E2),
          () => context.push('/violations'),
          imagePath: 'assets/images/features/push_alerts.png',
        ),
        ActionItem(
          'Quản lý Sự Cố',
          CupertinoIcons.exclamationmark_shield_fill,
          AppTheme.kError,
          const Color(0xFFFEE2E2),
          () => context.push('/incidents'),
          imagePath: 'assets/images/features/video_maintenance.png',
        ),
        ActionItem(
          'Lịch Bảo Trì',
          CupertinoIcons.exclamationmark_square_fill,
          AppTheme.kWarning,
          const Color(0xFFFEF3C7),
          () => Navigator.push(
            context,
            CupertinoPageRoute(builder: (c) => const MaintenanceScreen()),
          ),
          imagePath: 'assets/images/features/staff_dispatch.png',
        ),
        ActionItem(
          'Quản lý Phương Tiện',
          CupertinoIcons.car_fill,
          AppTheme.kBrand,
          const Color(0xFFE3F0FF),
          () => Navigator.push(
            context,
            CupertinoPageRoute(builder: (c) => const VehicleManagementScreen()),
          ),
          imagePath: 'assets/images/features/smart_locker.png',
        ),
        ActionItem(
          'Khai Báo Tạm Trú (CT01)',
          CupertinoIcons.doc_text_fill,
          AppTheme.kWarning,
          const Color(0xFFFEF3C7),
          () => Navigator.push(
            context,
            CupertinoPageRoute(builder: (c) => const CT01ExportScreen()),
          ),
          imagePath: 'assets/images/features/auto_pdf_gen.png',
        ),
        ActionItem(
          'Dịch Vụ & Tiện Ích',
          CupertinoIcons.cube_box_fill,
          AppTheme.kBrand,
          const Color(0xFFE3F0FF),
          () => context.push('/owner-addons'),
          imagePath: 'assets/images/features/local_services.png',
        ),
      ],
    },
    {
      'title': 'NHÂN SỰ & TƯƠNG TÁC',
      'items': [
        ActionItem(
          'Quản lý Nhân Viên',
          CupertinoIcons.group_solid,
          const Color(0xFF4B5563),
          const Color(0xFFF3F4F6),
          () => context.push('/staff-management'),
          imagePath: 'assets/images/features/staff_dispatch.png',
        ),
        ActionItem(
          'Phân Ca & Lịch Trực',
          CupertinoIcons.calendar_badge_plus,
          AppTheme.kBrand,
          const Color(0xFFE3F0FF),
          () => context.push('/owner-shifts'),
          imagePath: 'assets/images/features/feat_booking.png',
        ),
        ActionItem(
          'Phân Quyền Truy Cập',
          CupertinoIcons.shield_fill,
          const Color(0xFF4B5563),
          const Color(0xFFF3F4F6),
          () => context.push('/permissions'),
          imagePath: 'assets/images/features/rbac.png',
        ),
        ActionItem(
          'Gửi Thông Báo',
          CupertinoIcons.bell_circle_fill,
          const Color(0xFFEC4899),
          const Color(0xFFFCE7F3),
          () => Navigator.push(
            context,
            CupertinoPageRoute(builder: (c) => const BroadcastScreen()),
          ),
          imagePath: 'assets/images/features/broadcast_msg.png',
        ),
      ],
    },
    {
      'title': 'MARKETING & TÌM KHÁCH',
      'items': [
        ActionItem(
          'Đăng Tin Cho Thuê',
          CupertinoIcons.speaker_2_fill,
          AppTheme.kWarning,
          const Color(0xFFFEF3C7),
          () => context.push('/owner/post-management'),
          imagePath: 'assets/images/features/marketing_campaign.png',
        ),
        ActionItem(
          'Mạng Lưới Môi Giới',
          CupertinoIcons.person_3_fill,
          AppTheme.kWarning,
          const Color(0xFFFEF3C7),
          () => ToastUtils.show(context, 'Tính năng này đang được phát triển'),
          imagePath: 'assets/images/features/feat_roommate.png',
        ),
        ActionItem(
          'Quản lý Đại Lý',
          CupertinoIcons.building_2_fill,
          AppTheme.kWarning,
          const Color(0xFFFEF3C7),
          () => ToastUtils.show(context, 'Tính năng này đang được phát triển'),
          imagePath: 'assets/images/features/multi_property.png',
        ),
        ActionItem(
          'Chương Trình Khuyến Mãi',
          CupertinoIcons.gift_fill,
          AppTheme.kWarning,
          const Color(0xFFFEF3C7),
          () => ToastUtils.show(context, 'Tính năng này đang được phát triển'),
          imagePath: 'assets/images/features/loyalty_rewards.png',
        ),
      ],
    },
    {
      'title': 'SMART HOME & IOT',
      'items': [
        ActionItem(
          'Quản Lý Thiết Bị IoT',
          CupertinoIcons.antenna_radiowaves_left_right,
          AppTheme.kAccentColor,
          AppTheme.kAccentColor.withValues(alpha: 0.1),
          () => Navigator.push(
            context,
            CupertinoPageRoute(builder: (c) => const IotManagementScreen()),
          ),
          imagePath: 'assets/images/features/iot_management.png',
        ),
        ActionItem(
          'Khóa Cửa Thông Minh',
          CupertinoIcons.lock_fill,
          AppTheme.kAccentColor,
          AppTheme.kAccentColor.withValues(alpha: 0.1),
          () => ToastUtils.show(context, 'Tính năng này đang được phát triển'),
          imagePath: 'assets/images/features/iot_smart_key.png',
        ),
        ActionItem(
          'Công Tơ Tự Động',
          CupertinoIcons.gauge,
          AppTheme.kAccentColor,
          AppTheme.kAccentColor.withValues(alpha: 0.1),
          () => ToastUtils.show(context, 'Tính năng này đang được phát triển'),
          imagePath: 'assets/images/features/ocr_meter.png',
        ),
        ActionItem(
          'Cổng Ra Vào Tự Động',
          CupertinoIcons.check_mark_circled_solid,
          AppTheme.kAccentColor,
          AppTheme.kAccentColor.withValues(alpha: 0.1),
          () => ToastUtils.show(context, 'Tính năng này đang được phát triển'),
          imagePath: 'assets/images/features/guest_access_code.png',
        ),
      ],
    },
  ];
}
