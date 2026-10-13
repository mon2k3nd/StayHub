import '../../../../core/network/api_client.dart';

class ContractRemoteDataSource {
  final ApiClient _apiClient;

  const ContractRemoteDataSource(this._apiClient);

  Future<Map<String, dynamic>> loadByOwner(int ownerId) async {
    return _apiClient.get('/v1/contracts/owner/$ownerId');
  }

  Future<Map<String, dynamic>> loadByTenant(int tenantId) async {
    return _apiClient.get('/v1/contracts/tenant/$tenantId');
  }

  Future<Map<String, dynamic>> createContract(Map<String, dynamic> data) async {
    return _apiClient.post('/v1/contracts', data: data);
  }

  Future<Map<String, dynamic>> terminateContract(
    int contractId,
    String reason,
  ) async {
    return _apiClient.post(
      '/v1/contracts/$contractId/terminate',
      data: {'reason': reason},
    );
  }

  Future<Map<String, dynamic>> renewContract(int contractId, int months) async {
    return _apiClient.post(
      '/v1/contracts/$contractId/renew',
      data: {'months': months},
    );
  }

  Future<Map<String, dynamic>> createRentalRequest(
    Map<String, dynamic> data,
  ) async {
    return _apiClient.post('/v1/rental-requests', data: data);
  }
}
