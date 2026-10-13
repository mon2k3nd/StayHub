class Conversation {
  final String id;
  final int userId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Conversation({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  // BUGFIX (Bug 106): trước đây ép kiểu trực tiếp (`as String`/`as int`) và
  // `DateTime.parse` không bọc try/catch → ném TypeError/FormatException khi
  // payload thiếu trường hoặc sai kiểu, làm hỏng toàn bộ danh sách.
  factory Conversation.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return Conversation(
      id: json['id']?.toString() ?? '',
      userId: json['userId'] is int
          ? json['userId'] as int
          : int.tryParse(json['userId']?.toString() ?? '') ?? 0,
      title: json['title']?.toString() ?? '',
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

class ChatMessage {
  final int? id;
  final String conversationId;
  final String senderType;
  final String content;
  final String status;
  final DateTime createdAt;

  const ChatMessage({
    this.id,
    required this.conversationId,
    required this.senderType,
    required this.content,
    required this.status,
    required this.createdAt,
  });

  // BUGFIX (Bug 106): ép kiểu trực tiếp + DateTime.parse không bọc try/catch →
  // crash khi payload sai kiểu. Dùng parse an toàn.
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    return ChatMessage(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? ''),
      conversationId: json['conversationId']?.toString() ?? '',
      senderType: json['senderType']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'senderType': senderType,
    'content': content,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
  };

  ChatMessage copyWith({
    int? id,
    String? conversationId,
    String? senderType,
    String? content,
    String? status,
    DateTime? createdAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderType: senderType ?? this.senderType,
      content: content ?? this.content,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
