import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/application/auth_notifier.dart';

// --- Staff Model --------------------------------------------
class StaffModel {
  final int id;
  final String name;
  final String phoneNumber;
  final String? role;
  final List<dynamic> assignments;
  final double cashSpent;
  final double? maxCashLimit;
  final String status;
  final String? resignReason;

  const StaffModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.role,
    this.assignments = const [],
    this.cashSpent = 0.0,
    this.maxCashLimit,
    this.status = 'ACTIVE',
    this.resignReason,
  });

  /// BUGFIX (data): coerce an toàn sang double — tránh `as num` ném TypeError
  /// khi backend trả String/null.
  static double _toDouble(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;

  /// BUGFIX (data): coerce an toàn sang int — tránh `as int` ném TypeError.
  static int _toInt(dynamic v) =>
      v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    double cashSpent = 0.0;
    double? maxCashLimit;
    final wallet = json['wallet'];
    if (wallet is Map) {
      if (wallet['cashSpent'] != null) {
        cashSpent = _toDouble(wallet['cashSpent']);
      }
      if (wallet['maxCashLimit'] != null) {
        maxCashLimit = _toDouble(wallet['maxCashLimit']);
      }
    }
    final rawAssignments = json['assignments'];
    return StaffModel(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? 'Chua c?p nh?t',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      role: json['role']?.toString(),
      assignments: rawAssignments is List ? rawAssignments : const [],
      cashSpent: cashSpent,
      maxCashLimit: maxCashLimit,
      status: json['status']?.toString() ?? 'ACTIVE',
      resignReason: json['resignReason']?.toString(),
    );
  }
}

// --- Notifier ------------------------------------------------
class StaffListNotifier extends AsyncNotifier<List<StaffModel>> {
  @override
  Future<List<StaffModel>> build() async {
    final user = ref.watch(authProvider).value;
    if (user == null) return [];
    final api = ref.watch(apiClientProvider);
    final res = await api.get('/v1/staff/owner/${user.id}');
    final List<dynamic> data = res['data'] ?? [];
    return data.map((j) => StaffModel.fromJson(j)).toList();
  }

  Future<bool> createStaff(
    String name,
    String phone,
    String password,
    List<int> branchIds,
  ) async {
    final user = ref.read(authProvider).value;
    if (user == null) return false;
    try {
      final api = ref.read(apiClientProvider);
      await api.post(
        '/v1/staff/create',
        data: {
          'name': name,
          'phoneNumber': phone,
          'password': password,
          'ownerId': user.id,
          'branchIds': branchIds,
        },
      );
      ref.invalidateSelf();
      return true;
    } catch (e, st) {
      debugPrint('createStaff error: $e\n$st');
      return false;
    }
  }

  Future<bool> resignStaff(int staffId, String reason) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.put('/v1/staff/$staffId/resign', data: {'reason': reason});
      ref.invalidateSelf();
      return true;
    } catch (e, st) {
      debugPrint('resignStaff error: $e\n$st');
      return false;
    }
  }

  Future<bool> toggleStaffStatus(int staffId, String currentStatus) async {
    try {
      final api = ref.read(apiClientProvider);
      final newStatus = currentStatus == 'ACTIVE' ? 'LOCKED' : 'ACTIVE';
      await api.put('/v1/staff/$staffId/status', data: {'status': newStatus});
      ref.invalidateSelf();
      return true;
    } catch (e, st) {
      debugPrint('toggleStaffStatus error: $e\n$st');
      return false;
    }
  }

  Future<bool> settleWallet(int staffId, double amount) async {
    try {
      final api = ref.read(apiClientProvider);
      await api.put(
        '/v1/staff/wallet/settle/$staffId',
        data: {'amount': amount},
      );
      ref.invalidateSelf();
      return true;
    } catch (e, st) {
      debugPrint('settleWallet error: $e\n$st');
      return false;
    }
  }
}

// --- Provider ------------------------------------------------
final staffListNotifierProvider =
    AsyncNotifierProvider<StaffListNotifier, List<StaffModel>>(
      StaffListNotifier.new,
    );
