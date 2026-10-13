import 'package:firebase_auth/firebase_auth.dart';

/// Service đóng gói Firebase Phone Auth để gửi và xác thực OTP qua SMS.
/// Sử dụng miễn phí 10,000 SMS/tháng qua Firebase.
class FirebasePhoneAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lưu verificationId và resendToken hiện tại
  static String? _currentVerificationId;
  static int? _resendToken;

  /// Gửi SMS OTP đến số điện thoại.
  /// [phoneNumber] có thể là: 0912345678, +84912345678
  /// [onCodeSent] được gọi khi OTP đã gửi thành công
  /// [onError] được gọi khi có lỗi
  static Future<void> sendSmsOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  }) async {
    final formatted = _formatVietnamesePhone(phoneNumber);

    await _auth.verifyPhoneNumber(
      phoneNumber: formatted,
      forceResendingToken: _resendToken,
      verificationCompleted: (PhoneAuthCredential credential) {
        // Android có thể tự detect OTP (SMS auto-fill)
        // Không dùng trong flow nhập tay
      },
      verificationFailed: (FirebaseAuthException e) {
        String message;
        switch (e.code) {
          case 'invalid-phone-number':
            message = 'Số điện thoại không hợp lệ. Vui lòng kiểm tra lại.';
            break;
          case 'too-many-requests':
            message = 'Quá nhiều yêu cầu. Vui lòng thử lại sau vài phút.';
            break;
          case 'quota-exceeded':
            message = 'Hạn mức SMS đã vượt quá. Vui lòng liên hệ hỗ trợ.';
            break;
          case 'operation-not-allowed':
            message =
                '(Lỗi V2) Xác thực SĐT chưa được bật. Vui lòng liên hệ hỗ trợ.';
            break;
          default:
            message = 'Lỗi gửi OTP: ${e.message ?? e.code}';
        }
        onError(message);
      },
      codeSent: (String verificationId, int? resendToken) {
        _currentVerificationId = verificationId;
        _resendToken = resendToken;
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _currentVerificationId = verificationId;
      },
      timeout: const Duration(seconds: 60),
    );
  }

  /// Xác thực mã OTP người dùng nhập.
  /// Trả về [User] Firebase nếu thành công.
  /// Throws [Exception] nếu OTP sai hoặc hết hạn.
  static Future<User> verifySmsOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    try {
      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) throw Exception('Xác thực thất bại. Vui lòng thử lại.');
      return user;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-verification-code':
          throw Exception('Mã OTP không đúng. Vui lòng kiểm tra lại.');
        case 'session-expired':
          throw Exception('Phiên xác thực đã hết hạn. Vui lòng gửi lại mã.');
        case 'invalid-verification-id':
          throw Exception('Phiên không hợp lệ. Vui lòng gửi lại mã.');
        default:
          throw Exception('Lỗi xác thực: ${e.message ?? e.code}');
      }
    }
  }

  /// Gửi lại OTP (tái sử dụng resendToken để tránh bị Firebase chặn)
  static Future<void> resendSmsOtp({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
  }) async {
    await sendSmsOtp(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onError: onError,
    );
  }

  /// Đăng xuất khỏi Firebase (Firebase chỉ dùng để verify SĐT, không giữ session)
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}
  }

  /// Chuẩn hóa số điện thoại VN thành E.164
  /// 0912345678 → +84912345678
  static String _formatVietnamesePhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('+84')) return cleaned;
    if (cleaned.startsWith('84')) return '+$cleaned';
    if (cleaned.startsWith('0')) return '+84${cleaned.substring(1)}';
    return '+84$cleaned';
  }

  static String? get currentVerificationId => _currentVerificationId;
}
