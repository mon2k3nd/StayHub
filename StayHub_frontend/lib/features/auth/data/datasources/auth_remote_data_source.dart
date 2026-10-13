import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class AuthRemoteDataSource {
  final ApiClient _apiClient;

  const AuthRemoteDataSource(this._apiClient);

  Future<Map<String, dynamic>> login(
    String emailOrPhone,
    String password,
  ) async {
    return _apiClient.post(
      '/v1/auth/login',
      data: {'emailOrPhone': emailOrPhone, 'password': password},
    );
  }

  Future<Map<String, dynamic>> loginWithRefreshToken(
    String refreshToken,
  ) async {
    return _apiClient.post(
      '/v1/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    return _apiClient.post('/v1/auth/register', data: data);
  }

  Future<Map<String, dynamic>> sendOtp(String target, String channel) async {
    return _apiClient.post(
      '/v1/auth/send-otp',
      data: {'target': target, 'channel': channel, 'type': 'register'},
    );
  }

  Future<Map<String, dynamic>> verifyOtp(
    String target,
    String channel,
    String code,
  ) async {
    return _apiClient.post(
      '/v1/auth/verify-otp',
      data: {
        'target': target,
        'channel': channel,
        'code': code,
        'type': 'register',
      },
    );
  }

  Future<Map<String, dynamic>> verifyPhoneWithFirebase(
    String phoneNumber,
    String firebaseUid,
  ) async {
    return _apiClient.post(
      '/v1/auth/phone-verify',
      data: {'phoneNumber': phoneNumber, 'firebaseUid': firebaseUid},
    );
  }

  Future<Map<String, dynamic>> getProfile(int userId) async {
    return _apiClient.get('/v1/users/$userId/profile');
  }

  Future<Map<String, dynamic>> updateProfile(
    int userId,
    Map<String, dynamic> data,
  ) async {
    return _apiClient.put('/v1/users/$userId/profile', data: data);
  }

  Future<Map<String, dynamic>> setupPassword(String newPassword) async {
    return _apiClient.put(
      '/v1/users/me/password',
      data: {'newPassword': newPassword},
    );
  }

  Future<Map<String, dynamic>> uploadAvatar(
    int userId,
    String imagePath,
  ) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(imagePath),
    });
    return _apiClient.uploadFile('/v1/users/$userId/avatar', formData);
  }

  Future<Map<String, dynamic>> updateSignature(
    int userId,
    String signature,
    String? otp,
  ) async {
    return _apiClient.put(
      '/v1/users/$userId/signature',
      data: {
        'signature': signature,
        if (otp != null && otp.isNotEmpty) 'otp': otp,
      },
    );
  }

  Future<Map<String, dynamic>> getSignatureHistory(int userId) async {
    return _apiClient.get('/v1/users/$userId/signature-history');
  }

  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    return _apiClient.post('/v1/auth/google', data: {'idToken': idToken});
  }

  Future<Map<String, dynamic>> loginWithFacebook(String accessToken) async {
    return _apiClient.post(
      '/v1/auth/facebook',
      data: {'accessToken': accessToken},
    );
  }

  Future<Map<String, dynamic>> loginWithZalo(String accessToken) async {
    return _apiClient.post('/v1/auth/zalo', data: {'accessToken': accessToken});
  }

  Future<Map<String, dynamic>> loginWithApple(
    String identityToken, {
    String? fullName,
    String? email,
  }) async {
    return _apiClient.post(
      '/v1/auth/apple',
      data: {
        'identityToken': identityToken,
        if (fullName != null && fullName.isNotEmpty) 'fullName': fullName,
        if (email != null && email.isNotEmpty) 'email': email,
      },
    );
  }

  Future<Map<String, dynamic>> loginWithWhatsApp(String phoneToken) async {
    return _apiClient.post(
      '/v1/auth/whatsapp',
      data: {'phoneToken': phoneToken},
    );
  }
}
