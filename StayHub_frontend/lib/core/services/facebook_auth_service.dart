import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class FacebookAuthService {
  static Future<String> signIn() async {
    final LoginResult result = await FacebookAuth.instance.login(
      permissions: ['email', 'public_profile'],
    );
    if (result.status == LoginStatus.success) {
      final AccessToken accessToken = result.accessToken!;
      return accessToken.tokenString;
    } else {
      throw Exception('Facebook login failed: ${result.message}');
    }
  }

  static Future<void> signOut() async {
    await FacebookAuth.instance.logOut();
  }
}
