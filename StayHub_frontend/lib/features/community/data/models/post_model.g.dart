// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PostModel _$PostModelFromJson(Map<String, dynamic> json) => _PostModel(
  id: (json['id'] as num).toInt(),
  authorName: json['authorName'] as String? ?? '',
  authorRole: json['authorRole'] as String? ?? 'TENANT',
  content: json['content'] as String? ?? '',
  likes: (json['likes'] as num?)?.toInt() ?? 0,
  comments: (json['comments'] as num?)?.toInt() ?? 0,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  isLikedByMe: json['isLikedByMe'] as bool? ?? false,
);

Map<String, dynamic> _$PostModelToJson(_PostModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'authorName': instance.authorName,
      'authorRole': instance.authorRole,
      'content': instance.content,
      'likes': instance.likes,
      'comments': instance.comments,
      'createdAt': instance.createdAt?.toIso8601String(),
      'isLikedByMe': instance.isLikedByMe,
    };
