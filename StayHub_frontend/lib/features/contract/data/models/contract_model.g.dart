// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contract_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ContractModel _$ContractModelFromJson(Map<String, dynamic> json) =>
    _ContractModel(
      id: (json['id'] as num).toInt(),
      roomId: (json['roomId'] as num).toInt(),
      tenantId: (json['tenantId'] as num).toInt(),
      ownerId: (json['ownerId'] as num).toInt(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      monthlyRent: (json['monthlyRent'] as num).toDouble(),
      depositAmount: (json['depositAmount'] as num?)?.toDouble(),
      electricityPrice: (json['electricityPrice'] as num?)?.toDouble(),
      waterPrice: (json['waterPrice'] as num?)?.toDouble(),
      serviceFee: (json['serviceFee'] as num?)?.toDouble(),
      terms: json['terms'] as String?,
      status: json['status'] as String? ?? 'ACTIVE',
      signedAt: json['signedAt'] == null
          ? null
          : DateTime.parse(json['signedAt'] as String),
      terminatedAt: json['terminatedAt'] == null
          ? null
          : DateTime.parse(json['terminatedAt'] as String),
      terminationReason: json['terminationReason'] as String?,
      contractImages: json['contractImages'] as String?,
      electricityMeterImage: json['electricityMeterImage'] as String?,
      waterMeterImage: json['waterMeterImage'] as String?,
      roomName: json['roomName'] as String?,
      branchId: (json['branchId'] as num?)?.toInt(),
      branchName: json['branchName'] as String?,
      ownerName: json['ownerName'] as String?,
      tenantName: json['tenantName'] as String?,
      ekycVerified: json['ekycVerified'] as bool? ?? false,
      ekycDocumentId: json['ekycDocumentId'] as String?,
      digitalSignatureId: json['digitalSignatureId'] as String?,
      signatureProvider: json['signatureProvider'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ContractModelToJson(_ContractModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'roomId': instance.roomId,
      'tenantId': instance.tenantId,
      'ownerId': instance.ownerId,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'monthlyRent': instance.monthlyRent,
      'depositAmount': instance.depositAmount,
      'electricityPrice': instance.electricityPrice,
      'waterPrice': instance.waterPrice,
      'serviceFee': instance.serviceFee,
      'terms': instance.terms,
      'status': instance.status,
      'signedAt': instance.signedAt?.toIso8601String(),
      'terminatedAt': instance.terminatedAt?.toIso8601String(),
      'terminationReason': instance.terminationReason,
      'contractImages': instance.contractImages,
      'electricityMeterImage': instance.electricityMeterImage,
      'waterMeterImage': instance.waterMeterImage,
      'roomName': instance.roomName,
      'branchId': instance.branchId,
      'branchName': instance.branchName,
      'ownerName': instance.ownerName,
      'tenantName': instance.tenantName,
      'ekycVerified': instance.ekycVerified,
      'ekycDocumentId': instance.ekycDocumentId,
      'digitalSignatureId': instance.digitalSignatureId,
      'signatureProvider': instance.signatureProvider,
      'createdAt': instance.createdAt.toIso8601String(),
    };
