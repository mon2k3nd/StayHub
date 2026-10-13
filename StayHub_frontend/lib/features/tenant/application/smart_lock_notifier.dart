import 'package:flutter_riverpod/flutter_riverpod.dart';

class SmartLockState {
  final bool isLocked;
  final bool isProcessing;
  final String? error;

  const SmartLockState({
    this.isLocked = true,
    this.isProcessing = false,
    this.error,
  });

  SmartLockState copyWith({bool? isLocked, bool? isProcessing, String? error}) {
    return SmartLockState(
      isLocked: isLocked ?? this.isLocked,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
    );
  }
}

class SmartLockNotifier extends Notifier<SmartLockState> {
  @override
  build() {
    return const SmartLockState();
  }

  Future<void> toggleLock() async {
    if (state.isProcessing) return;

    state = state.copyWith(isProcessing: true, error: null);

    try {
      // Thay thế bằng API thật trong tương lai
      // final iotRepo = ref.read(iotRepositoryProvider);
      // await iotRepo.toggleDoorLock(roomId);

      // Simulating network/hardware delay for now until IoT module is integrated
      await Future.delayed(const Duration(milliseconds: 1500));

      state = state.copyWith(isLocked: !state.isLocked, isProcessing: false);
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Lỗi kết nối Bluetooth/IoT. Vui lòng thử lại.',
      );
    }
  }
}

final smartLockProvider = NotifierProvider<SmartLockNotifier, SmartLockState>(
  SmartLockNotifier.new,
);
