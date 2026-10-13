class ViolationReport {
  final int id;
  final int? ruleId;
  final String targetType; // TENANT, STAFF
  final int? targetId; // roomId or staffId
  final int? roomId;
  final int? contractId;
  final String violationType;
  final String description;
  final double penaltyAmount;
  final String status; // PENDING, PAID, CANCELLED
  final DateTime createdAt;

  ViolationReport({
    required this.id,
    this.ruleId,
    required this.targetType,
    this.targetId,
    this.roomId,
    this.contractId,
    required this.violationType,
    required this.description,
    required this.penaltyAmount,
    required this.status,
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

  factory ViolationReport.fromJson(Map<String, dynamic> json) {
    return ViolationReport(
      id: _toIntOrNull(json['id']) ?? 0,
      ruleId: _toIntOrNull(json['ruleId']),
      targetType: json['targetType']?.toString() ?? 'TENANT',
      targetId: _toIntOrNull(json['targetId']),
      roomId: _toIntOrNull(json['roomId']),
      contractId: _toIntOrNull(json['contractId']),
      violationType: json['violationType']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      penaltyAmount: json['penaltyAmount'] is num
          ? (json['penaltyAmount'] as num).toDouble()
          : double.tryParse(json['penaltyAmount']?.toString() ?? '') ?? 0.0,
      status: json['status']?.toString() ?? 'PENDING',
      createdAt: _toDate(json['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ruleId': ruleId,
      'targetType': targetType,
      'targetId': targetId,
      'roomId': roomId,
      'contractId': contractId,
      'violationType': violationType,
      'description': description,
      'penaltyAmount': penaltyAmount,
      'status': status,
    };
  }
}
