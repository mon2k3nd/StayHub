import '../../domain/repositories/contract_repository.dart';
import '../datasources/contract_remote_data_source.dart';
import '../models/contract_model.dart';

class ContractRepositoryImpl implements ContractRepository {
  final ContractRemoteDataSource _remoteDataSource;

  const ContractRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<ContractModel>> loadByOwner(int ownerId) async {
    final res = await _remoteDataSource.loadByOwner(ownerId);
    final rawData = res['data'];
    if (rawData is! List) return [];
    return rawData.whereType<Map<String, dynamic>>().map((e) {
      final map = Map<String, dynamic>.from(e);
      if (map['roomName'] == null && map['room'] != null) {
        map['roomName'] = map['room']['roomName'];
      }
      if (map['branchName'] == null && map['room'] != null) {
        map['branchName'] = map['room']['branchName'];
      }
      return ContractModel.fromJson(map);
    }).toList();
  }

  @override
  Future<List<ContractModel>> loadByTenant(int tenantId) async {
    final res = await _remoteDataSource.loadByTenant(tenantId);
    final rawData = res['data'];
    if (rawData is! List) return [];
    return rawData.whereType<Map<String, dynamic>>().map((e) {
      final map = Map<String, dynamic>.from(e);
      if (map['roomName'] == null && map['room'] != null) {
        map['roomName'] = map['room']['roomName'];
      }
      if (map['branchName'] == null && map['room'] != null) {
        map['branchName'] = map['room']['branchName'];
      }
      return ContractModel.fromJson(map);
    }).toList();
  }

  @override
  Future<ContractModel> createContract(Map<String, dynamic> data) async {
    final res = await _remoteDataSource.createContract(data);
    final rawData = res['data'];
    if (rawData is! Map<String, dynamic>) {
      throw Exception('T?o h?p d?ng th?t b?i.');
    }
    return ContractModel.fromJson(rawData);
  }

  @override
  Future<ContractModel> terminateContract(int contractId, String reason) async {
    final res = await _remoteDataSource.terminateContract(contractId, reason);
    final rawData = res['data'];
    if (rawData is! Map<String, dynamic>) {
      throw Exception('Ch?m d?t h?p d?ng th?t b?i.');
    }
    return ContractModel.fromJson(rawData);
  }

  @override
  Future<ContractModel> renewContract(int contractId, int months) async {
    final res = await _remoteDataSource.renewContract(contractId, months);
    final rawData = res['data'];
    if (rawData is! Map<String, dynamic>) {
      throw Exception('Gia h?n h?p d?ng th?t b?i.');
    }
    return ContractModel.fromJson(rawData);
  }

  @override
  Future<void> createRentalRequest(Map<String, dynamic> data) async {
    await _remoteDataSource.createRentalRequest(data);
  }
}
