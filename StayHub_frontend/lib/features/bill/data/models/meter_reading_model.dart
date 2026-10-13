import 'package:freezed_annotation/freezed_annotation.dart';

part 'meter_reading_model.freezed.dart';
part 'meter_reading_model.g.dart';

@freezed
abstract class MeterReadingModel with _$MeterReadingModel {
  const factory MeterReadingModel({
    required int roomId,
    required String roomName,
    int? currentTenantId,
    int? currentContractId,
    @Default(0.0) double electricPrevious,
    @Default(0.0) double waterPrevious,
    double? electricCurrent,
    double? waterCurrent,
    int? currentMonthBillId,
    required int month,
    required int year,
  }) = _MeterReadingModel;

  factory MeterReadingModel.fromJson(Map<String, dynamic> json) =>
      _$MeterReadingModelFromJson(json);
}
