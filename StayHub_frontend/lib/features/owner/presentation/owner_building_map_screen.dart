import 'package:flutter/cupertino.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/theme/app_theme.dart';
import 'dart:async' show unawaited;

enum RoomStatus { occupied, expiring, debt, vacant }

class RoomData {
  final String id;
  final String name;
  final RoomStatus status;
  final String? tenantName;
  final String? debtAmount;

  RoomData({
    required this.id,
    required this.name,
    required this.status,
    this.tenantName,
    this.debtAmount,
  });
}

class OwnerBuildingMapScreen extends StatelessWidget {
  const OwnerBuildingMapScreen({super.key});

  List<RoomData> _getFloorRooms(int floor) {
    if (floor == 1) {
      return [
        RoomData(
          id: '101',
          name: '101',
          status: RoomStatus.occupied,
          tenantName: 'Lê Văn B',
        ),
        RoomData(id: '102', name: '102', status: RoomStatus.vacant),
        RoomData(
          id: '103',
          name: '103',
          status: RoomStatus.occupied,
          tenantName: 'Trần Thị C',
        ),
        RoomData(
          id: '104',
          name: '104',
          status: RoomStatus.occupied,
          tenantName: 'Nguyễn Văn D',
        ),
      ];
    } else if (floor == 2) {
      return [
        RoomData(
          id: '201',
          name: '201',
          status: RoomStatus.expiring,
          tenantName: 'Hoàng Văn E',
        ),
        RoomData(
          id: '202',
          name: '202',
          status: RoomStatus.occupied,
          tenantName: 'Phạm Thị F',
        ),
        RoomData(
          id: '203',
          name: '203',
          status: RoomStatus.debt,
          tenantName: 'Vũ Văn G',
          debtAmount: '2,500,000 đ',
        ),
        RoomData(id: '204', name: '204', status: RoomStatus.vacant),
      ];
    } else {
      return [
        RoomData(
          id: '301',
          name: '301',
          status: RoomStatus.occupied,
          tenantName: 'Đặng Văn H',
        ),
        RoomData(
          id: '302',
          name: '302',
          status: RoomStatus.debt,
          tenantName: 'Nguyễn Văn A',
          debtAmount: '4,500,000 đ',
        ),
        RoomData(
          id: '303',
          name: '303',
          status: RoomStatus.occupied,
          tenantName: 'Bùi Thị K',
        ),
        RoomData(
          id: '304',
          name: '304',
          status: RoomStatus.occupied,
          tenantName: 'Lý Văn L',
        ),
      ];
    }
  }

  Color _getStatusColor(RoomStatus status) {
    switch (status) {
      case RoomStatus.occupied:
        return CupertinoColors.activeGreen;
      case RoomStatus.expiring:
        return CupertinoColors.systemYellow;
      case RoomStatus.debt:
        return CupertinoColors.destructiveRed;
      case RoomStatus.vacant:
        return CupertinoColors.systemGrey;
    }
  }

  IconData _getStatusIcon(RoomStatus status) {
    switch (status) {
      case RoomStatus.occupied:
        return CupertinoIcons.checkmark_circle_fill;
      case RoomStatus.expiring:
        return CupertinoIcons.exclamationmark_triangle_fill;
      case RoomStatus.debt:
        return CupertinoIcons.money_dollar_circle_fill;
      case RoomStatus.vacant:
        return CupertinoIcons.house_fill;
    }
  }

  void _showRoomDetails(BuildContext context, RoomData room) {
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(24).copyWith(bottom: 48),
          decoration: const BoxDecoration(
            color: AppTheme.kBackgroundLight,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getStatusIcon(room.status),
                    color: _getStatusColor(room.status),
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'PHÒNG ${room.name}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (room.status == RoomStatus.vacant) ...[
                const Text(
                  'Trạng thái: Trống',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    child: const Text('Tìm Khách Thuê'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ] else ...[
                _buildDetailRow('Khách thuê:', room.tenantName ?? 'N/A'),
                const SizedBox(height: 12),
                if (room.status == RoomStatus.debt) ...[
                  _buildDetailRow(
                    'Đang Nợ:',
                    room.debtAmount ?? '0 đ',
                    valueColor: CupertinoColors.destructiveRed,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: CupertinoColors.destructiveRed,
                      child: const Text('Gửi Nhắc Nhở Thanh Toán'),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ] else if (room.status == RoomStatus.expiring) ...[
                  _buildDetailRow(
                    'Hết hạn vào:',
                    '15/07/2026',
                    valueColor: CupertinoColors.systemYellow,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: CupertinoColors.systemYellow,
                      child: const Text(
                        'Gửi Gia Hạn Hợp Đồng',
                        style: TextStyle(color: CupertinoColors.black),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ] else ...[
                  _buildDetailRow(
                    'Trạng thái:',
                    'Đã đóng tiền đầy đủ',
                    valueColor: CupertinoColors.activeGreen,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: CupertinoColors.systemGrey,
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: valueColor ?? CupertinoColors.black,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      title: 'Bản Đồ Tòa Nhà',
      backgroundColors: AppTheme.kBackgroundDark,
      useScrollView: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Legend
            GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildLegendItem(CupertinoColors.activeGreen, 'Bình thường'),
                  _buildLegendItem(CupertinoColors.systemYellow, 'Sắp hết hạn'),
                  _buildLegendItem(CupertinoColors.destructiveRed, 'Nợ cước'),
                  _buildLegendItem(CupertinoColors.systemGrey, 'Trống'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Floor 3
            _buildFloor(context, 3),
            const SizedBox(height: 32),
            // Floor 2
            _buildFloor(context, 2),
            const SizedBox(height: 32),
            // Floor 1
            _buildFloor(context, 1),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: CupertinoColors.white),
        ),
      ],
    );
  }

  Widget _buildFloor(BuildContext context, int floor) {
    final rooms = _getFloorRooms(floor);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TẦNG $floor',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: CupertinoColors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: CupertinoColors.white.withValues(alpha: 0.1),
            ),
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final color = _getStatusColor(room.status);

              return GestureDetector(
                onTap: () => _showRoomDetails(context, room),
                child: Container(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        room.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 24,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(_getStatusIcon(room.status), color: color, size: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
