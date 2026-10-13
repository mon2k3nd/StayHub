import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/application/auth_notifier.dart';
import '../../staff/application/staff_assignment_notifier.dart';
import '../data/datasources/contract_remote_data_source.dart';
import '../data/models/contract_model.dart';
import '../data/repositories/contract_repository_impl.dart';
import '../domain/repositories/contract_repository.dart';

part 'contract_notifier.g.dart';

@riverpod
ContractRemoteDataSource contractRemoteDataSource(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ContractRemoteDataSource(apiClient);
}

@riverpod
ContractRepository contractRepository(Ref ref) {
  final remoteDataSource = ref.watch(contractRemoteDataSourceProvider);
  return ContractRepositoryImpl(remoteDataSource);
}

@riverpod
class ContractNotifier extends _$ContractNotifier {
  @override
  FutureOr<List<ContractModel>> build() async {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    if (user == null) return [];

    final repository = ref.read(contractRepositoryProvider);
    if (user.role == 'OWNER') {
      return await repository.loadByOwner(user.id);
    } else if (user.role == 'STAFF') {
      // Staff: l?y contract theo ownerId t? assignment
      final assignments = ref.read(staffAssignmentProvider).assignments;
      if (assignments.isEmpty) return [];
      final ownerId = assignments.first.ownerId;
      return await repository.loadByOwner(ownerId);
    } else {
      return await repository.loadByTenant(user.id);
    }
  }

  Future<void> refreshContracts() async {
    final authState = ref.read(authProvider);
    final user = authState.value;
    if (user == null) return;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(contractRepositoryProvider);
      if (user.role == 'OWNER') {
        return repository.loadByOwner(user.id);
      } else if (user.role == 'STAFF') {
        final assignments = ref.read(staffAssignmentProvider).assignments;
        if (assignments.isEmpty) return [];
        final ownerId = assignments.first.ownerId;
        return repository.loadByOwner(ownerId);
      } else {
        return repository.loadByTenant(user.id);
      }
    });
  }

  Future<bool> terminateContract(int contractId, String reason) async {
    final repository = ref.read(contractRepositoryProvider);
    try {
      state = const AsyncValue.loading();
      await repository.terminateContract(contractId, reason);
      await refreshContracts();
      return true;
    } catch (e, stack) {
      debugPrint('terminateContract error: $e\n$stack');
      await refreshContracts();
      return false;
    }
  }

  Future<bool> renewContract(int contractId, int months) async {
    final repository = ref.read(contractRepositoryProvider);
    try {
      state = const AsyncValue.loading();
      await repository.renewContract(contractId, months);
      await refreshContracts();
      return true;
    } catch (e, stack) {
      debugPrint('renewContract error: $e\n$stack');
      await refreshContracts();
      return false;
    }
  }

  Future<void> createRentalRequest(Map<String, dynamic> data) async {
    final repository = ref.read(contractRepositoryProvider);
    await repository.createRentalRequest(data);
  }

  Future<bool> createContract(Map<String, dynamic> data) async {
    final repository = ref.read(contractRepositoryProvider);
    try {
      state = const AsyncValue.loading();
      await repository.createContract(data);
      await refreshContracts();
      return true;
    } catch (e, stack) {
      debugPrint('createContract error: $e\n$stack');
      await refreshContracts();
      return false;
    }
  }
}
