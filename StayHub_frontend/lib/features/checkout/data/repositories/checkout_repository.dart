import 'package:dio/dio.dart';
import '../models/checkout_request_model.dart';

class CheckoutRepository {
  final Dio _dio;

  CheckoutRepository(this._dio);

  Future<CheckoutRequestModel> createRequest(
    Map<String, dynamic> data,
    List<String> filePaths,
  ) async {
    FormData formData = FormData.fromMap({
      'contractId': data['contractId'],
      'targetCheckoutDate': data['targetCheckoutDate'],
      'tenantNote': data['tenantNote'],
    });

    for (var path in filePaths) {
      formData.files.add(MapEntry('files', await MultipartFile.fromFile(path)));
    }

    final response = await _dio.post('/v1/checkouts', data: formData);
    return CheckoutRequestModel.fromJson(response.data['data']);
  }

  Future<List<CheckoutRequestModel>> getRequestsForOwner(int ownerId) async {
    final response = await _dio.get('/v1/checkouts/owner/$ownerId');
    final List<dynamic> data = response.data['data'];
    return data.map((json) => CheckoutRequestModel.fromJson(json)).toList();
  }

  Future<List<CheckoutRequestModel>> getRequestsForTenant(int tenantId) async {
    final response = await _dio.get('/v1/checkouts/tenant/$tenantId');
    final List<dynamic> data = response.data['data'];
    return data.map((json) => CheckoutRequestModel.fromJson(json)).toList();
  }

  Future<CheckoutRequestModel> rejectRequest(int id, String ownerReason) async {
    final response = await _dio.put(
      '/v1/checkouts/$id/reject',
      data: {'ownerReason': ownerReason},
    );
    return CheckoutRequestModel.fromJson(response.data['data']);
  }

  Future<Map<String, dynamic>> approveAndCreateBill(
    int id,
    Map<String, dynamic> billData,
  ) async {
    final response = await _dio.post(
      '/v1/checkouts/$id/approve-and-bill',
      data: billData,
    );
    return response.data['data'];
  }

  Future<String> analyzeImagesWithAI(int id) async {
    final response = await _dio.get('/v1/checkouts/$id/ai-analyze');
    return response.data['data'];
  }
}
