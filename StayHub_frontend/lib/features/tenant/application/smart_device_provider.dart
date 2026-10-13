import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/core_providers.dart';
import '../data/models/smart_device_model.dart';
import '../data/repositories/smart_device_repository.dart';

part 'smart_device_provider.g.dart';

@riverpod
SmartDeviceRepository smartDeviceRepository(Ref ref) {
  final dio = ref.watch(dioProvider);
  return SmartDeviceRepository(dio);
}

@riverpod
class SmartDevice extends _$SmartDevice {
  @override
  FutureOr<List<SmartDeviceModel>> build(int roomId) async {
    final repository = ref.watch(smartDeviceRepositoryProvider);
    try {
      await repository.seedDevices(roomId);
    } catch (_) {}
    return repository.getDevicesByRoom(roomId);
  }

  Future<void> toggleDevice(int deviceId, String newStatus) async {
    final oldState = state;
    if (state.hasValue) {
      final devices = state.value!;
      final updatedDevices = devices.map((d) {
        if (d.id == deviceId) {
          return d.copyWith(status: newStatus);
        }
        return d;
      }).toList();
      state = AsyncData(updatedDevices);
    }

    try {
      final repository = ref.read(smartDeviceRepositoryProvider);
      final updatedDevice = await repository.toggleDevice(deviceId, newStatus);
      if (state.hasValue) {
        final devices = state.value!;
        final updatedDevices = devices.map((d) {
          if (d.id == deviceId) {
            return updatedDevice;
          }
          return d;
        }).toList();
        state = AsyncData(updatedDevices);
      }
    } catch (e) {
      state = oldState;
    }
  }

  Future<void> updateSettings(
    int deviceId,
    Map<String, dynamic> newSettings,
  ) async {
    final oldState = state;
    if (state.hasValue) {
      final devices = state.value!;
      final updatedDevices = devices.map((d) {
        if (d.id == deviceId) {
          return d.copyWith(settings: jsonEncode(newSettings));
        }
        return d;
      }).toList();
      state = AsyncData(updatedDevices);
    }

    try {
      final repository = ref.read(smartDeviceRepositoryProvider);
      final updatedDevice = await repository.updateSettings(
        deviceId,
        newSettings,
      );
      if (state.hasValue) {
        final devices = state.value!;
        final updatedDevices = devices.map((d) {
          if (d.id == deviceId) {
            return updatedDevice;
          }
          return d;
        }).toList();
        state = AsyncData(updatedDevices);
      }
    } catch (e) {
      state = oldState;
    }
  }
}
