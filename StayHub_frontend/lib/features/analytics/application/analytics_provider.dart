import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/utils/image_url_helper.dart';
import '../data/models/owner_analytics_model.dart';

class AnalyticsMonthsNotifier extends Notifier<int> {
  @override
  int build() => 6;
  void setMonths(int m) => state = m;
}

final analyticsMonthsProvider = NotifierProvider<AnalyticsMonthsNotifier, int>(
  () => AnalyticsMonthsNotifier(),
);

final ownerAnalyticsProvider = FutureProvider.autoDispose
    .family<OwnerAnalyticsModel, int>((ref, ownerId) async {
      final dio = ref.watch(dioProvider);
      final months = ref.watch(analyticsMonthsProvider);

      // Gọi song song tất cả API để giảm thời gian tải
      final results = await Future.wait([
        dio.get('/v1/analytics/advanced/owner/financial?months=$months'),
        dio.get('/v1/analytics/advanced/owner/occupancy'),
        dio.get('/v1/analytics/advanced/owner/ops'),
        dio.get('/v1/users/$ownerId/profile'),
      ]);

      Map<String, dynamic> getSafeMap(dynamic rawData) {
        if (rawData is Map) {
          final innerData = rawData['data'];
          if (innerData is Map<String, dynamic>) {
            return innerData;
          }
        }
        return {};
      }

      final financial = getSafeMap(results[0].data);
      final occupancy = getSafeMap(results[1].data);
      final ops = getSafeMap(results[2].data);
      final profile = getSafeMap(results[3].data);

      // Parse revenue trend từ danh sách cashflowTrend từ API financial
      // BUGFIX (data): tránh `as List` ném TypeError + `m['label']` ném
      // NoSuchMethodError khi phần tử không phải Map — lọc an toàn.
      final monthlyList = (financial['cashflowTrend'] is List
          ? (financial['cashflowTrend'] as List).whereType<Map>()
          : const <Map>[]);
      final revenueTrend = monthlyList.map((m) {
        return RevenuePoint(
          label: (m['label'] ?? '').toString(),
          y: (m['value'] is num ? (m['value'] as num).toDouble() : 0.0),
        );
      }).toList();

      // Parse room performance từ financial['revenueBreakdown'] thay vì ops (vì API mới không trả topRooms)
      final topRooms = (financial['revenueBreakdown'] is List
          ? (financial['revenueBreakdown'] as List).whereType<Map>()
          : const <Map>[]);
      final roomPerformanceRank = topRooms.map((r) {
        return RoomPerformance(
          roomName: (r['label'] ?? 'Mục').toString(),
          revenue: (r['value'] is num ? (r['value'] as num).toDouble() : 0.0),
          status: 'Tốt',
        );
      }).toList();

      return OwnerAnalyticsModel(
        ownerId: ownerId,
        fullName: (profile['fullName'] ?? ops['ownerName'] ?? 'Chủ nhà')
            .toString(),
        packageStatus: (profile['packageId'] ?? ops['packageStatus'] ?? 'FREE')
            .toString(),
        trustScore: (ops['trustScore'] as num? ?? 4.9).toDouble(),
        totalRevenue: (financial['gmv'] as num? ?? 0).toDouble(),
        totalRooms: (occupancy['totalRooms'] as num? ?? 0).toInt(),
        occupancyRate: (occupancy['realTimeOccupancyRate'] as num? ?? 0)
            .toDouble(),
        unpaidDebt: (financial['badDebt'] as num? ?? 0).toDouble(),
        revenueTrend: revenueTrend,
        roomPerformanceRank: roomPerformanceRank,
        actionableInsights: [], // AI Insights bỏ qua theo yêu cầu
        avatarUrl: ImageUrlHelper.buildUrl(profile['avatarUrl'] as String?),
      );
    });
