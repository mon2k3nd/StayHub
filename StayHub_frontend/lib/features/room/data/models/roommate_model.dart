import 'package:freezed_annotation/freezed_annotation.dart';

part 'roommate_model.freezed.dart';
part 'roommate_model.g.dart';

@freezed
abstract class RoommateModel with _$RoommateModel {
  const factory RoommateModel({
    required int id,
    required int contractId,
    required int roomId,
    required String fullName,
    String? phoneNumber,
    String? cccdNumber,
    String? hometown,
    DateTime? birthday,
    String? gender,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    @Default(true) bool isActive,
  }) = _RoommateModel;

  factory RoommateModel.fromJson(Map<String, dynamic> json) =>
      _$RoommateModelFromJson(json);
}
