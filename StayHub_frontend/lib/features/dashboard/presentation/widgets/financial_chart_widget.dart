import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/liquid_glass_colors.dart';

class FinancialChartWidget extends StatelessWidget {
  final List<dynamic> chartData; // List of {month, year, revenue, expenses}

  const FinancialChartWidget({super.key, required this.chartData});

  @override
  Widget build(BuildContext context) {
    // If no data, use empty or dummy
    final data = chartData.isNotEmpty ? chartData : [];

    // Reverse data to display oldest to newest if it's descending from API
    // Actually API returns from month - 5 to current month, so it's already oldest to newest.
    // Let's just map it.
    final months = data.map((e) => 'Th ${e['month']}').toList();

    double maxRevenue = 0;
    for (var e in data) {
      double rev = (e['revenue'] ?? 0).toDouble();
      if (rev > maxRevenue) maxRevenue = rev;
    }
    // Convert to millions for display
    double maxRevenueMillions = maxRevenue / 1000000.0;
    double maxY = maxRevenueMillions > 0
        ? (maxRevenueMillions * 1.2)
        : 100; // 20% padding above max, default 100 if 0

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9CA3AF).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Doanh Thu 6 Tháng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const Text(
            '(Triệu VNĐ)',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF9CA3AF),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return SizedBox(
                height: 220,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => const Color(0xFF111827),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          // rod.toY / value will crash if value is 0.0 (first animation frame)
                          final displayY = value == 0.0
                              ? 0.0
                              : (rod.toY / value);
                          return BarTooltipItem(
                            '${displayY.toStringAsFixed(1)} Tr',
                            const TextStyle(
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) {
                            const style = TextStyle(
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            );
                            String text =
                                val.toInt() >= 0 && val.toInt() < months.length
                                ? months[val.toInt()]
                                : '';
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(text, style: style),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (val, meta) {
                            if (val == 0) return const SizedBox.shrink();
                            return Text(
                              '${val.toInt()}T',
                              style: const TextStyle(
                                color: Color(0xFF9CA3AF),
                                fontSize: 11,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 25,
                      getDrawingHorizontalLine: (val) => const FlLine(
                        color: Color(0xFFF3F4F6),
                        strokeWidth: 1,
                        dashArray: [5, 5],
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(data.length, (index) {
                      final item = data[index];
                      double rev =
                          (item['revenue'] ?? 0).toDouble() / 1000000.0;
                      return _makeGroupData(
                        index,
                        rev * value,
                        isTouched: index == data.length - 1,
                      );
                    }),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, {bool isTouched = false}) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: LinearGradient(
            colors: isTouched
                ? [
                    const Color(0xFF10B981),
                    AppTheme.kBrandDeep,
                  ] // Success to Brand
                : [
                    AppTheme.kBrandLight,
                    AppTheme.kBrandDeep.withValues(alpha: 0.7),
                  ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
          width: 22,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 100,
            color: const Color(0xFFF3F4F6),
          ),
        ),
      ],
    );
  }
}
