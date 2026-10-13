import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';

final adminRiskAnalyticsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      final client = ref.watch(apiClientProvider);
      final response = await client.get('/v1/admin/analytics/risk?days=7');

      if (response['success'] == true) {
        final rawData = response['data'];
        if (rawData is Map<String, dynamic>) return rawData;
      }

      throw Exception(response['message'] ?? 'Không tải được dữ liệu rủi ro.');
    });
