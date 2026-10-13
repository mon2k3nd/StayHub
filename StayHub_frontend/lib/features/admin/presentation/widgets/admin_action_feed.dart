import 'package:flutter/cupertino.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../../../core/components/glass_container.dart';
import '../../../notification/data/notification_provider.dart';
import '../../../../core/components/app_error_widget.dart';

class AdminActionFeed extends ConsumerWidget {
  final AsyncValue notificationsAsync;

  const AdminActionFeed({super.key, required this.notificationsAsync});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return notificationsAsync.when(
      data: (notifications) {
        // BUGFIX (data): tránh `as List` ném TypeError khi notifications không
        // phải List — lọc an toàn bằng whereType.
        final actions = (notifications is List ? notifications : const [])
            .whereType<dynamic>()
            .where((n) => n.isActionable == true)
            .toList();
        if (actions.isEmpty) {
          return const GlassContainer(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'Chưa có hành động nào cần xử lý',
                style: TextStyle(color: CupertinoColors.systemGrey),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildActionCard(action, ref, context);
          },
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, _) => AppErrorWidget(error: e),
    );
  }

  Widget _buildActionCard(dynamic action, WidgetRef ref, BuildContext context) {
    Map<String, dynamic> metadata = {};
    if (action.actionMetadata != null && action.actionMetadata!.isNotEmpty) {
      try {
        // BUGFIX (data): tránh gán dynamic vào Map<String, dynamic> ném
        // TypeError khi JSON không phải object.
        final decoded = jsonDecode(action.actionMetadata!);
        if (decoded is Map) metadata = Map<String, dynamic>.from(decoded);
      } catch (e) {
        debugPrint('Error decoding metadata: $e');
      }
    }

    String? imageUrl =
        metadata['cccd_front_image_url'] ?? metadata['bill_image_url'];
    final isPending = action.actionStatus == 'PENDING';

    final card = GlassContainer(
      padding: const EdgeInsets.all(16),
      border: Border.all(
        color: isPending
            ? CupertinoColors.systemOrange.withValues(alpha: 0.5)
            : CupertinoColors.systemGreen.withValues(alpha: 0.5),
        width: 1.5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPending
                    ? CupertinoIcons.exclamationmark_triangle_fill
                    : CupertinoIcons.checkmark_seal_fill,
                color: isPending
                    ? CupertinoColors.systemOrange
                    : CupertinoColors.systemGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  action.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPending
                      ? CupertinoColors.systemOrange.withValues(alpha: 0.2)
                      : CupertinoColors.systemGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  action.actionStatus,
                  style: TextStyle(
                    color: isPending
                        ? CupertinoColors.systemOrange
                        : CupertinoColors.systemGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            action.content,
            style: const TextStyle(color: Color(0xFF4B5563)),
          ),
          const SizedBox(height: 12),
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  color: CupertinoColors.systemGrey6,
                  child: const Center(
                    child: Icon(
                      CupertinoIcons.photo,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (!isPending) return card;

    // Vuốt để Duyệt (Phải sang Trái là Từ chối, Trái sang Phải là Duyệt)
    return Dismissible(
      key: ValueKey(action.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGreen,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          CupertinoIcons.check_mark,
          color: CupertinoColors.white,
          size: 32,
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: CupertinoColors.systemRed,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(
          CupertinoIcons.xmark,
          color: CupertinoColors.white,
          size: 32,
        ),
      ),
      confirmDismiss: (direction) async {
        final status = direction == DismissDirection.startToEnd
            ? 'APPROVED'
            : 'REJECTED';
        await _handleAction(action, ref, context, status);
        return true; // Xóa khỏi danh sách UI sau khi xử lý xong
      },
      child: card,
    );
  }

  Future<void> _handleAction(
    dynamic action,
    WidgetRef ref,
    BuildContext context,
    String status,
  ) async {
    Map<String, dynamic> metadata = {};
    if (action.actionMetadata != null && action.actionMetadata!.isNotEmpty) {
      try {
        metadata = jsonDecode(action.actionMetadata!);
      } catch (e) {
        debugPrint('Error decoding metadata: $e');
      }
    }

    String endpoint = metadata['endpoint'] ?? '';
    String method = metadata['method'] ?? 'POST';
    Map<String, dynamic> payload = metadata['payload'] ?? {};

    // Override payload based on status
    payload['approved'] = status == 'APPROVED';
    if (status == 'REJECTED') payload['reason'] = 'Bị từ chối bởi Admin';

    final success = await ref
        .read(notificationActionProvider)
        .executeAction(action.id, endpoint, method, payload, status);
    if (success) {
      ref.invalidate(notificationsProvider);
    }
  }
}
