import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  const SecureStorageService(this._storage);

  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserRole = 'user_role';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserPhone = 'user_phone';
  static const String _keyPlanType = 'plan_type';
  static const String _keyCccdNumber = 'cccd_number';
  static const String _keyHometown = 'hometown';
  static const String _keyOccupation = 'occupation';
  static const String _keyGender = 'gender';
  static const String _keyStatus = 'status';
  static const String _keyOwnerStatus = 'owner_status';
  static const String _keyKycStatus = 'kyc_status';
  static const String _keyLastPhone = 'last_login_phone';
  static const String _keyLastName = 'last_login_name';
  static const String _keyLastAvatar = 'last_login_avatar';
  static const String _keyAvatarUrl = 'avatar_url';
  static const String _keyIsBiometricEnabled = 'is_biometric_enabled';
  static const String _keyQuickPinHash = 'quick_pin_hash';
  static const String _keyQuickPinSalt = 'quick_pin_salt';

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: _keyIsBiometricEnabled,
      value: enabled.toString(),
    );
  }

  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _keyIsBiometricEnabled);
    return val == 'true';
  }

  // --- Quick PIN 6 số với SHA-256 + Salt ---
  Future<void> saveQuickPin(String pin) async {
    final salt = DateTime.now().microsecondsSinceEpoch.toString();
    final bytes = utf8.encode('$salt:$pin:stayhub_pin_pepper_2026');
    final hash = sha256.convert(bytes).toString();
    await _storage.write(key: _keyQuickPinHash, value: hash);
    await _storage.write(key: _keyQuickPinSalt, value: salt);
  }

  Future<bool> verifyQuickPin(String pin) async {
    final savedHash = await _storage.read(key: _keyQuickPinHash);
    final salt = await _storage.read(key: _keyQuickPinSalt);
    if (savedHash == null || salt == null) return false;
    final bytes = utf8.encode('$salt:$pin:stayhub_pin_pepper_2026');
    final hash = sha256.convert(bytes).toString();
    return hash == savedHash;
  }

  Future<bool> hasQuickPin() async {
    final savedHash = await _storage.read(key: _keyQuickPinHash);
    return savedHash != null && savedHash.isNotEmpty;
  }

  Future<void> clearQuickPin() async {
    await _storage.delete(key: _keyQuickPinHash);
    await _storage.delete(key: _keyQuickPinSalt);
  }

  Future<void> saveLastUser(
    String phone, {
    String? name,
    String? avatar,
  }) async {
    await _storage.write(key: _keyLastPhone, value: phone);
    if (name != null) await _storage.write(key: _keyLastName, value: name);
    if (avatar != null) {
      await _storage.write(key: _keyLastAvatar, value: avatar);
    }
  }

  Future<Map<String, String?>> getLastUser() async {
    final phone = await _storage.read(key: _keyLastPhone);
    final name = await _storage.read(key: _keyLastName);
    final avatar = await _storage.read(key: _keyLastAvatar);
    return {'phone': phone, 'name': name, 'avatar': avatar};
  }

  Future<void> clearLastUser() async {
    await _storage.delete(key: _keyLastPhone);
    await _storage.delete(key: _keyLastName);
    await _storage.delete(key: _keyLastAvatar);
    await _storage.delete(key: _keyIsBiometricEnabled);
    await _storage.delete(key: _keyRefreshToken); // Xóa token khi đổi tài khoản
    await clearQuickPin();
  }

  Future<void> saveToken(String accessToken, {String? refreshToken}) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
    }
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _keyAccessToken);
  }

  /// Alias kept for backward compatibility with legacy call sites.
  Future<String?> getToken() => getAccessToken();

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: _keyRefreshToken);
  }

  /// Alias kept for backward compatibility with legacy call sites.
  Future<void> clearAll() => clearSession();

  Future<void> saveUserSession({
    required String id,
    required String role,
    required String name,
    required String phone,
    String? email,
    String? planType,
    String? cccdNumber,
    String? hometown,
    String? occupation,
    String? gender,
    String? status,
    String? ownerStatus,
    String? kycStatus,
    String? avatarUrl,
  }) async {
    final futures = <Future>[
      _storage.write(key: _keyUserId, value: id),
      _storage.write(key: _keyUserRole, value: role),
      _storage.write(key: _keyUserName, value: name),
      _storage.write(key: _keyUserPhone, value: phone),
    ];
    if (email != null) {
      futures.add(_storage.write(key: _keyUserEmail, value: email));
    }
    if (planType != null) {
      futures.add(_storage.write(key: _keyPlanType, value: planType));
    }
    if (cccdNumber != null) {
      futures.add(_storage.write(key: _keyCccdNumber, value: cccdNumber));
    }
    if (hometown != null) {
      futures.add(_storage.write(key: _keyHometown, value: hometown));
    }
    if (occupation != null) {
      futures.add(_storage.write(key: _keyOccupation, value: occupation));
    }
    if (gender != null) {
      futures.add(_storage.write(key: _keyGender, value: gender));
    }
    if (status != null) {
      futures.add(_storage.write(key: _keyStatus, value: status));
    }
    if (ownerStatus != null) {
      futures.add(_storage.write(key: _keyOwnerStatus, value: ownerStatus));
    }
    if (kycStatus != null) {
      futures.add(_storage.write(key: _keyKycStatus, value: kycStatus));
    }
    if (avatarUrl != null) {
      futures.add(_storage.write(key: _keyAvatarUrl, value: avatarUrl));
    }

    await Future.wait(futures);
  }

  Future<Map<String, String?>> getUserSession() async {
    final futures = <Future<String?>>[
      _storage.read(key: _keyUserId),
      _storage.read(key: _keyUserRole),
      _storage.read(key: _keyUserName),
      _storage.read(key: _keyUserPhone),
      _storage.read(key: _keyUserEmail),
      _storage.read(key: _keyPlanType),
      _storage.read(key: _keyCccdNumber),
      _storage.read(key: _keyHometown),
      _storage.read(key: _keyOccupation),
      _storage.read(key: _keyGender),
      _storage.read(key: _keyStatus),
      _storage.read(key: _keyOwnerStatus),
      _storage.read(key: _keyKycStatus),
      _storage.read(key: _keyAvatarUrl),
    ];
    final results = await Future.wait(futures);

    final id = results[0];
    final role = results[1];
    final name = results[2];
    final phone = results[3];
    final email = results[4];
    final plan = results[5];
    final cccd = results[6];
    final hometown = results[7];
    final occupation = results[8];
    final gender = results[9];
    final status = results[10];
    final ownerStatus = results[11];
    final kycStatus = results[12];
    final avatarUrl = results[13];

    return {
      'id': id,
      'role': role,
      'name': name,
      'phone': phone,
      'email': email,
      'plan_type': plan,
      'cccd_number': cccd,
      'hometown': hometown,
      'occupation': occupation,
      'gender': gender,
      'status': status,
      'ownerStatus': ownerStatus,
      'kycStatus': kycStatus,
      'avatarUrl': avatarUrl,
    };
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _keyAccessToken);

    final biometricEnabled = await isBiometricEnabled();
    if (!biometricEnabled) {
      await _storage.delete(key: _keyRefreshToken);
    }

    await _storage.delete(key: _keyUserId);
    await _storage.delete(key: _keyUserRole);
    await _storage.delete(key: _keyUserName);
    await _storage.delete(key: _keyUserPhone);
    await _storage.delete(key: _keyUserEmail);
    await _storage.delete(key: _keyPlanType);
    await _storage.delete(key: _keyCccdNumber);
    await _storage.delete(key: _keyHometown);
    await _storage.delete(key: _keyOccupation);
    await _storage.delete(key: _keyGender);
    await _storage.delete(key: _keyStatus);
    await _storage.delete(key: _keyOwnerStatus);
    await _storage.delete(key: _keyAvatarUrl);
  }
}
