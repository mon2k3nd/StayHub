import 'package:flutter/material.dart'
    show LinearProgressIndicator, AlwaysStoppedAnimation;
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/components/glass_container.dart';
import '../../../../../core/components/liquid_background.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../application/owner_multi_property_notifier.dart';

class OwnerMultiPropertyScreen extends ConsumerWidget {
  const OwnerMultiPropertyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(multiPropertyProvider);
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Quản Lý Đa Dãy Trọ'),
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
                    SliverToBoxAdapter(
                      child: _buildPortfolioSummary(state, formatter),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildPropertyCard(
                            state.buildings[index],
                            formatter,
                          ),
                          childCount: state.buildings.length,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPortfolioSummary(
    MultiPropertyState state,
    NumberFormat formatter,
  ) {
    final totalRooms = state.buildings.fold(0, (sum, b) => sum + b.totalRooms);
    final occupiedRooms = state.buildings.fold(
      0,
      (sum, b) => sum + b.occupiedRooms,
    );
    final occupancyRate = totalRooms > 0
        ? (occupiedRooms / totalRooms * 100).toInt()
        : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: GlassContainer(
        borderRadius: 24,
        blur: 25,
        color: AppTheme.kAccentColor.withValues(alpha: 0.85),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tổng Doanh Thu Danh Mục',
              style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              formatter.format(state.totalPortfolioRevenue),
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 32,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildStatItem(
                  'Số cơ sở',
                  '${state.buildings.length}',
                  CupertinoIcons.building_2_fill,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: CupertinoColors.white.withValues(alpha: 0.3),
                ),
                _buildStatItem(
                  'Lấp đầy',
                  '$occupancyRate%',
                  CupertinoIcons.person_3_fill,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: CupertinoColors.white.withValues(alpha: 0.3),
                ),
                _buildStatItem(
                  'Phòng trống',
                  '${totalRooms - occupiedRooms}',
                  CupertinoIcons.lock_open,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: CupertinoColors.white, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildPropertyCard(PropertyBuilding building, NumberFormat formatter) {
    final occupancy = (building.occupiedRooms / building.totalRooms);
    final isFull = building.status == 'Kín phòng';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GlassContainer(
        borderRadius: 20,
        blur: 15,
        color: CupertinoColors.white.withValues(alpha: 0.7),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.kAccentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    CupertinoIcons.building_2_fill,
                    color: AppTheme.kAccentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        building.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        building.address,
                        style: const TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isFull
                        ? CupertinoColors.activeGreen.withValues(alpha: 0.1)
                        : AppTheme.kAccentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    building.status,
                    style: TextStyle(
                      color: isFull
                          ? CupertinoColors.activeGreen
                          : AppTheme.kAccentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
                      'Phòng',
                      style: TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${building.occupiedRooms}/${building.totalRooms}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: CupertinoColors.black,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Doanh thu/tháng',
                      style: TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatter.format(building.monthlyRevenue),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppTheme.kAccentColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: occupancy,
                  backgroundColor: CupertinoColors.systemGrey5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isFull
                        ? CupertinoColors.activeGreen
                        : AppTheme.kAccentColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
