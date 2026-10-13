import 'package:freezed_annotation/freezed_annotation.dart';

part 'bill_model.freezed.dart';
part 'bill_model.g.dart';

@freezed
abstract class BillModel with _$BillModel {
  const factory BillModel({
    required int id,
    required int roomId,
    int? contractId,
    int? tenantId,
    required int month,
    required int year,
    double? electricCurrent,
    double? electricPrevious,
    double? waterCurrent,
    double? waterPrevious,
    double? electricUnitPrice,
    double? waterUnitPrice,
    double? electricAmount,
    double? waterAmount,
    double? rentAmount,
    double? serviceAmount,
    double? totalAmount,
    String? electricImage,
    String? waterImage,
    String? paymentQrUrl,
    @Default('MONTHLY') String type,
    @Default('PENDING') String status,
    double? damageFee,
    String? damageReason,
    double? sharedPoolAmount,
    String? serviceDetails,
    double? discountAmount,
    @Default(false) bool isPaid,
    DateTime? paidAt,
    @Default(false) bool paidByCash,
    int? collectedByStaffId,
    DateTime? dueDate,
    required DateTime createdAt,
  }) = _BillModel;

  factory BillModel.fromJson(Map<String, dynamic> json) =>
      _$BillModelFromJson(json);

  const BillModel._();

  String get periodLabel => 'Tháng $month/$year';
  bool get isOverdue =>
      dueDate != null && dueDate!.isBefore(DateTime.now()) && !isPaid;
}
