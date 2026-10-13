export 'app_theme.dart';
import 'package:flutter/cupertino.dart';

// Import tường minh để dùng AppTheme.kBrand trong chính file này (export ở
// trên chỉ tái xuất cho bên ngoài, KHÔNG đưa tên vào scope nội bộ).
import 'app_theme.dart';

class LiquidGlassColors {
  // Bảng màu High-End Deep Contrast mới
  // Màu nền tối đa hóa độ sâu, không dùng xám nhạt nữa, dùng Slate (Slate 50) kết hợp với màu nền tĩnh Deep Ocean cho Dark Mode nếu cần
  //
  // BUGFIX UI/UX (design-system consistency): trước đây file này hardcode
  // #298FFF cho mọi role accent, LỆCH với AppTheme.kBrand = #69B1FF (Sky Blue
  // chuẩn theo skill thiết kế). Hai nguồn màu khác nhau khiến cùng một nút
  // "primary" hiển thị 2 sắc xanh khác nhau tuỳ màn hình. Nay mọi accent đều
  // TRỎ VỀ AppTheme.kBrand — một nguồn chân lý duy nhất, không còn phân kỳ.
  static const List<Color> tenantBg = [Color(0xFFF8FAFC), Color(0xFFF1F5F9)];
  static const Color tenantAccent = AppTheme.kBrand; // Sky Blue (single source)

  static const List<Color> staffBg = [Color(0xFFF8FAFC), Color(0xFFF1F5F9)];
  static const Color staffAccent = AppTheme.kBrand; // Sky Blue (single source)

  static const List<Color> ownerBg = [Color(0xFFF8FAFC), Color(0xFFF1F5F9)];
  static const Color ownerAccent = AppTheme.kBrand; // Sky Blue (single source)

  static const List<Color> adminBg = [Color(0xFFF8FAFC), Color(0xFFF1F5F9)];
  static const Color adminAccent = AppTheme.kBrand; // Sky Blue (single source)

  // Kính & Thẻ (Cards) chuẩn Apple
  static const Color glassWhite = Color(0xB3FFFFFF); // 70% White
  static const Color glassBorder = Color(0x33FFFFFF); // 20% White cho viền mờ

  static const Color gold = Color(0xFFF59E0B);
}
