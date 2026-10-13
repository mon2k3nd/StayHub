import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async' show unawaited;

class IotDevice {
  final String id;
  final String name;
  final String type; // 'lock', 'meter', 'camera'
  final String location;
  final bool isOnline;
  final bool isOn;
  final double? batteryLevel;

  const IotDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    this.isOnline = true,
    this.isOn = false,
    this.batteryLevel,
  });

  IotDevice copyWith({bool? isOnline, bool? isOn, double? batteryLevel}) {
    return IotDevice(
      id: id,
      name: name,
      type: type,
      location: location,
      isOnline: isOnline ?? this.isOnline,
      isOn: isOn ?? this.isOn,
      batteryLevel: batteryLevel ?? this.batteryLevel,
    );
  }
}

class IotState {
  final bool isLoading;
  final List<IotDevice> devices;

  const IotState({this.isLoading = false, this.devices = const []});

  IotState copyWith({bool? isLoading, List<IotDevice>? devices}) {
    return IotState(
      isLoading: isLoading ?? this.isLoading,
      devices: devices ?? this.devices,
    );
  }
}

class IotNotifier extends Notifier<IotState> {
  @override
  build() {
    unawaited(Future.microtask(_loadDevices));
    return const IotState();
  }

  Future<void> _loadDevices() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 1000));

    final mockDevices = [
      const IotDevice(
        id: 'l1',
        name: 'Khóa cửa P101',
        type: 'lock',
        location: 'Tầng 1 - P101',
        isOn: true,
        batteryLevel: 0.85,
      ),
      const IotDevice(
        id: 'l2',
        name: 'Khóa cửa P102',
        type: 'lock',
        location: 'Tầng 1 - P102',
        isOn: false,
        batteryLevel: 0.15,
      ),
      const IotDevice(
        id: 'm1',
        name: 'Đồng hồ điện Tầng 1',
        type: 'meter',
        location: 'Hành lang T1',
        isOn: true,
      ),
      const IotDevice(
        id: 'c1',
        name: 'Camera Cổng chính',
        type: 'camera',
        location: 'Cổng Ra Vào',
        isOn: true,
        isOnline: true,
      ),
      const IotDevice(
        id: 'c2',
        name: 'Camera Bãi Xe',
        type: 'camera',
        location: 'Hầm B1',
        isOn: true,
        isOnline: false,
      ),
    ];

    // if (!mounted) return;
    state = state.copyWith(isLoading: false, devices: mockDevices);
  }

  Future<void> toggleDevice(String id) async {
    final idx = state.devices.indexWhere((d) => d.id == id);
    if (idx == -1) return;

    final device = state.devices[idx];
    if (!device.isOnline) return;

    // Optimistic Update
    final updatedDevices = List<IotDevice>.from(state.devices);
    updatedDevices[idx] = device.copyWith(isOn: !device.isOn);
    state = state.copyWith(devices: updatedDevices);

    // Simulate API Call
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      // Nếu lỗi, rollback:
      // state = state.copyWith(devices: oldDevices);
    } catch (e) {
      // Handle error
    }
  }
}

final iotProvider = NotifierProvider<IotNotifier, IotState>(IotNotifier.new);
