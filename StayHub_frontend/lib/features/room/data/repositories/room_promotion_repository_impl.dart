import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/room_promotion_repository.dart';
import '../datasources/room_promotion_remote_data_source.dart';
import '../models/room_promotion_model.dart';

final roomPromotionRepositoryProvider = Provider<RoomPromotionRepository>((
  ref,
) {
  return RoomPromotionRepositoryImpl(
    ref.read(roomPromotionRemoteDataSourceProvider),
  );
});

class RoomPromotionRepositoryImpl implements RoomPromotionRepository {
  final RoomPromotionRemoteDataSource _remoteDataSource;

  const RoomPromotionRepositoryImpl(this._remoteDataSource);

  @override
  Future<RoomPromotionModel> createOrUpdatePromotion(
    int roomId,
    RoomPromotionRequest request,
  ) {
    return _remoteDataSource.createOrUpdatePromotion(roomId, request);
  }

  @override
  Future<RoomPromotionModel?> getActivePromotion(int roomId) {
    return _remoteDataSource.getActivePromotion(roomId);
  }

  @override
  Future<void> deactivatePromotion(int roomId) {
    return _remoteDataSource.deactivatePromotion(roomId);
  }
}
