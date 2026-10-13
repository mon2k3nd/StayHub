// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'roommate_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RoommateModel _$RoommateModelFromJson(Map<String, dynamic> json) =>
    _RoommateModel(
      id: (json['id'] as num).toInt(),
      contractId: (json['contractId'] as num).toInt(),
      roomId: (json['roomId'] as num).toInt(),
      fullName: json['fullName'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      cccdNumber: json['cccdNumber'] as String?,
      hometown: json['hometown'] as String?,
      birthday: json['birthday'] == null
          ? null
          : DateTime.parse(json['birthday'] as String),
      gender: json['gender'] as String?,
      checkInDate: json['checkInDate'] == null
          ? null
          : DateTime.parse(json['checkInDate'] as String),
      checkOutDate: json['checkOutDate'] == null
          ? null
          : DateTime.parse(json['checkOutDate'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );

Map<String, dynamic> _$RoommateModelToJson(_RoommateModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'contractId': instance.contractId,
      'roomId': instance.roomId,
      'fullName': instance.fullName,
      'phoneNumber': instance.phoneNumber,
      'cccdNumber': instance.cccdNumber,
      'hometown': instance.hometown,
      'birthday': instance.birthday?.toIso8601String(),
      'gender': instance.gender,
      'checkInDate': instance.checkInDate?.toIso8601String(),
      'checkOutDate': instance.checkOutDate?.toIso8601String(),
      'isActive': instance.isActive,
    };
