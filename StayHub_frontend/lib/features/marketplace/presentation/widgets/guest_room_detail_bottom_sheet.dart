import 'dart:convert';
import 'dart:async' show unawaited;

import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/room_type_codes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/osm_map_service.dart';
import '../../../../core/services/recently_viewed_service.dart';
import '../../application/wishlist_provider.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/liquid_glass_colors.dart';
import '../../../../core/utils/image_url_helper.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../../auth/presentation/widgets/guest_auth_bottom_sheet.dart';
import '../../../auth/presentation/widgets/ekyc_verification_dialog.dart';
import '../../../room/application/public_rooms_provider.dart';
import '../../../shared/presentation/widgets/full_screen_media_viewer.dart';
import 'cho_tot_room_detail.dart';
import '../../../chat/application/conversation_provider.dart';
import '../../../chat/presentation/thread_message_screen.dart';

part 'guest_room_detail_bottom_sheet_helpers.dart';

/// Bottom Sheet detail view for a room (used in Reels view).
class GuestRoomDetailBottomSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> room;
  final int? roomId;
  final ScrollController scrollController;
  final bool isPreview;
  final bool isFullScreen;

  const GuestRoomDetailBottomSheet({
    super.key,
    required this.room,
    this.roomId,
    required this.scrollController,
    this.isPreview = false,
    this.isFullScreen = false,
  });

  @override
  ConsumerState<GuestRoomDetailBottomSheet> createState() =>
      _GuestRoomDetailBottomSheetState();
}

