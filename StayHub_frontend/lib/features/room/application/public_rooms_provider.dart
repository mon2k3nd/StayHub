import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/image_url_helper.dart';
import 'public_rooms_filter_provider.dart';

// -- Pagination State ---------------------------------------------------------
class PublicRoomsState {
  final List<dynamic> rooms;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;

  const PublicRoomsState({
    this.rooms = const [],
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 0,
  });

  PublicRoomsState copyWith({
    List<dynamic>? rooms,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
  }) {
    return PublicRoomsState(
      rooms: rooms ?? this.rooms,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

// -- Notifier -----------------------------------------------------------------
/// Chẩn đoán runtime cho guest feed — hiển thị TRỰC TIẾP trên màn hình để
/// không cần adb logcat. Ghi lại URL thực tế, HTTP status và số phòng parse
/// được của lần fetch gần nhất.
class GuestFeedDiagnostics {
  static String? lastUrl;
  static int? lastStatus;
  static int? lastRoomCount;
  static String? lastError;
  static String? lastBodyPreview;
}

class PublicRoomsNotifier extends AsyncNotifier<PublicRoomsState> {
  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSub;
  static const int _pageSize = 20;

  @override
  FutureOr<PublicRoomsState> build() async {
    ref.watch(publicRoomsFilterProvider); // Trigger reload on filter change
    ref.onDispose(() {
      unawaited(_wsSub?.cancel());
      unawaited(_wsChannel?.sink.close());
    });

    final initialState = await _fetchPage(0);

    // PERF4: KHÔNG await WebSocket trong build(). Trên thiết bị thật, handshake
    // WS tới tunnel có thể treo rất lâu (tunnel không proxy WS ổn định) → build()
    // không bao giờ trả về → provider kẹt ở AsyncLoading mãi mãi → UI hiển thị
    // shimmer/trắng vô hạn. Chạy nền để dữ liệu phòng hiển thị ngay lập tức.
    unawaited(_connectWishlistWs());

    return initialState;
  }

  // -- WebSocket realtime wishlist count --------------------------------------
  Future<void> _connectWishlistWs() async {
    // BUGFIX (rò rỉ kết nối): `build()` chạy lại MỖI KHI bộ lọc đổi (do
    // `ref.watch(publicRoomsFilterProvider)`), và mỗi lần lại gọi
    // `_connectWishlistWs()`. Trước đây hàm này ghi đè `_wsChannel`/`_wsSub`
    // mà KHÔNG đóng kết nối cũ → mỗi thay đổi bộ lọc để lại một WebSocket
    // "zombie" còn mở (rò rỉ socket + subscription). `ref.onDispose` chỉ chạy
    // khi provider bị huỷ hoàn toàn, không chạy khi rebuild. Nay đóng dứt điểm
    // kết nối cũ trước khi mở kết nối mới.
    await _wsSub?.cancel();
    _wsSub = null;
    await _wsChannel?.sink.close();
    _wsChannel = null;

    try {
      final secureStorage = ref.read(secureStorageServiceProvider);
      final token = await secureStorage.getAccessToken();
      if (token == null) return;

      final apiClient = ref.read(apiClientProvider);
      final baseUrl = apiClient.dio.options.baseUrl;
      final wsBase = baseUrl.replaceFirst(RegExp(r'^http'), 'ws');
      final cleanBase = wsBase.replaceAll(RegExp(r'/api/?$|/v1/?$'), '');
      final wsUrl =
          '${cleanBase.endsWith('/') ? cleanBase.substring(0, cleanBase.length - 1) : cleanBase}/ws?token=$token';

      _wsChannel = WebSocketChannel.connect(Uri.parse(wsUrl));

      try {
        await _wsChannel!.ready;
      } catch (e) {
        debugPrint('[WishlistWS] connect failed (handshake): $e');
        return;
      }

      _wsSub = _wsChannel!.stream.listen(
        (raw) {
          try {
            final data = jsonDecode(raw as String);
            if (data is Map && data['type'] == 'WISHLIST_COUNT_UPDATE') {
              final roomId = data['roomId'];
              // BUGFIX (data): `count` có thể là String/null → tránh TypeError.
              final rawCount = data['count'];
              final newCount = rawCount is num
                  ? rawCount.toInt()
                  : int.tryParse(rawCount?.toString() ?? '') ?? 0;
              _updateRoomWishlistCount(roomId, newCount);
            }
          } catch (e) {
            debugPrint('[WishlistWS] parse error: $e');
          }
        },
        onError: (e) {
          debugPrint('[WishlistWS] error: $e');
        },
        onDone: () {
          debugPrint('[WishlistWS] closed');
        },
      );

      debugPrint('[WishlistWS] connected: $wsUrl');
    } catch (e) {
      debugPrint('[WishlistWS] connect failed: $e');
    }
  }

  void _updateRoomWishlistCount(dynamic roomId, int newCount) {
    final current = state.asData?.value;
    if (current == null) return;
    final updated = current.rooms.map((r) {
      final room = Map<String, dynamic>.from(r as Map);
      final id = room['id']?.toString() ?? room['roomId']?.toString();
      if (id == roomId.toString()) {
        room['wishlistCount'] = newCount;
      }
      return room;
    }).toList();
    state = AsyncData(current.copyWith(rooms: updated));
  }

  // -- Fetch a single page ----------------------------------------------------
  Future<PublicRoomsState> _fetchPage(int page) async {
    try {
      final filterState = ref.read(publicRoomsFilterProvider);
      final queryParams = filterState.toQueryParams();
      queryParams['page'] = page;
      queryParams['size'] = _pageSize;

      final dio = ref.read(dioProvider);
      // Dùng endpoint /search để TOÀN BỘ bộ lọc (giá, diện tích, loại phòng,
      // tiện ích, hướng, tỉnh/thành, vị trí, sắp xếp...) chạy ở tầng DB.
      // Endpoint cũ `/v1/rooms/public` chỉ nhận page/size nên mọi bộ lọc bị bỏ qua.
      //
      // PERF3: Dùng Options fail-fast (không retry) để khi backend không tới
      // được, UI hiển thị lỗi/empty ngay thay vì treo shimmer 60s+.
      final fullUrl = '${dio.options.baseUrl}/v1/rooms/public/search';
      GuestFeedDiagnostics.lastUrl = fullUrl;
      GuestFeedDiagnostics.lastError = null;

      final res = await dio.get(
        '/v1/rooms/public/search',
        queryParameters: queryParams,
        options: Options(extra: {'_failFast': true}),
      );

      GuestFeedDiagnostics.lastStatus = res.statusCode;

      // PERF5: DioCacheInterceptor (v3.x) có thể trả về body dưới dạng String
      // (JSON thô) khi phục vụ từ cache thay vì Map đã decode. Truy cập
      // `res.data['data']` trên một String sẽ ném NoSuchMethodError → rơi vào
      // catch → UI hiển thị "không có phòng nào". Decode phòng thủ ở đây.
      dynamic body = res.data;
      if (body is String) {
        try {
          body = jsonDecode(body);
        } catch (_) {
          body = null;
        }
      }
      final data = (body is Map ? body['data'] : null) ?? body;
      GuestFeedDiagnostics.lastBodyPreview = data == null
          ? 'null'
          : (data is Map
                ? 'Map keys=${data.keys.take(6).join(",")}'
                : data.runtimeType.toString());

      List<dynamic> newRooms = [];
      bool hasMore = false;

      if (data is Map && data.containsKey('content')) {
        // BUGFIX (data): `content` có thể null/không phải List → tránh TypeError.
        final rawContent = data['content'];
        newRooms = rawContent is List ? rawContent : const [];
        final rawTotalPages = data['totalPages'];
        final totalPages = rawTotalPages is num
            ? rawTotalPages.toInt()
            : int.tryParse(rawTotalPages?.toString() ?? '') ?? 1;
        hasMore = page < totalPages - 1;
      } else if (data is List) {
        newRooms = data;
        hasMore =
            newRooms.length >=
            _pageSize; // If we got a full page, there might be more
      }

      // Normalize image URLs
      newRooms = newRooms.map((room) {
        if (room is Map<String, dynamic>) {
          final r = Map<String, dynamic>.from(room);
          if (r['ownerAvatar'] != null) {
            r['ownerAvatar'] = ImageUrlHelper.buildUrl(
              r['ownerAvatar'].toString(),
            );
          }
          return r;
        }
        return room;
      }).toList();

      GuestFeedDiagnostics.lastRoomCount = newRooms.length;

      // Cache first page for offline use
      if (page == 0 && newRooms.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('cached_public_rooms', jsonEncode(newRooms));
      }

      return PublicRoomsState(
        rooms: newRooms,
        isLoadingMore: false,
        hasMore: hasMore,
        currentPage: page,
      );
    } catch (e) {
      GuestFeedDiagnostics.lastError = e.toString();
      GuestFeedDiagnostics.lastRoomCount = 0;
      if (page == 0) {
        // On first load failure, try cache
        try {
          final prefs = await SharedPreferences.getInstance();
          final cached = prefs.getString('cached_public_rooms');
          if (cached != null) {
            final decoded = jsonDecode(cached) as List<dynamic>;
            if (decoded.isNotEmpty) {
              return PublicRoomsState(
                rooms: decoded,
                isLoadingMore: false,
                hasMore: false,
                currentPage: 0,
              );
            }
          }
        } catch (_) {}
      }
      // BUGFIX: KHÔNG gán `state = AsyncError(...)` ở đây. `_fetchPage` được gọi
      // từ `build()` (nơi gán state là bất hợp lệ và bị bỏ qua) LẪN từ
      // `loadMore()` (nơi caller tự xử lý lỗi). Việc gán state tại đây gây
      // trạng thái không nhất quán: `loadMore` set AsyncError rồi ngay sau đó
      // ghi đè bằng AsyncData → lỗi bị nuốt. Chỉ `rethrow` để caller quyết định.
      rethrow;
    }
  }

  // -- Load next page (infinite scroll) -------------------------------------
  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    // Mark as loading more
    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final nextPage = current.currentPage + 1;
      final nextState = await _fetchPage(nextPage);

      // Append new rooms to existing list
      state = AsyncData(
        current.copyWith(
          rooms: [...current.rooms, ...nextState.rooms],
          isLoadingMore: false,
          hasMore: nextState.hasMore,
          currentPage: nextPage,
        ),
      );
    } catch (e) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
      debugPrint('[PublicRooms] loadMore error: $e');
    }
  }

