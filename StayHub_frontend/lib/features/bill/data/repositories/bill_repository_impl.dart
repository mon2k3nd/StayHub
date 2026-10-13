import 'package:flutter/foundation.dart';
import '../../domain/repositories/bill_repository.dart';
import '../datasources/bill_remote_data_source.dart';
import '../models/bill_model.dart';
import '../models/meter_reading_model.dart';

class BillRepositoryImpl implements BillRepository {
  final BillRemoteDataSource _remoteDataSource;

  const BillRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<BillModel>> loadBillsByTenant(int tenantId) async {
    final res = await _remoteDataSource.loadBillsByTenant(tenantId);
    final rawData = res['data'];
    if (rawData is! List) return [];
    return rawData
        .whereType<Map<String, dynamic>>()
        .map((e) => BillModel.fromJson(e))
        .toList();
  }

  @override
  Future<List<BillModel>> loadBillsByOwner(int ownerId) async {
    try {
      final res = await _remoteDataSource.loadBillsByOwner(ownerId);
      final rawData = res['data'];
      if (rawData is! List) return [];
      return rawData
          .whereType<Map<String, dynamic>>()
          .map((e) => BillModel.fromJson(e))
          .toList();
    } catch (e, stack) {
      debugPrint('loadBillsByOwner error: $e\n$stack');
      // Nếu API lỗi (chưa cài đặt), trả về danh sách rỗng để app chạy trơn tru
      return [];
    }
  }

  @override
  Future<List<BillModel>> loadBillsByStaff(int staffId) async {
    try {
      final res = await _remoteDataSource.loadBillsByStaff(staffId);
      final rawData = res['data'];
      if (rawData is! List) return [];
      return rawData
          .whereType<Map<String, dynamic>>()
          .map((e) => BillModel.fromJson(e))
          .toList();
    } catch (e, stack) {
      debugPrint('loadBillsByStaff error: $e\n$stack');
      return [];
    }
  }

  @override
  Future<void> payBill(int billId, {required bool cash, int? staffId}) async {
    await _remoteDataSource.payBill(billId, cash, staffId: staffId);
  }

  @override
  Future<void> payBillOnline(int billId) async {
    await _remoteDataSource.payBillOnline(billId);
  }

  @override
  Future<void> confirmCashPayment(int billId, int ownerId) async {
    await _remoteDataSource.confirmCash(billId, ownerId);
  }

  @override
  Future<void> updateUtilities(
    int billId,
    double? electricCurrent,
    double? waterCurrent, {
    String? electricImage,
    String? waterImage,
  }) async {
    await _remoteDataSource.updateUtilities(
      billId,
      electricCurrent,
      waterCurrent,
    );
  }

  @override
  Future<void> sendBill(int billId) async {
    await _remoteDataSource.sendBill(billId);
  }

  @override
  Future<List<MeterReadingModel>> getMeterReadings(
    int branchId,
    int month,
    int year,
  ) async {
    final response = await _remoteDataSource.getMeterReadings(
      branchId,
      month,
      year,
    );
    final List<dynamic> data = response['data'] ?? [];
    return data.map((json) => MeterReadingModel.fromJson(json)).toList();
  }

  @override
  Future<List<BillModel>> generateBills(
    int branchId,
    int month,
    int year,
  ) async {
    final response = await _remoteDataSource.generateBills(
      branchId,
      month,
      year,
    );
    final List<dynamic> data = response['data'] ?? [];
    return data.map((json) => BillModel.fromJson(json)).toList();
  }

  @override
  Future<void> updateUtilitiesByRoom(
    int roomId,
    double? electricCurrent,
    double? waterCurrent, {
    String? electricImage,
    String? waterImage,
  }) async {
    await _remoteDataSource.updateUtilitiesByRoom(
      roomId,
      electricCurrent,
      waterCurrent,
      electricImage: electricImage,
      waterImage: waterImage,
    );
  }
}
