import 'dart:async';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/custom_sse_client.dart';

class ChatRepository {
  final String baseUrl;
  CustomSseClient? _sseClient;

  // BUGFIX (Bug 88): giữ tham chiếu subscription để huỷ trong cancelStream,
  // tránh rò rỉ và callback bắn sau khi widget đã bị huỷ.
  StreamSubscription<dynamic>? _sseSub;

  // Dùng chung nguồn base URL với ApiClient (trước đây hardcode ngrok URL đã chết).
  ChatRepository({String? baseUrl})
    : baseUrl = baseUrl ?? '${ApiClient.baseUrl}/api/v1';

  /// Connects to the Spring Boot SSE endpoint and yields text chunks
  Stream<String> streamChat(String conversationId, String prompt) {
    final streamController = StreamController<String>();

    final uri =
        '$baseUrl/chat/stream?conversationId=$conversationId&prompt=${Uri.encodeComponent(prompt)}';

    // Subscribe to SSE
    _sseClient = CustomSseClient();
    _sseSub = _sseClient!
        .subscribeToSSE(
          method: SSERequestType.get,
          url: uri,
          header: {
            'Accept': 'text/event-stream',
            'ngrok-skip-browser-warning': 'true',
          },
        )
        .listen(
          (event) {
            if (event.data != null && event.data!.isNotEmpty) {
              streamController.add(event.data!);
            }
          },
          onError: (error) {
            // BUGFIX (Bug 109): trước đây chỉ addError mà không đóng
            // StreamController → consumer chờ mãi (stream không bao giờ kết
            // thúc) và rò rỉ controller. Đóng stream sau khi báo lỗi.
            if (!streamController.isClosed) {
              streamController.addError(error);
              unawaited(streamController.close());
            }
            _sseClient?.unsubscribeFromSSE();
          },
          onDone: () {
            if (!streamController.isClosed) {
              unawaited(streamController.close());
            }
            _sseClient?.unsubscribeFromSSE();
          },
        );

    return streamController.stream;
  }

  void cancelStream() {
    // BUGFIX (Bug 88): huỷ subscription trước khi unsubscribe SSE.
    unawaited(_sseSub?.cancel());
    _sseSub = null;
    _sseClient?.unsubscribeFromSSE();
  }
}
