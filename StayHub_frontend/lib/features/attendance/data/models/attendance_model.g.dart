// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttendanceModel _$AttendanceModelFromJson(Map<String, dynamic> json) =>
    AttendanceModel(
      id: (json['id'] as num).toInt(),
      staffId: (json['staffId'] as num).toInt(),
      branchId: (json['branchId'] as num?)?.toInt(),
      branchName: json['branchName'] as String?,
      checkInTime: json['checkInTime'] == null
          ? null
          : DateTime.parse(json['checkInTime'] as String),
      checkOutTime: json['checkOutTime'] == null
          ? null
          : DateTime.parse(json['checkOutTime'] as String),
      checkInLocation: json['checkInLocation'] as String?,
      checkOutLocation: json['checkOutLocation'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
      status: json['status'] as String?,
    );

Map<String, dynamic> _$AttendanceModelToJson(AttendanceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'staffId': instance.staffId,
      'branchId': instance.branchId,
      'branchName': instance.branchName,
      'checkInTime': instance.checkInTime?.toIso8601String(),
      'checkOutTime': instance.checkOutTime?.toIso8601String(),
      'checkInLocation': instance.checkInLocation,
      'checkOutLocation': instance.checkOutLocation,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'distanceMeters': instance.distanceMeters,
      'status': instance.status,
    };
