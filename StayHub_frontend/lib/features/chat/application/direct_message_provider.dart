import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/custom_sse_client.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/application/auth_notifier.dart';

part 'direct_message_provider.g.dart';

class DirectMessage {
  // BUGFIX (Bug 80): thêm `id` để khử trùng lặp tin nhắn SSE theo định danh
  // thay vì so khớp nội dung (dễ trùng khi hai người gửi cùng nội dung).
  final String? id;
  final String senderId;
  final String senderName;
  final String content;
  final String messageType;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final bool isMe;

  const DirectMessage({
    this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.messageType = 'TEXT',
    this.metadata,
    required this.createdAt,
    required this.isMe,
  });

  factory DirectMessage.fromJson(
    Map<String, dynamic> json,
    String currentUserId,
  ) {
    // BUGFIX (Bug 95): `jsonDecode(json['metadata'])` ném FormatException khi
    // metadata là chuỗi JSON hỏng → làm hỏng cả quá trình parse lịch sử/SSE.
    // Bọc try/catch và chỉ decode khi là String; nếu đã là Map thì dùng luôn.
    Map<String, dynamic>? meta;
    final rawMeta = json['metadata'];
    if (rawMeta != null && rawMeta.toString().isNotEmpty) {
      if (rawMeta is Map) {
        meta = Map<String, dynamic>.from(rawMeta);
      } else {
        try {
          final decoded = jsonDecode(rawMeta.toString());
          if (decoded is Map) meta = Map<String, dynamic>.from(decoded);
        } catch (_) {}
      }
    }
    // BUGFIX (Bug 95): `DateTime.parse` ném FormatException khi createdAt là
    // chuỗi không hợp lệ → bọc try/catch, fallback về thời điểm hiện tại.
    DateTime createdAt;
    try {
      createdAt = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now();
    } catch (_) {
      createdAt = DateTime.now();
    }
    return DirectMessage(
      id: json['id']?.toString(),
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName'] ?? 'Người dùng',
      content: json['content'] ?? json['message'] ?? '',
      messageType: json['messageType'] ?? 'TEXT',
      metadata: meta,
      createdAt: createdAt,
      isMe: json['senderId']?.toString() == currentUserId,
    );
  }
}

class DirectMessageState {
  final bool isLoading;
  final List<DirectMessage> messages;

  DirectMessageState({required this.isLoading, required this.messages});
}

/// Provider for direct messages between owner and tenant via SSE on /v1/messages/stream/{roomId}
@riverpod
class DirectMessageNotifier extends _$DirectMessageNotifier {
  late int _roomId;
  CustomSseClient? _sseClient;
  // BUGFIX (Bug 79): giữ StreamSubscription để cancel hẳn khi dispose. Trước
  // đây chỉ gọi `unsubscribeFromSSE()` mà không cancel subscription → listener
  // vẫn có thể bắn sau khi provider dispose (rò rỉ + ghi state cũ).
  StreamSubscription<dynamic>? _sseSub;

  @override
  DirectMessageState build(int roomId) {
    _roomId = roomId;
    unawaited(_fetchHistory());
    _initSSE();
    ref.onDispose(() {
      unawaited(_sseSub?.cancel());
      _sseSub = null;
      _sseClient?.unsubscribeFromSSE();
    });
    return DirectMessageState(isLoading: true, messages: []);
  }

  Future<void> _fetchHistory() async {
    try {
      final dio = ref.read(dioProvider);
      final user = ref.read(authProvider).value;
      if (user == null) return;

      final response = await dio.get('/v1/messages/$_roomId');
      if (response.data is List) {
        final msgs = (response.data as List)
            .map((e) => DirectMessage.fromJson(e, user.id.toString()))
            .toList();
        state = DirectMessageState(isLoading: false, messages: msgs);
      } else {
        state = DirectMessageState(isLoading: false, messages: []);
      }
    } catch (e, st) {
      debugPrint('Error fetching chat history: $e\n$st');
      state = DirectMessageState(isLoading: false, messages: []);
    }
  }

