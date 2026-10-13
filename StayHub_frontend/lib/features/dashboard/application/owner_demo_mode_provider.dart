import 'package:flutter_riverpod/flutter_riverpod.dart';

class OwnerDemoModeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setDemoMode(bool value) {
    state = value;
  }
}

/// Provider quản lý trạng thái Chế độ Khám phá Thử nghiệm (Demo Sandbox) cho Chủ nhà mới.
/// Cho phép người thuê phòng trải nghiệm trước Dashboard, AI Giám đốc vận hành
/// và các công cụ quản lý trọ mà không bị chặn cứng ngay từ đầu.
final ownerDemoModeProvider =
    NotifierProvider<OwnerDemoModeNotifier, bool>(OwnerDemoModeNotifier.new);
