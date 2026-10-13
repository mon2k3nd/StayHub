import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../data/models/addon_model.dart';
import '../data/models/tenant_addon_request_model.dart';
import '../../../core/components/global_loading.dart';
import 'package:flutter/cupertino.dart';

final ownerAddonsProvider = FutureProvider<List<AddonModel>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/v1/owner/addons');
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
});

final roomAddonRequestsProvider =
    FutureProvider.family<List<TenantAddonRequestModel>, int>((
      ref,
      roomId,
    ) async {
      final dio = ref.watch(dioProvider);
      final res = await dio.get(
        '/v1/owner/addons/rooms/$roomId/requests?status=PENDING',
      );
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
    });

class OwnerAddonNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> createAddon(
    BuildContext context,
    String name,
    double price,
  ) async {
    GlobalLoading.show(context);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post(
        '/v1/owner/addons',
        data: {'name': name, 'price': price},
      );

      if (res.data['success'] == true) {
        ref.invalidate(ownerAddonsProvider);
        if (context.mounted) {
          GlobalLoading.hide();
          Navigator.pop(context); // Close modal
          _showSuccess(context, 'Tạo dịch vụ thành công!');
        }
      } else {
        throw Exception(res.data['message']);
      }
    } catch (e) {
      if (context.mounted) {
        GlobalLoading.hide();
        _showError(context, e.toString());
      }
    }
  }

  Future<void> deleteAddon(BuildContext context, int addonId) async {
    GlobalLoading.show(context);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.delete('/v1/owner/addons/$addonId');

      if (res.data['success'] == true) {
        ref.invalidate(ownerAddonsProvider);
        if (context.mounted) {
          GlobalLoading.hide();
          _showSuccess(context, 'Đã xóa dịch vụ!');
        }
      } else {
        throw Exception(res.data['message']);
      }
    } catch (e) {
      if (context.mounted) {
        GlobalLoading.hide();
        _showError(context, e.toString());
      }
    }
  }

  Future<void> respondToRequest(
    BuildContext context,
    int roomId,
    int requestId,
    bool approved,
    String note,
  ) async {
    GlobalLoading.show(context);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.put(
        '/v1/owner/addons/requests/$requestId',
        data: {'approved': approved, 'note': note},
      );

      if (res.data['success'] == true) {
        ref.invalidate(roomAddonRequestsProvider(roomId));
        if (context.mounted) {
          GlobalLoading.hide();
          _showSuccess(
            context,
            approved ? 'Đã duyệt yêu cầu!' : 'Đã từ chối yêu cầu!',
          );
        }
      } else {
        throw Exception(res.data['message']);
      }
    } catch (e) {
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

final ownerAddonProvider = AsyncNotifierProvider<OwnerAddonNotifier, void>(
  () => OwnerAddonNotifier(),
);
