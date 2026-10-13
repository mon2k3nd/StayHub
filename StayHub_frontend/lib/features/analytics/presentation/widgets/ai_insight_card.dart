import 'package:flutter/cupertino.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/owner_analytics_model.dart';
import '../../../../core/components/glass_container.dart';
import '../../../../core/components/bounce_click.dart';

class AiInsightCard extends StatelessWidget {
  final ActionableInsight insight;

  const AiInsightCard({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    final isWarning = insight.type == 'WARNING';
    final color = isWarning
        ? CupertinoColors.systemOrange
        : AppTheme.kAccentColor;
    final icon = isWarning
        ? CupertinoIcons.exclamationmark_triangle_fill
        : CupertinoIcons.lightbulb_fill;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      color: color.withValues(alpha: 0.05),
      border: Border.all(color: color.withValues(alpha: 0.2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                isWarning ? 'CẢNH BÁO' : 'CƠ HỘI TĂNG TRƯỞNG',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight.message,
            style: const TextStyle(
              color: CupertinoColors.black,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          BounceClick(
            onPressed: () {
              // Action triggers logic
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    insight.actionText,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    CupertinoIcons.arrow_right,
                    color: CupertinoColors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
