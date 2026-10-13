import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Dịch vụ so sánh phòng (Guest Mode - lưu local).
///
/// Cho phép khách chọn tối đa [maxItems] phòng để so sánh song song
/// các tiêu chí: giá, diện tích, số phòng ngủ, số WC, tiện ích...
class CompareService {
  static const String _key = 'compare_rooms_local';
  static const int maxItems = 3;

  /// Lấy danh sách phòng đang được chọn so sánh.
  static Future<List<Map<String, dynamic>>> getRooms() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    // BUGFIX (data): tránh `as Map` ném TypeError khi dữ liệu local hỏng.
    final out = <Map<String, dynamic>>[];
    for (final e in raw) {
      final m = _decodeMap(e);
      if (m != null) out.add(m);
    }
    return out;
  }

  /// BUGFIX (data): giải mã an toàn 1 phần tử JSON local — trả null nếu hỏng.
  static Map<String, dynamic>? _decodeMap(String e) {
    try {
      final decoded = json.decode(e);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  /// Thêm/xoá phòng khỏi danh sách so sánh.
  /// Trả về `true` nếu đã THÊM, `false` nếu đã XOÁ.
  /// Ném [CompareLimitException] nếu đã đủ [maxItems] phòng.
  static Future<bool> toggle(Map<String, dynamic> room) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final roomId = _extractId(room);

    // BUGFIX (data): tránh `as Map` ném TypeError khi dữ liệu local hỏng.
    final index = raw.indexWhere((e) {
      final m = _decodeMap(e);
      return m != null && _extractId(m) == roomId;
    });

    if (index >= 0) {
      raw.removeAt(index);
      await prefs.setStringList(_key, raw);
      return false;
    }

    if (raw.length >= maxItems) {
      throw const CompareLimitException(maxItems);
    }

    raw.add(json.encode(_sanitize(room)));
    await prefs.setStringList(_key, raw);
    return true;
  }

  /// Kiểm tra phòng đã có trong danh sách so sánh chưa.
  static Future<bool> contains(dynamic room) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final roomId = room is Map
        ? _extractId(Map<String, dynamic>.from(room))
        : room.toString();
    if (roomId.isEmpty) return false;
    // BUGFIX (data): tránh `as Map` ném TypeError khi dữ liệu local hỏng.
    return raw.any((e) {
      final m = _decodeMap(e);
      return m != null && _extractId(m) == roomId;
    });
  }

  /// Số phòng đang chọn so sánh.
  static Future<int> count() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? []).length;
  }

  /// Xoá toàn bộ danh sách so sánh.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  /// Xoá 1 phòng khỏi danh sách so sánh.
  static Future<void> remove(dynamic roomId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    final id = roomId.toString();
    // BUGFIX (data): tránh `as Map` ném TypeError khi dữ liệu local hỏng.
    raw.removeWhere((e) {
      final m = _decodeMap(e);
      return m != null && _extractId(m) == id;
    });
    await prefs.setStringList(_key, raw);
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  /// Chỉ giữ các trường cần thiết để tiết kiệm bộ nhớ.
  static Map<String, dynamic> _sanitize(Map<String, dynamic> room) {
    String firstImage = '';
    if (room['coverImageUrl'] != null &&
        room['coverImageUrl'].toString().isNotEmpty) {
      firstImage = room['coverImageUrl'].toString();
    } else if (room['firstImage'] != null) {
      firstImage = room['firstImage'].toString();
    } else if (room['roomImages'] != null) {
      final imgStr = room['roomImages'].toString();
      try {
        if (imgStr.startsWith('[')) {
          final list = jsonDecode(imgStr) as List;
          if (list.isNotEmpty) firstImage = list.first.toString();
        } else if (imgStr.isNotEmpty) {
          firstImage = imgStr.split(',').first.trim();
        }
      } catch (_) {}
    }

    return {
      'id': room['id'] ?? room['roomId'],
      'title':
          room['title'] ??
          room['postTitle'] ??
          room['name'] ??
          room['roomName'] ??
          'Phòng',
      'price': room['price'] ?? room['rentingPrice'],
      'floorArea': room['floorArea'] ?? room['area'],
      'bedrooms': room['bedrooms'],
      'bathrooms': room['bathrooms'],
      'floor': room['floor'],
      'address': room['addressOld'] ?? room['address'],
      'firstImage': firstImage,
      'roomType': room['roomType'] ?? room['roomTypeName'],
      'branchName': room['branchName'],
      'roomName': room['roomName'],
    };
  }

  static String _extractId(Map<String, dynamic> room) {
    return room['id']?.toString() ?? room['roomId']?.toString() ?? '';
  }
}

/// Ném khi danh sách so sánh đã đạt giới hạn tối đa.
class CompareLimitException implements Exception {
  final int limit;
  const CompareLimitException(this.limit);

  @override
  String toString() => 'Chỉ có thể so sánh tối đa $limit phòng.';
}
