import 'package:dio/dio.dart';

class HousekeepingRemoteDataSource {
  final Dio dio;

  HousekeepingRemoteDataSource(this.dio);

  Future<List<dynamic>> getTasksByBranch(int branchId) async {
    final response = await dio.get(
      '/v1/staff/housekeeping/tasks',
      queryParameters: {'branchId': branchId},
    );
    // BUGFIX (data): tránh `as List<dynamic>` ném TypeError khi `data`
    // null/không phải List — trả [] để màn hình không vỡ.
    final raw = response.data is Map ? response.data['data'] : null;
    return raw is List ? raw : const <dynamic>[];
  }

  Future<dynamic> updateTaskStatus(int taskId, String status) async {
    final response = await dio.put(
      '/v1/staff/housekeeping/tasks/$taskId/status',
      data: {'status': status},
    );
    return response.data['data'];
  }

  Future<dynamic> updateChecklist(
    int taskId,
    List<Map<String, dynamic>> checklist,
  ) async {
    final response = await dio.put(
      '/v1/staff/housekeeping/tasks/$taskId/checklist',
      data: checklist,
    );
    return response.data['data'];
  }
}
