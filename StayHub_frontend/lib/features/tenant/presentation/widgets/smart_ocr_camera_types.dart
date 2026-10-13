part of 'smart_ocr_camera.dart';

// ══════════════════════════════════════════════════════════════
// 3-STATE UX ENUM
// ══════════════════════════════════════════════════════════════
/// Trạng thái khung hình theo bảng quy chuẩn UX/UI
enum _CaptureState {
  /// Trạng thái 1 – Chờ / Chưa đạt: khung trắng #FFFFFF, border 2px
  idle,

  /// Trạng thái 2 – Đang đếm ổn định: khung vàng #FFC107, border 2px
  stabilizing,

  /// Trạng thái 3 – Auto-capture thành công: khung huỳnh quang #00E676,
  /// border 4px + Glow effect
  captured,
}

// ══════════════════════════════════════════════════════════════
// Pipeline gate result
// ══════════════════════════════════════════════════════════════
enum _GateStatus { pass, fail }

class _PipelineResult {
  final _GateStatus position;
  final _GateStatus tilt;
  final _GateStatus blur;
  final _GateStatus glare;
  final String hint;

  const _PipelineResult({
    required this.position,
    required this.tilt,
    required this.blur,
    required this.glare,
    required this.hint,
  });

  bool get allPass =>
      position == _GateStatus.pass &&
      tilt == _GateStatus.pass &&
      blur == _GateStatus.pass &&
      glare == _GateStatus.pass;
}

// ══════════════════════════════════════════════════════════════
// Error Type Enum – Each maps to icon + message + border color
// ══════════════════════════════════════════════════════════════
enum _ErrorType {
  none,
  occlusion, // Tay che/vật che thẻ
  glare, // Chói đèn / lóa sáng
  tooFar, // Quá xa camera
  blur, // Ảnh mờ / rung tay
  wrongSide, // Lật nhầm mặt thẻ
  multipleFaces, // Nhiều khuôn mặt
  maskDetected, // Khẩu trang / kính râm
  lowLight, // Môi trường tối
  tooFast, // Quay đầu quá nhanh
  tooClose, // Quá gần camera
}

extension _ErrorTypeInfo on _ErrorType {
  String get message {
    switch (this) {
      case _ErrorType.none:
        return '';
      case _ErrorType.occlusion:
        return 'Bỏ tay / vật cản ra khỏi thẻ';
      case _ErrorType.glare:
        return 'Nghiêng nhẹ để tránh ánh sáng phản chiếu';
      case _ErrorType.tooFar:
        return 'Lại gần hơn để camera nhận diện thẻ';
      case _ErrorType.blur:
        return 'Giữ yên điện thoại để lấy nét';
      case _ErrorType.wrongSide:
        return 'Vui lòng lật đúng mặt yêu cầu';
      case _ErrorType.multipleFaces:
        return 'Chỉ giữ một khuôn mặt trong khung';
      case _ErrorType.maskDetected:
        return 'Tháo khẩu trang và kính râm';
      case _ErrorType.lowLight:
        return 'Di chuyển ra nơi có đủ ánh sáng';
      case _ErrorType.tooFast:
        return 'Quay đầu chậm lại';
      case _ErrorType.tooClose:
        return 'Lùi ra xa camera một chút';
    }
  }

  bool get isError => this != _ErrorType.none;

  Color get bannerBg {
    if (!isError) return AppTheme.kTextPrimary.withValues(alpha: 0.80);
    switch (this) {
      case _ErrorType.glare:
        return AppTheme.kWarning.withValues(alpha: 0.18);
      default:
        return AppTheme.kError.withValues(alpha: 0.18);
    }
  }

  Color get bannerBorder {
    if (!isError) return AppTheme.kBrandLight.withValues(alpha: 0.4);
    switch (this) {
      case _ErrorType.glare:
        return AppTheme.kWarning.withValues(alpha: 0.7);
      default:
        return AppTheme.kError.withValues(alpha: 0.6);
    }
  }

  Color get textColor {
    if (!isError) return Colors.white;
    switch (this) {
      case _ErrorType.glare:
        return const Color(0xFFFBBF24);
      default:
        return const Color(0xFFFCA5A5);
    }
  }

  Color get frameBorderColor {
    switch (this) {
      case _ErrorType.none:
        return AppTheme.kBrandDeep;
      case _ErrorType.glare:
        return AppTheme.kWarning;
      case _ErrorType.blur:
        return const Color(0xFF94A3B8);
      default:
        return AppTheme.kError;
    }
  }
}

// ══════════════════════════════════════════════════════════════
// UX Color Constants (theo bảng quy chuẩn)
// ══════════════════════════════════════════════════════════════
class _UXColors {
  /// State 1: Chờ – Xanh Sky
  // ignore: unused_field
  static const idle = AppTheme.kBrandDeep;

  /// State 2: Đang lấy nét ổn định – Xanh Sky nhạt
  static const stabilizing = AppTheme.kBrandLight;

  /// State 3: Chụp thành công – Emerald Green
  static const captured = AppTheme.kSuccess;

  /// Màu lỗi (blur, glare fail) – Coral Red
  // ignore: unused_field
  static const error = AppTheme.kError;
}
