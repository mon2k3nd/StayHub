class RoomPromotionModel {
  final int? id;
  final int? roomId;
  final String discountType;
  final double? discountAmount;
  final double? discountPercent;
  final double? maxDiscountAmount;
  final int monthsPerTenant;
  final int totalMonths;
  final int usedMonths;
  final int remainingMonths;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? description;
  final bool isActive;
  final double? originalPrice;
  final double? promotionPrice;
  final String? badgeLabel;

  RoomPromotionModel({
    this.id,
    this.roomId,
    this.discountType = 'FIXED_AMOUNT',
    this.discountAmount,
    this.discountPercent,
    this.maxDiscountAmount,
    this.monthsPerTenant = 3,
    this.totalMonths = 0,
    this.usedMonths = 0,
    this.remainingMonths = -1,
    this.startDate,
    this.endDate,
    this.description,
    this.isActive = true,
    this.originalPrice,
    this.promotionPrice,
    this.badgeLabel,
  });

  factory RoomPromotionModel.fromJson(Map<String, dynamic> json) {
    return RoomPromotionModel(
      id: json['id'],
      roomId: json['roomId'],
      discountType: json['discountType'] ?? 'FIXED_AMOUNT',
      discountAmount: json['discountAmount']?.toDouble(),
      discountPercent: json['discountPercent']?.toDouble(),
      maxDiscountAmount: json['maxDiscountAmount']?.toDouble(),
      monthsPerTenant: json['monthsPerTenant'] ?? 3,
      totalMonths: json['totalMonths'] ?? 0,
      usedMonths: json['usedMonths'] ?? 0,
      remainingMonths: json['remainingMonths'] ?? -1,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'])
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'])
          : null,
      description: json['description'],
      isActive: json['isActive'] ?? true,
      originalPrice: json['originalPrice']?.toDouble(),
      promotionPrice: json['promotionPrice']?.toDouble(),
      badgeLabel: json['badgeLabel'],
    );
  }
}

class RoomPromotionRequest {
  final String discountType;
  final double? discountAmount;
  final double? discountPercent;
  final double? maxDiscountAmount;
  final int? monthsPerTenant;
  final int? totalMonths;
  final String? startDate;
  final String? endDate;
  final String? description;

  RoomPromotionRequest({
    required this.discountType,
    this.discountAmount,
    this.discountPercent,
    this.maxDiscountAmount,
    this.monthsPerTenant,
    this.totalMonths,
    this.startDate,
    this.endDate,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'discountType': discountType,
      if (discountAmount != null) 'discountAmount': discountAmount,
      if (discountPercent != null) 'discountPercent': discountPercent,
      if (maxDiscountAmount != null) 'maxDiscountAmount': maxDiscountAmount,
      if (monthsPerTenant != null) 'monthsPerTenant': monthsPerTenant,
      if (totalMonths != null) 'totalMonths': totalMonths,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (description != null) 'description': description,
    };
  }
}
