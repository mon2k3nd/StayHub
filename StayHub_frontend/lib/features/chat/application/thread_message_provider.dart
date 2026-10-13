import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:convert';
import '../../../core/network/custom_sse_client.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/application/auth_notifier.dart';
import 'dart:async';

part 'thread_message_provider.g.dart';

class ThreadMessage {
  final int id;
  final int senderId;
  final String senderName;
  final String content;
  final String messageType;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final bool isMe;

  ThreadMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.messageType,
    this.metadata,
    required this.createdAt,
    required this.isMe,
  });

  factory ThreadMessage.fromJson(Map<String, dynamic> json, int currentUserId) {
    // BUGFIX (Bug 99): `json['id']`/`json['senderId']` trước đây gán thẳng vào
    // trường `int` → ném TypeError khi backend trả null hoặc chuỗi. Dùng helper
    // ép kiểu an toàn.
    int asInt(dynamic v, [int fallback = 0]) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    Map<String, dynamic>? meta;
    if (json['metadata'] != null) {
      if (json['metadata'] is String) {
        try {
          final decoded = jsonDecode(json['metadata']);
          if (decoded is Map) meta = Map<String, dynamic>.from(decoded);
        } catch (_) {}
      } else if (json['metadata'] is Map) {
        meta = Map<String, dynamic>.from(json['metadata']);
      }
    }
    // BUGFIX (Bug 99): `DateTime.parse` ném FormatException với chuỗi hỏng.
    DateTime createdAt;
    try {
      createdAt = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now();
    } catch (_) {
      createdAt = DateTime.now();
    }
    final senderId = asInt(json['senderId']);
    return ThreadMessage(
      id: asInt(json['id']),
      senderId: senderId,
      senderName: json['senderName'] ?? '',
      content: json['content'] ?? '',
      messageType: json['messageType'] ?? 'TEXT',
      metadata: meta,
      createdAt: createdAt,
      isMe: senderId == currentUserId,
    );
  }
}

class ThreadMessageState {
  final List<ThreadMessage> messages;
  final bool isLoading;

  ThreadMessageState({required this.messages, this.isLoading = false});
  ThreadMessageState copyWith({
    List<ThreadMessage>? messages,
    bool? isLoading,
  }) {
    return ThreadMessageState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@riverpod
class ThreadMessageNotifier extends _$ThreadMessageNotifier {
  CustomSseClient? _sseClient;
  // BUGFIX (Bug 40): giữ StreamSubscription để huỷ hẳn khi provider dispose.
  // Trước đây chỉ gọi `unsubscribeFromSSE()` nhưng không cancel subscription
  // → listener vẫn có thể bắn sau khi dispose (rò rỉ + setState trên state cũ).
  StreamSubscription<dynamic>? _sseSub;

  @override
  ThreadMessageState build(int threadId) {
    unawaited(_loadMessages());
    _connectSse();

    ref.onDispose(() {
      unawaited(_sseSub?.cancel());
      _sseSub = null;
      _sseClient?.unsubscribeFromSSE();
    });

    return ThreadMessageState(messages: [], isLoading: true);
  }

  Future<void> _loadMessages() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/v1/conversations/$threadId/messages');
      if (res.data is List) {
        final authUser = ref.read(authProvider).value;
        // BUGFIX (Bug 6): nếu chưa có user (id=0) thì không thể xác định
        // isMe. Dùng -1 để không tin nhắn nào bị gán nhầm là "của tôi".
        final currentUserId = authUser?.id ?? -1;
        final fetched = (res.data as List)
            .map((e) => ThreadMessage.fromJson(e, currentUserId))
            .toList();
        // BUGFIX (Bug 32): trước đây gán đè toàn bộ danh sách bằng dữ liệu
        // vừa tải → tin nhắn realtime (SSE) đến trong lúc request đang bay bị
        // mất. Merge theo id: giữ tin nhắn đã có, thêm tin mới từ server.
        final byId = <int, ThreadMessage>{
          for (final m in state.messages) m.id: m,
          for (final m in fetched) m.id: m,
        };
        final merged = byId.values.toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        state = state.copyWith(messages: merged, isLoading: false);
      }
    } catch (e) {
      debugPrint('Error loading thread msgs: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  void _connectSse() {
    _sseClient = CustomSseClient();
    // BUGFIX (Bug 40): lưu subscription để cancel khi dispose.
    _sseSub = _sseClient!
        .subscribeToSSE(
          method: SSERequestType.get,
          url: '${ApiClient.baseUrl}/v1/conversations/$threadId/stream',
          header: {"Accept": "text/event-stream"},
        )
        .listen(
          onError: (Object e, StackTrace st) {
            // BUGFIX (Bug 132): thêm onError cho SSE subscription — trước đây
            // không có handler nên lỗi stream (mất mạng, server đóng) trở thành
            // unhandled async error. Giờ chỉ log gọn để app mượt.
            debugPrint('[ThreadMessageProvider] SSE error: $e');
          },
          (event) {
            if (event.event == 'RECONNECT_SUCCESS') {
              debugPrint(
                '[ThreadMessageProvider] Reconnected! Fetching missed messages...',
              );
              unawaited(_loadMessages()); // Fetch again to get missed messages
            } else if (event.event == 'MESSAGE' &&
                event.data != null &&
                event.data!.isNotEmpty) {
              try {
                final authUser = ref.read(authProvider).value;
                // BUGFIX (Bug 6): dùng -1 khi chưa có user để tránh gán nhầm isMe.
                final currentUserId = authUser?.id ?? -1;
                final json = jsonDecode(event.data!);
                final newMsg = ThreadMessage.fromJson(json, currentUserId);

                if (!state.messages.any((m) => m.id == newMsg.id)) {
                  // BUGFIX (Bug 7): sắp xếp lại theo createdAt sau khi thêm tin
                  // nhắn realtime, tránh tin nhắn hiển thị sai thứ tự khi SSE
                  // đến lệch nhịp so với danh sách đã tải.
                  final updated = [...state.messages, newMsg]
                    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
                  state = state.copyWith(messages: updated);
                }
              } catch (e) {
                debugPrint('SSE Thread Parse Error: $e');
              }
            }
          },
        );
  }

  /// BUGFIX (Bug 29): trả về `bool` để UI biết gửi thành công hay thất bại,
  /// từ đó chỉ clear ô nhập khi thành công và hiển thị toast lỗi khi thất bại.
  Future<bool> sendMessage(
    String text, {
    String type = 'TEXT',
    Map<String, dynamic>? meta,
  }) async {
    final authUser = ref.read(authProvider).value;
    if (authUser == null) return false;

    try {
      final dio = ref.read(dioProvider);
      // BUGFIX (Bug 5): không gửi senderId/senderName từ client — backend đã
      // lấy danh tính từ token xác thực. Gửi kèm cho phép giả mạo người gửi.
      final payload = {'message': text, 'messageType': type};
      if (meta != null) payload['metadata'] = jsonEncode(meta);

      await dio.post('/v1/conversations/$threadId/messages', data: payload);
      return true;
    } catch (e) {
      debugPrint('Thread Send Error: $e');
      return false;
    }
  }
}