  void _initSSE() {
    _sseClient = CustomSseClient();
    // BUGFIX (Bug 79): lưu subscription để cancel khi dispose.
    _sseSub = _sseClient!
        .subscribeToSSE(
          method: SSERequestType.get,
          url: '${ApiClient.baseUrl}/v1/messages/stream/$_roomId',
          header: {"Accept": "text/event-stream"},
        )
        .listen(
          onError: (Object e, StackTrace st) {
            // BUGFIX (Bug 131): thêm onError cho SSE subscription — trước đây
            // không có handler nên khi stream phát lỗi (mất mạng, server đóng)
            // lỗi trở thành unhandled async error, gây nhiễu log và có thể làm
            // treo vòng reconnect. Giờ chỉ log gọn để app mượt.
            debugPrint('[DirectMessageProvider] SSE error: $e');
          },
          (event) {
            if (event.event == 'RECONNECT_SUCCESS') {
              debugPrint(
                '[DirectMessageProvider] Reconnected! Fetching missed messages...',
              );
              unawaited(_fetchHistory());
            } else if (event.event == 'MESSAGE') {
              // BUGFIX (Bug 96): guard null/empty trước khi jsonDecode — trước đây
              // dùng `event.data!` nên event MESSAGE không kèm data sẽ ném lỗi
              // (và bị catch nuốt, nhưng vẫn lãng phí + khó chẩn đoán).
              final rawData = event.data;
              if (rawData == null || rawData.isEmpty) return;
              try {
                final data = jsonDecode(rawData);
                final user = ref.read(authProvider).value;
                final isMe = data['senderId'].toString() == user?.id.toString();

                // BUGFIX (Bug 80): backend trả trường `content` (không phải
                // `message`) → trước đây msgContent luôn rỗng nên tin nhắn SSE
                // hiển thị trống. Đọc cả hai để tương thích.
                final msgContent = data['content'] ?? data['message'] ?? '';
                // BUGFIX (Bug 80): khử trùng lặp theo id — nếu tin nhắn đã có
                // (do optimistic replace hoặc reconnect) thì bỏ qua.
                final incomingId = data['id'];
                if (incomingId != null &&
                    state.messages.any((m) => m.id == incomingId.toString())) {
                  return;
                }

                // Prevent duplicating optimistic updates
                final existingOpt = state.messages
                    .where(
                      (m) =>
                          m.isMe &&
                          m.content == msgContent &&
                          DateTime.now().difference(m.createdAt).inSeconds < 5,
                    )
                    .toList();

                if (!isMe || existingOpt.isEmpty) {
                  state = DirectMessageState(
                    isLoading: false,
                    messages: [
                      ...state.messages,
                      DirectMessage(
                        id: incomingId?.toString(),
                        senderId: data['senderId'].toString(),
                        senderName: data['senderName'] ?? 'Người dùng',
                        content: msgContent,
                        messageType: data['messageType'] ?? 'TEXT',
                        metadata:
                            data['metadata'] != null &&
                                data['metadata'].toString().isNotEmpty
                            ? (data['metadata'] is String
                                  ? jsonDecode(data['metadata'])
                                  : data['metadata'])
                            : null,
                        createdAt: DateTime.now(),
                        isMe: isMe,
                      ),
                    ],
                  );
                }
              } catch (e, st) {
                debugPrint('Error: $e\n$st');
              }
            }
          },
        );
  }

  // BUGFIX (Bug 46): trả về bool để UI biết gửi thành công/thất bại mà báo lỗi
  // (trước đây Future<void> + catch nuốt lỗi → thất bại âm thầm).
  Future<bool> sendMessage(
    String content, {
    String messageType = 'TEXT',
    Map<String, dynamic>? metadata,
  }) async {
    if (content.trim().isEmpty) return false;
    final user = ref.read(authProvider).value;
    if (user == null) return false;

    // Optimistic update
    final msg = DirectMessage(
      senderId: user.id.toString(),
      senderName: user.fullName,
      content: content,
      messageType: messageType,
      metadata: metadata,
      createdAt: DateTime.now(),
      isMe: true,
    );
    state = DirectMessageState(
      isLoading: false,
      messages: [...state.messages, msg],
    );

    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        '/v1/messages/$_roomId',
        data: {
          'senderId': user.id.toString(),
          'senderName': user.fullName,
          'message': content,
          'messageType': messageType,
          if (metadata != null) 'metadata': jsonEncode(metadata),
        },
      );
      return true;
    } catch (e) {
      // BUGFIX (Bug 81): loại bỏ đúng tin nhắn optimistic vừa thêm bằng cách
      // so khớp tham chiếu (identical) thay vì `!=` (dựa trên == vốn bỏ qua
      // createdAt → có thể xoá nhầm tin nhắn trùng nội dung của người khác).
      state = DirectMessageState(
        isLoading: false,
        messages: state.messages.where((m) => !identical(m, msg)).toList(),
      );
      return false;
    }
  }
}
