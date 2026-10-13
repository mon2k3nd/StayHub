// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'signature_history_model.freezed.dart';
part 'signature_history_model.g.dart';

@freezed
abstract class SignatureHistoryModel with _$SignatureHistoryModel {
  const factory SignatureHistoryModel({
    required int id,
    required int userId,
    required String signature,
    required String createdAt,
  }) = _SignatureHistoryModel;

  factory SignatureHistoryModel.fromJson(Map<String, dynamic> json) =>
      _$SignatureHistoryModelFromJson(json);
}
