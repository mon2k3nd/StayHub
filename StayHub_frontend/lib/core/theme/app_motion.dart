import 'package:flutter/animation.dart';

class AppMotion {
  /// Custom Cubic curve optimized for 120Hz displays.
  /// Mimics Apple's smooth ease-out-expo behavior (stiff start, smooth tail).
  static const Curve appleEaseOut = Cubic(0.16, 1.0, 0.3, 1.0);

  /// Custom Cubic curve for bouncy/springy animations.
  static const Curve appleSpring = Cubic(0.175, 0.885, 0.32, 1.275);

  /// Smooth ease-in-out for loops and background elements.
  static const Curve smoothInOut = Cubic(0.65, 0.0, 0.35, 1.0);
}
