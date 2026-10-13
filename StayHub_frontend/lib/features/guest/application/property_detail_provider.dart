import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';

import '../../../core/services/viewed_history_service.dart';
import 'dart:async' show unawaited;

final guestPropertyDetailProvider = FutureProvider.family
    .autoDispose<Map<String, dynamic>, int>((ref, id) async {
      final dio = ref.watch(dioProvider);
      try {
        final response = await dio.get('/v1/rooms/public/$id');
        // BUGFIX: `response.data` là `dynamic`; nếu backend trả về List/String
        // (hoặc null) thì `response.data['success']` ném NoSuchMethodError, và
        // `as Map<String, dynamic>` ném TypeError khi `data` không phải Map.
        // Guard bằng `is Map` trước khi truy cập để tránh crash cả màn chi tiết.
        final raw = response.data;
        if (raw is! Map) {
          throw Exception('Malformed response for property details');
        }
        final body = Map<String, dynamic>.from(raw);
        if (body['success'] == true) {
          final data = body['data'];
          if (data is! Map) {
            throw Exception('Malformed property data');
          }
          final roomData = Map<String, dynamic>.from(data);
          // unawaited(Bất đồng bộ lưu vào lịch sử (không cần await để không block UI))
          unawaited(ViewedHistoryService.addRoom(roomData).catchError((_) {}));
          return roomData;
        } else {
          throw Exception(body['message'] ?? 'Failed to load property details');
        }
      } catch (e) {
        throw Exception('Error loading property details: $e');
      }
    });
