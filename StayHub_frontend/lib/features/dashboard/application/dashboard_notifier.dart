import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/providers/core_providers.dart';
import 'dart:async' show unawaited;

part 'dashboard_notifier.g.dart';

@riverpod
class DashboardStats extends _$DashboardStats {
  @override
  Future<Map<String, dynamic>> build({int? month, int? year}) async {
    try {
      return await _fetch(month: month, year: year);
    } catch (e) {
      // Fallback to cache only on error
      try {
        final prefs = await SharedPreferences.getInstance();
        final cacheKey = 'dashboard_stats_${month ?? 'all'}_${year ?? 'all'}';
        final cachedStr = prefs.getString(cacheKey);
        if (cachedStr != null) {
          return jsonDecode(cachedStr) as Map<String, dynamic>;
        }
      } catch (_) {}
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _fetch({int? month, int? year}) async {
    final apiClient = ref.read(apiClientProvider);
    final queryParams = <String, dynamic>{};
    if (month != null) queryParams['month'] = month;
    if (year != null) queryParams['year'] = year;

    final response = await apiClient.get(
      '/v1/dashboard/owner',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );

    // Also save cache here in case this is the first fetch
    try {
      final data = response['data'] as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'dashboard_stats_${month ?? 'all'}_${year ?? 'all'}';
      unawaited(prefs.setString(cacheKey, jsonEncode(data)));
    } catch (_) {}

    final rawData = response['data'];
    if (rawData == null) {
      return {
        'totalRevenue': 0,
        'totalRooms': 0,
        'occupiedRooms': 0,
        'pendingRentals': 0,
      };
    }
    if (rawData is! Map<String, dynamic>) {
      return {
        'totalRevenue': 0,
        'totalRooms': 0,
        'occupiedRooms': 0,
        'pendingRentals': 0,
      };
    }
    return rawData;
  }
}
