import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../models/voucher_model.dart';

final voucherRepositoryProvider = Provider<VoucherRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return VoucherRepositoryImpl(dio: dio);
});

abstract class VoucherRepository {
  Future<List<VoucherModel>> getLandlordVouchers();
  Future<VoucherModel> createLandlordVoucher(Map<String, dynamic> data);
  Future<void> deleteLandlordVoucher(int id);
  Future<List<VoucherModel>> getTenantVouchersForRoom(int roomId);
}

class VoucherRepositoryImpl implements VoucherRepository {
  final Dio _dio;

  VoucherRepositoryImpl({required Dio dio}) : _dio = dio;

  @override
  Future<List<VoucherModel>> getLandlordVouchers() async {
    try {
      final response = await _dio.get('/v1/vouchers/landlord');
      if (response.data is List) {
        // BUGFIX (data): lọc an toàn — tránh phần tử không phải Map.
        return (response.data as List)
            .whereType<Map>()
            .map((e) => VoucherModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<VoucherModel> createLandlordVoucher(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/v1/vouchers/landlord', data: data);
      // BUGFIX (data): tránh `as Map<String, dynamic>` ném TypeError.
      final body = response.data;
      return VoucherModel.fromJson(
        body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{},
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteLandlordVoucher(int id) async {
    try {
      await _dio.delete('/v1/vouchers/landlord/$id');
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<VoucherModel>> getTenantVouchersForRoom(int roomId) async {
    try {
      final response = await _dio.get('/v1/vouchers/tenant/room/$roomId');
      if (response.data is List) {
        // BUGFIX (data): lọc an toàn — tránh `as Map<String, dynamic>` ném TypeError.
        return (response.data as List)
            .whereType<Map>()
            .map((e) => VoucherModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
}
