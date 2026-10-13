import 'package:json_annotation/json_annotation.dart';

part 'attendance_model.g.dart';

@JsonSerializable()
class AttendanceModel {
  final int id;
  final int staffId;
  final int? branchId;
  final String? branchName;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? checkInLocation;
  final String? checkOutLocation;
  final double? latitude;
  final double? longitude;
  final double? distanceMeters;
  final String? status;

  AttendanceModel({
    required this.id,
    required this.staffId,
    this.branchId,
    this.branchName,
    this.checkInTime,
    this.checkOutTime,
    this.checkInLocation,
    this.checkOutLocation,
    this.latitude,
    this.longitude,
    this.distanceMeters,
    this.status,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) =>
      _$AttendanceModelFromJson(json);
  Map<String, dynamic> toJson() => _$AttendanceModelToJson(this);
}
