import '../user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String emailOrPhone, String password);
  Future<UserEntity> loginWithBiometric(String refreshToken);
  Future<UserEntity> register(Map<String, dynamic> data);
  Future<String?> sendOtp(String target, String channel);
  Future<String> verifyOtp(String target, String channel, String code);
  Future<void> logout();
  Future<UserEntity?> tryAutoLogin();
  Future<UserEntity> updateProfile(Map<String, dynamic> data);
  Future<UserEntity> uploadAvatar(String imagePath);
  Future<UserEntity> updateSignature(String signature, String? otp);
  Future<UserEntity> loginWithGoogle(String idToken);
  Future<UserEntity> loginWithFacebook(String accessToken);
  Future<UserEntity> loginWithZalo(String accessToken);
  Future<UserEntity> loginWithApple(
    String identityToken, {
    String? fullName,
    String? email,
  });
  Future<UserEntity> loginWithWhatsApp(String phoneToken);
  Future<String> verifyPhoneWithFirebase(
    String phoneNumber,
    String firebaseUid,
  );
  Future<void> setupPassword(String newPassword);
}
