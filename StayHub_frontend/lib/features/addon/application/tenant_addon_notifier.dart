import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/core_providers.dart';
import '../data/models/addon_model.dart';
import '../data/models/tenant_addon_request_model.dart';
import '../../../core/components/global_loading.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async' show unawaited;

part 'tenant_addon_notifier.g.dart';

@riverpod
Future<List<AddonModel>> availableAddons(Ref ref, int roomId) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/v1/tenant/addons/rooms/$roomId/available');
  if (res.data['success'] == true) {
    // BUGFIX (data): tránh `as List` ném TypeError khi `data` là null/không
    // phải List — lọc an toàn bằng whereType.
    final raw = res.data['data'];
    // BUGFIX (data): whereType<Map>() trả Map<dynamic,dynamic> — cần ép về
    // Map<String,dynamic> để khớp fromJson.
    return raw is List
        ? raw
              .whereType<Map>()
              .map((e) => AddonModel.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : <AddonModel>[];
  }
  return [];
}

@riverpod
Future<List<TenantAddonRequestModel>> myAddonRequests(Ref ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/v1/tenant/addons/requests');
  if (res.data['success'] == true) {
    // BUGFIX (data): tránh `as List` ném TypeError khi `data` là null/không
    // phải List — lọc an toàn bằng whereType.
    final raw = res.data['data'];
    // BUGFIX (data): whereType<Map>() trả Map<dynamic,dynamic> — cần ép về
    // Map<String,dynamic> để khớp fromJson.
    return raw is List
        ? raw
              .whereType<Map>()
              .map(
                (e) => TenantAddonRequestModel.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
        : <TenantAddonRequestModel>[];
  }
  return [];
}

@riverpod
class TenantAddonNotifier extends _$TenantAddonNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> orderAddon(
    BuildContext context,
    int roomId,
    int addonId,
    int quantity,
  ) async {
    GlobalLoading.show(context);
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post(
        '/v1/tenant/addons/rooms/$roomId/order',
        data: {'addonId': addonId, 'quantity': quantity},
      );

      if (res.data['success'] == true) {
        state = const AsyncData(null);
        ref.invalidate(myAddonRequestsProvider);
        if (context.mounted) {
          GlobalLoading.hide();
          _showSuccess(context, 'Đã đặt dịch vụ thành công!');
        }
      } else {
        throw Exception(res.data['message']);
      }
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      if (context.mounted) {
        GlobalLoading.hide();
        _showError(context, e.toString());
      }
    }
  }

  void _showSuccess(BuildContext context, String message) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Thành công'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('Đóng'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(BuildContext context, String error) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Lỗi'),
          content: Text(error),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Đóng'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}
