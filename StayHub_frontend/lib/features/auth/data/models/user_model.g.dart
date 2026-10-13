// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserModel _$UserModelFromJson(Map<String, dynamic> json) => _UserModel(
  id: (json['id'] as num).toInt(),
  fullName: json['fullName'] as String,
  phone: json['phone'] as String?,
  email: json['email'] as String?,
  roleId: readRoleIdValue(json, 'roleId') as String,
  packageId: json['packageId'] as String? ?? 'FREE',
  status: json['status'] as String?,
  bankName: json['bankName'] as String?,
  bankAccountNumber: json['bankAccountNumber'] as String?,
  bankAccountName: json['bankAccountName'] as String?,
  cccdNumber: json['cccdNumber'] as String?,
  cccdIssueDate: json['cccdIssueDate'] as String?,
  cccdIssuePlace: json['cccdIssuePlace'] as String?,
  emergencyContactName: json['emergencyContactName'] as String?,
  emergencyContactPhone: json['emergencyContactPhone'] as String?,
  vehicleType: json['vehicleType'] as String?,
  licensePlate: json['licensePlate'] as String?,
  hometown: json['hometown'] as String?,
  gender: json['gender'] as String?,
  dateOfBirth: json['dateOfBirth'] as String?,
  occupation: json['occupation'] as String?,
  ownerStatus: json['ownerStatus'] as String?,
  signature: json['signature'] as String?,
  kycStatus: json['kycStatus'] as String?,
  trustScore: (json['trustScore'] as num?)?.toInt(),
  avatarUrl: json['avatarUrl'] as String?,
  requirePasswordSetup: json['requirePasswordSetup'] as bool? ?? false,
);

Map<String, dynamic> _$UserModelToJson(_UserModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'phone': instance.phone,
      'email': instance.email,
      'roleId': instance.roleId,
      'packageId': instance.packageId,
      'status': instance.status,
      'bankName': instance.bankName,
      'bankAccountNumber': instance.bankAccountNumber,
      'bankAccountName': instance.bankAccountName,
      'cccdNumber': instance.cccdNumber,
      'cccdIssueDate': instance.cccdIssueDate,
      'cccdIssuePlace': instance.cccdIssuePlace,
      'emergencyContactName': instance.emergencyContactName,
      'emergencyContactPhone': instance.emergencyContactPhone,
      'vehicleType': instance.vehicleType,
      'licensePlate': instance.licensePlate,
      'hometown': instance.hometown,
      'gender': instance.gender,
      'dateOfBirth': instance.dateOfBirth,
      'occupation': instance.occupation,
      'ownerStatus': instance.ownerStatus,
      'signature': instance.signature,
      'kycStatus': instance.kycStatus,
      'trustScore': instance.trustScore,
      'avatarUrl': instance.avatarUrl,
      'requirePasswordSetup': instance.requirePasswordSetup,
    };
