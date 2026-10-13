import '../../domain/repositories/post_repository.dart';
import '../datasources/post_remote_data_source.dart';
import '../models/post_model.dart';

class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource _remoteDataSource;

  const PostRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<PostModel>> getPosts() async {
    final res = await _remoteDataSource.getPosts();
    final rawData = res['data'];
    if (rawData is! List) return [];
    return rawData
        .whereType<Map<String, dynamic>>()
        .map(PostModel.fromJson)
        .toList();
  }

  @override
  Future<PostModel> createPost(String content) async {
    final res = await _remoteDataSource.createPost({'content': content});
    final rawData = res['data'];
    if (rawData is! Map<String, dynamic>) {
      throw Exception('Tạo bài đăng thất bại: dữ liệu không hợp lệ.');
    }
    return PostModel.fromJson(rawData);
  }

  @override
  Future<void> toggleLike(int postId) async {
    await _remoteDataSource.toggleLike(postId);
  }
}
