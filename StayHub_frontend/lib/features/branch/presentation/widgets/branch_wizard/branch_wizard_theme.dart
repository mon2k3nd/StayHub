/// ─────────────────────────────────────────────────────────────────────────────
/// DESIGN SYSTEM DÙNG CHUNG CHO TOÀN BỘ WIZARD "QUẢN LÝ CHI NHÁNH"
/// ─────────────────────────────────────────────────────────────────────────────
///
/// Trước đây mỗi bước (Step1..Step4) tự khai báo màu, cỡ chữ, bo góc, nút bấm…
/// bằng hằng số rải rác → giao diện lệch nhau, "cám lợn".
///
/// File này gom TẤT CẢ token + widget tái sử dụng về một chỗ, để mọi màn hình
/// của wizard nói CÙNG MỘT ngôn ngữ thiết kế:
///   • Màu sắc  → [WzColors]
///   • Khoảng cách → [WzSpacing]
///   • Bo góc   → [WzRadius]
///   • Chữ      → [WzText]
///   • Widget   → [WzStepHeader], [WzInfoCard], [WzSectionRow],
///                [WzPrimaryButton], [WzNoticeCard], [WzStatTile],
///                [WzChecklistRow], [WzStatusPill]
///
/// Quy ước: mọi widget trong wizard PHẢI dùng các thành phần ở đây, KHÔNG tự
/// hardcode màu / cỡ chữ / bán kính riêng.
library;

import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../../core/components/glass_container.dart';
import '../../../../../core/theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 1. TOKENS
// ─────────────────────────────────────────────────────────────────────────────

/// Bảng màu chuẩn của wizard — ánh xạ trực tiếp từ [AppTheme] để không lệch
/// với phần còn lại của ứng dụng.
abstract final class WzColors {
  static const Color brand = AppTheme.kBrand; // #298FFF
  static const Color brandLight = AppTheme.kBrandLight; // #5FAEFF
  static const Color brandDeep = AppTheme.kBrandDeep; // #1A6FD4
  static const Color success = AppTheme.kSuccess; // #10B981
  static const Color warning = AppTheme.kWarning; // #F59E0B
  static const Color error = AppTheme.kError; // #EF4444

  static const Color textPrimary = AppTheme.kTextPrimary; // #0F172A
  static const Color textSecondary = AppTheme.kTextSecondary; // #475569
  static const Color textMuted = AppTheme.kTextMuted; // #64748B
  static const Color textFaint = Color(0xFF94A3B8);

  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFF8FAFC);
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);
  static const Color scaffold = Color(0xFFF9FAFB);

  /// Gradient thương hiệu dùng cho nút chính / FAB.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brand, brandDeep],
  );

  static const LinearGradient fabGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brand, brandLight],
  );
}

/// Thang khoảng cách 4pt — dùng thống nhất cho padding / margin / gap.
abstract final class WzSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;

  /// Padding ngang chuẩn của mọi màn hình wizard.
  static const EdgeInsets screenH = EdgeInsets.symmetric(horizontal: lg);

  /// Padding chuẩn cho nội dung cuộn của một bước.
  static const EdgeInsets stepContent = EdgeInsets.fromLTRB(lg, sm, lg, xxl);
}

/// Bán kính bo góc chuẩn.
abstract final class WzRadius {
  static const double card = 20;
  static const double tile = 16;
  static const double chip = 10;
  static const double button = 100; // pill
  static const double circle = 999;
}

/// Typography chuẩn của wizard.
abstract final class WzText {
  static const TextStyle screenTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: WzColors.textPrimary,
    height: 1.25,
  );

  static const TextStyle screenSubtitle = TextStyle(
    fontSize: 12.5,
    color: WzColors.textMuted,
    height: 1.35,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: WzColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle rowTitle = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
    color: WzColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    fontSize: 13,
    color: WzColors.textMuted,
    height: 1.45,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11.5,
    color: WzColors.textFaint,
    height: 1.4,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.6,
    color: WzColors.textMuted,
  );

  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static const TextStyle statValue = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.1,
  );

  static const TextStyle statLabel = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    color: WzColors.textMuted,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

