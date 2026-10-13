import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_motion.dart';
import 'glass_container.dart';
import 'dart:async' show unawaited;

class SpeedDialAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  SpeedDialAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color = CupertinoColors.activeBlue,
  });
}

class LiquidGlassSpeedDial extends StatefulWidget {
  final List<SpeedDialAction> actions;
  final IconData openIcon;
  final IconData closeIcon;
  final Color primaryColor;

  const LiquidGlassSpeedDial({
    super.key,
    required this.actions,
    this.openIcon = CupertinoIcons.add,
    this.closeIcon = CupertinoIcons.xmark,
    this.primaryColor = CupertinoColors.activeBlue,
  });

  @override
  State<LiquidGlassSpeedDial> createState() => _LiquidGlassSpeedDialState();
}

class _LiquidGlassSpeedDialState extends State<LiquidGlassSpeedDial>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    unawaited(HapticFeedback.lightImpact());
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        unawaited(_controller.forward());
      } else {
        unawaited(_controller.reverse());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      clipBehavior: Clip.none,
      children: [
        if (_isOpen)
          Positioned.fill(
            child: GestureDetector(
              onTap: _toggle,
              child: Container(
                color: CupertinoColors.black.withValues(alpha: 0.1),
              ),
            ),
          ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ...List.generate(widget.actions.length, (index) {
              final action = widget.actions[index];
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final curvedValue = CurvedAnimation(
                    parent: _controller,
                    curve: Interval(
                      0.1 * index,
                      1.0,
                      curve: AppMotion.appleSpring,
                    ),
                  ).value;

                  return Transform.scale(
                    scale: curvedValue,
                    child: Opacity(
                      opacity: curvedValue.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GlassContainer(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        borderRadius: 8,
                        child: Text(
                          action.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: CupertinoColors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          _toggle();
                          action.onTap();
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: action.color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: action.color.withValues(alpha: 0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            action.icon,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList().reversed,
            GestureDetector(
              onTap: _toggle,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _controller.value * 0.75 * 3.14159,
                    child: child,
                  );
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.primaryColor,
                        widget.primaryColor.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.primaryColor.withValues(alpha: 0.4),
                        blurRadius: 15,
                        spreadRadius: 3,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isOpen ? widget.closeIcon : widget.openIcon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
