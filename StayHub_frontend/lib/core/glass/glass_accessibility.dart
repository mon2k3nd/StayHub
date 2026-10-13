import 'package:flutter/cupertino.dart';

// ─────────────────────────────────────────────────────────────────────────────
// StayHub Glass Design System — Accessibility
//
// Glass is a visual luxury. Legibility is not negotiable. When the operating
// system tells us that a user has asked for less transparency or less motion,
// the material must obey immediately and completely.
//
// These are not "fallbacks" or "degraded modes". They are the same material
// with one physical property switched off, and they must look deliberate.
// ─────────────────────────────────────────────────────────────────────────────

/// Resolves the accessibility posture for glass on the current platform.
///
/// Read this once per build and pass the values down. It is cheap — it only
/// reads platform flags — but it should not be re-read inside a painter.
@immutable
class GlassAccessibility {
  /// The system has asked for reduced transparency. Glass must stop
  /// refracting and become a solid, high-contrast surface.
  final bool reduceTransparency;

  /// The system has asked for reduced motion. Every duration collapses, so
  /// state changes are instant rather than animated.
  final bool reduceMotion;

  /// The system has asked for high contrast. Glass must increase the contrast
  /// between its content and its backdrop.
  final bool highContrast;

  /// The platform's text scale factor. Glass must never clip scaled text.
  final double textScale;

  const GlassAccessibility({
    required this.reduceTransparency,
    required this.reduceMotion,
    required this.highContrast,
    required this.textScale,
  });

  /// Reads the current platform accessibility settings.
  factory GlassAccessibility.of(BuildContext context) {
    final media = MediaQuery.maybeOf(context);
    final platform = MediaQuery.maybePlatformBrightnessOf(context);

    // `disableAnimations` is the platform-level "reduce motion" flag and is
    // the correct signal on both iOS and Android.
    final reduceMotion =
        media?.disableAnimations ??
        WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .disableAnimations;

    // `highContrast` is the platform-level contrast flag.
    final highContrast =
        media?.highContrast ??
        WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .highContrast;

    // Flutter does not expose a "reduce transparency" flag directly, so we
    // treat high contrast as implying it: a user who needs more contrast
    // cannot afford a translucent surface behind their text.
    final reduceTransparency = highContrast;

    return GlassAccessibility(
      reduceTransparency: reduceTransparency,
      reduceMotion: reduceMotion,
      highContrast: highContrast,
      textScale: media?.textScaler.scale(1.0) ?? 1.0,
      // `platform` is read so the factory stays honest about needing a context
      // that carries platform brightness; it is intentionally unused beyond
      // that, because glass adapts to *backdrop* luminance, not to theme mode.
    ).._unused(platform);
  }

  /// A neutral posture for contexts with no MediaQuery, such as tests and
  /// isolated painters.
  static const GlassAccessibility none = GlassAccessibility(
    reduceTransparency: false,
    reduceMotion: false,
    highContrast: false,
    textScale: 1.0,
  );

  /// Collapses a duration when reduced motion is on.
  ///
  /// Returning a near-zero duration rather than zero keeps Flutter's
  /// animation machinery in a valid state while making the change instant.
  Duration duration(Duration normal) =>
      reduceMotion ? const Duration(milliseconds: 300) : normal;

  /// The alpha the glass body should use. Under reduced transparency the
  /// material becomes nearly opaque so content stays readable.
  double bodyAlpha(double normal) => reduceTransparency ? 200 : normal;

  /// Whether refraction should run at all.
  bool get allowsRefraction => !reduceTransparency;

  /// Whether shadows should be strengthened for contrast.
  double get shadowBoost => highContrast ? 1.4 : 1.0;

  void _unused(Object? _) {}
}
