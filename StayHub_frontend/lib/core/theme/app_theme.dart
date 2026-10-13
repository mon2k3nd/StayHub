import 'package:flutter/cupertino.dart';

// ─────────────────────────────────────────────────────────────────────────────
// iOS 26 "Liquid Glass" Design System — Warm Cream + Sky Blue Edition
// Accent: #69B1FF (Sky Blue)  |  Base: warm cream/beige (khớp ảnh nền header)
// Dark bg: rich deep-blue slate, not pure black
// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  // ── Global font family ─────────────────────────────────────────────────────
  // Dùng font Roboto đóng gói sẵn trong assets/fonts (khai báo ở pubspec.yaml
  // với family "CustomRoboto"). Font này hỗ trợ đầy đủ tiếng Việt và hiển thị
  // ổn định, sắc nét, KHÔNG phụ thuộc mạng (khác với GoogleFonts tải runtime).
  static const String kFontFamily = 'CustomRoboto';
  static const Color kBrand = Color(0xFF69B1FF); // Sky Blue — brand primary
  static const Color kBrandLight = Color(
    0xFF8AC4FF,
  ); // Sky Blue lighter highlight
  static const Color kBrandDeep = Color(0xFF4A90E2); // Sky Blue pressed state
  static const Color kBrandGlow = Color(0xFFB3D9FF); // Sky Blue glow / tint
  static const Color kAccentColor = Color(0xFF69B1FF); // alias for kBrand

  // ── Surface (Light) — Sky Blue + Ice Surface Edition ──────────────────────
  // Đã chuyển sang nền trắng tinh theo yêu cầu thiết kế mới
  static const Color kBackgroundLight = Color(0xFFF9FAFB); // Khói nhạt
  static const Color kSurface1Light = Color(
    0xFFFFFFFF,
  ); // trắng tinh khiết — card nổi
  static const Color kSurface2Light = Color(
    0xFFE1EFFF,
  ); // xanh sky nhạt — highlight/badge
  static const Color kGlassColorLight = Color(
    0xCCF4F8FC,
  ); // kính mờ ánh xanh băng — glass
  static const Color kGlassTintLight = Color(0x1A69B1FF); // sky-blue tint nhẹ

  // ── Surface (Dark) — Deep-space sky blue  ──────────────────────────────────
  static const Color kBackgroundDark = Color(0xFF07111F); // deep navy
  static const Color kSurface1Dark = Color(0xFF0E1B2E); // card bg
  static const Color kSurface2Dark = Color(0xFF122438); // elevated panel
  static const Color kGlassColorDark = Color(0x4D0E1B2E); // navy glass
  static const Color kGlassTintDark = Color(0x22298FFF); // sky-blue glow dark

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color kTextPrimary = Color(0xFF1E293B); // Text color from rule
  static const Color kTextPrimaryDark = Color(0xFFF2F8FF); // sky-blue white
  static const Color kTextSecondary = Color(0xFF475569); // Slate 600
  static const Color kTextSecondaryDark = Color(0xFF9CCBFF); // sky-blue muted
  static const Color kTextMuted = Color(0xFF64748B); // Slate 500
  static const Color kTextMutedDark = Color(0xFF5FAEFF); // sky-blue light

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color kSuccess = Color(0xFF10B981); // Emerald 500
  static const Color kWarning = Color(0xFFF59E0B); // Amber 500
  static const Color kError = Color(0xFFEF4444); // Red 500
  static const Color kGoldColor = Color(0xFFFFD700);

  // ── Border / Divider ───────────────────────────────────────────────────────
  static const Color kBorderColor = Color(
    0xFFD3E4F4,
  ); // viền xanh pastel thanh lịch
  static const Color kBorderColorDark = Color(0xFF1B3A5C); // deep blue border
  static const Color kSurfaceBlue = Color(
    0xFFE6F2FF,
  ); // sky blue tint surface phụ

  // ── Legacy aliases ─────────────────────────────────────────────────────────
  static const Color kBackgroundLightGray = Color(
    0xFFE5EEF7,
  ); // xanh xám thanh thoát

  // ── Premium Shadows ────────────────────────────────────────────────────────
  static const List<BoxShadow> kPremiumShadowLight = [
    BoxShadow(
      color: Color(
        0x1469B1FF,
      ), // bóng đổ ám xanh nhạt 0px 8px 24px rgba(105, 177, 255, 0.08)
      offset: Offset(0, 8),
      blurRadius: 24,
      spreadRadius: 0,
    ),
    BoxShadow(color: Color(0x080F2A4A), offset: Offset(0, 1), blurRadius: 6),
  ];

  static const List<BoxShadow> kPremiumShadowDark = [
    BoxShadow(
      color: Color(0x4D000000),
      offset: Offset(0, 6),
      blurRadius: 30,
      spreadRadius: -4,
    ),
    BoxShadow(color: Color(0x22298FFF), offset: Offset(0, 2), blurRadius: 12),
  ];

  // ── iOS 26 Liquid Glass — Light Theme ──────────────────────────────────────
  static CupertinoThemeData get lightTheme {
    const base = kFontFamily;
    return const CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: kBrand,
      scaffoldBackgroundColor: kBackgroundLight,
      barBackgroundColor: kGlassColorLight,
      textTheme: CupertinoTextThemeData(
        primaryColor: kBrand,
        textStyle: TextStyle(
          fontFamily: base,
          color: kTextPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        navTitleTextStyle: TextStyle(
          fontFamily: base,
          color: kTextPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        navLargeTitleTextStyle: TextStyle(
          fontFamily: base,
          color: kTextPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 34,
          letterSpacing: -1.2,
        ),
      ),
    );
  }

  // ── iOS 26 Liquid Glass — Dark Theme ───────────────────────────────────────
  static CupertinoThemeData get darkTheme {
    const base = kFontFamily;
    return const CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: kBrandLight,
      scaffoldBackgroundColor: kBackgroundDark,
      barBackgroundColor: kGlassColorDark,
      textTheme: CupertinoTextThemeData(
        primaryColor: kBrandLight,
        textStyle: TextStyle(
          fontFamily: base,
          color: kTextPrimaryDark,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        navTitleTextStyle: TextStyle(
          fontFamily: base,
          color: kTextPrimaryDark,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        navLargeTitleTextStyle: TextStyle(
          fontFamily: base,
          color: kTextPrimaryDark,
          fontWeight: FontWeight.w800,
          fontSize: 34,
          letterSpacing: -1.2,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// iOS 26 Liquid Glass Gradients — Warm Cream + Sky Blue Edition
// ─────────────────────────────────────────────────────────────────────────────
class PremiumGradients {
  // Brand sky-blue gradient — primary CTA buttons, hero banners
  static const LinearGradient skyBrand = LinearGradient(
    colors: [Color(0xFF69B1FF), Color(0xFF4A90E2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Aurora — card highlights (trắng sáng → xanh sky)
  static const LinearGradient aurora = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFE1EFFF), Color(0xFF69B1FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Soft sky — nền/hero gradient đồng bộ header
  static const LinearGradient warmCream = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFEBF2F8), Color(0xFFDCEAF5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Guest home background — Đổi sang nền trắng đồng bộ với thiết kế mới
  static const LinearGradient guestHomeBackground = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFFFFFF), Color(0xFFFFFFFF)],
    stops: [0.0, 0.45, 1.0],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Deep ocean — dark backgrounds
  static const LinearGradient deepOcean = LinearGradient(
    colors: [Color(0xFF07111F), Color(0xFF0E2340), Color(0xFF1B4A7E)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Cyan mint — success / availability
  static const LinearGradient cyanMint = LinearGradient(
    colors: [Color(0xFF22D3EE), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Sunset (warm accent)
  static const LinearGradient sunset = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Legacy compat
  static const LinearGradient oceanBlue = skyBrand;
  static const LinearGradient purpleNebula = aurora;
  static const LinearGradient fireOrange = sunset;
  static const LinearGradient emeraldGreen = cyanMint;
}

// ─────────────────────────────────────────────────────────────────────────────
// iOS 26 Liquid Glass material — reusable paint helper
// Usage: paint with LiquidGlassPainter.forLight() on any CustomPainter
// ─────────────────────────────────────────────────────────────────────────────
class LiquidGlassTokens {
  // Glass background colors
  static const Color surfaceLight = Color(0xCCF4F8FC); // kính mờ ánh xanh băng
  static const Color surfaceDark = Color(0xB80E1B2E);

  // Specular / iridescent shimmer on glass edges
  static const Color shimmerLight = Color(0x66FFFFFF);
  static const Color shimmerDark = Color(0x22298FFF);

  // Inner glow on interactive glass
  static const Color glowBlue = Color(0x4069B1FF);
  static const Color glowSky = Color(0x3069B1FF);

  // Border highlights (top-left bright, bottom-right muted)
  static const Color borderTopLight = Color(0xE6FFFFFF);
  static const Color borderBotLight = Color(0x3369B1FF);
  static const Color borderTopDark = Color(0x44298FFF);
  static const Color borderBotDark = Color(0x11298FFF);

  // Blur values
  static const double blurCard = 20.0;
  static const double blurSheet = 30.0;
  static const double blurOverlay = 40.0;
  static const double blurNav = 24.0;
}