/// Header chuẩn cho MÀN HÌNH CHI TIẾT của một bước.
///
/// Gồm: nút back tròn + tiêu đề bước + phụ đề. Dùng thống nhất ở Step1..Step4
/// thay cho việc mỗi màn hình tự vẽ một kiểu.
class WzStepHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onBack;

  const WzStepHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WzSpacing.lg,
        WzSpacing.sm,
        WzSpacing.lg,
        WzSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: WzColors.surface,
              shape: BoxShape.circle,
            ),
            child: CupertinoButton(
              padding: const EdgeInsets.all(8),
              borderRadius: BorderRadius.circular(WzRadius.circle),
              onPressed: onBack ?? () => Navigator.of(context).pop(),
              child: const Icon(
                CupertinoIcons.back,
                color: WzColors.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: WzSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: WzText.screenTitle),
                const SizedBox(height: 2),
                Text(subtitle, style: WzText.screenSubtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ giới thiệu đầu mỗi bước: icon + tiêu đề + mô tả.
class WzInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color accent;

  const WzInfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.accent = WzColors.brand,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(WzSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(WzRadius.tile - 4),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: WzSpacing.md),
              Expanded(child: Text(title, style: WzText.cardTitle)),
            ],
          ),
          const SizedBox(height: WzSpacing.md),
          Text(description, style: WzText.body),
        ],
      ),
    );
  }
}

/// Một dòng mô tả hạng mục trong bước (icon + tiêu đề + phụ đề).
class WzSectionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  const WzSectionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accent = WzColors.brand,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: WzSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: WzText.rowTitle),
                const SizedBox(height: 3),
                Text(subtitle, style: WzText.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Một dòng dữ liệu dạng bảng: nhãn bên trái — giá trị bên phải.
///
/// [value] rỗng/null → hiển thị [placeholder] (mặc định "Chưa cập nhật")
/// bằng màu ĐỎ để chủ nhà thấy ngay trường còn thiếu.
class WzInfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final String placeholder;
  final bool emphasize;

  const WzInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.placeholder = 'Chưa cập nhật',
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final v = value?.trim() ?? '';
    final missing = v.isEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: WzColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: WzSpacing.sm),
          Expanded(
            child: Text(
              missing ? placeholder : v,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                fontWeight: missing || emphasize
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: missing
                    ? WzColors.error
                    : (emphasize ? WzColors.brandDeep : WzColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Khối checklist dạng bảng: tiêu đề mục + các dòng nhãn/giá trị.
///
/// [rows] là danh sách (nhãn, giá trị). Giá trị rỗng → hiện "Chưa cập nhật"
/// màu đỏ. Dùng bảng có hàng/cột thay vì chip cho giao diện chững chạc hơn.
class WzChecklistRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<(String, String?)> rows;
  final Color accent;

  const WzChecklistRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.rows = const [],
    this.accent = WzColors.brand,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: WzSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(icon, size: 18, color: accent),
              ),
              const SizedBox(width: WzSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: WzText.rowTitle),
                    const SizedBox(height: 2),
                    Text(subtitle, style: WzText.caption),
                  ],
                ),
              ),
            ],
          ),
          if (rows.isNotEmpty) ...[
            const SizedBox(height: WzSpacing.sm),
            Container(
              margin: const EdgeInsets.only(left: 30),
              padding: const EdgeInsets.symmetric(
                horizontal: WzSpacing.md,
                vertical: WzSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: WzColors.surfaceSoft,
                borderRadius: BorderRadius.circular(WzRadius.chip),
                border: Border.all(color: WzColors.divider),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    WzInfoRow(label: rows[i].$1, value: rows[i].$2),
                    if (i != rows.length - 1)
                      const Divider(height: 1, color: WzColors.divider),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Thẻ cảnh báo / ghi chú (info, warning, success).
enum WzNoticeTone { info, warning, success }

class WzNoticeCard extends StatelessWidget {
  final WzNoticeTone tone;
  final String message;

  const WzNoticeCard({super.key, required this.tone, required this.message});

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon, Color textColor) = switch (tone) {
      WzNoticeTone.success => (
        WzColors.success,
        CupertinoIcons.info_circle_fill,
        const Color(0xFF047857),
      ),
      WzNoticeTone.warning => (
        WzColors.warning,
        CupertinoIcons.exclamationmark_triangle_fill,
        const Color(0xFF92400E),
      ),
      WzNoticeTone.info => (
        WzColors.brand,
        CupertinoIcons.info_circle_fill,
        WzColors.brandDeep,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(WzRadius.tile),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, height: 1.45, color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Nút hành động chính (pill, gradient) — dùng thống nhất cho mọi bước.
class WzPrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool loading;
  final Color? color;
  final bool enabled;

  const WzPrimaryButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.loading = false,
    this.color,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final bool active = enabled && !loading && onPressed != null;
    final Color base = color ?? WzColors.brand;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(WzRadius.button),
      onPressed: active ? onPressed : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [base, Color.lerp(base, Colors.black, 0.18)!],
                )
              : null,
          color: active ? null : WzColors.border,
          borderRadius: BorderRadius.circular(WzRadius.button),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: base.withValues(alpha: 0.32),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: loading
            ? const CupertinoActivityIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: WzSpacing.sm),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WzText.button,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Ô số liệu (giá trị lớn + nhãn nhỏ) dùng trong các thẻ thống kê.
class WzStatTile extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const WzStatTile({
    super.key,
    required this.value,
    required this.label,
    this.color = WzColors.brand,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: WzText.statValue.copyWith(color: color)),
        const SizedBox(height: 2),
        Text(label, style: WzText.statLabel),
      ],
    );
  }
}

