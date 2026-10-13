import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/animated_property_icons.dart';
import 'widgets/typewriter_text.dart';
import 'widgets/guest_property_card.dart'; // Thêm dòng này

import '../../../core/theme/app_theme.dart';
import '../../../core/components/bounce_click.dart';
import '../../../core/components/safe_network_image.dart';
import '../../../core/components/stayhub_main_header.dart';
import '../../../core/constants/room_type_codes.dart';
import '../../../core/services/viewed_history_service.dart';
import '../../../core/services/compare_service.dart';
import '../../room/application/public_rooms_provider.dart';
import '../../room/application/public_rooms_filter_provider.dart';
import '../../marketplace/presentation/widgets/guest_room_detail_premium.dart';
import 'package:go_router/go_router.dart';
import 'dart:async' show unawaited, StreamSubscription;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shimmer/shimmer.dart';
import '../../auth/application/auth_notifier.dart';
import '../../auth/presentation/widgets/guest_auth_bottom_sheet.dart';
import '../../marketplace/application/wishlist_provider.dart';
import '../../../core/utils/toast_utils.dart';

/// Trang Chủ dành cho Khách (Chưa đăng nhập).
///
/// Giao diện iOS 26 "Liquid Glass":
/// - Header kính mờ (Glassmorphism).
/// - Linh vật 3D tương tác.
/// - Thẻ hành động chính, grid tiện ích, banner khuyến mãi.
/// - Danh sách "Gợi ý căn hộ".
class GuestLandingScreen extends ConsumerStatefulWidget {
  const GuestLandingScreen({super.key});

  @override
  ConsumerState<GuestLandingScreen> createState() => _GuestLandingScreenState();
}

