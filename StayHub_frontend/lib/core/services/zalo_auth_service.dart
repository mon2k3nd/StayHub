import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Service xử lý đăng nhập bằng Zalo.
///
/// Zalo không có SDK Flutter chính thức cho luồng OAuth native đơn giản, nên
/// ta dùng Zalo OAuth 2.0 (PKCE) qua WebView/URL launcher để lấy Access Token,
/// sau đó gửi token lên backend để verify và đổi lấy JWT hệ thống.
///
/// LƯU Ý: Cần cấu hình `ZALO_APP_ID` trong Zalo Developer Console và thêm
/// redirect URI tương ứng. Nếu chưa cấu hình, service sẽ ném exception rõ ràng.
class ZaloAuthService {
  /// App ID lấy từ Zalo Developer Console.
  /// Cần thay bằng App ID thật khi production.
  static const String appId = String.fromEnvironment(
    'ZALO_APP_ID',
    defaultValue: '',
  );

  /// Endpoint uỷ quyền Zalo.
  static const String _authEndpoint = 'https://oauth.zaloapp.com/v4/permission';

  /// Endpoint đổi code lấy access token.
  static const String _tokenEndpoint =
      'https://oauth.zaloapp.com/v4/access_token';

  /// Tạo URL uỷ quyền để mở trong WebView/browser.
  static String buildAuthUrl(String redirectUri, String codeChallenge) {
    final params = {
      'app_id': appId,
      'redirect_uri': redirectUri,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    };
    final query = params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
    return '$_authEndpoint?$query';
  }

  /// Đổi authorization code lấy Zalo Access Token.
  ///
  /// [code] là mã uỷ quyền nhận được từ redirect URI.
  /// [codeVerifier] là PKCE code verifier đã dùng để tạo code_challenge.
  static Future<String> exchangeCodeForToken({
    required String code,
    required String codeVerifier,
  }) async {
    if (appId.isEmpty) {
      throw Exception(
        'Chưa cấu hình ZALO_APP_ID. Vui lòng thiết lập trước khi đăng nhập Zalo.',
      );
    }

    final response = await http.post(
      Uri.parse(_tokenEndpoint),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'app_id': appId,
        'grant_type': 'authorization_code',
        'code': code,
        'code_verifier': codeVerifier,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Đổi Zalo token thất bại: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final accessToken = data['access_token'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Không lấy được Zalo Access Token.');
    }
    return accessToken;
  }

  /// Redirect URI mặc định (deep link quay về app).
  static const String redirectUri = 'stayhub://zalo-auth';

  /// Bộ đệm nhận authorization code từ deep link.
  static final StreamController<String> _codeController =
      StreamController<String>.broadcast();

  /// Được gọi từ deep-link handler khi Zalo redirect về app.
  static void handleRedirect(Uri uri) {
    if (uri.scheme == 'stayhub' && uri.host == 'zalo-auth') {
      final code = uri.queryParameters['code'];
      final error = uri.queryParameters['error'];
      if (code != null && code.isNotEmpty) {
        _codeController.add(code);
      } else if (error != null) {
        _codeController.addError(Exception('Zalo OAuth lỗi: $error'));
      }
    }
  }

  /// Sinh PKCE code verifier + challenge (S256).
  static Map<String, String> _generatePkce() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(32, (_) => rnd.nextInt(256));
    final verifier = base64Url
        .encode(bytes)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
    final challenge = base64Url
        .encode(sha256.convert(utf8.encode(verifier)).bytes)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
    return {'verifier': verifier, 'challenge': challenge};
  }

  /// Thực hiện toàn bộ luồng đăng nhập Zalo OAuth 2.0 (PKCE).
  ///
  /// Mở trình duyệt tới trang uỷ quyền Zalo, chờ deep link `stayhub://zalo-auth`
  /// trả về authorization code, rồi đổi code lấy Access Token.
  static Future<String> signIn({
    Duration timeout = const Duration(minutes: 3),
  }) async {
    if (appId.isEmpty) {
      throw Exception(
        'Chưa cấu hình ZALO_APP_ID. Vui lòng thiết lập trước khi đăng nhập Zalo.',
      );
    }

    final pkce = _generatePkce();
    final authUrl = buildAuthUrl(redirectUri, pkce['challenge']!);

    final completer = Completer<String>();
    late StreamSubscription<String> sub;
    sub = _codeController.stream.listen(
      (code) {
        if (!completer.isCompleted) completer.complete(code);
      },
      onError: (Object e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
    );

    try {
      final launched = await launchUrl(
        Uri.parse(authUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw Exception('Không mở được trang đăng nhập Zalo.');
      }

      final code = await completer.future.timeout(
        timeout,
        onTimeout: () =>
            throw TimeoutException('Hết thời gian đăng nhập Zalo.'),
      );

      return await exchangeCodeForToken(
        code: code,
        codeVerifier: pkce['verifier']!,
      );
    } finally {
      await sub.cancel();
    }
  }

  /// Trả về access token đã có sẵn (dùng khi token được lấy từ luồng khác,
  /// ví dụ Zalo Mini App hoặc deep link).
  static Future<String> signInWithToken(String accessToken) async {
    if (accessToken.isEmpty) {
      throw Exception('Zalo Access Token rỗng.');
    }
    return accessToken;
  }

  /// Đăng xuất khỏi Zalo (chỉ xoá trạng thái cục bộ; Zalo không có API logout
  /// cho luồng OAuth web).
  static Future<void> signOut() async {
    if (kDebugMode) {
      debugPrint('ZaloAuthService.signOut() — cleared local state');
    }
  }
}