/// Nhãn trạng thái nhỏ (pill) — "Hoàn tất", "Cần thực hiện", "Chưa mở khoá"…
class WzStatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const WzStatusPill({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// Nhãn nhỏ dạng viền (icon + chữ) dùng cho meta của thẻ chi nhánh.
class WzMetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const WzMetaChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: WzColors.surfaceSoft,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: WzColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: WzColors.textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: WzColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Thanh tiến độ 4 bước dùng chung (tổng quan + thẻ chi nhánh).
class WzProgressBar extends StatelessWidget {
  final int done;
  final int total;
  final String? caption;
  final double height;

  const WzProgressBar({
    super.key,
    required this.done,
    this.total = 4,
    this.caption,
    this.height = 7,
  });

  @override
  Widget build(BuildContext context) {
    final double ratio = (done / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: height,
            backgroundColor: WzColors.border,
            valueColor: const AlwaysStoppedAnimation<Color>(WzColors.brand),
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: 5),
          Text(
            caption!,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: WzColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

/// Scaffold chuẩn cho MÀN HÌNH CHI TIẾT của một bước.
///
/// Gồm header ([WzStepHeader]) + vùng nội dung cuộn + thanh nút hành động dưới
/// cùng (tuỳ chọn). Nhờ đó Step1..Step4 có bố cục giống hệt nhau.
class WzStepScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? bottomBar;
  final VoidCallback? onBack;

  const WzStepScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.bottomBar,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final double keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        color: WzColors.scaffold,
        child: Column(
          children: [
            WzStepHeader(title: title, subtitle: subtitle, onBack: onBack),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  WzSpacing.lg,
                  WzSpacing.sm,
                  WzSpacing.lg,
                  (keyboard > 0 ? keyboard : 0) + (bottomBar != null ? 96 : 24),
                ),
                children: children,
              ),
            ),
            if (bottomBar != null)
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: WzColors.scaffold.withValues(alpha: 0.92),
                      border: const Border(
                        top: BorderSide(color: Color(0x12000000), width: 0.5),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          WzSpacing.lg,
                          WzSpacing.md,
                          WzSpacing.lg,
                          WzSpacing.md,
                        ),
                        child: bottomBar,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
