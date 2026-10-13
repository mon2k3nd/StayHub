import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A unified renderer for the StayHub premium 3D isometric icon system.
///
/// Every icon in the app should be rendered through this widget so the whole
/// product shares one visual language: a miniature 3D scene sitting on the
/// same rounded floating platform, with identical perspective, lighting and
/// spacing.
///
/// Usage:
/// ```dart
/// AppIcon3D(
///   asset: 'assets/images/features/feat_wallet.png',
///   fallbackIcon: CupertinoIcons.money_dollar_circle_fill,
///   size: 28,
/// )
/// ```
///
/// When [asset] is `null` (or the asset fails to load) the widget gracefully
/// falls back to [fallbackIcon], which keeps every call-site safe while the
/// 3D set is rolled out across the app.
class AppIcon3D extends StatelessWidget {
  /// Path to the 3D isometric PNG, e.g. `assets/images/features/feat_home.png`.
  final String? asset;

  /// Icon shown when [asset] is null or cannot be decoded.
  final IconData? fallbackIcon;

  /// Rendered box size (width == height).
  final double size;

  /// Optional tint applied to the fallback icon only.
  final Color? color;

  /// Optional semantic label for accessibility.
  final String? semanticLabel;

  /// Optional drop shadow behind the 3D scene to lift it off the surface.
  final bool shadow;

  const AppIcon3D({
    super.key,
    this.asset,
    this.fallbackIcon,
    this.size = 28,
    this.color,
    this.semanticLabel,
    this.shadow = false,
  });

  @override
  Widget build(BuildContext context) {
    // FORCE FALLBACK TO AVOID ISOMETRIC ICONS
    final Widget child = _fallback();

    final wrapped = semanticLabel != null
        ? Semantics(label: semanticLabel, image: true, child: child)
        : child;

    if (!shadow) return wrapped;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF69B1FF).withValues(alpha: 0.18),
            blurRadius: size * 0.28,
            offset: Offset(0, size * 0.10),
          ),
        ],
      ),
      child: wrapped,
    );
  }

  Widget _fallback() {
    if (fallbackIcon == null) {
      return SizedBox(width: size, height: size);
    }
    return Icon(fallbackIcon, size: size, color: color);
  }
}

/// Convenience helper that resolves a feature icon asset path.
///
/// Keeps call-sites terse and typo-safe:
/// ```dart
/// AppIcon3D(asset: featureIcon('feat_wallet'), ...)
/// ```
String featureIcon(String name) => 'assets/images/features/$name.png';

/// Convenience helper that resolves a category icon asset path.
String categoryIcon(String name) => 'assets/images/categories/${name}_v11.png';
