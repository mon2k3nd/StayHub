import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/custom_sse_client.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/application/auth_notifier.dart';
import 'dart:async' show unawaited;

part 'rental_request_notifier.g.dart';

@Riverpod(keepAlive: true)
class PendingRequests extends _$PendingRequests {
  CustomSseClient? _sseClient;

  @override
  List<Map<String, dynamic>> build() {
    unawaited(
      Future.microtask(() {
        unawaited(_fetchInitialRequests());
        unawaited(_connectSse());
      }),
    );

    ref.onDispose(() {
      _sseClient?.unsubscribeFromSSE();
    });

    return [];
  }

  Future<void> _fetchInitialRequests() async {
    try {
      final user = ref.read(authProvider).value;
      if (user == null) return;

      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.get('/v1/rental-requests/owner/${user.id}');
      if (res['success'] == true) {
        final List data = res['data'] ?? [];
        state = data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('Error fetching initial rental requests: $e');
    }
  }

  Future<void> _connectSse() async {
    final user = ref.read(authProvider).value;
    if (user == null) return;

    final token = await ref.read(secureStorageServiceProvider).getAccessToken();
    // Dùng chung nguồn base URL với ApiClient (trước đây hardcode ngrok URL đã chết).
    final baseUrl = ApiClient.baseUrl;

    _sseClient = CustomSseClient();
    _sseClient!
        .subscribeToSSE(
          method: SSERequestType.get,
          url: '$baseUrl/v1/rental-requests/stream/owner/${user.id}',
          header: {
            "Accept": "text/event-stream",
            "Cache-Control": "no-cache",
            "ngrok-skip-browser-warning": "true",
            if (token != null) "Authorization": "Bearer $token",
          },
        )
        .listen((event) {
          if (event.event == 'rental-request' && event.data != null) {
            try {
              final newData = jsonDecode(event.data!) as Map<String, dynamic>;
              if (newData['status'] == 'PENDING') {
                final existsIndex = state.indexWhere(
                  (req) => req['id'] == newData['id'],
                );
                if (existsIndex >= 0) {
                  final newState = [...state];
                  newState[existsIndex] = newData;
                  state = newState;
                } else {
                  state = [...state, newData];
                }
              } else {
                // Remove from pending list if status is no longer PENDING
                state = state
                    .where((req) => req['id'] != newData['id'])
                    .toList();
              }
            } catch (e) {
              debugPrint('Error parsing SSE data: $e');
            }
          }
        });
  }

  Future<bool> approveRequest(int id) => respondToRequest(id, true);
  Future<bool> rejectRequest(int id) => respondToRequest(id, false);

  Future<bool> respondToRequest(
    int requestId,
    bool approved, {
    int? durationMonths,
    String? terms,
  }) async {
    final oldState = [...state];
    state = state.where((req) => req['id'] != requestId).toList();

    try {
      final apiClient = ref.read(apiClientProvider);
      final data = <String, dynamic>{'approved': approved};
      if (durationMonths != null) data['durationMonths'] = durationMonths;
      if (terms != null && terms.isNotEmpty) data['terms'] = terms;

      final res = await apiClient.post(
        '/v1/rental-requests/$requestId/respond',
        data: data,
      );
      if (res['success'] == true) {
        return true;
      }
      state = oldState;
      return false;
    } catch (e) {
      debugPrint('Error responding to request: $e');
      state = oldState;
      return false;
    }
  }
}
