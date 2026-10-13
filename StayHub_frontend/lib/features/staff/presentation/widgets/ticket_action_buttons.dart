import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/liquid_glass_colors.dart';
import '../../../../core/enums/ticket_status.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../../ticket/data/models/ticket_model.dart';
import 'dart:async' show unawaited;

class TicketActionButtons extends ConsumerWidget {
  final TicketModel ticket;
  final bool isLoading;
  final VoidCallback onStartProcessing;
  final Function(int, bool) onShowReasonModal;
  final Function(int) onShowCompleteModal;
  final Function(int) onApproveTicket;

  const TicketActionButtons({
    super.key,
    required this.ticket,
    required this.isLoading,
    required this.onStartProcessing,
    required this.onShowReasonModal,
    required this.onShowCompleteModal,
    required this.onApproveTicket,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    final isOwner = ref.read(authProvider).value?.role == 'OWNER';
    final status = TicketStatus.fromString(ticket.status);

    if (status == TicketStatus.newTicket) {
      if (isOwner) {
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: CupertinoColors.systemBlue,
                borderRadius: BorderRadius.circular(14),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.person_badge_plus,
                      color: CupertinoColors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Phân công Nhân viên',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                onPressed: () {
                  Navigator.pop(context); // Go back to list
                  unawaited(
                    showCupertinoDialog(
                      context: context,
                      builder: (c) => CupertinoAlertDialog(
                        title: const Text('Phân công'),
                        content: const Text(
                          'Tính năng Phân công đang được hoàn thiện. Vui lòng thực hiện thao tác này tại phiên bản sau hoặc trên Web Admin.',
                        ),
                        actions: [
                          CupertinoDialogAction(
                            child: const Text('OK'),
                            onPressed: () => Navigator.pop(c),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    color: CupertinoColors.systemRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.systemRed,
                      ),
                    ),
                    onPressed: () => onShowReasonModal(ticket.id, true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    color: CupertinoColors.systemGreen,
                    borderRadius: BorderRadius.circular(14),
                    child: const Text(
                      'Tự xử lý & Xong',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.white,
                      ),
                    ),
                    onPressed: () => onShowCompleteModal(ticket.id),
                  ),
                ),
              ],
            ),
          ],
        );
      }
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: CupertinoColors.systemOrange,
              borderRadius: BorderRadius.circular(14),
              onPressed: onStartProcessing,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.play_circle_fill,
                    color: CupertinoColors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Tiếp nhận & Xử lý',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (status == TicketStatus.assigned) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: CupertinoColors.systemOrange,
              borderRadius: BorderRadius.circular(14),
              onPressed: onStartProcessing,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.play_circle_fill,
                    color: CupertinoColors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Bắt đầu xử lý',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (status == TicketStatus.processing) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: LiquidGlassColors.staffAccent,
              borderRadius: BorderRadius.circular(14),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: CupertinoColors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Báo cáo hoàn thành',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              onPressed: () => onShowCompleteModal(ticket.id),
            ),
          ),
        ],
      );
    }

    if (status == TicketStatus.completed ||
        status == TicketStatus.pendingOwnerReview) {
      if (isOwner) {
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: CupertinoColors.systemBlue,
                borderRadius: BorderRadius.circular(14),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.check_mark_circled_solid,
                      color: CupertinoColors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Phê duyệt hoàn thành',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                onPressed: () => onApproveTicket(ticket.id),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: CupertinoColors.systemRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                child: const Text(
                  'Từ chối nghiệm thu',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemRed,
                  ),
                ),
                onPressed: () => onShowReasonModal(ticket.id, false),
              ),
            ),
          ],
        );
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: CupertinoColors.systemBlue.withValues(alpha: 0.3),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoActivityIndicator(
              radius: 10,
            ), // Cải thiện UX ở đây (dòng 943 cũ)
            SizedBox(width: 8),
            Text(
              'Đang chờ chủ nhà nghiệm thu',
              style: TextStyle(
                color: CupertinoColors.systemBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (status == TicketStatus.closed) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.checkmark_seal_fill,
              color: CupertinoColors.systemGreen,
            ),
            SizedBox(width: 8),
            Text(
              'Sự cố đã xử lý xong',
              style: TextStyle(
                color: CupertinoColors.systemGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
