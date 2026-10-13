import 'package:freezed_annotation/freezed_annotation.dart';

part 'checkout_request_model.freezed.dart';
part 'checkout_request_model.g.dart';

@freezed
abstract class CheckoutRequestModel with _$CheckoutRequestModel {
  const factory CheckoutRequestModel({
    required int id,
    required int roomId,
    required int tenantId,
    required int ownerId,
    required int contractId,
    required String status,
    required DateTime targetCheckoutDate,
    String? checkoutImages,
    required String tenantNote,
    String? ownerReason,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _CheckoutRequestModel;

  factory CheckoutRequestModel.fromJson(Map<String, dynamic> json) =>
      _$CheckoutRequestModelFromJson(json);

  const CheckoutRequestModel._();
}
