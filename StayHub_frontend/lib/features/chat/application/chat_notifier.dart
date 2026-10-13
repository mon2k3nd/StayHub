import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/chat_models.dart';
import '../data/repositories/chat_repository.dart';

part 'chat_notifier.g.dart';

@riverpod
ChatRepository chatRepository(Ref ref) {
  return ChatRepository();
}

@riverpod
class ChatNotifier extends _$ChatNotifier {
  StreamSubscription<String>? _streamSubscription;
  String _currentConversationId =
      '550e8400-e29b-41d4-a716-446655440000'; // Default or generated UUID
  // BUGFIX (Bug 97): cờ chống gửi trùng — trước đây bấm gửi nhanh nhiều lần
  // tạo nhiều stream đồng thời cùng ghi vào một AI placeholder → nội dung trộn
  // lẫn và trạng thái sai.
  bool _isSending = false;

  @override
  List<ChatMessage> build() {
    // BUGFIX (Bug 98): huỷ subscription khi provider dispose. Trước đây chỉ
    // huỷ bên trong sendMessage nên nếu provider bị dispose giữa chừng (rời
    // màn hình) listener vẫn bắn vào state đã chết → rò rỉ.
    ref.onDispose(() {
      unawaited(_streamSubscription?.cancel());
      _streamSubscription = null;
    });
    return [];
  }

  void setConversationId(String id) {
    _currentConversationId = id;
    // Potentially load history here
  }

  Future<void> sendMessage(String prompt) async {
    if (prompt.trim().isEmpty) return;
    // BUGFIX (Bug 97): chặn gửi chồng khi đang stream câu trả lời trước.
    if (_isSending) return;
    _isSending = true;

    final repo = ref.read(chatRepositoryProvider);

    // 1. Optimistic Update: Add User Message
    final userMsg = ChatMessage(
      conversationId: _currentConversationId,
      senderType: 'USER',
      content: prompt,
      status: 'SUCCESS',
      createdAt: DateTime.now(),
    );

    // 2. Add Placeholder AI Message
    final aiPlaceholder = ChatMessage(
      conversationId: _currentConversationId,
      senderType: 'AI',
      content: '', // Start empty
      status: 'LOADING',
      createdAt: DateTime.now(),
    );

    state = [...state, userMsg, aiPlaceholder];

    // unawaited(3. Listen to SSE Stream)
    unawaited(_streamSubscription?.cancel());

    String accumulatedText = '';

    // BUGFIX (Bug 129): bọc try/catch — nếu `streamChat` ném exception đồng bộ
    // (ví dụ lỗi tạo URI/SSE client) thì `_isSending` sẽ bị kẹt ở true mãi mãi,
    // khoá luôn tính năng gửi. Bắt lỗi, mở khoá và đánh dấu tin nhắn AI thất bại.
    try {
      _streamSubscription = repo
          .streamChat(_currentConversationId, prompt)
          .listen(
            (chunk) {
              accumulatedText += chunk;

              // Update the last message (which is the AI placeholder)
              final List<ChatMessage> newState = List.from(state);
              final lastIndex = newState.length - 1;

              if (newState[lastIndex].senderType == 'AI') {
                newState[lastIndex] = newState[lastIndex].copyWith(
                  content: accumulatedText,
                  status: 'LOADING',
                );
                state = newState;
              }
            },
            onError: (error) {
              // BUGFIX (Bug 97): mở khoá gửi khi stream lỗi để người dùng thử lại.
              _isSending = false;
              // BUGFIX (Bug 76): kiểm tra biên trước khi truy cập phần tử cuối,
              // tránh RangeError khi state rỗng (ví dụ bị reset giữa chừng).
              final List<ChatMessage> newState = List.from(state);
              if (newState.isEmpty) return;
              final lastIndex = newState.length - 1;
              if (newState[lastIndex].senderType == 'AI') {
                newState[lastIndex] = newState[lastIndex].copyWith(
                  content: accumulatedText.isEmpty
                      ? 'Error: Failed to fetch response.'
                      : accumulatedText,
                  status: 'FAILED',
                );
                state = newState;
              }
            },
            onDone: () {
              // BUGFIX (Bug 97): mở khoá gửi khi stream kết thúc.
              _isSending = false;
              // BUGFIX (Bug 76): kiểm tra biên trước khi truy cập phần tử cuối.
              final List<ChatMessage> newState = List.from(state);
              if (newState.isEmpty) return;
              final lastIndex = newState.length - 1;
              if (newState[lastIndex].senderType == 'AI') {
                newState[lastIndex] = newState[lastIndex].copyWith(
                  status: 'SUCCESS',
                );
                state = newState;
              }
            },
          );
    } catch (e) {
      _isSending = false;
      final List<ChatMessage> newState = List.from(state);
      if (newState.isNotEmpty &&
          newState[newState.length - 1].senderType == 'AI') {
        newState[newState.length - 1] = newState[newState.length - 1].copyWith(
          content: 'Error: Failed to fetch response.',
          status: 'FAILED',
        );
        state = newState;
      }
    }
  }
}
