// Simple model (no freezed) — plain Dart class
class VoucherModel {
  final int? id;
  final String code;
  final String discountType;
  final double? discountAmount;
  final double? discountPercent;
  final double? maxDiscountAmount;
  final String? fundedBy;
  final String? appliesToTarget;
  final String? scopeType;
  final int? branchId;
  final bool applyAllRooms;
  final String? targetIds;
  final int? totalUsageLimit;
  final int? usedCount;
  final int? monthsPerTenant;
  final bool isActive;
  final String? createdAt;
  final String? endDate;
  final String? createdByRole;

  const VoucherModel({
    this.id,
    required this.code,
    required this.discountType,
    this.discountAmount,
    this.discountPercent,
    this.maxDiscountAmount,
    this.fundedBy,
    this.appliesToTarget,
    this.scopeType,
    this.branchId,
    this.applyAllRooms = false,
    this.targetIds,
    this.totalUsageLimit,
    this.usedCount,
    this.monthsPerTenant,
    this.isActive = true,
    this.createdAt,
    this.endDate,
    this.createdByRole,
  });

  factory VoucherModel.fromJson(Map<String, dynamic> j) => VoucherModel(
    id: j['id'] as int?,
    code: (j['code'] as String?) ?? '',
    discountType: (j['discountType'] as String?) ?? 'FIXED_AMOUNT',
    discountAmount: (j['discountAmount'] as num?)?.toDouble(),
    discountPercent: (j['discountPercent'] as num?)?.toDouble(),
    maxDiscountAmount: (j['maxDiscountAmount'] as num?)?.toDouble(),
    fundedBy: j['fundedBy'] as String?,
    appliesToTarget: j['appliesToTarget'] as String?,
    scopeType: j['scopeType'] as String?,
    branchId: j['branchId'] as int?,
    applyAllRooms: j['applyAllRooms'] as bool? ?? false,
    targetIds: j['targetIds'] as String?,
    totalUsageLimit: j['totalUsageLimit'] as int?,
    usedCount: j['usedCount'] as int?,
    monthsPerTenant: j['monthsPerTenant'] as int?,
    isActive: j['isActive'] as bool? ?? true,
    createdAt: j['createdAt'] as String?,
    endDate: j['endDate'] as String?,
    createdByRole: j['createdByRole'] as String?,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'code': code,
    'discountType': discountType,
    if (discountAmount != null) 'discountAmount': discountAmount,
    if (discountPercent != null) 'discountPercent': discountPercent,
    if (maxDiscountAmount != null) 'maxDiscountAmount': maxDiscountAmount,
    if (fundedBy != null) 'fundedBy': fundedBy,
    if (appliesToTarget != null) 'appliesToTarget': appliesToTarget,
    if (scopeType != null) 'scopeType': scopeType,
    if (branchId != null) 'branchId': branchId,
    'applyAllRooms': applyAllRooms,
    if (targetIds != null) 'targetIds': targetIds,
    if (totalUsageLimit != null) 'totalUsageLimit': totalUsageLimit,
    if (usedCount != null) 'usedCount': usedCount,
    if (monthsPerTenant != null) 'monthsPerTenant': monthsPerTenant,
    'isActive': isActive,
    if (createdAt != null) 'createdAt': createdAt,
    if (endDate != null) 'endDate': endDate,
    if (createdByRole != null) 'createdByRole': createdByRole,
  };
}
