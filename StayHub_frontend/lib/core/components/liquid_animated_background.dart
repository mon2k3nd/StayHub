import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'dart:async' show unawaited;

class LiquidAnimatedBackground extends ConsumerStatefulWidget {
  final Widget child;

  const LiquidAnimatedBackground({super.key, required this.child});

  @override
  ConsumerState<LiquidAnimatedBackground> createState() =>
      _LiquidAnimatedBackgroundState();
}

class _LiquidAnimatedBackgroundState
    extends ConsumerState<LiquidAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    unawaited(_controller.repeat());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);
    final bgColor = isDark
        ? AppTheme.kBackgroundDark
        : AppTheme.kBackgroundLight;

    return Container(
      color: bgColor,
      child: Stack(
        children: [
          // Animated gradient orbs
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _MeshGradientPainter(_controller.value, isDark),
                size: Size.infinite,
              );
            },
          ),

          // Ultra blur layer to mix them
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              color: CupertinoColors.white.withValues(alpha: 0.1),
            ),
          ),
          // Actual content
          widget.child,
        ],
      ),
    );
  }
}

class _MeshGradientPainter extends CustomPainter {
  final double progress;
  final bool isDark;

  _MeshGradientPainter(this.progress, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

    // Orb 1 (Top Left moving in circle)
    final dx1 = size.width * 0.2 + math.cos(progress * 2 * math.pi) * 100;
    final dy1 = size.height * 0.2 + math.sin(progress * 2 * math.pi) * 100;
    paint.color = (isDark ? const Color(0xFF1B3A5C) : const Color(0xFFE3F0FF))
        .withValues(alpha: 0.7);
    canvas.drawCircle(Offset(dx1, dy1), size.width * 0.6, paint);

    // Orb 2 (Bottom Right moving in figure 8)
    final dx2 = size.width * 0.8 + math.sin(progress * 2 * math.pi) * 150;
    final dy2 = size.height * 0.8 + math.sin(progress * 4 * math.pi) * 150;
    paint.color = (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7))
        .withValues(alpha: 0.6);
    canvas.drawCircle(Offset(dx2, dy2), size.width * 0.7, paint);

    // Orb 3 (Center sweeping)
    final dx3 =
        size.width * 0.5 + math.cos(progress * 2 * math.pi + math.pi) * 200;
    final dy3 =
        size.height * 0.5 + math.sin(progress * 2 * math.pi + math.pi) * 200;
    paint.color = (isDark ? const Color(0xFF0F172A) : const Color(0xFFF3E8FF))
        .withValues(alpha: 0.8);
    canvas.drawCircle(Offset(dx3, dy3), size.width * 0.5, paint);
  }

  @override
  bool shouldRepaint(covariant _MeshGradientPainter oldDelegate) => true;
}
