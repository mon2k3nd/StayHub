import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/liquid_glass_colors.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../data/notification_model.dart';
import 'dart:async' show unawaited;

/// A single notification row rendered as a premium Liquid Glass card.
///
/// NOTE: This widget intentionally does NOT wrap itself in a [Dismissible].
/// The parent list owns the swipe-to-delete gesture — nesting two Dismissibles
/// with the same key caused a "Duplicate GlobalKey" crash and swallowed the
/// swipe gesture (Bug fix).
class NotificationCard extends ConsumerStatefulWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  @override
  ConsumerState<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends ConsumerState<NotificationCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final notif = widget.notification;
    final typeColor = _getTypeColor(notif.type);
    final isUnread = !notif.isRead;

    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isUnread
                  ? AppTheme.kBrand.withValues(alpha: 0.14)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: isUnread ? 24 : 10,
              offset: isUnread ? const Offset(0, 8) : const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: isUnread
                    ? Colors.white.withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isUnread
                      ? Colors.white.withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: () {
                    unawaited(HapticFeedback.lightImpact());
                    widget.onTap();
                  },
                  onHighlightChanged: (isHighlighted) {
                    setState(() => _isPressed = isHighlighted);
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Type icon ──────────────────────────────────────
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isUnread
                                  ? [
                                      typeColor.withValues(alpha: 0.7),
                                      typeColor,
                                    ]
                                  : [
                                      typeColor.withValues(alpha: 0.2),
                                      typeColor.withValues(alpha: 0.05),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: isUnread
                                    ? typeColor.withValues(alpha: 0.4)
                                    : Colors.transparent,
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              _getTypeIcon(notif.type),
                              color: isUnread
                                  ? Colors.white
                                  : typeColor.withValues(alpha: 0.8),
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // ── Content ────────────────────────────────────────
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        if (isUnread)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            margin: const EdgeInsets.only(
                                              right: 8,
                                              top: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppTheme.kBrand,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppTheme.kBrand
                                                      .withValues(alpha: 0.5),
                                                  blurRadius: 6,
                                                ),
                                              ],
                                            ),
                                          ),
                                        Expanded(
                                          child: Text(
                                            notif.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontFamily: AppTheme.kFontFamily,
                                              fontSize: 15.5,
                                              fontWeight: isUnread
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                              color: isUnread
                                                  ? AppTheme.kTextPrimary
                                                  : AppTheme.kTextSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatTime(notif.createdAt),
                                    style: TextStyle(
                                      fontFamily: AppTheme.kFontFamily,
                                      fontSize: 12,
                                      color: isUnread
                                          ? AppTheme.kBrand
                                          : AppTheme.kTextMuted,
                                      fontWeight: isUnread
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                notif.content,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: AppTheme.kFontFamily,
                                  fontSize: 14,
                                  color: isUnread
                                      ? AppTheme.kTextSecondary
                                      : AppTheme.kTextMuted,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(String createdAt) {
    final createdAtDate = DateTime.tryParse(createdAt);
    if (createdAtDate == null) return '';
    final now = DateTime.now();
    final diff = now.difference(createdAtDate);
    if (diff.inDays == 0 && now.day == createdAtDate.day) {
      return DateFormat('HH:mm').format(createdAtDate);
    } else if (diff.inDays == 1 ||
        (diff.inDays == 0 && now.day != createdAtDate.day)) {
      return 'Hôm qua';
    }
    return DateFormat('dd/MM').format(createdAtDate);
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'SYSTEM_ALERT':
        return CupertinoColors.systemRed;
      case 'PROMOTION':
        return CupertinoColors.systemPurple;
      case 'SYSTEM':
        return CupertinoColors.activeBlue;
      case 'ROOM_RESERVED':
      case 'RENTAL_REQUESTED':
      case 'CONTRACT_SIGNED':
        return CupertinoColors.systemGreen;
      case 'CHECKOUT_REQUESTED':
      case 'TICKET_CREATED':
      case 'TICKET_UPDATED':
      case 'MAINTENANCE_ASSIGNED':
      case 'MAINTENANCE_RESOLVED':
        return CupertinoColors.systemOrange;
      default:
        return LiquidGlassColors.tenantAccent;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'SYSTEM_ALERT':
        return CupertinoIcons.exclamationmark_triangle_fill;
      case 'PROMOTION':
        return CupertinoIcons.gift_fill;
      case 'SYSTEM':
        return CupertinoIcons.speaker_2_fill;
      case 'ROOM_RESERVED':
      case 'RENTAL_REQUESTED':
        return CupertinoIcons.house_fill;
      case 'CONTRACT_SIGNED':
        return CupertinoIcons.doc_text_fill;
      case 'CHECKOUT_REQUESTED':
        return CupertinoIcons.square_arrow_right_fill;
      case 'TICKET_CREATED':
      case 'TICKET_UPDATED':
      case 'MAINTENANCE_ASSIGNED':
      case 'MAINTENANCE_RESOLVED':
        return CupertinoIcons.wrench_fill;
      default:
        return CupertinoIcons.bell_fill;
    }
  }
}
