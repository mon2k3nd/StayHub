import 'addon_model.dart';

class TenantAddonRequestModel {
  final int id;
  final int tenantId;
  final int roomId;
  final AddonModel addonService;
  final int quantity;
  final String status;
  final String? statusNote;
  final DateTime? requestedAt;
  final DateTime? resolvedAt;
  final int? billMonth;
  final int? billYear;
  final bool isBilled;

  const TenantAddonRequestModel({
    required this.id,
    required this.tenantId,
    required this.roomId,
    required this.addonService,
    this.quantity = 1,
    this.status = 'PENDING',
    this.statusNote,
    this.requestedAt,
    this.resolvedAt,
    this.billMonth,
    this.billYear,
    this.isBilled = false,
  });

  factory TenantAddonRequestModel.fromJson(Map<String, dynamic> json) {
    // BUGFIX (data): coerce an toàn — tránh `as int`/`as Map` ném TypeError
    // khi JSON trả id dạng String hoặc addonService null/khác kiểu.
    final rawId = json['id'];
    final rawTenantId = json['tenantId'];
    final rawRoomId = json['roomId'];
    final rawAddon = json['addonService'];
    return TenantAddonRequestModel(
      id: rawId is num ? rawId.toInt() : int.tryParse('$rawId') ?? 0,
      tenantId: rawTenantId is num
          ? rawTenantId.toInt()
          : int.tryParse('$rawTenantId') ?? 0,
      roomId: rawRoomId is num
          ? rawRoomId.toInt()
          : int.tryParse('$rawRoomId') ?? 0,
      addonService: AddonModel.fromJson(
        rawAddon is Map ? Map<String, dynamic>.from(rawAddon) : const {},
      ),
      quantity: json['quantity'] as int? ?? 1,
      status: json['status'] as String? ?? 'PENDING',
      statusNote: json['statusNote'] as String?,
      requestedAt: json['requestedAt'] == null
          ? null
          : DateTime.parse(json['requestedAt'] as String),
      resolvedAt: json['resolvedAt'] == null
          ? null
          : DateTime.parse(json['resolvedAt'] as String),
      billMonth: json['billMonth'] as int?,
      billYear: json['billYear'] as int?,
      isBilled: json['isBilled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenantId': tenantId,
      'roomId': roomId,
      'addonService': addonService.toJson(),
      'quantity': quantity,
      'status': status,
      'statusNote': statusNote,
      'requestedAt': requestedAt?.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'billMonth': billMonth,
      'billYear': billYear,
      'isBilled': isBilled,
    };
  }
}
