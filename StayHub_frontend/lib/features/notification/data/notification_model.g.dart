// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NotificationModel _$NotificationModelFromJson(Map<String, dynamic> json) =>
    _NotificationModel(
      id: (json['id'] as num).toInt(),
      senderId: (json['senderId'] as num?)?.toInt(),
      receiverId: (json['receiverId'] as num).toInt(),
      scope: json['scope'] as String?,
      title: json['title'] as String,
      content: json['content'] as String,
      type: json['type'] as String,
      refId: (json['refId'] as num?)?.toInt(),
      isActionable: json['isActionable'] as bool? ?? false,
      actionStatus: json['actionStatus'] as String?,
      actionMetadata: json['actionMetadata'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] as String,
    );

Map<String, dynamic> _$NotificationModelToJson(_NotificationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'senderId': instance.senderId,
      'receiverId': instance.receiverId,
      'scope': instance.scope,
      'title': instance.title,
      'content': instance.content,
      'type': instance.type,
      'refId': instance.refId,
      'isActionable': instance.isActionable,
      'actionStatus': instance.actionStatus,
      'actionMetadata': instance.actionMetadata,
      'isRead': instance.isRead,
      'createdAt': instance.createdAt,
    };
