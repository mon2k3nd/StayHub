import 'package:flutter/foundation.dart';

/// Một trang kết quả tìm phòng trả về từ `GET /v1/rooms/public/search`.
///
/// Backend trả về `Page<MarketplacePostDTO>` (Spring Data). Lớp này giữ nguyên
/// `Map` thô của từng bài đăng (để tái sử dụng đúng các builder/card hiện có)
/// kèm metadata phân trang cần cho infinite scroll.
@immutable
class RoomSearchPage {
  /// Danh sách bài đăng thô (mỗi phần tử là 1 `MarketplacePostDTO` dạng Map).
  final List<Map<String, dynamic>> items;

  /// Tổng số bài đăng khớp bộ lọc (trên toàn bộ DB, không chỉ trang này).
  final int totalElements;

  /// Tổng số trang.
  final int totalPages;

  /// Chỉ số trang hiện tại (0-based).
  final int page;

  /// Kích thước trang.
  final int size;

  /// Trang này có phải trang cuối không.
  final bool isLast;

  const RoomSearchPage({
    required this.items,
    required this.totalElements,
    required this.totalPages,
    required this.page,
    required this.size,
    required this.isLast,
  });

  static const empty = RoomSearchPage(
    items: [],
    totalElements: 0,
    totalPages: 0,
    page: 0,
    size: 20,
    isLast: true,
  );

  bool get isEmpty => items.isEmpty;

  /// Parse payload `data` của ApiResponse (chính là object `Page` của Spring).
  factory RoomSearchPage.fromJson(
    Map<String, dynamic> json, {
    int fallbackSize = 20,
  }) {
    final rawContent = json['content'];
    final items = <Map<String, dynamic>>[];
    if (rawContent is List) {
      for (final e in rawContent) {
        if (e is Map) items.add(Map<String, dynamic>.from(e));
      }
    }
    final pageNumber = _asInt(json['number']) ?? 0;
    final size = _asInt(json['size']) ?? fallbackSize;
    final totalPages = _asInt(json['totalPages']) ?? 0;
    final totalElements = _asInt(json['totalElements']) ?? items.length;
    final isLast = json['last'] is bool
        ? json['last'] as bool
        : (totalPages == 0 || pageNumber >= totalPages - 1);
    return RoomSearchPage(
      items: items,
      totalElements: totalElements,
      totalPages: totalPages,
      page: pageNumber,
      size: size,
      isLast: isLast,
    );
  }

  static int? _asInt(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}
