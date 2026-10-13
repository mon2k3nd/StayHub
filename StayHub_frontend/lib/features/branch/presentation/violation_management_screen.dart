import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import 'package:intl/intl.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/violation_report_provider.dart';

class ViolationManagementScreen extends ConsumerStatefulWidget {
  const ViolationManagementScreen({super.key});

  @override
  ConsumerState<ViolationManagementScreen> createState() =>
      _ViolationManagementScreenState();
}

class _ViolationManagementScreenState
    extends ConsumerState<ViolationManagementScreen> {
  final _fmt = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final violationsAsync = ref.watch(violationReportProvider(1));
    return LiquidGlassScaffold(
      title: 'Phiếu Vi Phạm',
      backgroundColors: AppTheme.kBackgroundLight,
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _showCreateViolationDialog,
        child: const Icon(
          CupertinoIcons.plus_app_fill,
          color: LiquidGlassColors.ownerAccent,
          size: 26,
        ),
      ),
      child: violationsAsync.when(
        data: (violations) => violations.isEmpty
            ? const Center(child: Text('Chưa có vi phạm nào'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: violations.length,
                itemBuilder: (context, index) {
                  final v = violations[index];
                  final isPending = v.status == 'PENDING';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(16),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                v.targetType == 'TENANT'
                                    ? 'Phòng ${v.roomId}'
                                    : 'Nhân sự #${v.targetId}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: CupertinoColors.black,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isPending
                                      ? CupertinoColors.systemOrange.withValues(
                                          alpha: 0.1,
                                        )
                                      : CupertinoColors.systemGreen.withValues(
                                          alpha: 0.1,
                                        ),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  isPending ? 'Chưa nộp phạt' : 'Đã nộp phạt',
                                  style: TextStyle(
                                    color: isPending
                                        ? CupertinoColors.systemOrange
                                        : CupertinoColors.systemGreen,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Lỗi: ${v.violationType}',
                            style: const TextStyle(
                              color: CupertinoColors.systemRed,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            v.description,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Phạt: ${_fmt.format(v.penaltyAmount)}',
                                style: const TextStyle(
                                  color: CupertinoColors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (isPending)
                                CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  color: CupertinoColors.systemGreen,
                                  borderRadius: BorderRadius.circular(100),
                                  onPressed: () {
                                    // Mark as paid
                                  },
                                  minimumSize: const Size(0, 0),
                                  child: const Text(
                                    'Thu tiền',
                                    style: TextStyle(
                                      fontSize: 13,
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            err.toString(),
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }

  void _showCreateViolationDialog() {
    // Show dialog
  }
}
