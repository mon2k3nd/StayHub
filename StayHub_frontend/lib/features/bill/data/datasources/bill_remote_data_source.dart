import '../../../../core/network/api_client.dart';

class BillRemoteDataSource {
  final ApiClient _apiClient;

  const BillRemoteDataSource(this._apiClient);

  Future<Map<String, dynamic>> loadBillsByTenant(int tenantId) async {
    return _apiClient.get('/v1/bills/tenant/$tenantId');
  }

  Future<Map<String, dynamic>> loadBillsByOwner(int ownerId) async {
    return _apiClient.get('/v1/bills/owner/$ownerId');
  }

  Future<Map<String, dynamic>> loadBillsByStaff(int staffId) async {
    return _apiClient.get('/v1/bills/staff/$staffId');
  }

  Future<Map<String, dynamic>> payBill(
    int billId,
    bool cash, {
    int? staffId,
  }) async {
    return _apiClient.post(
      '/v1/bills/$billId/pay-cash',
      data: {if (staffId != null) 'collectedByStaffId': staffId},
    );
  }

  Future<Map<String, dynamic>> payBillOnline(int billId) async {
    return _apiClient.post(
      '/v1/bills/$billId/simulate-online-payment',
      data: {},
    );
  }

  Future<Map<String, dynamic>> confirmCash(int billId, int ownerId) async {
    return _apiClient.post(
      '/v1/bills/$billId/confirm-cash',
      data: {'ownerId': ownerId},
    );
  }

  Future<Map<String, dynamic>> updateUtilities(
    int billId,
    double? electricCurrent,
    double? waterCurrent,
  ) async {
    return _apiClient.put(
      '/v1/bills/$billId/utilities',
      data: {
        if (electricCurrent != null) 'electricCurrent': electricCurrent,
        if (waterCurrent != null) 'waterCurrent': waterCurrent,
      },
    );
  }

  Future<Map<String, dynamic>> sendBill(int billId) async {
    return _apiClient.post('/v1/bills/$billId/send', data: {});
  }

  Future<Map<String, dynamic>> getMeterReadings(
    int branchId,
    int month,
    int year,
  ) async {
    return _apiClient.get(
      '/v1/bills/branch/$branchId/meter-readings?month=$month&year=$year',
    );
  }

  Future<Map<String, dynamic>> generateBills(
    int branchId,
    int month,
    int year,
  ) async {
    return _apiClient.post(
      '/v1/bills/branch/$branchId/generate?month=$month&year=$year',
      data: {},
    );
  }

  Future<Map<String, dynamic>> updateUtilitiesByRoom(
    int roomId,
    double? electricCurrent,
    double? waterCurrent, {
    String? electricImage,
    String? waterImage,
  }) async {
    return _apiClient.put(
      '/v1/bills/room/$roomId/utilities',
      data: {
        if (electricCurrent != null) 'electricCurrent': electricCurrent,
        if (waterCurrent != null) 'waterCurrent': waterCurrent,
        if (electricImage != null) 'electricImage': electricImage,
        if (waterImage != null) 'waterImage': waterImage,
      },
    );
  }
}
