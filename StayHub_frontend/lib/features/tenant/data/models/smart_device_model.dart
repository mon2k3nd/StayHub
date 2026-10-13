class SmartDeviceModel {
  final int? id;
  final int roomId;
  final String name;
  final String deviceType;
  final String status;
  final String? settings;
  final bool isOnline;

  const SmartDeviceModel({
    this.id,
    required this.roomId,
    required this.name,
    required this.deviceType,
    required this.status,
    this.settings,
    this.isOnline = true,
  });

  // BUGFIX (data): coerce an toàn — tránh TypeError khi backend trả String/null.
  static int _toInt(dynamic v) =>
      v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

  static int? _toIntOrNull(dynamic v) =>
      v == null ? null : (v is num ? v.toInt() : int.tryParse(v.toString()));

  factory SmartDeviceModel.fromJson(Map<String, dynamic> json) =>
      SmartDeviceModel(
        id: _toIntOrNull(json['id']),
        roomId: _toInt(json['roomId']),
        name: json['name']?.toString() ?? 'Thiết bị',
        deviceType: json['deviceType']?.toString() ?? 'UNKNOWN',
        status: json['status']?.toString() ?? 'OFF',
        settings: json['settings']?.toString(),
        isOnline: json['isOnline'] is bool
            ? json['isOnline'] as bool
            : (json['isOnline']?.toString().toLowerCase() == 'true'),
      );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'roomId': roomId,
    'name': name,
    'deviceType': deviceType,
    'status': status,
    if (settings != null) 'settings': settings,
    'isOnline': isOnline,
  };

  SmartDeviceModel copyWith({
    int? id,
    int? roomId,
    String? name,
    String? deviceType,
    String? status,
    String? settings,
    bool? isOnline,
  }) {
    return SmartDeviceModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      name: name ?? this.name,
      deviceType: deviceType ?? this.deviceType,
      status: status ?? this.status,
      settings: settings ?? this.settings,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