class _GuestRoomDetailBottomSheetState
    extends ConsumerState<GuestRoomDetailBottomSheet> {
  Map<String, dynamic>? _resolvedRoom;
  int _currentImageIndex = 0;
  bool _isWishlisted = false;
  final PageController _pageController = PageController();
  List<dynamic> _reviews = [];
  bool _isLoadingReviews = true;
  bool _showBigHeart = false;

  // ── Cached computed data (built once when room data arrives) ──
  List<String>? _cachedImages;

  /// Compute expensive derived values once and cache them.
  void _buildRoomCache(Map<String, dynamic> room) {
    _cachedImages = _extractImages(room);
  }

  @override
  void initState() {
    super.initState();

    final currentId = widget.roomId ?? widget.room['id'];

    // Check if the data is partial (e.g., loaded from local ViewedHistory which only saves 'firstImage' and essential fields)
    final isPartialData =
        widget.room.isNotEmpty &&
        widget.room['images'] == null &&
        widget.room['roomImages'] == null &&
        widget.room['postImages'] == null;

    if ((widget.room.isEmpty || isPartialData) && currentId != null) {
      unawaited(_fetchRoomDetails(currentId));
    } else {
      unawaited(_checkWishlist());
      final roomToUse = _resolvedRoom ?? widget.room;
      if (roomToUse.isNotEmpty && roomToUse['id'] != null) {
        _buildRoomCache(roomToUse);
        unawaited(RecentlyViewedService.addRoom(roomToUse['id'].toString()));
        unawaited(_fetchReviews(roomToUse['id'].toString()));
      }
    }
  }

  Future<void> _fetchRoomDetails(dynamic id) async {
    try {
      final res = await ApiClient().dio.get('/v1/rooms/public/$id');
      if (mounted) {
        setState(() {
          final responseData = res.data;
          if (responseData is Map<String, dynamic> &&
              responseData.containsKey('data')) {
            _resolvedRoom = responseData['data'];
          } else {
            _resolvedRoom = responseData;
          }
          // Build cache immediately so first build uses cached data
          if (_resolvedRoom != null && _resolvedRoom!.isNotEmpty) {
            _buildRoomCache(_resolvedRoom!);
          }
        });
        unawaited(_checkWishlist());
        unawaited(RecentlyViewedService.addRoom(id.toString()));
        unawaited(_fetchReviews(id.toString()));
      }
    } catch (e) {
      debugPrint('Error fetching room detail: $e');
      if (mounted) {
        setState(() {
          _resolvedRoom = {}; // Prevent infinite loading
        });
      }
    }
  }

  Future<void> _fetchReviews(String roomId) async {
    try {
      final res = await ApiClient().dio.get('/api/v1/reviews/room/$roomId');
      if (mounted) {
        setState(() {
          _reviews = res.data ?? [];
          _isLoadingReviews = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingReviews = false);
      }
    }
  }

  Future<void> _checkWishlist() async {
    final roomToUse = _resolvedRoom ?? widget.room;
    final roomId = (roomToUse['id'] ?? roomToUse['roomId'])?.toString() ?? '';
    if (roomId.isNotEmpty) {
      final inList = ref.read(wishlistProvider).ids.contains(roomId);
      if (mounted) setState(() => _isWishlisted = inList);
    }
  }

  Future<void> _handleDoubleTapHeart() async {
    final authUser = ref.read(authProvider).value;
    if (authUser == null) {
      if (!mounted) return;
      GuestAuthBottomSheet.show(context);
      return;
    }

    setState(() => _showBigHeart = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showBigHeart = false);
    });

    final roomToUse = _resolvedRoom ?? widget.room;
    unawaited(HapticFeedback.mediumImpact());
    await ref.read(wishlistProvider.notifier).toggle(roomToUse);
    final roomId = (roomToUse['id'] ?? roomToUse['roomId'])?.toString() ?? '';
    final isLikedNow = ref.read(wishlistProvider).ids.contains(roomId);
    if (mounted) setState(() => _isWishlisted = isLikedNow);
    if (mounted) {
      ToastUtils.show(
        context,
        isLikedNow ? 'Đã lưu phòng vào yêu thích' : 'Đã bỏ lưu phòng',
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> _extractImages(Map<String, dynamic> room) {
    String resolveUrl(dynamic item) {
      String urlStr = '';
      if (item is Map) {
        urlStr = (item['url'] ?? item['imageUrl'] ?? item['path'] ?? '').toString();
      } else {
        urlStr = item.toString();
      }
      return ImageUrlHelper.buildUrl(urlStr) ?? '';
    }

    final videoUrlRaw = room['videoUrl']?.toString() ?? '';
    var videoUrl = videoUrlRaw.isNotEmpty ? resolveUrl(videoUrlRaw) : '';
    if (videoUrl.contains('w3schools.com') || videoUrl.contains('dummy')) {
      videoUrl = ''; // Ignore mock videos from backend
    }

    List<String> urls = [];

    // Try 'images' array first.
    // BUGFIX: `roomImages` là gallery CHÍNH (toàn bộ ảnh phòng, đúng thứ tự chủ
    // trọ sắp). Trước đây ưu tiên `postImages` (chỉ là ảnh phụ của bài đăng) nên
    // gallery bị thiếu ảnh / sai thứ tự so với lúc xem trước.
    final imagesRaw =
        room['images'] ?? room['roomImages'] ?? room['postImages'];
    if (imagesRaw is List && imagesRaw.isNotEmpty) {
      urls = imagesRaw
          .map((e) => resolveUrl(e))
          .where((e) => e.isNotEmpty)
          .toList();
    } else {
      // Try JSON array first (roomImages field)
      final raw =
          room['roomImages'] ??
          room['postImages'] ??
          room['coverImageUrl'] ??
          room['image'] ??
          '';
      final str = raw.toString();
      if (str.isNotEmpty) {
        if (str.trim().startsWith('[')) {
          try {
            final decoded = jsonDecode(str) as List;
            urls = decoded
                .map((e) => resolveUrl(e))
                .where((e) => e.isNotEmpty)
                .toList();
          } catch (_) {
            urls = str
                .replaceAll('[', '')
                .replaceAll(']', '')
                .replaceAll('"', '')
                .replaceAll(r'\', '')
                .split(',')
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .map(resolveUrl)
                .where((e) => e.isNotEmpty)
                .toList();
          }
        } else {
          urls = str
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .map(resolveUrl)
              .where((e) => e.isNotEmpty)
              .toList();
        }
      }
    }

    List<String> allMedia = [];
    if (videoUrl.isNotEmpty) allMedia.add(videoUrl);
    allMedia.addAll(urls);

    // Extract featurePhotos from detailedInfo
    final diRaw = room['detailedInfo'];
    Map<String, dynamic> info = {};
    if (diRaw is Map) {
      info = Map<String, dynamic>.from(diRaw);
    } else if (diRaw is String && diRaw.trim().startsWith('{')) {
      try {
        final decoded = jsonDecode(diRaw);
        if (decoded is Map) info = Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    final featurePhotos = info['featurePhotos'];
    if (featurePhotos is Map) {
      for (final value in featurePhotos.values) {
        if (value is String) {
          final res = resolveUrl(value);
          if (res.isNotEmpty && !allMedia.contains(res)) allMedia.add(res);
        } else if (value is List) {
          for (final item in value) {
            final res = resolveUrl(item);
            if (res.isNotEmpty && !allMedia.contains(res)) allMedia.add(res);
          }
        }
      }
    }

    if (allMedia.isEmpty) {
      allMedia.add(
        'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800&auto=format&fit=crop',
      );
    }

    return allMedia;
  }

  double _extractPrice(dynamic priceRaw) {
    if (priceRaw == null) return 0.0;
    if (priceRaw is num) return priceRaw.toDouble();
    if (priceRaw is String) return double.tryParse(priceRaw) ?? 0.0;
    return 0.0;
  }

  void _showMap(BuildContext context, Map<String, dynamic> room) {
    // -- Coordinate extraction (done before showModal to avoid jank) --
    final latStr =
        room['latitude']?.toString() ??
        room['lat']?.toString() ??
        (room['branch'] is Map
            ? room['branch']['latitude']?.toString()
            : null) ??
        '';
    final lngStr =
        room['longitude']?.toString() ??
        room['lng']?.toString() ??
        (room['branch'] is Map
            ? room['branch']['longitude']?.toString()
            : null) ??
        '';
    final lat = double.tryParse(latStr) ?? 21.028511;
    final lng = double.tryParse(lngStr) ?? 105.804817;
    final center = LatLng(lat, lng);

    // -- Parse POIs (pre-compute before builder) --
    final dynamic poisRaw =
        room['pois'] ??
        (room['branch'] is Map ? room['branch']['pois'] : null) ??
        room['poi'] ??
        room['placesOfInterest'];
    List<String> poisList = [];
    if (poisRaw is List) {
      poisList = poisRaw.map((e) => e.toString()).toList();
    } else if (poisRaw is String) {
      if (poisRaw.trim().startsWith('[')) {
        try {
          final List parsed = jsonDecode(poisRaw);
          poisList = parsed.map((e) => e.toString()).toList();
        } catch (_) {
          poisList = poisRaw
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll('"', '')
              .replaceAll("'", '')
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } else {
        poisList = poisRaw
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    // -- POI color palette --
    const List<Color> poiColors = [
      Color(0xFF3B82F6),
      Color(0xFF10B981),
      Color(0xFFEF4444),
      Color(0xFF8B5CF6),
      Color(0xFFF59E0B),
      Color(0xFFEC4899),
      Color(0xFF14B8A6),
      Color(0xFF6366F1),
    ];
    const List<IconData> poiIcons = [
      CupertinoIcons.book_fill, // schools
      CupertinoIcons.cart_fill, // shops
      CupertinoIcons.heart_fill, // hospital
      CupertinoIcons.bus, // bus
      CupertinoIcons.flame_fill, // food
      CupertinoIcons.star_fill, // misc
      CupertinoIcons.creditcard_fill, // bank
      CupertinoIcons.location_fill, // default
    ];

    // Map POI name keyword -> icon index
    int poiIconIdx(String name) {
      final n = name.toLowerCase();
      if (n.contains('trường') ||
          n.contains('đại học') ||
          n.contains('học viện')) {
        return 0;
      }
      if (n.contains('chợ') ||
          n.contains('siêu thị') ||
          n.contains('circle') ||
          n.contains('mart')) {
        return 1;
      }
      if (n.contains('bệnh viện') ||
          n.contains('phòng khám') ||
          n.contains('y tế') ||
          n.contains('huyết')) {
        return 2;
      }
      if (n.contains('trạm xe') || n.contains('bus') || n.contains('buýt')) {
        return 3;
      }
      if (n.contains('nhà hàng') || n.contains('quán') || n.contains('ăn')) {
        return 4;
      }
      if (n.contains('ngân hàng') || n.contains('atm')) {
        return 6;
      }
      return 7;
    }

    // -- Nearby rooms (pre-compute) --
    final String myId =
        room['id']?.toString() ?? room['roomId']?.toString() ?? '';
    final nearbyRooms =
        ref
            .read(publicRoomsProvider)
            .value
            ?.rooms
            .where((r) {
              // BUGFIX (data): trước đây ép `r as Map<String, dynamic>` — nếu phần tử
              // không phải Map (JSON lỗi) thì ném TypeError và cả danh sách phòng lân
              // cận không hiển thị. Guard bằng `is Map` an toàn.
              if (r is! Map) return false;
              final rid = r['id']?.toString() ?? r['roomId']?.toString() ?? '';
              return rid != myId && rid.isNotEmpty;
            })
            .take(8)
            .toList() ??
        <dynamic>[];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (bsCtx) {
        final screenH = MediaQuery.of(context).size.height;
        final bottomPad = MediaQuery.of(context).padding.bottom;
        return SizedBox(
          height: screenH * 0.88,
          child: Column(
            children: [
              // Sheet header (const-friendly)
              _MapSheetHeader(onClose: () => Navigator.of(bsCtx).pop()),

              // Map - wrapped in RepaintBoundary to isolate repaints
              Expanded(
                child: RepaintBoundary(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: 15.5,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: OsmMapService.tileUrl,
                        subdomains: OsmMapService.tileSubdomains,
                        userAgentPackageName: 'com.stayhub.app',
                        // Cache tiles aggressively
                        maxZoom: 19,
                        minZoom: 10,
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: center,
                            width: 48,
                            height: 48,
                            alignment: Alignment.topCenter,
                            child: const _RoomMapPin(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom panel (white card)
              _MapBottomPanel(
                poisList: poisList,
                poiColors: poiColors,
                poiIcons: poiIcons,
                poiIconIdx: poiIconIdx,
                nearbyRooms: nearbyRooms,
                parentContext: context,
                parentBsCtx: bsCtx,
                bottomPad: bottomPad,
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPartialData =
        widget.room.isNotEmpty &&
        widget.room['images'] == null &&
        widget.room['roomImages'] == null &&
        widget.room['postImages'] == null;

    if (widget.room.isEmpty || isPartialData) {
      if (_resolvedRoom == null) {
        return Container(
          color: AppTheme.kBackgroundLight,
          child: const Center(child: CupertinoActivityIndicator()),
        );
      } else if (_resolvedRoom!.isEmpty) {
        return Container(
          color: AppTheme.kBackgroundLight,
          child: const Center(child: Text('Không tìm thấy phòng')),
        );
      }
    }

    final roomToUse =
        ((widget.room.isEmpty || isPartialData) && _resolvedRoom != null)
        ? _resolvedRoom!
        : widget.room;
    return _buildContent(context, roomToUse);
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> room) {
    // Build cache if not yet built (first synchronous render)
    if (_cachedImages == null) _buildRoomCache(room);
    final authUser = ref.watch(authProvider).value;
    final isLoggedIn = authUser != null;
    // Use cached images - never recompute on rebuild
    final images = _cachedImages!;

    // `detailedInfo` có thể là Map hoặc JSON string (tuỳ nguồn dữ liệu).
    Map<String, dynamic> info = {};
    final diRaw = room['detailedInfo'];
    if (diRaw is Map) {
      info = Map<String, dynamic>.from(diRaw);
    } else if (diRaw is String && diRaw.trim().startsWith('{')) {
      try {
        final decoded = jsonDecode(diRaw);
        if (decoded is Map) info = Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    final price =
        double.tryParse(
          room['promotionPrice']?.toString() ?? room['price']?.toString() ?? '',
        ) ??
        0;
    final area =
        double.tryParse(
          room['floorArea']?.toString() ?? room['area']?.toString() ?? '',
        ) ??
        0;

    // Service prices (điện/nước/mạng/gửi xe/rác/phí dịch vụ) belong to the
    // BRANCH. The room object usually does NOT carry them, so we must read from
    // `room['branch']` (injected by the caller) before falling back to the room.
    final branchRaw = room['branch'];
    Map<String, dynamic> branchMap = branchRaw is Map
        ? Map<String, dynamic>.from(branchRaw)
        : (() {
            try {
              return Map<String, dynamic>.from(
                (branchRaw as dynamic).toJson() as Map,
              );
            } catch (_) {
              return <String, dynamic>{};
            }
          })();

    // ── Fallback: dữ liệu công khai (MarketplacePostDTO) trả các field branch
    //    ở dạng PHẲNG (branchName, internetPrice, parkingPrice, trashPrice,
    //    waterPricingType, branchAmenities) chứ không lồng trong `branch`.
    //    Gộp chúng vào branchMap để khối "Chi phí" + "Tiện ích toà nhà" hiển thị
    //    giống hệt lúc xem trước.
    void adoptFlat(String flatKey, String branchKey) {
      final v = room[flatKey];
      if (v == null) return;
      final existing = branchMap[branchKey];
      if (existing == null || (existing is String && existing.isEmpty)) {
        branchMap[branchKey] = v;
      }
    }

    adoptFlat('internetPrice', 'internetPrice');
    adoptFlat('parkingPrice', 'parkingPrice');
    adoptFlat('trashPrice', 'trashPrice');
    adoptFlat('waterPricingType', 'waterPricingType');
    adoptFlat('elecPricingType', 'elecPricingType');
    adoptFlat('internetPricingType', 'internetPricingType');
    adoptFlat('parkingPricingType', 'parkingPricingType');
    adoptFlat('trashPricingType', 'trashPricingType');
    adoptFlat('servicePricingType', 'servicePricingType');
    adoptFlat('branchAmenities', 'branchAmenities');
    adoptFlat('electricityPrice', 'electricityPrice');
    adoptFlat('waterPrice', 'waterPrice');
    adoptFlat('serviceFee', 'serviceFee');

    // Tiện ích chung của toà nhà (bước 2 khi tạo chi nhánh) — kèm giá nếu có.
    final branchAmenities = <Map<String, dynamic>>[];
    {
      List<dynamic>? raw;
      final direct = branchMap['branchAmenities'];
      if (direct is List) {
        raw = direct;
      } else {
        final desc = branchMap['description'];
        dynamic decoded = desc;
        if (desc is String && desc.trim().startsWith('{')) {
          try {
            decoded = jsonDecode(desc);
          } catch (_) {
            decoded = null;
          }
        }
        if (decoded is Map && decoded['branchAmenities'] is List) {
          raw = decoded['branchAmenities'] as List;
        }
      }
      if (raw != null) {
        for (final a in raw) {
          if (a is! Map) continue;
          final name = (a['name'] ?? '').toString().trim();
          if (name.isEmpty) continue;
          final chargeType = (a['chargeType'] ?? 'free').toString();
          final price = double.tryParse((a['price'] ?? 0).toString()) ?? 0;
          branchAmenities.add({
            'name': name,
            // Tiện ích "free" luôn coi như 0đ, tránh hiển thị giá sai.
            'price': chargeType == 'free' ? 0.0 : price,
            'chargeType': chargeType,
            'icon': (a['icon'] ?? a['emoji'] ?? '✅').toString(),
          });
        }
      }
    }

    /// Derives a fee from the branch's `branchAmenities` metadata (root list
    /// or the branch description JSON). Reliable fallback when the dedicated
    /// fee column is 0/null (branches created before the fee mapping existed).
    /// Amenities marked `chargeType: 'free'` are ignored.
    double feeFromAmenities(List<String> prefixes) {
      double best = 0;
      for (final a in branchAmenities) {
        final name = (a['name'] ?? '').toString().toLowerCase();
        if (name.isEmpty) continue;
        if (!prefixes.any((p) => name.contains(p))) continue;
        final chargeType = (a['chargeType'] ?? 'free').toString();
        if (chargeType == 'free') continue;
        final price = double.tryParse((a['price'] ?? 0).toString()) ?? 0;
        if (price > best) best = price;
      }
      return best;
    }

    /// Reads a numeric fee from the branch (canonical key or JSON alias),
    /// then derives it from `branchAmenities`, then falls back to the room.
    double feeOf(
      String key, {
      String? alias,
      List<String> roomKeys = const [],
      List<String> amenityPrefixes = const [],
    }) {
      dynamic v = branchMap[key];
      if (v == null && alias != null) v = branchMap[alias];
      final direct = double.tryParse(v?.toString() ?? '') ?? 0;
      if (direct > 0) return direct;
      if (amenityPrefixes.isNotEmpty) {
        final derived = feeFromAmenities(amenityPrefixes);
        if (derived > 0) return derived;
      }
      if (v == null) {
        for (final rk in roomKeys) {
          v = room[rk] ?? info[rk];
          if (v != null) break;
        }
      }
      return double.tryParse(v?.toString() ?? '') ?? 0;
    }

    String typeOf(String key, {String? alias, List<String> roomKeys = const [], List<String> amenityPrefixes = const []}) {
      dynamic v = branchMap[key];
      if (v == null && alias != null) v = branchMap[alias];
      if (v != null && v.toString().isNotEmpty) return v.toString();
      
      if (amenityPrefixes.isNotEmpty) {
        String bestType = '';
        double bestPrice = 0;
        for (final a in branchAmenities) {
          final name = (a['name'] ?? '').toString().toLowerCase();
          if (name.isEmpty) continue;
          if (!amenityPrefixes.any((p) => name.contains(p))) continue;
          final chargeType = (a['chargeType'] ?? 'free').toString();
          if (chargeType == 'free') continue;
          final price = double.tryParse((a['price'] ?? 0).toString()) ?? 0;
          if (price >= bestPrice) {
            bestPrice = price;
            bestType = chargeType;
          }
        }
        if (bestType.isNotEmpty) return bestType;
      }
      if (v == null) {
        for (final rk in roomKeys) {
          v = room[rk] ?? info[rk];
          if (v != null && v.toString().isNotEmpty) return v.toString();
        }
      }
      return '';
    }

    final elecPrice = feeOf(
      'electricityPrice',
      roomKeys: ['electricPrice', 'electricityPrice'],
    );
    final waterPrice = feeOf('waterPrice', roomKeys: ['waterPrice']);
    final serviceFee = feeOf(
      'serviceFee',
      roomKeys: ['serviceFee'],
      amenityPrefixes: ['dịch vụ', 'bảo vệ', 'thang máy', 'quản lý'],
    );
    final internetPrice = feeOf(
      'internetPrice',
      alias: 'internetFee',
      roomKeys: ['internetPrice', 'internetFee'],
      amenityPrefixes: ['wifi', 'internet', 'mạng'],
    );
    final parkingPrice = feeOf(
      'parkingPrice',
      alias: 'parkingFee',
      roomKeys: ['parkingPrice', 'parkingFee'],
      amenityPrefixes: ['bãi để xe', 'giữ xe', 'gửi xe', 'đỗ xe', 'bãi giữ xe'],
    );
    final trashPrice = feeOf(
      'trashPrice',
      alias: 'garbageFee',
      roomKeys: ['trashPrice', 'garbageFee'],
      amenityPrefixes: ['vệ sinh', 'rác', 'thu gom'],
    );
    final elecPricingType = typeOf('elecPricingType', roomKeys: ['elecPricingType', 'electricityPricingType']);
    final waterPricingType = typeOf('waterPricingType', roomKeys: ['waterPricingType']);
    final servicePricingType = typeOf('servicePricingType', amenityPrefixes: ['dịch vụ', 'bảo vệ', 'thang máy', 'quản lý']);
    final internetPricingType = typeOf('internetPricingType', amenityPrefixes: ['wifi', 'internet', 'mạng']);
    final parkingPricingType = typeOf('parkingPricingType', amenityPrefixes: ['bãi để xe', 'giữ xe', 'gửi xe', 'đỗ xe', 'bãi giữ xe']);
    final trashPricingType = typeOf('trashPricingType', amenityPrefixes: ['vệ sinh', 'rác', 'thu gom']);
    final baseDeposit = double.tryParse(room['deposit']?.toString() ?? '') ?? 0;
    final furnitureLevel = info['furnitureLevel']?.toString() ?? '';

    // Loại phòng con + WC chung (bước 2/3) — DTO công khai trả ở dạng phẳng.
    final roomSubType = (info['roomSubType'] ?? room['roomSubType'] ?? '')
        .toString();
    final isSharedWc =
        info['isSharedWc'] == true ||
        info['isSharedWc'] == 'true' ||
        room['isSharedWc'] == true ||
        room['isSharedWc'] == 'true' ||
        room['bathroomType'] == 'CHUNG';

    List<String> amenities = [];
    if (info['furnitureItems'] != null && info['furnitureItems'] is List) {
      amenities.addAll(List<String>.from(info['furnitureItems']));
    } else if (room['furniture'] != null &&
        room['furniture'].toString().isNotEmpty) {
      try {
        final decoded = jsonDecode(room['furniture'].toString());
        if (decoded is List) {
          amenities = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        amenities = room['furniture']
            .toString()
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    // Add shared facilities equipment if it's a shared WC room
    final shared = room['sharedFacilities'];
    if (shared != null && shared is List) {
      for (final f in shared) {
        // `f` có thể KHÔNG phải Map (JSON lỗi/định dạng cũ) → guard tránh crash.
        if (f is! Map) continue;
        final equipment = f['equipment'];
        if (equipment is List) {
          amenities.addAll(equipment.map((e) => e.toString()));
        }
      }
    }

    final Map<String, String> furnitureMap = {
      'AC': 'Điều hoà',
      'NUOC_NONG': 'Nóng lạnh',
      'GIUONG': 'Giường đệm',
      'TU_QUAN_AO': 'Tủ quần áo',
      'BAN_HOC': 'Bàn học',
      'TU_LANH': 'Tủ lạnh',
      'TV': 'TV',
      'MAY_GIAT': 'Máy giặt',
      'BEP': 'Bếp',
      'SOFA': 'Sofa',
      'BAN_GHE': 'Bàn ghế',
      'TU_BEP': 'Tủ bếp',
      'BEP_TU': 'Bếp từ/gas',
      'LO_VI_SONG': 'Lò vi sóng',
      'HUT_MUI': 'Máy hút mùi',
      'MAY_LOC_NUOC': 'Máy lọc nước',
      'BINH_NONG_LANH': 'Bình nóng lạnh',
      'VOI_SEN': 'Vòi sen',
      'BET': 'Bồn cầu bệt',
      'BON_CAU_BET': 'Bồn cầu bệt',
      'BON_CAU_XOM': 'Bồn cầu xổm',
      'GUONG': 'Gương soi',
      'CHAU_RUA': 'Chậu rửa mặt',
      'QUAT_THONG_GIO': 'Quạt thông gió',
      'CUA_SO': 'Cửa sổ',
      'BAN_CONG': 'Ban công',
      'GAC_LUNG': 'Gác lửng',
      'WC': 'Vệ sinh riêng',
    };
    amenities = amenities.map((e) => furnitureMap[e] ?? e).toList();

    if (info['hasBalcony'] == true || info['hasBalcony'] == 'true' ||
        room['hasBalcony'] == true ||
        room['hasBalcony'] == 'true') {
      amenities.add('Ban công');
    }
    if (info['hasWindow'] == true || info['hasWindow'] == 'true' ||
        room['hasWindow'] == true ||
        room['hasWindow'] == 'true') {
      amenities.add('Cửa sổ');
    }
    if (info['hasKitchen'] == true || info['hasKitchen'] == 'true') amenities.add('Khu bếp riêng');

    // BUGFIX: ưu tiên `addressOld` (địa chỉ cũ 4 cấp, dùng cho UI/Map) — trước đây
    // bị bỏ qua nên địa chỉ hiển thị khác lúc xem trước.
    String address =
        room['addressOld'] ??
        room['branchAddress'] ??
        branchMap['address'] ??
        (room['branch'] is Map ? room['branch']['address'] : null) ??
        room['address'] ??
        room['region'] ??
        'Chưa cập nhật địa chỉ';
    if (!isLoggedIn) {
      address = address.replaceAll(
        RegExp(r'^(Số\s*)?[0-9A-Za-z/]+\s*,?\s*'),
        '***, ',
      );
    }

    final addrParts = address.split(',');
    if (addrParts.length > 2) {
      int splitIndex = addrParts.length - 2;
      final line1 = addrParts
          .sublist(0, splitIndex)
          .map((e) => e.trim())
          .join(', ');
      final line2 = addrParts
          .sublist(splitIndex)
          .map((e) => e.trim())
          .join(', ');
      address = '$line1,\n$line2';
    }

    // Loại phòng: gom mọi nguồn (detailedInfo.roomType, room.roomType,
    // room.roomSubType) về MÃ canonical rồi đổi sang NHÃN qua nguồn chân lý
    // duy nhất RoomTypeCodes — không hardcode map cục bộ.
    final rawRoomType =
        (info['roomType'] ?? room['roomType'] ?? roomSubType)?.toString() ?? '';
    final roomType = rawRoomType.isNotEmpty
        ? RoomTypeCodes.labelOf(rawRoomType)
        : 'Phòng trọ';

    String restroomType = 'Khép kín';
    if (info['isSelfContained'] == true || info['isSelfContained'] == 'true') {
      restroomType = 'Khép kín';
    } else if (info['isSelfContained'] == false || info['isSelfContained'] == 'false') {
      restroomType = 'Chung';
    } else if (isSharedWc) {
      // BUGFIX: dùng cờ `isSharedWc` (đã gộp cả bathroomType == 'CHUNG').
      restroomType = 'Chung';
    } else if (room['bathroomType'] == 'RIENG') {
      restroomType = 'Khép kín';
    }

    // BUGFIX: TIÊU ĐỀ TIN ĐĂNG phải ưu tiên `postTitle` (tên bài đăng chủ trọ nhập),
    // KHÔNG phải tên phòng. Trước đây ưu tiên `title`/`roomName` → hiển thị sai.
    var rawName =
        (room['postTitle'] != null &&
            room['postTitle'].toString().trim().isNotEmpty)
        ? room['postTitle'].toString().trim()
        : (room['post'] is Map &&
              room['post']['title'] != null &&
              room['post']['title'].toString().trim().isNotEmpty)
        ? room['post']['title'].toString().trim()
        : (room['title'] != null && room['title'].toString().trim().isNotEmpty)
        ? room['title'].toString().trim()
        : (room['roomName'] ?? room['name'] ?? '').toString();

    if (rawName.isNotEmpty &&
        room['postTitle'] == null &&
        room['title'] == null &&
        room['post'] == null) {
      // Generate a catchy title!
      String districtStr = '';
      if (address.isNotEmpty && !address.contains('Chưa cập nhật')) {
        final flatAddr = address.replaceAll('\n', ' ');
        final p = flatAddr.split(',');
        if (p.length >= 2) districtStr = ' tại ${p[p.length - 2].trim()}';
      }

      String furStr = '';
      if (furnitureLevel == 'FULL') {
        furStr = ', full nội thất';
      } else if (furnitureLevel == 'BASIC') {
        furStr = ', đồ cơ bản';
      }

      String rrStr = (restroomType == 'Khép kín') ? ' khép kín' : '';

      rawName = 'Cho thuê $roomType$rrStr$furStr$districtStr';
    }
    final roomName = rawName;

    final isOwner =
        authUser != null &&
        authUser.id.toString() == room['ownerId']?.toString();
    final resolvedOwnerName =
        room['ownerFullName'] ??
        room['ownerName'] ??
        room['landlordName'] ??
        (room['owner'] is Map
            ? room['owner']['fullName'] ?? room['owner']['name']
            : null) ??
        (room['post'] is Map && room['post']['author'] is Map
            ? room['post']['author']['fullName']
            : null) ??
        (room['branch'] is Map && room['branch']['owner'] is Map
            ? room['branch']['owner']['fullName']
            : null) ??
        (room['branch'] is Map ? room['branch']['ownerName'] : null) ??
        (isOwner ? authUser.fullName : null) ??
        'Chủ nhà';
    final resolvedOwnerAvatar =
        room['ownerAvatar'] ??
        room['hostAvatar'] ??
        (room['owner'] is Map
            ? room['owner']['avatarUrl'] ?? room['owner']['avatar']
            : null) ??
        (room['post'] is Map && room['post']['author'] is Map
            ? room['post']['author']['avatarUrl']
            : null) ??
        (isOwner ? authUser.avatar : null);

    final phone =
        room['phone']?.toString() ??
        room['ownerPhone']?.toString() ??
        (room['owner'] is Map ? room['owner']['phone'] : null) ??
        (isOwner ? authUser.phoneNumber : null) ??
        '';
    // ── Security: Guest Mode KHÔNG được thấy SĐT chủ nhà (NĐ 13/2023/NĐ-CP) ──
    // Chỉ chủ sở hữu (isOwner) hoặc người đã đăng nhập mới thấy số đầy đủ.
    final String ownerSubtitle;
    if (phone.isEmpty) {
      ownerSubtitle = 'Chủ phòng xác thực';
    } else if (isOwner || isLoggedIn) {
      ownerSubtitle = phone;
    } else {
      // FOMO Effect: Hiển thị đầu số và che các số cuối để kích thích tính tò mò
      final maskedPhone = phone.length >= 4
          ? '${phone.substring(0, 4)}.***.*** (Đăng nhập để xem)'
          : '***.*** (Đăng nhập để xem)';
      ownerSubtitle = maskedPhone;
    }

    final description =
        info['roomDescription']?.toString() ??
        room['description']?.toString() ??
        room['note']?.toString() ??
        'Chưa có mô tả chi tiết.';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: CustomScrollView(
                controller: widget.scrollController,
                // ignore: deprecated_member_use
                cacheExtent: 600,
                physics: const ClampingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    expandedHeight: 280,
                    backgroundColor: Colors.white,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    pinned: true,
                    stretch: false,
                    collapsedHeight: 64,
                    toolbarHeight: 64,
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      background: RepaintBoundary(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            images.isNotEmpty
                                ? Hero(
                                    tag:
                                        'room_image_${room['id'] ?? room['roomId']}',
                                    child: PageView.builder(
                                      controller: _pageController,
                                      onPageChanged: (idx) => setState(
                                        () => _currentImageIndex = idx,
                                      ),
                                      itemCount: images.length,
                                      itemBuilder: (ctx, idx) {
                                        final isVideo = images[idx]
                                            .toLowerCase()
                                            .endsWith('.mp4');
                                        return GestureDetector(
                                          onTap: () {
                                            try {
                                              if (!context.mounted) return;
                                              unawaited(
                                                Navigator.of(
                                                  context,
                                                  rootNavigator: true,
                                                ).push(
                                                  PageRouteBuilder(
                                                    opaque: false,
                                                    barrierDismissible: true,
                                                    barrierColor: Colors.transparent,
                                                    pageBuilder: (_, __, ___) =>
                                                        FullScreenMediaViewer(
                                                          imageUrls: images,
                                                          initialIndex: idx,
                                                        ),
                                                  ),
                                                ),
                                              );
                                            } catch (_) {
                                              // Bỏ qua lỗi điều hướng để không crash UI.
                                            }
                                          },
                                          onDoubleTap: () =>
                                              _handleDoubleTapHeart(),
                                          child: isVideo
                                              ? Container(
                                                  color: CupertinoColors.black,
                                                  child: const Center(
                                                    child: Icon(
                                                      CupertinoIcons
                                                          .play_circle_fill,
                                                      size: 64,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                )
                                              : CachedNetworkImage(
                                                  imageUrl:
                                                      ImageUrlHelper.buildUrl(
                                                        images[idx],
                                                      ) ??
                                                      images[idx],
                                                  fit: BoxFit.cover,
                                                  memCacheWidth: 800,
                                                  errorWidget:
                                                      (ctx, err, stack) =>
                                                          Container(
                                                            color: AppTheme
                                                                .kSurfaceBlue,
                                                          ),
                                                ),
                                        );
                                      },
                                    ),
                                  )
                                : Container(color: AppTheme.kSurfaceBlue),

                            // Close X Button
                            Positioned(
                              top: 24,
                              left: 20,
                              child: GestureDetector(
                                onTap: () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go('/marketplace');
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.xmark,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                            
                            // Drag handle
                            Positioned(
                              top: 12,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  width: 48,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black26, blurRadius: 4),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            if (_showBigHeart)
                              Positioned.fill(
                                child: Center(
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.5, end: 1.0),
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.elasticOut,
                                    builder: (context, scale, child) {
                                      return Transform.scale(
                                        scale: scale,
                                        child: const Icon(
                                          CupertinoIcons.heart_fill,
                                          color: Colors.white,
                                          size: 100,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),

                            if (images.isNotEmpty)
                              Positioned(
                                bottom: 36,
                                right: 14,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_currentImageIndex + 1}/${images.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: ChoTotRoomDetailLayout(
                      amenities: amenities,
                      elecPrice: elecPrice,
                      waterPrice: waterPrice,
                      internetPrice: internetPrice,
                      parkingPrice: parkingPrice,
                      trashPrice: trashPrice,
                      serviceFee: serviceFee,
                      waterPricingType: waterPricingType,
                      elecPricingType: elecPricingType,
                      internetPricingType: internetPricingType,
                      parkingPricingType: parkingPricingType,
                      trashPricingType: trashPricingType,
                      servicePricingType: servicePricingType,
                      room: room,
                      info: info,
                      branchMap: branchMap,
                      images: images,
                      roomName: roomName,
                      address: address,
                      price: price,
                      area: area,
                      baseDeposit: baseDeposit,
                      roomTypeLabel: roomType,
                      description: description,
                      resolvedOwnerName: resolvedOwnerName,
                      resolvedOwnerAvatar: resolvedOwnerAvatar,
                      ownerSubtitle: ownerSubtitle,
                      isWishlisted: _isWishlisted,
                      onToggleWishlist: _handleDoubleTapHeart,
                      onRequireLogin: () async {
                        final authUser = ref.read(authProvider).value;
                        if (authUser == null) {
                          GuestAuthBottomSheet.show(context);
                        } else if (phone.isNotEmpty) {
                          final uri = Uri.parse('tel:$phone');
                          if (await canLaunchUrl(uri)) await launchUrl(uri);
                        } else {
                          ToastUtils.show(context, 'Chủ nhà không cung cấp số điện thoại.', isError: true);
                        }
                      },
                      onMapTap: () => _showMap(context, room),
                    ),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
                ],
              ),
            ),
          ),
          // ── Bottom Action Bar (Standard Style) ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final authUser = ref.read(authProvider).value;
                        if (authUser == null) {
                          GuestAuthBottomSheet.show(context);
                        } else {
                          final isKycVerified = authUser.kycStatus == 'APPROVED';
                          if (!isKycVerified) {
                            unawaited(
                              showCupertinoDialog(
                                context: context,
                                builder: (ctx) => const EkycVerificationDialog(
                                  customContent:
                                      'Tài khoản của bạn cần được xác thực danh tính (EKYC) để nhắn tin cho chủ nhà.',
                                ),
                              ),
                            );
                            return;
                          }
                          
                          final ownerIdRaw = room['ownerId'] ?? 
                              room['userId'] ??
                              room['authorId'] ??
                              (room['owner'] is Map ? room['owner']['id'] ?? room['owner']['userId'] : null) ?? 
                              (room['post'] is Map && room['post']['author'] is Map ? room['post']['author']['id'] : null) ??
                              (room['branch'] is Map && room['branch']['owner'] is Map ? room['branch']['owner']['id'] : null) ??
                              (room['branch'] is Map ? room['branch']['ownerId'] : null);
                          final ownerId = int.tryParse(ownerIdRaw?.toString() ?? '0') ?? 0;
                          
                          if (ownerId == 0 || ownerId.toString() == authUser.id.toString()) {
                            ToastUtils.show(context, 'Không thể chat với chính mình hoặc không tìm thấy chủ nhà.', isError: true);
                            return;
                          }
                          
                          ToastUtils.show(context, 'Đang kết nối...');
                          try {
                            final thread = await ref
                                .read(conversationProvider.notifier)
                                .createOrGetThread(ownerId, 'INQUIRY');
                            
                            if (!context.mounted) return;
                            
                            if (thread != null) {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (_) => ThreadMessageScreen(
                                    threadId: thread.id, 
                                    title: resolvedOwnerName,
                                  ),
                                ),
                              );
                            } else {
                              ToastUtils.show(context, 'Không mở được cuộc trò chuyện.', isError: true);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ToastUtils.show(context, 'Lỗi kết nối: $e', isError: true);
                            }
                          }
                        }
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFCBD5E1),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.chat_bubble_text,
                              color: Color(0xFF0F172A),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Chat',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final authUser = ref.read(authProvider).value;
                        if (authUser == null) {
                          GuestAuthBottomSheet.show(context);
                        } else if (phone.isNotEmpty) {
                          final uri = Uri.parse('tel:$phone');
                          if (await canLaunchUrl(uri)) await launchUrl(uri);
                        } else {
                          ToastUtils.show(context, 'Chủ nhà không cung cấp số điện thoại.', isError: true);
                        }
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.kBrand,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.phone,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Gọi',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Map sheet helper widgets (extracted to avoid full-tree rebuilds)
// ═══════════════════════════════════════════════════════════════════════

/// Lightweight header for the map bottom sheet.
class _MapSheetHeader extends StatelessWidget {
  final VoidCallback onClose;
  const _MapSheetHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppTheme.kBrand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    CupertinoIcons.map_fill,
                    color: AppTheme.kBrand,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Vị trí & Khu vực',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.xmark,
                      size: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Const-friendly map pin marker for the main room.
class _RoomMapPin extends StatelessWidget {
  const _RoomMapPin();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.kBrand,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x664C8CFF),
            blurRadius: 12,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        CupertinoIcons.house_fill,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}

/// Bottom panel: POI chips + nearby room cards.
class _MapBottomPanel extends StatelessWidget {
  final List<String> poisList;
  final List<Color> poiColors;
  final List<IconData> poiIcons;
  final int Function(String) poiIconIdx;
  final List<dynamic> nearbyRooms;
  final BuildContext parentContext;
  final BuildContext parentBsCtx;
  final double bottomPad;

  const _MapBottomPanel({
    required this.poisList,
    required this.poiColors,
    required this.poiIcons,
    required this.poiIconIdx,
    required this.nearbyRooms,
    required this.parentContext,
    required this.parentBsCtx,
    required this.bottomPad,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── POI chips ──
          if (poisList.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.map_pin_ellipse,
                    size: 13,
                    color: Color(0xFF3B82F6),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Tiện ích gần đây',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: poisList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 7),
                itemBuilder: (_, i) {
                  final color = poiColors[i % poiColors.length];
                  final icon = poiIcons[poiIconIdx(poisList[i])];
                  return _PoiChip(label: poisList[i], color: color, icon: icon);
                },
              ),
            ),
            const SizedBox(height: 4),
          ],

          // ── Nearby rooms ──
          if (nearbyRooms.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: Row(
                children: [
                  Icon(CupertinoIcons.home, size: 13, color: Color(0xFF8B5CF6)),
                  SizedBox(width: 6),
                  Text(
                    'Phòng lân cận',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 106,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 2),
                itemCount: nearbyRooms.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final r = nearbyRooms[i] as Map<String, dynamic>;
                  return _NearbyRoomCard(
                    room: r,
                    onTap: () {
                      Navigator.of(parentBsCtx).pop();
                      showModalBottomSheet(
                        context: parentContext,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (c) => DraggableScrollableSheet(
                          initialChildSize: 0.92,
                          maxChildSize: 0.97,
                          minChildSize: 0.5,
                          builder: (cc, sc) => GuestRoomDetailBottomSheet(
                            room: r,
                            scrollController: sc,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
          SizedBox(height: bottomPad + 10),
        ],
      ),
    );
  }
}

/// Single POI chip (const-constructable for performance).
class _PoiChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _PoiChip({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Nearby room card shown in the map bottom panel.
class _NearbyRoomCard extends StatelessWidget {
  final Map<String, dynamic> room;
  final VoidCallback onTap;
  const _NearbyRoomCard({required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Extract image
    String? imgUrl;
    final imgs = room['images'];
    final roomImgs = room['roomImages'];
    if (imgs is List && imgs.isNotEmpty) {
      imgUrl = imgs.first?.toString();
    } else if (roomImgs is List && roomImgs.isNotEmpty) {
      final first = roomImgs.first;
      imgUrl = (first is Map ? first['imageUrl'] : first)?.toString();
    }
    if (imgUrl != null) imgUrl = ImageUrlHelper.buildUrl(imgUrl) ?? imgUrl;

    final priceRaw = room['promotionPrice'] ?? room['price'];
    final priceVal = double.tryParse(priceRaw?.toString() ?? '') ?? 0;
    final priceStr = priceVal > 0
        ? NumberFormat.compactCurrency(
            locale: 'vi_VN',
            symbol: 'đ',
            decimalDigits: 0,
          ).format(priceVal)
        : 'Liên hệ';
    final name =
        room['postTitle']?.toString() ??
        room['title']?.toString() ??
        room['name']?.toString() ??
        'Phòng cho thuê';
    final areaStr =
        room['floorArea']?.toString() ?? room['area']?.toString() ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 210,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8EEFB)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
              child: imgUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imgUrl,
                      width: 78,
                      height: 106,
                      fit: BoxFit.cover,
                      memCacheWidth: 156, // 2x for retina
                      errorWidget: (_, __, ___) =>
                          const _RoomThumbPlaceholder(),
                    )
                  : const _RoomThumbPlaceholder(),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      priceStr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.kBrand,
                      ),
                    ),
                    if (areaStr.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            CupertinoIcons.square_split_2x1_fill,
                            size: 10,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '$areaStr m²',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomThumbPlaceholder extends StatelessWidget {
  const _RoomThumbPlaceholder();
  @override
  Widget build(BuildContext context) => Container(
    width: 78,
    height: 106,
    color: const Color(0xFFEFF6FF),
    child: const Icon(CupertinoIcons.photo, color: Color(0xFFBFDBFE), size: 22),
  );
}
