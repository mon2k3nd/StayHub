import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import '../../../core/network/custom_sse_client.dart';
import '../../../core/network/api_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/core_providers.dart';
import '../../tenant/application/tenant_dashboard_notifier.dart';
import '../../../core/providers/dashboard_refresh.dart';

part 'dispute_chat_provider.g.dart';

@riverpod
class DisputeChatNotifier extends _$DisputeChatNotifier {
  late int _billId;
  CustomSseClient? _sseClient;

  @override
  List<Map<String, dynamic>> build(int billId) {
    _billId = billId;
    unawaited(_fetchMessages());
    _initSSE();
    ref.onDispose(() {
      _sseClient?.unsubscribeFromSSE();
    });
    return [];
  }

  Future<void> _fetchMessages() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/v1/disputes/$_billId/messages');
      if (response.statusCode == 200) {
        // BUGFIX (data): tránh `as List`/`as Map` ném TypeError khi body không
        // phải List hoặc phần tử không phải Map — lọc an toàn bằng whereType.
        final raw = response.data;
        state = raw is List
            ? raw
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList()
            : <Map<String, dynamic>>[];
      }
    } catch (e) {
      debugPrint('Fetch messages error: $e');
    }
  }

  void _initSSE() {
    _sseClient = CustomSseClient();
    _sseClient!
        .subscribeToSSE(
          method: SSERequestType.get,
          url: '${ApiClient.baseUrl}/v1/disputes/stream/$_billId',
          header: {"Accept": "text/event-stream"},
        )
        .listen((event) {
          if (event.event == 'MESSAGE') {
            final data = jsonDecode(event.data!);
            final msgText = data['message'] ?? '';
            final senderId = data['senderId']?.toString() ?? '';

            // Prevent duplicating optimistic updates
            final existingOpt = state
                .where(
                  (m) =>
                      m['senderId']?.toString() == senderId &&
                      m['message'] == msgText,
                )
                .toList();

            if (existingOpt.isEmpty) {
              state = [...state, data];
            }
          } else if (event.event == 'BILL_UPDATED') {
            final data = jsonDecode(event.data!);
            state = [
              ...state,
              {
                'type': 'system',
                'message': 'Hóa đơn đã được cập nhật lại.',
                'data': data,
                'event': 'BILL_UPDATED',
              },
            ];
          } else if (event.event == 'PAYMENT_SUCCESS') {
            state = [
              ...state,
              {
                'type': 'system',
                'message': 'Thanh toán thành công! Hợp đồng đã đóng.',
                'event': 'PAYMENT_SUCCESS',
              },
            ];

            try {
              ref.invalidate(unpaidBillsProvider);
              ref.invalidate(tenantDashboardProvider);
              refreshOwnerDashboard(ref);
            } catch (e) {
              debugPrint('Failed to invalidate providers after payment: $e');
            }
          }
        });
  }

  Future<void> sendMessage(String senderId, String message) async {
    // Optimistic update
    final newMessage = {
      'senderId': senderId,
      'message': message,
      'createdAt': DateTime.now().toIso8601String(),
    };
    state = [...state, newMessage];

    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        '/v1/disputes/$_billId/messages',
        data: {'senderId': senderId, 'message': message},
      );
    } catch (e) {
      debugPrint('Send message error: $e');
      // Revert optimistic update if needed
      state = state.where((m) => m != newMessage).toList();
    }
  }

  Future<void> updateBill(Map<String, dynamic> payload) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/v1/disputes/$_billId/update-bill', data: payload);
    } catch (e) {
      debugPrint('Update bill error: $e');
    }
  }
}
