// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signature_history_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SignatureHistoryModel _$SignatureHistoryModelFromJson(
  Map<String, dynamic> json,
) => _SignatureHistoryModel(
  id: (json['id'] as num).toInt(),
  userId: (json['userId'] as num).toInt(),
  signature: json['signature'] as String,
  createdAt: json['createdAt'] as String,
);

Map<String, dynamic> _$SignatureHistoryModelToJson(
  _SignatureHistoryModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'signature': instance.signature,
  'createdAt': instance.createdAt,
};
