import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/core_providers.dart';

part 'room_member_provider.g.dart';

@riverpod
class RoomMemberNotifier extends _$RoomMemberNotifier {
  @override
  FutureOr<List<Map<String, dynamic>>> build(int roomId) async {
    return _fetchMembers();
  }

  Future<List<Map<String, dynamic>>> _fetchMembers() async {
    final dio = ref.read(dioProvider);
    final resp = await dio.get('/v1/roommates/room/$roomId');
    // BUGFIX (data): tránh `as List`/`as Map` ném TypeError khi `data` là null
    // hoặc phần tử không phải Map — lọc an toàn bằng whereType.
    final raw = (resp.data is Map && resp.data['data'] is List)
        ? resp.data['data'] as List
        : const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<bool> addMember(Map<String, dynamic> memberData) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/v1/roommates/room/$roomId', data: memberData);
      ref.invalidateSelf();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateMember(
    int memberId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.put('/v1/roommates/$memberId', data: updateData);
      ref.invalidateSelf();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkoutMember(int memberId) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.put('/v1/roommates/$memberId/checkout');
      ref.invalidateSelf();
      return true;
    } catch (e) {
      return false;
    }
  }
}
