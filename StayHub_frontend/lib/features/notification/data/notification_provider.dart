import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../auth/application/auth_notifier.dart';
import '../../../core/network/api_client.dart';
import 'notification_model.dart';
import '../../../core/providers/core_providers.dart';

final notificationsProvider = FutureProvider<List<NotificationModel>>((
  ref,
) async {
  final user = ref.watch(authProvider).value;
  if (user == null) {
    // Return mock promotional notifications for Guests (Not logged in)
    final now = DateTime.now().toIso8601String();
    return [
      NotificationModel(
        id: -1,
        receiverId: 0,
        title: '🎉 Khuyến mãi từ STAYHUB',
        content:
            'Tặng bạn mã giảm giá 200K khi thuê phòng trong tháng này. Khám phá ngay!',
        type: 'PROMOTION',
        isActionable: true,
        isRead: false,
        createdAt: now,
      ),
      NotificationModel(
        id: -2,
        receiverId: 0,
        title: '🔔 Cập nhật tính năng mới',
        content:
            'Đã có tính năng tìm kiếm phòng trọ bằng AI cực thông minh. Trải nghiệm ngay hôm nay.',
        type: 'SYSTEM',
        isActionable: false,
        isRead: false,
        createdAt: now,
      ),
    ];
  }
  final apiClient = ref.read(apiClientProvider);

  try {
    final response = await apiClient.get('/v1/notifications/user/${user.id}');
    if (response['success'] == true) {
      final data = response['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map(
              (e) => NotificationModel.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
      }
    }
  } catch (e, st) {
    debugPrint('Error fetching notifications: $e\n$st');
  }
  return [];
});

final notificationActionProvider = Provider((ref) {
  return NotificationActionService(ref.read(apiClientProvider));
});

class NotificationActionService {
  final ApiClient _apiClient;
  NotificationActionService(this._apiClient);

  Future<bool> markAsRead(int notificationId) async {
    if (notificationId < 0) return true; // Fake notifications for Guests
    try {
      await _apiClient.post('/v1/notifications/$notificationId/read');
      return true;
    } catch (e, st) {
      debugPrint('Error: $e\n$st');
      return false;
    }
  }

  /// Marks every notification of the given user as read in one request.
  /// Falls back gracefully so the UI never gets stuck in a loading state.
  Future<bool> markAllAsRead(int userId) async {
    if (userId <= 0) return false;
    try {
      await _apiClient.post('/v1/notifications/user/$userId/read-all');
      return true;
    } catch (e, st) {
      debugPrint('Error marking all as read: $e\n$st');
      return false;
    }
  }

  Future<bool> executeAction(
    int notificationId,
    String endpoint,
    String method,
    Map<String, dynamic> payload,
    String status,
  ) async {
    try {
      // 1. Thực thi API nghiệp vụ
      if (method.toUpperCase() == 'POST') {
        await _apiClient.post(endpoint, data: payload);
      } else if (method.toUpperCase() == 'PUT') {
        await _apiClient.put(endpoint, data: payload);
      } else {
        await _apiClient.get(endpoint);
      }

      // 2. Cập nhật trạng thái Action của thẻ Notification
      await _apiClient.put(
        '/v1/notifications/$notificationId/action-status',
        data: {"status": status},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> pushSystemNotification(Map<String, dynamic> data) async {
    try {
      // Bắn API push notification. Backend cần support endpoint này.
      await _apiClient.post('/v1/notifications', data: data);
      return true;
    } catch (e) {
      debugPrint('Error pushing system notification: $e');
      return false;
    }
  }

  Future<bool> deleteNotification(int notificationId) async {
    if (notificationId < 0) return true; // Fake notifications for Guests
    try {
      await _apiClient.delete('/v1/notifications/$notificationId');
      return true;
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return false;
    }
  }
}
