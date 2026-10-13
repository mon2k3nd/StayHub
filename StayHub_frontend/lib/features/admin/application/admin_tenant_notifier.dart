import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';

// 1a. Provider lấy danh sách khách thuê
final adminTenantsProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final client = ref.watch(apiClientProvider);
  try {
    final response = await client.get('/v1/admin/tenants');
    if (response['success'] == true) {
      // BUGFIX (data): tránh `as List<dynamic>` ném TypeError khi `data`
      // null/không phải List — trả [] để màn hình không vỡ.
      final raw = response['data'];
      return raw is List ? raw : const <dynamic>[];
    }
  } catch (e) {
    // return mock below
  }

  await Future.delayed(const Duration(seconds: 1));
  return [
    {
      'id': 1,
      'fullName': 'Nguyễn Văn Khách',
      'email': 'khach1@stayhub.vn',
      'phone': '0901234567',
      'status': 'ACTIVE',
      'cccdNumber': '001200001234',
    },
    {
      'id': 2,
      'fullName': 'Trần Thị Thuê',
      'email': 'thue2@stayhub.vn',
      'phone': '0909876543',
      'status': 'INACTIVE',
      'cccdNumber': '001200009876',
    },
  ];
});

// 1b. Provider lấy danh sách yêu cầu xác thực lại (REVERIFY_REQUESTED)
final adminReverifyRequestsProvider = FutureProvider.autoDispose<List<dynamic>>(
  (ref) async {
    final client = ref.watch(apiClientProvider);
    try {
      final response = await client.get(
        '/v1/admin/tenants?kycStatus=REVERIFY_REQUESTED',
      );
      if (response['success'] == true) {
        // BUGFIX (data): tránh `as List<dynamic>` ném TypeError khi `data`
        // null/không phải List — trả [] để màn hình không vỡ.
        final raw = response['data'];
        final data = raw is List ? raw : const <dynamic>[];
        return data
            .whereType<Map>()
            .where((t) => t['kycStatus'] == 'REVERIFY_REQUESTED')
            .toList();
      }
    } catch (_) {}
    return [];
  },
);

// 2. Notifier thực thi các quyền can thiệp sâu
class AdminTenantActionNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Initial state
  }

  Future<bool> unbanTenant(int tenantId, String reason) async {
    state = const AsyncLoading();
    try {
      final client = ref.read(apiClientProvider);
      final res = await client.put(
        '/v1/admin/tenants/$tenantId/unban',
        data: {'reason': reason},
      );
      if (res['success'] == true) {
        state = const AsyncData(null);
        ref.invalidate(adminTenantsProvider);
        return true;
      }
      state = AsyncError(Exception(res['message']), StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> updateTrustScore(int tenantId, int score, String reason) async {
    state = const AsyncLoading();
    try {
      final client = ref.read(apiClientProvider);
      final res = await client.put(
        '/v1/admin/tenants/$tenantId/trust-score',
        data: {'score': score, 'reason': reason},
      );
      if (res['success'] == true) {
        state = const AsyncData(null);
        ref.invalidate(adminTenantsProvider);
        return true;
      }
      state = AsyncError(Exception(res['message']), StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> unlinkCccd(int tenantId, String reason) async {
    state = const AsyncLoading();
    try {
      final client = ref.read(apiClientProvider);
      final res = await client.post(
        '/v1/admin/tenants/$tenantId/unlink-cccd',
        data: {'reason': reason},
      );
      if (res['success'] == true) {
        state = const AsyncData(null);
        ref.invalidate(adminTenantsProvider);
        return true;
      }
      state = AsyncError(Exception(res['message']), StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> approveEkyc(
    int tenantId,
    bool isApproved,
    String? reason, {
    String? cccdNumber,
  }) async {
    state = const AsyncLoading();
    try {
      final client = ref.read(apiClientProvider);
      final res = await client.dio.put(
        '/v1/admin/tenants/$tenantId/approve-ekyc',
        data: {
          'isApproved': isApproved,
          'reason': reason,
          if (cccdNumber != null) 'cccdNumber': cccdNumber,
        },
      );
      if (res.data['success'] == true) {
        state = const AsyncData(null);
        ref.invalidate(adminTenantsProvider);
        return true;
      }
      state = AsyncError(Exception(res.data['message']), StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  /// Duyệt / từ chối yêu cầu xác thực lại (REVERIFY_REQUESTED → UNVERIFIED / APPROVED)
  Future<bool> approveReverify(
    int tenantId,
    bool isApproved,
    String? reason,
  ) async {
    state = const AsyncLoading();
    try {
      final client = ref.read(apiClientProvider);
      // isApproved=true → UNVERIFIED (cho phép quét lại)
      // isApproved=false → APPROVED (giữ nguyên trạng thái cũ)
      final res = await client.dio.put(
        '/v1/admin/tenants/$tenantId/approve-ekyc',
        data: {
          'isApproved': isApproved,
          'reason':
              reason ??
              (isApproved
                  ? 'Admin duyệt yêu cầu xác thực lại'
                  : 'Admin từ chối yêu cầu xác thực lại'),
        },
      );
      if (res.data['success'] == true) {
        state = const AsyncData(null);
        ref.invalidate(adminTenantsProvider);
        ref.invalidate(adminReverifyRequestsProvider);
        return true;
      }
      state = AsyncError(Exception(res.data['message']), StackTrace.current);
      return false;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final adminTenantActionProvider =
    AsyncNotifierProvider<AdminTenantActionNotifier, void>(() {
      return AdminTenantActionNotifier();
    });
