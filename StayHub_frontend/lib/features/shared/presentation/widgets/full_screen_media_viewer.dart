import 'dart:async' show unawaited;
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show Clipboard, ClipboardData, HapticFeedback, KeyDownEvent, LogicalKeyboardKey;
import 'package:screen_protector/screen_protector.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/components/responsive_file_image.dart';
import '../../../../core/utils/toast_utils.dart';

/// Trình xem ảnh/video toàn màn hình đỉnh cao chuẩn Facebook / iOS Photos.
/// - Vuốt kéo ảnh xuống/lên (drag-to-dismiss) mượt mà 120 FPS không giật lag.
/// - Nhún đàn hồi (spring physics) khi thả tay.
/// - Chạm nhẹ (single tap) ẩn/hiện thanh công cụ & thông tin bài viết.
/// - Chạm đúp (double tap) phóng to 2x / trở về 1x.
/// - Hiển thị caption, nhãn ảnh, giá tiền dưới đáy kiểu Newsfeed Facebook.
class FullScreenMediaViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String heroTagPrefix;
  final List<String>? labels;
  final String? title;
  final String? subtitle;
  final ValueChanged<int>? onIndexChanged;
  final ValueChanged<double>? onDismissProgress;

  const FullScreenMediaViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.heroTagPrefix = '',
    this.labels,
    this.title,
    this.subtitle,
    this.onIndexChanged,
    this.onDismissProgress,
  });

  @override
  State<FullScreenMediaViewer> createState() => _FullScreenMediaViewerState();
}

