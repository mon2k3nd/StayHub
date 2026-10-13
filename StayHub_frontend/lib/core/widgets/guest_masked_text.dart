import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// GuestMaskedText — DRY widget bảo mật cho Guest Mode (chưa đăng nhập).
///
/// Tuân thủ NĐ 13/2023/NĐ-CP về bảo vệ dữ liệu cá nhân: khi người dùng chưa
/// đăng nhập, các thông tin nhạy cảm (SĐT chủ nhà, số nhà chi tiết, eKYC)
/// PHẢI được che (mask) và thay bằng lời mời đăng nhập.
///
/// Cách dùng:
/// ```dart
/// GuestMaskedText(
///   isLoggedIn: isLoggedIn,
///   value: ownerPhone,
///   maskType: GuestMaskType.phone,
///   onLoginTap: () => context.push('/login'),
/// )
/// ```
/// ─────────────────────────────────────────────────────────────────────────────

enum GuestMaskType {
  /// SĐT: 0901234567 -> 0901***567
  phone,

  /// Số nhà chi tiết: "Số 12A, Nguyễn Trãi" -> "***, Nguyễn Trãi"
  address,

  /// eKYC / CCCD: che toàn bộ
  ekyc,

  /// Tên riêng: "Nguyễn Văn A" -> "N*** A"
  name,
}

class GuestMaskedText extends StatelessWidget {
  final bool isLoggedIn;
  final String? value;
  final GuestMaskType maskType;
  final VoidCallback? onLoginTap;
  final TextStyle? style;
  final String? fallback;

  const GuestMaskedText({
    super.key,
    required this.isLoggedIn,
    required this.value,
    required this.maskType,
    this.onLoginTap,
    this.style,
    this.fallback,
  });

  /// Che dữ liệu theo loại. Trả về null nếu không có gì để hiển thị.
  static String? mask(String? raw, GuestMaskType type) {
    if (raw == null || raw.trim().isEmpty) return null;
    final v = raw.trim();

    switch (type) {
      case GuestMaskType.phone:
        final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.length < 7) return '***';
        return '${digits.substring(0, 4)}***${digits.substring(digits.length - 3)}';

      case GuestMaskType.address:
        // Giữ lại phần đường/phường, che số nhà chi tiết ở đầu chuỗi.
        return v.replaceAll(
          RegExp(r'^(Số\s*)?[0-9A-Za-zÀ-ỹ/]+(\s*[A-Za-zÀ-ỹ]?)?\s*,?\s*'),
          '***, ',
        );

      case GuestMaskType.ekyc:
        return '•••• •••• ••••';

      case GuestMaskType.name:
        final parts = v.split(RegExp(r'\s+'));
        final firstInitial = parts.first.isNotEmpty ? parts.first[0] : '';
        if (parts.length == 1) {
          return '$firstInitial***';
        }
        return '$firstInitial*** ${parts.last}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveStyle =
        style ??
        const TextStyle(
          fontSize: 14,
          color: AppTheme.kTextPrimary,
          fontWeight: FontWeight.w500,
        );

    // Đã đăng nhập → hiển thị bình thường (null-safe fallback).
    if (isLoggedIn) {
      return Text(
        value?.trim().isNotEmpty == true ? value!.trim() : (fallback ?? '—'),
        style: effectiveStyle,
      );
    }

    // Chưa đăng nhập → che + mời đăng nhập.
    final masked = mask(value, maskType);
    return GestureDetector(
      onTap: onLoginTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 14, color: AppTheme.kBrand),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              masked ?? 'Đăng nhập để xem',
              style: effectiveStyle.copyWith(
                color: AppTheme.kTextSecondary,
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onLoginTap != null) ...[
            const SizedBox(width: 6),
            Text(
              'Đăng nhập để xem',
              style: effectiveStyle.copyWith(
                color: AppTheme.kBrand,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
