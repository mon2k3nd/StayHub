import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class CustomSseEvent {
  final String? id;
  final String? event;
  final String? data;

  CustomSseEvent({this.id, this.event, this.data});
}

enum SSERequestType { get, post }

class CustomSseClient {
  http.Client? _client;
  StreamController<CustomSseEvent>? _controller;
  bool _isSubscribed = false;

  /// Đọc token mới nhất từ SecureStorage
  static Future<String?> _getToken() async {
    const storage = FlutterSecureStorage();
    return storage.read(key: 'access_token');
  }

  Stream<CustomSseEvent> subscribeToSSE({
    required SSERequestType method,
    required String url,
    required Map<String, String> header,
  }) {
    // BUGFIX (Bug 136): nếu subscribeToSSE được gọi lại trên cùng instance
    // (ví dụ provider rebuild) thì controller cũ bị thay thế mà KHÔNG đóng →
    // rò rỉ bộ nhớ và vòng `_connect` cũ vẫn chạy song song. Đóng dọn dẹp
    // trước khi tạo mới.
    final oldController = _controller;
    if (oldController != null && !oldController.isClosed) {
      unawaited(oldController.close());
    }
    _isSubscribed = true;
    _controller = StreamController<CustomSseEvent>.broadcast(
      onCancel: unsubscribeFromSSE,
    );

    unawaited(_connect(method.name, url, header));

    return _controller!.stream;
  }

  Future<void> _connect(
    String method,
    String url,
    Map<String, String> header,
  ) async {
    bool hasConnectedOnce = false;
    int retryDelaySeconds = 5; // bắt đầu 5s
    const int maxDelaySeconds = 60; // tối đa 60s

    while (_isSubscribed) {
      try {
        _client = http.Client();
        final request = http.Request(method, Uri.parse(url));

        // Luôn đọc token mới nhất từ SecureStorage trước mỗi lần kết nối
        final token = await _getToken();
        final finalHeaders = Map<String, String>.from(header);
        finalHeaders['ngrok-skip-browser-warning'] = 'true';
        if (token != null && token.isNotEmpty) {
          finalHeaders['Authorization'] = 'Bearer $token';
        }
        request.headers.addAll(finalHeaders);

        final response = await _client!
            .send(request)
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () => throw TimeoutException('SSE connect timeout'),
            );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          if (hasConnectedOnce &&
              _controller != null &&
              !_controller!.isClosed) {
            _controller!.add(
              CustomSseEvent(event: 'RECONNECT_SUCCESS', data: ''),
            );
          }
          hasConnectedOnce = true;
          retryDelaySeconds = 5; // reset về 5s sau khi kết nối thành công

          String? currentId;
          String? currentEvent;
          StringBuffer currentData = StringBuffer();

          await for (final chunk
              in response.stream
                  .transform(utf8.decoder)
                  .transform(const LineSplitter())) {
            if (!_isSubscribed) break;

            if (chunk.isEmpty) {
              if (currentData.isNotEmpty || currentEvent != null) {
                if (_controller != null && !_controller!.isClosed) {
                  _controller!.add(
                    CustomSseEvent(
                      id: currentId,
                      event: currentEvent,
                      data: currentData.toString().trim(),
                    ),
                  );
                }
              }
              currentEvent = null;
              currentData.clear();
              continue;
            }

            if (chunk.startsWith('id:')) {
              currentId = chunk.substring(3).trim();
            } else if (chunk.startsWith('event:')) {
              currentEvent = chunk.substring(6).trim();
            } else if (chunk.startsWith('data:')) {
              // BUGFIX (Bug 135): theo chuẩn SSE chỉ bỏ MỘT khoảng trắng đầu
              // tiên sau `data:`. Trước đây dùng `.trim()` nên xoá sạch mọi
              // khoảng trắng đầu/cuối → làm hỏng nội dung tin nhắn (thụt lề
              // code block, khoảng trắng có nghĩa). Giờ chỉ cắt 1 space.
              var line = chunk.substring(5);
              if (line.startsWith(' ')) line = line.substring(1);
              currentData.writeln(line);
            }
          }
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          // Token hết hạn — ngừng retry, chờ app tự refresh token
          debugPrint('SSE Auth Error (${response.statusCode}), stopping retry');
          break;
        } else {
          debugPrint('SSE Error (Status ${response.statusCode})');
        }
      } on TimeoutException {
        debugPrint('SSE connect timeout: $url');
      } catch (e) {
        if (_isSubscribed) {
          debugPrint('SSE Connection Lost: $url');
        }
      } finally {
        _client?.close();
        _client = null;
      }

      if (_isSubscribed) {
        debugPrint('---RETRYING SSE IN ${retryDelaySeconds}s---');
        await Future.delayed(Duration(seconds: retryDelaySeconds));
        // Exponential backoff: 5 → 10 → 20 → 40 → 60 → 60 → ...
        retryDelaySeconds = (retryDelaySeconds * 2).clamp(5, maxDelaySeconds);
      }
    }
  }

  void unsubscribeFromSSE() {
    _isSubscribed = false;
    _client?.close();
    _client = null;
    if (_controller != null && !_controller!.isClosed) {
      unawaited(_controller!.close());
    }
    _controller = null;
  }
}
