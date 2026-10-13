import 'package:freezed_annotation/freezed_annotation.dart';

part 'contract_model.freezed.dart';
part 'contract_model.g.dart';

@freezed
abstract class ContractModel with _$ContractModel {
  const factory ContractModel({
    required int id,
    required int roomId,
    required int tenantId,
    required int ownerId,
    required DateTime startDate,
    required DateTime endDate,
    required double monthlyRent,
    double? depositAmount,
    double? electricityPrice,
    double? waterPrice,
    double? serviceFee,
    String? terms,
    @Default('ACTIVE') String status,
    DateTime? signedAt,
    DateTime? terminatedAt,
    String? terminationReason,
    String? contractImages,
    String? electricityMeterImage,
    String? waterMeterImage,
    String? roomName,
    int? branchId,
    String? branchName,
    String? ownerName,
    String? tenantName,
    @Default(false) bool ekycVerified,
    String? ekycDocumentId,
    String? digitalSignatureId,
    String? signatureProvider,
    required DateTime createdAt,
  }) = _ContractModel;

  factory ContractModel.fromJson(Map<String, dynamic> json) =>
      _$ContractModelFromJson(json);

  const ContractModel._();

  bool get isActive => status == 'ACTIVE';
  bool get isExpired => endDate.isBefore(DateTime.now());
  int get daysRemaining => endDate.difference(DateTime.now()).inDays;
}
