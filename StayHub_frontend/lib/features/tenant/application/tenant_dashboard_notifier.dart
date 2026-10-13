import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter/foundation.dart';
import '../../../core/constants/role_types.dart';
import '../../auth/application/auth_notifier.dart';
import '../../../core/providers/core_providers.dart';
import '../../contract/application/contract_notifier.dart';
import 'dart:async' show unawaited;

part 'tenant_dashboard_notifier.g.dart';

@riverpod
Future<List<dynamic>> unpaidBills(Ref ref) async {
  final user = ref.watch(authProvider).value;
  if (user == null) return [];

  final apiClient = ref.watch(apiClientProvider);
  try {
    final res = await apiClient.get('/v1/bills/tenant/${user.id}/unpaid');
    if (res['success'] == true) {
      // BUGFIX (data): tránh `as List<dynamic>` ném TypeError khi `data`
      // null/không phải List.
      final raw = res['data'];
      return raw is List ? raw : const <dynamic>[];
    }
  } catch (e) {
    debugPrint('Lỗi lấy hóa đơn: $e');
  }
  return [];
}

// Lưu trữ trạng thái UI của màn hình Tenant Dashboard
class TenantDashboardState {
  final TenantState tenantState;
  final int selectedTab;
  final dynamic
  verificationRoom; // Chứa dữ liệu phòng để đem sang trang Nghiệm thu
  final bool isLoading;

  const TenantDashboardState({
    required this.tenantState,
    required this.selectedTab,
    this.verificationRoom,
    this.isLoading = false,
  });

