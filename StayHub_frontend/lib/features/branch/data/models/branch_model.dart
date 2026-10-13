import 'package:freezed_annotation/freezed_annotation.dart';

part 'branch_model.freezed.dart';
part 'branch_model.g.dart';

@freezed
abstract class BranchModel with _$BranchModel {
  const factory BranchModel({
    required int id,
    required int ownerId,
    required String branchName,
    String? branchCode,
    required String address, // backward compat
    String? addressOld, // Địa chỉ cũ 4 cấp (UI/Map)
    String? legalProvince,
    String? legalDistrict,
    String? legalWard,
    String? description,
    String? pois,
    double? electricityPrice,
    String? electricityPricingType,
    double? waterPrice,
    String? waterPricingType,
    @JsonKey(name: 'internetFee') double? internetPrice,
    @JsonKey(name: 'parkingFee') double? parkingPrice,
    @JsonKey(name: 'garbageFee') double? trashPrice,
    double? serviceFee,
    String? serviceFeePricingType,
    int? propertyType,
    int? numberOfFloors,
    int? managementType,
    @Default(0) int totalRooms,
    String? coverImage,
    @JsonKey(name: 'coverImages') String? coverImages,
    @Default(true) bool isActive,
    @Default('DRAFT') String creationStatus,
    @Default('APPROVED') String approvalStatus,
    // ─── Tiến độ wizard "Quản lý chi nhánh" (5 bước bắt buộc) ───
    @Default(false) bool step1Done,
    @Default(false) bool step2Done,
    @Default(false) bool step3Done,
    @Default(false) bool step4Done,
    @Default(false) bool step5Done,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? latitude,
    double? longitude,
    bool? petPolicy,
    bool? roommatePolicy,
    String? closingTime,
    String? cookingPolicy,
    bool? hasPccc,
    @JsonKey(name: 'pcccImages') String? pcccImages,
    bool? evChargingAllowed,
    String? evChargeType,
    double? evFixedPrice,
    double? evPercentage,
    int? billingDay,
    int? minLeaseDays,
    @Default(false) bool isDeleted,
  }) = _BranchModel;

  factory BranchModel.fromJson(Map<String, dynamic> json) =>
      _$BranchModelFromJson(json);
}

extension BranchModelX on BranchModel {
  /// Mã hiển thị cho người dùng.
  ///
  /// Khi chi nhánh bị TẠM NGỪNG, backend "nhả" mã gốc để chủ trọ có thể tạo
  /// lại chi nhánh mới cùng mã; lúc đó `branchCode` bị đổi thành placeholder
  /// `__SUSPENDED__<id>__<mã gốc>`. Getter này bóc placeholder để UI luôn
  /// hiển thị mã gốc thân thiện (VD: H5_351CAUGIAY) thay vì chuỗi kỹ thuật.
  String get displayCode {
    final raw = branchCode?.trim() ?? '';
    if (raw.isEmpty) return '';
    const marker = '__SUSPENDED__';
    if (raw.startsWith(marker)) {
      // Định dạng: __SUSPENDED__<id>__<mã gốc>
      final rest = raw.substring(marker.length);
      final sep = rest.indexOf('__');
      if (sep >= 0 && sep + 2 < rest.length) {
        return rest.substring(sep + 2);
      }
    }
    return raw;
  }

  /// True nếu `branchCode` đang ở dạng placeholder tạm ngừng.
  bool get isCodeSuspended => (branchCode ?? '').startsWith('__SUSPENDED__');
}
