class GlobalSearchResponse {
  final List<TenantSearchResult> tenants;
  final List<RoomSearchResult> roomsAndContracts;

  GlobalSearchResponse({
    required this.tenants,
    required this.roomsAndContracts,
  });

  factory GlobalSearchResponse.fromJson(Map<String, dynamic> json) {
    return GlobalSearchResponse(
      tenants:
          (json['tenants'] as List?)
              ?.map((e) => TenantSearchResult.fromJson(e))
              .toList() ??
          [],
      roomsAndContracts:
          (json['roomsAndContracts'] as List?)
              ?.map((e) => RoomSearchResult.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class TenantSearchResult {
  final int id;
  final String name;
  final String phone;
  final String cccd;
  final int? roomId;
  final String? roomName;

  TenantSearchResult({
    required this.id,
    required this.name,
    required this.phone,
    required this.cccd,
    this.roomId,
    this.roomName,
  });

  factory TenantSearchResult.fromJson(Map<String, dynamic> json) {
    return TenantSearchResult(
      id: json['id'],
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      cccd: json['cccd'] ?? '',
      roomId: json['roomId'],
      roomName: json['roomName'],
    );
  }
}

class RoomSearchResult {
  final int id;
  final String name;
  final String status;
  final int? contractId;
  final String? tenantName;

  RoomSearchResult({
    required this.id,
    required this.name,
    required this.status,
    this.contractId,
    this.tenantName,
  });

  factory RoomSearchResult.fromJson(Map<String, dynamic> json) {
    return RoomSearchResult(
      id: json['id'],
      name: json['name'] ?? '',
      status: json['status'] ?? '',
      contractId: json['contractId'],
      tenantName: json['tenantName'],
    );
  }
}
