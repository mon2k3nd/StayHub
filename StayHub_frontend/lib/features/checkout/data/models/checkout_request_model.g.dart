// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkout_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CheckoutRequestModel _$CheckoutRequestModelFromJson(
  Map<String, dynamic> json,
) => _CheckoutRequestModel(
  id: (json['id'] as num).toInt(),
  roomId: (json['roomId'] as num).toInt(),
  tenantId: (json['tenantId'] as num).toInt(),
  ownerId: (json['ownerId'] as num).toInt(),
  contractId: (json['contractId'] as num).toInt(),
  status: json['status'] as String,
  targetCheckoutDate: DateTime.parse(json['targetCheckoutDate'] as String),
  checkoutImages: json['checkoutImages'] as String?,
  tenantNote: json['tenantNote'] as String,
  ownerReason: json['ownerReason'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$CheckoutRequestModelToJson(
  _CheckoutRequestModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'roomId': instance.roomId,
  'tenantId': instance.tenantId,
  'ownerId': instance.ownerId,
  'contractId': instance.contractId,
  'status': instance.status,
  'targetCheckoutDate': instance.targetCheckoutDate.toIso8601String(),
  'checkoutImages': instance.checkoutImages,
  'tenantNote': instance.tenantNote,
  'ownerReason': instance.ownerReason,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
