import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../data/datasources/housekeeping_remote_data_source.dart';

// --- Models ---------------------------------------------------------------

enum TaskStatus { pending, inProgress, done }

enum TaskType { cleaning, checkOut, checkIn, maintenance }

class ChecklistItem {
  final String label;
  final bool isRequired;
  final bool isDone;

  const ChecklistItem({
    required this.label,
    this.isRequired = true,
    this.isDone = false,
  });

  ChecklistItem copyWith({bool? isDone}) => ChecklistItem(
    label: label,
    isRequired: isRequired,
    isDone: isDone ?? this.isDone,
  );

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      label: json['label']?.toString() ?? '',
      isRequired: json['isRequired'] is bool
          ? json['isRequired'] as bool
          : true,
      isDone: json['isDone'] is bool ? json['isDone'] as bool : false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'label': label, 'isRequired': isRequired, 'isDone': isDone};
  }
}

class HousekeepingTask {
  final String id;
  final String roomName;
  final int roomId;
  final TaskType type;
  final TaskStatus status;
  final String dueTime;
  final List<ChecklistItem> checklist;

  const HousekeepingTask({
    required this.id,
    required this.roomName,
    required this.roomId,
    required this.type,
    required this.status,
    required this.dueTime,
    required this.checklist,
  });

  HousekeepingTask copyWith({
    TaskStatus? status,
    List<ChecklistItem>? checklist,
  }) {
    return HousekeepingTask(
      id: id,
      roomName: roomName,
      roomId: roomId,
      type: type,
      status: status ?? this.status,
      dueTime: dueTime,
      checklist: checklist ?? this.checklist,
    );
  }

  double get progress {
    if (checklist.isEmpty) return 0;
    final done = checklist.where((i) => i.isDone).length;
    return done / checklist.length;
  }

  bool get canComplete =>
      checklist.where((i) => i.isRequired && !i.isDone).isEmpty;

  factory HousekeepingTask.fromJson(Map<String, dynamic> json) {
    final rawRoomId = json['roomId'];
    final roomId = rawRoomId is num
        ? rawRoomId.toInt()
        : int.tryParse(rawRoomId?.toString() ?? '') ?? 0;
    final rawChecklist = json['checklist'];
    return HousekeepingTask(
      id: json['id']?.toString() ?? '',
      roomName: json['roomName']?.toString() ?? 'Phòng',
      roomId: roomId,
      type: _parseType(json['type']?.toString() ?? ''),
      status: _parseStatus(json['status']?.toString() ?? ''),
      dueTime: json['dueTime']?.toString() ?? '',
      checklist: rawChecklist is List
          ? rawChecklist
                .whereType<Map>()
                .map(
                  (e) => ChecklistItem.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : [],
    );
  }

  static TaskType _parseType(String type) {
    switch (type.toUpperCase()) {
      case 'CHECKOUT':
      case 'CHECK_OUT':
        return TaskType.checkOut;
      case 'CHECKIN':
      case 'CHECK_IN':
        return TaskType.checkIn;
      case 'MAINTENANCE':
        return TaskType.maintenance;
      case 'CLEANING':
      default:
        return TaskType.cleaning;
    }
  }

  static TaskStatus _parseStatus(String status) {
    switch (status.toUpperCase()) {
      case 'DONE':
      case 'COMPLETED':
        return TaskStatus.done;
      case 'IN_PROGRESS':
        return TaskStatus.inProgress;
      case 'PENDING':
      default:
        return TaskStatus.pending;
    }
  }
}

// --- Provider -------------------------------------------------------------

final housekeepingDataSourceProvider = Provider((ref) {
  final dio = ref.watch(apiClientProvider);
  return HousekeepingRemoteDataSource(dio.dio);
});

// --- Notifier -------------------------------------------------------------

class HousekeepingNotifier extends AsyncNotifier<List<HousekeepingTask>> {
  @override
  FutureOr<List<HousekeepingTask>> build() async {
    final ds = ref.watch(housekeepingDataSourceProvider);
    // Assuming branchId = 1 for now (can be dynamically fetched from user profile)
    const branchId = 1;
    final rawData = await ds.getTasksByBranch(branchId);
    // BUGFIX (data): lọc an toàn — tránh `as Map<String, dynamic>` ném TypeError
    // khi phần tử không phải Map.
    return rawData
        .whereType<Map>()
        .map((e) => HousekeepingTask.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus) async {
    final currentTasks = state.value;
    if (currentTasks == null) return;

    final index = currentTasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    // Optimistic update
    final updatedTask = currentTasks[index].copyWith(status: newStatus);
    state = AsyncData([
      ...currentTasks.sublist(0, index),
      updatedTask,
      ...currentTasks.sublist(index + 1),
    ]);

    try {
      final ds = ref.read(housekeepingDataSourceProvider);
      String statusStr = 'PENDING';
      if (newStatus == TaskStatus.inProgress) statusStr = 'IN_PROGRESS';
      if (newStatus == TaskStatus.done) statusStr = 'DONE';

      await ds.updateTaskStatus(int.parse(taskId), statusStr);
    } catch (e) {
      // Revert on error
      ref.invalidateSelf();
    }
  }

  Future<void> toggleChecklistItem(String taskId, int itemIndex) async {
    final currentTasks = state.value;
    if (currentTasks == null) return;

    final taskIndex = currentTasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = currentTasks[taskIndex];
    final checklist = List<ChecklistItem>.from(task.checklist);
    checklist[itemIndex] = checklist[itemIndex].copyWith(
      isDone: !checklist[itemIndex].isDone,
    );

    // Auto-update status based on checklist progress if it's currently pending
    TaskStatus newStatus = task.status;
    if (task.status == TaskStatus.pending &&
        checklist.any((item) => item.isDone)) {
      newStatus = TaskStatus.inProgress;
    }

    final updatedTask = task.copyWith(checklist: checklist, status: newStatus);

    // Optimistic update
    state = AsyncData([
      ...currentTasks.sublist(0, taskIndex),
      updatedTask,
      ...currentTasks.sublist(taskIndex + 1),
    ]);

    try {
      final ds = ref.read(housekeepingDataSourceProvider);

      // Update status if it changed
      if (newStatus != task.status) {
        String statusStr = newStatus == TaskStatus.inProgress
            ? 'IN_PROGRESS'
            : 'PENDING';
        await ds.updateTaskStatus(int.parse(taskId), statusStr);
      }

      // Update checklist
      final checklistData = checklist.map((c) => c.toJson()).toList();
      await ds.updateChecklist(int.parse(taskId), checklistData);
    } catch (e) {
      // Revert on error
      ref.invalidateSelf();
    }
  }
}

final housekeepingProvider =
    AsyncNotifierProvider<HousekeepingNotifier, List<HousekeepingTask>>(
      HousekeepingNotifier.new,
    );
