class BranchRule {
  final int id;
  final int branchId;
  final String title;
  final String description;
  final double penaltyAmount;
  final String appliesTo; // TENANT, STAFF, ALL
  final bool isActive;
  final DateTime createdAt;

  BranchRule({
    required this.id,
    required this.branchId,
    required this.title,
    required this.description,
    required this.penaltyAmount,
    required this.appliesTo,
    required this.isActive,
    required this.createdAt,
  });

  // BUGFIX (data): coerce an toàn — tránh `as int?`/`as String?` ném TypeError
  // khi backend trả kiểu khác (id dạng chuỗi, số cho String...).
  static int? _toIntOrNull(dynamic v) =>
      v == null ? null : (v is num ? v.toInt() : int.tryParse(v.toString()));

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  factory BranchRule.fromJson(Map<String, dynamic> json) {
    return BranchRule(
      id: _toIntOrNull(json['id']) ?? 0,
      branchId: _toIntOrNull(json['branchId']) ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      penaltyAmount: json['penaltyAmount'] is num
          ? (json['penaltyAmount'] as num).toDouble()
          : double.tryParse(json['penaltyAmount']?.toString() ?? '') ?? 0.0,
      appliesTo: json['appliesTo']?.toString() ?? 'TENANT',
      isActive: json['isActive'] is bool ? json['isActive'] as bool : true,
      createdAt: _toDate(json['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'branchId': branchId,
      'title': title,
      'description': description,
      'penaltyAmount': penaltyAmount,
      'appliesTo': appliesTo,
      'isActive': isActive,
    };
  }
}
