import '../../data/models/post_model.dart';

/// Hợp đồng nghiệp vụ cho Bảng tin cộng đồng.
abstract class PostRepository {
  /// Lấy danh sách bài đăng (mới nhất trước).
  Future<List<PostModel>> getPosts();

  /// Tạo bài đăng mới với nội dung [content]. Trả về bài đăng vừa tạo.
  Future<PostModel> createPost(String content);

  /// Thích / bỏ thích bài đăng theo [postId].
  Future<void> toggleLike(int postId);
}
