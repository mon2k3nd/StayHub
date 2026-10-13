import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async' show unawaited;

class StaffRole {
  final String id;
  final String roleName;
  final String description;
  final int memberCount;
  final List<String> permissions;

  const StaffRole({
    required this.id,
    required this.roleName,
    required this.description,
    required this.memberCount,
    required this.permissions,
  });

  StaffRole copyWith({
    String? roleName,
    String? description,
    int? memberCount,
    List<String>? permissions,
  }) {
    return StaffRole(
      id: id,
      roleName: roleName ?? this.roleName,
      description: description ?? this.description,
      memberCount: memberCount ?? this.memberCount,
      permissions: permissions ?? this.permissions,
    );
  }
}

class RbacState {
  final bool isLoading;
  final List<StaffRole> roles;
  final List<String> availablePermissions;

  const RbacState({
    this.isLoading = false,
    this.roles = const [],
    this.availablePermissions = const [
      'Quản lý Hợp Đồng',
      'Thu Tiền Hàng Tháng',
      'Phê Duyệt Dịch Vụ',
      'Sửa Chữa Cơ Sở',
      'Cấu Hình IoT',
      'Đọc Báo Cáo Tài Chính',
    ],
  });

  RbacState copyWith({
    bool? isLoading,
    List<StaffRole>? roles,
    List<String>? availablePermissions,
  }) {
    return RbacState(
      isLoading: isLoading ?? this.isLoading,
      roles: roles ?? this.roles,
      availablePermissions: availablePermissions ?? this.availablePermissions,
    );
  }
}

class RbacNotifier extends Notifier<RbacState> {
  @override
  build() {
    unawaited(Future.microtask(_loadRoles));
    return const RbacState();
  }

  Future<void> _loadRoles() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 1000));

    final mockRoles = [
      const StaffRole(
        id: 'r1',
        roleName: 'Quản Lý Khu',
        description: 'Toàn quyền điều hành tại chi nhánh',
        memberCount: 2,
        permissions: [
          'Quản lý Hợp Đồng',
          'Thu Tiền Hàng Tháng',
          'Phê Duyệt Dịch Vụ',
        ],
      ),
      const StaffRole(
        id: 'r2',
        roleName: 'Thợ Bảo Trì',
        description: 'Nhận yêu cầu sửa chữa và kiểm tra tài sản',
        memberCount: 5,
        permissions: ['Sửa Chữa Cơ Sở', 'Cấu Hình IoT'],
      ),
      const StaffRole(
        id: 'r3',
        roleName: 'Kế Toán',
        description: 'Theo dõi dòng tiền và thu chi',
        memberCount: 1,
        permissions: ['Đọc Báo Cáo Tài Chính', 'Thu Tiền Hàng Tháng'],
      ),
    ];

    // if (!mounted) return;
    state = state.copyWith(isLoading: false, roles: mockRoles);
  }

  void togglePermission(String roleId, String permission) {
    final idx = state.roles.indexWhere((r) => r.id == roleId);
    if (idx == -1) return;

    final role = state.roles[idx];
    final perms = List<String>.from(role.permissions);

    if (perms.contains(permission)) {
      perms.remove(permission);
    } else {
      perms.add(permission);
    }

    final updatedRoles = List<StaffRole>.from(state.roles);
    updatedRoles[idx] = role.copyWith(permissions: perms);
    state = state.copyWith(roles: updatedRoles);
  }
}

final rbacProvider = NotifierProvider<RbacNotifier, RbacState>(
  RbacNotifier.new,
);
