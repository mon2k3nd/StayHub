// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meter_reading_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MeterReadingModel _$MeterReadingModelFromJson(Map<String, dynamic> json) =>
    _MeterReadingModel(
      roomId: (json['roomId'] as num).toInt(),
      roomName: json['roomName'] as String,
      currentTenantId: (json['currentTenantId'] as num?)?.toInt(),
      currentContractId: (json['currentContractId'] as num?)?.toInt(),
      electricPrevious: (json['electricPrevious'] as num?)?.toDouble() ?? 0.0,
      waterPrevious: (json['waterPrevious'] as num?)?.toDouble() ?? 0.0,
      electricCurrent: (json['electricCurrent'] as num?)?.toDouble(),
      waterCurrent: (json['waterCurrent'] as num?)?.toDouble(),
      currentMonthBillId: (json['currentMonthBillId'] as num?)?.toInt(),
      month: (json['month'] as num).toInt(),
      year: (json['year'] as num).toInt(),
    );

Map<String, dynamic> _$MeterReadingModelToJson(_MeterReadingModel instance) =>
    <String, dynamic>{
      'roomId': instance.roomId,
      'roomName': instance.roomName,
      'currentTenantId': instance.currentTenantId,
      'currentContractId': instance.currentContractId,
      'electricPrevious': instance.electricPrevious,
      'waterPrevious': instance.waterPrevious,
      'electricCurrent': instance.electricCurrent,
      'waterCurrent': instance.waterCurrent,
      'currentMonthBillId': instance.currentMonthBillId,
      'month': instance.month,
      'year': instance.year,
    };
