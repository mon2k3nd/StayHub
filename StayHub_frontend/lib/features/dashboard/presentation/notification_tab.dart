import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/components/app_error_widget.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/application/auth_notifier.dart';
import '../../notification/application/notification_notifier.dart';
import '../../notification/data/notification_model.dart';
import '../../notification/presentation/notification_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'dart:async' show unawaited;

enum NotificationFilter { all, unread, read, sent, actionRequired }

class NotificationTab extends ConsumerStatefulWidget {
  const NotificationTab({super.key});

  @override
  ConsumerState<NotificationTab> createState() => _NotificationTabState();
}

class _NotificationTabState extends ConsumerState<NotificationTab> {
  NotificationFilter _selectedFilter = NotificationFilter.all;

  /// Ids optimistically removed from the list the moment a row is swiped away.
  /// The provider also removes them, but the rebuild it schedules lands on the
  /// next frame — too late for the Dismissible, which asserts the dismissed
  /// child is gone by the end of the current frame. Filtering these ids out
  /// synchronously keeps the tree consistent and prevents the assertion.
  final Set<int> _locallyDeletedIds = <int>{};

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('vi', timeago.ViMessages());
  }

  @override
  Widget build(BuildContext context) {
    final notifsAsync = ref.watch(notificationProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        CupertinoSliverNavigationBar(
          largeTitle: const Text(
            'Thông báo',
            style: TextStyle(color: CupertinoColors.black),
          ),
          backgroundColor: const Color(0x00000000),
          border: null,
          transitionBetweenRoutes: false,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () =>
                    ref.read(notificationProvider.notifier).markAllRead(),
                child: const Text(
                  'Đọc tất cả',
                  style: TextStyle(fontSize: 13, color: AppTheme.kAccentColor),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(
                  CupertinoIcons.plus_circle_fill,
                  color: AppTheme.kAccentColor,
                  size: 28,
                ),
                onPressed: () => _showCreateNotificationModal(context),
              ),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tất cả', NotificationFilter.all),
                  _buildFilterChip('Chưa đọc', NotificationFilter.unread),
                  _buildFilterChip('Đã đọc', NotificationFilter.read),
                  _buildFilterChip(
                    'Cần duyệt',
                    NotificationFilter.actionRequired,
                  ),
                  _buildFilterChip('Đã gửi', NotificationFilter.sent),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          sliver: notifsAsync.when(
            data: (dataMap) {
              // The provider payload is untrusted: `received`/`sent` may be
              // missing or hold a non-List value. Coerce defensively so a
              // malformed response never crashes the whole list.
              final receivedRaw = dataMap['received'];
              final sentRaw = dataMap['sent'];
              final received = receivedRaw is List ? receivedRaw : const [];
              final sent = sentRaw is List ? sentRaw : const [];

              List<dynamic> filteredNotifs = [];
              if (_selectedFilter == NotificationFilter.sent) {
                filteredNotifs = List.from(sent);
              } else {
                filteredNotifs = List.from(received);
                if (_selectedFilter == NotificationFilter.unread) {
                  filteredNotifs = filteredNotifs
                      .where((n) => n['isRead'] == false)
                      .toList();
                } else if (_selectedFilter == NotificationFilter.read) {
                  filteredNotifs = filteredNotifs
                      .where((n) => n['isRead'] == true)
                      .toList();
                } else if (_selectedFilter ==
                    NotificationFilter.actionRequired) {
                  filteredNotifs = filteredNotifs
                      .where(
                        (n) =>
                            n['isActionable'] == true &&
                            n['actionStatus'] == 'PENDING',
                      )
                      .toList();
                }
              }

              // Drop rows the user already swiped away this session so the
              // Dismissible is removed from the tree in the same frame.
              if (_locallyDeletedIds.isNotEmpty) {
                filteredNotifs = filteredNotifs
                    .where(
                      (n) =>
                          !(n is Map && _locallyDeletedIds.contains(n['id'])),
                    )
                    .toList();
              }

              if (filteredNotifs.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.bell_slash,
                          size: 64,
                          color: Color(0xFFD1D5DB),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Không có thông báo nào.',
                          style: TextStyle(
                            color: Color(0xFF4B5563),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((ctx, i) {
                  final n = filteredNotifs[i];
                  // Skip malformed entries instead of throwing mid-build.
                  if (n is! Map) return const SizedBox.shrink();
                  final notifModel = NotificationModel.fromJson(
                    Map<String, dynamic>.from(n),
                  );
                  return _NotificationCard(
                    // Stable identity per notification so the card's local
                    // state (_isLoading / _resultStatus) is never reused for a
                    // different row when the list reorders after a refresh.
                    key: ValueKey('notif_card_${notifModel.id}'),
                    notifModel: notifModel,
                    isSent: _selectedFilter == NotificationFilter.sent,
                    onDismissed: () {
                      setState(() => _locallyDeletedIds.add(notifModel.id));
                      unawaited(
                        ref
                            .read(notificationProvider.notifier)
                            .deleteNotification(notifModel.id),
                      );
                    },
                  );
                }, childCount: filteredNotifs.length),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CupertinoActivityIndicator()),
            ),
            error: (err, _) =>
                SliverFillRemaining(child: AppErrorWidget(error: err)),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, NotificationFilter filter) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filter),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.kAccentColor : CupertinoColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.kAccentColor : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? CupertinoColors.white : const Color(0xFF4B5563),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _showCreateNotificationModal(BuildContext context) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    var isSending = false;

    final popupFuture = showCupertinoModalPopup(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
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
                'Tạo thông báo mới',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CupertinoTextField(
                          controller: titleCtrl,
                          placeholder: 'Tiêu đề thông báo',
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: CupertinoColors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CupertinoTextField(
                          controller: contentCtrl,
                          placeholder: 'Nội dung thông báo...',
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          maxLines: 5,
                          decoration: null,
                        ),
                      ),
                      const Spacer(),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: isSending
                            ? null
                            : () async {
                                final title = titleCtrl.text.trim();
                                final content = contentCtrl.text.trim();
                                if (title.isEmpty || content.isEmpty) {
                                  return;
                                }
                                setModalState(() => isSending = true);
                                final user = ref.read(authProvider).value;
                                var ok = false;
                                try {
                                  await ref
                                      .read(apiClientProvider)
                                      .post(
                                        '/v1/notifications/owner-broadcast',
                                        data: {
                                          'ownerId': user?.id ?? 0,
                                          'branchId': -1,
                                          'title': title,
                                          'content': content,
                                        },
                                      );
                                  ok = true;
                                } catch (_) {
                                  ok = false;
                                }
                                if (!ctx.mounted) return;
                                if (ok) {
                                  ref.invalidate(notificationProvider);
                                  Navigator.pop(ctx);
                                } else {
                                  setModalState(() => isSending = false);
                                }
                              },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: AppTheme.kAccentColor,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Center(
                            child: isSending
                                ? const CupertinoActivityIndicator(
                                    color: CupertinoColors.white,
                                  )
                                : const Text(
                                    'Gửi Thông Báo',
                                    style: TextStyle(
                                      color: CupertinoColors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    unawaited(
      popupFuture.whenComplete(() {
        titleCtrl.dispose();
        contentCtrl.dispose();
      }),
    );
  }
}

// ─── Card thông báo (tách riêng để có State loading) ───────────────────────
class _NotificationCard extends ConsumerStatefulWidget {
  final NotificationModel notifModel;
  final bool isSent;

  /// Invoked when the user swipes the card away. The parent removes the row
  /// from its local list synchronously (so the Dismissible leaves the tree in
  /// the same frame) and then fires the network delete.
  final VoidCallback? onDismissed;

  const _NotificationCard({
    super.key,
    required this.notifModel,
    this.isSent = false,
    this.onDismissed,
  });

  @override
  ConsumerState<_NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends ConsumerState<_NotificationCard> {
  bool _isLoading = false;
  String? _resultStatus; // 'APPROVED' | 'REJECTED'

  // Suy ra endpoint thật từ type thông báo (nếu backend chưa gắn metadata)
  Map<String, dynamic> _resolveAction(String status) {
    final notif = widget.notifModel;
    final type = notif.type;
    final refId = notif.refId;
    final bool approved = status == 'APPROVED';

    // 1. Ưu tiên metadata do backend gắn sẵn
    if (notif.actionMetadata != null && notif.actionMetadata!.isNotEmpty) {
      try {
        final decoded = jsonDecode(notif.actionMetadata!);
        if (decoded is Map) {
          final meta = Map<String, dynamic>.from(decoded);
          final payloadRaw = meta['payload'];
          final Map<String, dynamic> payload = payloadRaw is Map
              ? Map<String, dynamic>.from(payloadRaw)
              : <String, dynamic>{};
          payload['approved'] = approved;
          if (!approved) payload['reason'] = 'Bị từ chối bởi người quản lý';
          final endpointRaw = meta['endpoint'];
          final methodRaw = meta['method'];
          return {
            'endpoint': endpointRaw is String ? endpointRaw : '',
            'method': methodRaw is String && methodRaw.isNotEmpty
                ? methodRaw
                : 'POST',
            'payload': payload,
          };
        }
      } catch (_) {}
    }

    // 2. Fallback: tự suy từ type + refId
    if (type.contains('RENTAL_REQUEST') && refId != null) {
      return {
        'endpoint': '/v1/rental-requests/$refId/respond',
        'method': 'POST',
        'payload': {'approved': approved},
      };
    }
    if ((type.contains('KYC') || type.contains('OWNER_VERIFY')) &&
        refId != null) {
      return {
        'endpoint': '/v1/admin/owners/$refId/verify',
        'method': 'PUT',
        'payload': {
          'approved': approved,
          'reason': approved ? null : 'Hồ sơ chưa đạt',
        },
      };
    }
    if ((type.contains('EKYC') || type.contains('TENANT_EKYC')) &&
        refId != null) {
      return {
        'endpoint': '/v1/admin/tenants/$refId/approve-ekyc',
        'method': 'POST',
        'payload': {
          'approved': approved,
          'reason': approved ? 'Admin đã duyệt' : 'Hồ sơ chưa đạt',
        },
      };
    }
    if ((type.contains('MAINTENANCE') || type.contains('TICKET')) &&
        refId != null) {
      return {
        'endpoint': '/v1/tickets/owner-approve',
        'method': 'POST',
        'payload': {'ticketId': refId, 'approved': approved, 'staffBonus': 0},
      };
    }
    if (type.contains('CHECKOUT') && refId != null) {
      return {
        'endpoint': '/v1/checkouts/$refId/${approved ? 'approve' : 'reject'}',
        'method': 'POST',
        'payload': {},
      };
    }
    // Không xác định được
    return {'endpoint': '', 'method': 'POST', 'payload': {}};
  }

  Future<void> _handleAction(String status) async {
    final action = _resolveAction(status);
    // BUGFIX (data): trước đây ép `as String`/`as Map` — nếu map trả về
    // giá trị không đúng kiểu thì ném TypeError khi bấm nút duyệt. Coerce an toàn.
    final endpoint = action['endpoint']?.toString() ?? '';
    if (endpoint.isEmpty) {
      unawaited(
        showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
            title: const Text('Không thể thực hiện'),
            content: const Text(
              'Loại thông báo này chưa hỗ trợ duyệt trực tiếp. Vui lòng vào màn hình chi tiết để xử lý.',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await ref
        .read(notificationProvider.notifier)
        .executeAction(
          widget.notifModel.id,
          endpoint,
          action['method']?.toString() ?? 'POST',
          action['payload'] is Map
              ? Map<String, dynamic>.from(action['payload'] as Map)
              : <String, dynamic>{},
          status,
        );
    if (mounted) {
      setState(() {
        _isLoading = false;
        _resultStatus = success ? status : null;
      });
      if (!success) {
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (_) => CupertinoAlertDialog(
              title: const Text('Thao tác thất bại'),
              content: const Text(
                'Không thể xử lý yêu cầu này.\nVui lòng vào chi tiết để thử lại.',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('Xem chi tiết'),
                  onPressed: () {
                    Navigator.pop(context);
                    unawaited(
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => NotificationDetailScreen(
                            notification: widget.notifModel,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifModel = widget.notifModel;
    final type = notifModel.type;
    final isRead = notifModel.isRead;

    bool isActionable = notifModel.isActionable;
    if (!isActionable) {
      if (type.contains('REQUEST') ||
          type.contains('TICKET') ||
          type.contains('CHECKOUT') ||
          type.contains('KYC') ||
          type.contains('EKYC')) {
        isActionable = true;
      }
    }

    final actionStatus = notifModel.actionStatus ?? 'PENDING';

    IconData getIconForType() {
      if (type.contains('MAINTENANCE') || type.contains('TICKET')) {
        return CupertinoIcons.wrench_fill;
      }
      if (type.contains('BILL')) {
        return CupertinoIcons.money_dollar_circle_fill;
      }
      if (type.contains('CONTRACT')) {
        return CupertinoIcons.doc_text_fill;
      }
      if (type.contains('ROOM') || type.contains('RENTAL')) {
        return CupertinoIcons.bed_double_fill;
      }
      if (type.contains('CHECKOUT')) {
        return CupertinoIcons.arrow_right_square_fill;
      }
      if (type.contains('KYC') || type.contains('EKYC')) {
        return CupertinoIcons.checkmark_shield_fill;
      }
      return CupertinoIcons.bell_fill;
    }

    String getAssetForType() {
      if (type.contains('MAINTENANCE') || type.contains('TICKET')) {
        return 'assets/images/features/video_maintenance.png';
      }
      if (type.contains('BILL')) {
        return 'assets/images/features/feat_payments.png';
      }
      if (type.contains('CONTRACT')) {
        return 'assets/images/features/smart_contract.png';
      }
      if (type.contains('ROOM') || type.contains('RENTAL')) {
        return 'assets/images/features/feat_room.png';
      }
      if (type.contains('CHECKOUT')) {
        return 'assets/images/features/moveout_settlement.png';
      }
      if (type.contains('KYC') || type.contains('EKYC')) {
        return 'assets/images/features/tenant_bg_check.png';
      }
      return 'assets/images/features/push_alerts.png';
    }

    Color getColorForType() {
      if (type.contains('MAINTENANCE') || type.contains('TICKET')) {
        return CupertinoColors.systemOrange;
      }
      if (type.contains('BILL')) {
        return CupertinoColors.systemGreen;
      }
      if (type.contains('CONTRACT')) {
        return CupertinoColors.systemPurple;
      }
      if (type.contains('ROOM') || type.contains('RENTAL')) {
        return CupertinoColors.systemBlue;
      }
      if (type.contains('CHECKOUT')) {
        return CupertinoColors.systemRed;
      }
      if (type.contains('KYC') || type.contains('EKYC')) {
        return CupertinoColors.systemIndigo;
      }
      return AppTheme.kAccentColor;
    }

    final priorityColor = getColorForType();

    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(notifModel.createdAt);
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key('notif_${notifModel.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: CupertinoColors.systemRed,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(CupertinoIcons.trash, color: Colors.white),
        ),
        onDismissed: (_) {
          // Delegate to the parent so it can drop the row from its local list
          // synchronously (prevents the "dismissed Dismissible still in tree"
          // assertion) before the network delete runs.
          widget.onDismissed?.call();
        },
        child: GestureDetector(
          onTap: () {
            if (!isRead && !widget.isSent) {
              unawaited(
                ref.read(notificationProvider.notifier).markRead(notifModel.id),
              );
            }
            if (notifModel.refId != null) {
              if (type.contains('MAINTENANCE') || type.contains('TICKET')) {
                unawaited(
                  context.push('/ticket/ticket-detail/${notifModel.refId}'),
                );
                return;
              } else if (type.contains('BILL')) {
                unawaited(context.push('/bill-detail/${notifModel.refId}'));
                return;
              }
            }
            unawaited(
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      NotificationDetailScreen(notification: notifModel),
                ),
              ),
            );
          },
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            color: isRead
                ? CupertinoColors.white
                : priorityColor.withValues(alpha: 0.08),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        getAssetForType(),
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        isAntiAlias: true,
                        errorBuilder: (_, __, ___) => Icon(
                          getIconForType(),
                          color: priorityColor,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  notifModel.title,
                                  style: const TextStyle(
                                    color: CupertinoColors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(
                                    top: 6,
                                    left: 8,
                                  ),
                                  decoration: const BoxDecoration(
                                    color: CupertinoColors.systemRed,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notifModel.content,
                            style: TextStyle(
                              color: isRead
                                  ? const Color(0xFF6B7280)
                                  : const Color(0xFF374151),
                              fontSize: 13,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            parsedDate != null
                                ? timeago.format(parsedDate, locale: 'vi')
                                : notifModel.createdAt,
                            style: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // ── Nút hành động (Duyệt / Từ chối) ──────────────────────────
                if (isActionable && actionStatus == 'PENDING') ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  const SizedBox(height: 12),
                  if (_resultStatus != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _resultStatus == 'APPROVED'
                            ? CupertinoColors.systemGreen.withValues(alpha: 0.1)
                            : CupertinoColors.systemRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _resultStatus == 'APPROVED'
                                ? CupertinoIcons.checkmark_circle_fill
                                : CupertinoIcons.xmark_circle_fill,
                            color: _resultStatus == 'APPROVED'
                                ? CupertinoColors.systemGreen
                                : CupertinoColors.systemRed,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _resultStatus == 'APPROVED'
                                ? '✅ Đã phê duyệt thành công'
                                : '❌ Đã từ chối',
                            style: TextStyle(
                              color: _resultStatus == 'APPROVED'
                                  ? CupertinoColors.systemGreen
                                  : CupertinoColors.systemRed,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_isLoading)
                    const Center(child: CupertinoActivityIndicator())
                  else
                    Row(
                      children: [
                        Expanded(
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            color: CupertinoColors.systemRed.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            onPressed: () => _handleAction('REJECTED'),
                            child: const Text(
                              '✕  Từ chối',
                              style: TextStyle(
                                color: CupertinoColors.systemRed,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            color: AppTheme.kAccentColor,
                            borderRadius: BorderRadius.circular(10),
                            onPressed: () => _handleAction('APPROVED'),
                            child: const Text(
                              '✓  Duyệt ngay',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],

                // ── Đã xử lý rồi (từ server) ──────────────────────────────
                if (isActionable && actionStatus != 'PENDING') ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: actionStatus == 'APPROVED'
                          ? CupertinoColors.systemGreen.withValues(alpha: 0.1)
                          : CupertinoColors.systemRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      actionStatus == 'APPROVED'
                          ? '✅ Đã phê duyệt'
                          : '❌ Đã từ chối',
                      style: TextStyle(
                        color: actionStatus == 'APPROVED'
                            ? CupertinoColors.systemGreen
                            : CupertinoColors.systemRed,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
