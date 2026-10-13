import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async' show unawaited;

class Tilt3DWrapper extends StatefulWidget {
  final Widget child;
  final double depth;

  const Tilt3DWrapper({super.key, required this.child, this.depth = 1.0});

  @override
  State<Tilt3DWrapper> createState() => _Tilt3DWrapperState();
}

class _Tilt3DWrapperState extends State<Tilt3DWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    unawaited(_ctrl.repeat());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        // Slow circular/figure-8 floating motion
        final t = _ctrl.value * 2 * 3.14159;
        // xOffset controls rotation around X axis (up/down tilt)
        // yOffset controls rotation around Y axis (left/right tilt)
        final xOffset = math.sin(t) * 0.05 * widget.depth;
        final yOffset = math.cos(t * 0.5) * 0.05 * widget.depth;

        return Transform(
          alignment: FractionalOffset.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..rotateX(xOffset)
            ..rotateY(yOffset),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
