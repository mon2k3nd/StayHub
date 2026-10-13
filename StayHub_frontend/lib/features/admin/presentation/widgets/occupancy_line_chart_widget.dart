import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';

class OccupancyLineChartWidget extends StatelessWidget {
  final Map<String, dynamic> occupancyChartData;

  const OccupancyLineChartWidget({super.key, required this.occupancyChartData});

  @override
  Widget build(BuildContext context) {
    // BUGFIX (data): tránh `as List` ném TypeError + `p['y'] as num` ném
    // TypeError khi phần tử không phải Map hoặc giá trị sai kiểu.
    // BUGFIX (data): whereType<Map>() trả Iterable<Map<dynamic,dynamic>> (không
    // có `[]`) — ép về List<Map<String,dynamic>>.
    final pointsList = (occupancyChartData['points'] is List
        ? (occupancyChartData['points'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
        : const <Map<String, dynamic>>[]);

    double maxY = 100.0;

    // We map 'label' directly. But FlSpot needs x as double.
    // So we generate x incrementally
    final spots = <FlSpot>[];
    for (int i = 0; i < pointsList.length; i++) {
      final p = pointsList[i];
      final y = p['y'] is num ? (p['y'] as num).toDouble() : 0.0;
      spots.add(FlSpot((i + 1).toDouble(), y));
    }

    // Prevent FLChart crash if minX == maxX
    final safeMinX = spots.isNotEmpty ? spots.first.x : 1.0;
    final rawMaxX = spots.isNotEmpty ? spots.last.x : 7.0;
    final safeMaxX = rawMaxX > safeMinX ? rawMaxX : safeMinX + 1.0;

    return AspectRatio(
      aspectRatio: 1.7,
      child: LineChart(
        LineChartData(
          minX: safeMinX,
          maxX: safeMaxX,
          minY: 0,
          maxY: maxY,
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
                reservedSize: 35,
                interval: 25,
                getTitlesWidget: (value, meta) {
                  if (value == 0 || value == maxY) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    '${value.toInt()}%',
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
                  int index = value.toInt() - 1;
                  if (index >= 0 && index < pointsList.length) {
                    final point = pointsList[index];
                    if (point['label'] != null) {
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
              color: CupertinoColors.activeBlue,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: CupertinoColors.activeBlue.withValues(alpha: 0.2),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  int index = spot.x.toInt() - 1;
                  String tooltipText = '${spot.y}%';
                  if (index >= 0 && index < pointsList.length) {
                    final point = pointsList[index];
                    tooltipText = point['tooltip']?.toString() ?? tooltipText;
                  }
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
