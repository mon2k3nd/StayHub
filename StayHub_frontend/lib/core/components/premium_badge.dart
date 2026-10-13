import 'package:flutter/material.dart';
import '../theme/liquid_glass_colors.dart';

class PremiumBadge extends StatelessWidget {
  final String text;
  final bool isPro;

  const PremiumBadge({super.key, required this.text, this.isPro = false});

  @override
  Widget build(BuildContext context) {
    final color = isPro ? const Color(0xFFF59E0B) : AppTheme.kAccentColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
