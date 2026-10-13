import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/liquid_glass_colors.dart';
import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════
// Dark semi-transparent overlay with transparent cutout
// ══════════════════════════════════════════════════════════════
class ScannerOverlayPainter extends CustomPainter {
  final bool isSelfie;
  final bool isQr;
  final bool isBack;
  final Color borderColor;
  final double borderWidth;
  final double glowRadius;
  final Color glowColor;

  ScannerOverlayPainter({
    required this.isSelfie,
    this.isQr = false,
    this.isBack = false,
    required this.borderColor,
    required this.borderWidth,
    required this.glowRadius,
    required this.glowColor,
  });

  Rect _cutoutRect(Size size) {
    if (isSelfie) {
      final w = size.width * 0.72;
      final h = w * 1.25;
      return Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.44),
        width: w,
        height: h,
      );
    } else if (isQr) {
      // Square QR frame
      final w = size.width * 0.65;
      return Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.43),
        width: w,
        height: w,
      );
    } else {
      final w = size.width * 0.84;
      final h = w * 0.63;
      return Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.46),
        width: w,
        height: h,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final cutout = _cutoutRect(size);
    final radius = isQr ? const Radius.circular(24) : const Radius.circular(16);

    // Semi-transparent dark overlay (Dark Slate #0F172A với độ mờ 70%)
    final overlayPaint = Paint()
      ..color = AppTheme.kTextPrimary.withValues(alpha: 0.70);
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    final outerPath = Path()..addRect(fullRect);
    final cutoutPath = isSelfie
        ? (Path()..addOval(cutout))
        : (Path()..addRRect(RRect.fromRectAndRadius(cutout, radius)));
    final overlayPath = Path.combine(
      PathOperation.difference,
      outerPath,
      cutoutPath,
    );
    canvas.drawPath(overlayPath, overlayPaint);

    // QR corner accent lines
    if (isQr) {
      _drawQrCornerAccents(canvas, cutout);
      _drawQrWatermark(canvas, cutout);
    }

    // MRZ watermark for card back side
    if (isBack) {
      _drawMrzWatermark(canvas, cutout);
    }

    // Glow effect when captured
    if (glowRadius > 0) {
      final glowPaint = Paint()
        ..color = glowColor.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth + glowRadius * 0.8
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius * 1.2);
      if (isSelfie) {
        canvas.drawOval(cutout, glowPaint);
      } else {
        canvas.drawRRect(RRect.fromRectAndRadius(cutout, radius), glowPaint);
      }
    }
  }

  void _drawMrzWatermark(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    // Vẽ dải mã vạch mô phỏng ở đáy thẻ
    final mrzRect = Rect.fromLTWH(
      rect.left + 24,
      rect.bottom - 22,
      rect.width - 48,
      10,
    );
    canvas.drawRect(mrzRect, paint);
  }

  void _drawQrWatermark(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    const size = 20.0;
    // Top-left finder pattern
    canvas.drawRect(
      Rect.fromLTWH(rect.left + 32, rect.top + 32, size, size),
      paint,
    );
    // Top-right finder pattern
    canvas.drawRect(
      Rect.fromLTWH(rect.right - 32 - size, rect.top + 32, size, size),
      paint,
    );
    // Bottom-left finder pattern
    canvas.drawRect(
      Rect.fromLTWH(rect.left + 32, rect.bottom - 32 - size, size, size),
      paint,
    );
  }

  void _drawQrCornerAccents(Canvas canvas, Rect rect) {
    const len = 32.0;
    const cr = 14.0;
    const strokeW = 5.0;
    final paint = Paint()
      ..color = AppTheme.kSuccess
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;
    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left + cr, rect.top)
        ..lineTo(rect.left + cr + len, rect.top)
        ..moveTo(rect.left, rect.top + cr)
        ..lineTo(rect.left, rect.top + cr + len),
      paint,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right - cr - len, rect.top)
        ..lineTo(rect.right - cr, rect.top)
        ..moveTo(rect.right, rect.top + cr)
        ..lineTo(rect.right, rect.top + cr + len),
      paint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(rect.left, rect.bottom - cr - len)
        ..lineTo(rect.left, rect.bottom - cr)
        ..moveTo(rect.left + cr, rect.bottom)
        ..lineTo(rect.left + cr + len, rect.bottom),
      paint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(rect.right, rect.bottom - cr - len)
        ..lineTo(rect.right, rect.bottom - cr)
        ..moveTo(rect.right - cr - len, rect.bottom)
        ..lineTo(rect.right - cr, rect.bottom),
      paint,
    );
  }

  @override
  bool shouldRepaint(ScannerOverlayPainter old) =>
      old.borderColor != borderColor ||
      old.glowRadius != glowRadius ||
      old.isSelfie != isSelfie ||
      old.isQr != isQr;
}

