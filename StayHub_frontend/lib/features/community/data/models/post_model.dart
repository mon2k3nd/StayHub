import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_model.freezed.dart';
part 'post_model.g.dart';

/// Model bài đăng Bảng tin cộng đồng.
///
/// Khớp 1-1 với entity backend `CommunityPost`
/// (`/v1/community-board`): id, authorName, authorRole, content,
/// likes, comments, createdAt.
@freezed
abstract class PostModel with _$PostModel {
  const factory PostModel({
    required int id,
    @Default('') String authorName,
    @Default('TENANT') String authorRole, // 'OWNER' | 'TENANT'
    @Default('') String content,
    @Default(0) int likes,
    @Default(0) int comments,
    DateTime? createdAt,

    /// Trạng thái "đã thích" của người dùng hiện tại — chỉ tồn tại ở client,
    /// backend chưa trả về nên mặc định false.
    @Default(false) bool isLikedByMe,
  }) = _PostModel;

  factory PostModel.fromJson(Map<String, dynamic> json) =>
      _$PostModelFromJson(json);
}

extension PostModelX on PostModel {
  /// True nếu bài đăng do chủ trọ / ban quản lý tạo.
  bool get isOwnerPost => authorRole.toUpperCase() == 'OWNER';

  /// Nhãn vai trò hiển thị trên UI.
  String get authorRoleLabel => isOwnerPost ? 'Ban Quản Lý' : 'Cư dân';
}
