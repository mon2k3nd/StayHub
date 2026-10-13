import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';

class AdminDashboardState {
  final int totalUsers;
  final int totalOwners;
  final double totalRevenue;
  final bool isLoading;

  AdminDashboardState({
    this.totalUsers = 0,
    this.totalOwners = 0,
    this.totalRevenue = 0,
    this.isLoading = false,
  });

  AdminDashboardState copyWith({
    int? totalUsers,
    int? totalOwners,
    double? totalRevenue,
    bool? isLoading,
  }) {
    return AdminDashboardState(
      totalUsers: totalUsers ?? this.totalUsers,
      totalOwners: totalOwners ?? this.totalOwners,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AdminDashboardNotifier extends Notifier<AdminDashboardState> {
  @override
  AdminDashboardState build() {
    unawaited(Future.microtask(() => _fetchStats()));
    return AdminDashboardState();
  }

  Future<void> _fetchStats() async {
    state = state.copyWith(isLoading: true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/v1/admin/dashboard');
      if (res.data['success'] == true) {
        final data = res.data['data'];
        state = state.copyWith(
          totalUsers: data['totalUsers'] ?? 0,
          totalOwners: data['totalOwners'] ?? 0,
          totalRevenue: (data['totalRevenue'] ?? 0).toDouble(),
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void refresh() {
    unawaited(_fetchStats());
  }
}

final adminStatsProvider =
    NotifierProvider<AdminDashboardNotifier, AdminDashboardState>(
      () => AdminDashboardNotifier(),
    );
