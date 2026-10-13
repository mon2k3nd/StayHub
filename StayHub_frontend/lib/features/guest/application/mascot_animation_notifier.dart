import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Các hành động (state) của linh vật StayHub.
///
/// Đây là "ý nghĩa" của hành động, KHÔNG phải tên clip trong file GLB.
/// Tên clip được khai báo ở [MascotAction.clipName] và phải khớp **chính xác
/// 100% (case-sensitive)** với tên Animation Track trong file `.glb`.
enum MascotAction {
  /// Trạng thái nghỉ — track `Idle` (loop).
  idle,

  // STORY CLIPS – one‑shot (không lặp)
  /// Rơi từ trên cao – track `Fall` (one‑shot).
  fall,

  /// Buồn bã – track `Sad` (one‑shot).
  sad,

  /// Đứng dậy – track `StandUp` (one‑shot).
  standUp,

  /// Lấy điện thoại và nhảy lên – track `PhoneJump` (one‑shot).
  phoneJump,

  /// Rơi vào phòng – track `RoomFall` (one‑shot).
  roomFall,

  /// Ăn mừng – track `Celebrate` (one‑shot).
  celebrate,

  /// Xin chào khi mở App — track `Wave` (one‑shot).
  greeting,

  /// Đang tìm kiếm / load dữ liệu — track `Walking` (loop).
  searching,

  /// Thành công (đặt phòng, eKYC) — track `Dance` (one‑shot).
  success,

  /// Lỗi / không có kết quả — track `Sad` (one‑shot).
  error,

  /// Người dùng chạm vào linh vật — track `Jump` (one‑shot).
  touch;

  /// Tên clip hoạt ảnh tương ứng trong file GLB.
  ///
  /// Bắt buộc khớp chính xác tên Animation Track mà team 3D đặt trong `.glb`
  /// (xem bảng "Required Animation Tracks" trong Design Handoff).
  String get clipName {
    switch (this) {
      case MascotAction.idle:
        return 'Idle';
      case MascotAction.fall:
        return 'Fall';
      case MascotAction.sad:
        return 'Sad';
      case MascotAction.standUp:
        return 'StandUp';
      case MascotAction.phoneJump:
        return 'PhoneJump';
      case MascotAction.roomFall:
        return 'RoomFall';
      case MascotAction.celebrate:
        return 'Celebrate';
      case MascotAction.greeting:
        return 'Wave';
      case MascotAction.searching:
        return 'Walking';
      case MascotAction.success:
        return 'Dance';
      case MascotAction.error:
        return 'Sad';
      case MascotAction.touch:
        return 'Jump';
    }
  }

  /// Clip có lặp lại liên tục hay không (theo cột "Lặp lại" trong handoff).
  ///
  /// - `Idle` và `Walking` lặp vô hạn.
  /// - `Wave`, `Dance`, `Sad`, `Jump` là one-shot, phát xong thì quay về `Idle`.
  bool get isLooping {
    switch (this) {
      case MascotAction.idle:
      case MascotAction.searching:
        return true;
      case MascotAction.greeting:
      case MascotAction.success:
      case MascotAction.error:
      case MascotAction.touch:
      // STORY CLIPS – one‑shot
      case MascotAction.fall:
      case MascotAction.sad:
      case MascotAction.standUp:
      case MascotAction.phoneJump:
      case MascotAction.roomFall:
      case MascotAction.celebrate:
        return false;
    }
  }

  /// Thời lượng hiển thị mặc định trước khi tự động quay về [MascotAction.idle].
  ///
  /// Với clip loop ([isLooping] = `true`) giá trị này là `null` — linh vật giữ
  /// trạng thái đó cho tới khi có hành động khác thay thế.
  Duration? get defaultDuration {
    switch (this) {
      case MascotAction.idle:
      case MascotAction.searching:
        return null;
      case MascotAction.greeting:
        return const Duration(seconds: 3);
      case MascotAction.fall:
        return const Duration(seconds: 2);
      case MascotAction.sad:
        return const Duration(seconds: 3);
      case MascotAction.standUp:
        return const Duration(seconds: 2);
      case MascotAction.phoneJump:
        return const Duration(seconds: 2);
      case MascotAction.roomFall:
        return const Duration(seconds: 3);
      case MascotAction.celebrate:
        return const Duration(seconds: 4);
      case MascotAction.success:
        return const Duration(seconds: 4);
      case MascotAction.error:
        return const Duration(seconds: 3);
      case MascotAction.touch:
        return const Duration(seconds: 2);
    }
  }

  /// Cờ báo model GLB hiện tại đã có clip thật hay chưa.
  ///
  /// Đặt `true` sau khi team 3D bàn giao file `.glb` có đủ 6 track ở trên.
  /// Khi còn `false`, [Mascot3DStage] sẽ dùng hiệu ứng thủ tục thay vì
  /// gọi `animationName` (tránh model_viewer_plus log lỗi "animation not found").
  static const bool hasRealClip = false;
}

/// Quản lý trạng thái hoạt ảnh của linh vật.
///
/// Tự động đưa linh vật trở về trạng thái [MascotAction.idle] sau khi một
/// hành động one-shot kết thúc. Timer được huỷ an toàn trong [dispose] để
/// tránh rò rỉ bộ nhớ (memory leak) khi provider bị gỡ bỏ.
class MascotAnimationNotifier extends Notifier<MascotAction> {
  Timer? _resetTimer;

  @override
  MascotAction build() {
    // Đảm bảo timer luôn được dọn dẹp khi provider bị dispose.
    ref.onDispose(() {
      _resetTimer?.cancel();
      _resetTimer = null;
    });
    return MascotAction.idle;
  }

  /// Phát một hoạt ảnh cụ thể.
  ///
  /// Nếu [duration] được truyền, linh vật tự trả về [MascotAction.idle] sau
  /// khoảng thời gian đó. Nếu bỏ trống, dùng [MascotAction.defaultDuration] —
  /// và với clip loop thì linh vật giữ nguyên trạng thái.
  void playAction(MascotAction action, {Duration? duration}) {
    _resetTimer?.cancel();
    _resetTimer = null;

    // Tránh phát lại cùng một action gây rebuild thừa.
    if (state != action) {
      state = action;
    }

    final effectiveDuration = duration ?? action.defaultDuration;
    if (effectiveDuration != null) {
      _resetTimer = Timer(effectiveDuration, () {
        state = MascotAction.idle;
      });
    }
  }

  /// Đưa linh vật về trạng thái nghỉ ngay lập tức.
  void reset() {
    _resetTimer?.cancel();
    _resetTimer = null;
    if (state != MascotAction.idle) {
      state = MascotAction.idle;
    }
  }

  /// Phát một chuỗi các hành động nối tiếp nhau.
  ///
  /// Mỗi hành động sẽ được phát trong thời gian [defaultDuration] (hoặc thời gian tùy chỉnh).
  Future<void> playSequence(List<MascotAction> actions) async {
    for (final a in actions) {
      playAction(a);
      final wait = a.defaultDuration ?? const Duration(seconds: 1);
      await Future.delayed(wait);
    }
  }
}

final mascotAnimationProvider =
    NotifierProvider<MascotAnimationNotifier, MascotAction>(
      MascotAnimationNotifier.new,
    );
