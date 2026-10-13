class Role {
  static const String tenant = 'TENANT';
  static const String activeTenant = 'ACTIVE_TENANT';
  static const String staff = 'STAFF';
  static const String owner = 'OWNER';
  static const String admin = 'ADMIN';

  static bool isTenant(String? r) => r == tenant || r == activeTenant;
  static bool isOwner(String? r) => r == owner;
  static bool isStaff(String? r) => r == staff;
}

enum UserRole { tenant, staff, owner, admin }

enum TenantState {
  unlinked, // Chưa có phòng
  pendingApproval, // Đang chờ chủ nhà duyệt
  verifying, // Đang nghiệm thu phòng
  linked, // Đã có phòng
  requestingOwner, // Đang chờ duyệt lên chủ nhà
}
