import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/components/stayhub_logo_icon.dart';
import 'dart:async' show unawaited;

/// Floating Liquid-Glass bottom navigation for Guest Mode.
///
/// Sky Blue Edition: pill shape, frosted blur, brand glow on the active item.
class FloatingBottomNavBar extends ConsumerWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FloatingBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = <_NavItem>[
    _NavItem(
      CupertinoIcons.house_fill,
      CupertinoIcons.house,
      'Trang chủ',
      'assets/images/features/feat_home.png',
    ),
    _NavItem(
      CupertinoIcons.search,
      CupertinoIcons.search,
      'Tìm phòng',
      'assets/images/features/feat_search.png',
    ),
    _NavItem(
      CupertinoIcons.briefcase,
      CupertinoIcons.briefcase,
      'Chủ nhà',
      'assets/images/features/feat_investment.png',
    ),
    _NavItem(
      CupertinoIcons.person,
      CupertinoIcons.person,
      'Tôi',
      'assets/images/features/feat_profile.png',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.kSurface1Light.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: AppTheme.kBorderColor.withValues(alpha: 0.6),
            ),
            boxShadow: AppTheme.kPremiumShadowLight,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var i = 0; i < _items.length; i++)
                _buildNavItem(_items[i], currentIndex == i, i),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(_NavItem item, bool isActive, int index) {
    // Special handling for the first item (Trang chủ) to use StayHub Logo
    final isHome = index == 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (isActive) return;
        unawaited(HapticFeedback.selectionClick());
        onTap(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.kBrand : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.kBrand.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: isHome
            ? StayHubLogoIcon(
                size: 24,
                color: isActive ? Colors.white : AppTheme.kTextMuted,
              )
            : Image.asset(
                item.image,
                width: 24,
                height: 24,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                isAntiAlias: true,
                errorBuilder: (_, __, ___) => Icon(
                  isActive ? item.activeIcon : item.icon,
                  color: isActive ? Colors.white : AppTheme.kTextMuted,
                  size: 22,
                ),
              ),
      ),
    );
  }
}

class _NavItem {
  final IconData activeIcon;
  final IconData icon;
  final String label;
  final String image;
  const _NavItem(this.activeIcon, this.icon, this.label, this.image);
}
