import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';

class TenantProfileData {
  final Map<String, dynamic> userProfile;
  final List<dynamic> contracts;
  final List<dynamic> bills;

  TenantProfileData({
    required this.userProfile,
    required this.contracts,
    required this.bills,
  });
}

final tenantProfileProvider = FutureProvider.family<TenantProfileData?, String>((
  ref,
  tenantId,
) async {
  final apiClient = ref.watch(apiClientProvider);

  try {
    final results = await Future.wait([
      apiClient.get('/v1/users/$tenantId/profile'),
      apiClient.get('/v1/contracts/tenant/$tenantId'),
      apiClient.get('/v1/bills/tenant/$tenantId'),
    ]);

    final profileRes = results[0];
    final contractRes = results[1];
    final billRes = results[2];

    if (profileRes['success'] == true) {
      // BUGFIX (data): tránh NoSuchMethodError khi `data` không phải Map —
      // code bên dưới ghi trực tiếp vào map này.
      final rawProfile = profileRes['data'];
      final userProfile = rawProfile is Map
          ? Map<String, dynamic>.from(rawProfile)
          : <String, dynamic>{};

      // MOCK DATA for testing UI if images are missing from backend
      if (userProfile['cccdFrontUrl'] == null) {
        userProfile['cccdFrontUrl'] =
            'https://media.loveitopcdn.com/3807/phoi-cccd-gan-chip-mat-truoc-7-800x504.jpg';
      }
      if (userProfile['cccdBackUrl'] == null) {
        userProfile['cccdBackUrl'] =
            'https://media.loveitopcdn.com/3807/phoi-cccd-gan-chip-mat-sau-8-800x505.jpg';
      }

      return TenantProfileData(
        userProfile: userProfile,
        contracts: contractRes['data'] ?? [],
        bills: billRes['data'] ?? [],
      );
    }
  } catch (e) {
    debugPrint('Error fetching tenant profile: $e');
  }
  return null;
});
