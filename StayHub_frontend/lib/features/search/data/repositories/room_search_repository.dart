import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../domain/models/room_search_filter.dart';
import '../../domain/models/room_search_page.dart';

/// Provider cho repository tìm phòng (server-driven).
final roomSearchRepositoryProvider = Provider<RoomSearchRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return RoomSearchRepository(dio);
});

/// Repository gọi API tìm phòng công khai.
///
/// Toàn bộ việc lọc/sắp xếp/phân trang diễn ra ở backend
/// (`GET /v1/rooms/public/search`) nên kết quả luôn chính xác trên toàn bộ
/// tập dữ liệu, không phụ thuộc vào việc đã tải hết danh sách hay chưa.
class RoomSearchRepository {
  final Dio _dio;
  RoomSearchRepository(this._dio);

  /// Tìm phòng theo bộ lọc, trả về 1 trang kết quả.
  Future<RoomSearchPage> searchRooms(
    RoomSearchFilter filter, {
    int page = 0,
    int size = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/v1/rooms/public/search',
        queryParameters: filter.toQueryParameters(page: page, size: size),
      );
      final body = response.data;
      if (body is Map && body['success'] == true && body['data'] is Map) {
        return RoomSearchPage.fromJson(
          Map<String, dynamic>.from(body['data'] as Map),
          fallbackSize: size,
        );
      }
      return RoomSearchPage.empty;
    } on DioException catch (e) {
      throw Exception(_friendlyError(e));
    } catch (e) {
      throw Exception('Không thể tải danh sách phòng: $e');
    }
  }

  /// Metadata cho bộ lọc (khoảng giá/diện tích, loại phòng, tiện ích...).
  Future<Map<String, dynamic>> getFilterMetadata() async {
    try {
      final response = await _dio.get('/v1/rooms/public/filters');
      final body = response.data;
      if (body is Map && body['success'] == true && body['data'] is Map) {
        return Map<String, dynamic>.from(body['data'] as Map);
      }
      return const {};
    } on DioException catch (e) {
      throw Exception(_friendlyError(e));
    } catch (e) {
      throw Exception('Không thể tải cấu hình bộ lọc: $e');
    }
  }

  String _friendlyError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Kết nối quá lâu. Vui lòng thử lại.';
      case DioExceptionType.connectionError:
        return 'Không có kết nối mạng. Vui lòng kiểm tra lại.';
      case DioExceptionType.badResponse:
        return 'Máy chủ trả về lỗi (${e.response?.statusCode}).';
      default:
        return 'Lỗi kết nối máy chủ. Vui lòng thử lại.';
    }
  }
}
