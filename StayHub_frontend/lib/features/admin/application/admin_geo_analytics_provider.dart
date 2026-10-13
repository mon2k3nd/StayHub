import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';

final adminGeoAnalyticsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      final client = ref.watch(apiClientProvider);
      final response = await client.get('/v1/admin/analytics/geo-heatmap');

      if (response['success'] == true) {
        final rawData = response['data'];
        if (rawData is Map<String, dynamic>) return rawData;
      }

      throw Exception(response['message'] ?? 'Không tải được dữ liệu bản đồ.');
    });
