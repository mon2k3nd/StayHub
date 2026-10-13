import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Defines an item in the [GlassBottomNavigationBar].
///
/// Supports the StayHub premium 3D isometric icon system: when [image] /
/// [activeImage] are provided the bar renders the 3D scene instead of the
/// flat [IconData] glyph. The glyphs remain as a graceful fallback.
class GlassNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String semanticLabel;

  /// Optional 3D isometric asset shown when the tab is idle.
  final String? image;

  /// Optional 3D isometric asset shown when the tab is selected.
  final String? activeImage;

  const GlassNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.semanticLabel,
    this.image,
    this.activeImage,
  });
}

/// A Telegram iOS / LINE iOS style Edge-to-Edge Glass Bottom Navigation Bar
/// powered by the liquid_glass_widgets package.
class GlassBottomNavigationBar extends StatefulWidget {
  final int currentIndex;
  final List<GlassNavItem> items;
  final ValueChanged<int> onTap;

  /// Scroll-driven collapse: sliding the bar off-screen smoothly.
  final ValueListenable<double>? collapse;

  /// Average luminance (0..1) of the content behind the bar.
  final ValueListenable<double>? backdropLuminance;

  const GlassBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.collapse,
    this.backdropLuminance,
  }) : assert(items.length > 1);

  @override
  State<GlassBottomNavigationBar> createState() =>
      _GlassBottomNavigationBarState();
}

class _GlassBottomNavigationBarState extends State<GlassBottomNavigationBar> {
  static const Color kActiveColor = Color(0xFF0A7CFF); // iOS Blue
  static const Color kInactiveColor = Color(
    0xFF8E8E93,
  ); // Lighter grey for unselected to stand out

  @override
  Widget build(BuildContext context) {
    // Map our domain items to the package's GlassTab.
    //
    // When a 3D isometric asset is available we render the miniature scene
    // (premium icon system); otherwise we fall back to the flat glyph so the
    // bar never breaks.
    final mappedTabs = widget.items.map((item) {
      final Widget idleIcon = (item.image != null && item.image!.isNotEmpty)
          ? Image.asset(
              item.image!,
              width: 30,
              height: 30,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              isAntiAlias: true,
              errorBuilder: (_, __, ___) =>
                  Icon(item.icon, size: 28, color: kInactiveColor),
            )
          : Icon(item.icon, size: 28, color: kInactiveColor);

      final Widget activeGlyph =
          (item.activeImage != null && item.activeImage!.isNotEmpty)
          ? Image.asset(
              item.activeImage!,
              width: 26,
              height: 26,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              isAntiAlias: true,
              errorBuilder: (_, __, ___) =>
                  Icon(item.activeIcon, size: 22, color: kActiveColor),
            )
          : Icon(item.activeIcon, size: 22, color: kActiveColor);

      return GlassTab(
        icon: idleIcon,
        activeIcon: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            activeGlyph,
            const SizedBox(height: 2),
            Text(
              item.label,
              style: const TextStyle(
                fontSize: 11,
                color: kActiveColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        label: null,
      );
    }).toList();

    final bar = GlassTabBar.bottom(
      tabs: mappedTabs,
      selectedIndex: widget.currentIndex,
      onTabSelected: widget.onTap,
      selectedLabelColor: kActiveColor,
      unselectedLabelColor: Colors
          .transparent, // ẩn chữ bằng cách làm trong suốt để tạo hiệu ứng mượt mà khi lướt kính
    );

    // Apply scroll-driven collapse to slide the bar off-screen smoothly
    if (widget.collapse == null) return bar;

    return ValueListenableBuilder<double>(
      valueListenable: widget.collapse!,
      builder: (context, collapseVal, child) {
        // collapseVal runs from 0.0 (visible) to 1.0 (hidden).
        return Transform.translate(
          offset: Offset(0, collapseVal * 150),
          child: child,
        );
      },
      child: bar,
    );
  }
}
