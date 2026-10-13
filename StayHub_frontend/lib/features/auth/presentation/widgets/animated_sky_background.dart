import 'package:flutter/material.dart';
import 'dart:async' show unawaited;

class AnimatedSkyBackground extends StatefulWidget {
  final Widget child;
  const AnimatedSkyBackground({super.key, required this.child});

  @override
  State<AnimatedSkyBackground> createState() => _AnimatedSkyBackgroundState();
}

class _AnimatedSkyBackgroundState extends State<AnimatedSkyBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
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
    return Stack(
      children: [
        // Sky Gradient (Clear sky blue)
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF298FFF), // Sky Blue at the top
                Color(0xFF5FAEFF), // Sky Blue light
                Color(0xFFC7E2FF), // Sky Blue 200 near horizon
                Color(0xFFF2F8FF), // Sky Blue 50 at bottom
              ],
            ),
          ),
        ),
        // Moving Clouds
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _CloudPainter(_controller.value),
              size: Size.infinite,
            );
          },
        ),
        // Foreground Content
        widget.child,
      ],
    );
  }
}

class _CloudPainter extends CustomPainter {
  final double animationValue;
  _CloudPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        15.0,
      ); // Làm mềm (nhòe) mây để trông chân thực hơn

    void drawCloud(double x, double y, double scale, {double opacity = 0.65}) {
      paint.color = Colors.white.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(x, y);
      canvas.scale(scale);

      // Vẽ mây chân thực hơn bằng các hình oval và hình tròn
      canvas.drawOval(const Rect.fromLTRB(-10, -10, 50, 20), paint);
      canvas.drawCircle(const Offset(35, -20), 30, paint);
      canvas.drawCircle(const Offset(65, -5), 25, paint);
      canvas.drawCircle(const Offset(90, 10), 20, paint);
      canvas.drawCircle(const Offset(20, 15), 20, paint);
      canvas.drawCircle(const Offset(60, 15), 20, paint);

      // Fill base
      canvas.drawRect(const Rect.fromLTRB(0, 5, 85, 25), paint);
      canvas.restore();
    }

    // Cloud 1 (front, big, moving right)
    final dx1 = (animationValue * size.width * 2) - size.width;
    drawCloud(dx1, size.height * 0.12, 1.2, opacity: 0.8);

    // Cloud 2 (middle, moving left)
    // To move left, we invert the animation value
    final invertedAnim2 = 1.0 - ((animationValue * 0.8) % 1.0);
    final dx2 = (invertedAnim2 * size.width * 2) - size.width;
    drawCloud(dx2, size.height * 0.25, 0.8, opacity: 0.5);

    // Cloud 3 (back, small, moving right fast)
    final dx3 =
        ((animationValue * 1.5 + 0.4) % 1.0 * size.width * 2) - size.width;
    drawCloud(dx3, size.height * 0.05, 0.6, opacity: 0.4);

    // Cloud 4 (very back, slow moving left)
    final invertedAnim4 = 1.0 - ((animationValue * 0.4 + 0.2) % 1.0);
    final dx4 = (invertedAnim4 * size.width * 2) - size.width;
    drawCloud(dx4, size.height * 0.18, 0.5, opacity: 0.3);
  }

  @override
  bool shouldRepaint(covariant _CloudPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
