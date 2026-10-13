import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../../core/network/custom_sse_client.dart';
import '../../auth/application/auth_notifier.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/dashboard_refresh.dart';
import '../../dashboard/application/rental_request_notifier.dart';
import '../application/notification_notifier.dart';
import '../../checkout/application/checkout_provider.dart';

part 'unread_notifications_count_provider.g.dart';

@riverpod
class UnreadNotificationsCountNotifier
    extends _$UnreadNotificationsCountNotifier {
  CustomSseClient? _sseClient;

  @override
  FutureOr<int> build() async {
    final user = ref.watch(authProvider).value;
    // Guests see 2 promotional notifications (see notificationsProvider), so the
    // badge must match that list to stay consistent.
    if (user == null) return 2;

    // Lắng nghe SSE Stream hiện tại
    final url = '${ApiClient.baseUrl}/v1/notifications/stream/${user.id}';

    // Nếu chưa có Endpoint riêng cho Notifications,
    // chúng ta vẫn có thể cắm tạm vào stream cũ hoặc đợi Backend mở NotificationSSEStream
    StreamSubscription<dynamic>? sseSubscription;
    try {
      _sseClient = CustomSseClient();
      sseSubscription = _sseClient!
          .subscribeToSSE(
            method: SSERequestType.get,
            url: url,
            header: {
              "Accept": "text/event-stream",
              "Cache-Control": "no-cache",
              "ngrok-skip-browser-warning": "true",
            },
          )
          .listen((event) {
            // The SSE stream can emit after the provider is disposed (logout,
            // navigation). Touching `ref`/`state` on a disposed provider throws,
            // so bail out early.
            if (!ref.mounted) return;
            if (event.data != null && event.data!.isNotEmpty) {
              if (event.data!.contains('KYC_APPROVED_SUCCESS') ||
                  event.data!.contains('KYC_REJECTED')) {
                ref.invalidate(authProvider);
              } else if (event.event == 'unread-count') {
                final newCount = int.tryParse(event.data!) ?? 0;
                final currentCount = state.value ?? 0;

                state = AsyncValue.data(newCount);

                // Chỉ invalidate các provider khác nếu có thông báo mới (số lượng tăng lên)
                if (newCount > currentCount) {
                  refreshOwnerDashboard(ref);
                  ref.invalidate(pendingRequestsProvider);
                  ref.invalidate(notificationProvider);
                  ref.invalidate(ownerCheckoutRequestsProvider);
                }
              }
            }
          });
    } catch (e, st) {
      debugPrint('Error: $e\n$st');
    }

    ref.onDispose(() {
      unawaited(sseSubscription?.cancel());
      _sseClient?.unsubscribeFromSSE();
    });

    final apiClient = ref.read(apiClientProvider);

    try {
      final response = await apiClient.get(
        '/v1/notifications/user/${user.id}/unread-count',
      );
      if (response['success'] == true) {
        final data = response['data'];
        if (data is int) return data;
        if (data is num) return data.toInt();
        if (data is String) return int.tryParse(data) ?? 0;
      }
    } catch (e, st) {
      debugPrint('Error loading unread count: $e\n$st');
    }
    // Fallback to 0 if API fails
    return 0;
  }

  void increment() {
    if (state.hasValue) {
      state = AsyncValue.data(state.value! + 1);
    }
  }

  void decrement() {
    if (state.hasValue && state.value! > 0) {
      state = AsyncValue.data(state.value! - 1);
    }
  }
}
