import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';
import 'bounce_click.dart';

class PremiumCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;
  final bool hasGlow;
  final Color? backgroundColor;
  final LinearGradient? gradient;

  const PremiumCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 24.0,
    this.hasGlow = false,
    this.backgroundColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final defaultBg = isDark ? CupertinoColors.black : CupertinoColors.white;
    final shadows = isDark
        ? AppTheme.kPremiumShadowDark
        : AppTheme.kPremiumShadowLight;

    Widget cardContent = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? (backgroundColor ?? defaultBg) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: hasGlow ? shadows : null,
        border: isDark && gradient == null
            ? Border.all(
                color: AppTheme.kBorderColorDark.withValues(alpha: 0.5),
                width: 0.5,
              )
            : null,
      ),
      child: child,
    );

    if (onTap != null) {
      return BounceClick(onPressed: onTap, child: cardContent);
    }

    return cardContent;
  }
}