  // -- Full refresh ----------------------------------------------------------
  /// BUGFIX: bọc trong try/catch. Trước đây nếu `_fetchPage(0)` ném lỗi thì
  /// `refresh()` ném lỗi không bắt và provider KẸT ở `AsyncLoading` mãi mãi →
  /// UI hiển thị shimmer vô hạn (không bao giờ thoát). Nay đặt `AsyncError`
  /// để UI hiển thị trạng thái lỗi/empty đúng cách.
  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      state = AsyncData(await _fetchPage(0));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final publicRoomsProvider =
    AsyncNotifierProvider<PublicRoomsNotifier, PublicRoomsState>(() {
      return PublicRoomsNotifier();
    });

// -- Convenience provider: flat list of rooms (with distance sorting) ---------
final sortedPublicRoomsProvider = Provider<AsyncValue<List<dynamic>>>((ref) {
  final stateAsync = ref.watch(publicRoomsProvider);
  final locationAsync = ref.watch(realtimeLocationProvider);

  return stateAsync.whenData((publicRoomsState) {
    final rooms = publicRoomsState.rooms;

    if (!locationAsync.hasValue || locationAsync.value == null) return rooms;

    final userPos = locationAsync.value!;

    final sortedRooms = List<dynamic>.from(rooms).map((r) {
      final roomData = Map<String, dynamic>.from(r as Map);

      final latRaw = roomData['latitude'] ?? roomData['lat'];
      final lngRaw = roomData['longitude'] ?? roomData['lng'];

      if (latRaw != null && lngRaw != null) {
        final lat = (latRaw is num)
            ? latRaw.toDouble()
            : double.tryParse(latRaw.toString());
        final lng = (lngRaw is num)
            ? lngRaw.toDouble()
            : double.tryParse(lngRaw.toString());
        if (lat != null && lng != null) {
          final distanceInMeters = Geolocator.distanceBetween(
            userPos.latitude,
            userPos.longitude,
            lat,
            lng,
          );
          roomData['distanceKm'] = distanceInMeters / 1000.0;
        }
      }
      return roomData;
    }).toList();

    sortedRooms.sort((a, b) {
      // BUGFIX (data): coerce an toàn — tránh `as double?` ném TypeError khi
      // distanceKm là int/String.
      final rawDa = a['distanceKm'];
      final rawDb = b['distanceKm'];
      final da = rawDa is num ? rawDa.toDouble() : null;
      final db = rawDb is num ? rawDb.toDouble() : null;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });

    return sortedRooms;
  });
});
