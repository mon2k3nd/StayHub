import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'dart:math' as math;
import 'glass_container.dart';
import '../theme/liquid_glass_colors.dart';
import '../theme/app_motion.dart';
import 'dart:async' show unawaited;

class LiquidGlassLoader extends StatefulWidget {
  final double size;
  final String? text;
  final Color? color;

  const LiquidGlassLoader({
    super.key,
    this.size = 60.0,
    this.text = 'Đang tải...',
    this.color,
  });

  @override
  State<LiquidGlassLoader> createState() => _LiquidGlassLoaderState();
}

class _LiquidGlassLoaderState extends State<LiquidGlassLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassContainer(
            padding: EdgeInsets.all(widget.size * 0.3),
            color: (widget.color ?? LiquidGlassColors.ownerAccent).withValues(
              alpha: 0.1,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Vòng radar xoay
                AnimatedBuilder(
                  animation: _controller,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          (widget.color ?? LiquidGlassColors.ownerAccent)
                              .withValues(alpha: 0.0),
                          (widget.color ?? LiquidGlassColors.ownerAccent)
                              .withValues(alpha: 0.6),
                          (widget.color ?? LiquidGlassColors.ownerAccent),
                        ],
                        stops: const [0.0, 0.8, 1.0],
                      ),
                    ),
                  ),
                  builder: (_, child) {
                    return Transform.rotate(
                      angle: _controller.value * 2 * math.pi,
                      child: child,
                    );
                  },
                ),
                // Lõi nhà phát sáng & đập nhịp
                AnimatedBuilder(
                  animation: _controller,
                  child: Center(
                    child: Icon(
                      CupertinoIcons.house_fill,
                      color: widget.color ?? LiquidGlassColors.ownerAccent,
                      size: widget.size * 0.4,
                    ),
                  ),
                  builder: (_, child) {
                    // Using ping-pong scale with smooth curve
                    const curve = AppMotion.smoothInOut;
                    final progress = curve.transform(
                      _controller.value <= 0.5
                          ? _controller.value * 2
                          : (1.0 - _controller.value) * 2,
                    );
                    final scale = 0.85 + progress * 0.15;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: widget.size * 0.8,
                        height: widget.size * 0.8,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (widget.color ??
                                          LiquidGlassColors.ownerAccent)
                                      .withValues(alpha: 0.4),
                              blurRadius: 10 * scale,
                              spreadRadius: 2 * scale,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          if (widget.text != null) ...[
            const SizedBox(height: 16),
            Text(
              widget.text!,
              style: const TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
