import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../../core/components/glass_container.dart';
import '../../../../../core/components/liquid_background.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../application/owner_ai_financial_notifier.dart';

class OwnerAiFinancialScreen extends ConsumerWidget {
  const OwnerAiFinancialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiFinancialProvider);
    final notifier = ref.read(aiFinancialProvider.notifier);
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('AI Phân Tích Tài Chính'),
        backgroundColor: const Color(0x00000000),
        border: null,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.refresh),
          onPressed: () => notifier.refreshAnalysis(),
        ),
      ),
      child: LiquidBackground(
        colors: AppTheme.kBackgroundLight,
        child: SafeArea(
          child: state.isAnalyzing
              ? _buildAnalyzingView()
              : _buildDashboard(state, formatter),
        ),
      ),
    );
  }

  Widget _buildAnalyzingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.kGlassColorLight,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.kAccentColor.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const CupertinoActivityIndicator(
              radius: 30,
              color: AppTheme.kAccentColor,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'AI Đang Xử Lý Dữ Liệu...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Phân tích luồng tiền, hành vi người thuê\nvà dự báo xu hướng thị trường.',
            textAlign: TextAlign.center,
            style: TextStyle(color: CupertinoColors.systemGrey, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(AiFinancialState state, NumberFormat formatter) {
    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 1000));
          },
        ),
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildHighlightCard(state, formatter),
              const SizedBox(height: 24),
              const Text(
                'Biểu Đồ Doanh Thu & Dự Báo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.black,
                ),
              ),
              const SizedBox(height: 16),
              _buildChartCard(state),
              const SizedBox(height: 24),
              const Text(
                'Đề Xuất Từ AI',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.black,
                ),
              ),
              const SizedBox(height: 16),
              ...state.aiInsights.map((insight) => _buildInsightCard(insight)),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightCard(AiFinancialState state, NumberFormat formatter) {
    return GlassContainer(
      borderRadius: 24,
      blur: 20,
      color: AppTheme.kAccentColor.withValues(alpha: 0.8),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.sparkles,
                color: CupertinoColors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Hiệu Suất Tổng Thể',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.arrow_up_right,
                      color: CupertinoColors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${state.projectedGrowth}%',
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            formatter.format(state.currentMonthRevenue),
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 32,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Doanh thu dự kiến tháng này (đã đạt mức an toàn)',
            style: TextStyle(color: Color(0xB3FFFFFF), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(AiFinancialState state) {
    return GlassContainer(
      borderRadius: 24,
      blur: 20,
      color: CupertinoColors.white.withValues(alpha: 0.7),
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 20,
              getDrawingHorizontalLine: (value) => const FlLine(
                color: CupertinoColors.systemGrey5,
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => Text(
                    '${value.toInt()}tr',
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              bottomTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX:
                (state.revenueData.length +
                        state.projectedRevenueData.length -
                        2)
                    .toDouble(),
            minY: 100,
            maxY: 200,
            lineBarsData: [
              // Lịch sử
              LineChartBarData(
                spots: state.revenueData
                    .asMap()
                    .entries
                    .map((e) => FlSpot(e.key.toDouble(), e.value))
                    .toList(),
                isCurved: true,
                color: CupertinoColors.black,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: CupertinoColors.black.withValues(alpha: 0.1),
                ),
              ),
              // Dự báo (AI)
              LineChartBarData(
                spots: state.projectedRevenueData
                    .asMap()
                    .entries
                    .map(
                      (e) => FlSpot(
                        (e.key + state.revenueData.length - 1).toDouble(),
                        e.value,
                      ),
                    )
                    .toList(),
                isCurved: true,
                color: AppTheme.kAccentColor,
                barWidth: 3,
                dashArray: [5, 5],
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppTheme.kAccentColor.withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightCard(String insight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GlassContainer(
        borderRadius: 16,
        color: CupertinoColors.white.withValues(alpha: 0.8),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.kAccentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.lightbulb_fill,
                color: AppTheme.kAccentColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                insight,
                style: const TextStyle(
                  color: CupertinoColors.black,
                  height: 1.5,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
