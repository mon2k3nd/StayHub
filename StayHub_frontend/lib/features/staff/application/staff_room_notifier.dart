import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/core_providers.dart';
import 'staff_assignment_notifier.dart';
import 'dart:async' show unawaited;

part 'staff_room_notifier.g.dart';

class StaffRoomState {
  final bool isLoading;
  final String? error;
  final List<dynamic> rooms;

  const StaffRoomState({
    this.isLoading = false,
    this.error,
    this.rooms = const [],
  });

  StaffRoomState copyWith({
    bool? isLoading,
    String? error,
    List<dynamic>? rooms,
  }) {
    return StaffRoomState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      rooms: rooms ?? this.rooms,
    );
  }
}

@riverpod
class StaffRoomNotifier extends _$StaffRoomNotifier {
  @override
  StaffRoomState build() {
    // Listen to active branch changes
    ref.listen<StaffAssignmentState>(staffAssignmentProvider, (previous, next) {
      if (previous?.activeBranchId != next.activeBranchId &&
          next.activeBranchId != null) {
        unawaited(loadRoomsForBranch(next.activeBranchId!));
      }
    });

    final assignmentState = ref.read(staffAssignmentProvider);
    if (assignmentState.activeBranchId != null) {
      // delay load to avoid calling during build
      unawaited(
        Future.microtask(
          () => loadRoomsForBranch(assignmentState.activeBranchId!),
        ),
      );
    }

    return const StaffRoomState();
  }

  Future<void> loadRoomsForBranch(int branchId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/v1/rooms/branch/$branchId');

      final List<dynamic> rooms = response['data'] ?? [];

      state = state.copyWith(isLoading: false, rooms: rooms);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
