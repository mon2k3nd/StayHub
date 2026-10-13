import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/components/glass_container.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../application/owner_analytics_provider.dart';
import 'widgets/revenue_line_chart_widget.dart';
import 'dart:async' show unawaited;

class OwnerAnalyticsDetailScreen extends ConsumerWidget {
  final int ownerId;

  const OwnerAnalyticsDetailScreen({super.key, required this.ownerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(ownerAnalyticsProvider(ownerId));

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Phân Tích Chủ Nhà'),
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        previousPageTitle: 'Quay lại',
      ),
      child: SafeArea(
        child: analyticsAsync.when(
          data: (data) => _buildContent(context, data),
          loading: () => _buildSkeletonLoading(),
          error: (err, stack) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  color: CupertinoColors.systemRed,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Lỗi: $err',
                  style: const TextStyle(color: CupertinoColors.systemRed),
                ),
                const SizedBox(height: 16),
                CupertinoButton.filled(
                  child: const Text('Thử lại'),
                  onPressed: () =>
                      ref.invalidate(ownerAnalyticsProvider(ownerId)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> data) {
    // BUGFIX (data): tránh `as Map<String, dynamic>?` ném TypeError khi giá trị
    // không phải Map (ví dụ List/String) — chỉ nhận khi thực sự là Map.
    final ownerInfo = data['ownerInfo'] is Map
        ? Map<String, dynamic>.from(data['ownerInfo'] as Map)
        : <String, dynamic>{};
    final roiSummary = data['roiSummary'] is Map
        ? Map<String, dynamic>.from(data['roiSummary'] as Map)
        : <String, dynamic>{};
    final roomRanks = data['roomPerformanceRank'] is List
        ? (data['roomPerformanceRank'] as List).whereType<Map>().toList()
        : <Map>[];
    final insights = data['actionableInsights'] is List
        ? (data['actionableInsights'] as List).whereType<Map>().toList()
        : <Map>[];

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildOwnerHeader(ownerInfo),
              const SizedBox(height: 16),
              _buildSummaryCards(roiSummary),
              const SizedBox(height: 16),
              _buildActionableInsights(context, insights),
              const SizedBox(height: 16),
              _buildSectionTitle('Dòng tiền cá nhân (30 ngày)'),
              const SizedBox(height: 8),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: RevenueLineChartWidget(
                  // BUGFIX (data): tránh `as Map` ném TypeError khi dữ liệu
                  // không phải Map.
                  revenueChartData: data['revenueTrendChart'] is Map
                      ? Map<String, dynamic>.from(
                          data['revenueTrendChart'] as Map,
                        )
                      : <String, dynamic>{},
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Top Phòng Sinh Lời'),
              const SizedBox(height: 8),
              // BUGFIX (data): lọc an toàn — tránh `as Map<String, dynamic>` ném
              // TypeError khi phần tử không phải Map.
              ...roomRanks.whereType<Map>().map(
                (r) => _buildRoomRankTile(Map<String, dynamic>.from(r)),
              ),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerHeader(Map<String, dynamic> ownerInfo) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: LiquidGlassColors.adminAccent.withValues(
              alpha: 0.2,
            ),
            child: const Icon(
              CupertinoIcons.person_fill,
              color: LiquidGlassColors.adminAccent,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ownerInfo['fullName'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemYellow.withValues(
                          alpha: 0.2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ownerInfo['packageStatus'] ?? 'FREE',
                        style: const TextStyle(
                          color: CupertinoColors.systemYellow,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      CupertinoIcons.star_fill,
                      color: CupertinoColors.systemYellow,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${ownerInfo['trustScore'] ?? 5.0}',
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> summary) {
    final totalRevenue = (summary['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    final totalRooms = (summary['totalRooms'] as num?)?.toInt() ?? 0;
    final occupancyRate = (summary['occupancyRate'] as num?)?.toDouble() ?? 0.0;

    return Row(
      children: [
        Expanded(
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tổng Doanh Thu',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatMoney(totalRevenue),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: LiquidGlassColors.adminAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lấp đầy',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Text(
                  '$occupancyRate% ($totalRooms P)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomRankTile(Map<String, dynamic> rank) {
    final revenue = (rank['revenue'] as num?)?.toDouble() ?? 0.0;
    final isZero = revenue == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isZero
                  ? CupertinoColors.systemRed.withValues(alpha: 0.1)
                  : CupertinoColors.systemGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isZero
                  ? CupertinoIcons.exclamationmark_triangle_fill
                  : CupertinoIcons.building_2_fill,
              color: isZero
                  ? CupertinoColors.systemRed
                  : CupertinoColors.systemGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rank['roomName'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rank['status'] ?? '',
                  style: TextStyle(
                    color: isZero ? CupertinoColors.systemRed : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatMoney(revenue),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isZero ? Colors.grey : LiquidGlassColors.adminAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionableInsights(
    BuildContext context,
    List<dynamic> insights,
  ) {
    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      children: insights.map((insight) {
        final message = insight['message'] as String?;
        final actionText = insight['actionText'] as String?;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CupertinoColors.systemOrange.withValues(alpha: 0.1),
            border: Border.all(
              color: CupertinoColors.systemOrange.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                CupertinoIcons.gift_fill,
                color: CupertinoColors.systemOrange,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message ?? '',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
              if (actionText != null)
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  color: CupertinoColors.systemOrange,
                  borderRadius: BorderRadius.circular(8),
                  minimumSize: Size.zero,
                  onPressed: () => _showSuccessOverlay(context),
                  child: Text(
                    actionText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showSuccessOverlay(BuildContext context) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Thành công'),
          content: const Text('Đã tặng Voucher Up-sale cho Chủ nhà.'),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMoney(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}B đ';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M đ';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k đ';
    }
    return '${amount.toStringAsFixed(0)} đ';
  }
}
