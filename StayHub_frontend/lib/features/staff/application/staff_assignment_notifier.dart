import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/application/auth_notifier.dart';
import '../../branch/data/models/branch_model.dart';
import '../presentation/staff_permission_screen.dart'; // To reuse StaffPermissions model
import 'dart:async' show unawaited;

part 'staff_assignment_notifier.g.dart';

class StaffAssignmentWithBranch {
  final int assignmentId;
  final int branchId;
  final int ownerId;
  final String branchName;
  final String address;
  final StaffPermissions permissions;
  final String role;

  StaffAssignmentWithBranch({
    required this.assignmentId,
    required this.branchId,
    required this.ownerId,
    required this.branchName,
    required this.address,
    required this.permissions,
    required this.role,
  });
}

class StaffAssignmentState {
  final bool isLoading;
  final String? error;
  final List<StaffAssignmentWithBranch> assignments;
  final int? activeBranchId; // Currently selected branch context for UI

  StaffAssignmentState({
    this.isLoading = false,
    this.error,
    this.assignments = const [],
    this.activeBranchId,
  });

  StaffAssignmentState copyWith({
    bool? isLoading,
    String? error,
    List<StaffAssignmentWithBranch>? assignments,
    int? activeBranchId,
  }) {
    return StaffAssignmentState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      assignments: assignments ?? this.assignments,
      activeBranchId: activeBranchId ?? this.activeBranchId,
    );
  }
}

@Riverpod(keepAlive: true)
class StaffAssignmentNotifier extends _$StaffAssignmentNotifier {
  @override
  StaffAssignmentState build() {
    unawaited(Future.microtask(() => loadAssignments()));
    return StaffAssignmentState();
  }

  Future<void> loadAssignments() async {
    final user = ref.read(authProvider).value;
    if (user == null || user.role != 'STAFF') return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final api = ref.read(apiClientProvider);

      // 1. Fetch assignments
      final assignRes = await api.dio.get(
        '/v1/staff/assignments/staff/${user.id}',
      );
      // BUGFIX (data): lọc an toàn — tránh NoSuchMethodError khi phần tử
      // không phải Map (code bên dưới truy cập a['ownerId']/a['branchId']).
      final rawAssignments = assignRes.data['data'] is List
          ? (assignRes.data['data'] as List).whereType<Map>().toList()
          : <Map>[];

      if (rawAssignments.isEmpty) {
        // Không có phân công nào - thử lấy branches từ owner qua mapping
        try {
          final mappingRes = await api.dio.get('/v1/staff/owner-of/${user.id}');
          final ownerId = mappingRes.data['data']?['ownerId'] as int?;
          if (ownerId != null) {
            final bRes = await api.dio.get('/v1/branches/owner/$ownerId');
            final rawBranches = bRes.data['data'] as List<dynamic>? ?? [];
            // BUGFIX (data): lọc an toàn — tránh `as Map<String, dynamic>` ném
            // TypeError khi phần tử không phải Map.
            final List<StaffAssignmentWithBranch> virtual = rawBranches
                .whereType<Map>()
                .map((rb) {
                  final b = BranchModel.fromJson(Map<String, dynamic>.from(rb));
                  return StaffAssignmentWithBranch(
                    assignmentId: 0,
                    branchId: b.id,
                    ownerId: ownerId,
                    branchName: b.branchName,
                    address: b.address,
                    permissions: const StaffPermissions.fullAccess(),
                    role: 'STAFF',
                  );
                })
                .toList();
            state = state.copyWith(
              isLoading: false,
              assignments: virtual,
              activeBranchId: virtual.isNotEmpty
                  ? virtual.first.branchId
                  : null,
            );
            return;
          }
        } catch (e, st) {
          debugPrint('Error: $e\n$st');
        }
        // Thực sự chưa có phân công
        state = state.copyWith(isLoading: false, assignments: []);
        return;
      }

      // Collect unique ownerIds
      // BUGFIX (data): coerce an toàn — tránh `as int` ném TypeError khi
      // ownerId là String/null từ JSON.
      final ownerIds = rawAssignments
          .map((a) {
            final raw = a['ownerId'];
            return raw is num
                ? raw.toInt()
                : int.tryParse(raw?.toString() ?? '');
          })
          .whereType<int>()
          .toSet();

      // 2. Fetch branches for these owners
      final Map<int, BranchModel> branchMap = {};
      for (final oId in ownerIds) {
        try {
          final bRes = await api.dio.get('/v1/branches/owner/$oId');
          final rawBranches = bRes.data['data'] as List<dynamic>? ?? [];
          for (final rb in rawBranches) {
            // BUGFIX (data): tránh `as Map<String, dynamic>` ném TypeError khi
            // phần tử không phải Map.
            if (rb is! Map) continue;
            final b = BranchModel.fromJson(Map<String, dynamic>.from(rb));
            branchMap[b.id] = b;
          }
        } catch (e, st) {
          debugPrint('Error: $e\n$st');
        } // Ignore if an owner's branches fail to load
      }

      // 3. Merge
      final List<StaffAssignmentWithBranch> merged = [];
      for (final a in rawAssignments) {
        // BUGFIX (data): coerce an toàn các trường id — tránh TypeError khi
        // backend trả String/null.
        final rawBId = a['branchId'];
        final bId = rawBId is num
            ? rawBId.toInt()
            : int.tryParse(rawBId?.toString() ?? '');
        if (bId == null) continue;
        final branch = branchMap[bId];

        final rawAId = a['id'];
        final aId = rawAId is num
            ? rawAId.toInt()
            : int.tryParse(rawAId?.toString() ?? '');
        if (aId == null) continue;

        final rawOId = a['ownerId'];
        final oId = rawOId is num
            ? rawOId.toInt()
            : int.tryParse(rawOId?.toString() ?? '');
        if (oId == null) continue;

        // Hỗ trợ cả CSV lẫn JSON permissions
        final permsStr = a['permissions']?.toString();
        final perms = StaffPermissions.parse(permsStr);

        merged.add(
          StaffAssignmentWithBranch(
            assignmentId: aId,
            branchId: bId,
            ownerId: oId,
            branchName: branch?.branchName ?? 'Khu trọ #$bId',
            address: branch?.address ?? '',
            permissions: perms,
            role: a['staffRole']?.toString() ?? 'STAFF',
          ),
        );
      }

      // Set state and auto-select first branch
      state = state.copyWith(
        isLoading: false,
        assignments: merged,
        activeBranchId: merged.isNotEmpty ? merged.first.branchId : null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setActiveBranch(int branchId) {
    state = state.copyWith(activeBranchId: branchId);
  }
}
