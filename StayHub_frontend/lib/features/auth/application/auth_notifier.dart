import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/services/wishlist_service.dart';
import '../../../core/utils/image_url_helper.dart';
import '../data/datasources/auth_remote_data_source.dart';
import '../data/repositories/auth_repository_impl.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/user_entity.dart';

part 'auth_notifier.g.dart';

@Riverpod(keepAlive: true)
AuthRemoteDataSource authRemoteDataSource(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSource(apiClient);
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return AuthRepositoryImpl(remoteDataSource, secureStorage);
}

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  FutureOr<UserEntity?> build() async {
    final repository = ref.read(authRepositoryProvider);
    return await repository.tryAutoLogin();
  }

  Future<void> login(
    String emailOrPhone,
    String password, {
    bool rememberMe = true,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      return repository.login(emailOrPhone, password);
    });
    if (state.hasError) throw state.error!;

    // Save user info for biometric returning user flow
    if (state.hasValue && state.value != null) {
      if (rememberMe) {
        final user = state.value!;
        // await để tránh unhandled async error và đảm bảo dữ liệu sinh trắc
        // học đã lưu xong trước khi UI điều hướng.
        await ref
            .read(secureStorageServiceProvider)
            .saveLastUser(
              emailOrPhone,
              name: user.fullName,
              avatar: ImageUrlHelper.buildUrl(user.avatar),
            );
      } else {
        // If user unchecked "Duy trì đăng nhập", clear any existing saved user just in case
        await ref.read(secureStorageServiceProvider).clearLastUser();
      }
    }

    // Re-sync FCM token after login so it's tied to the authenticated JWT.
    // await để tránh unhandled async error khi FCM service ném lỗi.
    final apiClient = ref.read(apiClientProvider);
    try {
      await ref.read(fcmServiceProvider).resyncToken(apiClient);
    } catch (_) {}

    // Sync wishlist từ local storage (guest) lên server
    if (state.hasValue && state.value?.id != null) {
      try {
        await WishlistService.syncLocalToServer(
          state.value!.id.toString(),
          apiClient,
        );
      } catch (_) {}
    }
  }

  Future<void> loginWithBiometric() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final secureStorage = ref.read(secureStorageServiceProvider);
      final refreshToken = await secureStorage.getRefreshToken();
      if (refreshToken == null) {
        throw const FormatException(
          'Phiên đăng nhập đã hết hạn. Vui lòng nhập lại mật khẩu.',
        );
      }
      final repository = ref.read(authRepositoryProvider);
      return repository.loginWithBiometric(refreshToken);
    });
    if (state.hasError) throw state.error!;

    // Re-sync FCM token after biometric login
    final apiClient = ref.read(apiClientProvider);
    try {
      await ref.read(fcmServiceProvider).resyncToken(apiClient);
    } catch (_) {}

    // Sync wishlist từ local storage lên server
    if (state.hasValue && state.value?.id != null) {
      try {
        await WishlistService.syncLocalToServer(
          state.value!.id.toString(),
          apiClient,
        );
      } catch (_) {}
    }
  }

  Future<void> loginWithGoogle(String idToken) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      return repository.loginWithGoogle(idToken);
    });
    if (state.hasError) throw state.error!;

    // Google auth doesn't use standard password
    if (state.hasValue && state.value != null && state.value!.email != null) {
      final user = state.value!;
      // BUGFIX (Bug 139): bọc try/catch — nếu lưu secure storage lỗi thì KHÔNG
      // được ném ra ngoài, vì đăng nhập đã thành công (state đã là data). Ném
      // lỗi ở đây khiến UI báo "đăng nhập thất bại" oan. Đồng bộ với `register`.
      try {
        await ref
            .read(secureStorageServiceProvider)
            .saveLastUser(user.email!, name: user.fullName);
      } catch (_) {}
    }

    // Re-sync FCM token sau Google login
    final apiClient = ref.read(apiClientProvider);
    try {
      await ref.read(fcmServiceProvider).resyncToken(apiClient);
    } catch (_) {}

    // Sync wishlist từ local storage lên server
    if (state.hasValue && state.value?.id != null) {
      try {
        await WishlistService.syncLocalToServer(
          state.value!.id.toString(),
          apiClient,
        );
      } catch (_) {}
    }
  }

  Future<void> loginWithFacebook(String accessToken) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      return repository.loginWithFacebook(accessToken);
    });
    if (state.hasError) throw state.error!;

    // Facebook auth doesn't use standard password
    if (state.hasValue && state.value != null && state.value!.email != null) {
      final user = state.value!;
      // BUGFIX (Bug 139): bọc try/catch — tránh ném lỗi sau khi đăng nhập đã
      // thành công (xem giải thích ở loginWithGoogle).
      try {
        await ref
            .read(secureStorageServiceProvider)
            .saveLastUser(user.email!, name: user.fullName);
      } catch (_) {}
    }

    // Re-sync FCM token sau Facebook login
    final apiClient = ref.read(apiClientProvider);
    try {
      await ref.read(fcmServiceProvider).resyncToken(apiClient);
    } catch (_) {}

    // Sync wishlist từ local storage lên server
    if (state.hasValue && state.value?.id != null) {
      try {
        await WishlistService.syncLocalToServer(
          state.value!.id.toString(),
          apiClient,
        );
      } catch (_) {}
    }
  }

  Future<void> loginWithZalo(String accessToken) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      return repository.loginWithZalo(accessToken);
    });
    if (state.hasError) throw state.error!;

    // Zalo auth doesn't use standard password
    if (state.hasValue && state.value != null && state.value!.email != null) {
      final user = state.value!;
      // BUGFIX (Bug 139): bọc try/catch — tránh ném lỗi sau khi đăng nhập đã
      // thành công (xem giải thích ở loginWithGoogle).
      try {
        await ref
            .read(secureStorageServiceProvider)
            .saveLastUser(user.email!, name: user.fullName);
      } catch (_) {}
    }

    // Re-sync FCM token sau Zalo login
    final apiClient = ref.read(apiClientProvider);
    try {
      await ref.read(fcmServiceProvider).resyncToken(apiClient);
    } catch (_) {}

    // Sync wishlist từ local storage lên server
    if (state.hasValue && state.value?.id != null) {
      try {
        await WishlistService.syncLocalToServer(
          state.value!.id.toString(),
          apiClient,
        );
      } catch (_) {}
    }
  }

  Future<void> loginWithApple(
    String identityToken, {
    String? fullName,
    String? email,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      return repository.loginWithApple(
        identityToken,
        fullName: fullName,
        email: email,
      );
    });
    if (state.hasError) throw state.error!;

    // Apple auth doesn't use standard password
    if (state.hasValue && state.value != null && state.value!.email != null) {
      final user = state.value!;
      // BUGFIX (Bug 139): bọc try/catch — tránh ném lỗi sau khi đăng nhập đã
      // thành công (xem giải thích ở loginWithGoogle).
      try {
        await ref
            .read(secureStorageServiceProvider)
            .saveLastUser(user.email!, name: user.fullName);
      } catch (_) {}
    }

    // Re-sync FCM token sau Apple login
    final apiClient = ref.read(apiClientProvider);
    try {
      await ref.read(fcmServiceProvider).resyncToken(apiClient);
    } catch (_) {}

    // Sync wishlist từ local storage lên server
    if (state.hasValue && state.value?.id != null) {
      try {
        await WishlistService.syncLocalToServer(
          state.value!.id.toString(),
          apiClient,
        );
      } catch (_) {}
    }
  }

  Future<void> loginWithWhatsApp(String phoneToken) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      return repository.loginWithWhatsApp(phoneToken);
    });
    if (state.hasError) throw state.error!;

    // WhatsApp auth
    if (state.hasValue && state.value != null && state.value!.email != null) {
      final user = state.value!;
      // BUGFIX (Bug 139): bọc try/catch — tránh ném lỗi sau khi đăng nhập đã
      // thành công (xem giải thích ở loginWithGoogle).
      try {
        await ref
            .read(secureStorageServiceProvider)
            .saveLastUser(user.email!, name: user.fullName);
      } catch (_) {}
    }

    // Re-sync FCM token
    final apiClient = ref.read(apiClientProvider);
    try {
      await ref.read(fcmServiceProvider).resyncToken(apiClient);
    } catch (_) {}

    // Sync wishlist từ local storage lên server
    if (state.hasValue && state.value?.id != null) {
      try {
        await WishlistService.syncLocalToServer(
          state.value!.id.toString(),
          apiClient,
        );
      } catch (_) {}
    }
  }

  Future<void> register(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      return repository.register(data);
    });
    if (state.hasError) throw state.error!;

    // Lưu thông tin user vừa đăng ký để luồng "đăng nhập lại bằng sinh trắc học"
    // hoạt động ngay sau khi đăng ký (trước đây bị thiếu → user phải login lại).
    if (state.hasValue && state.value != null) {
      final user = state.value!;
      final identifier = (user.email?.isNotEmpty == true)
          ? user.email!
          : user.phoneNumber;
      if (identifier.isNotEmpty) {
        try {
          await ref
              .read(secureStorageServiceProvider)
              .saveLastUser(
                identifier,
                name: user.fullName,
                avatar: ImageUrlHelper.buildUrl(user.avatar),
              );
        } catch (_) {}
      }
    }

    // Re-sync FCM token sau khi đăng ký để gắn với JWT mới
    final apiClient = ref.read(apiClientProvider);
    try {
      await ref.read(fcmServiceProvider).resyncToken(apiClient);
    } catch (_) {}
  }

  Future<String?> sendOtp(String target, String channel) async {
    final repository = ref.read(authRepositoryProvider);
    return repository.sendOtp(target, channel);
  }

  Future<String> verifyOtp(String target, String channel, String code) async {
    final repository = ref.read(authRepositoryProvider);
    return repository.verifyOtp(target, channel, code);
  }

  Future<String> verifyPhoneWithFirebase(
    String phoneNumber,
    String firebaseUid,
  ) async {
    final repository = ref.read(authRepositoryProvider);
    return repository.verifyPhoneWithFirebase(phoneNumber, firebaseUid);
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      return repository.updateProfile(data);
    });
    if (state.hasError) throw state.error!;
    await checkAuth(); // Real-time sync
  }

  Future<void> uploadAvatar(String imagePath) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      return repository.uploadAvatar(imagePath);
    });
    if (state.hasError) throw state.error!;
    await checkAuth(); // Real-time sync
  }

  Future<void> updateSignature(String signature, String? otp) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      return repository.updateSignature(signature, otp);
    });
    if (state.hasError) throw state.error!;
    await checkAuth(); // Real-time sync
  }

  Future<void> logout() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.logout();
    } catch (_) {
      // Dù clearSession lỗi (hiếm gặp) vẫn phải đưa state về null,
      // nếu không UI sẽ kẹt ở trạng thái loading vĩnh viễn.
    } finally {
      state = const AsyncValue.data(null);
    }
  }

  Future<void> checkAuth() async {
    if (!state.hasValue) state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      return repository.tryAutoLogin();
    });
  }

  void setUser(UserEntity user) {
    state = AsyncValue.data(user);
  }
}
