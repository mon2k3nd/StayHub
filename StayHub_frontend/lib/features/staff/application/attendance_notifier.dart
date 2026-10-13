import 'dart:async' show unawaited;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/application/auth_notifier.dart';

part 'attendance_notifier.g.dart';

class AttendanceState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? currentLog;
  final List<dynamic> historyLogs;

  const AttendanceState({
    this.isLoading = false,
    this.error,
    this.currentLog,
    this.historyLogs = const [],
  });

  AttendanceState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? currentLog,
    List<dynamic>? historyLogs,
  }) {
    return AttendanceState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentLog: currentLog ?? this.currentLog,
      historyLogs: historyLogs ?? this.historyLogs,
    );
  }
}

@riverpod
class AttendanceNotifier extends _$AttendanceNotifier {
  @override
  AttendanceState build() {
    final authState = ref.watch(authProvider);
    if (authState.value != null && authState.value!.role == 'STAFF') {
      unawaited(
        Future.microtask(() {
          unawaited(checkCurrentStatus());
          unawaited(loadHistory());
        }),
      );
    }
    return const AttendanceState();
  }

  Future<void> checkCurrentStatus() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/v1/attendance/status');

      state = state.copyWith(isLoading: false, currentLog: res['data']);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadHistory() async {
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.get('/v1/attendance/logs');

      state = state.copyWith(historyLogs: res['data'] ?? []);
    } catch (e) {
      // ignore silently for now
    }
  }

  Future<bool> checkIn(int? branchId, String location) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.post(
        '/v1/attendance/check-in',
        data: {'branchId': branchId, 'location': location},
      );

      state = state.copyWith(isLoading: false, currentLog: res['data']);
      unawaited(loadHistory());
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> checkOut(String location) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = ref.read(apiClientProvider);
      await api.post('/v1/attendance/check-out', data: {'location': location});

      state = state.copyWith(isLoading: false, currentLog: null);
      unawaited(loadHistory());
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}
