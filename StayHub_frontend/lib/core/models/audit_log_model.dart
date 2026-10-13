// Simple model replacing Freezed due to version mismatch
class AuditLogModel {
  final int id;
  final String entityType;
  final int entityId;
  final String action;
  final int? changedBy;
  final String? changedByName;
  final String? changes;
  final String? createdAt;

  const AuditLogModel({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    this.changedBy,
    this.changedByName,
    this.changes,
    this.createdAt,
  });

  factory AuditLogModel.fromJson(Map<String, dynamic> json) {
    return AuditLogModel(
      id: json['id'] as int? ?? 0,
      entityType: json['entityType'] as String? ?? '',
      entityId: json['entityId'] as int? ?? 0,
      action: json['action'] as String? ?? '',
      changedBy: json['changedBy'] as int?,
      changedByName: json['changedByName'] as String?,
      changes: json['changes'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'entityType': entityType,
    'entityId': entityId,
    'action': action,
    'changedBy': changedBy,
    'changedByName': changedByName,
    'changes': changes,
    'createdAt': createdAt,
  };

  AuditLogModel copyWith({
    int? id,
    String? entityType,
    int? entityId,
    String? action,
    int? changedBy,
    String? changedByName,
    String? changes,
    String? createdAt,
  }) {
    return AuditLogModel(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      changedBy: changedBy ?? this.changedBy,
      changedByName: changedByName ?? this.changedByName,
      changes: changes ?? this.changes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditLogModel &&
          other.id == id &&
          other.entityType == entityType &&
          other.entityId == entityId &&
          other.action == action;

  @override
  int get hashCode => Object.hash(id, entityType, entityId, action);

  @override
  String toString() =>
      'AuditLogModel(id: $id, entityType: $entityType, entityId: $entityId, action: $action, changedBy: $changedBy, changedByName: $changedByName, changes: $changes, createdAt: $createdAt)';
}
