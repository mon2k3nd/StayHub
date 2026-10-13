import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/components/glass_container.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/staff_task_model.dart';
import 'dart:async' show unawaited;

class OwnerTaskKanbanScreen extends ConsumerStatefulWidget {
  final int branchId;
  const OwnerTaskKanbanScreen({super.key, required this.branchId});

  @override
  ConsumerState<OwnerTaskKanbanScreen> createState() =>
      _OwnerTaskKanbanScreenState();
}

class _OwnerTaskKanbanScreenState extends ConsumerState<OwnerTaskKanbanScreen> {
  bool _isLoading = true;
  List<StaffTaskModel> _tasks = [];
  late ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    unawaited(_fetchTasks());
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.dio.get(
        '/v1/staff-tasks/branch/${widget.branchId}',
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        setState(() {
          _tasks = data.map((e) => StaffTaskModel.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) ToastUtils.show(context, 'Lỗi tải danh sách công việc: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTaskStatus(StaffTaskModel task, String newStatus) async {
    if (task.status == newStatus) return;

    // Optimistic UI update
    final oldStatus = task.status;
    setState(() {
      final idx = _tasks.indexWhere((t) => t.id == task.id);
      if (idx >= 0) _tasks[idx] = task.copyWith(status: newStatus);
    });

    try {
      final response = await _apiClient.dio.put(
        '/v1/staff-tasks/${task.id}/status',
        data: {'status': newStatus},
      );
      if (response.statusCode != 200 || response.data['success'] != true) {
        throw Exception('Failed to update');
      }
      // Haptic feedback could be triggered here via HapticFeedback.mediumImpact();
    } catch (e) {
      // Revert on failure
      setState(() {
        final idx = _tasks.indexWhere((t) => t.id == task.id);
        if (idx >= 0) _tasks[idx] = task.copyWith(status: oldStatus);
      });
      if (mounted) ToastUtils.show(context, 'Lỗi cập nhật: $e');
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'URGENT':
        return AppTheme.kError;
      case 'HIGH':
        return AppTheme.kWarning;
      case 'LOW':
        return AppTheme.kSuccess;
      default:
        return AppTheme.kBrand;
    }
  }

  Widget _buildTaskCard(StaffTaskModel task) {
    final isUrgent = task.priority == 'URGENT';
    return Draggable<StaffTaskModel>(
      data: task,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.8,
          child: Transform.scale(
            scale: 1.05,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              child: _buildCardContent(task, isUrgent),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildCardContent(task, isUrgent),
      ),
      child: _buildCardContent(task, isUrgent),
    );
  }

  Widget _buildCardContent(StaffTaskModel task, bool isUrgent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        border: Border.all(
          color: isUrgent
              ? AppTheme.kError.withValues(alpha: 0.5)
              : AppTheme.kBorderColor,
        ),
        color: AppTheme.kSurface1Light,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(
                      task.priority,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    task.priority,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _getPriorityColor(task.priority),
                    ),
                  ),
                ),
                if (task.dueDate != null)
                  Text(
                    task.dueDate!.substring(5, 16).replaceFirst('T', ' '),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.kError,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  CupertinoIcons.person_crop_circle_fill,
                  size: 16,
                  color: AppTheme.kTextSecondary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task.assignedStaffName ?? 'Chưa giao',
                    style: TextStyle(
                      fontSize: 12,
                      color: task.assignedStaffName == null
                          ? AppTheme.kWarning
                          : AppTheme.kTextSecondary,
                      fontWeight: task.assignedStaffName == null
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKanbanColumn(String title, String status, Color color) {
    final columnTasks = _tasks.where((t) => t.status == status).toList();

    return Container(
      width: MediaQuery.of(context).size.width * 0.75,
      margin: const EdgeInsets.only(right: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${columnTasks.length}',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: DragTarget<StaffTaskModel>(
                onWillAcceptWithDetails: (data) => data.data.status != status,
                onAcceptWithDetails: (data) {
                  unawaited(_updateTaskStatus(data.data, status));
                },
                builder: (context, candidateData, rejectedData) {
                  return Container(
                    decoration: BoxDecoration(
                      color: candidateData.isNotEmpty
                          ? color.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      itemCount: columnTasks.length,
                      itemBuilder: (ctx, i) => _buildTaskCard(columnTasks[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundLight,
      appBar: AppBar(
        title: const Text('Giao việc (Kanban)'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              CupertinoIcons.add_circled_solid,
              color: AppTheme.kBrand,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Form tạo task đang phát triển')));
              ToastUtils.show(
                context,
                'Tính năng thêm mới đang hoàn thiện',
                isError: false,
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(16),
              children: [
                _buildKanbanColumn('Cần làm', 'TODO', AppTheme.kWarning),
                _buildKanbanColumn(
                  'Đang xử lý',
                  'IN_PROGRESS',
                  AppTheme.kBrand,
                ),
                _buildKanbanColumn('Hoàn thành', 'DONE', AppTheme.kSuccess),
              ],
            ),
    );
  }
}
