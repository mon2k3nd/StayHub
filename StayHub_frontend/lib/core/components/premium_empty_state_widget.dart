import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/theme_provider.dart';
import 'bounce_click.dart';
import 'glass_container.dart';

class PremiumEmptyStateWidget extends ConsumerWidget {
  final String title;
  final String message;
  final IconData icon;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const PremiumEmptyStateWidget({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    final primaryColor = isDark ? CupertinoColors.white : CupertinoColors.black;
    final secondaryColor = isDark
        ? AppTheme.kTextSecondaryDark
        : AppTheme.kTextSecondary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glass Morphism Icon Container
            Stack(
              alignment: Alignment.center,
              children: [
                // Glow effect behind icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.kAccentColor.withValues(alpha: 0.2),
                  ),
                ),
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.kAccentColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      color:
                          (isDark
                                  ? CupertinoColors.black
                                  : CupertinoColors.white)
                              .withValues(alpha: 0.3),
                    ),
                    child: Icon(icon, size: 50, color: AppTheme.kAccentColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: primaryColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: secondaryColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            if (buttonText != null && onButtonPressed != null)
              BounceClick(
                onPressed: onButtonPressed,
                child: GlassContainer(
                  color: AppTheme.kAccentColor,
                  borderRadius: 24,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.add,
                        color: CupertinoColors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        buttonText!,
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