// ══════════════════════════════════════════════════════════════
// Corner Bracket Painter – modern scanner frame
// ══════════════════════════════════════════════════════════════
class CornerBracketPainter extends CustomPainter {
  final bool isSelfie;
  final bool isQr;
  final Color color;
  final Color glowColor;
  final double glowRadius;
  final double spinValue;
  final double progressValue;

  CornerBracketPainter({
    required this.isSelfie,
    this.isQr = false,
    required this.color,
    this.glowColor = Colors.transparent,
    this.glowRadius = 0,
    this.spinValue = 0.0,
    this.progressValue = 0.0,
  });

  Rect _cutoutRect(Size size) {
    if (isSelfie) {
      final w = size.width * 0.72;
      final h = w * 1.25;
      return Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.44),
        width: w,
        height: h,
      );
    } else if (isQr) {
      final w = size.width * 0.65;
      return Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.43),
        width: w,
        height: w,
      );
    } else {
      final w = size.width * 0.84;
      final h = w * 0.63;
      return Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.46),
        width: w,
        height: h,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = _cutoutRect(size);
    const cornerLen = 26.0;
    const cornerRadius = 14.0;
    const strokeW = 3.5;

    if (isSelfie) {
      // Full oval border for selfie
      if (glowRadius > 0) {
        canvas.drawOval(
          rect,
          Paint()
            ..color = glowColor.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW + 6
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius),
        );
      }

      // Base Track
      canvas.drawOval(
        rect,
        Paint()
          ..color = Colors.white24
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW,
      );

      // Spinning Gradient (khi đang quét - stabilizing)
      if (spinValue > 0 && progressValue < 1.0) {
        final sweepGradient = SweepGradient(
          colors: [Colors.transparent, color],
          stops: const [0.0, 1.0],
          transform: GradientRotation(spinValue * 2 * 3.14159),
        );
        final spinPaint = Paint()
          ..shader = sweepGradient.createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW * 1.5
          ..strokeCap = StrokeCap.round;
        canvas.drawOval(rect, spinPaint);
      }

      // Progress Ring (khi giữ yên - progressValue)
      if (progressValue > 0) {
        final progressPaint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW * 1.5
          ..strokeCap = StrokeCap.round;
        canvas.drawArc(
          rect,
          -3.14159 / 2, // Start at top
          progressValue * 2 * 3.14159,
          false,
          progressPaint,
        );
      } else if (spinValue == 0) {
        // Default border (Idle)
        canvas.drawOval(
          rect,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeW
            ..strokeCap = StrokeCap.round,
        );
      }
      return;
    }

    // Glow pass for card mode
    if (glowRadius > 0) {
      final glowPaint = Paint()
        ..color = glowColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW + 8
        ..strokeCap = StrokeCap.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowRadius);
      _drawBrackets(canvas, rect, cornerLen, cornerRadius, glowPaint);
    }

    // Main corner brackets
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    _drawBrackets(canvas, rect, cornerLen, cornerRadius, paint);
  }

  void _drawBrackets(
    Canvas canvas,
    Rect r,
    double len,
    double cr,
    Paint paint,
  ) {
    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(r.left, r.top + cr + len)
        ..lineTo(r.left, r.top + cr)
        ..quadraticBezierTo(r.left, r.top, r.left + cr, r.top)
        ..lineTo(r.left + cr + len, r.top),
      paint,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(r.right - cr - len, r.top)
        ..lineTo(r.right - cr, r.top)
        ..quadraticBezierTo(r.right, r.top, r.right, r.top + cr)
        ..lineTo(r.right, r.top + cr + len),
      paint,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(r.left, r.bottom - cr - len)
        ..lineTo(r.left, r.bottom - cr)
        ..quadraticBezierTo(r.left, r.bottom, r.left + cr, r.bottom)
        ..lineTo(r.left + cr + len, r.bottom),
      paint,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(r.right - cr - len, r.bottom)
        ..lineTo(r.right - cr, r.bottom)
        ..quadraticBezierTo(r.right, r.bottom, r.right, r.bottom - cr)
        ..lineTo(r.right, r.bottom - cr - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(CornerBracketPainter old) =>
      old.color != color ||
      old.glowRadius != glowRadius ||
      old.isSelfie != isSelfie;
}
