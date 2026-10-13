import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PackagePieChartWidget extends StatelessWidget {
  final Map<String, dynamic> packageSalesData;

  const PackagePieChartWidget({super.key, required this.packageSalesData});

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    // BUGFIX (data): tránh `as List` ném TypeError + `s['value'] as num` ném
    // TypeError khi phần tử không phải Map hoặc giá trị sai kiểu.
    final sectionsData = (packageSalesData['sections'] is List
        ? (packageSalesData['sections'] as List).whereType<Map>()
        : const <Map>[]);
    final totalSold = packageSalesData['totalSold'] ?? 0;

    if (totalSold == 0 || sectionsData.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'Chưa có dữ liệu bán gói',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final pieSections = sectionsData.map((s) {
      // BUGFIX (data): ép kiểu an toàn — tránh TypeError khi giá trị sai kiểu.
      final value = s['value'] is num ? (s['value'] as num).toDouble() : 0.0;
      final colorHex = (s['color'] ?? '#69b1ff').toString();
      final percentage = s['percentage'] is num
          ? (s['percentage'] as num).toDouble()
          : 0.0;

      return PieChartSectionData(
        value: value,
        color: _hexToColor(colorHex),
        title: '$percentage%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: pieSections,
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Chú thích (Legend)
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: sectionsData.map((s) {
            // BUGFIX (data): tránh `as String` ném TypeError khi title/color
            // là null/kiểu khác.
            final title = (s['title'] ?? '').toString();
            final colorHex = (s['color'] ?? '#69b1ff').toString();
            final value = s['value'];
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 12, height: 12, color: _hexToColor(colorHex)),
                const SizedBox(width: 4),
                Text(
                  '$title ($value)',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
