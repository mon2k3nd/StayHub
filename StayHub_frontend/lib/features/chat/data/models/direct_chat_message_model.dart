// Simple model replacing Freezed due to version mismatch
class DirectChatMessageModel {
  final int? id;
  final int senderId;
  final int receiverId;
  final String content;
  final String messageType;
  final bool isRead;
  final DateTime? createdAt;
  final bool isOptimistic;
  final bool hasError;

  const DirectChatMessageModel({
    this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.messageType = 'TEXT',
    this.isRead = false,
    this.createdAt,
    this.isOptimistic = false,
    this.hasError = false,
  });

  factory DirectChatMessageModel.fromJson(Map<String, dynamic> json) {
    // BUGFIX (Bug 100): các cast `as int?`/`as String` ném TypeError khi backend
    // trả kiểu khác (ví dụ id dạng chuỗi số, senderId null). Dùng helper ép
    // kiểu an toàn cho int và bọc DateTime.parse trong try/catch.
    int? asIntOrNull(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    DateTime? createdAt;
    if (json['createdAt'] != null) {
      try {
        createdAt = DateTime.parse(json['createdAt'].toString());
      } catch (_) {
        createdAt = null;
      }
    }
    // BUGFIX (Bug 133): `json['isRead'] as bool?` ném TypeError khi backend trả
    // kiểu khác (ví dụ "true"/1). Dùng helper ép kiểu bool an toàn.
    bool asBool(dynamic v, [bool fallback = false]) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final s = v.toLowerCase();
        return s == 'true' || s == '1';
      }
      return fallback;
    }

    return DirectChatMessageModel(
      id: asIntOrNull(json['id']),
      senderId: asIntOrNull(json['senderId']) ?? 0,
      receiverId: asIntOrNull(json['receiverId']) ?? 0,
      content: json['content']?.toString() ?? '',
      messageType: json['messageType']?.toString() ?? 'TEXT',
      isRead: asBool(json['isRead']),
      createdAt: createdAt,
      isOptimistic: asBool(json['isOptimistic']),
      hasError: asBool(json['hasError']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'receiverId': receiverId,
    'content': content,
    'messageType': messageType,
    'isRead': isRead,
    'createdAt': createdAt?.toIso8601String(),
    'isOptimistic': isOptimistic,
    'hasError': hasError,
  };

  DirectChatMessageModel copyWith({
    int? id,
    int? senderId,
    int? receiverId,
    String? content,
    String? messageType,
    bool? isRead,
    DateTime? createdAt,
    bool? isOptimistic,
    bool? hasError,
  }) {
    return DirectChatMessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      isOptimistic: isOptimistic ?? this.isOptimistic,
      hasError: hasError ?? this.hasError,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DirectChatMessageModel &&
          other.id == id &&
          other.senderId == senderId &&
          other.receiverId == receiverId &&
          other.content == content &&
          other.isOptimistic == isOptimistic &&
          other.hasError == hasError;

  @override
  int get hashCode =>
      Object.hash(id, senderId, receiverId, content, isOptimistic, hasError);
}
