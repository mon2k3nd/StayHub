class UserEntity {
  final int id;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String role;
  final String planType;
  final String? bankName;
  final String? bankAccountNumber;
  final String? bankAccountName;
  final String? cccdNumber;
  final DateTime? cccdIssueDate;
  final String? cccdIssuePlace;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? vehicleType;
  final String? licensePlate;
  final String? hometown;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? occupation;
  final String? ownerStatus;
  final String? status;
  final String? signature;
  final String? kycStatus;
  final int? trustScore;
  final String? avatar;
  final bool requirePasswordSetup;

  UserEntity({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    required this.role,
    required this.planType,
    this.bankName,
    this.bankAccountNumber,
    this.bankAccountName,
    this.cccdNumber,
    this.cccdIssueDate,
    this.cccdIssuePlace,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.vehicleType,
    this.licensePlate,
    this.hometown,
    this.gender,
    this.dateOfBirth,
    this.occupation,
    this.ownerStatus,
    this.status,
    this.signature,
    this.kycStatus,
    this.trustScore,
    this.avatar,
    this.requirePasswordSetup = false,
  });
}