class _FullScreenMediaViewerState extends State<FullScreenMediaViewer>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;

  // Cache video controllers
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, ChewieController> _chewieControllers = {};

  // Điều khiển ẩn/hiện UI thanh bar khi chạm vào ảnh (kiểu Facebook)
  bool _showOverlays = true;
  bool _isZoomed = false;

  // Quản lý vuốt kéo cực mượt bằng ValueNotifier (không rebuild cả cây widget)
  final ValueNotifier<double> _dragNotifier = ValueNotifier<double>(0.0);
  late final AnimationController _springController;
  Animation<double>? _springAnimation;
  DateTime _lastTapTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    unawaited(_initScreenProtector());
    _initVideoForIndex(_currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _precacheAdjacentImages(_currentIndex);
    });
  }

  void _precacheAdjacentImages(int index) {
    if (!mounted) return;
    for (final neighbor in [index - 1, index + 1]) {
      if (neighbor >= 0 && neighbor < widget.imageUrls.length) {
        final url = widget.imageUrls[neighbor];
        if (url.startsWith('http')) {
          precacheImage(CachedNetworkImageProvider(url), context);
        } else if (url.startsWith('file://') ||
            (!url.startsWith('http') && !url.startsWith('base64:'))) {
          final filePath = url.startsWith('file://')
              ? url.replaceFirst('file://', '')
              : url;
          precacheImage(FileImage(File(filePath)), context);
        }
      }
    }
  }

  Future<void> _initScreenProtector() async {
    await ScreenProtector.preventScreenshotOn();
  }

  void _initVideoForIndex(int index) {
    if (index < 0 || index >= widget.imageUrls.length) return;
    final url = widget.imageUrls[index];
    if (url.toLowerCase().endsWith('.mp4') &&
        !_videoControllers.containsKey(index)) {
      final videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(url),
      );
      _videoControllers[index] = videoPlayerController;

      unawaited(
        videoPlayerController
            .initialize()
            .then((_) {
              if (mounted) {
                setState(() {
                  _chewieControllers[index] = ChewieController(
                    videoPlayerController: videoPlayerController,
                    autoPlay: true,
                    looping: true,
                    showControls: true,
                    allowFullScreen: false,
                    materialProgressColors: ChewieProgressColors(
                      playedColor: const Color(0xFF69B1FF),
                      handleColor: const Color(0xFF69B1FF),
                      backgroundColor: Colors.white24,
                      bufferedColor: Colors.white38,
                    ),
                  );
                });
              }
            })
            .catchError((error) {
              debugPrint("Error initializing video: $error");
            }),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _springController.dispose();
    _dragNotifier.dispose();
    unawaited(ScreenProtector.preventScreenshotOff());

    for (final controller in _chewieControllers.values) {
      controller.dispose();
    }
    for (final controller in _videoControllers.values) {
      unawaited(controller.dispose());
    }

    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_isZoomed) return;
    final newY = _dragNotifier.value + details.delta.dy;
    _dragNotifier.value = newY;
    final progress = (newY.abs() / 250.0).clamp(0.0, 1.0);
    widget.onDismissProgress?.call(progress);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_isZoomed) return;
    final velocity = details.primaryVelocity ?? 0.0;
    final currentY = _dragNotifier.value;

    if (currentY.abs() > 80 || velocity.abs() > 600) {
      // Đạt ngưỡng vuốt thoát: đóng và trả về index hiện tại
      widget.onDismissProgress?.call(1.0);
      Navigator.of(context).pop(_currentIndex);
    } else {
      // Nhún đàn hồi quay về tâm 0.0
      _springAnimation = Tween<double>(begin: currentY, end: 0.0).animate(
        CurvedAnimation(parent: _springController, curve: Curves.easeOutBack),
      )..addListener(() {
          _dragNotifier.value = _springAnimation!.value;
          final progress = (_springAnimation!.value.abs() / 250.0).clamp(0.0, 1.0);
          widget.onDismissProgress?.call(progress);
        });
      _springController.forward(from: 0.0);
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isZoomed) return;
    final now = DateTime.now();
    if (now.difference(_lastTapTime).inMilliseconds < 250) return;
    _lastTapTime = now;
    final screenWidth = MediaQuery.of(context).size.width;
    final dx = details.globalPosition.dx;

    if (widget.imageUrls.length > 1) {
      if (dx < screenWidth / 2) {
        // Ấn nửa màn bên trái -> chuyển sang ảnh bên trái
        if (_currentIndex > 0) {
          unawaited(HapticFeedback.selectionClick());
          _pageController.previousPage(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          );
          return;
        }
      } else {
        // Ấn nửa màn bên phải -> chuyển sang ảnh bên phải
        if (_currentIndex < widget.imageUrls.length - 1) {
          unawaited(HapticFeedback.selectionClick());
          _pageController.nextPage(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          );
          return;
        }
      }
    }

    // Nếu chỉ có 1 ảnh hoặc bấm khi đã ở ảnh đầu/cuối: chuyển đổi ẩn/hiện thanh bar
    _toggleOverlays();
  }

  void _toggleOverlays() {
    setState(() {
      _showOverlays = !_showOverlays;
    });
  }

  Future<void> _shareCurrentImage() async {
    if (_currentIndex < 0 || _currentIndex >= widget.imageUrls.length) return;
    unawaited(HapticFeedback.mediumImpact());
    final url = widget.imageUrls[_currentIndex];
    final text = [
      if (widget.title != null && widget.title!.isNotEmpty) widget.title!,
      if (widget.subtitle != null && widget.subtitle!.isNotEmpty) widget.subtitle!,
      'Ảnh: $url',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ToastUtils.show(context, 'Đã sao chép liên kết ảnh & thông tin phòng');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLabel = (widget.labels != null &&
            _currentIndex < widget.labels!.length &&
            widget.labels![_currentIndex].isNotEmpty)
        ? widget.labels![_currentIndex]
        : null;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            if (_currentIndex > 0) {
              unawaited(HapticFeedback.selectionClick());
              _pageController.previousPage(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
              );
              return KeyEventResult.handled;
            }
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            if (_currentIndex < widget.imageUrls.length - 1) {
              unawaited(HapticFeedback.selectionClick());
              _pageController.nextPage(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
              );
              return KeyEventResult.handled;
            }
          } else if (event.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(context).pop(_currentIndex);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: ValueListenableBuilder<double>(
        valueListenable: _dragNotifier,
        builder: (context, dragY, child) {
          final dragProgress = (dragY.abs() / 250.0).clamp(0.0, 1.0);
          final bgAlpha = (1.0 - dragProgress).clamp(0.0, 1.0);
          final imageScale = (1.0 - (dragY.abs() / 1400.0)).clamp(0.78, 1.0);
          final overlayAlpha = (_showOverlays ? (1.0 - dragProgress * 3.0) : 0.0)
              .clamp(0.0, 1.0);

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Nền đen sâu (chạm vào nền cũng đóng viewer)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(_currentIndex),
                  child: Container(
                    color: Colors.black.withValues(alpha: bgAlpha),
                  ),
                ),
              ),

              // 2. Tầng ảnh vuốt kéo & lướt trang
              Positioned.fill(
                child: GestureDetector(
                  onTapUp: _handleTapUp,
                  onVerticalDragUpdate: _onVerticalDragUpdate,
                  onVerticalDragEnd: _onVerticalDragEnd,
                  child: Transform.translate(
                    offset: Offset(0, dragY),
                    child: Transform.scale(
                      scale: imageScale,
                      child: PageView.builder(
                        controller: _pageController,
                        physics: _isZoomed
                            ? const NeverScrollableScrollPhysics()
                            : const BouncingScrollPhysics(),
                        onPageChanged: (index) {
                          setState(() {
                            _currentIndex = index;
                            for (final controller in _videoControllers.values) {
                              if (controller.value.isPlaying) {
                                unawaited(controller.pause());
                              }
                            }
                          });
                          widget.onIndexChanged?.call(index);
                          _initVideoForIndex(index);
                          _precacheAdjacentImages(index);
                        },
                        itemCount: widget.imageUrls.length,
                        itemBuilder: (context, index) {
                          final url = widget.imageUrls[index];
                          final isVideo = url.toLowerCase().endsWith('.mp4');

                          if (isVideo) {
                            final chewieController = _chewieControllers[index];
                            if (chewieController != null &&
                                chewieController
                                    .videoPlayerController
                                    .value
                                    .isInitialized) {
                              return Center(
                                child: Chewie(controller: chewieController),
                              );
                            } else {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF69B1FF),
                                ),
                              );
                            }
                          }

                          Widget imageWidget;
                          if (url.startsWith('base64:')) {
                            try {
                              imageWidget = Image.memory(
                                base64Decode(url.substring(7)),
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                                errorBuilder: (ctx, err, stack) => const Center(
                                  child: Icon(
                                    CupertinoIcons.exclamationmark_triangle,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              );
                            } catch (e) {
                              imageWidget = const Center(
                                child: Icon(
                                  CupertinoIcons.exclamationmark_triangle,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              );
                            }
                          } else if (url.startsWith('file://') ||
                              (!url.startsWith('http') &&
                                  !url.startsWith('base64:'))) {
                            final filePath = url.startsWith('file://')
                                ? url.replaceFirst('file://', '')
                                : url;
                            imageWidget = ResponsiveFileImage(
                              File(filePath),
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.contain,
                              errorBuilder: (ctx, err, stack) => const Center(
                                child: Icon(
                                  CupertinoIcons.exclamationmark_triangle,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            );
                          } else {
                            imageWidget = CachedNetworkImage(
                              imageUrl: url,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                              memCacheWidth: 1600,
                              errorWidget: (ctx, err, stack) => const Center(
                                child: Icon(
                                  CupertinoIcons.exclamationmark_triangle,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                              placeholder: (_, __) => const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF69B1FF),
                                ),
                              ),
                            );
                          }

                          return _ZoomableImage(
                            onTapUp: _handleTapUp,
                            onZoomChanged: (zoomed) {
                              if (zoomed != _isZoomed) {
                                setState(() => _isZoomed = zoomed);
                              }
                            },
                            child: Hero(
                              tag: '${widget.heroTagPrefix}$url',
                              flightShuttleBuilder: (
                                flightContext,
                                animation,
                                flightDirection,
                                fromHeroContext,
                                toHeroContext,
                              ) {
                                final curved = CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.fastOutSlowIn,
                                  reverseCurve: Curves.easeInCubic,
                                );
                                return AnimatedBuilder(
                                  animation: curved,
                                  builder: (context, child) {
                                    final t = curved.value;
                                    final r = Radius.circular(32.0 * (1.0 - t));
                                    return ClipRRect(
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: r,
                                        bottomRight: r,
                                      ),
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Opacity(
                                            opacity: (1.0 - t).clamp(0.0, 1.0),
                                            child: fromHeroContext.widget,
                                          ),
                                          Opacity(
                                            opacity: t.clamp(0.0, 1.0),
                                            child: toHeroContext.widget,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                              child: SizedBox.expand(child: imageWidget),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // 3. Top Header Bar kiểu Story & Facebook (Story Progress Bars + Pill Glass + Share Button)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: overlayAlpha,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Story Progress Bars (Dải vạch chỉ số ảnh kiểu tin Story)
                          if (widget.imageUrls.length > 1) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Row(
                                children: List.generate(
                                  widget.imageUrls.length,
                                  (index) {
                                    final isActive = index == _currentIndex;
                                    final isPassed = index < _currentIndex;
                                    return Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          unawaited(HapticFeedback.selectionClick());
                                          _pageController.animateToPage(
                                            index,
                                            duration: const Duration(milliseconds: 280),
                                            curve: Curves.easeOutCubic,
                                          );
                                        },
                                        behavior: HitTestBehavior.opaque,
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                            right: index == widget.imageUrls.length - 1 ? 0 : 4.0,
                                          ),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 250),
                                            height: 3.0,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(2.0),
                                              color: isActive
                                                  ? const Color(0xFF69B1FF)
                                                  : isPassed
                                                      ? Colors.white.withValues(alpha: 0.8)
                                                      : Colors.white.withValues(alpha: 0.28),
                                              boxShadow: isActive
                                                  ? [
                                                      BoxShadow(
                                                        color: const Color(0xFF69B1FF).withValues(alpha: 0.6),
                                                        blurRadius: 4,
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],

                          // Thanh điều khiển kính mờ (Close - Counter - Share)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Nút đóng hình tròn Liquid Glass viền mờ cao cấp
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(_currentIndex),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                    child: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(alpha: 0.14),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.28),
                                          width: 1.0,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF69B1FF).withValues(alpha: 0.12),
                                            blurRadius: 16,
                                            spreadRadius: -2,
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          CupertinoIcons.xmark,
                                          color: CupertinoColors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Huy hiệu đếm ảnh kiểu Liquid Glass Pill
                              ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      color: Colors.white.withValues(alpha: 0.14),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.28),
                                        width: 1.0,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF69B1FF).withValues(alpha: 0.12),
                                          blurRadius: 16,
                                          spreadRadius: -2,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      '${_currentIndex + 1} / ${widget.imageUrls.length}',
                                      style: const TextStyle(
                                        color: CupertinoColors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Nút chia sẻ Liquid Glass đối xứng
                              GestureDetector(
                                onTap: _shareCurrentImage,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                    child: Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(alpha: 0.14),
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.28),
                                          width: 1.0,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF69B1FF).withValues(alpha: 0.12),
                                            blurRadius: 16,
                                            spreadRadius: -2,
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          CupertinoIcons.share,
                                          color: CupertinoColors.white,
                                          size: 18,
                                        ),
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
                ),
              ),

              // 4. Bottom Info Scrim kiểu lướt tin Facebook với Liquid Glass Platter
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: overlayAlpha,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Color(0xD9000000),
                          Color(0x66000000),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 28, 16, 24),
                    child: SafeArea(
                      top: false,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.38),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.16),
                                width: 0.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF69B1FF).withValues(alpha: 0.08),
                                  blurRadius: 24,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Tag ảnh Liquid Glass (Phòng, Ban công, WC...)
                                if (currentLabel != null) ...[
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF69B1FF).withValues(alpha: 0.22),
                                      borderRadius: BorderRadius.circular(50),
                                      border: Border.all(
                                        color: const Color(0xFF69B1FF).withValues(alpha: 0.5),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      currentLabel,
                                      style: const TextStyle(
                                        color: Color(0xFF69B1FF),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],

                                // Tiêu đề phòng
                                if (widget.title != null && widget.title!.isNotEmpty)
                                  Text(
                                    widget.title!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                    ),
                                  ),

                                // Giá phòng hoặc địa chỉ phụ
                                if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.subtitle!,
                                    style: const TextStyle(
                                      color: Color(0xFF69B1FF),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      ),
    );
  }
}

class _ZoomableImage extends StatefulWidget {
  final Widget child;
  final ValueChanged<TapUpDetails>? onTapUp;
  final ValueChanged<bool>? onZoomChanged;

  const _ZoomableImage({
    required this.child,
    this.onTapUp,
    this.onZoomChanged,
  });

  @override
  State<_ZoomableImage> createState() => _ZoomableImageState();
}

class _ZoomableImageState extends State<_ZoomableImage>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late final AnimationController _resetController;
  Animation<Matrix4>? _resetAnimation;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onScaleChanged);
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  void _onScaleChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final isZoomed = scale > 1.02;
    if (isZoomed != _isZoomed) {
      setState(() {
        _isZoomed = isZoomed;
      });
      widget.onZoomChanged?.call(isZoomed);
    }
  }

  /// Khi người dùng thả tay ra, ảnh tự động đàn hồi về kích thước 1x và vị trí ban đầu
  void _springBack() {
    final currentMatrix = _transformationController.value;
    if (currentMatrix == Matrix4.identity()) return;

    _resetAnimation = _Matrix4Tween(
      begin: currentMatrix,
      end: Matrix4.identity(),
    ).animate(
      CurvedAnimation(
        parent: _resetController,
        curve: Curves.easeOutBack,
      ),
    )..addListener(() {
        _transformationController.value = _resetAnimation!.value;
      });

    _resetController.forward(from: 0.0).then((_) {
      if (mounted) {
        _transformationController.value = Matrix4.identity();
        setState(() {
          _isZoomed = false;
        });
        widget.onZoomChanged?.call(false);
      }
    });
  }

  @override
  void dispose() {
    _resetController.dispose();
    _transformationController.removeListener(_onScaleChanged);
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: widget.onTapUp,
      // Đã bỏ hoàn toàn kích đúp (onDoubleTap) theo yêu cầu người dùng
      child: InteractiveViewer(
        transformationController: _transformationController,
        panEnabled: _isZoomed,
        scaleEnabled: true,
        minScale: 1.0,
        maxScale: 3.5,
        clipBehavior: Clip.none,
        onInteractionStart: (details) {
          if (_resetController.isAnimating) {
            _resetController.stop();
          }
        },
        onInteractionEnd: (details) {
          // Thả 2 ngón tay ra: ảnh đàn hồi mượt mà trở lại vị trí ban đầu
          _springBack();
        },
        child: SizedBox.expand(child: widget.child),
      ),
    );
  }
}

/// Tween nội suy Matrix4 mượt mà cho hiệu ứng đàn hồi thu phóng
class _Matrix4Tween extends Tween<Matrix4> {
  _Matrix4Tween({super.begin, super.end});

  @override
  Matrix4 lerp(double t) {
    final b = begin ?? Matrix4.identity();
    final e = end ?? Matrix4.identity();
    final result = Matrix4.zero();
    for (int i = 0; i < 16; i++) {
      result.storage[i] = b.storage[i] + (e.storage[i] - b.storage[i]) * t;
    }
    return result;
  }
}
