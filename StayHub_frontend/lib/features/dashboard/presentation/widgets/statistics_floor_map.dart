import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../room/data/models/room_model.dart';
import 'statistics_room_detail_modal.dart';

class StatisticsFloorMap extends ConsumerWidget {
  final List<RoomModel> branchRooms;

  const StatisticsFloorMap({super.key, required this.branchRooms});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (branchRooms.isEmpty) return const SizedBox.shrink();

    final floors = _groupByFloor(branchRooms);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _legendRow(),
        const SizedBox(height: 16),
        ...floors.entries.map((entry) {
          final floorLabel = entry.key;
          final floorRooms = entry.value;
          floorRooms.sort((a, b) => a.roomName.compareTo(b.roomName));
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Floor label
                Container(
                  width: 50,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.kBorderColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Tầng',
                        style: TextStyle(
                          color: AppTheme.kTextSecondary,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        floorLabel.replaceAll('Tầng ', ''),
                        style: const TextStyle(
                          color: AppTheme.kTextPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Room cells - wrap so they flow to next row if needed
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: floorRooms
                        .map<Widget>((r) => _buildRoomCell(r, context, ref))
                        .toList(),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _legendRow() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _legendDot(CupertinoColors.systemGreen, 'Trống'),
        _legendDot(CupertinoColors.systemBlue, 'Đang thuê'),
        _legendDot(CupertinoColors.systemPurple, 'Chờ duyệt'),
        _legendDot(CupertinoColors.systemOrange, 'Nghiệm thu'),
        _legendDot(AppTheme.kWarning, 'Kích hoạt'),
        _legendDot(CupertinoColors.systemRed, 'Bảo trì'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.kTextSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRoomCell(RoomModel room, BuildContext context, WidgetRef ref) {
    final status = room.status;
    final isRented = status == 'DA_THUE';
    final isNghiemThu = status == 'NGHIEM_THU';

    Color bgColor = AppTheme.kBorderColor;
    Color textColor = AppTheme.kTextMuted;

    if (status == 'TRONG') {
      bgColor = CupertinoColors.systemGreen.withValues(alpha: 0.15);
      textColor = CupertinoColors.systemGreen;
    } else if (status == 'CHO_DUYET') {
      bgColor = CupertinoColors.systemPurple.withValues(alpha: 0.15);
      textColor = CupertinoColors.systemPurple;
    } else if (isNghiemThu) {
      bgColor = CupertinoColors.systemOrange.withValues(alpha: 0.15);
      textColor = CupertinoColors.systemOrange;
    } else if (isRented) {
      bgColor = CupertinoColors.systemBlue.withValues(alpha: 0.15);
      textColor = CupertinoColors.systemBlue;
    } else if (status == 'CHO_KICH_HOAT') {
      bgColor = AppTheme.kWarning.withValues(alpha: 0.15);
      textColor = AppTheme.kWarning;
    } else if (status == 'BAO_TRI') {
      bgColor = CupertinoColors.systemRed.withValues(alpha: 0.15);
      textColor = CupertinoColors.systemRed;
    }

    return GestureDetector(
      onTap: () => showRoomDetailModal(context, room, ref),
      child: Container(
        width: 60,
        height: 44,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: textColor.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        child: Center(
          child: Text(
            room.roomName,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Map<String, List<RoomModel>> _groupByFloor(List<RoomModel> rooms) {
    final Map<String, List<RoomModel>> floors = {};
    for (final r in rooms) {
      final digits = r.roomName.replaceAll(RegExp(r'[^0-9]'), '');
      final num = int.tryParse(digits);
      String floorKey;
      if (num != null && num >= 100) {
        floorKey = 'Tầng ${num ~/ 100}';
      } else {
        floorKey = 'Tầng 1';
      }
      floors.putIfAbsent(floorKey, () => []).add(r);
    }
    final sorted = Map.fromEntries(
      floors.entries.toList()..sort((a, b) {
        final aNum = int.tryParse(a.key.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final bNum = int.tryParse(b.key.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return aNum.compareTo(bNum);
      }),
    );
    return sorted;
  }
}
