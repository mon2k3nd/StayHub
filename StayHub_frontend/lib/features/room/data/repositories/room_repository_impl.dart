import '../../domain/repositories/room_repository.dart';
import '../datasources/room_remote_data_source.dart';
import '../models/room_model.dart';
import '../models/roommate_model.dart';

class RoomRepositoryImpl implements RoomRepository {
  final RoomRemoteDataSource _remoteDataSource;

  const RoomRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<RoomModel>> loadByBranch(int branchId) async {
    final res = await _remoteDataSource.loadByBranch(branchId);
    final rawData = res['data'];
    if (rawData is! List) return [];
    return rawData
        .whereType<Map<String, dynamic>>()
        .map((e) => RoomModel.fromJson(e))
        .toList();
  }

  @override
  Future<List<RoomModel>> loadByOwner(int ownerId, {String? status}) async {
    final res = await _remoteDataSource.loadByOwner(ownerId, status: status);
    final rawData = res['data'];
    if (rawData is! List) return [];
    return rawData
        .whereType<Map<String, dynamic>>()
        .map((e) => RoomModel.fromJson(e))
        .toList();
  }

  @override
  Future<RoomModel> loadRoomById(int roomId) async {
    final res = await _remoteDataSource.loadRoomById(roomId);
    final rawData = res['data'];
    if (rawData is! Map<String, dynamic>) {
      throw Exception('Không tải được thông tin phòng.');
    }
    return RoomModel.fromJson(rawData);
  }

  @override
  Future<RoomModel> createRoom(
    Map<String, dynamic> data, {
    List<String>? imagePaths,
  }) async {
    final res = await _remoteDataSource.createRoom(
      data,
      imagePaths: imagePaths,
    );
    final rawData = res['data'];
    if (rawData is! Map<String, dynamic>) {
      throw Exception('Tạo phòng thất bại: dữ liệu không hợp lệ.');
    }
    return RoomModel.fromJson(rawData);
  }

  @override
  Future<RoomModel> updateRoom(int roomId, Map<String, dynamic> data) async {
    final res = await _remoteDataSource.updateRoom(roomId, data);
    final rawData = res['data'];
    if (rawData is! Map<String, dynamic>) {
      throw Exception('Cập nhật phòng thất bại.');
    }
    return RoomModel.fromJson(rawData);
  }

  @override
  Future<RoomModel> configureRoom(int roomId, Map<String, dynamic> data) async {
    final res = await _remoteDataSource.configureRoom(roomId, data);
    final rawData = res['data'];
    if (rawData is! Map<String, dynamic>) {
      throw Exception('Cấu hình phòng thất bại.');
    }
    return RoomModel.fromJson(rawData);
  }

  @override
  Future<List<String>> uploadRoomImages(
    int roomId,
    List<String> imagePaths,
  ) async {
    return _remoteDataSource.uploadRoomImages(roomId, imagePaths);
  }

  @override
  Future<void> deleteRoom(int roomId) async {
    await _remoteDataSource.deleteRoom(roomId);
  }

  @override
  Future<RoomModel> approveRoom(int roomId, bool approved) async {
    final res = await _remoteDataSource.approveRoom(roomId, approved);
    final rawData = res['data'];
    if (rawData is! Map<String, dynamic>) {
      throw Exception('Phê duyệt phòng thất bại.');
    }
    return RoomModel.fromJson(rawData);
  }

  @override
  Future<List<RoommateModel>> loadRoommates(int contractId) async {
    final res = await _remoteDataSource.loadRoommates(contractId);
    final rawData = res['data'];
    if (rawData is! List) return [];
    return rawData
        .whereType<Map<String, dynamic>>()
        .map((e) => RoommateModel.fromJson(e))
        .toList();
  }

  @override
  Future<RoommateModel> createRoommate(Map<String, dynamic> data) async {
    final res = await _remoteDataSource.createRoommate(data);
    final rawData = res['data'];
    if (rawData is! Map<String, dynamic>) {
      throw Exception('Thêm người ở cùng thất bại.');
    }
    return RoommateModel.fromJson(rawData);
  }

  @override
  Future<void> checkoutRoommate(int roommateId) async {
    await _remoteDataSource.checkoutRoommate(roommateId);
  }
}
