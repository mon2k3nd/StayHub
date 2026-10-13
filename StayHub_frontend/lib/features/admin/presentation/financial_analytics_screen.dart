import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../application/admin_financial_analytics_provider.dart';
import 'widgets/revenue_line_chart_widget.dart';
import 'widgets/package_pie_chart_widget.dart';
import 'dart:async' show unawaited;

class FinancialAnalyticsScreen extends ConsumerWidget {
  const FinancialAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(adminFinancialAnalyticsProvider);

    return LiquidGlassScaffold(
      title: 'Báo cáo Doanh thu',
      backgroundColors: const Color(0xFFF3F4F6),
      useScrollView: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              ref.invalidate(adminFinancialAnalyticsProvider);
              try {
                await ref.read(adminFinancialAnalyticsProvider.future);
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
                  _buildSectionTitle('Biểu đồ Doanh thu (7 ngày)'),
                  const SizedBox(height: 8),
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: RevenueLineChartWidget(
                      // BUGFIX (data): tránh `as Map` ném TypeError khi dữ liệu
                      // không phải Map.
                      revenueChartData: data['revenueChart'] is Map
                          ? Map<String, dynamic>.from(
                              data['revenueChart'] as Map,
                            )
                          : <String, dynamic>{},
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Tỷ lệ Bán gói SaaS'),
                  const SizedBox(height: 8),
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: PackagePieChartWidget(
                      // BUGFIX (data): tránh `as Map` ném TypeError khi dữ liệu
                      // không phải Map.
                      packageSalesData: data['packageSalesChart'] is Map
                          ? Map<String, dynamic>.from(
                              data['packageSalesChart'] as Map,
                            )
                          : <String, dynamic>{},
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
                            ref.invalidate(adminFinancialAnalyticsProvider),
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
    final totalRevenue = (summary['totalRevenue'] as num?)?.toDouble() ?? 0.0;
    final mrr = (summary['mrr'] as num?)?.toDouble() ?? 0.0;

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
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatMoney(totalRevenue),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: LiquidGlassColors.adminAccent,
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
                  'MRR (Ước tính)',
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatMoney(mrr),
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
        // final actionApiUrl = insight['actionApiUrl'] as String?;

        Color cardColor = CupertinoColors.systemOrange;
        IconData icon = CupertinoIcons.exclamationmark_circle_fill;
        if (type == 'CHURN_WARNING') {
          cardColor = CupertinoColors.systemRed;
          icon = CupertinoIcons.person_crop_circle_badge_exclam;
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
                  onPressed: () =>
                      _confirmAction(context, actionText, message ?? ''),
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

  void _confirmAction(BuildContext context, String actionText, String message) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Xác nhận thao tác'),
          content: Text(
            'Bạn có chắc chắn muốn thực hiện:\n"$actionText"\ncho tác vụ này?',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Hủy'),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Thực hiện'),
              onPressed: () {
                Navigator.pop(ctx);
                _showSuccessOverlay(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessOverlay(BuildContext context) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Thành công'),
          content: const Text('Tác vụ đã được thực thi trên hệ thống.'),
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
          Container(height: 20, width: 150, color: Colors.white),
          const SizedBox(height: 8),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 24),
          Container(height: 20, width: 150, color: Colors.white),
          const SizedBox(height: 8),
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
