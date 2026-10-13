import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/glass_container.dart';
import '../application/housekeeping_notifier.dart';
import 'package:stayhub_frontend/core/components/stayhub_logo_icon.dart';
import 'dart:async' show unawaited;

class TaskChecklistScreen extends ConsumerStatefulWidget {
  final String taskId;
  const TaskChecklistScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskChecklistScreen> createState() =>
      _TaskChecklistScreenState();
}

class _TaskChecklistScreenState extends ConsumerState<TaskChecklistScreen> {
  bool _isCompleting = false;

  static const _typeLabel = {
    TaskType.cleaning: 'Dọn phòng',
    TaskType.checkOut: 'Bàn giao trả phòng',
    TaskType.checkIn: 'Bàn giao nhận phòng',
    TaskType.maintenance: 'Bảo trì sửa chữa',
  };

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

  static const _typeColor = {
    TaskType.cleaning: CupertinoColors.systemBlue,
    TaskType.checkOut: CupertinoColors.systemOrange,
    TaskType.checkIn: CupertinoColors.systemGreen,
    TaskType.maintenance: CupertinoColors.systemRed,
  };

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(housekeepingProvider);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Chi tiết nhiệm vụ'),
        previousPageTitle: 'Công việc',
        backgroundColor: CupertinoColors.systemGroupedBackground,
        border: null,
      ),
      child: tasksAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (tasks) {
          final task = tasks.where((t) => t.id == widget.taskId).firstOrNull;
          if (task == null) {
            return const Center(child: Text('Không tìm thấy task.'));
          }

          final color = _typeColor[task.type] ?? CupertinoColors.systemBlue;
          final icon = _typeIcon[task.type] ?? CupertinoIcons.checkmark_circle;
          final asset = _typeAsset[task.type];
          final label = _typeLabel[task.type] ?? 'Nhiệm vụ';
          final isDone = task.status == TaskStatus.done;
          final isPending = task.status == TaskStatus.pending;
          final requiredLeft = task.checklist
              .where((i) => i.isRequired && !i.isDone)
              .length;

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Task header card ──────────────────────────────
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  color: color.withValues(alpha: 0.06),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: asset != null
                                ? Image.asset(
                                    asset,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                    isAntiAlias: true,
                                    errorBuilder: (_, __, ___) =>
                                        Icon(icon, color: color, size: 30),
                                  )
                                : Icon(icon, color: color, size: 30),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                    color: CupertinoColors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const StayHubLogoIcon(
                                      size: 13,
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
                                      size: 13,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Trước ${task.dueTime}',
                                      style: const TextStyle(
                                        color: CupertinoColors.systemGrey,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Progress bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Tiến độ checklist',
                            style: TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.systemGrey.withValues(
                                alpha: 0.8,
                              ),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${(task.progress * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          height: 8,
                          color: CupertinoColors.systemGrey5,
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: task.progress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: task.progress >= 1.0
                                    ? CupertinoColors.systemGreen
                                    : color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (!isDone && requiredLeft > 0) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(
                              CupertinoIcons.exclamationmark_circle_fill,
                              color: CupertinoColors.systemOrange,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Còn $requiredLeft mục bắt buộc chưa hoàn thành',
                              style: const TextStyle(
                                color: CupertinoColors.systemOrange,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'DANH MỤC KIỂM TRA',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.systemGrey,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${task.checklist.where((i) => i.isDone).length}/${task.checklist.length}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Checklist items ────────────────────────────────
                ...task.checklist.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  return GestureDetector(
                    onTap: isDone
                        ? null
                        : () {
                            // Auto-start if pending
                            if (isPending) {
                              unawaited(
                                ref
                                    .read(housekeepingProvider.notifier)
                                    .updateTaskStatus(
                                      widget.taskId,
                                      TaskStatus.inProgress,
                                    ),
                              );
                            }
                            unawaited(
                              ref
                                  .read(housekeepingProvider.notifier)
                                  .toggleChecklistItem(widget.taskId, idx),
                            );
                          },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        color: item.isDone
                            ? CupertinoColors.systemGreen.withValues(
                                alpha: 0.04,
                              )
                            : null,
                        child: Row(
                          children: [
                            // Checkbox
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: item.isDone
                                    ? CupertinoColors.systemGreen
                                    : CupertinoColors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: item.isDone
                                      ? CupertinoColors.systemGreen
                                      : (item.isRequired
                                            ? color
                                            : CupertinoColors.systemGrey4),
                                  width: item.isDone ? 0 : 2,
                                ),
                                boxShadow: item.isDone
                                    ? [
                                        BoxShadow(
                                          color: CupertinoColors.systemGreen
                                              .withValues(alpha: 0.3),
                                          blurRadius: 6,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: item.isDone
                                  ? const Icon(
                                      CupertinoIcons.checkmark_alt,
                                      color: CupertinoColors.white,
                                      size: 16,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: item.isRequired
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: item.isDone
                                            ? CupertinoColors.systemGrey
                                            : CupertinoColors.black,
                                        decoration: item.isDone
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                  ),
                                  if (item.isRequired)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: item.isDone
                                            ? CupertinoColors.systemGreen
                                                  .withValues(alpha: 0.1)
                                            : color.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item.isDone ? '✓' : 'Bắt buộc',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: item.isDone
                                              ? CupertinoColors.systemGreen
                                              : color,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // ── Complete button ───────────────────────────────
                if (!isDone)
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      color: task.canComplete
                          ? CupertinoColors.systemGreen
                          : CupertinoColors.systemGrey4,
                      borderRadius: BorderRadius.circular(18),
                      onPressed: (!task.canComplete || _isCompleting)
                          ? null
                          : () async {
                              setState(() => _isCompleting = true);
                              await ref
                                  .read(housekeepingProvider.notifier)
                                  .updateTaskStatus(
                                    widget.taskId,
                                    TaskStatus.done,
                                  );
                              setState(() => _isCompleting = false);
                              if (context.mounted) {
                                unawaited(
                                  showCupertinoDialog(
                                    context: context,
                                    builder: (ctx) => CupertinoAlertDialog(
                                      title: const Text('🎉 Hoàn thành!'),
                                      content: Text(
                                        'Task "$label" tại ${task.roomName} đã được ghi nhận hoàn thành.',
                                      ),
                                      actions: [
                                        CupertinoDialogAction(
                                          child: const Text('Đóng'),
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            },
                      child: _isCompleting
                          ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  task.canComplete
                                      ? CupertinoIcons.checkmark_seal_fill
                                      : CupertinoIcons.lock_fill,
                                  color: CupertinoColors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  task.canComplete
                                      ? 'Xác nhận Hoàn thành'
                                      : 'Hoàn thành $requiredLeft mục bắt buộc trước',
                                  style: const TextStyle(
                                    color: CupertinoColors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                if (isDone)
                  GlassContainer(
                    padding: const EdgeInsets.all(20),
                    color: CupertinoColors.systemGreen.withValues(alpha: 0.08),
                    border: Border.all(
                      color: CupertinoColors.systemGreen.withValues(alpha: 0.3),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.checkmark_seal_fill,
                          color: CupertinoColors.systemGreen,
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Nhiệm vụ đã hoàn thành ✓',
                          style: TextStyle(
                            color: CupertinoColors.systemGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}
