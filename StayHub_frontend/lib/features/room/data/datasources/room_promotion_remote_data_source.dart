import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/network/api_client.dart';
import '../models/room_promotion_model.dart';

final roomPromotionRemoteDataSourceProvider =
    Provider<RoomPromotionRemoteDataSource>((ref) {
      return RoomPromotionRemoteDataSource(ref.read(apiClientProvider));
    });

class RoomPromotionRemoteDataSource {
  final ApiClient _apiClient;

  RoomPromotionRemoteDataSource(this._apiClient);

  Future<RoomPromotionModel> createOrUpdatePromotion(
    int roomId,
    RoomPromotionRequest request,
  ) async {
    final response = await _apiClient.post(
      '/v1/promotions/rooms/$roomId',
      data: request.toJson(),
    );
    return RoomPromotionModel.fromJson(response['data']);
  }

  Future<RoomPromotionModel?> getActivePromotion(int roomId) async {
    final response = await _apiClient.get('/v1/promotions/rooms/$roomId');
    if (response['data'] == null) return null;
    return RoomPromotionModel.fromJson(response['data']);
  }

  Future<void> deactivatePromotion(int roomId) async {
    await _apiClient.delete('/v1/promotions/rooms/$roomId');
  }
}
