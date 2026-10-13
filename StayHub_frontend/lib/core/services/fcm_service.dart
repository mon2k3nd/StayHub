import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../routing/app_router.dart';
import 'dart:async' show unawaited;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

class FCMService {
  late final FirebaseMessaging? _fcm = Firebase.apps.isEmpty
      ? null
      : FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init(ApiClient apiClient) async {
    if (_initialized || _fcm == null) return;

    try {
      // Yêu cầu quyền thông báo (iOS/Android 13+)
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('User granted permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        return;
      }

      // Khởi tạo Local Notifications (để hiện push khi app ở Foreground)
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings();
      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsDarwin,
          );

      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          _handleNotificationTap(details.payload);
        },
      );

      // Hiển thị thông báo ngay cả khi app đang mở (iOS foreground)
      await _fcm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Cấu hình Channel cho Android
      if (Platform.isAndroid) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'high_importance_channel', // id
          'High Importance Notifications', // title
          description:
              'This channel is used for important notifications.', // description
          importance: Importance.max,
        );

        await _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(channel);
      }

      // Đăng ký nhận token
      String? token = await _fcm.getToken();
      debugPrint("FCM Token: $token");
      if (token != null) {
        unawaited(_sendTokenToServer(apiClient, token));
      }

      // Lắng nghe token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        unawaited(_sendTokenToServer(apiClient, newToken));
      });

      // Lắng nghe tin nhắn khi app đang mở (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Got a message whilst in the foreground!');
        debugPrint('Message data: ${message.data}');

        if (message.notification != null) {
          debugPrint(
            'Message also contained a notification: ${message.notification}',
          );
          _showLocalNotification(message);
        }
      });

      // Lắng nghe background messages
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Xử lý khi user bấm vào notification (khi app đang chạy ngầm)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('onMessageOpenedApp: ${message.data}');
        _handleNotificationTap(message.data.toString());
      });

      // Xử lý khi user bấm vào notification (khi app đã bị tắt hoàn toàn)
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('getInitialMessage: ${initialMessage.data}');
        // Wait a bit for router to be ready
        Future.delayed(const Duration(seconds: 1), () {
          _handleNotificationTap(initialMessage.data.toString());
        });
      }

      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    unawaited(
      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
                'This channel is used for important notifications.',
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      ),
    );
  }

  Future<void> _sendTokenToServer(ApiClient apiClient, String token) async {
    try {
      // Gửi FCM token lên backend để nhận push notification
      await apiClient.dio.put('/v1/auth/fcm-token', data: {'token': token});
      debugPrint(
        'FCM token sent to server successfully: ${token.substring(0, 20)}...',
      );
    } catch (e) {
      debugPrint('Failed to send FCM token to server: $e');
    }
  }

  /// Gọi lại sau khi đăng nhập để đảm bảo FCM token được gắn với JWT của user
  Future<void> resyncToken(ApiClient apiClient) async {
    if (_fcm == null) return;
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _sendTokenToServer(apiClient, token);
      }
    } catch (e) {
      debugPrint('FCM resync failed: $e');
    }
  }

  void _handleNotificationTap(String? payload) {
    debugPrint('Notification tapped with payload: $payload');
    try {
      // Dùng AppRouter để chuyển hướng người dùng đến màn hình thông báo
      // khi họ click vào một push notification từ bên ngoài
      AppRouter.router.push('/notifications');
    } catch (e) {
      debugPrint('Navigation error from push notification: $e');
    }
  }
}
