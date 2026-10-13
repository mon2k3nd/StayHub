import 'package:flutter/cupertino.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/components/glass_container.dart';

import 'package:flutter/material.dart' show Divider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import 'package:intl/intl.dart';
import 'dart:async' show unawaited;

class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  // Mock data for maintenance schedules
  final List<Map<String, dynamic>> _schedules = [
    {
      'id': 1,
      'title': 'Vệ sinh máy lạnh',
      'room': 'Phòng 101 - Chi nhánh A',
      'lastMaintenance': DateTime.now().subtract(const Duration(days: 190)),
      'nextMaintenance': DateTime.now().subtract(const Duration(days: 10)),
      'status': 'OVERDUE',
      'frequency': '6 tháng',
    },
    {
      'id': 2,
      'title': 'Vệ sinh máy lạnh',
      'room': 'Phòng 102 - Chi nhánh A',
      'lastMaintenance': DateTime.now().subtract(const Duration(days: 150)),
      'nextMaintenance': DateTime.now().add(const Duration(days: 30)),
      'status': 'UPCOMING',
      'frequency': '6 tháng',
    },
    {
      'id': 3,
      'title': 'Bảo trì bình nóng lạnh',
      'room': 'Phòng 201 - Chi nhánh A',
      'lastMaintenance': DateTime.now().subtract(const Duration(days: 300)),
      'nextMaintenance': DateTime.now().add(const Duration(days: 65)),
      'status': 'NORMAL',
      'frequency': '1 năm',
    },
  ];

  void _markAsDone(int id) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Xác nhận bảo trì'),
          content: const Text(
            'Bạn xác nhận đã hoàn tất bảo trì hạng mục này hôm nay?',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Hủy'),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              child: const Text('Xác nhận'),
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  final idx = _schedules.indexWhere((s) => s['id'] == id);
                  if (idx != -1) {
                    _schedules[idx]['lastMaintenance'] = DateTime.now();
                    _schedules[idx]['status'] = 'NORMAL';
                    if (_schedules[idx]['frequency'] == '6 tháng') {
                      _schedules[idx]['nextMaintenance'] = DateTime.now().add(
                        const Duration(days: 180),
                      );
                    } else {
                      _schedules[idx]['nextMaintenance'] = DateTime.now().add(
                        const Duration(days: 365),
                      );
                    }
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      title: 'Lịch Bảo Trì',
      backgroundColors: AppTheme.kBackgroundLight,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _schedules.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (ctx, idx) {
          final s = _schedules[idx];

          Color statusColor;
          String statusText;
          IconData statusIcon;
          String statusAsset;

          if (s['status'] == 'OVERDUE') {
            statusColor = CupertinoColors.systemRed;
            statusText = 'QUÁ HẠN';
            statusIcon = CupertinoIcons.exclamationmark_triangle_fill;
            statusAsset = 'assets/images/features/sos_panic.png';
          } else if (s['status'] == 'UPCOMING') {
            statusColor = CupertinoColors.systemOrange;
            statusText = 'SẮP ĐẾN HẠN';
            statusIcon = CupertinoIcons.clock_fill;
            statusAsset = 'assets/images/features/feat_booking.png';
          } else {
            statusColor = CupertinoColors.systemGreen;
            statusText = 'BÌNH THƯỜNG';
            statusIcon = CupertinoIcons.check_mark_circled_solid;
            statusAsset = 'assets/images/features/move_checklist.png';
          }

          final dateFormat = DateFormat('dd/MM/yyyy');
          final lastDate = dateFormat.format(s['lastMaintenance']);
          final nextDate = dateFormat.format(s['nextMaintenance']);

          return GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        s['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            statusAsset,
                            width: 18,
                            height: 18,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            isAntiAlias: true,
                            errorBuilder: (_, __, ___) =>
                                Icon(statusIcon, color: statusColor, size: 14),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.location_solid,
                      size: 14,
                      color: AppTheme.kTextSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      s['room'],
                      style: const TextStyle(
                        color: AppTheme.kTextSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lần trước',
                          style: TextStyle(
                            color: AppTheme.kTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lastDate,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Kỳ tiếp theo',
                          style: TextStyle(
                            color: AppTheme.kTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          nextDate,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: CupertinoColors.activeBlue,
                    borderRadius: BorderRadius.circular(12),
                    onPressed: () => _markAsDone(s['id']),
                    child: const Text(
                      'Đã Bảo Trì Hôm Nay',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
