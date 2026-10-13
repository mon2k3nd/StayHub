import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/custom_sse_client.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/application/auth_notifier.dart';

part 'branch_group_chat_notifier.g.dart';

@riverpod
class BranchGroupChatState extends _$BranchGroupChatState {
  late String _branchId;
  CustomSseClient? _sseClient;
  // BUGFIX (Bug 60): giữ StreamSubscription để huỷ hẳn khi provider dispose.
  // Trước đây chỉ gọi `unsubscribeFromSSE()` nhưng không cancel subscription
  // → listener vẫn có thể bắn sau khi dispose (rò rỉ + ghi state cũ).
  StreamSubscription<dynamic>? _sseSub;
  // BUGFIX (Bug 104): chặn gửi trùng khi người dùng bấm nhanh nhiều lần.
  bool _isSending = false;

  @override
  List<Map<String, dynamic>> build(String branchId) {
    _branchId = branchId;
    unawaited(_fetchHistory());
    _initSSE();
    ref.onDispose(() {
      unawaited(_sseSub?.cancel());
      _sseSub = null;
      _sseClient?.unsubscribeFromSSE();
    });
    return [];
  }

  Future<void> _fetchHistory() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/v1/branches/$_branchId/chat');
      if (response.data is List) {
        // BUGFIX (Bug 105): trước đây ép `e as Map<String, dynamic>` → nếu phần
        // tử không phải Map (null/kiểu khác) sẽ ném TypeError làm hỏng toàn bộ
        // lịch sử. Lọc bỏ phần tử không hợp lệ thay vì crash.
        final fetched = (response.data as List)
            .whereType<Map>()
            .map((e) => _formatMessage(Map<String, dynamic>.from(e)))
            .toList();
        // BUGFIX (Bug 61): trước đây gán đè toàn bộ danh sách bằng dữ liệu
        // vừa tải → tin nhắn realtime (SSE) đến trong lúc request đang bay bị
        // mất. Merge theo id: giữ tin nhắn đã có, thêm tin mới từ server.
        final byId = <Object?, Map<String, dynamic>>{
          for (final m in state) m['id']: m,
          for (final m in fetched) m['id']: m,
        };
        state = byId.values.toList();
      }
    } catch (e, st) {
      debugPrint('Error fetching branch chat history: $e\n$st');
    }
  }

  void _initSSE() {
    _sseClient = CustomSseClient();
    // BUGFIX (Bug 60): lưu subscription để cancel khi dispose.
    _sseSub = _sseClient!
        .subscribeToSSE(
          method: SSERequestType.get,
          url: '${ApiClient.baseUrl}/v1/branches/$_branchId/chat/stream',
          header: {"Accept": "text/event-stream"},
        )
        .listen((event) {
          if (event.event == 'MESSAGE' &&
              event.data != null &&
              event.data!.isNotEmpty) {
            try {
              final data = jsonDecode(event.data!);
              final formattedMsg = _formatMessage(data);

              // BUGFIX (Bug 62): trước đây bỏ qua mọi tin nhắn `isMe == true`
              // → tin nhắn của chính mình gửi từ thiết bị khác không bao giờ
              // xuất hiện. Đồng thời không khử trùng lặp nên tin nhắn có thể
              // bị thêm 2 lần (SSE + optimistic replace). Thêm theo id và chỉ
              // khi chưa tồn tại.
              final id = formattedMsg['id'];
              if (!state.any((m) => m['id'] == id)) {
                state = [...state, formattedMsg];
              }
            } catch (e) {
              // BUGFIX (Bug 84): không nuốt lỗi âm thầm — ghi log để chẩn đoán
              // payload SSE hỏng thay vì bỏ qua hoàn toàn.
              debugPrint('BranchGroupChat SSE parse error: $e');
            }
          }
        });
  }

  Map<String, dynamic> _formatMessage(Map<String, dynamic> msg) {
    final user = ref.read(authProvider).value;
    final currentUserId = user?.id.toString();

    final isSystem = msg['senderRole'] == 'SYSTEM';
    final senderId = msg['senderId']?.toString();
    final isMe = !isSystem && senderId == currentUserId;

    return {
      'id': msg['id'],
      'isSystem': isSystem,
      'isMe': isMe,
      'senderRole': msg['senderRole'],
      'roomNumber': msg['roomNumber'],
      'senderName': msg['senderName'],
      'messageType': msg['messageType'],
      'text': msg['content'],
      // BUGFIX (Bug 103): trước đây ép `msg['createdAt'] as String?` → ném
      // TypeError nếu backend trả kiểu khác (epoch millis/int). Dùng toString.
      'time': _formatTime(msg['createdAt']?.toString()),
    };
  }

  String _formatTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  /// BUGFIX (Bug 58/59): trả về `bool` để UI biết gửi thành công hay thất bại,
  /// từ đó chỉ clear ô nhập khi thành công và hiển thị toast lỗi khi thất bại.
  Future<bool> sendMessage(
    String text, {
    String? filePath,
    String messageType = 'TEXT',
  }) async {
    // BUGFIX (Bug 104): chặn gửi trùng khi đang gửi (double-tap) → tránh tạo
    // nhiều tin nhắn optimistic trùng lặp và gọi API song song.
    if (_isSending) return false;
    final user = ref.read(authProvider).value;
    if (user == null) return false;
    _isSending = true;

    // Optimistic UI update
    final tempId = DateTime.now().millisecondsSinceEpoch;
    final tempMsg = {
      'id': tempId,
      'isSystem': false,
      'isMe': true,
      'senderRole': 'TENANT', // fallback
      'senderName': user.fullName,
      'messageType': messageType,
      'text': filePath ?? text,
      'time': 'Đang gửi...',
    };

    state = [...state, tempMsg];

    try {
      final dio = ref.read(dioProvider);

      final formData = FormData.fromMap({
        'messageType': messageType,
        if (text.isNotEmpty) 'content': text,
        if (filePath != null) 'file': await MultipartFile.fromFile(filePath),
      });

      final response = await dio.post(
        '/v1/branches/$_branchId/chat',
        data: formData,
        options: Options(headers: {'X-User-Id': user.id.toString()}),
      );

      // BUGFIX (Bug 128): tránh cast cứng `as Map<String, dynamic>` — nếu
      // backend trả kiểu khác (null/List) sẽ ném TypeError và rơi vào catch,
      // khiến tin nhắn đã gửi thành công bị revert khỏi UI (mất tin). Kiểm tra
      // kiểu an toàn; nếu không phải Map thì giữ nguyên optimistic message.
      final data = response.data;
      if (data is Map) {
        final formattedSaved = _formatMessage(Map<String, dynamic>.from(data));
        // Replace temp with saved
        state = state
            .map((msg) => msg['id'] == tempId ? formattedSaved : msg)
            .toList();
      }
      return true;
    } catch (e) {
      // Revert optimistic on error
      state = state.where((msg) => msg['id'] != tempId).toList();
      return false;
    } finally {
      _isSending = false;
    }
  }
}
