import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/liquid_background.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../ticket/data/models/ticket_model.dart';
import '../../ticket/application/ticket_provider.dart';
import '../../auth/application/auth_notifier.dart';
import '../../../core/providers/dashboard_refresh.dart';
import 'widgets/ticket_info_card.dart';
import 'widgets/ticket_action_buttons.dart';
import '../../../core/components/app_error_widget.dart';
import 'dart:async' show unawaited;

// Provider để load chi tiết 1 ticket
final ticketDetailProvider = FutureProvider.family<TicketModel?, int>((
  ref,
  id,
) async {
  try {
    final res = await ref.read(apiClientProvider).dio.get('/v1/tickets/$id');
    return TicketModel.fromJson(res.data['data']);
  } catch (e, st) {
    debugPrint('Error: $e\n$st');
    return null;
  }
});

class StaffTicketDetailScreen extends ConsumerStatefulWidget {
  final int ticketId;

  const StaffTicketDetailScreen({super.key, required this.ticketId});

  @override
  ConsumerState<StaffTicketDetailScreen> createState() =>
      _StaffTicketDetailScreenState();
}

class _StaffTicketDetailScreenState
    extends ConsumerState<StaffTicketDetailScreen> {
  bool _isLoading = false;
  final _fmt = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  Future<void> _startProcessing(int ticketId) async {
    setState(() => _isLoading = true);
    try {
      await ref
          .read(apiClientProvider)
          .dio
          .patch(
            '/v1/tickets/$ticketId/status',
            data: {'status': 'PROCESSING'},
          );
      ref.invalidate(ticketDetailProvider(ticketId));
      unawaited(ref.read(ticketProvider.notifier).refresh());
    } catch (e) {
      if (mounted) {
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (c) => CupertinoAlertDialog(
              title: const Text('Lỗi'),
              content: Text(e.toString()),
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
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showReasonModal(int ticketId, bool isCancel) async {
    final reasonController = TextEditingController();

    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isCancel ? 'Hủy yêu cầu' : 'Từ chối nghiệm thu',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    controller: reasonController,
                    placeholder: 'Lý do...',
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      CupertinoButton(
                        child: const Text(
                          'Đóng',
                          style: TextStyle(color: CupertinoColors.systemGrey),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                      CupertinoButton(
                        child: const Text(
                          'Xác nhận',
                          style: TextStyle(color: CupertinoColors.systemRed),
                        ),
                        onPressed: () async {
                          final reason = reasonController.text.trim();
                          if (reason.isEmpty) return;

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

                          final success = isCancel
                              ? await ref
                                    .read(ticketProvider.notifier)
                                    .cancelTicket(ticketId, reason)
                              : await ref
                                    .read(ticketProvider.notifier)
                                    .rejectTicket(ticketId, reason);

                          if (mounted) {
                            Navigator.pop(context); // close loading
                            if (success) {
                              ref.invalidate(ticketDetailProvider(ticketId));
                              refreshOwnerDashboardFromWidget(ref);
                            } else {
                              unawaited(
                                showCupertinoDialog(
                                  context: context,
                                  builder: (c) => CupertinoAlertDialog(
                                    title: const Text('Lỗi'),
                                    content: const Text('Thao tác thất bại.'),
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
  }

  Future<void> _showCompleteModal(int ticketId) async {
    final costCtrl = TextEditingController();
    final detailsCtrl = TextEditingController();
    bool isSuccessful = true;
    XFile? pickedImage;

    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModal) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx2).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Center(
                    child: Text(
                      'Báo cáo hoàn thành',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kết quả xử lý',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      CupertinoSlidingSegmentedControl<bool>(
                        groupValue: isSuccessful,
                        children: const {
                          true: Text(
                            'Thành công',
                            style: TextStyle(fontSize: 13),
                          ),
                          false: Text(
                            'Thất bại',
                            style: TextStyle(
                              fontSize: 13,
                              color: CupertinoColors.systemRed,
                            ),
                          ),
                        },
                        onValueChanged: (val) {
                          if (val != null) setModal(() => isSuccessful = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Chi tiết sửa chữa',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: detailsCtrl,
                    placeholder: 'Đã thay mới / Không sửa được do...',
                    minLines: 3,
                    maxLines: 5,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Chi phí vật tư (₫)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: costCtrl,
                    placeholder: 'Nhập chi phí (để trống nếu không có)',
                    keyboardType: TextInputType.number,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Ảnh nghiệm thu',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () async {
                      final picker = ImagePicker();
                      final img = await picker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 70,
                      );
                      if (img != null) setModal(() => pickedImage = img);
                    },
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: pickedImage != null
                            ? CupertinoColors.systemGreen.withValues(alpha: 0.1)
                            : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: pickedImage != null
                              ? CupertinoColors.systemGreen
                              : const Color(0xFFE5E7EB),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              pickedImage != null
                                  ? CupertinoIcons.checkmark_circle_fill
                                  : CupertinoIcons.camera,
                              color: pickedImage != null
                                  ? CupertinoColors.systemGreen
                                  : CupertinoColors.systemGrey,
                              size: 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pickedImage != null
                                  ? 'Đã chụp ảnh ✓'
                                  : 'Chụp ảnh nghiệm thu',
                              style: TextStyle(
                                color: pickedImage != null
                                    ? CupertinoColors.systemGreen
                                    : CupertinoColors.systemGrey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(12),
                          child: const Text(
                            'Hủy',
                            style: TextStyle(color: Color(0xFF374151)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          color: LiquidGlassColors.staffAccent,
                          borderRadius: BorderRadius.circular(12),
                          child: const Text(
                            'Gửi',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.white,
                            ),
                          ),
                          onPressed: () async {
                            final costStr = costCtrl.text.replaceAll(
                              RegExp(r'[^0-9]'),
                              '',
                            );
                            final cost = costStr.isNotEmpty
                                ? double.parse(costStr)
                                : 0.0;
                            final details = detailsCtrl.text.trim();
                            Navigator.pop(ctx);
                            final isOwner =
                                ref.read(authProvider).value?.role == 'OWNER';
                            final ok = isOwner
                                ? await ref
                                      .read(ticketProvider.notifier)
                                      .ownerCompleteTicket(
                                        ticketId,
                                        cost,
                                        isSuccessful,
                                        details,
                                        pickedImage?.path,
                                      )
                                : await ref
                                      .read(ticketProvider.notifier)
                                      .completeTicket(
                                        ticketId,
                                        cost,
                                        isSuccessful,
                                        details,
                                        pickedImage?.path,
                                      );

                            if (mounted) {
                              setState(() => _isLoading = false);
                              ref.invalidate(ticketDetailProvider(ticketId));
                              refreshOwnerDashboardFromWidget(ref);
                              if (ok) {
                                unawaited(
                                  showCupertinoDialog(
                                    context: context,
                                    builder: (c) => CupertinoAlertDialog(
                                      title: const Text('Đã hoàn tất'),
                                      content: Text(
                                        isOwner
                                            ? 'Đã lưu lại nghiệm thu của bạn.'
                                            : 'Chủ nhà sẽ nghiệm thu và đóng sự cố.',
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
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticketAsync = ref.watch(ticketDetailProvider(widget.ticketId));

    return CupertinoPageScaffold(
      child: LiquidBackground(
        colors: AppTheme.kBackgroundLight,
        child: ticketAsync.when(
          data: (ticket) {
            if (ticket == null) {
              return CustomScrollView(
                slivers: [
                  CupertinoSliverRefreshControl(
                    onRefresh: () async {
                      await Future.delayed(const Duration(milliseconds: 1000));
                    },
                  ),
                  const CupertinoSliverNavigationBar(
                    largeTitle: Text('Chi tiết Sự cố'),
                    backgroundColor: Color(0x00000000),
                    border: null,
                  ),
                  const SliverFillRemaining(
                    child: Center(child: Text('Không tìm thấy sự cố này.')),
                  ),
                ],
              );
            }

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                CupertinoSliverNavigationBar(
                  largeTitle: Text('Sự cố #${ticket.id}'),
                  backgroundColor: const Color(0x00000000),
                  border: null,
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Sử dụng TicketInfoCard đã được bóc tách
                      Hero(
                        tag: 'ticket_card_${ticket.id}',
                        child: Material(
                          color: const Color(
                            0x00000000,
                          ), // Transparent material for Hero text
                          child: TicketInfoCard(ticket: ticket),
                        ),
                      ),

                      // Lịch sử sửa chữa (nếu có)
                      if (ticket.repairDetails != null &&
                          ticket.repairDetails!.isNotEmpty) ...[
                        GlassContainer(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    ticket.isSuccessful == true
                                        ? CupertinoIcons
                                              .check_mark_circled_solid
                                        : CupertinoIcons.xmark_circle_fill,
                                    color: ticket.isSuccessful == true
                                        ? CupertinoColors.systemGreen
                                        : CupertinoColors.systemRed,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Lịch sử sửa chữa',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  ticket.repairDetails!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF4B5563),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Ảnh nghiệm thu
                      if (ticket.proofImageUrl != null &&
                          ticket.proofImageUrl!.isNotEmpty) ...[
                        GlassContainer(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ảnh nghiệm thu / Hỏng hóc',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  ticket.proofImageUrl!,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F4F6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'Không tải được ảnh',
                                        style: TextStyle(
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Chi phí
                      if (ticket.materialCost > 0) ...[
                        GlassContainer(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemGreen.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  CupertinoIcons.money_dollar_circle,
                                  color: CupertinoColors.systemGreen,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Chi phí vật tư',
                                    style: TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    _fmt.format(ticket.materialCost),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                      color: CupertinoColors.systemGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Action Buttons bóc tách
                      TicketActionButtons(
                        ticket: ticket,
                        isLoading: _isLoading,
                        onStartProcessing: () => _startProcessing(ticket.id),
                        onShowReasonModal: (id, isCancel) =>
                            _showReasonModal(id, isCancel),
                        onShowCompleteModal: (id) => _showCompleteModal(id),
                        onApproveTicket: (id) async {
                          unawaited(
                            showCupertinoDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (c) => const Center(
                                child: CupertinoActivityIndicator(),
                              ),
                            ),
                          );
                          final success = await ref
                              .read(ticketProvider.notifier)
                              .approveTicket(id, 0.0);
                          if (!context.mounted) return;

                          Navigator.pop(context);
                          if (success) {
                            ref.invalidate(ticketDetailProvider(id));
                            refreshOwnerDashboardFromWidget(ref);
                          } else {
                            unawaited(
                              showCupertinoDialog(
                                context: context,
                                builder: (c) => CupertinoAlertDialog(
                                  title: const Text('Lỗi'),
                                  content: const Text('Thao tác thất bại.'),
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
                    ]),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e, _) => AppErrorWidget(error: e),
        ),
      ),
    );
  }
}
