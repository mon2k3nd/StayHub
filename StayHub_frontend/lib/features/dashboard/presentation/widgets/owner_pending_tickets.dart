import 'package:flutter/cupertino.dart';

import '../../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../ticket/application/ticket_provider.dart';
import 'dart:async' show unawaited;

class OwnerPendingTickets extends ConsumerWidget {
  const OwnerPendingTickets({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(ticketProvider);

    return ticketsAsync.when(
      data: (tickets) {
        final pendingTickets = tickets
            .where((t) => t.status == 'NEW' || t.status == 'PROCESSING')
            .toList();

        if (pendingTickets.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 16,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.kError, Color(0xFFF97316)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'SỰ CỐ CẦN XỬ LÝ',
                      style: TextStyle(
                        color: Color(0xFF374151),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text(
                    'Xem tất cả',
                    style: TextStyle(
                      fontSize: 13,
                      color: LiquidGlassColors.ownerAccent,
                    ),
                  ),
                  onPressed: () => context.push('/ticket'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pendingTickets.length > 3 ? 3 : pendingTickets.length,
              itemBuilder: (context, index) {
                final t = pendingTickets[index];
                final isUrgent =
                    t.category == 'PLUMBING' || t.category == 'ELECTRICAL';

                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300 + (index * 70)),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) => Transform.translate(
                    offset: Offset(0, 16 * (1 - value)),
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () {
                        unawaited(HapticFeedback.lightImpact());
                        unawaited(
                          context.push('/ticket/ticket-detail/${t.id}'),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isUrgent
                                ? AppTheme.kError.withValues(alpha: 0.2)
                                : const Color(0xFFE5E7EB),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isUrgent
                                          ? AppTheme.kError
                                          : const Color(0xFFF97316))
                                      .withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isUrgent
                                      ? [
                                          AppTheme.kError.withValues(
                                            alpha: 0.15,
                                          ),
                                          AppTheme.kError.withValues(
                                            alpha: 0.08,
                                          ),
                                        ]
                                      : [
                                          const Color(
                                            0xFFF97316,
                                          ).withValues(alpha: 0.15),
                                          const Color(
                                            0xFFF97316,
                                          ).withValues(alpha: 0.08),
                                        ],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isUrgent
                                    ? CupertinoIcons
                                          .exclamationmark_triangle_fill
                                    : CupertinoIcons.wrench_fill,
                                color: isUrgent
                                    ? CupertinoColors.systemRed
                                    : CupertinoColors.systemOrange,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.category,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Color(0xFF1F2937),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${t.roomName ?? 'Phòng ?'} • ${t.branchName ?? 'Dãy trọ ?'}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF298FFF),
                                    AppTheme.kBrandDeep,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(100),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF298FFF,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Xử lý',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }
}
