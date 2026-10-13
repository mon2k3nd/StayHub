import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show LinearProgressIndicator;
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/glass_button.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/theme/app_theme.dart';
import 'dart:async' show unawaited;

class TenantBillSplitter extends StatefulWidget {
  const TenantBillSplitter({super.key});

  @override
  State<TenantBillSplitter> createState() => _TenantBillSplitterState();
}

class _TenantBillSplitterState extends State<TenantBillSplitter> {
  final double totalBill = 3500000;
  final List<Map<String, dynamic>> roommates = [
    {'name': 'Bạn (Đại diện)', 'paid': true, 'amount': 1500000, 'isMe': true},
    {'name': 'Nam', 'paid': false, 'amount': 1000000, 'isMe': false},
    {'name': 'Hùng', 'paid': true, 'amount': 1000000, 'isMe': false},
  ];

  @override
  Widget build(BuildContext context) {
    final collected = roommates
        .where((r) => r['paid'] == true)
        .fold<double>(0, (sum, r) => sum + r['amount']);
    final remaining = totalBill - collected;
    final progress = collected / totalBill;

    return LiquidGlassScaffold(
      title: 'Chia Tiền Phòng',
      backgroundColors: AppTheme.kBackgroundLight,
      useScrollView: true,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),

            // --- Summary Card ---
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: PremiumGradients.oceanBlue,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.kBrandDeep.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2),
              child: Container(
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text(
                      'Tổng Hóa Đơn Tháng Này',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '3.500.000đ',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.kBrandDeep,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFE3F0FF),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.kBrandDeep,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.kSuccess,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Đã gom: ${(collected / 1000000).toStringAsFixed(1)} Tr',
                              style: const TextStyle(
                                color: AppTheme.kSuccess,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.kError,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Còn thiếu: ${(remaining / 1000000).toStringAsFixed(1)} Tr',
                              style: const TextStyle(
                                color: AppTheme.kError,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // --- Section header ---
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Text(
                'DANH SÁCH THÀNH VIÊN',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: AppTheme.kBrandDeep,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // --- Member list ---
            ...roommates.asMap().entries.map((entry) {
              final r = entry.value;
              // BUGFIX (data): `paid`/`isMe` có thể là null/String → tránh
              // TypeError khi backend trả giá trị không phải bool.
              final isPaid = r['paid'] == true;
              final isMe = r['isMe'] == true;
              final memberColor = isMe
                  ? AppTheme.kBrandDeep
                  : const Color(0xFF6B7280);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Avatar
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: isMe
                              ? PremiumGradients.oceanBlue
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFFD1D5DB),
                                    Color(0xFF9CA3AF),
                                  ],
                                ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: memberColor.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Icon(
                          isMe
                              ? CupertinoIcons.person_solid
                              : CupertinoIcons.person,
                          color: CupertinoColors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Name & amount
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${(r['amount'] / 1000).toStringAsFixed(0)}.000 đ',
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isPaid
                              ? const Color(0xFFD1FAE5)
                              : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isPaid
                                ? AppTheme.kSuccess.withValues(alpha: 0.3)
                                : AppTheme.kError.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          isPaid ? '✓ Đã đóng' : '✗ Chưa đóng',
                          style: TextStyle(
                            color: isPaid
                                ? const Color(0xFF059669)
                                : const Color(0xFFDC2626),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            if (remaining > 0) ...[
              GlassButton(
                text: 'Nhắc nhở người chưa đóng',
                icon: CupertinoIcons.bell_fill,
                color: AppTheme.kWarning,
                onPressed: () {
                  unawaited(
                    showCupertinoDialog(
                      context: context,
                      builder: (c) => CupertinoAlertDialog(
                        title: const Text('Nhắc nhở'),
                        content: const Text(
                          'Đã gửi thông báo nhắc nhở đến Nam!',
                        ),
                        actions: [
                          CupertinoDialogAction(
                            child: const Text('OK'),
                            onPressed: () => Navigator.pop(c),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
