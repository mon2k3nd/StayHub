import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../network/api_client.dart';

/// Wishlist Service - Server-backed với local fallback cho guest.
/// - Người dùng đã đăng nhập → mọi thao tác gọi API server.
/// - Khách vãng lai → lưu local SharedPreferences.
/// - Khi login, gọi [syncLocalToServer] để đẩy dữ liệu local lên server.
class WishlistService {
  static const _kLocalKey = 'wishlist_rooms_local';

  // ─── Server-backed (logged-in user) ────────────────────────────────────────

  /// Lấy danh sách wishlist từ server, chia thành available/rented.
  /// Trả về { 'available': [...], 'rented': [...], 'totalSaved': int }
  static Future<Map<String, dynamic>> loadFromServer(
    String userId,
    ApiClient client,
  ) async {
    try {
      final res = await client.get('/v1/wishlist/$userId');
      // BUGFIX (data): tránh `as Map` ném TypeError khi `data` không phải Map.
      final data = res['data'] is Map
          ? Map<String, dynamic>.from(res['data'] as Map)
          : <String, dynamic>{};
      return {
        // BUGFIX (data): lọc an toàn — tránh `e as Map` ném TypeError khi
        // phần tử không phải Map.
        'available':
            (data['available'] is List
                    ? (data['available'] as List).whereType<Map>()
                    : const <Map>[])
                .map((e) => Map<String, dynamic>.from(e))
                .toList(),
        'upcoming':
            (data['upcoming'] is List
                    ? (data['upcoming'] as List).whereType<Map>()
                    : const <Map>[])
                .map((e) => Map<String, dynamic>.from(e))
                .toList(),
        'rented':
            (data['rented'] is List
                    ? (data['rented'] as List).whereType<Map>()
                    : const <Map>[])
                .map((e) => Map<String, dynamic>.from(e))
                .toList(),
        'totalSaved': data['totalSaved'] ?? 0,
      };
    } catch (e) {
      debugPrint('[WishlistService] loadFromServer error: $e');
      return {'available': [], 'upcoming': [], 'rented': [], 'totalSaved': 0};
    }
  }

  /// Toggle phòng (thêm/xóa). Trả về true nếu đã THÊM, false nếu ĐÃ XÓA.
  /// Throw exception nếu lỗi mạng/server - caller nên revert optimistic UI.
  static Future<bool> toggleOnServer(
    String userId,
    dynamic roomId,
    ApiClient client,
  ) async {
    final res = await client.post('/v1/wishlist/$userId/toggle/$roomId');
    // BUGFIX (data): tránh `as Map` ném TypeError khi `data` không phải Map.
    final data = res['data'] is Map
        ? Map<String, dynamic>.from(res['data'] as Map)
        : <String, dynamic>{};
    return data['added'] == true;
  }

  /// Cập nhật ghi chú riêng tư hoặc trạng thái đã đi xem thực tế
  static Future<bool> updateNoteAndVisited(
    String userId,
    dynamic roomId, {
    String? privateNote,
    bool? isVisited,
    required ApiClient client,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (privateNote != null) body['privateNote'] = privateNote;
      if (isVisited != null) body['isVisited'] = isVisited;

      final res = await client.patch(
        '/v1/wishlist/$userId/note/$roomId',
        data: body,
      );
      final data = res['data'] is Map ? res['data'] as Map : {};
      return data.isNotEmpty;
    } catch (e) {
      debugPrint('[WishlistService] updateNoteAndVisited error: $e');
      return false;
    }
  }

  /// Kiểm tra phòng có trong wishlist của user không.
  static Future<bool> checkOnServer(
    String userId,
    dynamic roomId,
    ApiClient client,
  ) async {
    try {
      final res = await client.get('/v1/wishlist/$userId/check/$roomId');
      return res['data'] == true;
    } catch (e) {
      debugPrint('[WishlistService] checkOnServer error: $e');
      return false;
    }
  }

  /// Sync dữ liệu local lên server sau khi login.
  static Future<void> syncLocalToServer(String userId, ApiClient client) async {
    try {
      final localRooms = await _loadLocal();
      if (localRooms.isEmpty) return;

      final roomIds = localRooms
          .map((r) => r['id'] ?? r['roomId'])
          .where((id) => id != null)
          .map((id) => int.tryParse(id.toString()))
          .where((id) => id != null)
          .toList();

      if (roomIds.isEmpty) return;

      await client.post(
        '/v1/wishlist/$userId/sync',
        data: {'roomIds': roomIds},
      );
      await _clearLocal(); // Xóa local sau khi sync thành công
      debugPrint('[WishlistService] Synced ${roomIds.length} rooms to server.');
    } catch (e) {
      debugPrint('[WishlistService] syncLocalToServer error: $e');
    }
  }

