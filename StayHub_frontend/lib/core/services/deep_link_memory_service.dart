import 'package:shared_preferences/shared_preferences.dart';

/// Service to remember where the guest was browsing before login,
/// so after login we can redirect them back seamlessly (Lazy Login).
class DeepLinkMemoryService {
  static const _kPendingRoute = 'pending_route';
  static const _kPendingRoomId = 'pending_room_id';
  static const _kPendingRoomName = 'pending_room_name';

  /// Save the route the guest was on before being prompted to log in
  static Future<void> savePendingRoute(
    String route, {
    int? roomId,
    String? roomName,
    double? price,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPendingRoute, route);
    if (roomId != null) await prefs.setInt(_kPendingRoomId, roomId);
    if (roomName != null) await prefs.setString(_kPendingRoomName, roomName);
    if (price != null) await prefs.setDouble('pending_price', price);
  }

  /// Retrieve and clear the pending route after login
  static Future<Map<String, dynamic>?> consumePendingRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final route = prefs.getString(_kPendingRoute);
    if (route == null) return null;

    final roomId = prefs.getInt(_kPendingRoomId);
    final roomName = prefs.getString(_kPendingRoomName);
    final price = prefs.getDouble('pending_price');

    // Clear all
    await prefs.remove(_kPendingRoute);
    await prefs.remove(_kPendingRoomId);
    await prefs.remove(_kPendingRoomName);
    await prefs.remove('pending_price');

    return {
      'route': route,
      if (roomId != null) 'roomId': roomId,
      if (roomName != null) 'roomName': roomName,
      if (price != null) 'price': price,
    };
  }

  /// Check if there's a pending route saved
  static Future<bool> hasPendingRoute() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_kPendingRoute);
  }
}
