import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/repositories/checkout_repository.dart';
import '../../../core/providers/core_providers.dart';
import '../data/models/checkout_request_model.dart';
import '../../auth/application/auth_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'checkout_provider.g.dart';

@riverpod
CheckoutRepository checkoutRepository(Ref ref) {
  return CheckoutRepository(ref.watch(dioProvider));
}

@riverpod
class TenantCheckoutRequests extends _$TenantCheckoutRequests {
  @override
  FutureOr<List<CheckoutRequestModel>> build() async {
    final authState = ref.watch(authProvider);
    if (authState.value == null) return [];
    return ref
        .watch(checkoutRepositoryProvider)
        .getRequestsForTenant(authState.value!.id);
  }
}

@riverpod
class OwnerCheckoutRequests extends _$OwnerCheckoutRequests {
  @override
  FutureOr<List<CheckoutRequestModel>> build() async {
    final authState = ref.watch(authProvider);
    if (authState.value == null) return [];
    return ref
        .watch(checkoutRepositoryProvider)
        .getRequestsForOwner(authState.value!.id);
  }
}

final checkoutTrackingProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, requestId) async {
      final api = ref.read(apiClientProvider);
      final res = await api.dio.get(
        '/v1/checkouts/$requestId/tracking-summary',
      );
      return res.data['data'] as Map<String, dynamic>;
    });