  TenantDashboardState copyWith({
    TenantState? tenantState,
    int? selectedTab,
    dynamic verificationRoom,
    bool? isLoading,
  }) {
    return TenantDashboardState(
      tenantState: tenantState ?? this.tenantState,
      selectedTab: selectedTab ?? this.selectedTab,
      verificationRoom: verificationRoom ?? this.verificationRoom,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@Riverpod(keepAlive: true)
class TenantDashboardNotifier extends _$TenantDashboardNotifier {
  bool _initialized = false;

  @override
  TenantDashboardState build() {
    if (!_initialized) {
      _initialized = true;
      unawaited(
        Future.microtask(() {
          _init();
        }),
      );
    }

    // Lắng nghe contractProvider để tự động cập nhật tenantState ban đầu
    ref.listen(contractProvider, (previous, next) {
      // GUARD 1: Không ghi đè khi đang chờ duyệt hoặc đang nghiệm thu
      if (state.tenantState == TenantState.verifying ||
          state.tenantState == TenantState.pendingApproval) {
        return;
      }

      if (next.isLoading) return; // Chống ghi đè state lúc đang call API

      final contracts = next.value ?? [];
      // GUARD 2: Chỉ vào linked khi có hợp đồng ACTIVE (không tính PENDING - đó chỉ là chờ ký)
      final hasActive = contracts.any((c) => c.status == 'ACTIVE');
      final hasPending = contracts.any((c) => c.status == 'PENDING');

      if (hasActive) {
        // Hợp đồng ACTIVE: cần kiểm tra rental request để xác định đã nghiệm thu xong chưa
        unawaited(_checkRentalRequestStatus());
      } else if (hasPending) {
        // Hợp đồng PENDING: linked nhưng UI sẽ hiện "Chờ Ký Hợp Đồng"
        state = state.copyWith(
          tenantState: TenantState.linked,
          selectedTab: 0,
          isLoading: false,
        );
      } else {
        // Có hợp đồng khác (TERMINATED, CANCELLED...) hoặc chưa có hợp đồng nào
        state = state.copyWith(
          tenantState: TenantState.unlinked,
          isLoading: false,
        );
      }
    });
    return const TenantDashboardState(
      tenantState: TenantState.unlinked,
      selectedTab: 0, // Mặc định mở Trang chủ (TenantHomeScreen)
      isLoading: true,
    );
  }

  void _init() {
    unawaited(_checkRentalRequestStatus());
  }

  Future<void> checkStatus() async {
    await _checkRentalRequestStatus();
  }

  Future<void> _checkRentalRequestStatus() async {
    final user = ref.read(authProvider).value;
    if (user == null) return;

    final apiClient = ref.read(apiClientProvider);
    try {
      final res = await apiClient.get(
        '/v1/rental-requests/tenant/${user.id}/latest',
      );
      if (res['success'] == true && res['data'] != null) {
        final req = res['data'];
        final status = req['status'];
        final roomData = {
          'id': req['roomId'],
          'roomName': req['roomName'],
          'requestId': req['id'],
        };

        if (status == 'PENDING') {
          state = state.copyWith(
            tenantState: TenantState.pendingApproval,
            verificationRoom: roomData,
            isLoading: false,
          );
          return; // Dừng lại ở đây vì UI đang theo luồng request
        } else if (status == 'APPROVED_WAITING_HANDOVER') {
          state = state.copyWith(
            tenantState: TenantState.verifying,
            selectedTab: 1,
            verificationRoom: roomData,
            isLoading: false,
          );
          return; // Đang chờ nghiệm thu
        } else if (status == 'COMPLETED') {
          // Bỏ qua, để cho logic kiểm tra contract bên dưới xử lý
        } else if (status == 'REJECTED' &&
            state.tenantState != TenantState.linked) {
          state = state.copyWith(
            tenantState: TenantState.unlinked,
            verificationRoom: null,
            isLoading: false, // Nếu k có request nào khác, sẽ set false
          );
        }
      }
    } catch (e) {
      debugPrint('Lỗi lấy rental request (có thể không có request nào): $e');
    }

    // Luôn luôn kiểm tra Fallback (Hợp đồng) - kể cả khi API trên trả về 404 hoặc lỗi
    try {
      final contractState = ref.read(contractProvider);

      // BẢO VỆ: Nếu hợp đồng chưa load xong, tuyệt đối KHÔNG tắt isLoading ở đây.
      // Vì ref.listen ở trên sẽ gọi lại hàm này (hoặc tự tắt isLoading) khi load xong.
      if (contractState.isLoading) {
        return;
      }

      final contracts = contractState.value ?? [];
      final hasActiveContract = contracts.any((c) => c.status == 'ACTIVE');
      final hasPendingContract = contracts.any((c) => c.status == 'PENDING');

      if (hasActiveContract || hasPendingContract) {
        state = state.copyWith(
          tenantState: TenantState.linked,
          selectedTab: 0,
          verificationRoom: null,
          isLoading: false,
        );
      } else {
        // Đã check request xong, đã check hợp đồng xong nhưng k có gì. Tắt loading, hiện màn Quét QR.
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      debugPrint('Lỗi khi fallback check contract: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  void setTab(int index) {
    state = state.copyWith(selectedTab: index);
  }

  void requestApproval(dynamic room) {
    state = state.copyWith(
      tenantState: TenantState.pendingApproval,
      selectedTab: 0, // Vẫn ở trang chủ để xem đồng hồ cát
      verificationRoom: room,
    );
  }

  Future<void> startVerification() async {
    // Refresh status to get latest verificationRoom data
    await _checkRentalRequestStatus();
    state = state.copyWith(
      tenantState: TenantState.verifying,
      selectedTab: 1, // Chuyển sang Tab Nghiệm thu (Tab 2)
    );
  }

  void completeVerification() {
    // 1. Ép State cập nhật thủ công ngay lập tức (Zero-Latency Core)
    state = state.copyWith(
      tenantState: TenantState.linked,
      selectedTab: 0, // Quay về Trang chủ
      verificationRoom: null,
    );

    // 2. Gọi ngầm background để fetch dữ liệu từ server (không block UI)
    ref.invalidate(contractProvider);
    // Fetch lại Auth/Profile nếu cần
    ref.invalidate(authProvider);
  }

  Future<bool> cancelRentalRequest() async {
    if (state.verificationRoom == null ||
        state.verificationRoom['requestId'] == null) {
      return false;
    }
    final reqId = state.verificationRoom['requestId'];
    final apiClient = ref.read(apiClientProvider);
    try {
      final res = await apiClient.put('/v1/rental-requests/$reqId/cancel');
      if (res['success'] == true) {
        state = state.copyWith(
          tenantState: TenantState.unlinked,
          selectedTab: 0,
          verificationRoom: null,
        );
        ref.invalidateSelf();
        return true;
      }
    } catch (e) {
      debugPrint('Lỗi hủy yêu cầu: $e');
    }
    return false;
  }
}
