import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/liquid_glass_colors.dart';

import 'package:fl_chart/fl_chart.dart';
import '../../../../core/components/glass_container.dart';

class RevenueChart extends StatelessWidget {
  final List<dynamic>? chartData;

  const RevenueChart({super.key, this.chartData});

  /// BUGFIX (data): coerce an toàn sang double — tránh `as double` ném
  /// TypeError khi giá trị là int/String.
  double _num(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> dataToRender = [];
    if (chartData != null && chartData!.isNotEmpty) {
      dataToRender = chartData!.map((e) {
        return {
          'month': 'T${e['month']}',
          'revenue': ((e['revenue'] as num?)?.toDouble() ?? 0.0) / 1000000.0,
          'expense': ((e['expenses'] as num?)?.toDouble() ?? 0.0) / 1000000.0,
        };
      }).toList();
    } else {
      final now = DateTime.now();
      for (int i = 5; i >= 0; i--) {
        final d = DateTime(now.year, now.month - i, 1);
        dataToRender.add({
          'month': 'T${d.month}',
          'revenue': 0.0,
          'expense': 0.0,
        });
      }
    }

    return GlassContainer(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        children: [
          Row(
            children: [
              _chartLegend(AppTheme.kAccentColor, 'Doanh thu'),
              const SizedBox(width: 20),
              _chartLegend(CupertinoColors.systemRed, 'Chi phí'),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 35,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF1A1A2E),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final val = rod.toY.toStringAsFixed(1);
                      final label = rodIndex == 0
                          ? 'Thu: ${val}tr'
                          : 'Chi: ${val}tr';
                      return BarTooltipItem(
                        label,
                        TextStyle(
                          color: rodIndex == 0
                              ? AppTheme.kAccentColor
                              : CupertinoColors.systemRed,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
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
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= dataToRender.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            dataToRender[idx]['month'],
                            style: const TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: 10,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}',
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: CupertinoColors.white,
                    strokeWidth: 1,
                  ),
                ),
                barGroups: dataToRender.asMap().entries.map((e) {
                  final idx = e.key;
                  final data = e.value;
                  return BarChartGroupData(
                    x: idx,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        // BUGFIX (data): trước đây ép `as double` — nếu giá
                        // trị là int/String thì ném TypeError và biểu đồ
                        // doanh thu không render. Coerce an toàn.
                        toY: _num(data['revenue']),
                        width: 12,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppTheme.kAccentColor,
                            AppTheme.kAccentColor,
                          ],
                        ),
                      ),
                      BarChartRodData(
                        toY: _num(data['expense']),
                        width: 12,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            CupertinoColors.systemRed,
                            CupertinoColors.systemRed,
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Color(0xFF4B5563), fontSize: 12),
        ),
      ],
    );
  }
}
