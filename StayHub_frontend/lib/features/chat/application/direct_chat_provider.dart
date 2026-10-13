import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/custom_sse_client.dart';
import '../data/models/direct_chat_message_model.dart';
import '../data/repositories/direct_chat_repository.dart';
import '../../auth/application/auth_notifier.dart';

part 'direct_chat_provider.g.dart';

@riverpod
DirectChatRepository directChatRepository(Ref ref) {
  final dio = ref.watch(dioProvider);
  return DirectChatRepository(dio);
}

@riverpod
class DirectChat extends _$DirectChat {
  CustomSseClient? _sseClient;
  // BUGFIX (Bug 111): lưu StreamSubscription để có thể huỷ khi provider bị
  // dispose. Trước đây chỉ gọi `_sseClient?.unsubscribeFromSSE()` mà không
  // huỷ subscription từ `.listen()` → rò rỉ bộ nhớ và callback vẫn chạy sau
  // khi widget/provider đã bị huỷ (set state trên provider đã dispose).
  StreamSubscription<dynamic>? _sseSub;

  @override
  FutureOr<List<DirectChatMessageModel>> build(int partnerId) async {
    final user = ref.watch(authProvider).value;
    final myUserId = user?.id ?? 1; // Real user ID

    // Cleanup old SSE connection if exists
    ref.onDispose(() {
      _sseSub?.cancel();
      _sseSub = null;
      _sseClient?.unsubscribeFromSSE();
    });

    final repository = ref.watch(directChatRepositoryProvider);
    final history = await repository.getHistory(myUserId, partnerId);

    // Connect to SSE
    _connectSse(myUserId);

    return history;
  }

  void _connectSse(int myUserId) {
    _sseClient = CustomSseClient();

    // BUGFIX (Bug 111): huỷ subscription cũ (nếu có) trước khi tạo mới để
    // tránh nhiều kết nối SSE song song khi build() chạy lại.
    _sseSub?.cancel();

    _sseSub = _sseClient!
        .subscribeToSSE(
          method: SSERequestType.get,
          url: '${ApiClient.baseUrl}/v1/direct-chat/stream',
          header: {'X-User-Id': myUserId.toString()},
        )
        .listen(
          onError: (Object e, StackTrace st) {
            // BUGFIX (Bug 134): thêm onError cho SSE subscription — trước đây
            // không có handler nên lỗi stream (mất mạng, server đóng) trở thành
            // unhandled async error. Giờ chỉ log gọn để app mượt.
            debugPrint('DirectChat SSE error: $e');
          },
          (event) {
            if (event.event == 'MESSAGE' && event.data != null) {
              try {
                final data = jsonDecode(event.data!);
                final msg = DirectChatMessageModel.fromJson(data);

                if (state.hasValue) {
                  final currentMessages = state.value!;
                  // BUGFIX (Bug 77): chỉ loại bỏ tin nhắn optimistic khi nó thực
                  // sự là bản gửi của chính mình (senderId == myUserId) và khớp
                  // nội dung, tránh xoá nhầm tin nhắn của đối phương trùng nội dung.
                  final filtered = currentMessages
                      .where(
                        (m) =>
                            !(m.isOptimistic &&
                                m.senderId == myUserId &&
                                m.content == msg.content &&
                                m.receiverId == msg.receiverId),
                      )
                      .toList();

                  state = AsyncData([...filtered, msg]);
                }
              } catch (e) {
                // BUGFIX (Bug 78): không nuốt lỗi âm thầm — ghi log để chẩn đoán
                // payload SSE hỏng thay vì bỏ qua hoàn toàn.
                debugPrint('DirectChat SSE parse error: $e');
              }
            }
          },
        );
  }

  Future<void> sendMessage(String content) async {
    final user = ref.read(authProvider).value;
    final myUserId = user?.id ?? 1; // Real user ID

    final optimisticMsg = DirectChatMessageModel(
      senderId: myUserId,
      receiverId: partnerId,
      content: content,
      createdAt: DateTime.now(),
      isOptimistic: true,
    );

    // Optimistic Update
    if (state.hasValue) {
      state = AsyncData([...state.value!, optimisticMsg]);
    }

    try {
      final repository = ref.read(directChatRepositoryProvider);
      await repository.sendMessage(myUserId, {
        'content': content,
        'messageType': 'TEXT',
        'receiverId': partnerId,
      });
      // The real message will be pushed via SSE, and the optimistic one will be removed there.
    } catch (e) {
      // Revert optimistic update and show error if needed
      if (state.hasValue) {
        final currentMessages = state.value!;
        // BUGFIX (Bug 112): dùng `identical()` thay vì `==`. DirectChatMessageModel
        // không override `==` nên `m == optimisticMsg` chỉ đúng khi cùng tham
        // chiếu — nhưng sau khi state được gán lại qua `AsyncData([...])`, phần
        // tử vẫn là cùng instance nên cần so sánh danh tính tường minh; đồng
        // thời thêm điều kiện isOptimistic để tránh gắn cờ lỗi nhầm.
        final updated = currentMessages.map((m) {
          if (identical(m, optimisticMsg) ||
              (m.isOptimistic && m.content == content)) {
            return m.copyWith(hasError: true);
          }
          return m;
        }).toList();
        state = AsyncData(updated);
      }
    }
  }
}
