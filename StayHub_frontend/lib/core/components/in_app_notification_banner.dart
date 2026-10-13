import 'package:flutter/cupertino.dart';
import 'dart:async';
import '../theme/app_motion.dart';
import 'package:flutter/material.dart' show Material;
import 'glass_container.dart';
import '../theme/liquid_glass_colors.dart';

class InAppNotificationBanner extends StatefulWidget {
  final String title;
  final String body;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const InAppNotificationBanner({
    super.key,
    required this.title,
    required this.body,
    required this.icon,
    this.iconColor = LiquidGlassColors.tenantAccent,
    this.onTap,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String body,
    IconData icon = CupertinoIcons.bell_fill,
    Color iconColor = LiquidGlassColors.tenantAccent,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          color: const Color(0x00000000),
          child: InAppNotificationBanner(
            title: title,
            body: body,
            icon: icon,
            iconColor: iconColor,
            onTap: () {
              entry.remove();
              if (onTap != null) onTap();
            },
          ),
        ),
      ),
    );

    overlay.insert(entry);

    Future.delayed(duration, () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }

  @override
  State<InAppNotificationBanner> createState() =>
      _InAppNotificationBannerState();
}

class _InAppNotificationBannerState extends State<InAppNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _offsetAnimation =
        Tween<Offset>(begin: const Offset(0.0, -1.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _controller, curve: AppMotion.appleSpring),
        );

    unawaited(_controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.primaryDelta! < -5) {
            unawaited(
              _controller.reverse().then((_) {
                if (mounted) widget.onTap?.call();
              }),
            );
          }
        },
        onTap: widget.onTap,
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          color: CupertinoColors.white.withValues(alpha: 0.9),
          border: Border.all(color: widget.iconColor.withValues(alpha: 0.3)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: CupertinoColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.body,
                      style: const TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.systemGrey,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
