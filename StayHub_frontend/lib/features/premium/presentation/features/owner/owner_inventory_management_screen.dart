import 'package:flutter/material.dart' show Divider;
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/components/glass_container.dart';
import '../../../../../core/components/liquid_background.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../application/owner_inventory_notifier.dart';

class OwnerInventoryManagementScreen extends ConsumerWidget {
  const OwnerInventoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inventoryProvider);
    final notifier = ref.read(inventoryProvider.notifier);
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Kho Tài Sản & Thiết Bị'),
        backgroundColor: const Color(0x00000000),
        border: null,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add_circled),
          onPressed: () {},
        ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = state.items[index];
                          return _buildInventoryCard(item, notifier, formatter);
                        }, childCount: state.items.length),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildInventoryCard(
    InventoryItem item,
    InventoryNotifier notifier,
    NumberFormat formatter,
  ) {
    final totalValue = item.quantity * item.unitPrice;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
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
                        color: AppTheme.kAccentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        CupertinoIcons.cube_box_fill,
                        color: AppTheme.kAccentColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: CupertinoColors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.category,
                          style: const TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.ellipsis_circle),
                  onPressed: () {},
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(color: CupertinoColors.systemGrey4),
            ),
            Row(
              children: [
                _buildStatColumn(
                  'Tổng',
                  '${item.quantity}',
                  CupertinoColors.black,
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: CupertinoColors.systemGrey4,
                ),
                _buildStatColumn(
                  'Đang dùng',
                  '${item.inUse}',
                  CupertinoColors.activeBlue,
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: CupertinoColors.systemGrey4,
                ),
                _buildStatColumn(
                  'Hỏng',
                  '${item.broken}',
                  CupertinoColors.destructiveRed,
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: CupertinoColors.systemGrey4,
                ),
                _buildStatColumn(
                  'Sẵn sàng',
                  '${item.available}',
                  CupertinoColors.activeGreen,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tổng giá trị:',
                      style: TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatter.format(totalValue),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppTheme.kAccentColor,
                      ),
                    ),
                  ],
                ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: CupertinoColors.destructiveRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  onPressed: () => notifier.reportBroken(item.id),
                  child: const Text(
                    'Báo hỏng',
                    style: TextStyle(
                      color: CupertinoColors.destructiveRed,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
