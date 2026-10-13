import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/application/auth_notifier.dart';

part 'conversation_provider.g.dart';

class MessageThreadModel {
  final int id;
  final int userId1;
  final int userId2;
  final String threadType;
  final DateTime updatedAt;
  final String? lastMessageContent;
  final int? lastSenderId;
  final String? lastSenderName;
  final DateTime? user1LastRead;
  final DateTime? user2LastRead;
  final bool user1IsDeleted;
  final bool user2IsDeleted;
  final bool user1IsSaved;
  final bool user2IsSaved;

  bool isDeletedBy(int userId) {
    if (userId == userId1) return user1IsDeleted;
    if (userId == userId2) return user2IsDeleted;
    return false;
  }

  bool isSavedBy(int userId) {
    if (userId == userId1) return user1IsSaved;
    if (userId == userId2) return user2IsSaved;
    return false;
  }

  MessageThreadModel({
    required this.id,
    required this.userId1,
    required this.userId2,
    required this.threadType,
    required this.updatedAt,
    this.lastMessageContent,
    this.lastSenderId,
    this.lastSenderName,
    this.user1LastRead,
    this.user2LastRead,
    this.user1IsDeleted = false,
    this.user2IsDeleted = false,
    this.user1IsSaved = false,
    this.user2IsSaved = false,
  });

  factory MessageThreadModel.fromJson(Map<String, dynamic> json) {
    // BUGFIX (Bug 93): trước đây ép kiểu trực tiếp `json['id']` / `userId1` /
    // `userId2` sang int — nếu backend trả null hoặc kiểu khác (String) sẽ
    // ném TypeError làm hỏng toàn bộ danh sách hội thoại. Dùng parse an toàn.
    int asInt(dynamic v, [int fallback = 0]) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    // BUGFIX (Bug 107): `DateTime.parse` không bọc try/catch → ném
    // FormatException khi backend trả chuỗi ngày không hợp lệ, làm hỏng cả
    // danh sách hội thoại. Bọc an toàn, fallback về null/now.
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return MessageThreadModel(
      id: asInt(json['id']),
      userId1: asInt(json['userId1']),
      userId2: asInt(json['userId2']),
      threadType: json['threadType'] ?? 'INQUIRY',
      updatedAt: parseDate(json['updatedAt']) ?? DateTime.now(),
      lastMessageContent: json['lastMessageContent'],
      lastSenderId: json['lastSenderId'],
      lastSenderName: json['lastSenderName'],
      user1LastRead: parseDate(json['user1LastRead']),
      user2LastRead: parseDate(json['user2LastRead']),
      user1IsDeleted: json['user1IsDeleted'] ?? false,
      user2IsDeleted: json['user2IsDeleted'] ?? false,
      user1IsSaved: json['user1IsSaved'] ?? false,
      user2IsSaved: json['user2IsSaved'] ?? false,
    );
  }
}

@Riverpod(keepAlive: true)
class ConversationNotifier extends _$ConversationNotifier {
  @override
  FutureOr<List<MessageThreadModel>> build() async {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    if (user == null) return [];

    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/v1/conversations/user/${user.id}');
      if (res.data is List) {
        return (res.data as List)
            .map((e) => MessageThreadModel.fromJson(e))
            .toList();
      }
    } catch (e, st) {
      debugPrint('Error fetching conversations: $e\n$st');
    }
    return [];
  }

  Future<MessageThreadModel?> createOrGetThread(
    int otherUserId,
    String type,
  ) async {
    final authState = ref.read(authProvider);
    final user = authState.value;
    if (user == null) return null;

    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post(
        '/v1/conversations',
        data: {'userId1': user.id, 'userId2': otherUserId, 'threadType': type},
      );

      final thread = MessageThreadModel.fromJson(res.data);
      ref.invalidateSelf();
      return thread;
    } catch (e) {
      debugPrint('Error creating thread: $e');
      return null;
    }
  }

  Future<void> markThreadAsRead(int threadId) async {
    final authState = ref.read(authProvider);
    final user = authState.value;
    if (user == null) return;

    try {
      final dio = ref.read(dioProvider);
      await dio.put('/v1/conversations/$threadId/read?userId=${user.id}');
      // Update local state without full reload
      final currentThreads = state.value;
      if (currentThreads != null) {
        state = AsyncData(
          currentThreads.map((t) {
            if (t.id == threadId) {
              // BUGFIX (Bug 1 & 9): giữ nguyên các cờ isDeleted/isSaved và
              // updatedAt khi cập nhật trạng thái đã đọc. Trước đây tạo lại
              // MessageThreadModel mà bỏ qua 4 cờ này khiến chúng reset về
              // false → hội thoại đã lưu/đã xoá bị "sống lại" sau khi đọc.
              return MessageThreadModel(
                id: t.id,
                userId1: t.userId1,
                userId2: t.userId2,
                threadType: t.threadType,
                updatedAt: t.updatedAt,
                lastMessageContent: t.lastMessageContent,
                lastSenderId: t.lastSenderId,
                lastSenderName: t.lastSenderName,
                user1LastRead: user.id == t.userId1
                    ? DateTime.now()
                    : t.user1LastRead,
                user2LastRead: user.id == t.userId2
                    ? DateTime.now()
                    : t.user2LastRead,
                user1IsDeleted: t.user1IsDeleted,
                user2IsDeleted: t.user2IsDeleted,
                user1IsSaved: t.user1IsSaved,
                user2IsSaved: t.user2IsSaved,
              );
            }
            return t;
          }).toList(),
        );
      }
    } catch (e) {
      debugPrint('Error marking thread as read: $e');
    }
  }

  Future<void> toggleSaveThread(int threadId) async {
    final authState = ref.read(authProvider);
    final user = authState.value;
    if (user == null) return;

    try {
      final dio = ref.read(dioProvider);
      await dio.put('/v1/conversations/$threadId/save?userId=${user.id}');
      ref.invalidateSelf();
    } catch (e) {
      debugPrint('Error saving thread: $e');
    }
  }

  Future<void> toggleDeleteThread(int threadId) async {
    final authState = ref.read(authProvider);
    final user = authState.value;
    if (user == null) return;

    try {
      final dio = ref.read(dioProvider);
      await dio.put('/v1/conversations/$threadId/delete?userId=${user.id}');
      ref.invalidateSelf();
    } catch (e) {
      debugPrint('Error deleting thread: $e');
    }
  }
}
