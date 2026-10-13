import 'package:flutter/cupertino.dart';

import '../../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter/material.dart' show Colors;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:async' show unawaited;

typedef QrScanCompleteCallback = void Function(String qrData);

class EkycQrScanner extends StatefulWidget {
  final QrScanCompleteCallback onScanComplete;

  const EkycQrScanner({super.key, required this.onScanComplete});

  @override
  State<EkycQrScanner> createState() => _EkycQrScannerState();
}

class _EkycQrScannerState extends State<EkycQrScanner>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.normal,
  );

  late AnimationController _animationController;
  late Animation<double> _laserAnimation;

  bool _hasScanned = false;
  String _statusText = 'Đưa mã QR vào trong khung hình...';

  bool _isCameraReady = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    unawaited(_animationController.repeat(reverse: true));
    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Delay 600ms để đảm bảo Camera của bước trước đã được giải phóng hoàn toàn khỏi bộ nhớ (tránh xung đột phần cứng gây trắng màn hình)
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isCameraReady = true;
        });
        unawaited(_controller.start());
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    unawaited(_controller.stop());
    unawaited(_controller.dispose());
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.isNotEmpty) {
        // Vietnamese CCCD QR format is typically split by '|'
        if (rawValue.contains('|')) {
          setState(() {
            _hasScanned = true;
            _statusText = 'Đã quét thành công mã QR!';
          });

          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              widget.onScanComplete(rawValue);
            }
          });
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Camera Feed
        Positioned.fill(
          child: _isCameraReady
              ? MobileScanner(controller: _controller, onDetect: _onDetect)
              : const Center(child: CupertinoActivityIndicator(radius: 20)),
        ),

        // Dark Overlay outside the frame
        Positioned.fill(
          child: Container(
            decoration: const ShapeDecoration(
              shape: _QrScannerOverlayShape(
                borderColor: LiquidGlassColors.adminAccent,
                borderWidth: 3,
                overlayColor: Color(0x99000000),
                borderRadius: 16,
              ),
            ),
          ),
        ),

        // Laser Animation inside the frame
        Positioned.fill(
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final boxSize = constraints.maxWidth * 0.7; // Square for QR
              final topOffset = (constraints.maxHeight - boxSize) / 2;

              return Stack(
                children: [
                  AnimatedBuilder(
                    animation: _laserAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: topOffset + (_laserAnimation.value * boxSize),
                        left: (constraints.maxWidth - boxSize) / 2,
                        width: boxSize,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: CupertinoColors.activeGreen,
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.activeGreen.withValues(
                                  alpha: 0.8,
                                ),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),

        // Text Guidance
        Positioned(
          top: 60,
          left: 20,
          right: 20,
          child: Column(
            children: [
              const Text(
                'Quét Mã QR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Quét mã QR trên mặt trước CCCD để đối chiếu',
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.activeGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: CupertinoColors.activeGreen.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!_hasScanned)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CupertinoActivityIndicator(
                          radius: 6,
                          color: CupertinoColors.activeGreen,
                        ),
                      ),
                    if (!_hasScanned) const SizedBox(width: 8),
                    Text(
                      _statusText,
                      style: const TextStyle(
                        color: CupertinoColors.activeGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;

  const _QrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 1.0,
    this.overlayColor = Colors.black54,
    this.borderRadius = 0,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    var outer = Path()..addRect(rect);
    var size = rect.width * 0.7; // Square
    var center = Offset(rect.width / 2, rect.height / 2);
    var innerRect = Rect.fromCenter(center: center, width: size, height: size);
    var inner = Path()
      ..addRRect(
        RRect.fromRectAndRadius(innerRect, Radius.circular(borderRadius)),
      );
    return Path.combine(PathOperation.difference, outer, inner);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    var paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(getOuterPath(rect), paint);

    var size = rect.width * 0.7;
    var center = Offset(rect.width / 2, rect.height / 2);
    var innerRect = Rect.fromCenter(center: center, width: size, height: size);

    var borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, Radius.circular(borderRadius)),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return _QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      overlayColor: overlayColor,
      borderRadius: borderRadius * t,
    );
  }
}
