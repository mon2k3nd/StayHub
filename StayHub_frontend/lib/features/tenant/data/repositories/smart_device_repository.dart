import 'package:dio/dio.dart';
import '../models/smart_device_model.dart';

class SmartDeviceRepository {
  final Dio _dio;

  SmartDeviceRepository(this._dio);

  Future<List<SmartDeviceModel>> getDevicesByRoom(int roomId) async {
    final response = await _dio.get('/v1/smart-devices/room/$roomId');
    // BUGFIX (data): tránh `as List`/`as Map` ném TypeError khi body không phải
    // List hoặc phần tử không phải Map — lọc an toàn bằng whereType.
    final raw = response.data;
    if (raw is! List) return <SmartDeviceModel>[];
    return raw
        .whereType<Map>()
        .map((e) => SmartDeviceModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<SmartDeviceModel> toggleDevice(int id, String newStatus) async {
    final response = await _dio.put(
      '/v1/smart-devices/$id/toggle',
      data: {'status': newStatus},
    );
    // BUGFIX (data): tránh `as Map<String, dynamic>` ném TypeError.
    final body = response.data;
    return SmartDeviceModel.fromJson(
      body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{},
    );
  }

  Future<SmartDeviceModel> updateSettings(
    int id,
    Map<String, dynamic> settings,
  ) async {
    final response = await _dio.put(
      '/v1/smart-devices/$id/settings',
      data: settings,
    );
    // BUGFIX (data): tránh `as Map<String, dynamic>` ném TypeError.
    final body = response.data;
    return SmartDeviceModel.fromJson(
      body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{},
    );
  }

  Future<void> seedDevices(int roomId) async {
    try {
      await _dio.post('/v1/smart-devices/room/$roomId/seed');
    } catch (e) {
      // Ignore if already seeded
    }
  }
}
