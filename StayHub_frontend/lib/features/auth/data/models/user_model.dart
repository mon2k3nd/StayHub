// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/user_entity.dart';
import '../../../../core/utils/image_url_helper.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

Object? readRoleIdValue(Map json, String key) {
  String rId = (json['role'] ?? json['roleId'])?.toString() ?? 'TENANT';
  return rId.toUpperCase();
}

@freezed
abstract class UserModel with _$UserModel {
  const factory UserModel({
    required int id,
    @JsonKey(name: 'fullName') required String fullName,
    @JsonKey(name: 'phone') String? phone,
    String? email,
    @JsonKey(name: 'roleId', readValue: readRoleIdValue) required String roleId,
    @JsonKey(name: 'packageId') @Default('FREE') String packageId,
    String? status,
    String? bankName,
    String? bankAccountNumber,
    String? bankAccountName,
    String? cccdNumber,
    String? cccdIssueDate,
    String? cccdIssuePlace,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? vehicleType,
    String? licensePlate,
    String? hometown,
    String? gender,
    String? dateOfBirth,
    String? occupation,
    String? ownerStatus,
    String? signature,
    String? kycStatus,
    int? trustScore,
    String? avatarUrl,
    @Default(false) bool requirePasswordSetup,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  const UserModel._();

  UserEntity toEntity() {
    String mappedRole = roleId.toUpperCase();
    if (mappedRole == '1') {
      mappedRole = 'ADMIN';
    } else if (mappedRole == '2') {
      mappedRole = 'OWNER';
    } else if (mappedRole == '3') {
      mappedRole = 'TENANT';
    } else if (mappedRole == '4') {
      mappedRole = 'STAFF';
    }

    return UserEntity(
      id: id,
      fullName: fullName,
      phoneNumber: phone ?? '',
      email: email,
      role: mappedRole,
      planType: packageId,
      bankName: bankName,
      bankAccountNumber: bankAccountNumber,
      bankAccountName: bankAccountName,
      cccdNumber: cccdNumber,
      cccdIssueDate: cccdIssueDate != null
          ? DateTime.tryParse(cccdIssueDate!)
          : null,
      cccdIssuePlace: cccdIssuePlace,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      vehicleType: vehicleType,
      licensePlate: licensePlate,
      hometown: hometown,
      gender: gender,
      dateOfBirth: dateOfBirth != null ? DateTime.tryParse(dateOfBirth!) : null,
      occupation: occupation,
      ownerStatus: ownerStatus,
      status: status,
      signature: signature,
      kycStatus: kycStatus,
      trustScore: trustScore,
      avatar: ImageUrlHelper.buildUrl(avatarUrl),
      requirePasswordSetup: requirePasswordSetup,
    );
  }
}
