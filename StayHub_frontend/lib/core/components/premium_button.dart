import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'bounce_click.dart';
import 'dart:async' show unawaited;

class PremiumButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final Color? color;
  final LinearGradient? gradient;
  final bool isLoading;
  final double borderRadius;
  final bool isSecondary;

  const PremiumButton({
    super.key,
    this.onPressed,
    required this.text,
    this.icon,
    this.color,
    this.gradient,
    this.isLoading = false,
    this.borderRadius = 16.0,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSecondary
        ? CupertinoColors.systemGrey6
        : (color ?? AppTheme.kAccentColor);

    final textColor = isSecondary
        ? CupertinoColors.black
        : CupertinoColors.white;
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;

    return BounceClick(
      onPressed: () {
        if (isLoading || onPressed == null) return;
        unawaited(HapticFeedback.lightImpact());
        onPressed!();
      },
      child: Container(
        decoration: BoxDecoration(
          color: gradient == null ? bgColor : null,
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: isSecondary
              ? null
              : [
                  BoxShadow(
                    color: (gradient != null ? AppTheme.kAccentColor : bgColor)
                        .withValues(alpha: 0.3),
                    blurRadius: 16,
                    spreadRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                ],
          border: isSecondary && isDark
              ? Border.all(color: AppTheme.kBorderColorDark, width: 1)
              : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              CupertinoActivityIndicator(color: textColor)
            else ...[
              if (icon != null) ...[
                Icon(icon, color: textColor, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
