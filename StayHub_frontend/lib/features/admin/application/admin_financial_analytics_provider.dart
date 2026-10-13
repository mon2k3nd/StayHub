import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';

final adminFinancialAnalyticsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      final client = ref.watch(apiClientProvider);
      try {
        final response = await client.get(
          '/v1/admin/analytics/financial?days=7',
        );
        if (response['success'] == true) {
          final rawData = response['data'];
          if (rawData is Map<String, dynamic>) return rawData;
        }
      } catch (e) {
        throw Exception('Lỗi kết nối hoặc dữ liệu: $e');
      }

      throw Exception('Không tải được dữ liệu tài chính.');
    });
