import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AttendanceRepository(dio);
});

class AttendanceRepository {
  final Dio _dio;
  AttendanceRepository(this._dio);

  Future<dynamic> checkIn(Map<String, dynamic> data) async {
    final response = await _dio.post('/v1/attendance/check-in', data: data);
    return response.data['data'];
  }

  Future<dynamic> checkOut(Map<String, dynamic> data) async {
    final response = await _dio.post('/v1/attendance/check-out', data: data);
    return response.data['data'];
  }

  Future<dynamic> getCurrentStatus() async {
    final response = await _dio.get('/v1/attendance/status');
    return response.data['data'];
  }

  Future<List<dynamic>> getMyLogs() async {
    final response = await _dio.get('/v1/attendance/logs');
    // BUGFIX (data): tránh `as List<dynamic>` ném TypeError khi `data`
    // null/không phải List — trả [] để màn hình không vỡ.
    final raw = response.data is Map ? response.data['data'] : null;
    return raw is List ? raw : const <dynamic>[];
  }
}
