// Trigger IDE refresh
import 'dart:ui';
import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../../../core/utils/image_url_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/utils/location_utils.dart';
import '../../../../core/constants/poi_database.dart';
import '../../../../core/constants/room_type_codes.dart';
import 'guest_room_detail_premium.dart';
import '../../../shared/presentation/widgets/animated_heart_button.dart';
import '../../../../core/components/responsive_file_image.dart';
import 'dart:async' show unawaited;

// ─── Sky Blue Brand Colors ───────────────────────────────────────
const _skyLight = Color(0xFF9CCBFF); // sky-blue-300 (for accents)

class GuestFeedView extends ConsumerStatefulWidget {
  final bool isGuest;
  final bool isKycVerified;
  final List<dynamic> rooms;
  final NumberFormat currencyFmt;
  final Set<String> wishlistIds;
  final double bottomInset;
  final bool isLoadingMore;
  final Function(String) onToggleWishlist;
  final Function(dynamic) onChatPressed;
  final VoidCallback? onLoadMore;

  const GuestFeedView({
    super.key,
    required this.isGuest,
    required this.isKycVerified,
    required this.rooms,
    required this.currencyFmt,
    required this.wishlistIds,
    this.bottomInset = 0.0,
    this.isLoadingMore = false,
    required this.onToggleWishlist,
    required this.onChatPressed,
    this.onLoadMore,
  });

  @override
  ConsumerState<GuestFeedView> createState() => _GuestFeedViewState();
}

