import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../../room/presentation/record_utilities_screen.dart';
import 'dart:async' show unawaited;

class OwnerQuickActions extends ConsumerWidget {
  const OwnerQuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = [
      (
        'Chốt điện nước',
        CupertinoIcons.gauge,
        '/record-utilities',
        AppTheme.kBrand,
        'assets/images/features/utilities_dashboard.png',
      ),
      (
        'Hóa đơn',
        CupertinoIcons.money_dollar_circle_fill,
        '/bill',
        CupertinoColors.systemGreen,
        'assets/images/features/feat_payments.png',
      ),
      (
        'Hợp đồng',
        CupertinoIcons.doc_text_fill,
        '/contract',
        CupertinoColors.systemOrange,
        'assets/images/features/smart_contract.png',
      ),
      (
        'Sự cố',
        CupertinoIcons.wrench_fill,
        '/ticket',
        CupertinoColors.systemRed,
        'assets/images/features/video_maintenance.png',
      ),
      (
        'Phòng',
        CupertinoIcons.bed_double_fill,
        '/room',
        CupertinoColors.systemIndigo,
        'assets/images/features/feat_room.png',
      ),
      (
        'Dãy trọ',
        CupertinoIcons.building_2_fill,
        '/branch',
        CupertinoColors.systemBlue,
        'assets/images/features/multi_property.png',
      ),
      (
        'Nhân viên',
        CupertinoIcons.person_3_fill,
        '/staff-management',
        CupertinoColors.systemPink,
        'assets/images/features/staff_dispatch.png',
      ),
      (
        'Quản lý nợ',
        CupertinoIcons.exclamationmark_triangle_fill,
        '/debt-management',
        AppTheme.kError,
        'assets/images/features/multilevel_debt.png',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 24) / 4;

        return Wrap(
          spacing: 8,
          runSpacing: 16,
          children: actions.asMap().entries.map((entry) {
            final i = entry.key;
            final a = entry.value;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + (i * 50)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Transform.translate(
                offset: Offset(0, 10 * (1 - value)),
                child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
              ),
              child: SizedBox(
                width: itemWidth,
                child: GestureDetector(
                  onTap: () {
                    unawaited(HapticFeedback.lightImpact());
                    if (a.$3 == '/room') {
                      final user = ref.read(authProvider).value;
                      unawaited(
                        context.push(
                          '/room',
                          extra: {
                            'ownerId': user?.id ?? 0,
                            'branchId': null,
                            'branchName': 'Tất cả phòng',
                          },
                        ),
                      );
                    } else if (a.$3 == '/record-utilities') {
                      unawaited(
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (c) => const RecordUtilitiesScreen(),
                          ),
                        ),
                      );
                    } else {
                      unawaited(context.push(a.$3));
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              a.$4.withValues(alpha: 0.15),
                              a.$4.withValues(alpha: 0.08),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: a.$4.withValues(alpha: 0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: a.$4.withValues(alpha: 0.18),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          a.$5,
                          width: 30,
                          height: 30,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (_, __, ___) =>
                              Icon(a.$2, color: a.$4, size: 24),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        a.$1,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: CupertinoColors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
