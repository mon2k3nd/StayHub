import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/application/auth_notifier.dart';
import '../data/datasources/bill_remote_data_source.dart';
import '../data/models/bill_model.dart';
import '../data/repositories/bill_repository_impl.dart';
import '../domain/repositories/bill_repository.dart';
import '../../tenant/application/tenant_dashboard_notifier.dart';
import '../../../core/providers/dashboard_refresh.dart';

part 'bill_notifier.g.dart';

@riverpod
BillRemoteDataSource billRemoteDataSource(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BillRemoteDataSource(apiClient);
}

@Riverpod(keepAlive: true)
BillRepository billRepository(Ref ref) {
  final remoteDataSource = ref.watch(billRemoteDataSourceProvider);
  return BillRepositoryImpl(remoteDataSource);
}

@Riverpod(keepAlive: true)
class BillNotifier extends _$BillNotifier {
  @override
  FutureOr<List<BillModel>> build() async {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    if (user == null) return [];

    final repository = ref.read(billRepositoryProvider);
    if (user.role == 'OWNER') {
      return await repository.loadBillsByOwner(user.id);
    } else if (user.role == 'STAFF') {
      return await repository.loadBillsByStaff(user.id);
    } else {
      return await repository.loadBillsByTenant(user.id);
    }
  }

  Future<void> refreshBills() async {
    final authState = ref.read(authProvider);
    final user = authState.value;
    if (user == null) return;

    if (!state.hasValue) state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(billRepositoryProvider);
      if (user.role == 'OWNER') {
        return repository.loadBillsByOwner(user.id);
      } else if (user.role == 'STAFF') {
        return repository.loadBillsByStaff(user.id);
      } else {
        return repository.loadBillsByTenant(user.id);
      }
    });
  }

  Future<void> payBill(int billId, {required bool cash}) async {
    final repository = ref.read(billRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authState = ref.read(authProvider);
      final user = authState.value!;

      await repository.payBill(
        billId,
        cash: cash,
        staffId: user.role == 'STAFF' ? user.id : null,
      );

      // Kích hoạt UI tự cập nhật (Invalidate states)
      try {
        ref.invalidate(unpaidBillsProvider);
        ref.invalidate(tenantDashboardProvider);
        refreshOwnerDashboard(ref);
      } catch (e) {
        // ignore error
      }

      if (user.role == 'OWNER') {
        return repository.loadBillsByOwner(user.id);
      } else if (user.role == 'STAFF') {
        return repository.loadBillsByStaff(user.id);
      } else {
        return repository.loadBillsByTenant(user.id);
      }
    });
  }

  Future<void> payBillOnline(int billId) async {
    final repository = ref.read(billRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.payBillOnline(billId);
      final authState = ref.read(authProvider);
      final user = authState.value!;

      // Kích hoạt UI tự cập nhật
      try {
        ref.invalidate(unpaidBillsProvider);
        ref.invalidate(tenantDashboardProvider);
        refreshOwnerDashboard(ref);
      } catch (e) {
        // ignore error
      }

      if (user.role == 'OWNER') {
        return repository.loadBillsByOwner(user.id);
      } else if (user.role == 'STAFF') {
        return repository.loadBillsByStaff(user.id);
      } else {
        return repository.loadBillsByTenant(user.id);
      }
    });
  }

  Future<void> confirmCashPayment(int billId) async {
    final repository = ref.read(billRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authState = ref.read(authProvider);
      final user = authState.value!;
      await repository.confirmCashPayment(billId, user.id);

      // Kích hoạt UI tự cập nhật
      try {
        ref.invalidate(unpaidBillsProvider);
        ref.invalidate(tenantDashboardProvider);
        refreshOwnerDashboard(ref);
      } catch (e) {
        // ignore error
      }

      if (user.role == 'OWNER') {
        return repository.loadBillsByOwner(user.id);
      } else if (user.role == 'STAFF') {
        return repository.loadBillsByStaff(user.id);
      } else {
        return repository.loadBillsByTenant(user.id);
      }
    });
  }

  Future<void> updateUtilities(
    int billId,
    double? electricCurrent,
    double? waterCurrent,
  ) async {
    final repository = ref.read(billRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.updateUtilities(billId, electricCurrent, waterCurrent);
      final user = ref.read(authProvider).value!;
      return repository.loadBillsByOwner(user.id);
    });
  }

  Future<void> sendBill(int billId) async {
    final repository = ref.read(billRepositoryProvider);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await repository.sendBill(billId);
      final user = ref.read(authProvider).value!;
      return repository.loadBillsByOwner(user.id);
    });
  }

  Future<void> sendDebtReminder(int billId, String channel) async {
    // Mock network call cho Zalo ZNS / SMS
    await Future.delayed(const Duration(milliseconds: 1500));
  }
}
