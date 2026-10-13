import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/enums/room_status.dart';

part 'room_model.freezed.dart';
part 'room_model.g.dart';

Object? readDepositValue(Map json, String key) =>
    json['deposit'] ?? json['baseDeposit'];
Object? readAreaValue(Map json, String key) =>
    json['area'] ?? json['size'] ?? json['floorArea'];
Object? readMaxGuestsValue(Map json, String key) =>
    json['maxGuests'] ?? json['maxTenants'] ?? json['capacity'];

@freezed
abstract class RoomModel with _$RoomModel {
  const factory RoomModel({
    required int id,
    required int ownerId,
    int? branchId,
    dynamic branch,
    required String roomName,
    double? price,
    String? address,
    @Default('TRONG') String status,
    String? description,
    @JsonKey(readValue: readDepositValue) double? deposit,
    @JsonKey(readValue: readMaxGuestsValue) int? maxGuests,
    @JsonKey(readValue: readAreaValue) double? area,
    double? electricityPrice,
    double? waterPrice,
    double? serviceFee,
    double? internetPrice,
    double? parkingPrice,
    double? trashPrice,
    String? roomImages,
    String? inspectionImages,
    String? qrCode,
    int? currentTenantId,
    int? currentContractId,
    String? bathroomType,
    String? direction,
    bool? hasBalcony,
    bool? hasWindow,
    Map<String, dynamic>? detailedInfo,
    String? availableFrom,
    double? mezzanineArea,
    int? maxVehicles,
    dynamic furniture,
    String? approvalStatus,
    @Default(false) bool isDeleted,
  }) = _RoomModel;

  factory RoomModel.fromJson(Map<String, dynamic> json) =>
      _$RoomModelFromJson(json);

  const RoomModel._();

  bool get isTrong => status == RoomStatus.trong.value;
  bool get isDaThue => status == RoomStatus.daThue.value;
  bool get isBaoTri => status == RoomStatus.baoTri.value;
  bool get isDongCua => status == RoomStatus.dongCua.value;
  bool get isCleaningTurnover => status == RoomStatus.cleaningTurnover.value;
  bool get isChoKichHoat => status == RoomStatus.choKichHoat.value;

  String get statusLabel {
    switch (status) {
      case 'TRONG':
        return 'Trống';
      case 'DA_THUE':
        return 'Đã thuê';
      case 'BAO_TRI':
        return 'Bảo trì';
      case 'DONG_CUA':
        return 'Đóng cửa';
      case 'CLEANING_TURNOVER':
        return 'Chờ dọn dẹp';
      case 'CHO_KICH_HOAT':
        return 'Chờ kích hoạt';
      default:
        return status;
    }
  }
}
