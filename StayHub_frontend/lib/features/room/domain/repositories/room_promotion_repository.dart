import '../../data/models/room_promotion_model.dart';

abstract class RoomPromotionRepository {
  Future<RoomPromotionModel> createOrUpdatePromotion(
    int roomId,
    RoomPromotionRequest request,
  );
  Future<RoomPromotionModel?> getActivePromotion(int roomId);
  Future<void> deactivatePromotion(int roomId);
}
