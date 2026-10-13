import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../theme/app_motion.dart';
import 'dart:async' show unawaited;

class BounceClick extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double scaleFactor;
  final Duration duration;

  const BounceClick({
    super.key,
    required this.child,
    this.onPressed,
    this.scaleFactor = 0.95,
    this.duration = const Duration(milliseconds: 150),
  });

  @override
  State<BounceClick> createState() => _BounceClickState();
}

class _BounceClickState extends State<BounceClick>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.scaleFactor)
        .animate(
          CurvedAnimation(parent: _controller, curve: AppMotion.appleEaseOut),
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateTime? _lastTapTime;

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      unawaited(_controller.forward());
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      final now = DateTime.now();
      if (_lastTapTime == null ||
          now.difference(_lastTapTime!) > const Duration(milliseconds: 500)) {
        _lastTapTime = now;
        unawaited(HapticFeedback.lightImpact());
        unawaited(_controller.reverse());
        widget.onPressed!();
      } else {
        // Ignored due to debounce
        unawaited(_controller.reverse());
      }
    }
  }

  void _onTapCancel() {
    if (widget.onPressed != null) {
      unawaited(_controller.reverse());
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
    );
  }
}
