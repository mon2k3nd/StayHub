// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(postRemoteDataSource)
final postRemoteDataSourceProvider = PostRemoteDataSourceProvider._();

final class PostRemoteDataSourceProvider
    extends
        $FunctionalProvider<
          PostRemoteDataSource,
          PostRemoteDataSource,
          PostRemoteDataSource
        >
    with $Provider<PostRemoteDataSource> {
  PostRemoteDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'postRemoteDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$postRemoteDataSourceHash();

  @$internal
  @override
  $ProviderElement<PostRemoteDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PostRemoteDataSource create(Ref ref) {
    return postRemoteDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PostRemoteDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PostRemoteDataSource>(value),
    );
  }
}

String _$postRemoteDataSourceHash() =>
    r'44e189c62ddeca506185e5fcb5054051011b9195';

@ProviderFor(postRepository)
final postRepositoryProvider = PostRepositoryProvider._();

final class PostRepositoryProvider
    extends $FunctionalProvider<PostRepository, PostRepository, PostRepository>
    with $Provider<PostRepository> {
  PostRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'postRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$postRepositoryHash();

  @$internal
  @override
  $ProviderElement<PostRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PostRepository create(Ref ref) {
    return postRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PostRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PostRepository>(value),
    );
  }
}

String _$postRepositoryHash() => r'69ec55f11af351e1f2eab1ccb6939452da85fe1b';

/// Quản lý danh sách bài đăng Bảng tin cộng đồng.
///
/// Tuân thủ pattern chuẩn của dự án (xem `BranchNotifier`):
/// - `build()` trả về `FutureOr<List<PostModel>>` → Riverpod tự sinh
///   `AsyncValue` (loading / data / error).
/// - Các thao tác ghi dùng `AsyncValue.guard` để bắt lỗi an toàn.

@ProviderFor(PostNotifier)
final postProvider = PostNotifierProvider._();

/// Quản lý danh sách bài đăng Bảng tin cộng đồng.
///
/// Tuân thủ pattern chuẩn của dự án (xem `BranchNotifier`):
/// - `build()` trả về `FutureOr<List<PostModel>>` → Riverpod tự sinh
///   `AsyncValue` (loading / data / error).
/// - Các thao tác ghi dùng `AsyncValue.guard` để bắt lỗi an toàn.
final class PostNotifierProvider
    extends $AsyncNotifierProvider<PostNotifier, List<PostModel>> {
  /// Quản lý danh sách bài đăng Bảng tin cộng đồng.
  ///
  /// Tuân thủ pattern chuẩn của dự án (xem `BranchNotifier`):
  /// - `build()` trả về `FutureOr<List<PostModel>>` → Riverpod tự sinh
  ///   `AsyncValue` (loading / data / error).
  /// - Các thao tác ghi dùng `AsyncValue.guard` để bắt lỗi an toàn.
  PostNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'postProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$postNotifierHash();

  @$internal
  @override
  PostNotifier create() => PostNotifier();
}

String _$postNotifierHash() => r'd3f4cacba07ea92eec4680eb605035316a366831';

/// Quản lý danh sách bài đăng Bảng tin cộng đồng.
///
/// Tuân thủ pattern chuẩn của dự án (xem `BranchNotifier`):
/// - `build()` trả về `FutureOr<List<PostModel>>` → Riverpod tự sinh
///   `AsyncValue` (loading / data / error).
/// - Các thao tác ghi dùng `AsyncValue.guard` để bắt lỗi an toàn.

abstract class _$PostNotifier extends $AsyncNotifier<List<PostModel>> {
  FutureOr<List<PostModel>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<PostModel>>, List<PostModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<PostModel>>, List<PostModel>>,
              AsyncValue<List<PostModel>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