  // ─── Local fallback (guest user) ───────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> loadLocal() => _loadLocal();

  static Future<List<Map<String, dynamic>>> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kLocalKey) ?? [];
    // BUGFIX (data): tránh `as Map` ném TypeError khi dữ liệu local hỏng
    // (không phải JSON object) — bỏ qua phần tử lỗi thay vì crash.
    final out = <Map<String, dynamic>>[];
    for (final e in raw) {
      try {
        final decoded = json.decode(e);
        if (decoded is Map) out.add(Map<String, dynamic>.from(decoded));
      } catch (_) {
        // bỏ qua phần tử hỏng
      }
    }
    return out;
  }

  static Future<bool> toggleLocal(Map<String, dynamic> room) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kLocalKey) ?? [];
    final roomId = _extractId(room);

    // BUGFIX (data): tránh `as Map` ném TypeError khi dữ liệu local hỏng.
    bool matches(String e) {
      try {
        final decoded = json.decode(e);
        if (decoded is! Map) return false;
        return _extractId(Map<String, dynamic>.from(decoded)) == roomId;
      } catch (_) {
        return false;
      }
    }

    final isIn = raw.any(matches);

    if (isIn) {
      raw.removeWhere(matches);
      await prefs.setStringList(_kLocalKey, raw);
      return false;
    } else {
      raw.add(json.encode(room));
      await prefs.setStringList(_kLocalKey, raw);
      return true;
    }
  }

  static Future<bool> isInLocal(dynamic room) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kLocalKey) ?? [];
    final roomId = room is Map
        ? _extractId(Map<String, dynamic>.from(room))
        : room.toString();
    if (roomId.isEmpty) return false;
    // BUGFIX (data): tránh `as Map` ném TypeError khi dữ liệu local hỏng.
    return raw.any((e) {
      try {
        final decoded = json.decode(e);
        if (decoded is! Map) return false;
        return _extractId(Map<String, dynamic>.from(decoded)) == roomId;
      } catch (_) {
        return false;
      }
    });
  }

  static Future<void> _clearLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLocalKey);
  }

  // ─── Legacy compat (giữ nguyên signature cũ để không phải sửa nhiều nơi) ─

  /// [DEPRECATED] Dùng toggleOnServer hoặc toggleLocal tuỳ trường hợp.
  /// Throw exception nếu server toggle thất bại (caller revert optimistic UI).
  static Future<bool> toggleWishlist(
    Map<String, dynamic> room,
    String? userId, {
    ApiClient? client,
  }) async {
    if (userId != null && client != null) {
      // Throw lỗi lên caller để có thể revert optimistic UI
      return toggleOnServer(userId, _extractId(room), client);
    }
    return toggleLocal(room);
  }

  /// [DEPRECATED] Dùng loadFromServer hoặc loadLocal.
  static Future<List<Map<String, dynamic>>> loadWishlist(
    String? userId, {
    ApiClient? client,
  }) async {
    if (userId != null && client != null) {
      final res = await loadFromServer(userId, client);
      final available = res['available'] as List<Map<String, dynamic>>;
      final rented = res['rented'] as List<Map<String, dynamic>>;
      return [...available, ...rented];
    }
    return _loadLocal();
  }

  static Future<bool> isInWishlist(
    dynamic room,
    String? userId, {
    ApiClient? client,
  }) async {
    if (userId != null && client != null) {
      return checkOnServer(
        userId,
        _extractId(
          room is Map ? Map<String, dynamic>.from(room) : {'id': room},
        ),
        client,
      );
    }
    return isInLocal(room);
  }

  static Future<void> clearWishlist(String? userId, {ApiClient? client}) async {
    if (userId != null && client != null) {
      try {
        await client.delete('/v1/wishlist/$userId');
      } catch (e) {
        debugPrint('[WishlistService] clearWishlist server error: $e');
      }
    }
    await _clearLocal();
  }

  static Future<int> count(String? userId, {ApiClient? client}) async {
    if (userId != null && client != null) {
      try {
        final res = await loadFromServer(userId, client);
        // BUGFIX (data): tránh `as int?` ném TypeError khi totalSaved là
        // String/double — coerce an toàn.
        final rawTotal = res['totalSaved'];
        if (rawTotal is num) return rawTotal.toInt();
        return int.tryParse(rawTotal?.toString() ?? '') ?? 0;
      } catch (_) {}
    }
    return (await _loadLocal()).length;
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  static String _extractId(Map<String, dynamic> room) {
    return room['id']?.toString() ?? room['roomId']?.toString() ?? '';
  }
}
