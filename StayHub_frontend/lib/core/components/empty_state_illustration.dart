import 'package:flutter/material.dart';
import '../theme/liquid_glass_colors.dart';

class EmptyStateIllustration extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? imagePath;

  const EmptyStateIllustration({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.kBackgroundLightGray.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.kAccentColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: imagePath != null
                ? Image.asset(
                    imagePath!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    isAntiAlias: true,
                    errorBuilder: (_, __, ___) =>
                        Icon(icon, size: 40, color: AppTheme.kAccentColor),
                  )
                : Icon(icon, size: 40, color: AppTheme.kAccentColor),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.kTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.kTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
