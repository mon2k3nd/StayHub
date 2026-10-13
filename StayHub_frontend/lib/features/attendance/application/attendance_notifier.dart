import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../data/models/attendance_model.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/components/global_loading.dart';
import 'package:geolocator/geolocator.dart';

final myAttendanceLogsProvider = FutureProvider<List<AttendanceModel>>((
  ref,
) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/v1/attendance/logs');
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
                (e) => AttendanceModel.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : <AttendanceModel>[];
  }
  return [];
});

final currentAttendanceStatusProvider = FutureProvider<AttendanceModel?>((
  ref,
) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/v1/attendance/status');
  if (res.data['success'] == true && res.data['data'] != null) {
    return AttendanceModel.fromJson(res.data['data']);
  }
  return null;
});

class AttendanceNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Dịch vụ định vị đang bị tắt.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Quyền truy cập vị trí bị từ chối.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Quyền truy cập vị trí bị từ chối vĩnh viễn, không thể yêu cầu quyền.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
    );
  }

  Future<void> checkIn(BuildContext context, int branchId) async {
    GlobalLoading.show(context);
    try {
      final position = await _determinePosition();

      final dio = ref.read(dioProvider);
      final res = await dio.post(
        '/v1/attendance/check-in',
        data: {
          'branchId': branchId,
          'location': '${position.latitude}, ${position.longitude}',
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
      );

      if (res.data['success'] == true) {
        ref.invalidate(currentAttendanceStatusProvider);
        ref.invalidate(myAttendanceLogsProvider);
        if (context.mounted) {
          GlobalLoading.hide();
          final data = AttendanceModel.fromJson(res.data['data']);
          if (data.status == 'INVALID_LOCATION') {
            _showError(
              context,
              'Check-in thành công nhưng vị trí của bạn không khớp với chi nhánh (> 200m).',
            );
          } else {
            _showSuccess(context, 'Check-in thành công!');
          }
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

  Future<void> checkOut(BuildContext context) async {
    GlobalLoading.show(context);
    try {
      final position = await _determinePosition();

      final dio = ref.read(dioProvider);
      final res = await dio.post(
        '/v1/attendance/check-out',
        data: {
          'location': '${position.latitude}, ${position.longitude}',
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
      );

      if (res.data['success'] == true) {
        ref.invalidate(currentAttendanceStatusProvider);
        ref.invalidate(myAttendanceLogsProvider);
        if (context.mounted) {
          GlobalLoading.hide();
          _showSuccess(context, 'Check-out thành công!');
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

final attendanceProvider = AsyncNotifierProvider<AttendanceNotifier, void>(
  () => AttendanceNotifier(),
);
