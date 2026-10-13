import '../../../../core/network/api_client.dart';

/// Tầng gọi API thô cho Bảng tin cộng đồng.
///
/// Chỉ chịu trách nhiệm gọi HTTP qua [ApiClient] và trả về Map/List thô.
/// Việc parse model nằm ở Repository.
class PostRemoteDataSource {
  final ApiClient _apiClient;

  const PostRemoteDataSource(this._apiClient);

  /// Lấy danh sách bài đăng (mới nhất trước).
  Future<Map<String, dynamic>> getPosts() async {
    return _apiClient.get('/v1/community-board');
  }

  /// Tạo bài đăng mới.
  Future<Map<String, dynamic>> createPost(Map<String, dynamic> data) async {
    return _apiClient.post('/v1/community-board', data: data);
  }

  /// Thích / bỏ thích bài đăng.
  Future<Map<String, dynamic>> toggleLike(int postId) async {
    return _apiClient.post('/v1/community-board/$postId/like');
  }
}