class _GuestLandingScreenState extends ConsumerState<GuestLandingScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollOffset = ValueNotifier(0.0);
  StreamSubscription<UserAccelerometerEvent>? _shakeSub;
  bool _isShaking = false;

  // "Tiếp tục xem" — danh sách phòng đã xem gần đây (lưu cục bộ).
  List<Map<String, dynamic>> _recentlyViewed = const [];
  // Số phòng đang chọn để so sánh (hiện pill nổi khi > 0).
  int _compareCount = 0;

  // Hero "rise" animation — thẻ chính trồi lên khi mở màn hình.
  late final AnimationController _heroCtrl;
  late final Animation<double> _heroRise;

  bool _showAllFeatures = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      _scrollOffset.value = _scrollController.offset;
    });
    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _heroRise = CurvedAnimation(parent: _heroCtrl, curve: Curves.easeOutCubic);
    unawaited(_heroCtrl.forward());

    _shakeSub = userAccelerometerEventStream().listen((event) {
      if (event.x.abs() > 15 || event.y.abs() > 15 || event.z.abs() > 15) {
        if (!_isShaking && mounted) {
          _isShaking = true;
          _triggerShakeSurprise();
        }
      }
    });

    unawaited(_loadLocalActivity());
  }

  /// Nạp "Tiếp tục xem" + số phòng đang so sánh từ bộ nhớ cục bộ.
  Future<void> _loadLocalActivity() async {
    final history = await ViewedHistoryService.getHistory();
    final compareCount = await CompareService.count();
    if (!mounted) return;
    setState(() {
      _recentlyViewed = history
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .take(8)
          .toList();
      _compareCount = compareCount;
    });
  }

  void _triggerShakeSurprise() {
    unawaited(HapticFeedback.vibrate());
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('🎉 BẠN VỪA LẮC ĐIỆN THOẠI!'),
        content: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            'Một phòng "Xả Lỗ" giảm 50% vừa rơi ra. Chớp lấy cơ hội này bằng cách đăng nhập ngay!',
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text(
              'Bỏ qua',
              style: TextStyle(color: CupertinoColors.systemGrey),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Future.delayed(const Duration(seconds: 3), () {
                if (mounted) _isShaking = false;
              });
            },
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text(
              'Nhận Phòng Ngay',
              style: TextStyle(
                color: AppTheme.kBrand,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _isShaking = false;
              context.push('/login');
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _shakeSub?.cancel();
    _heroCtrl.dispose();
    _scrollController.dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  Widget _buildHeaderContent() {
    // Dùng bộ action mặc định (QR · Tin nhắn · Thông báo) để icon nhắn tin
    // hiển thị và hoạt động. Trước đây truyền `rightActions: []` (list rỗng)
    // khiến header không render icon nào → bấm không có gì xảy ra.
    return const StayHubMainHeader();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final topPadding = media.padding.top;
    // Tile width for the 4-column feature grid.
    // available = screen - 32 (16px padding each side); gap = 8.
    // Subtracting the 3 gaps avoids float rounding pushing the 4th tile
    // onto the next line (which caused the 4-then-3 row layout).
    final double tileW = (media.size.width - 32 - 8 * 3) / 4;

    return Scaffold(
      // Nền ảnh header isometric xanh gốc (JPG đục) — phủ kín phía trên.
      backgroundColor: AppTheme.kBackgroundLight,
      body: Stack(
        children: [
          // 1. Ảnh nền header isometric xanh gốc (Fixed Background).
          //    - Cao hơn viewport (1.6x) để ảnh "cao lên" hẳn, thoáng hơn.
          //    - Mờ dần từ ~3/4 chiều cao ảnh trở xuống bằng lớp gradient trắng
          //      phủ lên trên, hoà mượt vào nền trắng bên dưới (không có đường
          //      kẻ ngang).
          //    - Dùng Stack + gradient overlay thay cho ShaderMask/BlendMode.dstIn
          //      vì ShaderMask bị lỗi render (ảnh tàng hình) trên CanvasKit web.
          ValueListenableBuilder<double>(
            valueListenable: _scrollOffset,
            builder: (context, offset, child) {
              // Scroll 300px thì mờ hẳn
              final opacity = (1.0 - (offset / 300.0)).clamp(0.0, 1.0);

              // Khi cuộn ngược lên trên (overscroll), offset sẽ < 0
              // Ta tính toán khoảng overscroll này để kéo ảnh xuống theo
              final overscrollDown = offset < 0 ? -offset : 0.0;

              final bgHeight =
                  media.size.height; // Hoàn toàn không phóng to (tỷ lệ 1.0)

              // Tạo hiệu ứng Parallax Zoom (như iOS):
              // Cố định đỉnh ảnh, chỉ phóng to ảnh một chút xíu khi kéo lố xuống dưới
              final currentScale = 1.1 + (overscrollDown / 4000.0);

              return Positioned(
                top:
                    -60, // Kéo nền lên trên thêm một chút xíu để thu hẹp khoảng trắng
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: opacity,
                  child: SizedBox(
                    width: double.infinity,
                    height: bgHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Ảnh nền gốc.
                        Transform.scale(
                          scale: currentScale, // Zoom nhẹ ảnh theo lực kéo
                          alignment: Alignment
                              .topCenter, // Lấy đỉnh ảnh làm điểm neo để zoom
                          child: Image.asset(
                            'assets/images/hero_city_white_new.jpg',
                            fit: BoxFit.fitWidth,
                            alignment: Alignment.topCenter,
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                        // Lớp gradient trắng: trong suốt ở 3/4 trên, trắng đặc ở đáy
                        // → ảnh giữ nét lâu hơn, chỉ mờ dần ở phần dưới cùng.
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x00FFFFFF),
                                Color(0x00FFFFFF),
                                Colors.white,
                              ],
                              stops: [
                                0.0,
                                0.75,
                                1.0,
                              ], // Bắt đầu mờ từ 3/4 ảnh, mượt mà chuyển sang trắng tinh
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

          // 2. Nội dung cuộn (CustomScrollView)
          CustomScrollView(
            controller: _scrollController,
            physics:
                const BouncingScrollPhysics(), // Trả lại hiệu ứng nảy mượt mà của iOS
            slivers: [
              // Thanh không gian trống để đẩy nội dung xuống
              const SliverAppBar(
                pinned: true,
                expandedHeight:
                    260, // Kéo thẻ lên cao hơn nữa để giảm khoảng trắng
                collapsedHeight: 80,
                toolbarHeight: 78,
                backgroundColor: Colors.transparent,
                elevation: 0,
                // Nền trong suốt để lộ ảnh
                surfaceTintColor: Colors.transparent,
                automaticallyImplyLeading: false,
              ),

              // 3. Khối nội dung (Các thẻ nổi floating cards)
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    // Nền trắng với hiệu ứng fade mờ dần ở trên để hoà quyện ảnh nền
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Column(
                        children: [
                          Container(
                            height: 180,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.0),
                                  Colors.white,
                                ],
                              ),
                            ),
                          ),
                          Expanded(child: Container(color: Colors.white)),
                        ],
                      ),
                    ),

                    // Nội dung Foreground
                    Column(
                      children: [
                        const SizedBox(
                          height: 24,
                        ), // Đẩy thẻ xuống để đè lên ranh giới nền trắng
                        // ── Main Action Card (Thuê và cho thuê) ──
                        // Hero "rise": trồi lên + mờ dần khi mở màn hình.
                        AnimatedBuilder(
                          animation: _heroRise,
                          builder: (context, child) {
                            final t = _heroRise.value;
                            return Opacity(
                              opacity: t.clamp(0.0, 1.0),
                              child: Transform.translate(
                                offset: Offset(0, (1 - t) * 26),
                                child: child,
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: BounceClick(
                              onPressed: _openMarketplace,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // Nền thẻ chính — gradient kem ấm + viền sáng trên đỉnh
                                  Container(
                                    padding: const EdgeInsets.fromLTRB(
                                      20,
                                      22,
                                      20,
                                      20,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Colors.white,
                                          AppTheme.kSurface1Light,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(28),
                                      boxShadow: [
                                        const BoxShadow(
                                          color: Color(0x1469B1FF),
                                          blurRadius: 40,
                                          spreadRadius: -6,
                                          offset: Offset(0, 16),
                                        ),
                                        BoxShadow(
                                          color: AppTheme.kBrand.withValues(
                                            alpha: 0.10,
                                          ),
                                          blurRadius: 24,
                                          spreadRadius: -8,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: AppTheme.kBorderColor.withValues(
                                          alpha: 0.55,
                                        ),
                                        width: 1.4,
                                      ),
                                    ),
                                    child: Builder(
                                      builder: (context) {
                                        final subtitleNotifier =
                                            ValueNotifier<String>(
                                              'Đa dạng loại hình lưu trú',
                                            );
                                        final subtitles = [
                                          'Đa dạng loại hình lưu trú',
                                          'Nhà nguyên căn tiện nghi',
                                          'Studio phong cách hiện đại',
                                          'Phòng trọ giá tốt, an ninh',
                                          'Chung cư cao cấp sang trọng',
                                        ];

                                        return Row(
                                          children: [
                                            // Icon 3D Animated Carousel — có quầng sáng Sky Blue phía sau
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: RadialGradient(
                                                  colors: [
                                                    AppTheme.kBrand.withValues(
                                                      alpha: 0.16,
                                                    ),
                                                    AppTheme.kBrand.withValues(
                                                      alpha: 0.0,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              child: AnimatedPropertyIcons(
                                                size: 80,
                                                onIndexChanged: (index) {
                                                  subtitleNotifier.value =
                                                      subtitles[index];
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 18),
                                            // Nội dung văn bản và Nút
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Thuê và cho thuê',
                                                    style: TextStyle(
                                                      fontSize: 19,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      letterSpacing: -0.3,
                                                      color: Color(
                                                        0xFF1E293B,
                                                      ), // Navy blue
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 5),
                                                  // Hiệu ứng GÕ CHỮ DẦN DẦN (typewriter)
                                                  ValueListenableBuilder<
                                                    String
                                                  >(
                                                    valueListenable:
                                                        subtitleNotifier,
                                                    builder: (context, subtitle, _) {
                                                      return TypewriterText(
                                                        text: subtitle,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          height: 1.4,
                                                          color: AppTheme
                                                              .kTextSecondary,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                  const SizedBox(height: 16),
                                                  // Nút Khám phá ngay — Sky Blue gradient (đồng bộ thương hiệu).
                                                  // Bọc BounceClick riêng để nút là vùng chạm độc lập,
                                                  // chạm là mở thẳng tab "Tìm phòng" (không bị nuốt
                                                  // thành thao tác cuộn/lướt của danh sách bên dưới).
                                                  BounceClick(
                                                    onPressed: _openMarketplace,
                                                    child: Container(
                                                      height: 44,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 26,
                                                          ),
                                                      alignment:
                                                          Alignment.center,
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            const LinearGradient(
                                                              colors: [
                                                                AppTheme.kBrand,
                                                                AppTheme
                                                                    .kBrandDeep,
                                                              ],
                                                              begin: Alignment
                                                                  .topLeft,
                                                              end: Alignment
                                                                  .bottomRight,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              50,
                                                            ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: AppTheme
                                                                .kBrand
                                                                .withValues(
                                                                  alpha: 0.34,
                                                                ),
                                                            blurRadius: 20,
                                                            spreadRadius: -2,
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  9,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      child: const Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            'Khám phá ngay',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              fontSize: 14,
                                                              letterSpacing:
                                                                  0.2,
                                                            ),
                                                          ),
                                                          SizedBox(width: 6),
                                                          Icon(
                                                            CupertinoIcons
                                                                .arrow_right,
                                                            color: Colors.white,
                                                            size: 15,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  // Nhãn "HOT" ở góc phải — gắn ý nghĩa cho icon lửa
                                  Positioned(
                                    top: -1,
                                    right: 22, // Thụt vào 1 chút
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFf9a05b),
                                            Color(0xFFe57332),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              bottom: Radius.circular(12),
                                            ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFFe57332,
                                            ).withValues(alpha: 0.28),
                                            blurRadius: 12,
                                            spreadRadius: -2,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            CupertinoIcons.flame_fill,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'HOT',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.6,
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
                        ),
                        const SizedBox(height: 22),

                        // ── 4-Item Grid ──
                        // AnimatedSize makes the extra rows grow/shrink smoothly
                        // when toggling "Xem thêm" / "Thu gọn".
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.topCenter,
                            child: Wrap(
                              alignment: WrapAlignment.start,
                              runSpacing: 16,
                              // 8px gap between tiles; width is computed so
                              // exactly 4 tiles fit per row (no float rounding
                              // pushing the 4th tile to the next line).
                              spacing: 8,
                              children: [
                                SizedBox(
                                  width: tileW,
                                  child: _build3DIconAction(
                                    0,
                                    'Tìm phòng\nnhanh',
                                    AppTheme.kBrand,
                                    onTap: _openMarketplace,
                                    isExpanded: false,
                                  ),
                                ),
                                SizedBox(
                                  width: tileW,
                                  child: _build3DIconAction(
                                    1,
                                    'Ghép phòng\ntiết kiệm',
                                    AppTheme.kBrand,
                                    isExpanded: false,
                                  ),
                                ),
                                SizedBox(
                                  width: tileW,
                                  child: _build3DIconAction(
                                    2,
                                    'Sự kiện &\nGiải trí',
                                    AppTheme.kBrand,
                                    isExpanded: false,
                                  ),
                                ),
                                SizedBox(
                                  width: tileW,
                                  child: _build3DIconAction(
                                    3,
                                    'Hóa đơn\nđiện nước',
                                    AppTheme.kBrand,
                                    onTap: () {
                                      context.go('/bill');
                                    },
                                    isExpanded: false,
                                  ),
                                ),
                                SizedBox(
                                  width: tileW,
                                  child: _build3DIconAction(
                                    4,
                                    'Báo sự cố\nbảo trì',
                                    AppTheme.kBrand,
                                    isExpanded: false,
                                  ),
                                ),
                                SizedBox(
                                  width: tileW,
                                  child: _build3DIconAction(
                                    5,
                                    'Hợp đồng\nđiện tử',
                                    AppTheme.kBrand,
                                    onTap: () {
                                      context.go('/contract-list');
                                    },
                                    isExpanded: false,
                                  ),
                                ),
                                SizedBox(
                                  width: tileW,
                                  child: _build3DIconAction(
                                    6,
                                    'Đầu tư\nsinh lời',
                                    AppTheme.kBrand,
                                    isExpanded: false,
                                  ),
                                ),
                                // Ô thứ 8 LUÔN hiển thị (kể cả khi thu gọn) để lưới
                                // thu gọn đủ 2 hàng × 4 ô — tránh hàng dưới lẻ 3 ô.
                                SizedBox(
                                  width: tileW,
                                  child: _build3DIconAction(
                                    7,
                                    'Cộng đồng\ncư dân',
                                    AppTheme.kBrand,
                                    isExpanded: false,
                                  ),
                                ),
                                if (_showAllFeatures) ...[
                                  SizedBox(
                                    width: tileW,
                                    child: _build3DIconAction(
                                      8,
                                      'Tiện ích\nxung quanh',
                                      AppTheme.kBrand,
                                      isExpanded: false,
                                    ),
                                  ),
                                  SizedBox(
                                    width: tileW,
                                    child: _build3DIconAction(
                                      13,
                                      'Phòng\ncủa tôi',
                                      AppTheme.kBrand,
                                      isExpanded: false,
                                    ),
                                  ),
                                  SizedBox(
                                    width: tileW,
                                    child: _build3DIconAction(
                                      10,
                                      'An ninh\ntoà nhà',
                                      AppTheme.kBrand,
                                      isExpanded: false,
                                    ),
                                  ),
                                  SizedBox(
                                    width: tileW,
                                    child: _build3DIconAction(
                                      11,
                                      'Hệ thống\nchi nhánh',
                                      AppTheme.kBrand,
                                      isExpanded: false,
                                    ),
                                  ),
                                  SizedBox(
                                    width: tileW,
                                    child: _build3DIconAction(
                                      12,
                                      'Ký hợp đồng\nđiện tử',
                                      AppTheme.kBrand,
                                      isExpanded: false,
                                    ),
                                  ),
                                  SizedBox(
                                    width: tileW,
                                    child: _build3DIconAction(
                                      15,
                                      'Hỗ trợ\n24/7',
                                      AppTheme.kBrand,
                                      isExpanded: false,
                                    ),
                                  ),
                                  SizedBox(
                                    width: tileW,
                                    child: _build3DIconAction(
                                      14,
                                      'Đánh giá\nchất lượng',
                                      AppTheme.kBrand,
                                      isExpanded: false,
                                    ),
                                  ),
                                  SizedBox(
                                    width: tileW,
                                    child: _build3DIconAction(
                                      9,
                                      'Ví điện tử',
                                      AppTheme.kBrand,
                                      onTap: () {
                                        context.go('/wallet');
                                      },
                                      isExpanded: false,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // ── Grid expand / collapse control ──
                        // "Xem thêm" and "Thu gọn" are NOT features — render
                        // them as a single centered pill button below the grid
                        // so users read them as controls, not feature tiles.
                        const SizedBox(height: 14),
                        Center(
                          child: _CollapseFeaturesButton(
                            expanded: _showAllFeatures,
                            onTap: () {
                              setState(() {
                                _showAllFeatures = !_showAllFeatures;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ── Tiếp tục xem (Recently viewed) ──
                        if (_recentlyViewed.isNotEmpty) ...[
                          _RecentlyViewedSection(
                            rooms: _recentlyViewed,
                            onSeeAll: () =>
                                unawaited(context.push('/viewed-history')),
                            onTapRoom: (room) => _openRoomDetail(room),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // ── Promo Banner (EPIC CENTER style) ──
                        const _PromoCarousel(),
                        const SizedBox(height: 24),

                        // ── AI Financial Calculator ──
                        const _FinancialCalculatorCard(),
                        const SizedBox(height: 24),

                        // ── Featured Rooms List ──
                        // Tiêu đề ĐỘNG theo chip loại phòng đang chọn. Trước đây
                        // hardcode "Gợi ý căn hộ" → mọi loại phòng (kể cả phòng
                        // trọ) đều hiển thị dưới tiêu đề "căn hộ" gây hiểu nhầm.
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      // BUGFIX: icon ĐỘNG theo loại phòng đang
                                      // lọc (trước đây luôn là can_ho.png).
                                      Image(
                                        image: AssetImage(
                                          _featuredSectionImage(ref),
                                        ),
                                        width: 24,
                                        height: 24,
                                        fit: BoxFit.contain,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _featuredSectionTitle(ref),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.kTextPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  BounceClick(
                                    onPressed: _openMarketplace,
                                    child: const Icon(
                                      CupertinoIcons.chevron_right,
                                      size: 20,
                                      color: AppTheme.kTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height:
                                  380, // Tăng chiều cao để chứa GuestPropertyCard chi tiết
                              child: ref
                                  .watch(sortedPublicRoomsProvider)
                                  .when(
                                    data: (posts) {
                                      if (posts.isEmpty) {
                                        return const Center(
                                          child: Text('Chưa có gợi ý nào'),
                                        );
                                      }
                                      return ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                        ),
                                        physics: const BouncingScrollPhysics(),
                                        itemCount: posts.length > 5
                                            ? 5
                                            : posts
                                                  .length, // Tạm show tối đa 5 cái mới nhất
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(width: 16),
                                        itemBuilder: (context, index) {
                                          final property = posts[index];
                                          final propId = (property['id'] ?? property['roomId'])?.toString() ?? '';
                                          final wishlistState = ref.watch(wishlistProvider);
                                          final isWishlisted = propId.isNotEmpty && wishlistState.ids.contains(propId);

                                          return SizedBox(
                                            width: 300,
                                            child: GuestPropertyCard(
                                              property: property,
                                              isWishlisted: isWishlisted,
                                              onToggleWishlist: () async {
                                                if (ref.read(authProvider).value == null) {
                                                  unawaited(GuestAuthBottomSheet.show(context));
                                                  return;
                                                }
                                                unawaited(HapticFeedback.mediumImpact());
                                                await ref.read(wishlistProvider.notifier).toggle(property);
                                                if (context.mounted) {
                                                  ToastUtils.show(
                                                    context,
                                                    isWishlisted ? 'Đã bỏ lưu phòng' : 'Đã lưu phòng vào yêu thích',
                                                  );
                                                }
                                              },
                                              onTap: () {
                                                unawaited(
                                                  showModalBottomSheet(
                                                    context: context,
                                                    isScrollControlled: true,
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    barrierColor: Colors.black
                                                        .withValues(alpha: 0.5),
                                                    enableDrag: false,
                                                    builder: (ctx) {
                                                      return DraggableScrollableSheet(
                                                        initialChildSize: 1.0,
                                                        minChildSize: 0.0,
                                                        maxChildSize: 1.0,
                                                        snap: true,
                                                        snapSizes: const [1.0],
                                                        builder:
                                                            (
                                                              ctx,
                                                              scrollController,
                                                            ) {
                                                              return GuestRoomDetailPremiumBottomSheet(
                                                                room: property,
                                                                scrollController:
                                                                    scrollController,
                                                              );
                                                            },
                                                      );
                                                    },
                                                  ),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    loading: () => ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                      ),
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: 3,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 16),
                                      itemBuilder: (_, __) => Shimmer.fromColors(
                                        baseColor: AppTheme.kBorderColor
                                            .withValues(alpha: 0.4),
                                        highlightColor: AppTheme.kSurfaceBlue
                                            .withValues(alpha: 0.6),
                                        child: Container(
                                          width: 300,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                height: 200,
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.vertical(
                                                        top: Radius.circular(
                                                          24,
                                                        ),
                                                      ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Container(
                                                      width: 120,
                                                      height: 14,
                                                      color: Colors.white,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Container(
                                                      width: double.infinity,
                                                      height: 20,
                                                      color: Colors.white,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Container(
                                                      width: 200,
                                                      height: 20,
                                                      color: Colors.white,
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Container(
                                                      width: 150,
                                                      height: 24,
                                                      color: Colors.white,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    error: (err, stack) =>
                                        Center(child: Text('Lỗi: $err')),
                                  ),
                            ),
                            const SizedBox(
                              height: 100,
                            ), // padding cho bottom nav
                          ], // Closes children of Featured Rooms Column
                        ), // Closes Featured Rooms Column
                      ], // Closes children of main Column
                    ), // Closes main Column
                  ], // Closes Stack children
                ), // Closes Stack
              ), // Closes SliverToBoxAdapter
            ], // Closes slivers
          ), // Closes CustomScrollView
          // 3. Fixed Header (Giữ Glassmorphism chỉ giới hạn trong 80px trên cùng)
          ValueListenableBuilder<double>(
            valueListenable: _scrollOffset,
            builder: (context, offset, child) {
              // Khi scroll qua 50px thì lớp kính mờ hiện rõ dần lên
              final glassOpacity = (offset / 150.0).clamp(0.0, 1.0);

              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: topPadding + 68,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Lớp kính mờ (Glassmorphism)
                    if (glassOpacity > 0)
                      Opacity(
                        opacity: glassOpacity,
                        child: ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              // Kính mờ trên nền trắng tinh — dùng trắng mờ
                              // để không ám tông xanh băng lệch màu nền.
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ),

                    // Nội dung Logo và Notification Icon
                    Positioned(
                      top: topPadding,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildHeaderContent(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // 4. Floating "So sánh phòng" pill — chỉ hiện khi đã chọn phòng.
          if (_compareCount > 0)
            Positioned(
              right: 20,
              bottom: 108,
              child: _CompareFab(
                count: _compareCount,
                onTap: () async {
                  await context.push('/compare-rooms');
                  await _loadLocalActivity();
                },
              ),
            ),
        ], // Closes Stack children
      ), // Closes Stack
    ); // Closes Scaffold
  }

  /// Mở chi tiết phòng dạng bottom sheet (dùng cho "Tiếp tục xem").
  void _openRoomDetail(Map<String, dynamic> room) {
    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        enableDrag: false,
        builder: (ctx) {
          return DraggableScrollableSheet(
            initialChildSize: 1.0,
            minChildSize: 0.0,
            maxChildSize: 1.0,
            snap: true,
            snapSizes: const [1.0],
            builder: (ctx, scrollController) {
              return GuestRoomDetailPremiumBottomSheet(
                room: room,
                scrollController: scrollController,
              );
            },
          );
        },
      ),
    );
  }

  Widget _build3DIconAction(
    int? gridIndex,
    String label,
    Color color, {
    VoidCallback? onTap,
    bool isExpanded = true,
    IconData? fallbackIcon,
  }) {
    final content = BounceClick(
      onPressed: onTap ?? () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 520),
            curve: Curves.easeOutBack,
            builder: (context, t, child) {
              return Transform.translate(
                offset: Offset(0, (1 - t) * 12),
                child: Transform.scale(scale: 0.88 + t * 0.12, child: child),
              );
            },
            child: SizedBox(
              // Icons are authored at 96x122 (portrait). Keep that aspect
              // ratio so the diorama art is not squished into a square.
              width: 76,
              height: 96,
              child: gridIndex != null
                  ? Image.asset(
                      'assets/images/features/split_icons/icon_$gridIndex.png',
                      fit: BoxFit.contain,
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(fallbackIcon, size: 32, color: color),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.25,
                height: 1.25,
                color: Color(0xFF0F2D59),
              ),
            ),
          ),
        ],
      ),
    );
    return isExpanded ? Expanded(child: content) : content;
  }

  /// Mở màn hình chợ phòng (tab "Tìm phòng").
  ///
  /// BUGFIX: bỏ tham số `ref` không dùng và bỏ `try/catch (_) {}` rỗng —
  /// catch rỗng nuốt mọi lỗi điều hướng khiến bug "im lặng" rất khó truy.
  /// `context.push` là Future; dùng `unawaited` + `mounted` guard là đủ.
  void _openMarketplace() {
    if (!mounted) return;
    unawaited(context.push('/guest-search'));
  }

  /// Tiêu đề mục "gợi ý" — ĐỘNG theo loại phòng đang lọc.
  ///
  /// Khi chưa chọn chip nào → "Gợi ý phòng mới nhất" (trung tính, không ám chỉ
  /// căn hộ). Khi chọn chip → "Gợi ý <nhãn loại phòng>" (vd "Gợi ý Phòng trọ").
  ///
  /// BUGFIX: canonical hoá trước khi lấy nhãn. Nếu state lỡ chứa alias (vd
  /// `KY_TUC_XA`) thì [RoomTypeCodes.labelOf] trả nhãn alias ("Ký túc xá") thay
  /// vì nhãn canonical ("Ở ghép / Ký túc xá") → tiêu đề lệch với chip. Dùng
  /// [RoomTypeCodes.toCode] để luôn hiển thị nhãn canonical.
  String _featuredSectionTitle(WidgetRef ref) {
    final selected = ref.watch(
      publicRoomsFilterProvider.select((s) => s.roomTypes),
    );
    if (selected.isEmpty) return 'Gợi ý phòng mới nhất';
    final canonical = RoomTypeCodes.toCode(selected.first) ?? selected.first;
    final label = RoomTypeCodes.labelOf(canonical);
    return 'Gợi ý $label';
  }

  /// Ảnh danh mục cho tiêu đề mục "gợi ý" — ĐỘNG theo loại phòng đang lọc.
  ///
  /// BUGFIX: trước đây icon tiêu đề LUÔN hardcode `can_ho.png` (căn hộ) bất kể
  /// người dùng chọn chip "Phòng trọ"/"Ký túc xá"/"Mặt bằng"… → icon mâu thuẫn
  /// với tiêu đề. Nay ánh xạ theo mã canonical, fallback về `can_ho.png`.
  String _featuredSectionImage(WidgetRef ref) {
    final selected = ref.watch(
      publicRoomsFilterProvider.select((s) => s.roomTypes),
    );
    if (selected.isEmpty) return 'assets/images/categories/can_ho.png';
    final canonical = RoomTypeCodes.toCode(selected.first) ?? selected.first;
    const map = <String, String>{
      'PHONG_TRO': 'phong_tro',
      'CHDV': 'phong_tro',
      'STUDIO': 'phong_tro',
      'GAC_LUNG': 'phong_tro',
      'PHONG_GAC_XEP': 'phong_tro',
      'CHUNG_CU_MINI': 'can_ho',
      'CHUNG_CU': 'can_ho',
      'NHA_NGUYEN_CAN': 'nha_o',
      'O_GHEP_KTX': 'o_ghep',
      'OFFICE': 'van_phong',
      'KIOT': 'mat_bang',
      'KHO_BAI': 'kho_van',
      'KHONG_GIAN_CD': 'khong_gian',
      'LUU_TRU': 'luu_tru',
      'DAT_CHO_THUE': 'dat_cho_thue',
    };
    final base = map[canonical] ?? 'can_ho';
    return 'assets/images/categories/$base.png';
  }
}

class _PromoCarousel extends StatelessWidget {
  const _PromoCarousel();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _PromoCard(
            title: 'Ưu đãi cư dân\nStayHub',
            subtitle: 'Sử dụng tiện ích hấp dẫn',
            iconPath: 'assets/images/categories/icon_resident_perks.png',
            bgColor: AppTheme.kSurface1Light,
            hasShadow: true,
            onTap: () => _showPromoDetail(
              context,
              title: 'Ưu đãi cư dân StayHub',
              body:
                  'Khi thuê phòng qua StayHub, bạn được miễn phí sử dụng các tiện ích: '
                  'hợp đồng điện tử, thanh toán hoá đơn, quản lý phòng thông minh và '
                  'hỗ trợ khách hàng 24/7.',
            ),
          ),
          const SizedBox(width: 16),
          _PromoCard(
            title: 'Giới thiệu bạn thuê\nphòng',
            subtitle: 'Nhận ngay',
            highlightText: '200K',
            iconPath: 'assets/images/categories/icon_referral_reward.png',
            bgColor: AppTheme.kSurfaceBlue,
            hasBorder: true,
            onTap: () => _showPromoDetail(
              context,
              title: 'Giới thiệu bạn bè — Nhận 200K',
              body:
                  'Chia sẻ mã giới thiệu của bạn. Khi bạn bè đặt phòng thành công, '
                  'cả hai cùng nhận 200.000₫ vào ví StayHub. Không giới hạn số lượt giới thiệu.',
            ),
          ),
          const SizedBox(width: 16),
          _PromoCard(
            title: 'Hoàn tiền 10%\nđặt cọc',
            subtitle: 'Dành cho hội viên mới',
            highlightText: 'Độc quyền',
            iconPath: 'assets/images/categories/khong_gian_v11.png',
            bgColor: AppTheme.kSurface1Light,
            hasShadow: true,
            onTap: () => _showPromoDetail(
              context,
              title: 'Hoàn tiền 10% đặt cọc',
              body:
                  'Hội viên mới đặt cọc lần đầu qua StayHub được hoàn 10% giá trị tiền cọc '
                  'vào ví điện tử trong vòng 24 giờ sau khi hợp đồng được ký kết.',
            ),
          ),
        ],
      ),
    );
  }

  void _showPromoDetail(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.kSurface1Light,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppTheme.kTextPrimary,
          ),
        ),
        content: Text(
          body,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppTheme.kTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Đóng',
              style: TextStyle(
                color: AppTheme.kBrand,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? highlightText;
  final String iconPath;
  final Color bgColor;
  final bool hasShadow;
  final bool hasBorder;
  final VoidCallback? onTap;

  const _PromoCard({
    required this.title,
    required this.subtitle,
    this.highlightText,
    required this.iconPath,
    required this.bgColor,
    this.hasShadow = false,
    this.hasBorder = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BounceClick(
      onPressed: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(28),
          border: hasBorder
              ? Border.all(color: AppTheme.kBorderColor.withValues(alpha: 0.6))
              : null,
          boxShadow: hasShadow
              ? const [
                  BoxShadow(
                    color: Color(0x1469B1FF),
                    blurRadius: 24,
                    spreadRadius: 0,
                    offset: Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppTheme.kTextPrimary,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (highlightText == null) const Spacer(),
            if (highlightText != null) const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppTheme.kTextSecondary,
              ),
            ),
            if (highlightText != null)
              Text(
                highlightText!,
                style: TextStyle(
                  fontSize: highlightText == '200K' ? 26 : 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.kBrandDeep,
                ),
              ),
            if (highlightText == null) const SizedBox(height: 12),
            if (highlightText != null) const Spacer(),
            Image.asset(
              iconPath,
              width: highlightText != null ? 38 : 44,
              height: highlightText != null ? 38 : 44,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => SizedBox(
                width: highlightText != null ? 38 : 44,
                height: highlightText != null ? 38 : 44,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section "Tiếp tục xem" — carousel phòng đã xem gần đây (lưu cục bộ).
class _RecentlyViewedSection extends StatelessWidget {
  final List<Map<String, dynamic>> rooms;
  final VoidCallback onSeeAll;
  final void Function(Map<String, dynamic> room) onTapRoom;

  const _RecentlyViewedSection({
    required this.rooms,
    required this.onSeeAll,
    required this.onTapRoom,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    CupertinoIcons.clock_fill,
                    size: 20,
                    color: AppTheme.kBrand,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Tiếp tục xem',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.kTextPrimary,
                    ),
                  ),
                ],
              ),
              BounceClick(
                onPressed: onSeeAll,
                child: const Row(
                  children: [
                    Text(
                      'Xem tất cả',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.kBrand,
                      ),
                    ),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 16,
                      color: AppTheme.kBrand,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
            itemCount: rooms.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final room = rooms[index];
              return _RecentlyViewedCard(
                room: room,
                onTap: () => onTapRoom(room),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Thẻ phòng gọn cho carousel "Tiếp tục xem".
class _RecentlyViewedCard extends StatelessWidget {
  final Map<String, dynamic> room;
  final VoidCallback onTap;

  const _RecentlyViewedCard({required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = (room['title'] ?? room['name'] ?? room['roomName'] ?? 'Phòng')
        .toString();
    final address = (room['address'] ?? room['addressOld'] ?? '').toString();
    final price = _asNum(room['price']);
    final area = _asNum(room['area'] ?? room['floorArea']);
    final image = (room['firstImage'] ?? room['coverImageUrl'] ?? '')
        .toString();

    return BounceClick(
      onPressed: onTap,
      child: Container(
        width: 168,
        decoration: BoxDecoration(
          color: AppTheme.kSurface1Light,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.kBorderColor.withValues(alpha: 0.6),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1469B1FF),
              blurRadius: 20,
              spreadRadius: -4,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: SizedBox(
                height: 104,
                width: double.infinity,
                child: image.isEmpty
                    ? Container(
                        color: AppTheme.kSurfaceBlue,
                        child: const Icon(
                          CupertinoIcons.photo,
                          color: AppTheme.kBrand,
                          size: 28,
                        ),
                      )
                    : SafeNetworkImage(
                        url: image,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          color: AppTheme.kSurfaceBlue,
                          child: const Icon(
                            CupertinoIcons.photo,
                            color: AppTheme.kBrand,
                            size: 28,
                          ),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    address.isEmpty ? 'Chưa cập nhật vị trí' : address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.kTextMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        price > 0 ? '${_formatPrice(price)}đ' : 'Liên hệ',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.kBrandDeep,
                        ),
                      ),
                      if (area > 0) ...[
                        const Spacer(),
                        Text(
                          '${area.toStringAsFixed(0)}m²',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.kTextSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút nổi "So sánh phòng" — hiện khi khách đã chọn phòng để so sánh.
class _CompareFab extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _CompareFab({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BounceClick(
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.kBrand, AppTheme.kBrandDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: AppTheme.kBrand.withValues(alpha: 0.4),
              blurRadius: 22,
              spreadRadius: -2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.arrow_left_right,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            const Text(
              'So sánh phòng',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: AppTheme.kBrandDeep,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ép kiểu số an toàn từ dynamic (int/double/String).
double _asNum(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

/// Định dạng giá kiểu Việt Nam (1.500.000).
String _formatPrice(double value) {
  final s = value.toStringAsFixed(0);
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}

class _FinancialCalculatorCard extends StatefulWidget {
  const _FinancialCalculatorCard();

  @override
  State<_FinancialCalculatorCard> createState() =>
      _FinancialCalculatorCardState();
}

class _FinancialCalculatorCardState extends State<_FinancialCalculatorCard> {
  double _income = 10.0; // Triệu VNĐ

  @override
  Widget build(BuildContext context) {
    final recommendedRent = (_income * 0.25).toStringAsFixed(1);
    final maxRent = (_income * 0.35).toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.kSurfaceBlue.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.kBrand.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kBrand.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.kBrand.withValues(alpha: 0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.chart_pie_fill,
                  color: AppTheme.kBrandDeep,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Khám Sức Khỏe Tài Chính',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppTheme.kBrandDeep,
                      ),
                    ),
                    Text(
                      'AI tính toán ngân sách thuê nhà an toàn',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Thu nhập hàng tháng: ${_income.toInt()} Triệu VNĐ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          CupertinoSlider(
            value: _income,
            min: 5.0,
            max: 50.0,
            divisions: 45,
            activeColor: AppTheme.kBrand,
            thumbColor: Colors.white,
            onChanged: (val) {
              setState(() {
                _income = val;
              });
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nên thuê tầm',
                      style: TextStyle(
                        color: AppTheme.kTextSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$recommendedRent - $maxRent Tr',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppTheme.kAccentColor,
                      ),
                    ),
                  ],
                ),
                BounceClick(
                  onPressed: () {
                    showCupertinoDialog(
                      context: context,
                      builder: (ctx) => CupertinoAlertDialog(
                        title: const Text('💡 Gợi Ý Từ AI'),
                        content: Text(
                          'Với ngân sách $recommendedRent - $maxRent Triệu, chúng tôi đã lọc ra hơn 100+ phòng trọ an ninh. Đăng nhập để xem ngay!',
                        ),
                        actions: [
                          CupertinoDialogAction(
                            child: const Text('Bỏ qua'),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                          CupertinoDialogAction(
                            isDefaultAction: true,
                            child: const Text('Đăng nhập'),
                            onPressed: () {
                              Navigator.pop(ctx);
                              if (context.mounted) {
                                context.push('/login');
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.kBrand,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Lọc phòng',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Small centered pill that toggles the feature grid between collapsed and
/// expanded. Rendered as a control (not a feature tile) so users immediately
/// read it as "Xem thêm" / "Thu gọn" rather than another feature.
///
/// Styled per the StayHub design system: pill shape (radius 50), soft blue
/// glow shadow, subtle brand gradient, and an animated chevron that rotates
/// smoothly when the grid toggles.
class _CollapseFeaturesButton extends StatelessWidget {
  const _CollapseFeaturesButton({required this.expanded, required this.onTap});

  /// When true the grid is expanded → show "Thu gọn" (chevron up).
  /// When false the grid is collapsed → show "Xem thêm" (chevron down).
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BounceClick(
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.kBrand.withValues(alpha: 0.16),
              AppTheme.kBrand.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: AppTheme.kBrand.withValues(alpha: 0.30),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.kBrand.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              expanded ? 'Thu gọn' : 'Xem thêm',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: AppTheme.kBrandDeep,
              ),
            ),
            const SizedBox(width: 6),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: const Icon(
                CupertinoIcons.chevron_down,
                size: 14,
                color: AppTheme.kBrandDeep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
