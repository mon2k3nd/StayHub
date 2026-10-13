import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';

class RoomRemoteDataSource {
  final ApiClient _apiClient;

  const RoomRemoteDataSource(this._apiClient);

  Future<Map<String, dynamic>> loadByBranch(int branchId) async {
    return _apiClient.get('/v1/rooms/branch/$branchId');
  }

  Future<Map<String, dynamic>> loadByOwner(
    int ownerId, {
    String? status,
  }) async {
    final query = status != null ? {'status': status} : null;
    return _apiClient.get('/v1/rooms/owner/$ownerId', queryParameters: query);
  }

  Future<Map<String, dynamic>> loadRoomById(int roomId) async {
    return _apiClient.get('/v1/rooms/$roomId');
  }

  Future<Map<String, dynamic>> createRoom(
    Map<String, dynamic> data, {
    List<String>? imagePaths,
  }) async {
    final formData = FormData.fromMap({'room': jsonEncode(data)});

    if (imagePaths != null && imagePaths.isNotEmpty) {
      for (final path in imagePaths) {
        formData.files.add(
          MapEntry('images', await MultipartFile.fromFile(path)),
        );
      }
    }

    return _apiClient.uploadFile('/v1/rooms', formData);
  }

  Future<Map<String, dynamic>> updateRoom(
    int roomId,
    Map<String, dynamic> data,
  ) async {
    return _apiClient.put('/v1/rooms/$roomId', data: data);
  }

  Future<void> deleteRoom(int roomId) async {
    await _apiClient.delete('/v1/rooms/$roomId');
  }

  Future<Map<String, dynamic>> approveRoom(int roomId, bool approved) async {
    return _apiClient.put(
      '/v1/rooms/$roomId/approve',
      queryParameters: {'approved': approved},
    );
  }

  // Các endpoints cho Roommates
  Future<Map<String, dynamic>> loadRoommates(int contractId) async {
    return _apiClient.get('/v1/roommates/contract/$contractId');
  }

  Future<Map<String, dynamic>> createRoommate(Map<String, dynamic> data) async {
    return _apiClient.post('/v1/roommates', data: data);
  }

  Future<void> checkoutRoommate(int roommateId) async {
    await _apiClient.post('/v1/roommates/$roommateId/checkout');
  }

  Future<List<String>> uploadRoomImages(
    int roomId,
    List<String> imagePaths,
  ) async {
    final formData = FormData();
    for (final path in imagePaths) {
      formData.files.add(
        MapEntry('images', await MultipartFile.fromFile(path)),
      );
    }
    final res = await _apiClient.post(
      '/v1/rooms/$roomId/images',
      data: formData,
    );
    // BUGFIX (data): tránh `as List` ném TypeError khi `data` là null/không phải
    // List — trả về danh sách rỗng an toàn.
    final raw = res['data'];
    if (raw is! List) return <String>[];
    return raw.map((e) => e.toString()).toList();
  }

  Future<Map<String, dynamic>> configureRoom(
    int roomId,
    Map<String, dynamic> data,
  ) async {
    return _apiClient.put('/v1/rooms/$roomId/config', data: data);
  }
}
