import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/components/glass_container.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/staff_task_model.dart';
import 'dart:convert';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import 'dart:async' show unawaited;

class StaffTaskReceiveScreen extends ConsumerStatefulWidget {
  const StaffTaskReceiveScreen({super.key});

  @override
  ConsumerState<StaffTaskReceiveScreen> createState() =>
      _StaffTaskReceiveScreenState();
}

class _StaffTaskReceiveScreenState
    extends ConsumerState<StaffTaskReceiveScreen> {
  bool _isLoading = true;
  List<StaffTaskModel> _tasks = [];
  late ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    unawaited(_fetchTasks());
    _subscribeSSE();
  }

  @override
  void dispose() {
    SSEClient.unsubscribeFromSSE();
    super.dispose();
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);
    const userId = 1; // MOCK USER ID

    try {
      final response = await _apiClient.dio.get(
        '/v1/staff-tasks/staff/$userId',
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        setState(() {
          _tasks = data.map((e) => StaffTaskModel.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) ToastUtils.show(context, 'Lỗi tải danh sách: $e');
      setState(() => _isLoading = false);
    }
  }

  void _subscribeSSE() {
    const userId = 1; // MOCK USER ID

    SSEClient.subscribeToSSE(
      method: SSERequestType.GET,
      url: '${ApiClient.baseUrl}/v1/staff-tasks/stream/staff/$userId',
      header: {
        "Accept": "text/event-stream",
        "Cache-Control": "no-cache",
        "Authorization": "Bearer MOCK_TOKEN",
      },
    ).listen((event) {
      if (event.event == 'NEW_TASK') {
        if (event.data != null && event.data!.isNotEmpty) {
          try {
            final data = json.decode(event.data!);
            final updated = StaffTaskModel.fromJson(data);
            setState(() {
              final idx = _tasks.indexWhere((c) => c.id == updated.id);
              if (idx >= 0) {
                _tasks[idx] = updated;
              } else {
                _tasks.insert(0, updated);
              }
            });
            if (!mounted) return;
            ToastUtils.show(
              context,
              'Ting Ting! Bạn có công việc mới: ${updated.title}',
              isError: false,
            );
          } catch (_) {}
        }
      }
    });
  }

  Future<void> _updateTaskStatus(StaffTaskModel task, String newStatus) async {
    try {
      final response = await _apiClient.dio.put(
        '/v1/staff-tasks/${task.id}/status',
        data: {'status': newStatus},
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          final idx = _tasks.indexWhere((t) => t.id == task.id);
          if (idx >= 0) _tasks[idx] = task.copyWith(status: newStatus);
        });
        if (mounted) {
          ToastUtils.show(context, 'Đã cập nhật trạng thái', isError: false);
        }
      }
    } catch (e) {
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
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
                    horizontal: 10,
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
                    'Hạn: ${task.dueDate!.substring(5, 16).replaceFirst('T', ' ')}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.kError,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.kTextPrimary,
              ),
            ),
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task.description!,
                style: const TextStyle(color: AppTheme.kTextSecondary),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (task.status == 'TODO')
                  ElevatedButton(
                    onPressed: () => _updateTaskStatus(task, 'IN_PROGRESS'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.kBrand,
                    ),
                    child: const Text(
                      'Bắt đầu làm',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                if (task.status == 'IN_PROGRESS')
                  ElevatedButton(
                    onPressed: () => _updateTaskStatus(task, 'DONE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.kSuccess,
                    ),
                    child: const Text(
                      'Đã xong',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                if (task.status == 'DONE')
                  const Row(
                    children: [
                      Icon(
                        CupertinoIcons.checkmark_seal_fill,
                        color: AppTheme.kSuccess,
                        size: 20,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Hoàn thành',
                        style: TextStyle(
                          color: AppTheme.kSuccess,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
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
        title: const Text('Công việc của tôi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
          ? const Center(child: Text('Bạn không có công việc nào'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _tasks.length,
              itemBuilder: (context, index) => _buildTaskCard(_tasks[index]),
            ),
    );
  }
}
