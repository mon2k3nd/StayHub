import 'package:flutter/cupertino.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/components/glass_container.dart';
import 'dart:async' show unawaited;

class AdminSaasChart extends StatefulWidget {
  final Map<String, dynamic> stats;
  const AdminSaasChart({super.key, required this.stats});

  @override
  State<AdminSaasChart> createState() => _AdminSaasChartState();
}

class _AdminSaasChartState extends State<AdminSaasChart>
    with SingleTickerProviderStateMixin {
  int touchedIndex = -1;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const _palette = [
    Color(0xFF298FFF), // VIP - Sky Blue
    Color(0xFF298FFF), // Pro - Sky Blue
    Color(0xFF10B981), // Basic - Green
    Color(0xFFF59E0B), // Free - Amber
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    unawaited(_animController.forward());
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutQuart,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? saasStats =
        widget.stats['saasPackageRatio'] as Map<String, dynamic>?;

    if (saasStats == null || saasStats.isEmpty) {
      return const GlassContainer(
        padding: EdgeInsets.all(24),
        borderRadius: 24,
        child: Row(
          children: [
            Icon(
              CupertinoIcons.chart_pie_fill,
              color: Color(0xFFD1D5DB),
              size: 32,
            ),
            SizedBox(width: 12),
            Text(
              'Chưa có dữ liệu gói SaaS',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
            ),
          ],
        ),
      );
    }

    final entries = saasStats.entries.toList();
    int total = 0;
    for (final e in entries) {
      total += (e.value as num).toInt();
    }

    final sections = <PieChartSectionData>[];
    for (int i = 0; i < entries.length; i++) {
      final val = (entries[i].value as num).toDouble();
      final isTouched = i == touchedIndex;
      final color = _palette[i % _palette.length];
      sections.add(
        PieChartSectionData(
          value: val,
          title: isTouched ? '${val.toInt()}' : '',
          color: color,
          radius: isTouched ? 72 : 60,
          titleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: CupertinoColors.white,
          ),
          borderSide: isTouched
              ? BorderSide(color: color, width: 3)
              : const BorderSide(color: Color(0x00000000)),
        ),
      );
    }

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      blur: 20,
      color: const Color(0xCCFFFFFF),
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Row(
          children: [
            // ── Donut Chart ──
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                response == null ||
                                response.touchedSection == null) {
                              touchedIndex = -1;
                            } else {
                              touchedIndex =
                                  response.touchedSection!.touchedSectionIndex;
                            }
                          });
                        },
                      ),
                      sectionsSpace: 3,
                      centerSpaceRadius: 44,
                      startDegreeOffset: -90,
                      sections: sections,
                    ),
                  ),
                  // Center text
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$total',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: CupertinoColors.black,
                          letterSpacing: -1,
                        ),
                      ),
                      const Text(
                        'Chủ nhà',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            // ── Legend ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Phân bổ gói',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF374151),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(entries.length, (i) {
                    final val = (entries[i].value as num).toDouble();
                    final pct = total > 0 ? (val / total * 100).round() : 0;
                    final color = _palette[i % _palette.length];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entries[i].key,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '$pct%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
