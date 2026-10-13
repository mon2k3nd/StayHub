import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/components/premium_empty_state_widget.dart';
import '../../../core/components/bounce_click.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../application/bill_notifier.dart';
import 'widgets/zalo_zns_campaign_modal.dart';
import '../data/models/bill_model.dart';
import 'dart:async' show unawaited;

class DebtManagementScreen extends ConsumerStatefulWidget {
  const DebtManagementScreen({super.key});

  @override
  ConsumerState<DebtManagementScreen> createState() =>
      _DebtManagementScreenState();
}

class _DebtManagementScreenState extends ConsumerState<DebtManagementScreen> {
  final _currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    unawaited(
      Future.microtask(() {
        unawaited(ref.read(billProvider.notifier).refreshBills());
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final billState = ref.watch(billProvider);

    return LiquidGlassScaffold(
      title: 'Quản Lý Nợ Đọng',
      backgroundColors: AppTheme.kBackgroundLight,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: () => ref.read(billProvider.notifier).refreshBills(),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHeader(),
                const SizedBox(height: 24),
                if (billState.isLoading && !billState.hasValue)
                  const Center(child: CupertinoActivityIndicator())
                else if (billState.hasError)
                  Center(
                    child: Text(
                      'Lỗi: ${billState.error}',
                      style: const TextStyle(color: CupertinoColors.systemRed),
                    ),
                  )
                else if (billState.hasValue)
                  _buildDebtList(billState.value ?? []),
                const SizedBox(height: 60),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Danh sách nợ đọng',
          style: TextStyle(
            color: CupertinoColors.black,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Hệ thống tự động nhắc nợ qua Zalo/SMS vào ngày mùng 5 hàng tháng.',
          style: TextStyle(
            color: CupertinoColors.black.withValues(alpha: 0.6),
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDebtList(List<dynamic> allBills) {
    final unpaidBills = allBills.where((b) => !(b.isPaid ?? false)).toList();
    if (unpaidBills.isEmpty) {
      return const PremiumEmptyStateWidget(
        title: 'Tuyệt vời!',
        message: 'Không có khách thuê nào đang nợ đọng.',
        icon: CupertinoIcons.check_mark_circled_solid,
      );
    }

    final double totalDebt = unpaidBills.fold(
      0.0,
      (sum, b) => sum + (b.totalAmount ?? 0.0),
    );

    return AnimationLimiter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimationConfiguration.staggeredList(
            position: 0,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 40,
              child: FadeInAnimation(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: PremiumGradients.fireOrange,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.kPremiumShadowLight,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TỔNG DƯ NỢ',
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _currencyFmt.format(totalDebt),
                                style: const TextStyle(
                                  color: CupertinoColors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 26,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: CupertinoColors.white.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${unpaidBills.length} hóa đơn',
                              style: const TextStyle(
                                color: CupertinoColors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _DebtStatChip(
                              label: 'Tháng này',
                              value: unpaidBills
                                  .where((b) => b.month == DateTime.now().month)
                                  .length,
                              color: CupertinoColors.systemOrange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _DebtStatChip(
                              label: 'Quá hạn',
                              value: unpaidBills
                                  .where((b) => b.status == 'OVERDUE')
                                  .length,
                              color: CupertinoColors.systemRed,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _DebtStatChip(
                              label: 'Nháp',
                              value: unpaidBills
                                  .where((b) => b.status == 'DRAFT')
                                  .length,
                              color: AppTheme.kTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          color: const Color(0xFF0068FF),
                          borderRadius: BorderRadius.circular(12),
                          onPressed: () {
                            final unpaidList = unpaidBills
                                .cast<BillModel>()
                                .toList();
                            unawaited(
                              ZaloZnsCampaignModal.show(context, unpaidList),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.white.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  CupertinoIcons.chat_bubble_fill,
                                  color: CupertinoColors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Gửi Zalo ZNS Hàng Loạt',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
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
            ),
          ),
          const SizedBox(height: 24),
          ...unpaidBills.asMap().entries.map(
            (entry) => AnimationConfiguration.staggeredList(
              position: entry.key + 1,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 40,
                child: FadeInAnimation(child: _buildDebtCard(entry.value)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtCard(dynamic bill) {
    final amount = bill.totalAmount ?? 0.0;
    final isDraft = bill.status == 'DRAFT';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: BounceClick(
        onPressed: () => _showReminderDialog(context, bill),
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDraft
                      ? CupertinoColors.systemOrange.withValues(alpha: 0.1)
                      : CupertinoColors.systemRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDraft
                      ? CupertinoIcons.doc_text_fill
                      : CupertinoIcons.money_dollar_circle_fill,
                  color: isDraft
                      ? CupertinoColors.systemOrange
                      : CupertinoColors.systemRed,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Phòng #${bill.roomId}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _currencyFmt.format(amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: CupertinoColors.systemRed,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Hóa đơn ${bill.month}/${bill.year}',
                          style: const TextStyle(
                            color: AppTheme.kTextSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isDraft
                                ? CupertinoColors.systemOrange.withValues(
                                    alpha: 0.1,
                                  )
                                : CupertinoColors.systemRed.withValues(
                                    alpha: 0.1,
                                  ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isDraft ? 'Bản nháp' : 'Chưa thanh toán',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDraft
                                  ? CupertinoColors.systemOrange
                                  : CupertinoColors.systemRed,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CupertinoButton(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            color: CupertinoColors.activeBlue.withValues(
                              alpha: 0.1,
                            ),
                            onPressed: () => _showReminderDialog(context, bill),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.paperplane_fill,
                                  size: 16,
                                  color: CupertinoColors.activeBlue,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Nhắc nợ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: CupertinoColors.activeBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  void _showReminderDialog(BuildContext context, dynamic bill) {
    final amount = bill.totalAmount ?? 0.0;
    final messagePreview =
        'StayHub thông báo:\nPhòng ${bill.roomId} hiện đang nợ cước ${_currencyFmt.format(amount)} (Hóa đơn ${bill.month}/${bill.year}).\nVui lòng thanh toán sớm nhất để không gián đoạn dịch vụ.';

    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: const Text(
            'Gửi thông báo nhắc nợ',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          message: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.kSurfaceBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  messagePreview,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.black,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vui lòng chọn kênh gửi tin nhắn tới khách thuê.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                unawaited(_triggerReminder(bill.id, 'ZALO'));
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.chat_bubble_text_fill,
                    color: Color(0xFF0068FF),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Gửi qua Zalo ZNS',
                    style: TextStyle(
                      color: Color(0xFF0068FF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                unawaited(_triggerReminder(bill.id, 'SMS'));
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.device_phone_portrait,
                    color: CupertinoColors.systemGreen,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Gửi qua tin nhắn SMS',
                    style: TextStyle(
                      color: CupertinoColors.systemGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
        ),
      ),
    );
  }

  Future<void> _triggerReminder(int billId, String channel) async {
    unawaited(
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) =>
            const Center(child: CupertinoActivityIndicator(radius: 16)),
      ),
    );

    try {
      await ref.read(billProvider.notifier).sendDebtReminder(billId, channel);
      if (mounted) {
        Navigator.pop(context); // unawaited(close loading)
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('✅ Thành công'),
              content: Text(
                'Đã gửi thông báo nhắc nợ qua kênh $channel thành công.',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Đóng'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // unawaited(close loading)
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Lỗi'),
              content: Text(e.toString()),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Đóng'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      }
    }
  }
}

// ─── Debt Stat Chip ──────────────────────────────────────────────────────────
class _DebtStatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _DebtStatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
