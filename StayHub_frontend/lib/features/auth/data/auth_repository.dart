import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/providers/core_providers.dart' hide dioProvider;
import '../../../core/security/secure_storage_service.dart';

final authRepositoryProvider = FutureProvider<AuthRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return AuthRepository(dio, secureStorage);
});

class AuthRepository {
  final Dio _dio;
  final SecureStorageService _secureStorage;

  AuthRepository(this._dio, this._secureStorage);

  Future<bool> login(String username, String password) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'username': username, 'password': password},
      );

      if (response.statusCode == 200 && response.data != null) {
        final accessToken = response.data['access_token'];
        final refreshToken = response.data['refresh_token'];

        if (accessToken != null) {
          await _secureStorage.saveToken(accessToken);
        }
        if (refreshToken != null) {
          await _secureStorage.saveRefreshToken(refreshToken);
        }
        return true;
      }
      return false;
    } on DioException catch (e) {
      // Handle login error (show message from backend or default message)
      throw Exception(e.response?.data['message'] ?? 'Đăng nhập thất bại');
    } catch (e) {
      throw Exception('Lỗi hệ thống: $e');
    }
  }

  Future<void> logout() async {
    try {
      // Có thể gọi API logout để revoke token ở backend nếu cần
      // await _dio.post('/auth/logout');
    } finally {
      await _secureStorage.clearAll();
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _secureStorage.getToken();
    return token != null && token.isNotEmpty;
  }
}
