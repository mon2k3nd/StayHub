import 'package:flutter/cupertino.dart';

import '../../../core/components/glass_container.dart';
import '../../../core/components/bounce_click.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/constants/role_types.dart';

import '../../../core/components/staggered_list_item.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../core/components/shimmer_loading.dart';
import 'package:flutter/material.dart'
    show RefreshIndicator, Material, Divider, ScaffoldMessenger, SnackBar;
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/components/premium_empty_state_widget.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/ticket_provider.dart';
import '../../review/presentation/review_modal.dart';
import '../../../core/providers/dashboard_refresh.dart';
import '../../staff/application/staff_notifier.dart';
import '../../../core/components/app_error_widget.dart';
import 'dart:async' show unawaited;

class TicketScreen extends ConsumerStatefulWidget {
  const TicketScreen({super.key});

  @override
  ConsumerState<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends ConsumerState<TicketScreen> {
  int _selectedFilter = 0;

  Future<void> _showCompleteModal(BuildContext context, int ticketId) async {
    final costController = TextEditingController();
    XFile? pickedImage;

    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              color: AppTheme.kBackgroundLight,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Báo Cáo Hoàn Thành',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CupertinoTextField(
                        controller: costController,
                        placeholder: 'Chi phí vật tư (nếu có)',
                        keyboardType: TextInputType.number,
                        prefix: const Padding(
                          padding: EdgeInsets.only(left: 8.0),
                          child: Icon(
                            CupertinoIcons.money_dollar,
                            color: AppTheme.kTextSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CupertinoButton(
                              color: pickedImage != null
                                  ? CupertinoColors.systemGreen
                                  : CupertinoColors.systemBlue,
                              child: Text(
                                pickedImage != null
                                    ? 'Đã chọn ảnh'
                                    : 'Chụp ảnh nghiệm thu',
                              ),
                              onPressed: () async {
                                final picker = ImagePicker();
                                final img = await picker.pickImage(
                                  source: ImageSource.camera,
                                  imageQuality: 50,
                                );
                                if (img != null) {
                                  setStateModal(() {
                                    pickedImage = img;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CupertinoButton(
                            child: const Text(
                              'Hủy',
                              style: TextStyle(
                                color: CupertinoColors.systemRed,
                              ),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                          CupertinoButton(
                            child: const Text('Gửi'),
                            onPressed: () async {
                              final costStr = costController.text.replaceAll(
                                RegExp(r'[^0-9]'),
                                '',
                              );
                              final cost = costStr.isNotEmpty
                                  ? double.parse(costStr)
                                  : 0.0;

                              Navigator.pop(ctx);

                              unawaited(
                                showCupertinoDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (c) => const Center(
                                    child: CupertinoActivityIndicator(),
                                  ),
                                ),
                              );

                              final bool isOwner = Role.isOwner(
                                ref.read(authProvider).value?.role,
                              );
                              final success = isOwner
                                  ? await ref
                                        .read(ticketProvider.notifier)
                                        .ownerCompleteTicket(
                                          ticketId,
                                          cost,
                                          true,
                                          'Xử lý nhanh',
                                          pickedImage?.path,
                                        )
                                  : await ref
                                        .read(ticketProvider.notifier)
                                        .completeTicket(
                                          ticketId,
                                          cost,
                                          true,
                                          'Xử lý nhanh',
                                          pickedImage?.path,
                                        );

                              if (!context.mounted) return;
                              Navigator.pop(context); // close loading
                              if (success) {
                                refreshOwnerDashboardFromWidget(ref);
                              } else {
                                if (!context.mounted) return;
                                unawaited(
                                  showCupertinoDialog(
                                    context: context,
                                    builder: (c) => CupertinoAlertDialog(
                                      title: const Text('Lỗi'),
                                      content: const Text(
                                        'Không thể báo cáo hoàn thành.',
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
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showReasonModal(
    BuildContext context,
    int ticketId,
    bool isCancel,
  ) async {
    final reasonController = TextEditingController();

    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(isCancel ? 'Hủy sự cố' : 'Từ chối phê duyệt'),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: CupertinoTextField(
            controller: reasonController,
            placeholder: 'Nhập lý do...',
            maxLines: 3,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              if (isCancel) {
                unawaited(
                  ref
                      .read(ticketProvider.notifier)
                      .cancelTicket(ticketId, reasonController.text.trim()),
                );
              } else {
                unawaited(
                  ref
                      .read(ticketProvider.notifier)
                      .rejectTicket(ticketId, reasonController.text.trim()),
                );
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  void _showAssignModal(BuildContext context, int ticketId) {
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: const BoxDecoration(
              color: AppTheme.kBackgroundLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFF3F4F6)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Phân công nhân viên',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Icon(
                          CupertinoIcons.clear_circled_solid,
                          color: CupertinoColors.inactiveGray,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Consumer(
                    builder: (ctx, ref, child) {
                      final staffAsync = ref.watch(staffListNotifierProvider);
                      return staffAsync.when(
                        data: (staffList) {
                          if (staffList.isEmpty) {
                            return const Center(
                              child: Text(
                                'Không có nhân viên nào',
                                style: TextStyle(
                                  color: CupertinoColors.inactiveGray,
                                ),
                              ),
                            );
                          }
                          return ListView.separated(
                            itemCount: staffList.length,
                            separatorBuilder: (c, i) => const Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                            ),
                            itemBuilder: (c, i) {
                              final staff = staffList[i];
                              return CupertinoListTile(
                                leading: const Icon(
                                  CupertinoIcons.person_solid,
                                  color: LiquidGlassColors.staffAccent,
                                ),
                                title: Text(staff.name),
                                subtitle: Text(
                                  staff.role ?? 'Nhân viên',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: CupertinoColors.inactiveGray,
                                  ),
                                ),
                                trailing: CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  color: LiquidGlassColors.staffAccent,
                                  borderRadius: BorderRadius.circular(16),
                                  child: const Text(
                                    'Chọn',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    unawaited(
                                      ref
                                          .read(ticketProvider.notifier)
                                          .assignTicket(ticketId, staff.id)
                                          .then((success) {
                                            if (success) {
                                              refreshOwnerDashboardFromWidget(
                                                ref,
                                              );
                                            }
                                          }),
                                    );
                                  },
                                ),
                              );
                            },
                          );
                        },
                        loading: () =>
                            const Center(child: CupertinoActivityIndicator()),
                        error: (e, st) => Center(child: Text('Lỗi: $e')),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(ticketProvider);
    final user = ref.watch(authProvider).value;
    final isTenant = Role.isTenant(user?.role);
    final isStaff = Role.isStaff(user?.role);

    return LiquidGlassScaffold(
      title: 'Quản lý Sự Cố',
      backgroundColors: AppTheme.kBackgroundLight,
      useScrollView: false,
      trailing: isTenant
          ? CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(
                CupertinoIcons.add_circled_solid,
                color: CupertinoColors.systemRed,
                size: 28,
              ),
              onPressed: () => context.push('/ticket/create'),
            )
          : CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(
                CupertinoIcons.refresh_circled,
                color: LiquidGlassColors.staffAccent,
                size: 28,
              ),
              onPressed: () => ref.read(ticketProvider.notifier).refresh(),
            ),
      child: ticketsAsync.when(
        data: (tickets) {
          final filteredTickets = tickets.where((t) {
            if (_selectedFilter == 0) return true; // All
            if (_selectedFilter == 1) {
              return t.status == 'NEW' ||
                  t.status == 'ASSIGNED' ||
                  t.status == 'PROCESSING';
            }
            if (_selectedFilter == 2) return t.status == 'COMPLETED';
            if (_selectedFilter == 3) {
              return t.status == 'CLOSED' ||
                  t.status == 'REJECTED' ||
                  t.status == 'CANCELLED';
            }
            return true;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: CupertinoSlidingSegmentedControl<int>(
                    groupValue: _selectedFilter,
                    children: const {
                      0: Text('Tất cả', style: TextStyle(fontSize: 13)),
                      1: Text('Đang xử lý', style: TextStyle(fontSize: 13)),
                      2: Text('Chờ duyệt', style: TextStyle(fontSize: 13)),
                      3: Text('Đã xong', style: TextStyle(fontSize: 13)),
                    },
                    onValueChanged: (val) {
                      if (val != null) setState(() => _selectedFilter = val);
                    },
                  ),
                ),
              ),
              Expanded(
                child: filteredTickets.isEmpty
                    ? PremiumEmptyStateWidget(
                        title: 'Không có sự cố nào',
                        message: _selectedFilter == 0
                            ? 'Tất cả đều ổn! Hiện chưa có sự cố nào được ghi nhận.'
                            : 'Không có sự cố nào trong mục này.',
                        icon: CupertinoIcons.checkmark_shield_fill,
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.read(ticketProvider.notifier).refresh(),
                        child: AnimationLimiter(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredTickets.length,
                            itemBuilder: (context, index) {
                              final t = filteredTickets[index];
                              return StaggeredListItem(
                                index: index,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: BounceClick(
                                    onPressed: !isTenant
                                        ? () => context.push(
                                            '/ticket/ticket-detail/${t.id}',
                                          )
                                        : () {},
                                    child: Hero(
                                      tag: 'ticket_card_${t.id}',
                                      child: Material(
                                        color: const Color(0x00000000),
                                        child: GlassContainer(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        t.category,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                      if (isStaff) ...[
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        const Icon(
                                                          CupertinoIcons
                                                              .chevron_right,
                                                          size: 14,
                                                          color: Color(
                                                            0xFF9CA3AF,
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: _getStatusColor(
                                                        t.status,
                                                      ).withValues(alpha: 0.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      _getStatusText(t.status),
                                                      style: TextStyle(
                                                        color: _getStatusColor(
                                                          t.status,
                                                        ),
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                t.description ??
                                                    'Không có mô tả',
                                                style: const TextStyle(
                                                  color: Color(0xFF4B5563),
                                                ),
                                              ),
                                              if (t.severity != null) ...[
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      CupertinoIcons
                                                          .exclamationmark_triangle_fill,
                                                      size: 14,
                                                      color: _getSeverityColor(
                                                        t.severity!,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Mức độ: ${_getSeverityText(t.severity!)}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            _getSeverityColor(
                                                              t.severity!,
                                                            ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    CupertinoIcons.house,
                                                    size: 13,
                                                    color: Color(0xFF9CA3AF),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Phòng #${t.roomId}',
                                                    style: const TextStyle(
                                                      color: Color(0xFF9CA3AF),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  if (t.createdAt != null) ...[
                                                    const SizedBox(width: 12),
                                                    const Icon(
                                                      CupertinoIcons.clock,
                                                      size: 13,
                                                      color: Color(0xFF9CA3AF),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${t.createdAt!.day}/${t.createdAt!.month}/${t.createdAt!.year}',
                                                      style: const TextStyle(
                                                        color: Color(
                                                          0xFF9CA3AF,
                                                        ),
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              if (!isTenant &&
                                                  !isStaff &&
                                                  (t.status == 'NEW' ||
                                                      t.status == 'ASSIGNED' ||
                                                      t.status == 'PROCESSING'))
                                                Row(
                                                  children: [
                                                    if (t.status == 'NEW') ...[
                                                      CupertinoButton(
                                                        padding:
                                                            EdgeInsets.zero,
                                                        child: const Text(
                                                          'Phân công',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                        onPressed: () {
                                                          _showAssignModal(
                                                            context,
                                                            t.id,
                                                          );
                                                        },
                                                      ),
                                                      const SizedBox(width: 16),
                                                      CupertinoButton(
                                                        padding:
                                                            EdgeInsets.zero,
                                                        child: const Text(
                                                          'Tự xử lý & Hoàn tất',
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color:
                                                                CupertinoColors
                                                                    .systemGreen,
                                                          ),
                                                        ),
                                                        onPressed: () {
                                                          unawaited(
                                                            _showCompleteModal(
                                                              context,
                                                              t.id,
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                    const Spacer(),
                                                    CupertinoButton(
                                                      padding: EdgeInsets.zero,
                                                      child: const Text(
                                                        'Hủy',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: CupertinoColors
                                                              .systemRed,
                                                        ),
                                                      ),
                                                      onPressed: () {
                                                        unawaited(
                                                          _showReasonModal(
                                                            context,
                                                            t.id,
                                                            true,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              if (!isTenant &&
                                                  !isStaff &&
                                                  t.status == 'COMPLETED')
                                                Row(
                                                  children: [
                                                    CupertinoButton(
                                                      padding: EdgeInsets.zero,
                                                      child: const Text(
                                                        'Phê duyệt hoàn thành',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: CupertinoColors
                                                              .systemGreen,
                                                        ),
                                                      ),
                                                      onPressed: () {
                                                        unawaited(
                                                          ref
                                                              .read(
                                                                ticketProvider
                                                                    .notifier,
                                                              )
                                                              .approveTicket(
                                                                t.id,
                                                                0.0,
                                                              )
                                                              .then((success) {
                                                                if (success) {
                                                                  refreshOwnerDashboardFromWidget(
                                                                    ref,
                                                                  );
                                                                }
                                                              }),
                                                        );
                                                      },
                                                    ),
                                                    const Spacer(),
                                                    CupertinoButton(
                                                      padding: EdgeInsets.zero,
                                                      child: const Text(
                                                        'Từ chối',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: CupertinoColors
                                                              .systemRed,
                                                        ),
                                                      ),
                                                      onPressed: () {
                                                        unawaited(
                                                          _showReasonModal(
                                                            context,
                                                            t.id,
                                                            false,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              if (isStaff &&
                                                  (t.status == 'ASSIGNED' ||
                                                      t.status == 'PROCESSING'))
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: LiquidGlassColors
                                                        .staffAccent
                                                        .withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        t.status == 'ASSIGNED'
                                                            ? CupertinoIcons
                                                                  .play_circle_fill
                                                            : CupertinoIcons
                                                                  .wrench_fill,
                                                        size: 14,
                                                        color: LiquidGlassColors
                                                            .staffAccent,
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        t.status == 'ASSIGNED'
                                                            ? 'Nhấn để bắt đầu xử lý'
                                                            : 'Nhấn để báo cáo',
                                                        style: const TextStyle(
                                                          color:
                                                              LiquidGlassColors
                                                                  .staffAccent,
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              if (t.status == 'CLOSED' &&
                                                  !isStaff)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 12,
                                                      ),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: CupertinoButton(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 8,
                                                              ),
                                                          color: CupertinoColors
                                                              .systemYellow
                                                              .withValues(
                                                                alpha: 0.1,
                                                              ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                          child: const Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Icon(
                                                                CupertinoIcons
                                                                    .star_fill,
                                                                color: CupertinoColors
                                                                    .systemYellow,
                                                                size: 16,
                                                              ),
                                                              SizedBox(
                                                                width: 8,
                                                              ),
                                                              Text(
                                                                'Đánh giá chất lượng',
                                                                style: TextStyle(
                                                                  color: CupertinoColors
                                                                      .systemYellow,
                                                                  fontSize: 13,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          onPressed: () {
                                                            ReviewModal.show(
                                                              context,
                                                              title:
                                                                  'Đánh giá xử lý sự cố',
                                                              targetName:
                                                                  'nhân viên bảo trì',
                                                              onSubmit: (rating, feedback) async {
                                                                try {
                                                                  final dio = ref
                                                                      .read(
                                                                        apiClientProvider,
                                                                      )
                                                                      .dio;
                                                                  await dio.post(
                                                                    '/v1/reviews',
                                                                    data: {
                                                                      'roomId':
                                                                          t.roomId,
                                                                      'reviewerName':
                                                                          'Khách thuê',
                                                                      'rating':
                                                                          rating,
                                                                      'content':
                                                                          feedback,
                                                                    },
                                                                  );
                                                                  if (!context
                                                                      .mounted) {
                                                                    return;
                                                                  }
                                                                  unawaited(
                                                                    showCupertinoDialog(
                                                                      context:
                                                                          context,
                                                                      builder: (ctx) => CupertinoAlertDialog(
                                                                        title: const Text(
                                                                          'Cảm ơn bạn!',
                                                                        ),
                                                                        content:
                                                                            Text(
                                                                              'Bạn đã gửi đánh giá $rating sao cho nhân viên bảo trì.',
                                                                            ),
                                                                        actions: [
                                                                          CupertinoDialogAction(
                                                                            child: const Text(
                                                                              'Đóng',
                                                                            ),
                                                                            onPressed: () => Navigator.pop(
                                                                              ctx,
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  );
                                                                } catch (e) {
                                                                  if (!context
                                                                      .mounted) {
                                                                    return;
                                                                  }
                                                                  ScaffoldMessenger.of(
                                                                    context,
                                                                  ).showSnackBar(
                                                                    SnackBar(
                                                                      content: Text(
                                                                        'Lỗi: $e',
                                                                      ),
                                                                    ),
                                                                  );
                                                                }
                                                              },
                                                            );
                                                          },
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
                              );
                            },
                          ),
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(20),
          child: ShimmerListLoading(),
        ),
        error: (err, _) => AppErrorWidget(error: err),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'NEW':
        return CupertinoColors.systemRed;
      case 'ASSIGNED':
      case 'PROCESSING':
        return CupertinoColors.systemOrange;
      case 'COMPLETED':
        return CupertinoColors.systemBlue;
      case 'CLOSED':
        return CupertinoColors.systemGreen;
      default:
        return AppTheme.kTextSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'NEW':
        return 'Mới';
      case 'ASSIGNED':
      case 'PROCESSING':
        return 'Đang xử lý';
      case 'COMPLETED':
        return 'Chờ duyệt';
      case 'CLOSED':
        return 'Đã xong';
      default:
        return status;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'LOW':
        return AppTheme.kTextSecondary;
      case 'NORMAL':
        return CupertinoColors.systemBlue;
      case 'HIGH':
        return CupertinoColors.systemOrange;
      case 'URGENT':
        return CupertinoColors.systemRed;
      default:
        return AppTheme.kTextSecondary;
    }
  }

  String _getSeverityText(String severity) {
    switch (severity) {
      case 'LOW':
        return 'Thấp';
      case 'NORMAL':
        return 'Bình thường';
      case 'HIGH':
        return 'Cao';
      case 'URGENT':
        return 'Khẩn cấp';
      default:
        return severity;
    }
  }
}
