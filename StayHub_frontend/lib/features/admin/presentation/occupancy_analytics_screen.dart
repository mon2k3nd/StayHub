import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../application/admin_occupancy_analytics_provider.dart';
import 'widgets/occupancy_line_chart_widget.dart';
import 'widgets/package_pie_chart_widget.dart'; // We can reuse this for demographics!
import 'dart:async' show unawaited;

class OccupancyAnalyticsScreen extends ConsumerWidget {
  const OccupancyAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(adminOccupancyAnalyticsProvider);

    return LiquidGlassScaffold(
      title: 'Lấp đầy & Phân khúc',
      backgroundColors: const Color(0xFFF3F4F6),
      useScrollView: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              ref.invalidate(adminOccupancyAnalyticsProvider);
              try {
                await ref.read(adminOccupancyAnalyticsProvider.future);
              } catch (e, st) {
                debugPrint('Error: $e\n$st');
              }
            },
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: analyticsAsync.when(
              data: (data) => SliverList(
                delegate: SliverChildListDelegate([
                  // BUGFIX (data): tránh `as Map`/`as List` ném TypeError khi
                  // dữ liệu không đúng kiểu — chỉ nhận khi thực sự đúng kiểu.
                  _buildSummaryCards(
                    data['summary'] is Map
                        ? Map<String, dynamic>.from(data['summary'] as Map)
                        : <String, dynamic>{},
                  ),
                  const SizedBox(height: 16),
                  _buildActionableInsights(
                    context,
                    data['actionableInsights'] is List
                        ? (data['actionableInsights'] as List)
                              .whereType<Map>()
                              .toList()
                        : <Map>[],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Xu hướng Lấp đầy (7 ngày)'),
                  const SizedBox(height: 8),
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: OccupancyLineChartWidget(
                      occupancyChartData:
                          data['occupancyTrendChart']
                              as Map<String, dynamic>? ??
                          {},
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Phân khúc Nghề nghiệp'),
                  const SizedBox(height: 8),
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    // Reusing PackagePieChartWidget, it just needs a Map with 'sections' list
                    child: PackagePieChartWidget(
                      packageSalesData: {
                        'sections':
                            (data['demographicsChart']
                                as Map<String, dynamic>?)?['occupation'] ??
                            [],
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Phân khúc Độ tuổi'),
                  const SizedBox(height: 8),
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: PackagePieChartWidget(
                      packageSalesData: {
                        'sections':
                            (data['demographicsChart']
                                as Map<String, dynamic>?)?['ageGroup'] ??
                            [],
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                ]),
              ),
              loading: () =>
                  SliverFillRemaining(child: _buildSkeletonLoading()),
              error: (err, stack) => SliverFillRemaining(
                child: Center(
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
                        style: const TextStyle(
                          color: CupertinoColors.systemRed,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      CupertinoButton.filled(
                        child: const Text('Thử lại'),
                        onPressed: () =>
                            ref.invalidate(adminOccupancyAnalyticsProvider),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> summary) {
    final totalRooms = (summary['totalRooms'] as num?)?.toInt() ?? 0;
    final occupancyRate = (summary['occupancyRate'] as num?)?.toDouble() ?? 0.0;
    final availableRooms = (summary['availableRooms'] as num?)?.toInt() ?? 0;

    return Row(
      children: [
        Expanded(
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tỷ lệ lấp đầy',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  '$occupancyRate%',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.activeBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Phòng trống',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  '$availableRooms / $totalRooms',
                  style: const TextStyle(
                    fontSize: 20,
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

  Widget _buildActionableInsights(
    BuildContext context,
    List<dynamic> insights,
  ) {
    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      children: insights.map((insight) {
        final type = insight['type'] as String?;
        final message = insight['message'] as String?;
        final actionText = insight['actionText'] as String?;

        Color cardColor = CupertinoColors.systemOrange;
        IconData icon = CupertinoIcons.wrench_fill;
        if (type == 'MAINTENANCE_WARNING') {
          cardColor = CupertinoColors.systemRed;
          icon = CupertinoIcons.exclamationmark_triangle_fill;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardColor.withValues(alpha: 0.1),
            border: Border.all(color: cardColor.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: cardColor, size: 28),
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
                  color: cardColor,
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
          title: const Text('Hệ thống'),
          content: const Text('Đã điều hướng đến màn hình bảo trì.'),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 16),
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
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
    );
  }
}
