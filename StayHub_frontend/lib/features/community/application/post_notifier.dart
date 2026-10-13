import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/core_providers.dart';
import '../data/datasources/post_remote_data_source.dart';
import '../data/models/post_model.dart';
import '../data/repositories/post_repository_impl.dart';
import '../domain/repositories/post_repository.dart';

part 'post_notifier.g.dart';

// ─── Dependency Injection ────────────────────────────────────────────────────

@riverpod
PostRemoteDataSource postRemoteDataSource(Ref ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PostRemoteDataSource(apiClient);
}

@Riverpod(keepAlive: true)
PostRepository postRepository(Ref ref) {
  final remoteDataSource = ref.watch(postRemoteDataSourceProvider);
  return PostRepositoryImpl(remoteDataSource);
}

// ─── State Management ────────────────────────────────────────────────────────

/// Quản lý danh sách bài đăng Bảng tin cộng đồng.
///
/// Tuân thủ pattern chuẩn của dự án (xem `BranchNotifier`):
/// - `build()` trả về `FutureOr<List<PostModel>>` → Riverpod tự sinh
///   `AsyncValue` (loading / data / error).
/// - Các thao tác ghi dùng `AsyncValue.guard` để bắt lỗi an toàn.
@Riverpod(keepAlive: true)
class PostNotifier extends _$PostNotifier {
  @override
  FutureOr<List<PostModel>> build() async {
    final repository = ref.read(postRepositoryProvider);
    return await repository.getPosts();
  }

  /// Nạp lại danh sách bài đăng từ server.
  Future<void> refreshPosts() async {
    if (!state.hasValue) state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(postRepositoryProvider);
      return repository.getPosts();
    });
  }

  /// Tạo bài đăng mới. Trả về bài đăng vừa tạo (null nếu lỗi).
  ///
  /// Thêm bài mới lên đầu danh sách (optimistic) để UI cập nhật tức thì,
  /// sau đó đồng bộ lại với server.
  Future<PostModel?> createPost(String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return null;

    final repository = ref.read(postRepositoryProvider);
    PostModel? createdPost;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      createdPost = await repository.createPost(trimmed);
      final currentList = state.value ?? const <PostModel>[];
      return [createdPost!, ...currentList];
    });

    return createdPost;
  }

  /// Thích / bỏ thích bài đăng (optimistic update + revert khi lỗi).
  Future<void> toggleLike(int postId) async {
    final currentList = state.value;
    if (currentList == null) return;

    final index = currentList.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final post = currentList[index];
    final newIsLiked = !post.isLikedByMe;
    final newLikes = newIsLiked
        ? post.likes + 1
        : (post.likes - 1).clamp(0, 1 << 31);

    final updatedPost = post.copyWith(isLikedByMe: newIsLiked, likes: newLikes);
    final newList = List<PostModel>.from(currentList);
    newList[index] = updatedPost;

    // Optimistic update
    state = AsyncData(newList);

    try {
      final repository = ref.read(postRepositoryProvider);
      await repository.toggleLike(postId);
    } catch (e) {
      // Revert nếu gọi API thất bại
      debugPrint('toggleLike error: $e');
      state = AsyncData(currentList);
    }
  }
}
