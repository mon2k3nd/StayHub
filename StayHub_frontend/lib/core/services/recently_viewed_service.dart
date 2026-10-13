import 'package:shared_preferences/shared_preferences.dart';

class RecentlyViewedService {
  static const String _key = 'recently_viewed_rooms';
  static const int _maxItems = 15;

  /// Adds a room ID to the recently viewed list.
  /// If it already exists, moves it to the front.
  static Future<void> addRoom(String roomId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> viewedRooms = prefs.getStringList(_key) ?? [];

    // Remove if already exists so we can move it to the front
    viewedRooms.remove(roomId);

    // Add to the front
    viewedRooms.insert(0, roomId);

    // Keep only the max limit
    if (viewedRooms.length > _maxItems) {
      viewedRooms = viewedRooms.sublist(0, _maxItems);
    }

    await prefs.setStringList(_key, viewedRooms);
  }

  /// Retrieves the list of recently viewed room IDs.
  static Future<List<String>> getRooms() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  /// Clears the recently viewed history.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
