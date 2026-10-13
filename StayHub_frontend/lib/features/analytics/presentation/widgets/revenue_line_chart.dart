import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/owner_analytics_model.dart';

class RevenueLineChart extends StatelessWidget {
  final List<RevenuePoint> points;

  const RevenueLineChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return AspectRatio(
        aspectRatio: 1.70,
        child: Container(
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: CupertinoColors.systemGrey6),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.kAccentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.chart_bar_square_fill,
                    size: 40,
                    color: AppTheme.kAccentColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chưa có dữ liệu giao dịch',
                  style: TextStyle(
                    color: CupertinoColors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Dữ liệu biểu đồ sẽ hiển thị khi có hóa đơn đầu tiên.',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final maxVal = points.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final currencyFmt = NumberFormat.compactCurrency(
      locale: 'vi_VN',
      symbol: 'đ',
    );

    List<Color> gradientColors = [
      CupertinoColors.systemBlue,
      AppTheme.kAccentColor,
    ];

    return AspectRatio(
      aspectRatio: 1.70,
      child: Padding(
        padding: const EdgeInsets.only(
          right: 18,
          left: 12,
          top: 24,
          bottom: 12,
        ),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: maxVal > 0 ? maxVal / 4 : 1,
              verticalInterval: 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: const Color(0xff37434d).withValues(alpha: 0.1),
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: const Color(0xff37434d).withValues(alpha: 0.1),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < points.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          points[index].label,
                          style: const TextStyle(
                            color: Color(0xff68737d),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: maxVal > 0 ? maxVal / 4 : 1,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      currencyFmt.format(value),
                      style: const TextStyle(
                        color: Color(0xff67727d),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    );
                  },
                  reservedSize: 50,
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(
                color: const Color(0xff37434d).withValues(alpha: 0.1),
              ),
            ),
            minX: 0,
            maxX: (points.length - 1).toDouble(),
            minY: 0,
            maxY: maxVal > 0 ? maxVal * 1.2 : 10,
            lineBarsData: [
              LineChartBarData(
                spots: points
                    .asMap()
                    .entries
                    .map((e) => FlSpot(e.key.toDouble(), e.value.y))
                    .toList(),
                isCurved: true,
                gradient: LinearGradient(colors: gradientColors),
                barWidth: 4,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: gradientColors
                        .map((color) => color.withValues(alpha: 0.2))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
