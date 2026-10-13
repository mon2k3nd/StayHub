import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/liquid_glass_colors.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../application/rental_request_notifier.dart';
import 'dart:async' show unawaited;

class OwnerPendingRequestsModal extends ConsumerStatefulWidget {
  const OwnerPendingRequestsModal({super.key});

  @override
  ConsumerState<OwnerPendingRequestsModal> createState() =>
      _OwnerPendingRequestsModalState();
}

class _OwnerPendingRequestsModalState
    extends ConsumerState<OwnerPendingRequestsModal> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: const BoxDecoration(
        color: AppTheme.kBackgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'Yêu cầu thuê phòng mới',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final requests = ref.watch(pendingRequestsProvider);
                if (requests.isEmpty) {
                  return const Center(child: Text('Không có yêu cầu mới.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 20),
                  itemCount: requests.length,
                  itemBuilder: (itemCtx, index) {
                    final req = requests[index];
                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Transform.translate(
                          // Staggered slide up based on index
                          offset: Offset(
                            0,
                            50 * (1 - value) + (index * 10 * (1 - value)),
                          ),
                          child: Opacity(opacity: value, child: child),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Dismissible(
                          key: ValueKey(req['id']),
                          direction: DismissDirection.horizontal,
                          onUpdate: (details) {
                            if (details.progress > 0.4 &&
                                details.progress < 0.45) {
                              unawaited(HapticFeedback.lightImpact());
                            }
                          },
                          confirmDismiss: (direction) async {
                            unawaited(HapticFeedback.heavyImpact());
                            if (direction == DismissDirection.startToEnd) {
                              // Approve
                              // BUGFIX (data): trước đây ép `req['id'] as int`
                              // — nếu id là String/null thì ném TypeError và
                              // thao tác duyệt không chạy. Coerce an toàn.
                              final reqId = req['id'] is num
                                  ? (req['id'] as num).toInt()
                                  : int.tryParse(req['id']?.toString() ?? '');
                              if (reqId == null) return false;
                              final success = await ref
                                  .read(pendingRequestsProvider.notifier)
                                  .approveRequest(reqId);
                              if (context.mounted) {
                                if (success) {
                                  ToastUtils.show(context, 'Đã duyệt yêu cầu!');
                                  return true;
                                } else {
                                  ToastUtils.show(
                                    context,
                                    'Kết nối gián đoạn. Vui lòng thử lại!',
                                    isError: true,
                                  );
                                }
                              }
                              return false;
                            } else {
                              // Reject
                              final confirm = await showCupertinoDialog<bool>(
                                context: context,
                                builder: (dlgCtx) => CupertinoAlertDialog(
                                  title: const Text('Từ chối yêu cầu'),
                                  content: Text(
                                    'Bạn có chắc muốn từ chối yêu cầu thuê phòng của ${req['tenantName']}?',
                                  ),
                                  actions: [
                                    CupertinoDialogAction(
                                      child: const Text('Hủy'),
                                      onPressed: () =>
                                          Navigator.pop(dlgCtx, false),
                                    ),
                                    CupertinoDialogAction(
                                      isDestructiveAction: true,
                                      child: const Text('Từ chối'),
                                      onPressed: () =>
                                          Navigator.pop(dlgCtx, true),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true && mounted) {
                                final reqId = req['id'] is num
                                    ? (req['id'] as num).toInt()
                                    : int.tryParse(req['id']?.toString() ?? '');
                                if (reqId == null) return false;
                                final success = await ref
                                    .read(pendingRequestsProvider.notifier)
                                    .rejectRequest(reqId);
                                if (context.mounted) {
                                  if (success) {
                                    ToastUtils.show(
                                      context,
                                      'Đã từ chối yêu cầu!',
                                    );
                                    return true;
                                  } else {
                                    ToastUtils.show(
                                      context,
                                      'Lỗi khi từ chối. Vui lòng thử lại!',
                                      isError: true,
                                    );
                                  }
                                }
                              }
                              return false;
                            }
                          },
                          background: Container(
                            color: CupertinoColors.systemGreen.withValues(
                              alpha: 0.8,
                            ),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            child: const Icon(
                              CupertinoIcons.check_mark,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          secondaryBackground: Container(
                            color: CupertinoColors.systemRed.withValues(
                              alpha: 0.8,
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              CupertinoIcons.trash,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppTheme.kBrandDeep.withValues(
                                      alpha: 0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.person_solid,
                                    color: AppTheme.kBrandDeep,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${req['roomName']} - ${req['tenantName']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Trạng thái: ${req['status']}\nGửi lúc: ${req['submittedAt']}',
                                        style: const TextStyle(
                                          color: Color(0xFF6B7280),
                                          fontSize: 13,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  CupertinoIcons.chevron_left_2,
                                  color: Color(0xFFD1D5DB),
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  CupertinoIcons.chevron_right_2,
                                  color: Color(0xFFD1D5DB),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
