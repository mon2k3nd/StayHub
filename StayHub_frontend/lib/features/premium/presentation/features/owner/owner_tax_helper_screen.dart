import 'package:flutter/material.dart' show Divider;
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/components/glass_container.dart';
import '../../../../../core/components/liquid_background.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../application/owner_tax_notifier.dart';

class OwnerTaxHelperScreen extends ConsumerWidget {
  const OwnerTaxHelperScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(taxProvider);
    final notifier = ref.read(taxProvider.notifier);
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text(
          'Khai Thuế Chủ Nhà',
          style: TextStyle(color: CupertinoColors.black),
        ),
        backgroundColor: Color(0x00000000),
        border: null,
      ),
      child: LiquidBackground(
        colors: AppTheme.kBackgroundLight,
        child: SafeArea(
          child: state.isLoading
              ? const Center(child: CupertinoActivityIndicator(radius: 20))
              : CustomScrollView(
                  slivers: [
                    CupertinoSliverRefreshControl(
                      onRefresh: () async {
                        await Future.delayed(
                          const Duration(milliseconds: 1000),
                        );
                      },
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(24.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final tax = state.taxPeriods[index];
                          return _buildTaxCard(
                            tax,
                            notifier,
                            formatter,
                            state.isGenerating,
                          );
                        }, childCount: state.taxPeriods.length),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTaxCard(
    TaxPeriod tax,
    TaxNotifier notifier,
    NumberFormat formatter,
    bool isGenerating,
  ) {
    final isPending = tax.status == 'Chưa nộp';

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: GlassContainer(
        borderRadius: 24,
        blur: 20,
        color: CupertinoColors.white.withValues(alpha: 0.9),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isPending
                            ? AppTheme.kAccentColor.withValues(alpha: 0.1)
                            : CupertinoColors.activeGreen.withValues(
                                alpha: 0.1,
                              ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.doc_chart_fill,
                        color: isPending
                            ? AppTheme.kAccentColor
                            : CupertinoColors.activeGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kỳ tính thuế: ${tax.periodName}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: CupertinoColors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hạn nộp: ${DateFormat('dd/MM/yyyy').format(tax.deadline)}',
                          style: TextStyle(
                            color: isPending
                                ? CupertinoColors.destructiveRed
                                : CupertinoColors.systemGrey,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isPending
                        ? CupertinoColors.systemOrange.withValues(alpha: 0.1)
                        : CupertinoColors.activeGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tax.status,
                    style: TextStyle(
                      color: isPending
                          ? CupertinoColors.systemOrange
                          : CupertinoColors.activeGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(color: CupertinoColors.systemGrey4),
            ),
            _buildAmountRow(
              'Tổng doanh thu:',
              formatter.format(tax.totalRevenue),
            ),
            const SizedBox(height: 12),
            _buildAmountRow(
              'Chi phí được trừ:',
              formatter.format(tax.deductibleExpenses),
            ),
            const SizedBox(height: 12),
            _buildAmountRow(
              'Thu nhập chịu thuế:',
              formatter.format(tax.taxableIncome),
            ),
            const SizedBox(height: 12),
            _buildAmountRow(
              'Thuế dự kiến (AI):',
              formatter.format(tax.estimatedTax),
              isHighlight: true,
            ),
            const SizedBox(height: 24),
            if (isPending) ...[
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      color: CupertinoColors.systemGrey5,
                      borderRadius: BorderRadius.circular(16),
                      onPressed: isGenerating
                          ? null
                          : () => notifier.generateTaxReport(tax.id),
                      child: isGenerating
                          ? const CupertinoActivityIndicator()
                          : const Text(
                              'Xuất Báo Cáo',
                              style: TextStyle(
                                color: CupertinoColors.black,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      color: AppTheme.kAccentColor,
                      borderRadius: BorderRadius.circular(16),
                      onPressed: () => notifier.markAsPaid(tax.id),
                      child: const Text(
                        'Đã Nộp Thuế',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: CupertinoColors.systemGrey,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: isHighlight ? AppTheme.kAccentColor : CupertinoColors.black,
          ),
        ),
      ],
    );
  }
}
