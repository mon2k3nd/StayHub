import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/advanced_analytics_repository.dart';

final ownerFinancialProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(advancedAnalyticsRepositoryProvider).getOwnerFinancial();
});

final ownerOccupancyProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(advancedAnalyticsRepositoryProvider).getOwnerOccupancy();
});

final ownerOpsProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(advancedAnalyticsRepositoryProvider).getOwnerOps();
});

final adminSaasProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(advancedAnalyticsRepositoryProvider).getAdminSaas();
});

final ownerForecastProvider = FutureProvider.autoDispose((ref) async {
  return ref.watch(advancedAnalyticsRepositoryProvider).getOwnerForecast();
});
