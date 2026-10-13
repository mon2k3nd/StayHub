import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../data/models/voucher_model.dart';

export '../data/models/voucher_model.dart';

final voucherRepositoryProvider = Provider<VoucherRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return VoucherRepositoryImpl(dio: dio);
});

/// Returns applicable vouchers for a specific room (used in booking flow)
final applicableVouchersProvider =
    FutureProvider.family<List<VoucherModel>, int>((ref, roomId) async {
      final repo = ref.watch(voucherRepositoryProvider);
      return repo.getTenantVouchersForRoom(roomId);
    });

abstract class VoucherRepository {
  Future<List<VoucherModel>> getLandlordVouchers();
  Future<VoucherModel> createLandlordVoucher(Map<String, dynamic> data);
  Future<void> deleteLandlordVoucher(int id);
  Future<List<VoucherModel>> getTenantVouchersForRoom(int roomId);
}

class VoucherRepositoryImpl implements VoucherRepository {
  final dynamic _dio;

  VoucherRepositoryImpl({required dynamic dio}) : _dio = dio;

  @override
  Future<List<VoucherModel>> getLandlordVouchers() async {
    final response = await _dio.get('/v1/vouchers/landlord');
    if (response.data is List) {
      // BUGFIX (data): tránh `as Map<String, dynamic>` ném TypeError khi phần
      // tử không phải Map — lọc an toàn bằng whereType.
      return (response.data as List)
          .whereType<Map>()
          .map((e) => VoucherModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }

  @override
  Future<VoucherModel> createLandlordVoucher(Map<String, dynamic> data) async {
    final response = await _dio.post('/v1/vouchers/landlord', data: data);
    // BUGFIX (data): tránh `as Map<String, dynamic>` ném TypeError khi body
    // không phải Map.
    final body = response.data;
    return VoucherModel.fromJson(
      body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{},
    );
  }

  @override
  Future<void> deleteLandlordVoucher(int id) async {
    await _dio.delete('/v1/vouchers/landlord/$id');
  }

  @override
  Future<List<VoucherModel>> getTenantVouchersForRoom(int roomId) async {
    final response = await _dio.get('/v1/vouchers/tenant/room/$roomId');
    if (response.data is List) {
      // BUGFIX (data): lọc an toàn — tránh `as Map<String, dynamic>` ném TypeError.
      return (response.data as List)
          .whereType<Map>()
          .map((e) => VoucherModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return [];
  }
}
