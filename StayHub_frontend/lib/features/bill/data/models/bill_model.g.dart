// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bill_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BillModel _$BillModelFromJson(Map<String, dynamic> json) => _BillModel(
  id: (json['id'] as num).toInt(),
  roomId: (json['roomId'] as num).toInt(),
  contractId: (json['contractId'] as num?)?.toInt(),
  tenantId: (json['tenantId'] as num?)?.toInt(),
  month: (json['month'] as num).toInt(),
  year: (json['year'] as num).toInt(),
  electricCurrent: (json['electricCurrent'] as num?)?.toDouble(),
  electricPrevious: (json['electricPrevious'] as num?)?.toDouble(),
  waterCurrent: (json['waterCurrent'] as num?)?.toDouble(),
  waterPrevious: (json['waterPrevious'] as num?)?.toDouble(),
  electricUnitPrice: (json['electricUnitPrice'] as num?)?.toDouble(),
  waterUnitPrice: (json['waterUnitPrice'] as num?)?.toDouble(),
  electricAmount: (json['electricAmount'] as num?)?.toDouble(),
  waterAmount: (json['waterAmount'] as num?)?.toDouble(),
  rentAmount: (json['rentAmount'] as num?)?.toDouble(),
  serviceAmount: (json['serviceAmount'] as num?)?.toDouble(),
  totalAmount: (json['totalAmount'] as num?)?.toDouble(),
  electricImage: json['electricImage'] as String?,
  waterImage: json['waterImage'] as String?,
  paymentQrUrl: json['paymentQrUrl'] as String?,
  type: json['type'] as String? ?? 'MONTHLY',
  status: json['status'] as String? ?? 'PENDING',
  damageFee: (json['damageFee'] as num?)?.toDouble(),
  damageReason: json['damageReason'] as String?,
  sharedPoolAmount: (json['sharedPoolAmount'] as num?)?.toDouble(),
  serviceDetails: json['serviceDetails'] as String?,
  discountAmount: (json['discountAmount'] as num?)?.toDouble(),
  isPaid: json['isPaid'] as bool? ?? false,
  paidAt: json['paidAt'] == null
      ? null
      : DateTime.parse(json['paidAt'] as String),
  paidByCash: json['paidByCash'] as bool? ?? false,
  collectedByStaffId: (json['collectedByStaffId'] as num?)?.toInt(),
  dueDate: json['dueDate'] == null
      ? null
      : DateTime.parse(json['dueDate'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$BillModelToJson(_BillModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'roomId': instance.roomId,
      'contractId': instance.contractId,
      'tenantId': instance.tenantId,
      'month': instance.month,
      'year': instance.year,
      'electricCurrent': instance.electricCurrent,
      'electricPrevious': instance.electricPrevious,
      'waterCurrent': instance.waterCurrent,
      'waterPrevious': instance.waterPrevious,
      'electricUnitPrice': instance.electricUnitPrice,
      'waterUnitPrice': instance.waterUnitPrice,
      'electricAmount': instance.electricAmount,
      'waterAmount': instance.waterAmount,
      'rentAmount': instance.rentAmount,
      'serviceAmount': instance.serviceAmount,
      'totalAmount': instance.totalAmount,
      'electricImage': instance.electricImage,
      'waterImage': instance.waterImage,
      'paymentQrUrl': instance.paymentQrUrl,
      'type': instance.type,
      'status': instance.status,
      'damageFee': instance.damageFee,
      'damageReason': instance.damageReason,
      'sharedPoolAmount': instance.sharedPoolAmount,
      'serviceDetails': instance.serviceDetails,
      'discountAmount': instance.discountAmount,
      'isPaid': instance.isPaid,
      'paidAt': instance.paidAt?.toIso8601String(),
      'paidByCash': instance.paidByCash,
      'collectedByStaffId': instance.collectedByStaffId,
      'dueDate': instance.dueDate?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };
