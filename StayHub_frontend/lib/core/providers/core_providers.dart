import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../security/secure_storage_service.dart';
import '../services/fcm_service.dart';

import 'session_expired_notifier.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return SecureStorageService(storage);
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    onSessionExpired: () {
      ref.read(sessionExpiredProvider.notifier).expire();
    },
  );
});

final dioProvider = Provider<Dio>((ref) {
  return ref.watch(apiClientProvider).dio;
});

final fcmServiceProvider = Provider<FCMService>((ref) {
  return FCMService();
});
