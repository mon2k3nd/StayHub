import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Lưu & đọc lịch sử tìm kiếm gần đây của khách (local, không cần đăng nhập).
///
/// Mỗi mục là một chuỗi từ khoá người dùng đã tìm. Giữ tối đa [maxItems]
/// mục, mới nhất ở đầu. Đồng bộ với trải nghiệm "Tìm kiếm gần đây" trong
/// sheet tìm kiếm của Guest Marketplace.
class RecentSearchService {
  RecentSearchService._();

  static const String _key = 'recent_searches_local';
  static const int maxItems = 8;

  /// Trả về danh sách từ khoá gần đây (mới nhất trước).
  static Future<List<String>> getSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<String>()
          .where((e) => e.trim().isNotEmpty)
          .take(maxItems)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Thêm một từ khoá vào đầu danh sách (loại bỏ trùng lặp, giữ tối đa
  /// [maxItems] mục). Bỏ qua từ khoá rỗng.
  static Future<void> add(String keyword) async {
    final value = keyword.trim();
    if (value.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await getSearches();
      final next = <String>[
        value,
        ...current.where((e) => e.toLowerCase() != value.toLowerCase()),
      ].take(maxItems).toList();
      await prefs.setString(_key, jsonEncode(next));
    } catch (_) {
      // Bỏ qua lỗi lưu trữ — không chặn luồng tìm kiếm.
    }
  }

  /// Xoá toàn bộ lịch sử tìm kiếm.
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {
      // Bỏ qua.
    }
  }
}
