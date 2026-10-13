import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../application/housekeeping_notifier.dart';
import 'task_checklist_screen.dart';
import 'package:stayhub_frontend/core/components/stayhub_logo_icon.dart';

class HousekeepingScreen extends ConsumerWidget {
  const HousekeepingScreen({super.key});

  static const _typeIcon = {
    TaskType.cleaning: CupertinoIcons.sparkles,
    TaskType.checkOut: CupertinoIcons.arrow_right_circle_fill,
    TaskType.checkIn: CupertinoIcons.arrow_left_circle_fill,
    TaskType.maintenance: CupertinoIcons.wrench_fill,
  };

  static const _typeAsset = {
    TaskType.cleaning: 'assets/images/features/local_services.png',
    TaskType.checkOut: 'assets/images/features/moveout_settlement.png',
    TaskType.checkIn: 'assets/images/features/move_checklist.png',
    TaskType.maintenance: 'assets/images/features/video_maintenance.png',
  };

  static const _typeLabel = {
    TaskType.cleaning: 'Dọn phòng',
    TaskType.checkOut: 'Bàn giao trả phòng',
    TaskType.checkIn: 'Bàn giao nhận phòng',
    TaskType.maintenance: 'Bảo trì sửa chữa',
  };

  static const _typeColor = {
    TaskType.cleaning: CupertinoColors.systemBlue,
    TaskType.checkOut: CupertinoColors.systemOrange,
    TaskType.checkIn: CupertinoColors.systemGreen,
    TaskType.maintenance: CupertinoColors.systemRed,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(housekeepingProvider);
    final today = DateFormat(
      'EEEE, dd/MM/yyyy',
      'vi_VN',
    ).format(DateTime.now());

    return LiquidGlassScaffold(
      title: 'Công Việc Hôm Nay',
      backgroundColors: AppTheme.kBackgroundLight,
      useScrollView: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: tasksAsync.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e, _) => Center(child: Text('Lỗi: $e')),
          data: (tasks) {
            final done = tasks.where((t) => t.status == TaskStatus.done).length;
            final total = tasks.length;
            final pct = total == 0 ? 0.0 : done / total;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // ── Header date ──
                Text(
                  today,
                  style: const TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Progress Overview ──
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  color: LiquidGlassColors.staffAccent.withValues(alpha: 0.08),
                  border: Border.all(
                    color: LiquidGlassColors.staffAccent.withValues(alpha: 0.2),
                  ),
                  child: Row(
                    children: [
                      // Circle progress
                      SizedBox(
                        width: 80,
                        height: 80,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: CircularProgressWidget(progress: pct),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$done/$total',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: CupertinoColors.black,
                                  ),
                                ),
                                const Text(
                                  'xong',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: CupertinoColors.systemGrey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              done == total
                                  ? '🎉 Hoàn thành ca!'
                                  : 'Còn ${total - done} việc cần làm',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: done == total
                                    ? CupertinoColors.systemGreen
                                    : CupertinoColors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                height: 8,
                                width: double.infinity,
                                color: CupertinoColors.systemGrey5,
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: pct,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: done == total
                                          ? CupertinoColors.systemGreen
                                          : LiquidGlassColors.staffAccent,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${(pct * 100).toInt()}% hoàn thành',
                              style: const TextStyle(
                                color: CupertinoColors.systemGrey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'DANH SÁCH NHIỆM VỤ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemGrey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Task list ──
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final color =
                        _typeColor[task.type] ?? CupertinoColors.systemBlue;
                    final icon =
                        _typeIcon[task.type] ?? CupertinoIcons.checkmark_circle;
                    final asset = _typeAsset[task.type];
                    final label = _typeLabel[task.type] ?? 'Nhiệm vụ';
                    final isDone = task.status == TaskStatus.done;
                    final isInProgress = task.status == TaskStatus.inProgress;

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (_) => TaskChecklistScreen(taskId: task.id),
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: GlassContainer(
                          padding: const EdgeInsets.all(16),
                          color: isDone
                              ? CupertinoColors.systemGreen.withValues(
                                  alpha: 0.04,
                                )
                              : null,
                          border: isDone
                              ? Border.all(
                                  color: CupertinoColors.systemGreen.withValues(
                                    alpha: 0.2,
                                  ),
                                )
                              : null,
                          child: Row(
                            children: [
                              // Icon vòng tròn
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: color.withValues(
                                    alpha: isDone ? 0.06 : 0.12,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: asset != null
                                    ? Opacity(
                                        opacity: isDone ? 0.45 : 1.0,
                                        child: Image.asset(
                                          asset,
                                          width: 34,
                                          height: 34,
                                          fit: BoxFit.contain,
                                          filterQuality: FilterQuality.high,
                                          isAntiAlias: true,
                                          errorBuilder: (_, __, ___) => Icon(
                                            icon,
                                            color: isDone
                                                ? CupertinoColors.systemGrey
                                                : color,
                                            size: 26,
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        icon,
                                        color: isDone
                                            ? CupertinoColors.systemGrey
                                            : color,
                                        size: 26,
                                      ),
                              ),
                              const SizedBox(width: 14),
                              // Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            label,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                              color: isDone
                                                  ? CupertinoColors.systemGrey
                                                  : CupertinoColors.black,
                                              decoration: isDone
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        _buildStatusChip(task.status),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const StayHubLogoIcon(
                                          size: 12,
                                          color: CupertinoColors.systemGrey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          task.roomName,
                                          style: const TextStyle(
                                            color: CupertinoColors.systemGrey,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Icon(
                                          CupertinoIcons.clock,
                                          size: 12,
                                          color: CupertinoColors.systemGrey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          task.dueTime,
                                          style: const TextStyle(
                                            color: CupertinoColors.systemGrey,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (isInProgress) ...[
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(3),
                                        child: Container(
                                          height: 5,
                                          color: CupertinoColors.systemGrey5,
                                          child: FractionallySizedBox(
                                            alignment: Alignment.centerLeft,
                                            widthFactor: task.progress,
                                            child: Container(color: color),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${(task.progress * 100).toInt()}% checklist',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: color,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                CupertinoIcons.chevron_right,
                                color: CupertinoColors.systemGrey4,
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 80),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusChip(TaskStatus status) {
    final (label, color) = switch (status) {
      TaskStatus.pending => ('CHỜ', CupertinoColors.systemGrey),
      TaskStatus.inProgress => ('ĐANG LÀM', CupertinoColors.systemOrange),
      TaskStatus.done => ('XONG ✓', CupertinoColors.systemGreen),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Custom Circle Progress Widget ──────────────────────────────────────
class CircularProgressWidget extends StatelessWidget {
  final double progress;
  const CircularProgressWidget({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CirclePainter(progress: progress));
  }
}

class _CirclePainter extends CustomPainter {
  final double progress;
  const _CirclePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 7.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFE5E7EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -3.14159 / 2, // start from top
        2 * 3.14159 * progress,
        false,
        Paint()
          ..color = progress >= 1.0
              ? const Color(0xFF2ECC71)
              : LiquidGlassColors.staffAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_CirclePainter old) => old.progress != progress;
}
