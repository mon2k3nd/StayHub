import '../../data/models/room_model.dart';
import '../../data/models/roommate_model.dart';

abstract class RoomRepository {
  Future<List<RoomModel>> loadByBranch(int branchId);
  Future<List<RoomModel>> loadByOwner(int ownerId, {String? status});
  Future<RoomModel> loadRoomById(int roomId);
  Future<RoomModel> createRoom(
    Map<String, dynamic> data, {
    List<String>? imagePaths,
  });
  Future<RoomModel> updateRoom(int roomId, Map<String, dynamic> data);
  Future<RoomModel> configureRoom(int roomId, Map<String, dynamic> data);
  Future<List<String>> uploadRoomImages(int roomId, List<String> imagePaths);
  Future<RoomModel> approveRoom(int roomId, bool approved);
  Future<void> deleteRoom(int roomId);

  Future<List<RoommateModel>> loadRoommates(int contractId);
  Future<RoommateModel> createRoommate(Map<String, dynamic> data);
  Future<void> checkoutRoommate(int roommateId);
}
