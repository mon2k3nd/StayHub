import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return MarketplaceRepository(dio);
});

class MarketplaceRepository {
  final Dio _dio;
  MarketplaceRepository(this._dio);

  Future<List<dynamic>> getPosts() async {
    try {
      final response = await _dio.get('/v1/marketplace/posts');
      if (response.data['success'] == true) {
        final List<dynamic> rawData = response.data['data'];
        // Map the backend DTO to match what GuestPropertyCard expects
        return rawData.map((post) {
          // Try to parse price if it's a formatted string like "15,000,000 đ"
          double parsedPrice = 0.0;
          if (post['price'] != null) {
            String pStr = post['price'].toString().replaceAll(
              RegExp(r'[^0-9]'),
              '',
            );
            if (pStr.isNotEmpty) parsedPrice = double.parse(pStr);
          }

          return {
            'id': post['id'],
            'roomName': post['title'], // Map title -> roomName
            'address':
                post['content'] != null &&
                    post['content'].toString().length > 30
                ? '${post['content'].toString().substring(0, 30)}...'
                : post['content'], // Map content -> address
            'price': parsedPrice,
            'bedrooms': 1,
            'bathrooms': 1,
            'floor': 1,
            'coverImageUrl':
                'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?q=80&w=2070&auto=format&fit=crop', // Use placeholder since backend doesn't have image yet
            'tag': post['tag'],
            'tagColor': post['tagColor'],
          };
        }).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Lỗi kết nối Server: $e');
    }
  }

  Future<dynamic> createPost(Map<String, dynamic> data) async {
    final response = await _dio.post('/v1/marketplace/posts', data: data);
    return response.data['data'];
  }
}
