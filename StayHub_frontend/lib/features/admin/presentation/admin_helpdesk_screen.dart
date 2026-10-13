import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircleAvatar;
import '../../../core/components/glass_container.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import 'admin_helpdesk_chat_screen.dart';
import 'dart:async' show unawaited;

class AdminHelpdeskScreen extends StatelessWidget {
  const AdminHelpdeskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> tickets = [
      {
        'owner': 'Nguyễn Văn A',
        'issue': 'Lỗi không nạp được tiền qua Momo',
        'status': 'OPEN',
        'time': '10 phút trước',
        'priority': 'HIGH',
      },
      {
        'owner': 'Trần Thị B',
        'issue': 'Hỏi về cách tính tiền điện nước bậc thang',
        'status': 'PENDING',
        'time': '1 giờ trước',
        'priority': 'NORMAL',
      },
      {
        'owner': 'Lê Văn C',
        'issue': 'Tài khoản nhân viên không đăng nhập được',
        'status': 'RESOLVED',
        'time': 'Hôm qua',
        'priority': 'LOW',
      },
    ];

    Color getPriorityColor(String priority) {
      switch (priority) {
        case 'HIGH':
          return CupertinoColors.destructiveRed;
        case 'NORMAL':
          return CupertinoColors.activeOrange;
        case 'LOW':
          return CupertinoColors.activeGreen;
        default:
          return CupertinoColors.systemGrey;
      }
    }

    return LiquidGlassScaffold(
      title: 'Trung Tâm Hỗ Trợ (Helpdesk)',
      backgroundColors: AppTheme.kBackgroundLight,
      useScrollView: false,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: LiquidGlassColors.adminAccent.withValues(alpha: 0.1),
            child: const Row(
              children: [
                Icon(
                  CupertinoIcons.headphones,
                  color: LiquidGlassColors.adminAccent,
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Khu vực giải đáp thắc mắc và hỗ trợ kỹ thuật trực tiếp cho các Chủ Trọ (VIP).',
                    style: TextStyle(
                      fontSize: 12,
                      color: LiquidGlassColors.adminAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final t = tickets[index];
                final pColor = getPriorityColor(t['priority']);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 12,
                                  backgroundColor:
                                      LiquidGlassColors.adminAccent,
                                  child: Icon(
                                    CupertinoIcons.person_fill,
                                    color: CupertinoColors.white,
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  t['owner'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: CupertinoColors.black,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              t['time'],
                              style: const TextStyle(
                                fontSize: 11,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          t['issue'],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.flag_fill,
                                  color: pColor,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Mức độ: ${t['priority']}',
                                  style: TextStyle(
                                    color: pColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            CupertinoButton(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              color: CupertinoColors.activeBlue,
                              borderRadius: BorderRadius.circular(16),
                              onPressed: () {
                                unawaited(
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) =>
                                          AdminHelpdeskChatScreen(
                                            ownerName: t['owner'],
                                            issue: t['issue'],
                                          ),
                                    ),
                                  ),
                                );
                              },
                              minimumSize: const Size(0, 0),
                              child: const Text(
                                'Phản hồi',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
