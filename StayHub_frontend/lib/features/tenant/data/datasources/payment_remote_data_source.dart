import 'package:dio/dio.dart';

class PaymentRemoteDataSource {
  final Dio dio;

  PaymentRemoteDataSource(this.dio);

  Future<dynamic> simulateOnlinePayment(int billId) async {
    final response = await dio.post(
      '/v1/bills/$billId/simulate-online-payment',
    );
    return response.data['data'];
  }

  Future<int?> getLatestPendingBillId(int tenantId) async {
    try {
      final res = await dio.get('/v1/bills/tenant/$tenantId/unpaid');
      // BUGFIX (data): `data` có thể null/không phải List, và `id` có thể là
      // String → tránh TypeError khi backend trả payload rỗng.
      final body = res.data;
      final data = body is Map ? body['data'] : null;
      if (data is List && data.isNotEmpty) {
        final first = data.first;
        if (first is Map) {
          final rawId = first['id'];
          return rawId is num
              ? rawId.toInt()
              : int.tryParse(rawId?.toString() ?? '');
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
