import '../../../../core/security/secure_storage_service.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/utils/image_url_helper.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/user_entity.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final SecureStorageService _secureStorage;

  const AuthRepositoryImpl(this._remoteDataSource, this._secureStorage);

  /// Helper: lưu toàn bộ thông tin user (kể cả CCCD, quê quán, avatar) vào secure storage
  Future<void> _saveFullSession(UserModel userModel) async {
    String mappedRole = userModel.roleId;
    if (mappedRole == '1') {
      mappedRole = 'ADMIN';
    } else if (mappedRole == '2') {
      mappedRole = 'OWNER';
    } else if (mappedRole == '3') {
      mappedRole = 'TENANT';
    } else if (mappedRole == '4') {
      mappedRole = 'STAFF';
    }

    await _secureStorage.saveUserSession(
      id: userModel.id.toString(),
      role: mappedRole,
      name: userModel.fullName,
      phone: userModel.phone ?? '',
      email: userModel.email,
      planType: userModel.packageId,
      cccdNumber: userModel.cccdNumber,
      hometown: userModel.hometown,
      occupation: userModel.occupation,
      gender: userModel.gender,
      status: userModel.status,
      ownerStatus: userModel.ownerStatus,
      kycStatus: userModel.kycStatus,
      avatarUrl: ImageUrlHelper.buildUrl(userModel.avatarUrl),
    );
  }

  @override
  Future<UserEntity> login(String emailOrPhone, String password) async {
    final res = await _remoteDataSource.login(emailOrPhone, password);

    // AuthResponse không có field 'success' – kiểm tra token
    // Nếu login thất bại, backend trả {success:false, message:...} qua security filter
    final success = res['success'];
    if (success == false) {
      final msg =
          res['message']?.toString() ??
          'Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin.';
      // Nếu backend trả kèm name/avatar → sai mật khẩu cá nhân hoá
      final name = res['name']?.toString();
      final avatar = res['avatar']?.toString();
      if (name != null && name.isNotEmpty) {
        throw WrongPasswordException(
          message: msg,
          userName: name,
          userAvatar: avatar?.isNotEmpty == true ? avatar : null,
        );
      }
      throw BadRequestException(message: msg);
    }

    final token = res['token'] as String?;
    if (token == null) {
      final msg =
          res['message']?.toString() ?? 'Xác thực thất bại. Vui lòng thử lại.';
      throw BadRequestException(message: msg);
    }
    final refreshToken = res['refreshToken'] as String?;
    final userData = res['user'] as Map<String, dynamic>?;
    if (userData == null) {
      throw const ServerException(message: 'Dữ liệu người dùng không hợp lệ.');
    }
    final userModel = UserModel.fromJson(userData);

    // Lưu token trước để các request kế tiếp có auth
    await _secureStorage.saveToken(token, refreshToken: refreshToken);

    // Sau khi login, gọi getProfile để lấy đầy đủ dữ liệu kể cả avatarUrl
    try {
      final profileRes = await _remoteDataSource.getProfile(userModel.id);
      final rawProfile = profileRes['data'];
      if (rawProfile is Map<String, dynamic>) {
        final fullUserModel = UserModel.fromJson(rawProfile);
        await _saveFullSession(fullUserModel);
        return fullUserModel.toEntity();
      }
    } on UnauthorizedException {
      // Token vừa cấp đã bị từ chối → phiên không hợp lệ, không nên nuốt lỗi
      // rồi trả về user "ảo" khiến UI tưởng đăng nhập thành công.
      await _secureStorage.clearSession();
      rethrow;
    } on ForbiddenException {
      await _secureStorage.clearSession();
      rethrow;
    } catch (_) {
      // Lỗi mạng/timeout tạm thời → chấp nhận fallback dữ liệu từ login response
    }
    // Fallback to login response data
    await _saveFullSession(userModel);
    return userModel.toEntity();
  }

  @override
  Future<UserEntity> loginWithBiometric(String refreshTokenParam) async {
    final res = await _remoteDataSource.loginWithRefreshToken(
      refreshTokenParam,
    );

    final success = res['success'];
    if (success == false) {
      final msg =
          res['message']?.toString() ??
          'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập bằng mật khẩu.';
      throw BadRequestException(message: msg);
    }

    final token = res['token'] as String?;
    if (token == null) {
      throw const BadRequestException(
        message: 'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.',
      );
    }
    final newRefreshToken = res['refreshToken'] as String?;
    final userData = res['user'] as Map<String, dynamic>?;
    if (userData == null) {
      throw const ServerException(message: 'Dữ liệu người dùng không hợp lệ.');
    }
    final userModel = UserModel.fromJson(userData);

    await _secureStorage.saveToken(
      token,
      refreshToken: newRefreshToken ?? refreshTokenParam,
    );

    // Sau khi login, gọi getProfile để lấy đầy đủ dữ liệu kể cả avatarUrl
    try {
      final profileRes = await _remoteDataSource.getProfile(userModel.id);
      final rawProfile = profileRes['data'];
      if (rawProfile is Map<String, dynamic>) {
        final fullUserModel = UserModel.fromJson(rawProfile);
        await _saveFullSession(fullUserModel);
        return fullUserModel.toEntity();
      }
    } catch (_) {}
    await _saveFullSession(userModel);
    return userModel.toEntity();
  }

  @override
  Future<UserEntity> register(Map<String, dynamic> data) async {
    final res = await _remoteDataSource.register(data);

    final success = res['success'];
    if (success == false) {
      final msg =
          res['message']?.toString() ?? 'Đăng ký thất bại. Vui lòng thử lại.';
      throw BadRequestException(message: msg);
    }

    final token = res['token'] as String?;
    if (token == null) {
      throw const ServerException(message: 'Không nhận được token đăng ký.');
    }
    final refreshToken = res['refreshToken'] as String?;
    final userData = res['user'] as Map<String, dynamic>?;
    if (userData == null) {
      throw const ServerException(message: 'Dữ liệu người dùng không hợp lệ.');
    }
    final userModel = UserModel.fromJson(userData);

    await _secureStorage.saveToken(token, refreshToken: refreshToken);
    await _saveFullSession(userModel);

    return userModel.toEntity();
  }

  @override
  Future<String?> sendOtp(String target, String channel) async {
    final res = await _remoteDataSource.sendOtp(target, channel);
    return res['devOtp']?.toString();
  }

  @override
  Future<String> verifyOtp(String target, String channel, String code) async {
    final res = await _remoteDataSource.verifyOtp(target, channel, code);
    if (res['registrationToken'] == null) {
      throw Exception('Không nhận được registrationToken từ server');
    }
    return res['registrationToken'] as String;
  }

  @override
  Future<void> logout() async {
    await _secureStorage.clearSession();
  }

  @override
  Future<UserEntity?> tryAutoLogin() async {
    final token = await _secureStorage.getAccessToken();
    if (token == null) return null;

    final session = await _secureStorage.getUserSession();
    final idStr = session['id'];
    final role = session['role']?.toString().toUpperCase();
    final name = session['name'];
    final phone = session['phone'];

    if (idStr == null || role == null || name == null || phone == null) {
      await _secureStorage.clearSession();
      return null;
    }

    final id = int.tryParse(idStr);
    if (id == null) {
      await _secureStorage.clearSession();
      return null;
    }

    try {
      // Ưu tiên lấy profile mới nhất từ server để luôn đồng bộ
      final res = await _remoteDataSource.getProfile(id);
      final rawData = res['data'];
      if (rawData is Map<String, dynamic>) {
        final userModel = UserModel.fromJson(rawData);
        await _saveFullSession(userModel);
        return userModel.toEntity();
      }
      // Fall through to offline fallback if data format is unexpected
    } catch (e, st) {
      debugPrint('Error: $e\n$st');
      if (e is UnauthorizedException ||
          e is ForbiddenException ||
          (e is AppException && (e.statusCode == 401 || e.statusCode == 403))) {
        await _secureStorage.clearSession();
        return null;
      }
    }
    // Fallback khi offline: đọc từ secure storage
    // Giờ đây secure storage đã có đầy đủ cccd/hometown/occupation
    return UserEntity(
      id: id,
      fullName: name,
      phoneNumber: phone,
      email: session['email'],
      role: role,
      planType: session['plan_type'] ?? 'FREE',
      cccdNumber: session['cccd_number']?.isNotEmpty == true
          ? session['cccd_number']
          : null,
      hometown: session['hometown']?.isNotEmpty == true
          ? session['hometown']
          : null,
      occupation: session['occupation']?.isNotEmpty == true
          ? session['occupation']
          : null,
      gender: session['gender']?.isNotEmpty == true ? session['gender'] : null,
      status: session['status']?.isNotEmpty == true ? session['status'] : null,
      ownerStatus: session['ownerStatus']?.isNotEmpty == true
          ? session['ownerStatus']
          : null,
      avatar: session['avatarUrl']?.isNotEmpty == true
          ? session['avatarUrl']
          : null,
    );
  }

  @override
  Future<UserEntity> updateProfile(Map<String, dynamic> data) async {
    final session = await _secureStorage.getUserSession();
    final idStr = session['id'];
    if (idStr == null) throw Exception('User not logged in');

    // Dùng tryParse thay vì parse: nếu session bị hỏng (id không phải số)
    // thì ném lỗi rõ ràng thay vì crash FormatException khó hiểu.
    final id = int.tryParse(idStr);
    if (id == null) {
      await _secureStorage.clearSession();
      throw const UnauthorizedException(
        message: 'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.',
      );
    }
    final res = await _remoteDataSource.updateProfile(id, data);
    final rawData = res['data'];
    if (rawData is! Map<String, dynamic>) {
      throw const ServerException(
        message: 'Cập nhật hồ sơ thất bại. Dữ liệu không hợp lệ.',
      );
    }
    final userModel = UserModel.fromJson(rawData);

    // Lưu đầy đủ thông tin sau khi cập nhật - bao gồm CCCD, quê quán
    await _saveFullSession(userModel);

    return userModel.toEntity();
  }

  @override
  Future<UserEntity> uploadAvatar(String imagePath) async {
    final session = await _secureStorage.getUserSession();
    final idStr = session['id'];
    if (idStr == null) throw Exception('User not logged in');

    final id = int.tryParse(idStr);
    if (id == null) {
      await _secureStorage.clearSession();
      throw const UnauthorizedException(
        message: 'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.',
      );
    }
    final res = await _remoteDataSource.uploadAvatar(id, imagePath);
    final rawData2 = res['data'];
    if (rawData2 is! Map<String, dynamic>) {
      throw const ServerException(message: 'Cập nhật ảnh đại diện thất bại.');
    }
    final userModel = UserModel.fromJson(rawData2);

    await _saveFullSession(userModel);
    return userModel.toEntity();
  }

  @override
  Future<UserEntity> updateSignature(String signature, String? otp) async {
    final session = await _secureStorage.getUserSession();
    final idStr = session['id'];
    if (idStr == null) throw Exception('User not logged in');

    final id = int.tryParse(idStr);
    if (id == null) {
      await _secureStorage.clearSession();
      throw const UnauthorizedException(
        message: 'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.',
      );
    }
    final res = await _remoteDataSource.updateSignature(id, signature, otp);
    final rawData3 = res['data'];
    if (rawData3 is! Map<String, dynamic>) {
      throw const ServerException(message: 'Cập nhật chữ ký thất bại.');
    }
    final userModel = UserModel.fromJson(rawData3);

    // Đồng bộ session giống updateProfile/uploadAvatar để chữ ký mới
    // không bị mất khi app khởi động lại (trước đây thiếu bước này).
    await _saveFullSession(userModel);

    return userModel.toEntity();
  }

  @override
  Future<UserEntity> loginWithGoogle(String idToken) async {
    final res = await _remoteDataSource.loginWithGoogle(idToken);

    // Kiểm tra lỗi từ backend
    final success = res['success'];
    if (success == false) {
      final msg = res['message']?.toString() ?? 'Đăng nhập Google thất bại.';
      throw BadRequestException(message: msg);
    }

    final token = res['token'] as String?;
    if (token == null) {
      final msg =
          res['message']?.toString() ?? 'Không nhận được token từ server.';
      throw BadRequestException(message: msg);
    }
    final refreshToken = res['refreshToken'] as String?;
    final userData = res['user'] as Map<String, dynamic>?;
    if (userData == null) {
      throw const ServerException(message: 'Dữ liệu người dùng không hợp lệ.');
    }

    final userModel = UserModel.fromJson(userData);
    await _secureStorage.saveToken(token, refreshToken: refreshToken);

    // Sau khi login, gọi getProfile để lấy đầy đủ dữ liệu kể cả avatarUrl
    try {
      final profileRes = await _remoteDataSource.getProfile(userModel.id);
      final rawProfile = profileRes['data'];
      if (rawProfile is Map<String, dynamic>) {
        final fullUserModel = UserModel.fromJson(rawProfile);
        await _saveFullSession(fullUserModel);
        return fullUserModel.toEntity();
      }
    } catch (_) {}
    await _saveFullSession(userModel);
    return userModel.toEntity();
  }

  @override
  Future<UserEntity> loginWithFacebook(String accessToken) async {
    final res = await _remoteDataSource.loginWithFacebook(accessToken);

    final success = res['success'];
    if (success == false) {
      final msg = res['message']?.toString() ?? 'Đăng nhập Facebook thất bại.';
      throw BadRequestException(message: msg);
    }

    // Backend có thể trả token ở field 'accessToken' hoặc 'token' tuỳ phiên bản.
    final token = res['accessToken'] as String? ?? res['token'] as String?;
    if (token == null) {
      throw const BadRequestException(
        message: 'Không nhận được token từ server.',
      );
    }
    final refreshToken = res['refreshToken'] as String?;
    final userData = res['user'] as Map<String, dynamic>?;
    if (userData == null) {
      throw const ServerException(message: 'Dữ liệu người dùng không hợp lệ.');
    }

    final userModel = UserModel.fromJson(userData);
    await _secureStorage.saveToken(token, refreshToken: refreshToken);

    try {
      final profileRes = await _remoteDataSource.getProfile(userModel.id);
      final rawProfile = profileRes['data'];
      if (rawProfile is Map<String, dynamic>) {
        final fullUserModel = UserModel.fromJson(rawProfile);
        await _saveFullSession(fullUserModel);
        return fullUserModel.toEntity();
      }
    } catch (_) {}
    await _saveFullSession(userModel);
    return userModel.toEntity();
  }

  @override
  Future<UserEntity> loginWithZalo(String accessToken) async {
    final res = await _remoteDataSource.loginWithZalo(accessToken);

    final success = res['success'];
    if (success == false) {
      final msg = res['message']?.toString() ?? 'Đăng nhập Zalo thất bại.';
      throw BadRequestException(message: msg);
    }

    final token = res['accessToken'] as String? ?? res['token'] as String?;
    if (token == null) {
      throw const BadRequestException(
        message: 'Không nhận được token từ server.',
      );
    }
    final refreshToken = res['refreshToken'] as String?;
    final userData = res['user'] as Map<String, dynamic>?;
    if (userData == null) {
      throw const ServerException(message: 'Dữ liệu người dùng không hợp lệ.');
    }

    final userModel = UserModel.fromJson(userData);
    await _secureStorage.saveToken(token, refreshToken: refreshToken);

    try {
      final profileRes = await _remoteDataSource.getProfile(userModel.id);
      final rawProfile = profileRes['data'];
      if (rawProfile is Map<String, dynamic>) {
        final fullUserModel = UserModel.fromJson(rawProfile);
        await _saveFullSession(fullUserModel);
        return fullUserModel.toEntity();
      }
    } catch (_) {}
    await _saveFullSession(userModel);
    return userModel.toEntity();
  }

  @override
  Future<UserEntity> loginWithApple(
    String identityToken, {
    String? fullName,
    String? email,
  }) async {
    final res = await _remoteDataSource.loginWithApple(
      identityToken,
      fullName: fullName,
      email: email,
    );

    final success = res['success'];
    if (success == false) {
      final msg = res['message']?.toString() ?? 'Đăng nhập Apple thất bại.';
      throw BadRequestException(message: msg);
    }

    final token = res['accessToken'] as String? ?? res['token'] as String?;
    if (token == null) {
      throw const BadRequestException(
        message: 'Không nhận được token từ server.',
      );
    }
    final refreshToken = res['refreshToken'] as String?;
    final userData = res['user'] as Map<String, dynamic>?;
    if (userData == null) {
      throw const ServerException(message: 'Dữ liệu người dùng không hợp lệ.');
    }

    final userModel = UserModel.fromJson(userData);
    await _secureStorage.saveToken(token, refreshToken: refreshToken);

    try {
      final profileRes = await _remoteDataSource.getProfile(userModel.id);
      final rawProfile = profileRes['data'];
      if (rawProfile is Map<String, dynamic>) {
        final fullUserModel = UserModel.fromJson(rawProfile);
        await _saveFullSession(fullUserModel);
        return fullUserModel.toEntity();
      }
    } catch (_) {}
    await _saveFullSession(userModel);
    return userModel.toEntity();
  }

  @override
  Future<UserEntity> loginWithWhatsApp(String phoneToken) async {
    final res = await _remoteDataSource.loginWithWhatsApp(phoneToken);

    final success = res['success'];
    if (success == false) {
      final msg = res['message']?.toString() ?? 'Đăng nhập WhatsApp thất bại.';
      throw BadRequestException(message: msg);
    }

    final token = res['token'] as String?;
    if (token == null) {
      throw const BadRequestException(
        message: 'Không nhận được token từ server.',
      );
    }
    final refreshToken = res['refreshToken'] as String?;
    final userData = res['user'] as Map<String, dynamic>?;
    if (userData == null) {
      throw const ServerException(message: 'Dữ liệu người dùng không hợp lệ.');
    }

    final userModel = UserModel.fromJson(userData);
    await _secureStorage.saveToken(token, refreshToken: refreshToken);

    try {
      final profileRes = await _remoteDataSource.getProfile(userModel.id);
      final rawProfile = profileRes['data'];
      if (rawProfile is Map<String, dynamic>) {
        final fullUserModel = UserModel.fromJson(rawProfile);
        await _saveFullSession(fullUserModel);
        return fullUserModel.toEntity();
      }
    } catch (_) {}
    await _saveFullSession(userModel);
    return userModel.toEntity();
  }

  @override
  Future<String> verifyPhoneWithFirebase(
    String phoneNumber,
    String firebaseUid,
  ) async {
    final res = await _remoteDataSource.verifyPhoneWithFirebase(
      phoneNumber,
      firebaseUid,
    );

    final success = res['success'];
    if (success == false) {
      final msg =
          res['message']?.toString() ?? 'Xác thực số điện thoại thất bại.';
      throw BadRequestException(message: msg);
    }

    final token = res['registrationToken'] as String?;
    if (token == null) {
      throw const BadRequestException(
        message: 'Không nhận được mã xác thực. Vui lòng thử lại.',
      );
    }
    return token;
  }

  @override
  Future<void> setupPassword(String newPassword) async {
    final res = await _remoteDataSource.setupPassword(newPassword);
    final success = res['success'];
    if (success == false) {
      final msg = res['message']?.toString() ?? 'Cập nhật mật khẩu thất bại.';
      throw BadRequestException(message: msg);
    }
  }
}
