import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';

/// Lấy toàn bộ danh sách Chủ nhà cho Admin quản lý.
/// Provider tự động refresh khi được invalidate.
final adminOwnersProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.get('/v1/admin/owners');
  if (response['success'] == true) {
    // BUGFIX (data): tránh `as List<dynamic>` ném TypeError khi `data`
    // null/không phải List — trả [] để màn hình không vỡ.
    final raw = response['data'];
    return raw is List ? raw : const <dynamic>[];
  }
  throw Exception(response['message'] ?? 'Không thể tải danh sách chủ nhà');
});

/// Đếm số chủ nhà đang chờ duyệt (PENDING_VERIFICATION).
/// Dùng để hiển thị badge trên tab Phê duyệt.
final adminPendingOwnersCountProvider = Provider.autoDispose<AsyncValue<int>>((
  ref,
) {
  return ref
      .watch(adminOwnersProvider)
      .whenData(
        (owners) => owners
            .where((o) => o['ownerStatus'] == 'PENDING_VERIFICATION')
            .length,
      );
});

/// Notifier xử lý các thao tác quản trị: duyệt, từ chối, sửa, đình chỉ.
class AdminOwnerNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<bool> verifyOwner(int ownerId, bool approved, {String? reason}) async {
    state = const AsyncLoading();
    try {
      final client = ref.read(apiClientProvider);
      await client.put(
        '/v1/admin/owners/$ownerId/verify',
        data: {'approved': approved, if (reason != null) 'reason': reason},
      );
      state = const AsyncData(null);
      ref.invalidate(adminOwnersProvider);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> banOwner(int ownerId, {required bool isBanned}) async {
    state = const AsyncLoading();
    try {
      final client = ref.read(apiClientProvider);
      await client.put(
        '/v1/admin/owners/$ownerId/ban',
        data: {'isBanned': isBanned},
      );
      state = const AsyncData(null);
      ref.invalidate(adminOwnersProvider);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> overrideOwner(
    int ownerId, {
    required String name,
    required String phone,
  }) async {
    state = const AsyncLoading();
    try {
      final client = ref.read(apiClientProvider);
      await client.put(
        '/v1/admin/owners/$ownerId/override',
        data: {'name': name, 'phone': phone},
      );
      state = const AsyncData(null);
      ref.invalidate(adminOwnersProvider);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final adminOwnerActionProvider =
    AsyncNotifierProvider<AdminOwnerNotifier, void>(AdminOwnerNotifier.new);