class _GuestFeedViewState extends ConsumerState<GuestFeedView> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // NOTE: Empty state được xử lý ở parent (GuestMarketplaceScreen._buildEmptyState)
    // theo theme sáng (Sky Blue). Tránh render empty-state tối trùng lặp ở đây.
    if (widget.rooms.isEmpty) {
      return const SizedBox.shrink();
    }

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      onPageChanged: (index) {
        unawaited(HapticFeedback.selectionClick());
        // Trigger loadMore when near end of list (3 items before end)
        final threshold = widget.rooms.length - 3;
        if (index >= threshold && index >= 0) {
          widget.onLoadMore?.call();
        }
      },
      itemCount: widget.rooms.length + (widget.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Show skeleton loader as the very last item while loading
        if (index == widget.rooms.length) {
          return _buildLoadMoreSkeleton();
        }
        final room = widget.rooms[index];
        final roomId =
            room['id']?.toString() ?? room['roomId']?.toString() ?? '';
        return GuestFeedItem(
          isGuest: widget.isGuest,
          isKycVerified: widget.isKycVerified,
          room: room,
          currencyFmt: widget.currencyFmt,
          isLiked: widget.wishlistIds.contains(roomId),
          bottomInset: widget.bottomInset,
          onLike: () {
            widget.onToggleWishlist(roomId);
          },
          onAction: () => widget.onChatPressed(room),
        );
      },
    );
  }

  Widget _buildLoadMoreSkeleton() {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Shimmering background
          const _ShimmerBox(
            width: double.infinity,
            height: double.infinity,
            borderRadius: 0,
          ),
          // Content overlay skeleton
          const Positioned(
            left: 16,
            right: 80,
            bottom: 100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(width: 200, height: 22, borderRadius: 6),
                SizedBox(height: 10),
                _ShimmerBox(width: 150, height: 18, borderRadius: 6),
                SizedBox(height: 10),
                _ShimmerBox(width: 260, height: 14, borderRadius: 6),
                SizedBox(height: 6),
                _ShimmerBox(width: 200, height: 14, borderRadius: 6),
              ],
            ),
          ),
          // Action buttons skeleton (right side)
          Positioned(
            right: 12,
            bottom: 100,
            child: Column(
              children: List.generate(
                4,
                (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: _ShimmerBox(width: 50, height: 50, borderRadius: 25),
                ),
              ),
            ),
          ),
          // Loading indicator
          const Center(
            child: CupertinoActivityIndicator(color: Colors.white, radius: 14),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer Box helper ────────────────────────────────────────────────────────
class _ShimmerBox extends StatefulWidget {
  final double width, height, borderRadius;
  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.borderRadius,
  });
  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    unawaited(_ctrl.repeat(reverse: true));
    _anim = Tween<double>(
      begin: 0.1,
      end: 0.25,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

class GuestFeedItem extends StatefulWidget {
  final bool isGuest;
  final bool isKycVerified;
  final dynamic room;
  final NumberFormat currencyFmt;
  final bool isLiked;
  final double bottomInset;
  final VoidCallback onLike;
  final VoidCallback onAction;
  final List<dynamic>? previewImages; // Used for preview mode to maintain order
  final bool isPreview;

  const GuestFeedItem({
    super.key,
    required this.isGuest,
    required this.isKycVerified,
    required this.room,
    required this.currencyFmt,
    required this.isLiked,
    required this.bottomInset,
    required this.onLike,
    required this.onAction,
    this.previewImages,
    this.isPreview = false,
  });

  @override
  State<GuestFeedItem> createState() => _GuestFeedItemState();
}

class _GuestFeedItemState extends State<GuestFeedItem>
    with TickerProviderStateMixin {
  late AnimationController _heartController;
  late Animation<double> _heartScale;
  Offset _heartPosition = Offset.zero;
  int _currentImgIndex = 0;

  double _overscrollOffset = 0.0;
  bool _showLongPressHint = true;
  bool _isUIHidden = false;

  late AnimationController _sheetAnimController;
  late AnimationController _staggerController;
  final ValueNotifier<double> _dragExtentNotifier = ValueNotifier<double>(0.0);

  List<String> _images = [];

  // Palette-derived background colors (used by _updatePalette)
  Color? _bgColor1;
  Color? _bgColor2;

  /// Phân tích palette màu từ ảnh để tạo nền gradient hài hoà.
  /// Kết quả được dùng để tô nền blur phía sau ảnh (xem _buildImageWithBlur).
  Future<void> _updatePalette(
    dynamic source, {
    bool isFile = false,
    bool isMemory = false,
  }) async {
    try {
      ImageProvider provider;
      if (isFile) {
        provider = getResponsiveFileImageProvider((source as File).path);
      } else if (isMemory) {
        provider = MemoryImage(base64Decode(source as String));
      } else {
        provider = NetworkImage(source as String);
      }
      final palette = await PaletteGenerator.fromImageProvider(
        provider,
        maximumColorCount: 20,
      );
      if (mounted) {
        setState(() {
          if (palette.dominantColor != null) {
            final hsl1 = HSLColor.fromColor(palette.dominantColor!.color);
            _bgColor1 = hsl1
                .withSaturation((hsl1.saturation * 0.2).clamp(0.0, 1.0))
                .withLightness((hsl1.lightness * 0.35).clamp(0.0, 1.0))
                .toColor();
            final color2 =
                palette.vibrantColor?.color ??
                palette.mutedColor?.color ??
                palette.dominantColor!.color;
            final hsl2 = HSLColor.fromColor(color2);
            _bgColor2 = hsl2
                .withSaturation((hsl2.saturation * 0.2).clamp(0.0, 1.0))
                .withLightness((hsl2.lightness * 0.35).clamp(0.0, 1.0))
                .toColor();
          }
        });
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    unawaited(_staggerController.forward());
    if (widget.previewImages != null && widget.previewImages!.isNotEmpty) {
      final first = widget.previewImages!.first;
      if (first is File) {
        unawaited(_updatePalette(first, isFile: true));
      } else {
        unawaited(_updatePalette(first));
      }
    } else {
      _images = _extractImages();
      if (_images.isNotEmpty) {
        unawaited(_updatePalette(_images.first));
      }
    }

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showLongPressHint = false);
    });
    _sheetAnimController = BottomSheet.createAnimationController(this);
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _heartScale = TweenSequence([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.5,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.5,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_heartController);
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _heartController.dispose();
    _sheetAnimController.dispose();
    _dragExtentNotifier.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    final totalImages = widget.previewImages?.length ?? _extractImages().length;
    if (notification is ScrollUpdateNotification) {
      if (notification.metrics.pixels > notification.metrics.maxScrollExtent &&
          _currentImgIndex == totalImages - 1) {
        setState(() {
          _overscrollOffset =
              notification.metrics.pixels -
              notification.metrics.maxScrollExtent;
        });
      } else if (notification.metrics.pixels <=
              notification.metrics.maxScrollExtent &&
          _overscrollOffset > 0) {
        setState(() {
          _overscrollOffset = 0.0;
        });
      }
    } else if (notification is OverscrollNotification) {
      if (notification.overscroll > 0 && _currentImgIndex == totalImages - 1) {
        setState(() {
          _overscrollOffset += notification.overscroll;
        });
      }
    } else if (notification is ScrollEndNotification) {
      if (_overscrollOffset > 60) {
        _openDetailSheet();
        if (mounted) setState(() => _overscrollOffset = 0.0);
      } else {
        if (mounted) setState(() => _overscrollOffset = 0.0);
      }
    }
    return false;
  }

  void _showQuickActionMenu() {
    unawaited(HapticFeedback.mediumImpact());
    unawaited(
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        elevation: 0,
        builder: (context) => Container(
          padding: const EdgeInsets.only(
            top: 12,
            bottom: 24,
            left: 16,
            right: 16,
          ),
          decoration: const BoxDecoration(
            color: AppTheme.kSurface1Light,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tùy chọn nhanh',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.kTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildBottomSheetItem(
                icon: CupertinoIcons.doc_text_fill,
                label: 'Xem chi tiết phòng',
                onTap: () {
                  Navigator.pop(context);
                  _openDetailSheet();
                },
              ),
              _buildBottomSheetItem(
                icon: widget.isLiked
                    ? CupertinoIcons.heart_fill
                    : CupertinoIcons.heart,
                label: widget.isLiked ? 'Bỏ lưu phòng' : 'Lưu phòng',
                onTap: () {
                  Navigator.pop(context);
                  widget.onLike();
                },
              ),
              _buildBottomSheetItem(
                icon: CupertinoIcons.chat_bubble_fill,
                label: 'Liên hệ chủ nhà',
                onTap: () {
                  Navigator.pop(context);
                  widget.onAction();
                },
              ),
              _buildBottomSheetItem(
                icon: CupertinoIcons.arrow_turn_up_right,
                label: 'Chia sẻ',
                onTap: () {
                  Navigator.pop(context);
                  unawaited(HapticFeedback.lightImpact());
                },
              ),
              const Divider(height: 16),
              _buildBottomSheetItem(
                icon: CupertinoIcons.exclamationmark_triangle_fill,
                label: 'Báo cáo / Không quan tâm',
                isDestructive: true,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetailSheet() {
    _dragExtentNotifier.value = 1.0; // initial extent – fullscreen
    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        barrierColor: Colors.black.withValues(alpha: 0.5),
        transitionAnimationController: _sheetAnimController,
        enableDrag: false,
        builder: (context) {
          return NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              _dragExtentNotifier.value = notification.extent;
              return false;
            },
            child: DraggableScrollableSheet(
              initialChildSize: 1.0,
              minChildSize: 0.0,
              maxChildSize: 1.0,
              snap: true,
              snapSizes: const [1.0],
              builder: (context, scrollController) {
                return GuestRoomDetailPremiumBottomSheet(
                  room: widget.room,
                  scrollController: scrollController,
                  isPreview: widget.isPreview,
                  isFullScreen: true,
                );
              },
            ),
          );
        },
      ).whenComplete(() {
        _dragExtentNotifier.value = 0.0;
      }),
    );
  }

  Widget _buildBottomSheetItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.redAccent : AppTheme.kAccentColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDoubleTap(TapDownDetails details) {
    unawaited(HapticFeedback.heavyImpact());
    setState(() {
      _heartPosition = details.localPosition;
    });
    unawaited(_heartController.forward(from: 0));
    if (!widget.isLiked) {
      widget.onLike();
    }
  }

  double _extractPrice(dynamic p) {
    if (p == null) return 0;
    if (p is num) return p.toDouble();
    if (p is String) {
      return double.tryParse(p.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    }
    return 0.0;
  }

  /// BUGFIX (data): parse ngày an toàn — trả null thay vì ném FormatException
  /// khi chuỗi ngày sai định dạng (vd `promotionEndDate` rác từ backend).
  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    if (s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  /// BUGFIX (data): coerce an toàn sang int — tránh `as num?` ném TypeError
  /// khi backend trả String ("12") hoặc giá trị không phải số.
  int _asInt(dynamic raw) {
    if (raw == null) return 0;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString().trim()) ?? 0;
  }

  /// Trả về list ảnh từ nhiều field khác nhau của backend
  List<String> _extractImages() {
    String resolveUrl(String url) {
      return ImageUrlHelper.buildUrl(url) ?? '';
    }

    // Thử field 'images' (List)
    final imagesRaw = widget.room['images'];
    if (imagesRaw is List && imagesRaw.isNotEmpty) {
      final urls = imagesRaw
          .map((e) => resolveUrl(e.toString()))
          .where((e) => e.isNotEmpty)
          .toList();
      if (urls.isNotEmpty) return urls;
    }
    // Thử field 'roomImages' (JSON string hoặc List từ backend Room.java)
    final roomImagesRaw = widget.room['roomImages'];
    if (roomImagesRaw is List && roomImagesRaw.isNotEmpty) {
      final urls = roomImagesRaw
          .map((e) => resolveUrl(e.toString()))
          .where((e) => e.isNotEmpty)
          .toList();
      if (urls.isNotEmpty) return urls;
    }
    if (roomImagesRaw is String && roomImagesRaw.isNotEmpty) {
      if (roomImagesRaw.trim().startsWith('[')) {
        try {
          final decoded = jsonDecode(roomImagesRaw) as List;
          final urls = decoded
              .map((e) => resolveUrl(e.toString()))
              .where((e) => e.isNotEmpty)
              .toList();
          if (urls.isNotEmpty) return urls;
        } catch (_) {}
      } else {
        final urls = roomImagesRaw
            .split(',')
            .map((e) => resolveUrl(e.trim()))
            .where((e) => e.isNotEmpty)
            .toList();
        if (urls.isNotEmpty) return urls;
      }
    }
    // Fallback: ảnh chi tiết phòng (WC / ban công / cửa sổ / bếp / đồng hồ)
    final featureRaw =
        widget.room['featurePhotos'] ?? _deepInfo(widget.room)['featurePhotos'];
    if (featureRaw is List && featureRaw.isNotEmpty) {
      final urls = featureRaw
          .map((e) => resolveUrl(e.toString()))
          .where((e) => e.isNotEmpty)
          .toList();
      if (urls.isNotEmpty) return urls;
    }
    return [];
  }

  Widget _buildErrorImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.kBrandLight, AppTheme.kBrandDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.building_2_fill,
              color: Colors.white.withValues(alpha: 0.5),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              'Hình ảnh không khả dụng',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageLayer(
    dynamic source, {
    bool isFile = false,
    bool isMemory = false,
    BoxFit fit = BoxFit.cover,
  }) {
    if (isFile) {
      return ResponsiveFileImage(
        source as File,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildErrorImage(),
      );
    }
    if (isMemory) {
      return Image.memory(
        base64Decode(source as String),
        fit: fit,
        errorBuilder: (_, __, ___) => _buildErrorImage(),
      );
    }
    return CachedNetworkImage(
      imageUrl: ImageUrlHelper.buildUrl(source as String) ?? source,
      fit: fit,
      memCacheWidth: 600,
      errorWidget: (_, __, ___) => _buildErrorImage(),
      placeholder: (_, __) => const Center(child: CupertinoActivityIndicator()),
    );
  }

  void _showPromoDetails(
    BuildContext context,
    dynamic roomData,
    double originalPrice,
    double discountedPrice,
  ) {
    final fmt = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    final discountAmount = originalPrice - discountedPrice;
    final pct = ((discountAmount / originalPrice) * 100).round();
    final promoEnd = roomData['promotionEndDate'] ?? roomData['promotionEnd'];
    final promoDesc = roomData['promotionDescription'];

    unawaited(
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.kSurface1Light,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1469B1FF),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF2F8FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.ticket_fill,
                    color: AppTheme.kBrand,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chi tiết Khuyến mãi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.kTextPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.kBackgroundLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Giá gốc:',
                            style: TextStyle(
                              color: AppTheme.kTextSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            fmt.format(originalPrice),
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Mức giảm:',
                            style: TextStyle(
                              color: AppTheme.kTextSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '-${fmt.format(discountAmount)} ($pct%)',
                            style: const TextStyle(
                              color: CupertinoColors.systemRed,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(color: Color(0xFFE2E8F0), height: 1),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Thực tế:',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            fmt.format(discountedPrice),
                            style: const TextStyle(
                              color: AppTheme.kBrand,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // BUGFIX (data): `DateTime.parse` ném FormatException nếu
                // `promotionEndDate` là chuỗi sai định dạng → sập dialog khuyến
                // mãi. Nay parse an toàn, chỉ hiện dòng hạn chót khi hợp lệ.
                if (_parseDate(promoEnd) != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        CupertinoIcons.clock_fill,
                        size: 16,
                        color: CupertinoColors.systemOrange,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Hạn chót: ${DateFormat('dd/MM/yyyy').format(_parseDate(promoEnd)!)}',
                          style: const TextStyle(
                            color: CupertinoColors.systemOrange,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (promoDesc != null && promoDesc.toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      promoDesc.toString(),
                      style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          backgroundColor: const Color(0xFFF1F5F9),
                        ),
                        child: const Text(
                          'Đóng',
                          style: TextStyle(
                            color: AppTheme.kTextSecondary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close the dialog
                          _openDetailSheet(); // Open the room details sheet
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          backgroundColor: AppTheme.kBrand,
                          elevation: 0,
                        ),
                        child: const Text(
                          'Xem phòng',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
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
      ),
    );
  }

  Widget _buildImageWithBlur(
    dynamic source, {
    bool isFile = false,
    bool isMemory = false,
  }) {
    // Nền gradient lấy từ palette của ảnh (nếu đã phân tích xong),
    // fallback về lớp phủ đen mờ để đảm bảo độ tương phản.
    final hasPalette = _bgColor1 != null && _bgColor2 != null;
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Lớp nền là chính ảnh đó, phóng to full màn hình (BoxFit.cover)
        _buildImageLayer(
          source,
          isFile: isFile,
          isMemory: isMemory,
          fit: BoxFit.cover,
        ),

        // 2. Làm mờ ảnh nền và thêm lớp phủ màu
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              decoration: hasPalette
                  ? BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [_bgColor1!, _bgColor2!],
                      ),
                    )
                  : null,
              color: hasPalette ? null : Colors.black.withValues(alpha: 0.55),
            ),
          ),
        ),

        // 3. Lớp ảnh chính nguyên bản (BoxFit.contain)
        _buildImageLayer(
          source,
          isFile: isFile,
          isMemory: isMemory,
          fit: BoxFit.contain,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final combinedImages = widget.previewImages != null
        ? List<dynamic>.from(widget.previewImages!)
        : List<dynamic>.from(_extractImages());

    final bool hasPromo = widget.room['hasPromotion'] == true;
    final price = _extractPrice(
      hasPromo
          ? (widget.room['promotionPrice'] ?? widget.room['price'])
          : widget.room['price'],
    );
    final originalPrice = _extractPrice(
      widget.room['originalPrice'] ?? widget.room['price'],
    );
    final double area = (_extractPrice(widget.room['floorArea']) > 0)
        ? _extractPrice(widget.room['floorArea'])
        : (_extractPrice(widget.room['area']) > 0)
        ? _extractPrice(widget.room['area'])
        : _extractPrice(widget.room['size']);

    // ─── Địa chỉ ────────────────────────────────────────────────
    String address =
        widget.room['address'] ??
        widget.room['region'] ??
        widget.room['district'] ??
        '';
    if (address.isEmpty) {
      address = 'Chưa có thông tin địa chỉ';
    } else if (!widget.isKycVerified) {
      address = address.replaceAll(
        RegExp(r'^(Số\s*)?[0-9]+[0-9A-Za-z/]*\s*,?\s*'),
        '***, ',
      );
    }

    // ─── Tiêu đề: Ưu tiên TIÊU ĐỀ TIN ĐĂNG (postTitle/title), rồi mới tới roomName ─
    // BUGFIX: DTO công khai trả `postTitle` (và alias `title`). Trước đây chỉ đọc
    // `title`/`roomName` → tiêu đề bài đăng bị hiển thị sai thành tên phòng.
    String rawRoomName = widget.room['roomName']?.toString() ?? '';
    final dynamic rawPostTitle =
        widget.room['postTitle'] ??
        (widget.room['post'] != null ? widget.room['post']['title'] : null) ??
        widget.room['title'];
    String title =
        (rawPostTitle != null && rawPostTitle.toString().trim().isNotEmpty)
        ? rawPostTitle.toString().trim()
        : rawRoomName.isNotEmpty
        ? (rawRoomName.length <= 4 && double.tryParse(rawRoomName) != null
              ? 'Phòng $rawRoomName'
              : rawRoomName)
        : widget.room['name']?.toString().isNotEmpty == true
        ? widget.room['name'].toString()
        : 'Phòng trọ cho thuê';

    // ─── Subtitle & Tags ────────────────────────
    String subtitle = '';

    // Auto-calculate from lat/lng
    // BUGFIX: fallback sang toạ độ TOÀ NHÀ (branchLatitude/branchLongitude hoặc
    // room['branch']['latitude']) khi phòng chưa gắn lat/lng — nếu không, "Tiện ích
    // xung quanh" ở bài đã đăng sẽ trống dù preview hiển thị đúng.
    final dynamic branchForGeo = widget.room['branch'];
    double? lat =
        double.tryParse(widget.room['latitude']?.toString() ?? '') ??
        double.tryParse(widget.room['branchLatitude']?.toString() ?? '') ??
        (branchForGeo is Map
            ? double.tryParse(branchForGeo['latitude']?.toString() ?? '')
            : null);
    double? lng =
        double.tryParse(widget.room['longitude']?.toString() ?? '') ??
        double.tryParse(widget.room['branchLongitude']?.toString() ?? '') ??
        (branchForGeo is Map
            ? double.tryParse(branchForGeo['longitude']?.toString() ?? '')
            : null);

    if (lat != null && lng != null) {
      final allPois = PoiDatabase.getAllPois();
      List<Map<String, dynamic>> nearestPois = [];
      for (var poi in allPois) {
        final dist = LocationUtils.calculateHaversineDistance(
          lat,
          lng,
          poi['lat'],
          poi['lng'],
        );
        if (dist <= 3.5) {
          nearestPois.add({'name': poi['name'], 'distance': dist});
        }
      }
      if (nearestPois.isNotEmpty) {
        // BUGFIX (data): coerce an toàn — tránh `as double`/`as String` ném
        // TypeError khi distance/name là int/null (JSON lỗi).
        double dist0(Map<String, dynamic> m) {
          final d = m['distance'];
          return d is num ? d.toDouble() : double.tryParse('$d') ?? 0.0;
        }

        nearestPois.sort((a, b) => dist0(a).compareTo(dist0(b)));
        final top3 = nearestPois
            .take(3)
            .map((e) => e['name']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
        subtitle = '📍 Gần ${top3.join(', ')}';
      }
    }

    if (subtitle.isEmpty) {
      dynamic poisData = widget.room['pois'] ?? widget.room['nearbyPlaces'];
      if (poisData != null && poisData.toString().isNotEmpty) {
        List<String> poisList = [];
        String extractPoi(dynamic e) {
          if (e is Map) return e['name']?.toString() ?? '';
          return e.toString().trim();
        }

        if (poisData is List) {
          poisList = poisData
              .map(extractPoi)
              .where((s) => s.isNotEmpty)
              .toList();
        } else if (poisData is String && poisData.trim().startsWith('[')) {
          try {
            final parsed = jsonDecode(poisData) as List;
            poisList = parsed
                .map(extractPoi)
                .where((s) => s.isNotEmpty)
                .toList();
          } catch (_) {}
        } else if (poisData is String) {
          poisList = poisData
              .split(',')
              .map((e) => e.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        }

        subtitle = poisList.isNotEmpty
            ? '📍 Gần ${poisList.take(3).join(', ')}'
            : '📍 ${poisData.toString()}';
      } else {
        final desc = widget.room['description']?.toString() ?? '';
        subtitle = desc.isNotEmpty ? desc : 'Nhấn để xem chi tiết phòng';
      }
    }

    // Extract tags
    final tags = <String>[];
    final roomType =
        widget.room['roomType']?.toString() ??
        widget.room['type']?.toString() ??
        '';
    if (roomType.isNotEmpty) tags.add(roomType);
    if (area > 0) tags.add('${area.toInt()}m²');
    final maxGuests = int.tryParse(widget.room['maxGuests']?.toString() ?? '');
    if (maxGuests != null && maxGuests > 0) tags.add('Tối đa $maxGuests người');

    return GestureDetector(
      onLongPress: () {
        setState(() {
          _isUIHidden = true;
        });
      },
      onLongPressUp: () {
        setState(() {
          _isUIHidden = false;
        });
      },
      onLongPressCancel: () {
        if (_isUIHidden) {
          setState(() {
            _isUIHidden = false;
          });
        }
      },
      onDoubleTapDown: _handleDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background for Elastic Overscroll ──────────────────────────────
          Container(
            color: const Color(0xFF1E293B), // slate-800
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: Opacity(
              opacity: (_overscrollOffset / 60).clamp(0.0, 1.0),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.chevron_left_2,
                    color: Colors.white,
                    size: 28,
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Thả tay\nxem chi tiết",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Main Card & Bottom Sheet Animation ──────────────
          AnimatedBuilder(
            animation: Listenable.merge([
              _dragExtentNotifier,
              _sheetAnimController,
            ]),
            builder: (context, child) {
              final overscrollScale =
                  1.0 -
                  (_overscrollOffset / MediaQuery.of(context).size.width).clamp(
                    0.0,
                    0.05,
                  );

              // effectiveExtent is max 1.0.
              // When sheetAnim = 1.0 and drag = 0.6 -> effectiveExtent = 0.6
              final effectiveExtent =
                  _dragExtentNotifier.value * _sheetAnimController.value;
              final sheetScale = (1.0 - effectiveExtent).clamp(0.0, 1.0);
              final uiOpacity = (1.0 - (effectiveExtent * 3)).clamp(0.0, 1.0);

              return Transform.scale(
                scale: overscrollScale,
                alignment: Alignment.centerLeft,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // ── Background Image Carousel (Cropped from top & bottom) ────────────────
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: MediaQuery.of(context).size.height * sheetScale,
                      child: ClipRRect(
                        borderRadius: sheetScale < 1.0
                            ? const BorderRadius.vertical(
                                bottom: Radius.circular(24),
                              )
                            : BorderRadius.zero,
                        child: Hero(
                          tag:
                              'room_image_${widget.room['id'] ?? widget.room['roomId']}',
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              NotificationListener<ScrollNotification>(
                                onNotification: _handleScrollNotification,
                                child: PageView.builder(
                                  physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics(),
                                  ),
                                  scrollDirection: Axis.horizontal,
                                  itemCount: combinedImages.isEmpty
                                      ? 1
                                      : combinedImages.length,
                                  onPageChanged: (idx) {
                                    setState(() => _currentImgIndex = idx);
                                    if (combinedImages.isNotEmpty) {
                                      final item = combinedImages[idx];
                                      if (item is File) {
                                        unawaited(
                                          _updatePalette(item, isFile: true),
                                        );
                                      } else {
                                        // BUGFIX (data): trước đây ép `item as String`
                                        // — nếu phần tử ảnh là Map/num (JSON lỗi) thì
                                        // ném TypeError. Ép về String an toàn.
                                        final imgUrl = item.toString();
                                        if (imgUrl.startsWith('base64:')) {
                                          unawaited(
                                            _updatePalette(
                                              imgUrl.substring(7),
                                              isMemory: true,
                                            ),
                                          );
                                        } else {
                                          unawaited(_updatePalette(imgUrl));
                                        }
                                      }
                                    }
                                  },
                                  itemBuilder: (context, idx) {
                                    if (combinedImages.isEmpty) {
                                      return _buildImageWithBlur(
                                        'https://images.unsplash.com/photo-1555854877-bab0e564b8d5',
                                      );
                                    }
                                    final item = combinedImages[idx];
                                    if (item is File) {
                                      return _buildImageWithBlur(
                                        item,
                                        isFile: true,
                                      );
                                    }
                                    // BUGFIX (data): ép `item as String` ném
                                    // TypeError nếu phần tử ảnh không phải String.
                                    final imgUrl = item.toString();
                                    if (imgUrl.startsWith('base64:')) {
                                      return _buildImageWithBlur(
                                        imgUrl.substring(7),
                                        isMemory: true,
                                      );
                                    }
                                    return _buildImageWithBlur(imgUrl);
                                  },
                                ),
                              ),
                              // Gradient: top-to-bottom dark
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.0),
                                        Colors.black.withValues(alpha: 0.15),
                                        Colors.black.withValues(alpha: 0.80),
                                      ],
                                      stops: const [0.35, 0.65, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── UI Overlays (fade out when bottom sheet slides up) ──────
                    Positioned.fill(
                      child: Opacity(
                        opacity: uiOpacity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // ── Double-tap heart ───────────────────────────────────────
                            Positioned(
                              left: _heartPosition.dx - 50,
                              top: _heartPosition.dy - 50,
                              child: AnimatedBuilder(
                                animation: _heartController,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _heartScale.value,
                                    child: Opacity(
                                      opacity: _heartController.value < 0.8
                                          ? 1.0
                                          : (1.0 -
                                                    (_heartController.value -
                                                            0.8) *
                                                        5)
                                                .clamp(0.0, 1.0),
                                      child: const Icon(
                                        CupertinoIcons.heart_fill,
                                        color: Colors.redAccent,
                                        size: 100,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            // ── Main Bottom Content ────────────────────────────────
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: _isUIHidden ? 0.0 : 1.0,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    if (_isUIHidden) return;
                                    _openDetailSheet();
                                  },
                                  onLongPress: () {
                                    if (_isUIHidden) return;
                                    _showQuickActionMenu();
                                  },
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      16,
                                      0,
                                      80,
                                      24 + widget.bottomInset,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // ── Image dot indicators ───────────────────────────────────
                                        if (combinedImages.length > 1)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 16,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: List.generate(
                                                    combinedImages.length,
                                                    (i) => AnimatedContainer(
                                                      duration: const Duration(
                                                        milliseconds: 250,
                                                      ),
                                                      margin:
                                                          const EdgeInsets.only(
                                                            right: 6,
                                                          ),
                                                      width:
                                                          _currentImgIndex == i
                                                          ? 20
                                                          : 6,
                                                      height: 4,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            _currentImgIndex ==
                                                                i
                                                            ? _skyLight
                                                            : Colors.white
                                                                  .withValues(
                                                                    alpha: 0.4,
                                                                  ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              2,
                                                            ),
                                                        boxShadow: const [
                                                          BoxShadow(
                                                            color:
                                                                Colors.black26,
                                                            blurRadius: 2,
                                                            offset: Offset(
                                                              0,
                                                              1,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                if (_currentImgIndex ==
                                                    combinedImages.length - 1)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 8,
                                                        ),
                                                    child: Text(
                                                      'Vuốt ảnh cuối để xem chi tiết ➔',
                                                      style: TextStyle(
                                                        color: Colors.white
                                                            .withValues(
                                                              alpha: 0.9,
                                                            ),
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        shadows: const [
                                                          Shadow(
                                                            blurRadius: 4,
                                                            color: Colors.black,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),

                                        // ── Discount Badge ─────────────────────────────────
                                        SlideTransition(
                                          position:
                                              Tween<Offset>(
                                                begin: const Offset(0, 0.2),
                                                end: Offset.zero,
                                              ).animate(
                                                CurvedAnimation(
                                                  parent: _staggerController,
                                                  curve: const Interval(
                                                    0.0,
                                                    0.5,
                                                    curve: Curves.easeOutCubic,
                                                  ),
                                                ),
                                              ),
                                          child: FadeTransition(
                                            opacity: CurvedAnimation(
                                              parent: _staggerController,
                                              curve: const Interval(
                                                0.0,
                                                0.5,
                                                curve: Curves.easeIn,
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (hasPromo &&
                                                    originalPrice > price)
                                                  GestureDetector(
                                                    onTap: () {
                                                      unawaited(
                                                        HapticFeedback.lightImpact(),
                                                      );
                                                      _showPromoDetails(
                                                        context,
                                                        widget.room,
                                                        originalPrice,
                                                        price,
                                                      );
                                                    },
                                                    child: Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                            bottom: 8,
                                                          ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 4,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            const LinearGradient(
                                                              colors: [
                                                                AppTheme
                                                                    .kBrandLight,
                                                                AppTheme
                                                                    .kBrandDeep,
                                                              ],
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              20,
                                                            ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          const Icon(
                                                            CupertinoIcons
                                                                .ticket_fill,
                                                            color: Colors.white,
                                                            size: 12,
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Text(
                                                            () {
                                                              if (originalPrice <=
                                                                      0 ||
                                                                  originalPrice <=
                                                                      price) {
                                                                return '';
                                                              }
                                                              final pct =
                                                                  ((originalPrice -
                                                                              price) /
                                                                          originalPrice *
                                                                          100)
                                                                      .round();
                                                              return 'Giảm $pct%';
                                                            }(),
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w800,
                                                                  letterSpacing:
                                                                      0.5,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),

                                                // ── Room Name ──────────────────────────────────────
                                                Text(
                                                  title,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.w800,
                                                    height: 1.2,
                                                    shadows: [
                                                      Shadow(
                                                        blurRadius: 12,
                                                        color: Colors.black87,
                                                        offset: Offset(0, 1),
                                                      ),
                                                    ],
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 6),

                                                // ── Price Row ──────────────────────────────────────
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .baseline,
                                                  textBaseline:
                                                      TextBaseline.alphabetic,
                                                  children: [
                                                    Text(
                                                      price > 0
                                                          ? '${widget.currencyFmt.format(price)}/tháng'
                                                          : 'Liên hệ',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 19,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        shadows: [
                                                          Shadow(
                                                            blurRadius: 8,
                                                            color:
                                                                Colors.black87,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    if (hasPromo &&
                                                        originalPrice > price)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              left: 8,
                                                            ),
                                                        child: Text(
                                                          widget.currencyFmt
                                                              .format(
                                                                originalPrice,
                                                              ),
                                                          style: TextStyle(
                                                            color: Colors.white
                                                                .withValues(
                                                                  alpha: 0.55,
                                                                ),
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            decoration:
                                                                TextDecoration
                                                                    .lineThrough,
                                                            decorationColor:
                                                                Colors.white
                                                                    .withValues(
                                                                      alpha:
                                                                          0.55,
                                                                    ),
                                                            shadows: const [
                                                              Shadow(
                                                                blurRadius: 4,
                                                                color: Colors
                                                                    .black54,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),

                                                // ── Address ────────────────────────────────────────
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      CupertinoIcons
                                                          .location_solid,
                                                      color: Colors.white,
                                                      size: 13,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        address,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          shadows: [
                                                            Shadow(
                                                              blurRadius: 6,
                                                              color: Colors
                                                                  .black87,
                                                            ),
                                                          ],
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                // ── Landmark / POI subtitle ─────────────────────────
                                                if (subtitle.isNotEmpty &&
                                                    subtitle !=
                                                        'Nhấn để xem chi tiết phòng') ...[
                                                  const SizedBox(height: 3),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        CupertinoIcons.sparkles,
                                                        color: Color(
                                                          0xFFFDE047,
                                                        ),
                                                        size: 13,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Expanded(
                                                        child: Text(
                                                          subtitle,
                                                          style: TextStyle(
                                                            color: Colors.white
                                                                .withValues(
                                                                  alpha: 0.9,
                                                                ),
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            shadows: const [
                                                              Shadow(
                                                                blurRadius: 6,
                                                                color: Colors
                                                                    .black87,
                                                              ),
                                                            ],
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                                const SizedBox(height: 8),

                                                // ── Room Specs Row ─────────────────────────────────
                                                _buildPillSpecsRow(),
                                                const SizedBox(height: 8),

                                                // ── Amenity Chips ─────────────────────────────────
                                                _buildAmenityChips(),

                                                // ── Long-press hint ───────────────────────────────
                                                if (_showLongPressHint)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 10,
                                                        ),
                                                    child: AnimatedOpacity(
                                                      duration: const Duration(
                                                        milliseconds: 500,
                                                      ),
                                                      opacity:
                                                          _showLongPressHint
                                                          ? 1.0
                                                          : 0.0,
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 14,
                                                              vertical: 6,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.black
                                                              .withValues(
                                                                alpha: 0.55,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                20,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          widget.room['badgeLabel']
                                                                  ?.toString() ??
                                                              'Ưu đãi đặc biệt',
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ), // End Column
                                          ), // End FadeTransition
                                        ), // End SlideTransition
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // ── Right Action Bar ──────────────────────────────────────
                            Positioned(
                              right: 10,
                              bottom: 40 + widget.bottomInset,
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: _isUIHidden ? 0.0 : 1.0,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildOwnerAvatar(),
                                    const SizedBox(height: 20),
                                    HeartActionButton(
                                      key: ValueKey(
                                        widget.room['id'] ??
                                            widget.room.hashCode,
                                      ),
                                      isLiked: widget.isLiked,
                                      isGuest: widget.isGuest,
                                      onTap: widget.onLike,
                                      size: 30,
                                      // BUGFIX (data): trước đây ép
                                      // `as num?` — nếu backend trả String
                                      // ("12") thì ném TypeError. Coerce an toàn.
                                      likesCount: _asInt(
                                        widget.room['wishlistCount'],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    _buildActionButton(
                                      icon: CupertinoIcons.chat_bubble_fill,
                                      color: Colors.white,
                                      label: 'Liên hệ',
                                      onTap: widget.onAction,
                                    ),
                                    const SizedBox(height: 20),
                                    _buildActionButton(
                                      icon: CupertinoIcons.arrow_turn_up_right,
                                      color: Colors.white,
                                      label: 'Chia sẻ',
                                      onTap: () => HapticFeedback.lightImpact(),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ], // End UI overlays stack children
                        ), // End Stack
                      ), // End Opacity
                    ), // End Positioned.fill
                  ], // End inner stack
                ),
              ); // End Transform.scale
            }, // End builder
          ), // End AnimatedBuilder
        ], // End outer stack
      ), // End outer GestureDetector
    ); // End Scaffold
  }

  Widget _buildOwnerAvatar() {
    final avatar = widget.room['ownerAvatar']?.toString() ?? '';
    final hasAvatar = avatar.isNotEmpty;

    return GestureDetector(
      onTap: widget.onAction, // Open chat when tapping avatar
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.5),
          color: Colors.grey[800],
          image: hasAvatar
              ? DecorationImage(image: NetworkImage(avatar), fit: BoxFit.cover)
              : null,
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: !hasAvatar
            ? const Icon(
                CupertinoIcons.person_fill,
                color: Colors.white,
                size: 22,
              )
            : null,
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 30,
            shadows: const [
              Shadow(
                blurRadius: 8,
                color: Colors.black45,
                offset: Offset(0, 2),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(blurRadius: 4, color: Colors.black87)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillStat(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95), // Semi-transparent white
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppTheme.kBrand.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.kBrand),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppTheme.kTextSecondary,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.kBrand,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Chuẩn hoá `detailedInfo` (Map hoặc JSON string) thành Map.
  Map<String, dynamic> _deepInfo(dynamic roomData) {
    dynamic di = roomData is Map ? roomData['detailedInfo'] : null;
    if (di is String && di.trim().startsWith('{')) {
      try {
        di = jsonDecode(di);
      } catch (_) {
        di = null;
      }
    }
    if (di is Map) {
      final out = <String, dynamic>{};
      di.forEach((k, v) => out[k.toString()] = v);
      return out;
    }
    return const {};
  }

  /// Đọc field: ưu tiên root, fallback `detailedInfo`.
  dynamic _pick(dynamic roomData, String key) {
    if (roomData is Map && roomData[key] != null) return roomData[key];
    return _deepInfo(roomData)[key];
  }

  static const Map<String, String> _directionLabels = {
    'DONG': 'Đông',
    'TAY': 'Tây',
    'NAM': 'Nam',
    'BAC': 'Bắc',
    'DONG_BAC': 'Đông Bắc',
    'DONG_NAM': 'Đông Nam',
    'TAY_BAC': 'Tây Bắc',
    'TAY_NAM': 'Tây Nam',
  };

  Widget _buildPillSpecsRow() {
    dynamic roomData;
    if (widget.room is Map) {
      roomData = widget.room;
    } else {
      try {
        roomData = widget.room.toJson();
      } catch (_) {
        roomData = {};
      }
    }

    final areaRaw =
        _pick(roomData, 'area') ??
        _pick(roomData, 'size') ??
        _pick(roomData, 'floorArea');
    final areaStr = areaRaw != null && areaRaw is num && areaRaw > 0
        ? '${areaRaw.toInt()} m²'
        : null;

    // DTO công khai trả MÃ canonical ở `roomType`/`roomSubType`. Dùng nguồn chân
    // lý duy nhất RoomTypeCodes để đổi MÃ → NHÃN (không hardcode map cục bộ).
    final rawRoomType =
        (_pick(roomData, 'roomType') ?? _pick(roomData, 'roomSubType'))
            ?.toString() ??
        '';
    final roomType = rawRoomType.isNotEmpty
        ? RoomTypeCodes.labelOf(rawRoomType)
        : 'Phòng trọ';

    final maxOccupants =
        _pick(roomData, 'maxOccupants') ?? _pick(roomData, 'maxGuests');
    // BUGFIX: DTO công khai trả `direction` (DONG|TAY|NAM|BAC) chứ không phải
    // `orientation` → trước đây pill "Hướng" luôn trống.
    final orientation =
        (_pick(roomData, 'orientation') ?? _pick(roomData, 'direction'))
            ?.toString() ??
        '';
    final orientationLabel =
        _directionLabels[orientation.toUpperCase()] ?? orientation;

    String restroomType = 'Khép kín';
    final bathroomType = _pick(roomData, 'bathroomType');
    if (bathroomType == 'CHUNG') {
      restroomType = 'Chung';
    } else if (bathroomType == 'RIENG') {
      restroomType = 'Khép kín';
    } else if (roomData is Map && roomData['restroomType'] != null) {
      restroomType = roomData['restroomType'].toString();
    } else if (roomData is Map && roomData['restroom'] != null) {
      restroomType = roomData['restroom'].toString();
    } else {
      final hasPrivateBathroom =
          _pick(roomData, 'hasPrivateBathroom') == true ||
          _pick(roomData, 'isSelfContained') == true;
      if (!hasPrivateBathroom && bathroomType == null) {
        restroomType = 'Chung'; // Fallback logic
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildPillStat(CupertinoIcons.house_fill, 'Loại phòng', roomType),
          const SizedBox(width: 8),
          if (areaStr != null) ...[
            _buildPillStat(
              CupertinoIcons.square_split_2x2_fill,
              'Diện tích',
              areaStr,
            ),
            const SizedBox(width: 8),
          ],
          _buildPillStat(CupertinoIcons.drop_fill, 'Vệ sinh', restroomType),
          if (maxOccupants != null &&
              maxOccupants is num &&
              maxOccupants > 0) ...[
            const SizedBox(width: 8),
            _buildPillStat(
              CupertinoIcons.person_2_fill,
              'Sức chứa',
              '${maxOccupants.toInt()} người',
            ),
          ],
          if (orientationLabel.isNotEmpty) ...[
            const SizedBox(width: 8),
            _buildPillStat(CupertinoIcons.compass, 'Hướng', orientationLabel),
          ],
        ],
      ),
    );
  }

  Widget _buildAmenityChips() {
    // Extract amenities from various possible fields (root + detailedInfo.furnitureItems)
    List<String> amenities = [];

    dynamic roomData;
    if (widget.room is Map) {
      roomData = widget.room;
    } else {
      try {
        roomData = widget.room.toJson();
      } catch (_) {
        roomData = {};
      }
    }

    dynamic raw = roomData is Map
        ? (roomData['amenities'] ??
              roomData['facilities'] ??
              roomData['features'])
        : null;
    // Fallback: nội thất cấu hình trong bước tạo phòng.
    raw ??= _pick(roomData, 'furnitureItems');
    raw ??= _pick(roomData, 'furniture');

    if (raw is List) {
      amenities = raw
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (raw is String && raw.isNotEmpty) {
      if (raw.trim().startsWith('[')) {
        try {
          final decoded = jsonDecode(raw) as List;
          amenities = decoded
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList();
        } catch (_) {
          amenities = raw
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } else {
        amenities = raw
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    // Map common amenity codes to Vietnamese labels + icons
    final Map<String, Map<String, dynamic>> amenityMap = {
      'AC': {'label': 'Điều hòa', 'icon': '❄️'},
      'AIR_CONDITIONER': {'label': 'Điều hòa', 'icon': '❄️'},
      'DIEU_HOA': {'label': 'Điều hòa', 'icon': '❄️'},
      'WASHING_MACHINE': {'label': 'Máy giặt', 'icon': '🫧'},
      'MAY_GIAT': {'label': 'Máy giặt', 'icon': '🫧'},
      'PARKING': {'label': 'Bãi xe', 'icon': '🅿️'},
      'WIFI': {'label': 'Wifi', 'icon': '📶'},
      'WATER_HEATER': {'label': 'Nóng lạnh', 'icon': '🚿'},
      'BINH_NONG_LANH': {'label': 'Bình nóng lạnh', 'icon': '🚿'},
      'KITCHEN': {'label': 'Bếp', 'icon': '🍳'},
      'TU_QUAN_AO': {'label': 'Tủ quần áo', 'icon': '🗄️'},
      'TU_LANH': {'label': 'Tủ lạnh', 'icon': '🧊'},
      'GIUONG': {'label': 'Giường', 'icon': '🛏️'},
      'BAN_LAM_VIEC': {'label': 'Bàn làm việc', 'icon': '🪑'},
      'BALCONY': {'label': 'Ban công', 'icon': '🌿'},
      'SECURITY': {'label': 'Bảo vệ', 'icon': '🔒'},
      'CAMERA': {'label': 'Camera', 'icon': '📹'},
      'ELEVATOR': {'label': 'Thang máy', 'icon': '🛗'},
      'THANG_MAY': {'label': 'Thang máy', 'icon': '🛗'},
      'PET': {'label': 'Thú cưng', 'icon': '🐾'},
      'FURNISHED': {'label': 'Nội thất', 'icon': '🛋️'},
      'NOI_THAT': {'label': 'Nội thất', 'icon': '🛋️'},
    };

    final displayChips = amenities.map((a) {
      final key = a.toUpperCase().replaceAll(' ', '_');
      final mapped = amenityMap[key] ?? amenityMap[a.toUpperCase()];
      if (mapped != null) {
        return {'icon': mapped['icon'], 'label': mapped['label']};
      }
      // Try direct match by label
      for (final entry in amenityMap.values) {
        // BUGFIX (data): `label` có thể không phải String → tránh TypeError.
        if ((entry['label']?.toString() ?? '').toLowerCase() ==
            a.toLowerCase()) {
          return {'icon': entry['icon'], 'label': entry['label']};
        }
      }
      return {'icon': '✓', 'label': a};
    }).toList();

    if (displayChips.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 28,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: displayChips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final chip = displayChips[i];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  // BUGFIX (data): tránh `as String` ném TypeError.
                  chip['icon']?.toString() ?? '',
                  style: const TextStyle(fontSize: 11),
                ),
                const SizedBox(width: 4),
                Text(
                  chip['label']?.toString() ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
