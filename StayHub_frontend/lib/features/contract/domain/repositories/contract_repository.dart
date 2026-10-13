import '../../data/models/contract_model.dart';

abstract class ContractRepository {
  Future<List<ContractModel>> loadByOwner(int ownerId);
  Future<List<ContractModel>> loadByTenant(int tenantId);
  Future<ContractModel> createContract(Map<String, dynamic> data);
  Future<ContractModel> terminateContract(int contractId, String reason);
  Future<ContractModel> renewContract(int contractId, int months);
  Future<void> createRentalRequest(Map<String, dynamic> data);
}
