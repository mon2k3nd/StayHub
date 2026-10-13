import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/application/auth_notifier.dart';

part 'notification_notifier.g.dart';

@riverpod
class NotificationNotifier extends _$NotificationNotifier {
  @override
  FutureOr<Map<String, List<dynamic>>> build() async {
    final user = ref.watch(authProvider).value;
    if (user == null) return {'received': [], 'sent': []};

    final client = ref.watch(apiClientProvider);
    List<dynamic> receivedList = [];
    try {
      final receivedRes = await client.get('/v1/notifications/user/${user.id}');
      final data = receivedRes['data'];
      if (data is List) receivedList = data;
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }

    List<dynamic> sentList = [];
    try {
      final sentRes = await client.get(
        '/v1/notifications/user/${user.id}/sent',
      );
      final data = sentRes['data'];
      if (data is List) sentList = data;
    } catch (e) {
      debugPrint('Error loading sent notifications: $e');
    }

    // NOTE: Mock data injection was removed — it polluted real accounts and
    // made the empty state unreachable. The UI now shows a proper empty state.
    return {'received': receivedList, 'sent': sentList};
  }

  Future<void> markRead(int notificationId) async {
    final client = ref.read(apiClientProvider);
    try {
      await client.post('/v1/notifications/$notificationId/read', data: {});
    } catch (_) {}
    if (!ref.mounted) return;
    ref.invalidateSelf();
  }

  Future<void> markAllRead() async {
    final user = ref.read(authProvider).value;
    if (user == null) return;

    final client = ref.read(apiClientProvider);
    try {
      await client.post('/v1/notifications/user/${user.id}/read-all', data: {});
    } catch (_) {}
    if (!ref.mounted) return;
    ref.invalidateSelf();
  }

  Future<void> deleteNotification(int id) async {
    final client = ref.read(apiClientProvider);
    // Remove locally first (optimistic). Guard against non-map entries so a
    // malformed payload can never crash the removal.
    if (state.hasValue) {
      final currentData = state.value!;
      final received = List<dynamic>.from(currentData['received'] ?? []);
      final sent = List<dynamic>.from(currentData['sent'] ?? []);
      received.removeWhere((e) => e is Map && e['id'] == id);
      sent.removeWhere((e) => e is Map && e['id'] == id);
      if (ref.mounted) {
        state = AsyncData({'received': received, 'sent': sent});
      }
    }

    try {
      await client.delete('/v1/notifications/$id');
    } catch (_) {}
  }

  Future<bool> executeAction(
    int notificationId,
    String endpoint,
    String method,
    Map<String, dynamic> payload,
    String status,
  ) async {
    final client = ref.read(apiClientProvider);
    try {
      if (method.toUpperCase() == 'POST') {
        await client.post(endpoint, data: payload);
      } else if (method.toUpperCase() == 'PUT') {
        await client.put(endpoint, data: payload);
      } else {
        await client.get(endpoint);
      }
      await client.put(
        '/v1/notifications/$notificationId/action-status',
        data: {"status": status},
      );
      if (ref.mounted) ref.invalidateSelf();
      return true;
    } catch (e, st) {
      debugPrint('Error: $e\n$st');
      return false;
    }
  }
}
