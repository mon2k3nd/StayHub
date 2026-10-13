class OwnerAnalyticsModel {
  final int ownerId;
  final String fullName;
  final String packageStatus;
  final double trustScore;
  final double totalRevenue;
  final int totalRooms;
  final double occupancyRate;
  final double unpaidDebt;
  final List<RevenuePoint> revenueTrend;
  final List<RoomPerformance> roomPerformanceRank;
  final List<ActionableInsight> actionableInsights;
  final String? avatarUrl;

  OwnerAnalyticsModel({
    required this.ownerId,
    required this.fullName,
    required this.packageStatus,
    required this.trustScore,
    required this.totalRevenue,
    required this.totalRooms,
    required this.occupancyRate,
    required this.unpaidDebt,
    required this.revenueTrend,
    required this.roomPerformanceRank,
    required this.actionableInsights,
    this.avatarUrl,
  });
}

class RevenuePoint {
  final String label;
  final double y;
  RevenuePoint({required this.label, required this.y});
}

class RoomPerformance {
  final String roomName;
  final double revenue;
  final String status;
  RoomPerformance({
    required this.roomName,
    required this.revenue,
    required this.status,
  });
}

class ActionableInsight {
  final String type;
  final String message;
  final String actionText;
  ActionableInsight({
    required this.type,
    required this.message,
    required this.actionText,
  });
}
