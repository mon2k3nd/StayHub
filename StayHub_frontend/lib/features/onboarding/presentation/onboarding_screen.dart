import 'package:flutter/physics.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../marketplace/application/location_provider.dart';
import 'package:stayhub_frontend/core/components/stayhub_logo_icon.dart';
import 'dart:async' show unawaited;

part 'onboarding_painters.dart';
part 'onboarding_ui_kit.dart';

// ════════════════════════════════
//  Data Models
// ════════════════════════════════

class _OnboardingPage {
  final String id;
  final String title;
  final String subtitle;
  final Color skyTop;
  final Color skyBottom;
  // btnColor is the CTA button background — always stays legible
  final Color btnColor;
  final Color btnText;
  final Color accent;
  final Alignment sunPos;
  final Color sunColor;
  final bool isNight;
  final IconData? icon;
  final bool isLocationPage;

  const _OnboardingPage({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.skyTop,
    required this.skyBottom,
    required this.btnColor,
    required this.btnText,
    required this.accent,
    required this.sunPos,
    required this.sunColor,
    required this.isNight,
    this.icon,
    this.isLocationPage = false,
  });
}

// ════════════════════════════════
//  OnboardingScreen
// ════════════════════════════════

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  int _currentPage = 0;
  int _prevPage = 0;
  bool _locationRequested = false;

  // ─€─€ Drag-to-peek spring state ─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€
  double _dragOffset = 0.0; // tiny spring bounce only
  double _dragVelocity = 0.0;
  static const double _maxDragUp =
      40.0; // Increased for a more satisfying jelly pull

  late final AnimationController _transitionCtrl;
  late final AnimationController _floatCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _cloudCtrl;
  late AnimationController _springCtrl; // drives spring-back
  // ignore: unused_field
  late Animation<double> _springAnim;
  late AnimationController _exitCtrl;

  late final Animation<double> _floatAnim;
  late final Animation<double> _pulseAnim;

  // Camera logic removed per new layout requirement.

  // ─€─€ Page Definitions: 6 time-of-day skies ─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€
  // dayProgress: 0.0 = dawn, 1.0 = morning, 2.0 = noon, 3.0 = sunset
  // Used by _SkyPainter to continuously interpolate the sun arc.
  static const _pages = [
    // Page 0: Bình minh (Dawn) — 5:30-6:30am
    _OnboardingPage(
      id: 'welcome',
      title: 'StayHub\nxin chào!',
      subtitle:
          'Hệ sinh thái lưu trú toàn diện: Khám phá không gian, kết nối cộng đồng, pháp lý minh bạch và làm chủ tiện ích thông minh chỉ với một ứng dụng.',
      skyTop: Color(0xFF5D9FFF), // Soft morning blue
      skyBottom: Color(0xFFFFB347), // Warm sunrise orange
      btnColor: Color(0xFFE8521A),
      btnText: Color(0xFFFFFFFF),
      accent: Color(0xFFFF8C42),
      sunPos: Alignment(-0.78, 0.55),
      sunColor: Color(0xFFFF8C42),
      isNight: false,
      icon: CupertinoIcons.home,
    ),
    // Page 1: Sáng sớm (Morning) — 8:00-9:00am
    _OnboardingPage(
      id: 'location',
      title: 'Phòng trọ\ngần bạn nhất',
      subtitle:
          'Định vị nhanh chóng hàng ngàn phòng trọ xung quanh bạn. Tính toán thông minh khoảng cách di chuyển đến trường và chỗ làm, giúp bạn tối ưu quỹ thời gian mỗi ngày.',
      skyTop: Color(0xFF0B3D91), // Deep clear blue
      skyBottom: Color(0xFF5FAEFF), // Light sky blue horizon
      btnColor: Color(0xFF1A6FD4),
      btnText: Color(0xFFFFFFFF),
      accent: Color(0xFF1A6FD4),
      sunPos: Alignment(-0.25, -0.35),
      sunColor: Color(0xFFFFE566),
      isNight: false,
      isLocationPage: true,
    ),
    // Page 2: Trưa (High Noon) — 11:30am-1:00pm
    _OnboardingPage(
      id: 'finance',
      title: 'Thanh toán\nhóa đơn',
      subtitle:
          'Thanh toán tiền phòng và tiện ích nhanh chóng, an toàn và minh bạch tuyệt đối. Trải nghiệm tính năng thống kê thông minh giúp bạn chủ động quản lý chi tiêu.',
      skyTop: Color(0xFF005FA3), // Intense midday blue
      skyBottom: Color(0xFF5FAEFF), // Pale horizon
      btnColor: Color(0xFF1A6FD4),
      btnText: Color(0xFFFFFFFF),
      accent: Color(0xFF1A6FD4),
      sunPos: Alignment(0.05, -0.82),
      sunColor: Color(0xFFFFF9C4),
      isNight: false,
      icon: CupertinoIcons.chart_pie_fill,
    ),
    // Page 3: Hoàng hôn (Sunset) — 5:30-6:30pm
    _OnboardingPage(
      id: 'security',
      title: 'Hợp đồng\nđiện tử & eKYC',
      subtitle:
          'Xác minh danh tính và ký hợp đồng 100% trực tuyến. Tính pháp lý minh bạch, bảo mật tuyệt đối – Đặt trọn quyền lợi trong tầm tay bạn.',
      skyTop: Color(0xFF7E30E1), // Very vibrant electric purple
      skyBottom: Color(0xFFFF5E3A), // Extremely bright glowing sunset orange
      btnColor: Color(0xFFEA580C),
      btnText: Color(0xFFFFFFFF),
      accent: Color(0xFFEA580C),
      sunPos: Alignment(0.75, 0.42),
      sunColor: Color(0xFFFF6B35),
      isNight: false,
      icon: CupertinoIcons.shield_lefthalf_fill,
    ),
    // Page 4: Tối (Night) — Moon top-left
    _OnboardingPage(
      id: 'community',
      title: 'Ghép Phòng\nkết nối bạn ở',
      subtitle:
          'Tìm người ở ghép phù hợp nhất bằng thuật toán thông minh, dựa trên các tiêu chí của bạn yêu cầu. Bạn cần trọ, tôi có phòng.',
      skyTop: Color(0xFF0A0E1A),
      skyBottom: Color(0xFF1A2744),
      btnColor: Color(0xFF5FAEFF),
      btnText: Color(0xFF0F172A),
      accent: Color(0xFF5FAEFF),
      sunPos: Alignment(-0.68, -0.72),
      sunColor: Color(0xFFE2E8F0),
      isNight: true,
      icon: CupertinoIcons.heart_fill,
    ),
    // Page 5: Khuya (Late Night) — Full moon top-right
    _OnboardingPage(
      id: 'smarthome',
      title: 'Nhà thông minh\nSmart IoT',
      subtitle:
          'Tự động hóa toàn diện không gian sống từ hệ thống camera an ninh, chiếu sáng đến giải trí qua nền tảng từ xa. Chào mừng đến với không gian sống vươn tầm!',
      skyTop: Color(0xFF010409),
      skyBottom: Color(0xFF070D26),
      btnColor: Color(0xFF298FFF),
      btnText: Color(0xFFFFFFFF),
      accent: Color(0xFF298FFF),
      sunPos: Alignment(0.68, -0.72),
      sunColor: Color(0xFFFFFFFF),
      isNight: true,
      icon: CupertinoIcons.lock_shield_fill,
    ),
  ];

  double _cumulativeCloudTime = 0.0;
  double _cumulativeWaveTime = 0.0;
  double _lastCloudV = 0.0;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
    unawaited(_floatCtrl.repeat(reverse: true));
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    unawaited(_pulseCtrl.repeat(reverse: true));

    _cloudCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    unawaited(_cloudCtrl.repeat());
    _cloudCtrl.addListener(() {
      double delta = _cloudCtrl.value - _lastCloudV;
      if (delta < -0.5) delta += 1.0; // handle wrap around from 1.0 back to 0.0

      _cumulativeWaveTime += delta;

      // Speed up clouds heavily during transition to simulate time passing quickly!
      if (_transitionCtrl.isAnimating) {
        delta *= 25.0;
      }
      if (_exitCtrl.isAnimating) {
        delta *= 50.0;
      }

      _cumulativeCloudTime += delta;
      _lastCloudV = _cloudCtrl.value;
      setState(() {}); // Rebuild every cloud frame so motion is continuous
    });

    _floatAnim = Tween<double>(
      begin: -8,
      end: 8,
    ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));
    _pulseAnim = Tween<double>(
      begin: 0.96,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _transitionCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _transitionCtrl.addListener(() => setState(() {}));
    _transitionCtrl.value = 1.0;

    // Spring controller for card drag-back
    _springCtrl = AnimationController.unbounded(vsync: this);
    _springAnim = _springCtrl;
    _springCtrl.addListener(
      () => setState(() {
        _dragOffset = _springCtrl.value;
      }),
    );

    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _exitCtrl.addListener(() => setState(() {}));
  }

  void _navigate(int to) {
    if (_transitionCtrl.isAnimating) return;
    _prevPage = _currentPage;
    _currentPage = to;
    unawaited(_transitionCtrl.forward(from: 0.0));
    unawaited(HapticFeedback.lightImpact());
  }

  void _goNext() {
    if (_currentPage < _pages.length - 1) {
      _navigate(_currentPage + 1);
    } else {
      unawaited(_finish());
    }
  }

  void _goBack() {
    if (_currentPage > 0) _navigate(_currentPage - 1);
  }

  Future<void> _requestLocationAndNext() async {
    if (!_locationRequested) {
      _locationRequested = true;
      unawaited(HapticFeedback.mediumImpact());
      unawaited(ref.read(locationProvider.notifier).requestPermission());
    }
    _goNext();
  }

  Future<void> _finish() async {
    if (_exitCtrl.isAnimating) return;
    unawaited(HapticFeedback.mediumImpact());
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTime', false);
    await _exitCtrl.forward();
    if (mounted) context.go('/login');
  }

  void _startSpringBack() {
    const spring = SpringDescription(mass: 1, stiffness: 300, damping: 22);
    final sim = SpringSimulation(spring, _dragOffset, 0.0, -_dragVelocity);
    unawaited(_springCtrl.animateWith(sim));
  }

  @override
  void dispose() {
    _transitionCtrl.dispose();
    _floatCtrl.dispose();
    _pulseCtrl.dispose();
    _cloudCtrl.dispose();
    _springCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  // ─€─€ Build ─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPad = MediaQuery.of(context).padding.top;
    final botPad = MediaQuery.of(context).padding.bottom;

    // Camera panning variables removed.

    final double t = Curves.easeInOutCubic.transform(_transitionCtrl.value);
    final int vFrom = _prevPage.clamp(0, _pages.length - 1);
    final int vTo = _currentPage.clamp(0, _pages.length - 1);

    return CupertinoPageScaffold(
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // ─€─€ Background: Sky fills entire screen ─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _transitionCtrl,
                _pulseCtrl,
                _cloudCtrl,
                _springCtrl,
              ]),
              builder: (_, __) {
                final liveT = Curves.easeInOutCubic.transform(
                  _transitionCtrl.value,
                );
                final liveFrom = _prevPage.clamp(0, _pages.length - 1);
                final liveTo = _currentPage.clamp(0, _pages.length - 1);
                return Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateX(_dragOffset * 0.0003),
                  alignment: Alignment.center,
                  child: CustomPaint(
                    painter: _SkyPainter(
                      pages: _pages,
                      from: liveFrom,
                      to: liveTo,
                      t: liveT,
                      pulseT: _pulseCtrl.value,
                      cloudT: _cumulativeCloudTime,
                      exitT: _exitCtrl.value,
                    ),
                  ),
                );
              },
            ),
          ),

          // ─€─€ Main Layout Column ─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€
          Column(
            children: [
              // ─€ TOP: Sky shrinks so wave card is taller ─€
              SizedBox(height: size.height * 0.25),

              // ─€─€ Draggable bottom card with spring-back ─€─€
              GestureDetector(
                onVerticalDragUpdate: (d) {
                  setState(() {
                    final oldOffset = _dragOffset;
                    _dragOffset = (_dragOffset - d.delta.dy).clamp(
                      0.0,
                      _maxDragUp,
                    );
                    // Add subtle haptic feedback when pulling against the boundary
                    if (oldOffset != _dragOffset && _dragOffset == _maxDragUp) {
                      unawaited(HapticFeedback.lightImpact());
                    }
                  });
                },
                onVerticalDragEnd: (d) {
                  _dragVelocity = d.primaryVelocity ?? 0;
                  _startSpringBack();
                },
                child: SizedBox(
                  width: size.width,
                  height: size.height * 0.75,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Compute the sink offset for the "draining water" effect
                      Builder(
                        builder: (context) {
                          double waveSink = 0.0;
                          if (_transitionCtrl.isAnimating && vFrom != vTo) {
                            // Parabolic sink: very large for diagnostic
                            waveSink =
                                math.sin(t * math.pi) * size.height * 0.22;
                          }
                          if (_exitCtrl.value > 0) {
                            waveSink += _exitCtrl.value * size.height * 0.8;
                          }
                          return Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.bottomCenter,
                            children: [
                              // ─€─€ 1. Wave Background (Static position, morphing shape, sinks during transition) ─€─€
                              _buildWaveBackground(
                                botPad,
                                vFrom + (vTo - vFrom) * t,
                                _dragOffset,
                                waveSink,
                              ),

                              // ─€─€ 2. Text Content (Sinks with water, clipped above footer) ─€─€
                              // ─€─€ 2. Text Content (Sinks with water, clipped above footer) ─€─€
                              ClipRect(
                                clipper: _FooterAvoidanceClipper(botPad + 80),
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: [
                                    // Old text sinks with water and fades out
                                    if (_transitionCtrl.isAnimating &&
                                        vFrom != vTo)
                                      Transform.translate(
                                        offset: Offset(
                                          0,
                                          size.height * t + waveSink,
                                        ),
                                        child: Opacity(
                                          opacity: (1.0 - t * 3.0).clamp(
                                            0.0,
                                            1.0,
                                          ),
                                          child: _buildTextContent(
                                            vFrom,
                                            botPad,
                                            size,
                                          ),
                                        ),
                                      ),
                                    // New text rises with water and fades in
                                    Transform.translate(
                                      offset: Offset(
                                        0,
                                        size.height * (1.0 - t) + waveSink,
                                      ),
                                      child: Opacity(
                                        opacity: ((t - 0.5) * 2.5).clamp(
                                          0.0,
                                          1.0,
                                        ),
                                        child: _buildTextContent(
                                          vTo,
                                          botPad,
                                          size,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // ─€─€ 2.5. Floating Illustrations (completely above text, native sizing) ─€─€
                              if (_transitionCtrl.isAnimating && vFrom != vTo)
                                _buildIllustrationLayer(
                                  vFrom,
                                  size,
                                  opacity: (1.0 - t * 3.0).clamp(0.0, 1.0),
                                  offsetY: waveSink,
                                ),
                              _buildIllustrationLayer(
                                vTo,
                                size,
                                opacity: ((t - 0.5) * 2.5).clamp(0.0, 1.0),
                                offsetY: waveSink,
                              ),

                              // ─€─€ 3. Footer Buttons and Dots (Static, does not slide or fade) ─€─€
                              _buildFooter(botPad),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ─€─€ Overlay: Top Header ─€─€─€─€─€─€─€─€─€
          Positioned(
            top: topPad + 12,
            left: 20,
            right: 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                StayHubLogoIcon(
                  size: 26,
                  useWhite: true,
                  color: CupertinoColors.white.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Text(
                    'STAYHUB',
                    style: TextStyle(
                      color: CupertinoColors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                      height: 1.0,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─€─€ 1. Wave Background (Static position, morphing shape) ─€─€
  Widget _buildWaveBackground(
    double botPad,
    double floatPage,
    double dragOffset,
    double waveSink,
  ) {
    final isDark = _pages[_currentPage]
        .isNight; // Use current page for general coloring, or interpolate if needed

    return Positioned(
      top: -15, // Kéo lên một chút xíu (khoảng giữa)
      left: 0,
      right: 0,
      bottom: 0,
      child: Transform.translate(
        offset: Offset(0, waveSink),
        child: AnimatedBuilder(
          animation: _cloudCtrl,
          builder: (context, child) {
            final double time = _cumulativeWaveTime * math.pi * 2;
            return ClipPath(
              clipper: _WaveClipper(floatPage, time, dragOffset),
              child: CustomPaint(
                painter: _WaveBorderPainter(
                  floatPage,
                  time,
                  isDark
                      ? CupertinoColors.white.withValues(alpha: 0.25)
                      : const Color(0xFF94A3B8).withValues(alpha: 0.35),
                  dragOffset,
                ),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0B1728)
                        : const Color(0xFFF5F8FC),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -80,
                        top: 130,
                        child: Opacity(
                          opacity: isDark ? 0.03 : 0.04,
                          child: Transform.rotate(
                            angle: -math.pi / 12,
                            child: StayHubLogoIcon(
                              size: 260,
                              color: _pages[_currentPage].accent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIllustrationLayer(
    int idx,
    Size size, {
    required double opacity,
    required double offsetY,
    double offsetX = 0.0,
  }) {
    final page = _pages[idx];
    return Positioned(
      right: 10, // Bring it inside the screen so nothing gets cut off
      top:
          -110, // Kéo toàn bộ container ảnh lên cao để không bao giờ đè vào chữ
      child: Transform.translate(
        offset: Offset(offsetX, offsetY),
        child: Opacity(
          opacity: opacity,
          child: AnimatedBuilder(
            animation: _floatAnim,
            builder: (_, child) => Transform.translate(
              offset: Offset(0, _floatAnim.value * 0.8),
              child: child,
            ),
            child: IgnorePointer(
              child: SizedBox(
                width: size.width * 0.48, // Made smaller
                height: size.height * 0.32, // Made smaller
                child: FittedBox(
                  fit: BoxFit.contain,
                  alignment: Alignment.centerRight,
                  child: _buildIllus(idx, page.accent, size),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextContent(int idx, double botPad, Size screenSize) {
    final page = _pages[idx];
    final isDark = page.isNight;
    final textColor = isDark ? CupertinoColors.white : const Color(0xFF0F172A);
    final subtextColor = isDark
        ? CupertinoColors.white.withValues(alpha: 0.72)
        : const Color(0xFF475569);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 100, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            page.title,
            style: TextStyle(
              color: textColor,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            page.subtitle,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: subtextColor, fontSize: 12, height: 1.55),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: _buildFeatureTags(idx, page, textColor)
                  .map(
                    (w) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: w,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ─€─€ 3. Footer (Static position, contains Buttons and Dots) ─€─€
  Widget _buildFooter(double botPad) {
    final page = _pages[_currentPage];
    final isLast = _currentPage == _pages.length - 1;
    final isDark = page.isNight;
    final textColor = isDark ? CupertinoColors.white : const Color(0xFF0F172A);

    return Positioned(
      left: 28,
      right: 28,
      bottom: botPad + 32,
      child: SizedBox(
        height: 50,
        child: Row(
          children: [
            // Logo or Back Button
            SizedBox(
              width: 50,
              child: _currentPage == 0
                  ? StayHubLogoIcon(
                      size: 32,
                      color: _pages[_currentPage].btnColor,
                    )
                  : GestureDetector(
                      onTap: _goBack,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? const Color(0xFF1E293B)
                              : CupertinoColors.white,
                          border: Border.all(
                            color: CupertinoColors.systemGrey4.withValues(
                              alpha: isDark ? 0.2 : 0.6,
                            ),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF000000,
                              ).withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          CupertinoIcons.back,
                          color: textColor,
                          size: 18,
                        ),
                      ),
                    ),
            ),

            const SizedBox(width: 12),

            // Dots (Aligned to left)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_pages.length, (i) {
                final isActive = _currentPage == i;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutExpo,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: isActive
                        ? page.btnColor
                        : (isDark
                              ? CupertinoColors.white.withValues(alpha: 0.2)
                              : CupertinoColors.systemGrey4),
                  ),
                );
              }),
            ),

            const Spacer(),

            // Next button
            _CTAButton(
              text: isLast
                  ? 'Vào Ứng Dụng'
                  : page.isLocationPage && !_locationRequested
                  ? 'Bật Vị Trí'
                  : 'Tiếp theo',
              icon: isLast
                  ? CupertinoIcons.checkmark_alt
                  : CupertinoIcons.arrow_right,
              color: page.btnColor,
              textColor: page.btnText,
              pulseScale: isLast ? _pulseAnim.value : 1.0,
              onTap: () {
                if (page.isLocationPage && !_locationRequested) {
                  unawaited(_requestLocationAndNext());
                } else {
                  _goNext();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─€─€ Illustration Dispatcher ─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€

  // ─€─€ Feature tag helpers ─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€
  static const _pageFeatures = [
    // Page 0: Welcome
    [
      (icon: CupertinoIcons.building_2_fill, label: 'Tìm phòng'),
      (icon: CupertinoIcons.person_2_fill, label: 'Ghép phòng'),
      (icon: CupertinoIcons.chat_bubble_2_fill, label: 'Nhắn tin'),
    ],
    // Page 1: Location
    [
      (icon: CupertinoIcons.location_fill, label: 'Vị trí'),
      (icon: CupertinoIcons.map_fill, label: 'Bản đồ'),
      (icon: CupertinoIcons.slider_horizontal_3, label: 'Bộ lọc'),
    ],
    // Page 2: Finance
    [
      (icon: CupertinoIcons.money_dollar_circle_fill, label: 'Thanh toán'),
      (icon: CupertinoIcons.doc_text_fill, label: 'Hóa đơn'),
      (icon: CupertinoIcons.chart_bar_alt_fill, label: 'Chi tiêu'),
    ],
    // Page 3: Security
    [
      (icon: CupertinoIcons.shield_fill, label: 'Bảo mật'),
      (icon: CupertinoIcons.person_crop_circle_badge_checkmark, label: 'eKYC'),
      (icon: CupertinoIcons.doc_checkmark_fill, label: 'Hợp đồng'),
    ],
    // Page 4: Community
    [
      (icon: CupertinoIcons.heart_fill, label: 'Ghép đôi'),
      (icon: CupertinoIcons.star_fill, label: 'Đánh giá'),
      (icon: CupertinoIcons.hand_thumbsup_fill, label: 'Kết bạn'),
    ],
    // Page 5: SmartHome
    [
      (icon: CupertinoIcons.lock_open_fill, label: 'Mở khóa'),
      (icon: CupertinoIcons.wifi, label: 'Wi-Fi'),
      (icon: CupertinoIcons.lightbulb_fill, label: 'Äiều khiển'),
    ],
  ];

  List<Widget> _buildFeatureTags(
    int idx,
    _OnboardingPage page,
    Color textColor,
  ) {
    final features = _pageFeatures[idx.clamp(0, _pageFeatures.length - 1)];
    return features
        .map(
          (f) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: page.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: page.accent.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(f.icon, size: 11, color: page.accent),
                const SizedBox(width: 4),
                Text(
                  f.label,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  Widget _buildIllus(int index, Color accent, Size size) {
    switch (index) {
      case 0:
        return _buildWelcomeIllustration(accent, size);
      case 1:
        return _buildRadarMapIllustration(accent, size);
      case 2:
        return _buildFinanceIllustration(accent, size);
      case 3:
        return _buildSecurityIllustration(accent, size);
      case 4:
        return _buildCommunityIllustration(accent, size);
      case 5:
        return _buildSmartHomeIllustration(accent, size);
      default:
        return const SizedBox();
    }
  }

  // Page 0: Welcome — 3D Floating Isometric Houses
  Widget _buildWelcomeIllustration(Color accent, Size size) {
    final s = math.min(size.width, size.height);
    return AnimatedBuilder(
      animation: Listenable.merge([_floatCtrl, _pulseCtrl]),
      builder: (_, __) {
        final float = _floatAnim.value;
        final pulse = _pulseAnim.value;
        return SizedBox(
          width: s,
          height: s,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.hardEdge,
            children: [
              // Ambient glow
              Container(
                width: s * 0.7,
                height: s * 0.7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.25),
                      blurRadius: 80,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
              // Isometric building
              Positioned(
                bottom: s * 0.15 + float,
                child: Transform(
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.002)
                    ..rotateX(-0.4)
                    ..rotateY(0.4),
                  alignment: Alignment.center,
                  child: Container(
                    width: s * 0.55,
                    height: s * 0.70,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          CupertinoColors.white.withValues(alpha: 0.9),
                          CupertinoColors.white.withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: CupertinoColors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF000000,
                          ).withValues(alpha: 0.15),
                          blurRadius: 30,
                          offset: const Offset(8, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        3,
                        (i) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(
                            2,
                            (j) => Container(
                              width: s * 0.14,
                              height: s * 0.14,
                              decoration: BoxDecoration(
                                color: accent.withValues(
                                  alpha: 0.2 + (i * 0.1),
                                ),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.5),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                CupertinoIcons.bed_double_fill,
                                color: accent,
                                size: s * 0.07,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Badge: Cao cấp
              Positioned(
                bottom: s * 0.62 - float * 1.5,
                left: s * 0.02,
                child: Transform.scale(
                  scale: pulse,
                  child: _buildGlassBadge(
                    CupertinoIcons.star_fill,
                    'Cao cấp',
                    accent,
                  ),
                ),
              ),
              // Badge: An toàn
              Positioned(
                bottom: s * 0.20 + float * 2,
                right: s * 0.02,
                child: Transform.scale(
                  scale: 2.0 - pulse,
                  child: _buildGlassBadge(
                    CupertinoIcons.shield_fill,
                    'An toàn',
                    const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGlassBadge(
    IconData icon,
    String text,
    Color accent, {
    bool isDark = false,
  }) => _OnboardingUiKit.glassBadge(icon, text, accent, isDark: isDark);

  // Page 1: Fast Match — High-Speed Distance Search ─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€
  Widget _buildRadarMapIllustration(Color accent, Size size) {
    final w = size.width;
    final h = size.height * 0.68;

    final cards = [
      (
        title: 'Chung cư mini Q7',
        dist: '5.2 km',
        scale: 0.65,
        dx: -90.0,
        dy: 20.0,
        angle: -0.15,
        floatFactor: -0.6,
        isBest: false,
      ),
      (
        title: 'Nhà nguyên căn Q3',
        dist: '3.8 km',
        scale: 0.75,
        dx: 70.0,
        dy: 10.0,
        angle: 0.22,
        floatFactor: 0.8,
        isBest: false,
      ),
      (
        title: 'Phòng trọ Gò Vấp',
        dist: '2.4 km',
        scale: 0.85,
        dx: -50.0,
        dy: 90.0,
        angle: -0.08,
        floatFactor: 0.5,
        isBest: false,
      ),
      (
        title: 'Studio Q1 Cao cấp',
        dist: '150 m',
        scale: 1.15,
        dx: 40.0,
        dy: 80.0,
        angle: 0.05,
        floatFactor: 1.2,
        isBest: true,
      ),
    ];

    return SizedBox(
      width: w,
      height: h,
      child: Align(
        alignment: Alignment.center,
        child: AnimatedBuilder(
          animation: Listenable.merge([_floatCtrl, _pulseCtrl]),
          builder: (_, __) {
            final float = _floatAnim.value;
            final pulse = _pulseAnim.value;

            final cx = w / 2;
            final cy = h / 2 + 10;

            return Stack(
              clipBehavior: Clip.none,
              children: cards.map((c) {
                return Positioned(
                  left:
                      cx -
                      (c.isBest ? 80 : 75) +
                      c.dx, // 80 is half of 160, 75 is half of 150
                  top:
                      cy -
                      (c.isBest ? 75 : 65) +
                      c.dy +
                      (float * c.floatFactor),
                  child: Transform.scale(
                    scale: c.scale,
                    child: Transform.rotate(
                      angle: c.angle,
                      child: Opacity(
                        opacity: c.isBest ? 1.0 : 0.8,
                        child: _buildDistanceCard(
                          c.title,
                          c.dist,
                          c.isBest,
                          pulse,
                          accent,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDistanceCard(
    String title,
    String dist,
    bool isBest,
    double pulse,
    Color accent,
  ) => _OnboardingUiKit.distanceCard(title, dist, isBest, pulse, accent);

  // Page 2: Finance — multiple invoice cards floating
  Widget _buildFinanceIllustration(Color accent, Size size) {
    final s = size.width * 0.55;

    return SizedBox(
      width: s,
      height: s * 1.4, // Taller to fit all cards
      child: AnimatedBuilder(
        animation: _floatCtrl,
        builder: (_, __) {
          final wave = _floatAnim.value / 8.0;
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Invoice card 1 — Tiền phòng (back, left)
              Positioned(
                top: s * 0.2 + 50 + wave * -10,
                left: -30.0,
                child: Transform.rotate(
                  angle: -0.15,
                  child: _invoiceCard(
                    w: s * 0.75,
                    icon: CupertinoIcons.house_fill,
                    label: 'Tiền phòng tháng 8',
                    amount: '4.200.000 ₫',
                    status: 'Đã thanh toán',
                    paid: true,
                    offset: 0,
                    accent: accent,
                  ),
                ),
              ),
              // Invoice card 2 — Äiện (middle, right)
              Positioned(
                top: s * 0.25 + 60 + wave * 5,
                left: s * 0.45,
                child: Transform.rotate(
                  angle: 0.18,
                  child: _invoiceCard(
                    w: s * 0.75,
                    icon: CupertinoIcons.bolt_fill,
                    label: 'Hóa đơn điện tháng 8',
                    amount: '320.000 ₫',
                    status: 'Đã thanh toán',
                    paid: true,
                    offset: 1,
                    accent: accent,
                  ),
                ),
              ),
              // Invoice card 3 — Nước (front, center)
              Positioned(
                top: s * 0.4 + 80 + wave * 15,
                left: s * 0.1,
                child: Transform.rotate(
                  angle: -0.05,
                  child: _invoiceCard(
                    w: s * 0.82, // slightly larger to look closer
                    icon: CupertinoIcons.drop_fill,
                    label: 'Hóa đơn nước tháng 8',
                    amount: '85.000 ₫',
                    status: 'Chưa thanh toán',
                    paid: false,
                    offset: 2,
                    accent: accent,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _invoiceCard({
    required double w,
    required IconData icon,
    required String label,
    required String amount,
    required String status,
    required bool paid,
    required int offset,
    required Color accent,
  }) {
    final statusColor = paid
        ? const Color(0xFF10B981)
        : const Color(0xFFFF4F5E);
    return _InteractiveElement(
      child: Container(
        width: w,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC), // Off-white paper color
          borderRadius: BorderRadius.circular(6), // Sharp edges for paper
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        amount,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Dashed separator line
            Row(
              children: List.generate(
                20,
                (index) => Expanded(
                  child: Container(
                    height: 1,
                    color: index % 2 == 0
                        ? const Color(0xFFCBD5E1)
                        : const Color(0x00000000),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Fake barcode lines
                Row(
                  children: List.generate(
                    6,
                    (i) => Container(
                      margin: const EdgeInsets.only(right: 3),
                      width: i % 2 == 0 ? 3 : 1.5,
                      height: 16,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // _bar and _animatedBar removed — Finance page now uses invoice cards

  // Page 3: Security ─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€
  Widget _buildSecurityIllustration(Color accent, Size size) {
    final s = size.width * 0.70; // Thu nhỏ đi 1 xíu theo yêu cầu
    return SizedBox(
      width: s,
      height: s * 0.72,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseCtrl, _floatCtrl, _cloudCtrl]),
        builder: (_, __) {
          final pulse = _pulseAnim.value;
          final float = _floatAnim.value;
          final scanY = (_cloudCtrl.value * s * 0.52) % (s * 0.52);
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // ─€─€ Main ID Card ─€─€
              Transform.translate(
                offset: Offset(0, float * 1.5),
                child: Container(
                  width: s,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1A0A2E),
                        accent.withValues(alpha: 0.85),
                        const Color(0xFF1A0A2E),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    border: Border.all(
                      color: CupertinoColors.white.withValues(
                        alpha: 0.18 + pulse * 0.07,
                      ),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.40 + pulse * 0.15),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: accent.withValues(alpha: 0.12),
                        blurRadius: 60,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row
                      Row(
                        children: [
                          const StayHubLogoIcon(
                            useWhite: true,
                            size: 18,
                            color: CupertinoColors.white,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'STAYHUB  ID',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.5,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF10B981),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.8 + pulse * 0.2),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'VERIFIED',
                                  style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Photo + Info row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Photo box with scan line
                          Stack(
                            children: [
                              Container(
                                width: 58,
                                height: 68,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      accent.withValues(alpha: 0.5),
                                      accent.withValues(alpha: 0.2),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: CupertinoColors.white.withValues(
                                      alpha: 0.2,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(11),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Icon(
                                        CupertinoIcons.person_fill,
                                        color: CupertinoColors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                        size: 38,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Animated scan line
                              Positioned(
                                left: 0,
                                right: 0,
                                top: scanY.clamp(0.0, 58.0),
                                child: Container(
                                  height: 1.5,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(
                                          0xFF10B981,
                                        ).withValues(alpha: 0),
                                        const Color(
                                          0xFF10B981,
                                        ).withValues(alpha: 0.85),
                                        const Color(
                                          0xFF10B981,
                                        ).withValues(alpha: 0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nguyễn Văn A',
                                  style: TextStyle(
                                    color: CupertinoColors.white.withValues(
                                      alpha: 0.95,
                                    ),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'ID: SH-2024-’¢’¢’¢’¢',
                                  style: TextStyle(
                                    color: CupertinoColors.white.withValues(
                                      alpha: 0.45,
                                    ),
                                    fontSize: 9.5,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _idRow('Ngày sinh', '01/01/1999'),
                                const SizedBox(height: 5),
                                _idRow('Quốc tịch', 'Việt Nam'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        height: 0.5,
                        color: CupertinoColors.white.withValues(alpha: 0.12),
                      ),
                      const SizedBox(height: 12),
                      // Bottom: QR + fingerprint + barcode
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(38, 38),
                            painter: _MiniQRPainter(),
                          ),
                          Icon(
                            CupertinoIcons.hand_draw_fill,
                            color: accent.withValues(alpha: 0.6 + pulse * 0.4),
                            size: 30,
                          ),
                          Column(
                            children: [
                              Row(
                                children: List.generate(
                                  14,
                                  (i) => Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 0.8,
                                    ),
                                    width: i % 3 == 0 ? 2.5 : 1.2,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.white.withValues(
                                        alpha: 0.18 + (i % 4) * 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'SH-2024',
                                style: TextStyle(
                                  color: CupertinoColors.white.withValues(
                                    alpha: 0.3,
                                  ),
                                  fontSize: 7,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // ─€─€ Floating lock badge ─€─€
              Positioned(
                top: -14,
                right: -4,
                child: Transform.translate(
                  offset: Offset(0, float * 1.5),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0F172A),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.6 + pulse * 0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.45),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: Icon(
                      CupertinoIcons.lock_shield_fill,
                      color: accent,
                      size: 18,
                    ),
                  ),
                ),
              ),
              // ─€─€ Floating eKYC badge ─€─€
              Positioned(
                bottom: -14,
                left: 8,
                child: Transform.translate(
                  offset: Offset(0, float * -1.8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.7),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.checkmark_shield_fill,
                          color: Color(0xFF10B981),
                          size: 14,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'eKYC Verified',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _idRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: CupertinoColors.white.withValues(alpha: 0.4),
            fontSize: 9,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            color: CupertinoColors.white.withValues(alpha: 0.85),
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Page 4: Community ─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€
  Widget _buildCommunityIllustration(Color accent, Size size) {
    final s = size.width * 0.78;
    // Changed from rooms to roommate profiles
    final profiles = [
      (
        name: 'Trần Vũ',
        info: 'Nam, 24t ’¢ Kỹ sư IT',
        tag: 'Tìm ghép Q1',
        match: 98,
        bio: 'Gọn gàng, đi làm cả ngày, ít nhậu nhẹt',
        lookingFor: 'Phòng sạch sẽ, giá < 3tr, giờ tự do',
        color: const Color(0xFF1E3A5F),
        tagColor: const Color(0xFF5FAEFF),
        icon: CupertinoIcons.person_solid,
      ),
      (
        name: 'Minh Thư',
        info: 'Nữ, 21t ’¢ Sinh viên',
        tag: 'Tìm bạn nữ',
        match: 85,
        bio: 'Vui vẻ, thích nấu ăn, hay ở nhà',
        lookingFor: 'Share phòng Master chung cư an ninh',
        color: const Color(0xFF2E1A44),
        tagColor: const Color(0xFFA78BFA),
        icon: CupertinoIcons.person_solid,
      ),
      (
        name: 'Hoàng Long',
        info: 'Nam, 27t ’¢ Văn phòng',
        tag: 'Có sẵn phòng',
        match: 72,
        bio: 'Hòa đồng, thích thể thao, có đồ sẵn',
        lookingFor: 'Cần 1 bạn share phòng giá 2.5tr',
        color: const Color(0xFF0F172A),
        tagColor: const Color(0xFF10B981),
        icon: CupertinoIcons.person_solid,
      ),
    ];

    return SizedBox(
      width: s,
      height: s * 1.05,
      child: AnimatedBuilder(
        animation: Listenable.merge([_floatCtrl, _pulseCtrl]),
        builder: (_, __) {
          final float = _floatAnim.value;
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Card 3 (back, left)
              Positioned(
                top: 30 + float * -0.5,
                left: -20,
                child: Transform.rotate(
                  angle: -0.15,
                  child: _richProfileCard(
                    profiles[2],
                    s * 0.82,
                    accent,
                    offset: 2,
                  ),
                ),
              ),
              // Card 2 (middle, right)
              Positioned(
                top: 45 + float * 0.5,
                left: s * 0.3,
                child: Transform.rotate(
                  angle: 0.15,
                  child: _richProfileCard(
                    profiles[1],
                    s * 0.88,
                    accent,
                    offset: 1,
                  ),
                ),
              ),
              // Card 1 (front, center)
              Positioned(
                top: 60 + float * 1.5,
                left: s * 0.05,
                child: Transform.rotate(
                  angle: -0.02,
                  child: _richProfileCard(
                    profiles[0],
                    s * 0.94,
                    accent,
                    offset: 0,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _richProfileCard(
    ({
      String name,
      String info,
      String tag,
      int match,
      String bio,
      String lookingFor,
      Color color,
      Color tagColor,
      IconData icon,
    })
    profile,
    double w,
    Color accent, {
    required int offset,
  }) {
    return Container(
      width: w,
      decoration: BoxDecoration(
        color: profile.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: CupertinoColors.white.withValues(alpha: 0.10 - offset * 0.02),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF000000,
            ).withValues(alpha: 0.35 + offset * 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile image area (abstract gradient with icon)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Container(
              height: w * 0.32, // Thu nhỏ phần avatar lại vì không có ảnh thật
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    profile.tagColor.withValues(alpha: 0.15),
                    profile.color,
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Abstract circles pattern
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: profile.tagColor.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -30,
                    bottom: 0,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: profile.tagColor.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  // Avatar icon centered
                  Center(
                    child: Container(
                      width: w * 0.18,
                      height: w * 0.18, // Vòng tròn avatar nhỏ lại
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: profile.tagColor.withValues(alpha: 0.2),
                        border: Border.all(
                          color: profile.tagColor.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: profile.tagColor.withValues(alpha: 0.2),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        profile.icon,
                        size: w * 0.10, // Icon nhỏ lại
                        color: profile.tagColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  // Tag
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: profile.tagColor.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: profile.tagColor.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        profile.tag,
                        style: TextStyle(
                          color: profile.tagColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  // Match %
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF000000).withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.5),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.sparkles,
                            color: Color(0xFF10B981),
                            size: 10,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '${profile.match}% Hợp',
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      profile.name,
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      color: Color(0xFF5FAEFF),
                      size: 16,
                    ), // verified tick
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  profile.info,
                  style: TextStyle(
                    color: CupertinoColors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                // Divider
                Container(
                  height: 1,
                  color: CupertinoColors.white.withValues(alpha: 0.1),
                ),
                const SizedBox(height: 10),
                // Who they are
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      CupertinoIcons.person_crop_circle,
                      color: profile.tagColor.withValues(alpha: 0.8),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        profile.bio,
                        style: TextStyle(
                          color: CupertinoColors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // What they are looking for
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      CupertinoIcons.search_circle,
                      color: profile.tagColor.withValues(alpha: 0.8),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        profile.lookingFor,
                        style: TextStyle(
                          color: CupertinoColors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _actionBtn(IconData icon, Color color, double pulse) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
        border: Border.all(
          color: color.withValues(alpha: 0.5 + pulse * 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25 + pulse * 0.1),
            blurRadius: 12,
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  // Page 5: Smart Home ─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€
  Widget _buildSmartHomeIllustration(Color accent, Size size) {
    final s = size.width * 0.80;

    final devices = [
      (
        icon: CupertinoIcons.lightbulb_fill,
        label: 'Đèn',
        color: const Color(0xFFFBBF24),
        on: true,
      ),
      (
        icon: CupertinoIcons.thermometer,
        label: 'Nhiệt độ',
        color: const Color(0xFFFF6B6B),
        on: true,
      ),
      (
        icon: CupertinoIcons.wifi,
        label: 'Wi-Fi',
        color: const Color(0xFF5FAEFF),
        on: true,
      ),
      (
        icon: CupertinoIcons.lock_shield_fill,
        label: 'An ninh',
        color: const Color(0xFF34D399),
        on: true,
      ),
      (
        icon: CupertinoIcons.wind,
        label: 'Quạt',
        color: const Color(0xFFA78BFA),
        on: false,
      ),
      (
        icon: CupertinoIcons.drop_fill,
        label: 'Nước',
        color: const Color(0xFF60A5FA),
        on: false,
      ),
    ];

    return SizedBox(
      width: s,
      height: s * 1.0,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseCtrl, _floatCtrl, _cloudCtrl]),
        builder: (_, __) {
          final pulse = _pulseAnim.value;
          final float = _floatAnim.value;
          final t = _cloudCtrl.value;
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // ─€─€ Phone mockup ─€─€
              Transform.translate(
                offset: Offset(0, float * 1.5),
                child: Container(
                  width: s,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B1728),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.25 + pulse * 0.10),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.30 + pulse * 0.12),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: accent.withValues(alpha: 0.08),
                        blurRadius: 60,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent.withValues(alpha: 0.15),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              CupertinoIcons.house_fill,
                              color: accent,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nhà thông minh',
                                style: TextStyle(
                                  color: CupertinoColors.white.withValues(
                                    alpha: 0.9,
                                  ),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '6 thiết bị',
                                style: TextStyle(
                                  color: accent.withValues(alpha: 0.7),
                                  fontSize: 9.5,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Power button
                          Transform.scale(
                            scale: 0.95 + pulse * 0.05,
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accent.withValues(alpha: 0.18),
                                border: Border.all(color: accent, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withValues(alpha: 0.5),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Icon(
                                CupertinoIcons.power,
                                color: accent,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Devices grid 3x2
                      // Wrapped in Expanded so the grid shrinks to the space
                      // actually left over after the header and the energy bar,
                      // instead of forcing its natural height and overflowing
                      // the fixed-size phone mockup (RenderFlex overflow).
                      Expanded(
                        child: GridView.count(
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.05,
                          children: devices.map((d) {
                            final glow = d.on ? (0.3 + pulse * 0.25) : 0.0;
                            return Container(
                              decoration: BoxDecoration(
                                color: d.on
                                    ? d.color.withValues(
                                        alpha: 0.12 + pulse * 0.05,
                                      )
                                    : CupertinoColors.white.withValues(
                                        alpha: 0.04,
                                      ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: d.on
                                      ? d.color.withValues(alpha: 0.4)
                                      : CupertinoColors.white.withValues(
                                          alpha: 0.07,
                                        ),
                                  width: 1,
                                ),
                                boxShadow: d.on
                                    ? [
                                        BoxShadow(
                                          color: d.color.withValues(
                                            alpha: glow * 0.6,
                                          ),
                                          blurRadius: 10,
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    d.icon,
                                    color: d.on
                                        ? d.color
                                        : CupertinoColors.white.withValues(
                                            alpha: 0.25,
                                          ),
                                    size: 20,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    d.label,
                                    style: TextStyle(
                                      color: d.on
                                          ? d.color.withValues(alpha: 0.9)
                                          : CupertinoColors.white.withValues(
                                              alpha: 0.25,
                                            ),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    d.on ? 'Bật' : 'Tắt',
                                    style: TextStyle(
                                      color:
                                          (d.on
                                                  ? d.color
                                                  : CupertinoColors.white)
                                              .withValues(alpha: 0.4),
                                      fontSize: 8,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Energy usage bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Năng lượng hôm nay',
                                style: TextStyle(
                                  color: CupertinoColors.white.withValues(
                                    alpha: 0.45,
                                  ),
                                  fontSize: 9,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '2.4 kWh',
                                style: TextStyle(
                                  color: accent.withValues(alpha: 0.85),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              height: 5,
                              color: CupertinoColors.white.withValues(
                                alpha: 0.07,
                              ),
                              child: FractionallySizedBox(
                                widthFactor: 0.4 + t * 0.2,
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        accent,
                                        accent.withValues(alpha: 0.5),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
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
              // ─€─€ Floating temp badge ─€─€
              Positioned(
                top: -14,
                right: -8,
                child: Transform.translate(
                  offset: Offset(0, float * 1.8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.6),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.thermometer,
                          color: Color(0xFFFF6B6B),
                          size: 13,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '26°C',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ignore: unused_element
  Widget _profileCard(
    Color accent,
    double w,
    String title,
    String sub,
    Color bg,
  ) {
    return _InteractiveElement(
      child: Container(
        width: w,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: CupertinoColors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: CupertinoColors.white.withValues(alpha: 0.05),
              ),
              child: Center(
                child: Icon(
                  CupertinoIcons.house_fill,
                  size: 24,
                  color: CupertinoColors.white.withValues(alpha: 0.2),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: TextStyle(
                color: CupertinoColors.white.withValues(alpha: 0.6),
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _swipeBtn(IconData icon, Color color) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}
