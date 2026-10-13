import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

enum GlassThickness { thin, regular, thick }

/// A reusable optical glass panel mapped to `AdaptiveGlass` from `liquid_glass_widgets`.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final GlassThickness thickness;
  final double? radius;
  final EdgeInsetsGeometry padding;
  final double? adaptation;
  final double elevation;
  final bool castsShadow;
  final bool interactive;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final Color? reducedTransparencyColor;

  const GlassSurface({
    super.key,
    required this.child,
    this.thickness = GlassThickness.regular,
    this.radius,
    this.padding = const EdgeInsets.all(16),
    this.adaptation,
    this.elevation = 1.0,
    this.castsShadow = true,
    this.interactive = false,
    this.onTap,
    this.semanticLabel,
    this.reducedTransparencyColor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedRadius = radius ?? 24.0;
    final content = Padding(padding: padding, child: child);

    Widget result = AdaptiveGlass(
      shape: LiquidRoundedSuperellipse(borderRadius: resolvedRadius),
      settings: const LiquidGlassSettings(),
      child: content,
    );

    if (interactive || onTap != null) {
      result = GestureDetector(onTap: onTap, child: result);
    }

    if (semanticLabel != null) {
      result = Semantics(
        label: semanticLabel,
        button: onTap != null,
        container: true,
        child: result,
      );
    }

    return result;
  }
}

/// Which screen edge a [GlassBar] is docked to.
enum GlassBarEdge { top, bottom, none }

class GlassBar extends StatelessWidget {
  final Widget child;
  final GlassThickness thickness;
  final EdgeInsetsGeometry padding;
  final double? adaptation;
  final GlassBarEdge edge;

  const GlassBar({
    super.key,
    required this.child,
    this.thickness = GlassThickness.thin,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.adaptation,
    this.edge = GlassBarEdge.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return AdaptiveGlass(
      shape: const LiquidRoundedRectangle(borderRadius: 0),
      settings: const LiquidGlassSettings(),
      child: Padding(padding: padding, child: child),
    );
  }
}
