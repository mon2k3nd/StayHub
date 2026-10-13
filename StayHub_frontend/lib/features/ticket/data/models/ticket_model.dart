class TicketModel {
  final int id;
  final int roomId;
  final int tenantId;
  final int? assignedStaffId;
  final String category;
  final String? description;
  final String? proofImageUrl;
  final String status;
  final double materialCost;
  final double staffBonus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? tenantName;
  final String? tenantPhone;
  final String? roomName;
  final String? branchName;
  final String? severity;
  final String? tenantDesire;
  final bool? isSuccessful;
  final String? repairDetails;
  final String? propertyAddress;
  final double? roomPrice;
  final double? roomArea;
  final List<String>? roommatesPhones;

  const TicketModel({
    required this.id,
    required this.roomId,
    required this.tenantId,
    this.assignedStaffId,
    required this.category,
    this.description,
    this.proofImageUrl,
    required this.status,
    this.materialCost = 0.0,
    this.staffBonus = 0.0,
    this.createdAt,
    this.updatedAt,
    this.tenantName,
    this.tenantPhone,
    this.roomName,
    this.branchName,
    this.severity,
    this.tenantDesire,
    this.isSuccessful,
    this.repairDetails,
    this.propertyAddress,
    this.roomPrice,
    this.roomArea,
    this.roommatesPhones,
  });

  // BUGFIX (data): coerce an toàn — tránh TypeError khi backend trả String/null.
  static int _toInt(dynamic v) =>
      v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

  static int? _toIntOrNull(dynamic v) =>
      v == null ? null : (v is num ? v.toInt() : int.tryParse(v.toString()));

  static double? _toDoubleOrNull(dynamic v) => v == null
      ? null
      : (v is num ? v.toDouble() : double.tryParse(v.toString()));

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: _toInt(json['id']),
      roomId: _toInt(json['roomId']),
      tenantId: _toInt(json['tenantId']),
      assignedStaffId: _toIntOrNull(json['assignedStaffId']),
      category: json['category']?.toString() ?? 'OTHER',
      description: json['description']?.toString(),
      proofImageUrl: json['proofImageUrl']?.toString(),
      status: json['status']?.toString() ?? 'PENDING',
      materialCost: _toDoubleOrNull(json['materialCost']) ?? 0.0,
      staffBonus: _toDoubleOrNull(json['staffBonus']) ?? 0.0,
      createdAt: _toDate(json['createdAt']),
      updatedAt: _toDate(json['updatedAt']),
      tenantName: json['tenantName']?.toString(),
      tenantPhone: json['tenantPhone']?.toString(),
      roomName: json['roomName']?.toString(),
      branchName: json['branchName']?.toString(),
      severity: json['severity']?.toString(),
      tenantDesire: json['tenantDesire']?.toString(),
      isSuccessful: json['isSuccessful'] is bool
          ? json['isSuccessful'] as bool
          : null,
      repairDetails: json['repairDetails']?.toString(),
      propertyAddress: json['propertyAddress']?.toString(),
      roomPrice: _toDoubleOrNull(json['roomPrice']),
      roomArea: _toDoubleOrNull(json['roomArea']),
      roommatesPhones: json['roommatesPhones'] is List
          ? (json['roommatesPhones'] as List)
                .map((e) => e?.toString() ?? '')
                .where((e) => e.isNotEmpty)
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'tenantId': tenantId,
      'assignedStaffId': assignedStaffId,
      'category': category,
      'description': description,
      'proofImageUrl': proofImageUrl,
      'status': status,
      'materialCost': materialCost,
      'staffBonus': staffBonus,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'tenantName': tenantName,
      'tenantPhone': tenantPhone,
      'roomName': roomName,
      'branchName': branchName,
      'severity': severity,
      'tenantDesire': tenantDesire,
      'isSuccessful': isSuccessful,
      'repairDetails': repairDetails,
      'propertyAddress': propertyAddress,
      'roomPrice': roomPrice,
      'roomArea': roomArea,
      'roommatesPhones': roommatesPhones,
    };
  }
}
