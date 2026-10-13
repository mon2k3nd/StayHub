import '../glass/glass_surface.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/theme_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GlassContainer — legacy façade over the StayHub Glass Design System
//
// This widget used to be its own glassmorphism implementation: a uniform
// BackdropFilter blur, a flat tint fill, a painted gradient sheen and a
// SweepGradient stroke border. That is the exact vocabulary the design system
// forbids — a blur card with a white outline.
//
// It is now a thin façade. It keeps its original constructor so that the many
// existing call sites across the app continue to compile and render without a
// single edit, but it delegates every optical decision to [OpticalGlass], which
// is the one place glass is defined.
//
// The mapping is deliberate:
//
//   blur 24  → GlassThickness.regular   (the default panel)
//   blur 32+ → GlassThickness.thick     (sheets and modals)
//   blur <16 → GlassThickness.thin      (chips and inline overlays)
//
// `hasBorder` is accepted and ignored. Real glass has no border; its edge is
// produced by rim absorption. Honouring the flag would reintroduce the fake
// outline this migration exists to remove.
//
// New code should use [GlassSurface] directly. This façade exists so that
// migrating the whole application is a series of small, safe steps rather than
// one large, risky rewrite.
// ─────────────────────────────────────────────────────────────────────────────
class GlassContainer extends ConsumerWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  /// Retained for source compatibility. Ignored — the material draws its own
  /// edge through rim absorption, never through a border.
  final bool hasBorder;

  /// Retained for source compatibility. Ignored for the same reason as
  /// [hasBorder].
  final BoxBorder? border;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 22.0,
    this.blur = 24.0,
    this.color,
    this.padding,
    this.hasBorder = true,
    this.border,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The theme is still read, because the reduced-transparency fallback needs
    // to match the app's surface colour rather than the platform's.
    ref.watch(themeProvider);

    return RepaintBoundary(
      child: GlassSurface(
        thickness: _thicknessFor(blur),
        radius: borderRadius,

        // A dark theme is a dark backdrop, which lifts the glass.
        reducedTransparencyColor: color,
        child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
      ),
    );
  }

  /// Maps the legacy blur radius onto a physical thickness.
  ///
  /// This is the one place the old vocabulary and the new one meet. Blur is a
  /// symptom of thickness, not a property in its own right, so the mapping is
  /// monotonic and coarse: three bands, not a continuum.
  static GlassThickness _thicknessFor(double blur) {
    if (blur >= 30) return GlassThickness.thick;
    if (blur >= 16) return GlassThickness.regular;
    return GlassThickness.thin;
  }
}
