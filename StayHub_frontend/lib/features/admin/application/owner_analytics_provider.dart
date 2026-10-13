import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';

final ownerAnalyticsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, ownerId) async {
      final client = ref.watch(apiClientProvider);
      final response = await client.get(
        '/v1/admin/analytics/owners/$ownerId?days=30',
      );

      if (response['success'] == true) {
        final rawData = response['data'];
        if (rawData is Map<String, dynamic>) return rawData;
      }

      throw Exception(response['message'] ?? 'Không tải được dữ liệu chủ nhà.');
    });
