import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';

final ownerPostsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/v1/room-posts/owner');
  final data = response.data['data'];
  if (data is List) {
    return data;
  }
  return [];
});
