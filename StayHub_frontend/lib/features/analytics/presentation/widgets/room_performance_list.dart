import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../../data/models/owner_analytics_model.dart';
import '../../../../core/components/glass_container.dart';

class RoomPerformanceList extends StatelessWidget {
  final List<RoomPerformance> rooms;

  const RoomPerformanceList({super.key, required this.rooms});

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) return const SizedBox();

    final currencyFmt = NumberFormat.compactCurrency(
      locale: 'vi_VN',
      symbol: 'd',
    );

    return Column(
      children: rooms.map((room) {
        final isLoss = room.revenue == 0;
        final color = isLoss
            ? CupertinoColors.systemRed
            : CupertinoColors.systemGreen;
        final icon = isLoss
            ? CupertinoIcons.arrow_down_right_square_fill
            : CupertinoIcons.chart_bar_fill;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        room.roomName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: CupertinoColors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        room.status,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  currencyFmt.format(room.revenue),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: isLoss
                        ? CupertinoColors.systemRed
                        : CupertinoColors.black,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
