import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_model.freezed.dart';
part 'notification_model.g.dart';

@freezed
abstract class NotificationModel with _$NotificationModel {
  const factory NotificationModel({
    required int id,
    int? senderId,
    required int receiverId,
    String? scope,
    required String title,
    required String content,
    required String type,
    int? refId,
    @Default(false) bool isActionable,
    String? actionStatus,
    String? actionMetadata,
    @Default(false) bool isRead,
    required String createdAt,
  }) = _NotificationModel;

  /// Defensive JSON parser.
  ///
  /// The backend occasionally omits or nulls fields (e.g. `content`,
  /// `createdAt`, `receiverId`). The generated `_$NotificationModelFromJson`
  /// performs hard casts and would throw on a null, which would fail the whole
  /// notification list. This wrapper coerces every field to a safe value so a
  /// single malformed record can never break the entire feed.
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v, {int fallback = 0}) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    String asString(Object? v, {String fallback = ''}) {
      if (v == null) return fallback;
      if (v is String) return v;
      return v.toString();
    }

    bool asBool(Object? v, {bool fallback = false}) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      if (v is String) {
        final lower = v.toLowerCase();
        if (lower == 'true' || lower == '1') return true;
        if (lower == 'false' || lower == '0') return false;
      }
      return fallback;
    }

    return NotificationModel(
      id: asInt(json['id']),
      senderId: json['senderId'] == null ? null : asInt(json['senderId']),
      receiverId: asInt(json['receiverId']),
      scope: json['scope'] == null ? null : asString(json['scope']),
      title: asString(json['title'], fallback: 'Thông báo'),
      content: asString(json['content']),
      type: asString(json['type'], fallback: 'SYSTEM'),
      refId: json['refId'] == null ? null : asInt(json['refId']),
      isActionable: asBool(json['isActionable']),
      actionStatus: json['actionStatus'] == null
          ? null
          : asString(json['actionStatus']),
      actionMetadata: json['actionMetadata'] == null
          ? null
          : asString(json['actionMetadata']),
      isRead: asBool(json['isRead']),
      createdAt: asString(
        json['createdAt'],
        fallback: DateTime.now().toIso8601String(),
      ),
    );
  }
}
