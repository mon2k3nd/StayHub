import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ViewedHistoryService {
  static const String _key = 'viewed_history_json';
  static const int _maxItems = 20;

  static Future<List<dynamic>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final strList = prefs.getStringList(_key) ?? [];
    // BUGFIX (data): tránh FormatException khi 1 phần tử JSON hỏng — bỏ qua.
    final out = <dynamic>[];
    for (final s in strList) {
      try {
        out.add(jsonDecode(s));
      } catch (_) {
        // bỏ qua phần tử hỏng
      }
    }
    return out;
  }

  static Future<void> addRoom(Map<String, dynamic> room) async {
    final prefs = await SharedPreferences.getInstance();

    // Keep only essential fields to save space
    final essential = {
      'id': room['id'],
      'name': room['postTitle'] ?? room['roomName'] ?? room['name'],
      'price': room['price'],
      'address': room['address'],
      'firstImage':
          room['coverImageUrl'] ??
          room['firstImage'] ??
          (room['postImages'] != null && (room['postImages'] as List).isNotEmpty
              ? room['postImages'][0]
              : null) ??
          (room['roomImages'] != null && (room['roomImages'] as List).isNotEmpty
              ? room['roomImages'][0]
              : null) ??
          (room['images'] != null && (room['images'] as List).isNotEmpty
              ? room['images'][0]
              : null),
      'roomType': room['roomType'],
      'area': room['area'] ?? room['floorArea'],
      'bathrooms': room['bathrooms'],
      'bedrooms': room['bedrooms'],
      'isFavorite': room['isFavorite'],
      'ownerAvatar': room['ownerAvatar'],
    };

    final currentHistory = await getHistory();

    // Remove if already exists to push it to the top
    // BUGFIX (data): guard phần tử là Map trước khi truy cập `item['id']` —
    // tránh NoSuchMethodError khi dữ liệu local hỏng.
    currentHistory.removeWhere(
      (item) => item is Map && item['id'] == essential['id'],
    );

    // Add to the front
    currentHistory.insert(0, essential);

    // Truncate
    if (currentHistory.length > _maxItems) {
      currentHistory.removeRange(_maxItems, currentHistory.length);
    }

    final strList = currentHistory.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList(_key, strList);
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
