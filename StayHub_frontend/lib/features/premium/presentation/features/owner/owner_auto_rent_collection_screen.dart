import 'package:flutter/material.dart'
    show LinearProgressIndicator, AlwaysStoppedAnimation;
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/components/glass_container.dart';
import '../../../../../core/components/liquid_background.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../application/owner_auto_rent_notifier.dart';

class OwnerAutoRentCollectionScreen extends ConsumerWidget {
  const OwnerAutoRentCollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(autoRentProvider);
    final notifier = ref.read(autoRentProvider.notifier);

    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final allSelected =
        state.tenantInvoices.isNotEmpty &&
        state.tenantInvoices
            .where((inv) => inv['status'] == 'Chờ thu')
            .every((inv) => inv['selected'] == true);
    final pendingCount = state.tenantInvoices
        .where((inv) => inv['status'] == 'Chờ thu')
        .length;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Thu Tiền Tự Động',
          style: TextStyle(color: CupertinoColors.black),
        ),
        backgroundColor: const Color(0x00000000),
        border: null,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(
            CupertinoIcons.settings,
            color: CupertinoColors.black,
          ),
          onPressed: () {},
        ),
      ),
      child: LiquidBackground(
        colors: AppTheme.kBackgroundLight,
        child: SafeArea(
          child: state.isLoading
              ? const Center(child: CupertinoActivityIndicator(radius: 20))
              : Column(
                  children: [
                    _buildSummaryHeader(state, formatter),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        itemCount: state.tenantInvoices.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Hóa Đơn Chờ Thu',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: CupertinoColors.black,
                                    ),
                                  ),
                                  if (pendingCount > 0)
                                    GestureDetector(
                                      onTap: () =>
                                          notifier.selectAll(!allSelected),
                                      child: Text(
                                        allSelected
                                            ? 'Bỏ chọn tất cả'
                                            : 'Chọn tất cả',
                                        style: const TextStyle(
                                          color: AppTheme.kAccentColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }
                          final inv = state.tenantInvoices[index - 1];
                          return _buildInvoiceItem(
                            inv,
                            () => notifier.toggleSelection(index - 1),
                            formatter,
                          );
                        },
                      ),
                    ),
                    _buildBottomAction(state, notifier),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(AutoRentState state, NumberFormat formatter) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: GlassContainer(
        borderRadius: 24,
        blur: 20,
        color: AppTheme.kAccentColor.withValues(alpha: 0.1),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.kAccentColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    CupertinoIcons.money_dollar,
                    color: CupertinoColors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đã thu tháng này',
                        style: TextStyle(
                          color: AppTheme.kTextSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatter.format(state.totalAmountCollected),
                        style: const TextStyle(
                          color: AppTheme.kTextPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (state.isCollecting) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text(
                    'Đang thu tiền...',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.kAccentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(state.collectionProgress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.kAccentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 6,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: state.collectionProgress,
                    backgroundColor: AppTheme.kAccentColor.withValues(
                      alpha: 0.2,
                    ),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.kAccentColor,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceItem(
    Map<String, dynamic> inv,
    VoidCallback onTap,
    NumberFormat formatter,
  ) {
    final isPending = inv['status'] == 'Chờ thu';
    final isSelected = inv['selected'] == true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: isPending ? onTap : null,
        child: GlassContainer(
          borderRadius: 20,
          color: CupertinoColors.white.withValues(alpha: 0.7),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (isPending)
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.kAccentColor
                          : CupertinoColors.systemGrey3,
                      width: 2,
                    ),
                    color: isSelected
                        ? AppTheme.kAccentColor
                        : CupertinoColors.white,
                  ),
                  child: isSelected
                      ? const Icon(
                          CupertinoIcons.checkmark_alt,
                          size: 16,
                          color: CupertinoColors.white,
                        )
                      : null,
                )
              else
                Container(
                  margin: const EdgeInsets.only(right: 16),
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: CupertinoColors.activeGreen,
                  ),
                  child: const Icon(
                    CupertinoIcons.checkmark_alt,
                    size: 16,
                    color: CupertinoColors.white,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phòng ${inv['room']} - ${inv['tenant']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: CupertinoColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      inv['status'],
                      style: TextStyle(
                        color: isPending
                            ? CupertinoColors.systemOrange
                            : CupertinoColors.activeGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatter.format(inv['amount']),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: CupertinoColors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction(AutoRentState state, AutoRentNotifier notifier) {
    final selectedCount = state.tenantInvoices
        .where((inv) => inv['selected'] == true && inv['status'] == 'Chờ thu')
        .length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 16),
          color: AppTheme.kAccentColor,
          disabledColor: CupertinoColors.systemGrey4,
          borderRadius: BorderRadius.circular(20),
          onPressed: (selectedCount > 0 && !state.isCollecting)
              ? () => notifier.startAutoCollection()
              : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.isCollecting)
                const CupertinoActivityIndicator(color: CupertinoColors.white)
              else ...[
                const Icon(
                  CupertinoIcons.wand_stars,
                  color: CupertinoColors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  'Thu Tiền Tự Động ($selectedCount)',
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
