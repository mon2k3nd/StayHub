import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/core_providers.dart';

part 'admin_kyc_notifier.g.dart';

@riverpod
class AdminKycNotifier extends _$AdminKycNotifier {
  @override
  FutureOr<List<dynamic>> build() async {
    final client = ref.watch(apiClientProvider);
    final response = await client.get(
      '/v1/admin/owners?status=PENDING_VERIFICATION',
    );
    // BUGFIX (data): tránh `as List<dynamic>` ném TypeError khi `data`
    // null/không phải List — trả [] để màn hình không vỡ.
    final raw = response['data'];
    return raw is List ? raw : const <dynamic>[];
  }

  Future<bool> approve(int kycId) async {
    try {
      final client = ref.read(apiClientProvider);
      await client.put(
        '/v1/admin/owners/$kycId/verify',
        data: {'approved': true},
      );
      ref.invalidateSelf();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> reject(int kycId, String reason) async {
    try {
      final client = ref.read(apiClientProvider);
      await client.put(
        '/v1/admin/owners/$kycId/verify',
        data: {'approved': false, 'reason': reason},
      );
      ref.invalidateSelf();
      return true;
    } catch (e) {
      return false;
    }
  }
}
