import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Kết quả đăng nhập Apple: identity token + thông tin người dùng (chỉ có ở
/// lần đăng nhập đầu tiên).
class AppleAuthResult {
  final String identityToken;
  final String? fullName;
  final String? email;

  const AppleAuthResult({
    required this.identityToken,
    this.fullName,
    this.email,
  });
}

/// Service xử lý đăng nhập bằng Apple Sign In (iCloud).
///
/// Chỉ khả dụng trên iOS/macOS. Trên các nền tảng khác sẽ ném exception để UI
/// hiển thị thông báo phù hợp.
class AppleAuthService {
  /// Kiểm tra nền tảng có hỗ trợ Apple Sign In hay không.
  static bool get isSupported {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isMacOS;
  }

  /// Thực hiện Apple Sign In, trả về [AppleAuthResult].
  /// Throw Exception nếu user huỷ hoặc xảy ra lỗi.
  static Future<AppleAuthResult> signIn() async {
    if (!isSupported) {
      throw Exception('Đăng nhập Apple chỉ khả dụng trên iOS/macOS.');
    }

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        throw Exception('Không lấy được Apple Identity Token.');
      }

      // Apple chỉ trả fullName/email ở lần đăng nhập đầu tiên.
      final nameParts = <String>[
        if (credential.givenName != null && credential.givenName!.isNotEmpty)
          credential.givenName!,
        if (credential.familyName != null && credential.familyName!.isNotEmpty)
          credential.familyName!,
      ];
      final fullName = nameParts.isEmpty ? null : nameParts.join(' ');

      return AppleAuthResult(
        identityToken: identityToken,
        fullName: fullName,
        email: credential.email,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw Exception('Người dùng đã huỷ đăng nhập Apple');
      }
      throw Exception('Đăng nhập Apple thất bại: ${e.message}');
    } catch (e) {
      if (e.toString().contains('huỷ')) rethrow;
      throw Exception('Đăng nhập Apple thất bại: $e');
    }
  }
}
