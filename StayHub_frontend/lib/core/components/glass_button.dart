import '../glass/glass_surface.dart';
import 'package:flutter/cupertino.dart';

import '../glass/glass_accessibility.dart';
import '../glass/glass_interactive.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GlassButton — legacy façade over the StayHub Glass Design System
//
// The previous implementation was a solid colour fill with a coloured glow
// shadow underneath it. That is a plastic button wearing a glass costume: the
// fill hides the backdrop, and the glow is light that the object emits rather
// than light that it bends.
//
// It is now the same optical material as everything else, at action thickness,
// with the compression behaviour that makes it feel like a physical object.
// The public API is unchanged, so every existing call site keeps working.
//
// The `color` parameter is preserved but reinterpreted. It no longer becomes a
// fill; it becomes the *tint* the glass carries and the colour of its label.
// A caller who passes the brand colour still gets a brand-coloured button — it
// is simply made of glass now instead of paint.
// ─────────────────────────────────────────────────────────────────────────────
class GlassButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;

  /// The accent colour. Applied as a faint tint in the glass and as the label
  /// colour — never as an opaque fill.
  final Color? color;

  final bool isLoading;

  const GlassButton({
    super.key,
    this.onPressed,
    required this.text,
    this.icon,
    this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final a11y = GlassAccessibility.of(context);
    final accent = color ?? AppTheme.kAccentColor;
    final enabled = !isLoading && onPressed != null;

    // A pill. Actions are the one place the fully-round radius is right,
    // because a pill reads as a discrete object rather than as a panel.
    const radius = 30.0;

    return GlassInteractive(
      enabled: enabled,
      onTap: onPressed,
      builder: (context, state) => GlassSurface(
        thickness: GlassThickness.thick,
        radius: radius,

        // An action sits close to the surface it belongs to. It lifts slightly,
        // but it is not a floating object.
        elevation: 0.6,

        reducedTransparencyColor: Color.alphaBlend(
          accent.withValues(alpha: 0.16),
          CupertinoColors.systemBackground.resolveFrom(context),
        ),
        child: Stack(
          children: [
            // The accent tint. A few percent over the glass, never a fill —
            // the material must still be visible through it.
            if (!a11y.reduceTransparency)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      color: accent.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    const CupertinoActivityIndicator(
                      color: CupertinoColors.white,
                    )
                  else ...[
                    if (icon != null) ...[
                      Icon(icon, color: CupertinoColors.white, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      text,
                      textScaler: MediaQuery.textScalerOf(context),
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
