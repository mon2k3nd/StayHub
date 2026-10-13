import 'package:flutter/cupertino.dart';

import 'liquid_animated_background.dart';

class LiquidBackground extends StatelessWidget {
  final Widget child;
  final Color? colors;

  const LiquidBackground({super.key, required this.child, this.colors});

  @override
  Widget build(BuildContext context) {
    return LiquidAnimatedBackground(child: child);
  }
}
