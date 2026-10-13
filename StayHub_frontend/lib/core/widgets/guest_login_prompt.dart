import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../components/bounce_click.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// GuestLoginPrompt — DRY CTA mời đăng nhập cho Guest Mode.
///
/// Dùng thống nhất cho mọi hành động bị chặn khi chưa đăng nhập
/// (xem SĐT chủ nhà, đặt phòng, eKYC, chat...). Pill-shape, Sky Blue glow.
/// ─────────────────────────────────────────────────────────────────────────────
class GuestLoginPrompt extends StatelessWidget {
  final String message;
  final String actionLabel;
  final VoidCallback onLoginTap;
  final IconData icon;
  final bool compact;

  const GuestLoginPrompt({
    super.key,
    this.message = 'Đăng nhập để xem thông tin chi tiết',
    this.actionLabel = 'Đăng nhập',
    required this.onLoginTap,
    this.icon = Icons.lock_outline,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return BounceClick(
        onPressed: onLoginTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.kSurfaceBlue,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: AppTheme.kBorderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppTheme.kBrand),
              const SizedBox(width: 8),
              Text(
                actionLabel,
                style: const TextStyle(
                  color: AppTheme.kBrand,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.kSurface1Light,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.kPremiumShadowLight,
        border: Border.all(color: AppTheme.kBorderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppTheme.kSurfaceBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.kBrand, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.kTextSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: BounceClick(
              onPressed: onLoginTap,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.kBrand,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: AppTheme.kPremiumShadowLight,
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
