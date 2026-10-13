import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/liquid_glass_colors.dart';

class RevenueLineChartWidget extends StatelessWidget {
  final Map<String, dynamic> revenueChartData;

  const RevenueLineChartWidget({super.key, required this.revenueChartData});

  @override
  Widget build(BuildContext context) {
    final minY = (revenueChartData['minY'] as num?)?.toDouble() ?? 0.0;
    final maxY = (revenueChartData['maxY'] as num?)?.toDouble() ?? 5000000.0;
    // BUGFIX (data): tránh `as List` ném TypeError + `p['x'] as num` ném
    // TypeError khi phần tử không phải Map hoặc giá trị sai kiểu.
    final pointsList = (revenueChartData['points'] is List
        ? (revenueChartData['points'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : const <Map<String, dynamic>>[]);

    final spots = pointsList.map((p) {
      final x = p['x'] is num ? (p['x'] as num).toDouble() : 0.0;
      final y = p['y'] is num ? (p['y'] as num).toDouble() : 0.0;
      return FlSpot(x, y);
    }).toList();

    // Prevent FLChart crash if minX == maxX or minY >= maxY
    final safeMinX = spots.isNotEmpty ? spots.first.x : 1.0;
    final rawMaxX = spots.isNotEmpty ? spots.last.x : 7.0;
    final safeMaxX = rawMaxX > safeMinX ? rawMaxX : safeMinX + 1.0;
    final safeMaxY = maxY > minY ? maxY : minY + 1000000.0;

    return AspectRatio(
      aspectRatio: 1.7,
      child: LineChart(
        LineChartData(
          minX: safeMinX,
          maxX: safeMaxX,
          minY: minY,
          maxY: safeMaxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withValues(alpha: 0.2),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget: (value, meta) {
                  if (value == minY || value == maxY) {
                    return const SizedBox.shrink();
                  }
                  // Format value (e.g. 1.000.000 -> 1M)
                  final formatted = value >= 1000000
                      ? '${(value / 1000000).toStringAsFixed(1)}M'
                      : '${(value / 1000).toStringAsFixed(0)}k';
                  return Text(
                    formatted,
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  // Map X value to JSON label
                  // BUGFIX (data): firstWhere với orElse null cần kiểu nullable
                  // — dùng Map<String,dynamic>? để tránh lỗi kiểu.
                  final Map<String, dynamic> point = pointsList
                      .firstWhere(
                        (p) => (p['x'] as num?)?.toDouble() == value,
                        orElse: () => <String, dynamic>{},
                      );
                  if (point.isNotEmpty && point['label'] != null) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        point['label'],
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: LiquidGlassColors.adminAccent,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: LiquidGlassColors.adminAccent.withValues(alpha: 0.2),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final Map<String, dynamic> point = pointsList
                      .firstWhere(
                        (p) => (p['x'] as num?)?.toDouble() == spot.x,
                        orElse: () => <String, dynamic>{},
                      );
                  final tooltipText = point.isNotEmpty && point.containsKey('tooltip') 
                      ? point['tooltip'].toString()
                      : spot.y.toString();
                  return LineTooltipItem(
                    tooltipText,
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
