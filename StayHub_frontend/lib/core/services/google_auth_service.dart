import 'package:google_sign_in/google_sign_in.dart';

/// Service xử lý Google Sign In và trả về Google ID Token.
/// ID Token này sẽ được gửi lên backend để verify và đổi lấy JWT hệ thống.
class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Thực hiện Google Sign In, trả về idToken.
  /// Throw Exception nếu user huỷ hoặc xảy ra lỗi.
  static Future<String> signIn() async {
    try {
      // Đảm bảo sign out account cũ để luôn hiện account picker
      await _googleSignIn.signOut();

      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        throw Exception('Người dùng đã huỷ đăng nhập Google');
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Không lấy được Google ID Token. Vui lòng thử lại.');
      }

      return idToken;
    } catch (e) {
      // Rethrow với message rõ ràng hơn
      if (e.toString().contains('huỷ')) rethrow;
      throw Exception('Đăng nhập Google thất bại: $e');
    }
  }

  /// Đăng xuất khỏi Google account (gọi khi user logout khỏi app)
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
