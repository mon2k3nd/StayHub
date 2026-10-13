import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';

final advancedAnalyticsRepositoryProvider = Provider((ref) {
  return AdvancedAnalyticsRepository(ref.watch(dioProvider));
});

class AdvancedAnalyticsRepository {
  final Dio _dio;
  AdvancedAnalyticsRepository(this._dio);

  Future<Map<String, dynamic>> getOwnerFinancial() async {
    final res = await _dio.get('/v1/analytics/advanced/owner/financial');
    return res.data['data'];
  }

  Future<Map<String, dynamic>> getOwnerOccupancy() async {
    final res = await _dio.get('/v1/analytics/advanced/owner/occupancy');
    return res.data['data'];
  }

  Future<Map<String, dynamic>> getOwnerOps() async {
    final res = await _dio.get('/v1/analytics/advanced/owner/ops');
    return res.data['data'];
  }

  Future<Map<String, dynamic>> getAdminSaas() async {
    final res = await _dio.get('/v1/analytics/advanced/admin/saas');
    return res.data['data'];
  }

  Future<Map<String, dynamic>> getOwnerForecast() async {
    // Mock data cho Forecast & Trends Tab
    await Future.delayed(const Duration(milliseconds: 600));
    return {
      'revenueMoM': 5.2, // Tăng 5.2% so với tháng trước
      'revenueYoY': 12.8, // Tăng 12.8% so với năm trước
      'occupancyForecast': 92, // Dự báo lấp đầy tháng sau
      'churnRisk': 3, // Số phòng có rủi ro rời đi cao
      'recommendations': [
        'Giảm 5% giá phòng tại Cơ sở 2 để lấp đầy 3 phòng trống.',
        'Chi phí bảo trì tăng đột biến 15% - Cần rà soát đường ống nước.',
      ],
      'alerts': [
        {
          'type': 'WARNING',
          'message': 'Doanh thu Dãy B giảm 8% so với tháng trước.',
        },
        {
          'type': 'SUCCESS',
          'message': 'Tỉ lệ lấp đầy toàn hệ thống đạt mức cao nhất (95%).',
        },
      ],
    };
  }
}
