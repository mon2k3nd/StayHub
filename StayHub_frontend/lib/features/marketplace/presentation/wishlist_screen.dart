import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'widgets/guest_room_detail_premium.dart';
import '../application/wishlist_provider.dart';
import '../../auth/application/auth_notifier.dart';
import '../../auth/presentation/widgets/guest_auth_bottom_sheet.dart';
import '../../guest/presentation/compare_rooms_screen.dart';
import '../../../core/services/compare_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'dart:math' as math;
import '../../../core/services/osm_map_service.dart';
import '../../../core/components/bounce_click.dart';
import '../../../core/components/safe_network_image.dart';
import '../application/location_provider.dart';
import 'dart:async' show unawaited;
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../guest/presentation/guest_main_scaffold.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../../core/widgets/share_room_sheet.dart';

enum _WishlistTabType { available, upcoming, rented }

class WishlistScreen extends ConsumerStatefulWidget {
  const WishlistScreen({super.key});

  @override
  ConsumerState<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends ConsumerState<WishlistScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isEditMode = false;
  bool _isMapView = false;
  final Set<String> _selectedRoomIds = {};
  final Set<String> _notifiedRoomIds = {};
  final MapController _mapController = MapController();

  // Ghim địa chỉ Cơ quan / Trường học của người dùng
  String? _workAddress;
  LatLng? _workCoord;
  final bool _showWorkRadius = true;
  bool _dismissWorkplaceBanner = false;
  bool _hasTriggeredRefreshHaptic = false;

  // Baseline toạ độ trung tâm TP.HCM (Quận 1 - Bến Thành: 10.7725, 106.6980)
  static const double _defaultCenterLat = 10.7725;
  static const double _defaultCenterLng = 106.6980;

  // Quản lý marker phòng được chọn và cuộn thẻ xem trước trên bản đồ
  String? _selectedMapRoomId;
  final ScrollController _mapCardScrollController = ScrollController();

  // Cache toạ độ geocoding để tránh gọi API nhiều lần
  final Map<String, LatLng> _geocodedAddresses = {};
  final Set<String> _pendingGeocodes = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadNotifiedRooms();
    _loadWorkplace();
  }

  /// Trích xuất toạ độ thực tế của phòng trọ (hoặc kích hoạt geocoding bất đồng bộ nếu chưa có)
  LatLng? _resolveRoomCoordinates(Map<String, dynamic> room) {
    // 1. Kiểm tra trực tiếp các trường toạ độ trong room
    double? lat = double.tryParse(room['latitude']?.toString() ?? '') ??
        double.tryParse(room['lat']?.toString() ?? '') ??
        double.tryParse(room['branchLatitude']?.toString() ?? '');
    double? lng = double.tryParse(room['longitude']?.toString() ?? '') ??
        double.tryParse(room['lng']?.toString() ?? '') ??
        double.tryParse(room['branchLongitude']?.toString() ?? '');

    // 2. Fallback sang thông tin branch lồng nhau nếu có
    if ((lat == null || lng == null) && room['branch'] is Map) {
      final b = room['branch'] as Map;
      lat ??= double.tryParse(b['latitude']?.toString() ?? '');
      lng ??= double.tryParse(b['longitude']?.toString() ?? '');
    }

    if (lat != null && lng != null && OsmMapService.isInsideVietnam(LatLng(lat, lng))) {
      return LatLng(lat, lng);
    }

    // 3. Fallback tra cứu địa chỉ thực tế (address / branchAddress)
    final address = (room['address'] ??
            room['branchAddress'] ??
            (room['branch'] is Map ? room['branch']['address'] : null))
        ?.toString()
        .trim() ?? '';

    if (address.isNotEmpty) {
      if (_geocodedAddresses.containsKey(address)) {
        return _geocodedAddresses[address];
      }
      _geocodeAddressAsync(address);
    }
    return null;
  }

  /// Geocoding bất đồng bộ từ địa chỉ thật và cập nhật bản đồ
  Future<void> _geocodeAddressAsync(String address) async {
    if (_pendingGeocodes.contains(address)) return;
    _pendingGeocodes.add(address);
    try {
      // B1: Thử tra cứu qua OsmMapService (hỗ trợ danh mục địa điểm nhanh)
      final results = await OsmMapService().searchAddress(address, limit: 1);
      if (results.isNotEmpty && mounted) {
        setState(() {
          _geocodedAddresses[address] = results.first.latLng;
        });
        return;
      }

      // B2: Fallback trực tiếp qua Nominatim OSM
      final dio = Dio();
      final res = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': address,
          'format': 'json',
          'limit': 1,
          'countrycodes': 'vn',
        },
        options: Options(
          headers: {'User-Agent': 'StayHubApp/1.0 (stayhub.app)'},
          sendTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );
      if (res.data is List && (res.data as List).isNotEmpty) {
        final data = (res.data as List).first;
        if (data is Map) {
          final lat = double.tryParse(data['lat']?.toString() ?? '');
          final lon = double.tryParse(data['lon']?.toString() ?? '');
          if (lat != null && lon != null && mounted) {
            final pt = LatLng(lat, lon);
            if (OsmMapService.isInsideVietnam(pt)) {
              setState(() {
                _geocodedAddresses[address] = pt;
              });
            }
          }
        }
      }
    } catch (_) {
      // Bỏ qua lỗi mạng
    } finally {
      _pendingGeocodes.remove(address);
    }
  }


  // ─── Helpers: Tiêu đề & Ảnh phòng chuẩn sàn BĐS ──────────────────────────────

  static String _resolveRoomTitle(Map<String, dynamic> r) {
    final title = r['title'] ?? r['postTitle'];
    if (title != null && title.toString().trim().isNotEmpty) {
      return title.toString().trim();
    }
    final branchName = r['branchName'];
    final rName = (r['roomName'] ?? r['name'] ?? 'Phòng').toString().trim();
    final formattedRoom = rName.startsWith('Phòng') ? rName : 'Phòng $rName';
    if (branchName != null && branchName.toString().trim().isNotEmpty) {
      return '$branchName - $formattedRoom';
    }
    return formattedRoom;
  }

  static String _resolveRoomImage(Map<String, dynamic> r) {
    // 1. Ưu tiên coverImageUrl từ bài đăng hoặc phòng
    final cover = r['coverImageUrl'] ?? r['coverImage'];
    if (cover != null && cover.toString().trim().isNotEmpty) {
      final built = ImageUrlHelper.buildUrl(cover.toString().trim());
      if (built != null && built.isNotEmpty) return built;
    }

    // 2. roomImages / postImages / images / image
    final raw = r['roomImages'] ?? r['postImages'] ?? r['images'] ?? r['image'];
    if (raw == null) return '';

    // Trường hợp dữ liệu trả về đã là List
    if (raw is List && raw.isNotEmpty) {
      for (final item in raw) {
        if (item != null && item.toString().trim().isNotEmpty) {
          final built = ImageUrlHelper.buildUrl(item.toString().trim());
          if (built != null && built.isNotEmpty) return built;
        }
      }
    }

    final rawStr = raw.toString().trim();
    if (rawStr.isEmpty) return '';

    try {
      if (rawStr.startsWith('[')) {
        final decoded = jsonDecode(rawStr);
        if (decoded is List && decoded.isNotEmpty) {
          for (final item in decoded) {
            if (item != null && item.toString().trim().isNotEmpty) {
              final built = ImageUrlHelper.buildUrl(item.toString().trim());
              if (built != null && built.isNotEmpty) return built;
            }
          }
        }
      } else {
        final parts = rawStr.split(',');
        for (final part in parts) {
          final cleaned = part
              .replaceAll('"', '')
              .replaceAll("'", "")
              .replaceAll('[', '')
              .replaceAll(']', '')
              .trim();
          final built = ImageUrlHelper.buildUrl(cleaned);
          if (built != null && built.isNotEmpty) return built;
        }
      }
    } catch (_) {}

    return '';
  }

  // Calculate distance in km from workplace or user's real GPS location
  double? _calculateDistance(Map<String, dynamic> room) {
    final coord = _resolveRoomCoordinates(room);
    if (coord == null) return null;

    // 1. Ưu tiên điểm ghim Nơi làm việc / Trường học của người dùng nếu có
    if (_workCoord != null) {
      final distWork = _calculateDistanceToWork(room);
      if (distWork != null && distWork <= 60.0) {
        return distWork;
      }
    }

    // 2. Dùng toạ độ GPS thực tế của thiết bị (chỉ khi thiết bị đã cấp quyền & có vị trí thật)
    final userLoc = ref.read(locationProvider);
    if (userLoc.latitude == null || userLoc.longitude == null) {
      // Chưa có vị trí thật của người dùng -> Không hiển thị khoảng cách giả định để tránh số km phi thực tế
      return null;
    }

    final baseLat = userLoc.latitude!;
    final baseLng = userLoc.longitude!;

    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        math.cos((coord.latitude - baseLat) * p) / 2 +
        math.cos(baseLat * p) *
            math.cos(coord.latitude * p) *
            (1 - math.cos((coord.longitude - baseLng) * p)) /
            2;
    final dist = 12742 * math.asin(math.sqrt(a));

    // Nếu khoảng cách > 80km (khác tỉnh/thành phố, ví dụ người ở TP.HCM xem phòng Hà Nội), không hiển thị phút xe máy nội thành
    if (dist > 80.0) return null;

    return dist;
  }


  // Smart Alternative BottomSheet: Suggest alternative available rooms
  void _showAlternativeRoomsModal(
    BuildContext context,
    Map<String, dynamic> targetRoom,
    List<Map<String, dynamic>> availableRooms,
  ) {
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final targetPrice = double.tryParse(targetRoom['price']?.toString() ?? '') ?? 0;
    
    // Sort available rooms by price closeness or fallback
    final alternatives = List<Map<String, dynamic>>.from(availableRooms)
      ..sort((a, b) {
        final pa = double.tryParse(a['price']?.toString() ?? '') ?? 0;
        final pb = double.tryParse(b['price']?.toString() ?? '') ?? 0;
        return (pa - targetPrice).abs().compareTo((pb - targetPrice).abs());
      });

    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.75,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.9),
                width: 1.2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 30,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        ),
                        child: const Icon(
                          CupertinoIcons.sparkles,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Phòng tương tự đang còn trống',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Cùng tầm giá và khu vực với ${targetRoom['roomName'] ?? targetRoom['name'] ?? 'phòng đã chọn'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: alternatives.isEmpty
                      ? const Center(
                          child: Text(
                            'Hiện chưa có phòng thay thế phù hợp',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: alternatives.take(6).length,
                          itemBuilder: (context, idx) {
                            final altRoom = alternatives[idx];
                            return _WishlistCard(
                              room: altRoom,
                              tabType: _WishlistTabType.available,
                              isDark: isDark,
                              distanceKm: _calculateDistance(altRoom),
                              onSelectChanged: (_) {},
                              onRemove: () => _remove(altRoom),
                              onEditNote: () => _showPrivateNoteDialog(altRoom),
                              onTap: () {
                                Navigator.pop(ctx);
                                unawaited(
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => DraggableScrollableSheet(
                                      initialChildSize: 1.0,
                                      minChildSize: 0.0,
                                      maxChildSize: 1.0,
                                      snap: true,
                                      builder: (_, sc) =>
                                          GuestRoomDetailPremiumBottomSheet(
                                        room: altRoom,
                                        scrollController: sc,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _loadNotifiedRooms() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('wishlist_notified_rooms') ?? [];
    if (mounted) {
      setState(() {
        _notifiedRoomIds.addAll(list);
      });
    }
  }

  Future<void> _toggleNotifyRoom(Map<String, dynamic> room) async {
    final id = room['id']?.toString() ?? room['roomId']?.toString() ?? '';
    if (id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final isNowNotified = !_notifiedRoomIds.contains(id);

    setState(() {
      if (isNowNotified) {
        _notifiedRoomIds.add(id);
      } else {
        _notifiedRoomIds.remove(id);
      }
    });

    await prefs.setStringList('wishlist_notified_rooms', _notifiedRoomIds.toList());

    if (!mounted) return;
    final roomName = room['roomName'] ?? room['name'] ?? 'phòng';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor:
            isNowNotified ? const Color(0xFF0F172A) : const Color(0xFF334155),
        content: Row(
          children: [
            Icon(
              isNowNotified
                  ? CupertinoIcons.bell_fill
                  : CupertinoIcons.bell_slash,
              color: isNowNotified ? const Color(0xFFF59E0B) : Colors.white70,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isNowNotified
                    ? 'Đã bật chuông! StayHub sẽ báo bạn ngay khi $roomName sẵn sàng.'
                    : 'Đã tắt nhận thông báo cho $roomName.',
                style: const TextStyle(fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _toggleVisited(Map<String, dynamic> room) async {
    final roomId = room['id']?.toString() ?? room['roomId']?.toString() ?? '';
    if (roomId.isEmpty) return;
    final current = room['isVisited'] == true;
    final newVal = !current;
    room['isVisited'] = newVal;
    setState(() {});
    await ref.read(wishlistProvider.notifier).updateNoteAndVisited(
      roomId,
      note: room['privateNote']?.toString(),
      isVisited: newVal,
    );
    if (!mounted) return;
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
        backgroundColor:
            newVal ? const Color(0xFF0F172A) : const Color(0xFF334155),
        content: Row(
          children: [
            Icon(
              newVal
                  ? CupertinoIcons.checkmark_seal_fill
                  : CupertinoIcons.clear_circled,
              color: newVal ? const Color(0xFF10B981) : Colors.white70,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              newVal
                  ? 'Đã đánh dấu: Đã đi xem phòng thực tế!'
                  : 'Đã hủy đánh dấu xem phòng.',
              style: const TextStyle(fontSize: 13, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _shareRoom(Map<String, dynamic> room) {
    final title = _resolveRoomTitle(room);
    final price = double.tryParse(room['price']?.toString() ?? '') ?? 0;
    final priceFormatted =
        NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
    final roomId = room['id']?.toString() ?? room['roomId']?.toString() ?? '';
    final shareUrl = 'https://stayhub.vn/room/$roomId';
    final imgUrl = _resolveRoomImage(room);

    ShareRoomSheet.show(
      context,
      title: title,
      priceText: '$priceFormatted/tháng',
      shareUrl: shareUrl,
      imageUrl: imgUrl.isNotEmpty ? imgUrl : null,
    );
  }

  void _onTabChanged() {
    // Chỉ rebuild khi index thực sự đổi (listener còn bắn khi animation).
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _mapCardScrollController.dispose();
    super.dispose();
  }

  Future<void> _remove(Map<String, dynamic> room) async {
    await ref.read(wishlistProvider.notifier).toggle(room);
  }

  Future<void> _compareSelected(List<Map<String, dynamic>> allRooms) async {
    if (_selectedRoomIds.length < 2) return;
    if (_selectedRoomIds.length > 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: const Text(
            'Vui lòng chọn tối đa 3 phòng để so sánh song song.',
            style: TextStyle(fontSize: 13),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final roomsToCompare = allRooms.where((r) {
      final id = r['id']?.toString() ?? r['roomId']?.toString() ?? '';
      return _selectedRoomIds.contains(id);
    }).toList();

    await CompareService.clear();
    for (final r in roomsToCompare) {
      await CompareService.toggle(r);
    }

    if (!mounted) return;
    unawaited(
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => const CompareRoomsScreen(),
        ),
      ),
    );
  }

  Future<void> _removeSelected(List<Map<String, dynamic>> allRooms) async {
    if (_selectedRoomIds.isEmpty) return;

    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: Text('Xóa ${_selectedRoomIds.length} phòng?'),
          content: const Text(
            'Các phòng đã chọn sẽ được bỏ lưu khỏi danh sách yêu thích của bạn.',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Hủy'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Xóa'),
              onPressed: () async {
                Navigator.pop(context);
                final idsToRemove = Set<String>.from(_selectedRoomIds);
                setState(() {
                  _isEditMode = false;
                  _selectedRoomIds.clear();
                });

                // Xóa đồng thời các phòng đã chọn thay vì tuần tự từng request
                final roomsToRemove = allRooms.where((r) {
                  final id = r['id']?.toString() ?? r['roomId']?.toString() ?? '';
                  return idsToRemove.contains(id);
                }).toList();

                for (final room in roomsToRemove) {
                  unawaited(ref.read(wishlistProvider.notifier).toggle(room));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final authUser = ref.watch(authProvider).value;

    if (authUser == null) {
      return CupertinoPageScaffold(
        backgroundColor: isDark
            ? const Color(0xFF0F0F17)
            : const Color(0xFFF8FAFC),
        navigationBar: CupertinoNavigationBar(
          backgroundColor:
              (isDark ? const Color(0xFF1E293B) : Colors.white)
                  .withValues(alpha: 0.85),
          border: Border(
            bottom: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFF69B1FF).withValues(alpha: 0.15),
            ),
          ),
          leading: Navigator.canPop(context)
              ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFF69B1FF).withValues(alpha: 0.12),
                    ),
                    child: const Center(
                      child: Icon(
                        CupertinoIcons.back,
                        color: AppTheme.kTextPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                )
              : null,
          middle: const Text(
            'Phòng Đã Lưu',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.4,
            ),
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : const Color(0xFF69B1FF).withValues(alpha: 0.22),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF69B1FF)
                          .withValues(alpha: isDark ? 0.08 : 0.10),
                      blurRadius: 32,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xFFFF2D55).withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF2D55).withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          CupertinoIcons.heart_fill,
                          size: 42,
                          color: Color(0xFFFF2D55),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Đăng nhập để xem phòng đã lưu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Lưu các phòng ưng ý vào danh sách yêu thích và đồng bộ tự động trên tất cả thiết bị của bạn.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : const Color(0xFF64748B),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 28),
                    BounceClick(
                      onPressed: () {
                        unawaited(GuestAuthBottomSheet.show(context));
                      },
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF69B1FF), Color(0xFF3B82F6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF69B1FF).withValues(alpha: 0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Đăng nhập ngay',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final wishlistState = ref.watch(wishlistProvider);
    final available = wishlistState.available;
    final upcoming = wishlistState.upcoming;
    final rented = wishlistState.rented;
    final loading = wishlistState.loading;
    final total = available.length + upcoming.length + rented.length;
    final allCurrentList = _tabController.index == 0
        ? available
        : (_tabController.index == 1 ? upcoming : rented);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0E17)
          : const Color(0xFFF4F7FC),
      body: Stack(
        children: [
          // ── Ambient Lighting Mesh (Liquid Glass Canvas) ────────────
          _buildAmbientBackdrop(isDark),

          // ── Foreground Content ─────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // ── Liquid Glass Floating Header ─────────────────────
                _buildHeader(context, isDark, total),

                // ── Liquid Glass Segmented Pill Tab Bar (Tự động thu gọn khi xem Bản đồ) ──
                AnimatedCrossFade(
                  firstChild: _buildTabBar(
                    isDark,
                    available.length,
                    upcoming.length,
                    rented.length,
                  ),
                  secondChild: const SizedBox.shrink(),
                  crossFadeState: _isMapView
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 260),
                ),

                // ── Tab View Content OR Map View ─────────────────────
                Expanded(
                  child: loading && total == 0
                      ? _buildWishlistSkeleton(isDark)
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) => FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, 0.02),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          ),
                          child: _isMapView
                              ? KeyedSubtree(
                                  key: const ValueKey('wishlist_map_view'),
                                  child: _buildMapView(
                                    allCurrentList.isNotEmpty
                                        ? allCurrentList
                                        : (available.isNotEmpty
                                            ? available
                                            : [...available, ...upcoming, ...rented]),
                                    available,
                                    isDark,
                                  ),
                                )
                              : KeyedSubtree(
                                  key: const ValueKey('wishlist_list_view'),
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      _buildList(
                                        available,
                                        availableRooms: available,
                                        tabType: _WishlistTabType.available,
                                        isDark: isDark,
                                      ),
                                      _buildList(
                                        upcoming,
                                        availableRooms: available,
                                        tabType: _WishlistTabType.upcoming,
                                        isDark: isDark,
                                      ),
                                      _buildList(
                                        rented,
                                        availableRooms: available,
                                        tabType: _WishlistTabType.rented,
                                        isDark: isDark,
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                ),

                if (_isEditMode)
                  const SizedBox(height: 76),
              ],
            ),
          ),

          // ── Edit Mode Bottom Glass Bar ────────────────────────────
          if (_isEditMode && allCurrentList.isNotEmpty)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: _buildEditBottomBar(
                allCurrentList,
                available,
                upcoming,
                rented,
                isDark,
              ),
            ),
        ],
      ),
    );
  }

  // ─── Ambient Backdrop ───────────────────────────────────────────────────────

  Widget _buildAmbientBackdrop(bool isDark) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: isDark ? const Color(0xFF0A0E17) : const Color(0xFFF5F8FC),
          ),
        ),
        // Soft Sky-Blue Ambient Light (Top Right)
        Positioned(
          top: -40,
          right: -50,
          width: 320,
          height: 320,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF69B1FF).withValues(alpha: isDark ? 0.22 : 0.28),
                    const Color(0xFF69B1FF).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Soft Violet-Indigo Ambient Light (Mid Left)
        Positioned(
          top: 260,
          left: -80,
          width: 300,
          height: 300,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF818CF8).withValues(alpha: isDark ? 0.15 : 0.18),
                    const Color(0xFF818CF8).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        // Soft Cyan Ambient Light (Bottom Right)
        Positioned(
          bottom: 60,
          right: -60,
          width: 280,
          height: 280,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.12 : 0.16),
                    const Color(0xFF38BDF8).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Liquid Glass Header ────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, bool isDark, int total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Tiêu đề căn chính giữa màn hình với Glass Pill Badge tinh tế, thanh lịch
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Phòng Đã Lưu',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: -0.3,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                if (total > 0) ...[
                  const SizedBox(width: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7.5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF69B1FF).withValues(alpha: 0.18)
                          : const Color(0xFF69B1FF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF69B1FF).withValues(alpha: isDark ? 0.35 : 0.30),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF69B1FF).withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '$total',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1D4ED8),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Nút Quay lại bên trái
          if (Navigator.canPop(context))
            Positioned(
              left: 0,
              child: BounceClick(
                scaleFactor: 0.90,
                onPressed: () => Navigator.pop(context),
                child: AdaptiveGlass(
                  shape: const LiquidOval(),
                  settings: const LiquidGlassSettings(blur: 16),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.10)
                          : Colors.white.withValues(alpha: 0.75),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.85),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF69B1FF).withValues(alpha: 0.16),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        CupertinoIcons.chevron_back,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Nút Chuyển Bản đồ (neo cố định ngoài cùng bên phải) & Chế độ Sửa (bên trái)
          if (total > 0)
            Positioned(
              right: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nút So Sánh (Chạm vào để bật chế độ chọn 2-3 phòng so sánh đối đầu)
                  AnimatedOpacity(
                    opacity: _isMapView ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: _isMapView,
                      child: BounceClick(
                        scaleFactor: 0.92,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _isEditMode = true;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              duration: const Duration(seconds: 2),
                              content: const Row(
                                children: [
                                  Icon(
                                    Icons.compare_arrows_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Chọn 2 đến 3 phòng để so sánh đối đầu!'),
                                ],
                              ),
                            ),
                          );
                        },
                        child: AdaptiveGlass(
                          shape: const LiquidRoundedSuperellipse(borderRadius: 50),
                          settings: const LiquidGlassSettings(blur: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 7.5,
                            ),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.75),
                              border: Border.all(
                                color: const Color(0xFF69B1FF).withValues(alpha: 0.4),
                                width: 1.2,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.compare_arrows_rounded,
                                  size: 15,
                                  color: Color(0xFF2563EB),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'So sánh',
                                  style: TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Nút Sửa (nằm bên TRÁI nút chuyển đổi, có animation xuất hiện mượt mà khi ở chế độ danh sách)
                  AnimatedOpacity(
                    opacity: _isMapView ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: _isMapView,
                      child: BounceClick(
                        scaleFactor: 0.92,
                        onPressed: () {
                          setState(() {
                            _isEditMode = !_isEditMode;
                            if (!_isEditMode) _selectedRoomIds.clear();
                          });
                        },
                        child: AdaptiveGlass(
                          shape: const LiquidRoundedSuperellipse(borderRadius: 50),
                          settings: const LiquidGlassSettings(blur: 16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7.5,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: _isEditMode
                                  ? const Color(0xFF69B1FF).withValues(alpha: 0.22)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.white.withValues(alpha: 0.75)),
                              border: Border.all(
                                color: _isEditMode
                                    ? const Color(0xFF69B1FF)
                                    : Colors.white.withValues(alpha: isDark ? 0.18 : 0.85),
                                width: 1.2,
                              ),
                            ),
                            child: Text(
                              _isEditMode ? 'Xong' : 'Sửa',
                              style: TextStyle(
                                color: _isEditMode
                                    ? const Color(0xFF2563EB)
                                    : (isDark ? Colors.white : const Color(0xFF334155)),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Nút Chuyển đổi Bản đồ / Danh sách (CỐ ĐỊNH TỌA ĐỘ NGOÀI CÙNG BÊN PHẢI - 38x38 chuẩn đối xứng nút Back)
                  BounceClick(
                    scaleFactor: 0.90,
                    onPressed: () {
                      setState(() {
                        _isMapView = !_isMapView;
                        if (_isMapView) {
                          _isEditMode = false;
                          _selectedRoomIds.clear();
                        }
                      });
                    },
                    child: AdaptiveGlass(
                      shape: const LiquidOval(),
                      settings: const LiquidGlassSettings(blur: 16),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isMapView
                              ? const Color(0xFF2563EB).withValues(alpha: 0.15)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.white.withValues(alpha: 0.75)),
                          border: Border.all(
                            color: _isMapView
                                ? const Color(0xFF2563EB).withValues(alpha: 0.8)
                                : Colors.white.withValues(alpha: isDark ? 0.18 : 0.85),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF69B1FF).withValues(alpha: 0.16),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            transitionBuilder: (child, animation) => ScaleTransition(
                              scale: animation,
                              child: child,
                            ),
                            child: Icon(
                              _isMapView
                                  ? CupertinoIcons.list_bullet
                                  : CupertinoIcons.map_fill,
                              key: ValueKey(_isMapView),
                              color: _isMapView
                                  ? const Color(0xFF2563EB)
                                  : (isDark ? Colors.white : const Color(0xFF334155)),
                              size: 17,
                            ),
                          ),
                        ),
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

  // ─── Edit Mode Bottom Bar ───────────────────────────────────────────────────

  Widget _buildEditBottomBar(
    List<Map<String, dynamic>> allCurrentList,
    List<Map<String, dynamic>> available,
    List<Map<String, dynamic>> upcoming,
    List<Map<String, dynamic>> rented,
    bool isDark,
  ) {
    final allIds = allCurrentList
        .map(
          (r) =>
              (r['id']?.toString() ??
              r['roomId']?.toString() ??
              ''),
        )
        .where((id) => id.isNotEmpty)
        .toList();
    final allSelected =
        allIds.isNotEmpty && allIds.every(_selectedRoomIds.contains);

    return AdaptiveGlass(
      shape: const LiquidRoundedSuperellipse(borderRadius: 24),
      settings: const LiquidGlassSettings(blur: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withValues(alpha: 0.65)
              : Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: isDark ? 0.16 : 0.90),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF69B1FF).withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                setState(() {
                  if (allSelected) {
                    _selectedRoomIds.removeAll(allIds);
                  } else {
                    _selectedRoomIds.addAll(allIds);
                  }
                });
              },
              child: Text(
                allSelected ? 'Bỏ chọn tất cả' : 'Chọn tất cả',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_selectedRoomIds.length >= 2) ...[
                  BounceClick(
                    scaleFactor: 0.92,
                    onPressed: () => _compareSelected([
                      ...available,
                      ...upcoming,
                      ...rented,
                    ]),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF69B1FF), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF69B1FF).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.arrow_right_arrow_left,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'So sánh (${_selectedRoomIds.length})',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 9,
                  ),
                  color: const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(50),
                  onPressed: _selectedRoomIds.isEmpty
                      ? null
                      : () => _removeSelected([
                          ...available,
                          ...upcoming,
                          ...rented,
                        ]),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        CupertinoIcons.trash,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Xóa (${_selectedRoomIds.length})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  // ─── Tab Bar (Liquid Glass Segmented Pill - 3 Tabs) ─────────────────────

  Widget _buildTabBar(
    bool isDark,
    int availableCount,
    int upcomingCount,
    int rentedCount,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: AdaptiveGlass(
        shape: const LiquidRoundedSuperellipse(borderRadius: 50),
        settings: const LiquidGlassSettings(blur: 20),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.16 : 0.88),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF69B1FF).withValues(alpha: isDark ? 0.06 : 0.10),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            dividerColor: Colors.transparent,
            indicator: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF69B1FF), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            labelColor: Colors.white,
            unselectedLabelColor: isDark
                ? Colors.white.withValues(alpha: 0.65)
                : const Color(0xFF64748B),
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              letterSpacing: -0.2,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: -0.2,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              Tab(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.checkmark_seal_fill, size: 14),
                    const SizedBox(width: 4),
                    Text('Còn trống ($availableCount)'),
                  ],
                ),
              ),
              Tab(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.sparkles, size: 14),
                    const SizedBox(width: 4),
                    Text('Sắp trống ($upcomingCount)'),
                  ],
                ),
              ),
              Tab(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.lock_shield_fill, size: 14),
                    const SizedBox(width: 4),
                    Text('Đã thuê ($rentedCount)'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  // ─── Liquid Glass Shimmer Skeleton Loading ─────────────────────────────────
  Widget _buildWishlistSkeleton(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          child: AdaptiveGlass(
            shape: const LiquidRoundedSuperellipse(borderRadius: 26),
            settings: const LiquidGlassSettings(blur: 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.85),
                  width: 1.2,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Skeleton thumbnail
                  Container(
                    width: 94,
                    height: 94,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFFE2E8F0).withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(width: 13),
                  // Skeleton lines
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 130,
                          height: 14,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 90,
                          height: 18,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF69B1FF).withValues(alpha: 0.15)
                                : const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Quản lý Địa chỉ Cơ quan / Trường học (Tính năng 1) ───────────────────

  Future<void> _loadWorkplace() async {
    final prefs = await SharedPreferences.getInstance();
    final addr = prefs.getString('wishlist_work_address');
    final lat = prefs.getDouble('wishlist_work_lat');
    final lng = prefs.getDouble('wishlist_work_lng');
    if (addr != null && lat != null && lng != null && mounted) {
      setState(() {
        _workAddress = addr;
        _workCoord = LatLng(lat, lng);
      });
    }
  }

  Future<void> _saveWorkplace(String address, LatLng coord) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wishlist_work_address', address);
    await prefs.setDouble('wishlist_work_lat', coord.latitude);
    await prefs.setDouble('wishlist_work_lng', coord.longitude);
    if (mounted) {
      setState(() {
        _workAddress = address;
        _workCoord = coord;
      });
    }
  }

  Future<void> _clearWorkplace() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('wishlist_work_address');
    await prefs.remove('wishlist_work_lat');
    await prefs.remove('wishlist_work_lng');
    if (mounted) {
      setState(() {
        _workAddress = null;
        _workCoord = null;
      });
    }
  }

  double? _calculateDistanceToWork(Map<String, dynamic> room) {
    if (_workCoord == null) return null;
    final coord = _resolveRoomCoordinates(room);
    if (coord == null) return null;

    const p = 0.017453292519943295;
    final a = 0.5 -
        math.cos((coord.latitude - _workCoord!.latitude) * p) / 2 +
        math.cos(_workCoord!.latitude * p) *
            math.cos(coord.latitude * p) *
            (1 - math.cos((coord.longitude - _workCoord!.longitude) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a));
  }

  void _showSetWorkplaceDialog() {
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final controller = TextEditingController(text: _workAddress ?? '');
    bool isSearching = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: AdaptiveGlass(
              shape: const LiquidRoundedSuperellipse(borderRadius: 32),
              settings: const LiquidGlassSettings(blur: 24),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B).withValues(alpha: 0.95)
                      : Colors.white.withValues(alpha: 0.95),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.16 : 0.9),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF69B1FF).withValues(alpha: 0.15),
                          ),
                          child: const Icon(
                            CupertinoIcons.building_2_fill,
                            color: Color(0xFF2563EB),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ghim Nơi làm việc / Trường học',
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Đo khoảng cách chính xác & tính thời gian đi xe máy',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF69B1FF).withValues(alpha: 0.3),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Nhập địa chỉ, tên tòa nhà hoặc trường đại học...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          ),
                          border: InputBorder.none,
                          icon: const Icon(
                            CupertinoIcons.search,
                            size: 18,
                            color: Color(0xFF69B1FF),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Gợi ý nhanh:',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        'ĐH Bách Khoa TP.HCM',
                        'Tòa nhà Bitexco Q1',
                        'Landmark 81',
                        'Khu CNC Quận 9',
                      ].map((preset) {
                        return BounceClick(
                          scaleFactor: 0.94,
                          onPressed: () {
                            controller.text = preset;
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF69B1FF).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              preset,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        if (_workCoord != null) ...[
                          BounceClick(
                            onPressed: () async {
                              await _clearWorkplace();
                              if (ctx.mounted) Navigator.pop(ctx);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: const Icon(
                                CupertinoIcons.trash,
                                color: Color(0xFFEF4444),
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: BounceClick(
                            onPressed: isSearching
                                ? null
                                : () async {
                                    final text = controller.text.trim();
                                    if (text.isEmpty) return;
                                    setModalState(() => isSearching = true);
                                    try {
                                      final results = await OsmMapService().searchAddress(text, limit: 1);
                                      if (results.isNotEmpty) {
                                        await _saveWorkplace(text, results.first.latLng);
                                        if (ctx.mounted) {
                                          Navigator.pop(ctx);
                                          _mapController.move(results.first.latLng, 15.0);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Đã ghim: $text'),
                                              backgroundColor: const Color(0xFF10B981),
                                            ),
                                          );
                                        }
                                        return;
                                      }

                                      final dio = Dio();
                                      final res = await dio.get(
                                        'https://nominatim.openstreetmap.org/search',
                                        queryParameters: {
                                          'q': text,
                                          'format': 'json',
                                          'limit': 1,
                                          'countrycodes': 'vn',
                                        },
                                        options: Options(
                                          headers: {'User-Agent': 'StayHubApp/1.0 (stayhub.app)'},
                                        ),
                                      );
                                      if (res.data is List && (res.data as List).isNotEmpty) {
                                        final first = (res.data as List).first;
                                        final lat = double.tryParse(first['lat']?.toString() ?? '');
                                        final lon = double.tryParse(first['lon']?.toString() ?? '');
                                        if (lat != null && lon != null) {
                                          final pt = LatLng(lat, lon);
                                          await _saveWorkplace(text, pt);
                                          if (ctx.mounted) {
                                            Navigator.pop(ctx);
                                            _mapController.move(pt, 15.0);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Đã ghim: $text'),
                                                backgroundColor: const Color(0xFF10B981),
                                              ),
                                            );
                                          }
                                          return;
                                        }
                                      }

                                      if (ctx.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Không tìm thấy toạ độ cho địa chỉ này.'),
                                            backgroundColor: Color(0xFFEF4444),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (ctx.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Lỗi: $e')),
                                        );
                                      }
                                    } finally {
                                      if (ctx.mounted) setModalState(() => isSearching = false);
                                    }
                                  },
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF69B1FF), Color(0xFF2563EB)],
                                ),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Center(
                                child: isSearching
                                    ? const CupertinoActivityIndicator(color: Colors.white)
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(CupertinoIcons.pin_fill, color: Colors.white, size: 16),
                                          SizedBox(width: 8),
                                          Text(
                                            'Ghim Địa Điểm',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Ghi chú riêng tư & Đã xem thực tế (Tính năng 3) ───────────────────────

  void _showPrivateNoteDialog(Map<String, dynamic> room) {
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final roomId = (room['id'] ?? room['roomId'])?.toString() ?? '';
    final roomName = room['roomName'] ?? room['name'] ?? 'Phòng';
    final existingNote = room['privateNote']?.toString() ?? '';
    bool isVisited = room['isVisited'] == true;
    final controller = TextEditingController(text: existingNote);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: AdaptiveGlass(
              shape: const LiquidRoundedSuperellipse(borderRadius: 32),
              settings: const LiquidGlassSettings(blur: 24),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E293B).withValues(alpha: 0.95)
                      : Colors.white.withValues(alpha: 0.95),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: isDark ? 0.16 : 0.9),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          ),
                          child: const Icon(
                            CupertinoIcons.pencil_ellipsis_rectangle,
                            color: Color(0xFF10B981),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ghi chú phòng: $roomName',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Chỉ mình bạn xem được ghi chú này',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Switch: Đã đi xem phòng thực tế
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.06)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isVisited
                              ? const Color(0xFF10B981)
                              : Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isVisited
                                ? CupertinoIcons.checkmark_seal_fill
                                : CupertinoIcons.checkmark_seal,
                            color: isVisited ? const Color(0xFF10B981) : Colors.grey,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Đã đi xem thực tế',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  isVisited
                                      ? 'Đã khảo sát thực tế phòng này'
                                      : 'Đánh dấu khi bạn đã tới khảo sát phòng',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CupertinoSwitch(
                            value: isVisited,
                            activeTrackColor: const Color(0xFF10B981),
                            onChanged: (val) {
                              setModalState(() => isVisited = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // TextField ghi chú
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF69B1FF).withValues(alpha: 0.3),
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: controller,
                        maxLines: 3,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          hintText: 'VD: Phòng thoáng, chủ dễ tính, cọc 1 tháng, gửi xe 100k/th...',
                          hintStyle: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    BounceClick(
                      onPressed: () async {
                        final noteText = controller.text.trim();
                        room['privateNote'] = noteText;
                        room['isVisited'] = isVisited;
                        await ref.read(wishlistProvider.notifier).updateNoteAndVisited(
                          roomId,
                          note: noteText,
                          isVisited: isVisited,
                        );
                        if (mounted) setState(() {});
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đã cập nhật ghi chú & trạng thái phòng!'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        }
                      },
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Center(
                          child: Text(
                            'Lưu Ghi Chú',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Tour xem phòng trong ngày (Tính năng 2) ───────────────────────────────

  void _showTourRouteModal(List<Map<String, dynamic>> rooms) {
    final isDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;

    // Lọc các phòng có toạ độ hợp lệ
    final validRooms = rooms.where((r) => _resolveRoomCoordinates(r) != null).toList();

    if (validRooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Các phòng hiện tại chưa có toạ độ để tạo lộ trình.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    // Sắp xếp thứ tự phòng tối ưu (Nearest Neighbor Algorithm)
    final origin = _workCoord ??
        (ref.read(locationProvider).latitude != null
            ? LatLng(ref.read(locationProvider).latitude!, ref.read(locationProvider).longitude!)
            : const LatLng(_defaultCenterLat, _defaultCenterLng));

    final sortedRooms = <Map<String, dynamic>>[];
    final remaining = List<Map<String, dynamic>>.from(validRooms);
    LatLng currentPoint = origin;

    while (remaining.isNotEmpty) {
      remaining.sort((a, b) {
        final cA = _resolveRoomCoordinates(a)!;
        final cB = _resolveRoomCoordinates(b)!;
        final distA = OsmMapService.calculateDistance(
          currentPoint.latitude,
          currentPoint.longitude,
          cA.latitude,
          cA.longitude,
        );
        final distB = OsmMapService.calculateDistance(
          currentPoint.latitude,
          currentPoint.longitude,
          cB.latitude,
          cB.longitude,
        );
        return distA.compareTo(distB);
      });
      final nextRoom = remaining.removeAt(0);
      sortedRooms.add(nextRoom);
      currentPoint = _resolveRoomCoordinates(nextRoom)!;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, sc) {
          return AdaptiveGlass(
            shape: const LiquidRoundedSuperellipse(borderRadius: 32),
            settings: const LiquidGlassSettings(blur: 24),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.95)
                    : Colors.white.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.16 : 0.9),
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF69B1FF).withValues(alpha: 0.15),
                          ),
                          child: const Icon(
                            CupertinoIcons.map_fill,
                            color: Color(0xFF2563EB),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lộ trình xem ${sortedRooms.length} phòng trong ngày',
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _workAddress != null
                                    ? 'Khởi hành từ: $_workAddress'
                                    : 'Khởi hành từ vị trí của bạn',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Nút Chia sẻ Lộ trình
                        BounceClick(
                          scaleFactor: 0.90,
                          onPressed: () {
                            final buffer = StringBuffer();
                            buffer.writeln('🏠 LỘ TRÌNH XEM PHÒNG TRỌ STAYHUB');
                            if (_workAddress != null) {
                              buffer.writeln('📍 Khởi hành: $_workAddress');
                            } else {
                              buffer.writeln('📍 Khởi hành: Vị trí hiện tại');
                            }
                            buffer.writeln('📋 Danh sách: ${sortedRooms.length} phòng cần đi xem hôm nay:\n');

                            for (int i = 0; i < sortedRooms.length; i++) {
                              final r = sortedRooms[i];
                              final c = _resolveRoomCoordinates(r)!;
                              final name = r['roomName'] ?? r['name'] ?? 'Phòng';
                              final addr = r['address'] ?? 'Đang cập nhật địa chỉ';
                              final price = double.tryParse(r['price']?.toString() ?? '') ?? 0;
                              final pStr = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price);
                              final note = (r['privateNote']?.toString() ?? '').trim();

                              buffer.writeln('👉 Chặng #${i + 1}: $name ($pStr/tháng)');
                              buffer.writeln('   • Địa chỉ: $addr');
                              if (note.isNotEmpty) buffer.writeln('   • Ghi chú: $note');
                              buffer.writeln('   • Bản đồ: https://maps.google.com/?q=${c.latitude},${c.longitude}');
                              buffer.writeln();
                            }
                            buffer.writeln('✨ Tạo tự động từ StayHub');

                            Clipboard.setData(ClipboardData(text: buffer.toString()));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã sao chép lộ trình vào bộ nhớ tạm! Bạn có thể dán vào Zalo để gửi bạn bè.'),
                                backgroundColor: Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                color: const Color(0xFF10B981).withValues(alpha: 0.5),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(CupertinoIcons.share, color: Color(0xFF10B981), size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Chia sẻ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      controller: sc,
                      padding: const EdgeInsets.all(16),
                      itemCount: sortedRooms.length,
                      separatorBuilder: (_, idx) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 24),
                        child: Row(
                          children: [
                            Container(
                              width: 2,
                              height: 22,
                              color: const Color(0xFF69B1FF).withValues(alpha: 0.5),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Chặng tiếp theo (~5-10 ph xe máy)',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      itemBuilder: (context, idx) {
                        final r = sortedRooms[idx];
                        final c = _resolveRoomCoordinates(r)!;
                        final rName = r['roomName'] ?? r['name'] ?? 'Phòng';
                        final rAddress = r['address'] ?? 'Địa chỉ đang cập nhật';
                        final isVisited = r['isVisited'] == true;
                        final pPrice = double.tryParse(r['price']?.toString() ?? '') ?? 0;
                        final priceStr = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(pPrice);

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isVisited
                                  ? const Color(0xFF10B981).withValues(alpha: 0.4)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Điểm thứ tự
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: isVisited
                                        ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                        : [const Color(0xFF69B1FF), const Color(0xFF2563EB)],
                                  ),
                                ),
                                child: Center(
                                  child: isVisited
                                      ? const Icon(CupertinoIcons.checkmark, color: Colors.white, size: 16)
                                      : Text(
                                          '#${idx + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      rName.toString(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      rAddress.toString(),
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      priceStr,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Nút chỉ đường Google Maps
                              BounceClick(
                                scaleFactor: 0.90,
                                onPressed: () async {
                                  final uri = Uri.parse(
                                    'https://www.google.com/maps/dir/?api=1&destination=${c.latitude},${c.longitude}&travelmode=two_wheeler',
                                  );
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                                  } else {
                                    await launchUrl(uri);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(50),
                                    border: Border.all(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(CupertinoIcons.location_north_fill, color: Color(0xFF2563EB), size: 12),
                                      SizedBox(width: 4),
                                      Text(
                                        'Chỉ đường',
                                        style: TextStyle(
                                          color: Color(0xFF2563EB),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  // ─── Liquid Glass Map View ─────────────────────────────────────────────────

  Widget _buildMapView(
    List<Map<String, dynamic>> rawRooms,
    List<Map<String, dynamic>> availableRooms,
    bool isDark,
  ) {
    final filtered = rawRooms;
    final validMarkers = <Marker>[];
    final resolvedCoords = <LatLng>[];

    // Thêm Marker Chỗ làm việc / Trường học nếu người dùng đã ghim
    if (_workCoord != null) {
      validMarkers.add(
        Marker(
          point: _workCoord!,
          width: 130,
          height: 46,
          child: GestureDetector(
            onTap: _showSetWorkplaceDialog,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AdaptiveGlass(
                  shape: const LiquidRoundedSuperellipse(borderRadius: 20),
                  settings: const LiquidGlassSettings(blur: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF69B1FF), Color(0xFF1D4ED8)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.building_2_fill,
                          color: Colors.white,
                          size: 11,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _workAddress != null && _workAddress!.length > 10
                              ? '${_workAddress!.substring(0, 10)}...'
                              : (_workAddress ?? 'Chỗ làm'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Icon(
                  CupertinoIcons.arrowtriangle_down_fill,
                  color: Color(0xFF1D4ED8),
                  size: 10,
                ),
              ],
            ),
          ),
        ),
      );
    }

    for (int i = 0; i < filtered.length; i++) {
      final r = filtered[i];
      final rId = (r['id'] ?? r['roomId'] ?? i.toString()).toString();
      final isSelected = _selectedMapRoomId == rId;

      LatLng? coord = _resolveRoomCoordinates(r);
      // Fallback vị trí tương đối xung quanh tâm nếu phòng chưa có toạ độ thực tế
      if (coord == null) {
        final offsetLat = ((i % 5) - 2) * 0.007;
        final offsetLng = (((i ~/ 5) % 5) - 2) * 0.007;
        coord = LatLng(_defaultCenterLat + offsetLat, _defaultCenterLng + offsetLng);
      }

      resolvedCoords.add(coord);

      final priceNum = double.tryParse(r['price']?.toString() ?? '') ?? 0;
      final priceLabel = priceNum >= 1000000
          ? '${(priceNum / 1000000).toStringAsFixed(1)}Tr'
          : '${(priceNum / 1000).toStringAsFixed(0)}k';

      final rStatus = (r['status'] ?? '').toString().toUpperCase();
      final isAvailableRoom = rStatus == 'AVAILABLE' ||
          availableRooms.any((a) => (a['id'] ?? a['roomId']).toString() == rId);
      final isUpcomingRoom = rStatus == 'UPCOMING' || r['availableFrom'] != null;

      final markerColor = isSelected
          ? const Color(0xFF2563EB)
          : (isAvailableRoom
              ? const Color(0xFF10B981)
              : (isUpcomingRoom ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)));

      validMarkers.add(
        Marker(
          point: coord,
          width: isSelected ? 104 : 90,
          height: isSelected ? 50 : 44,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedMapRoomId = rId;
              });
              _mapController.move(coord!, 16.0);
              if (_mapCardScrollController.hasClients) {
                final targetScroll = (i * (295.0 + 12.0)).clamp(
                  0.0,
                  _mapCardScrollController.position.maxScrollExtent,
                );
                _mapCardScrollController.animateTo(
                  targetScroll,
                  duration: const Duration(milliseconds: 360),
                  curve: Curves.easeOutCubic,
                );
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AdaptiveGlass(
                  shape: const LiquidRoundedSuperellipse(borderRadius: 20),
                  settings: const LiquidGlassSettings(blur: 16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: isSelected ? 10 : 8,
                      vertical: isSelected ? 5 : 4,
                    ),
                    decoration: BoxDecoration(
                      color: markerColor.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white,
                        width: isSelected ? 2.2 : 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: markerColor.withValues(alpha: isSelected ? 0.65 : 0.45),
                          blurRadius: isSelected ? 14 : 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.house_fill,
                          color: Colors.white,
                          size: isSelected ? 13 : 11,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          priceLabel,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSelected ? 12 : 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Icon(
                  CupertinoIcons.arrowtriangle_down_fill,
                  color: markerColor,
                  size: isSelected ? 12 : 10,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final initialCenter = _workCoord ??
        (resolvedCoords.isNotEmpty
            ? resolvedCoords.first
            : const LatLng(_defaultCenterLat, _defaultCenterLng));

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: resolvedCoords.isNotEmpty ? 15.0 : 13.5,
          ),
          children: [
            TileLayer(
              urlTemplate: OsmMapService.tileUrl,
              subdomains: OsmMapService.tileSubdomains,
              userAgentPackageName: 'com.stayhub.app',
              maxZoom: 19,
            ),
            // Vòng tròn bán kính tiện lợi 3km từ chỗ làm
            if (_showWorkRadius && _workCoord != null)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _workCoord!,
                    radius: 3000,
                    useRadiusInMeter: true,
                    color: const Color(0xFF69B1FF).withValues(alpha: 0.14),
                    borderColor: const Color(0xFF2563EB).withValues(alpha: 0.65),
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),
            MarkerLayer(markers: validMarkers),
          ],
        ),

        // Floating Top Controls: Counter + Ghim Chỗ Làm + Tour + Recenter & Banner nhắc nhở
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  // Badge đếm phòng
                  AdaptiveGlass(
                    shape: const LiquidRoundedSuperellipse(borderRadius: 50),
                    settings: const LiquidGlassSettings(blur: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.65)
                            : Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: isDark ? 0.16 : 0.9),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF69B1FF).withValues(alpha: 0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.map_pin_ellipse,
                            color: Color(0xFF2563EB),
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${validMarkers.length} điểm',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Nút Ghim Cơ Quan / Trường Học
                  BounceClick(
                    scaleFactor: 0.90,
                    onPressed: _showSetWorkplaceDialog,
                    child: AdaptiveGlass(
                      shape: const LiquidRoundedSuperellipse(borderRadius: 50),
                      settings: const LiquidGlassSettings(blur: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: _workCoord != null
                              ? const Color(0xFF2563EB).withValues(alpha: 0.9)
                              : (isDark ? Colors.black.withValues(alpha: 0.65) : Colors.white.withValues(alpha: 0.85)),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.9),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.building_2_fill,
                              color: _workCoord != null ? Colors.white : const Color(0xFF2563EB),
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _workCoord != null ? 'Chỗ làm' : 'Ghim cty',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: _workCoord != null ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Nút Lộ trình Tour Xem Phòng
                  BounceClick(
                    scaleFactor: 0.90,
                    onPressed: () => _showTourRouteModal(filtered),
                    child: AdaptiveGlass(
                      shape: const LiquidRoundedSuperellipse(borderRadius: 50),
                      settings: const LiquidGlassSettings(blur: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF69B1FF), Color(0xFF2563EB)],
                          ),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: Colors.white, width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(CupertinoIcons.map_fill, color: Colors.white, size: 13),
                            SizedBox(width: 4),
                            Text(
                              'Tour xem',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Re-center floating button
                  BounceClick(
                    scaleFactor: 0.90,
                    onPressed: () {
                      if (_workCoord != null) {
                        _mapController.move(_workCoord!, 15.0);
                      } else if (resolvedCoords.isNotEmpty) {
                        _mapController.move(resolvedCoords.first, 15.5);
                      } else {
                        final userLoc = ref.read(locationProvider);
                        final lat = userLoc.latitude ?? _defaultCenterLat;
                        final lng = userLoc.longitude ?? _defaultCenterLng;
                        _mapController.move(LatLng(lat, lng), 14.0);
                      }
                    },
                    child: AdaptiveGlass(
                      shape: const LiquidOval(),
                      settings: const LiquidGlassSettings(blur: 16),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.65)
                              : Colors.white.withValues(alpha: 0.85),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: isDark ? 0.16 : 0.9),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            CupertinoIcons.location_fill,
                            color: Color(0xFF2563EB),
                            size: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_workCoord == null && !_dismissWorkplaceBanner) ...[
                const SizedBox(height: 10),
                AdaptiveGlass(
                  shape: const LiquidRoundedSuperellipse(borderRadius: 18),
                  settings: const LiquidGlassSettings(blur: 20),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B).withValues(alpha: 0.92)
                          : Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFF69B1FF).withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF69B1FF).withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF69B1FF).withValues(alpha: 0.15),
                          ),
                          child: const Icon(
                            CupertinoIcons.building_2_fill,
                            color: Color(0xFF2563EB),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bạn chưa ghim chỗ làm / trường học',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                'Ghim để xem bán kính 3km & đo phút xe máy',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        BounceClick(
                          scaleFactor: 0.92,
                          onPressed: _showSetWorkplaceDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF69B1FF), Color(0xFF2563EB)],
                              ),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Text(
                              'Ghim ngay',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(28, 28),
                          onPressed: () {
                            setState(() {
                              _dismissWorkplaceBanner = true;
                            });
                          },
                          child: Icon(
                            CupertinoIcons.xmark,
                            size: 14,
                            color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // Bottom horizontal room cards preview + Quick POI Radar
        if (filtered.isNotEmpty)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            height: 154,
            child: ListView.separated(
              controller: _mapCardScrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, idx) {
                final r = filtered[idx];
                final rId = (r['id'] ?? r['roomId'] ?? idx.toString()).toString();
                final isSelected = _selectedMapRoomId == rId;
                final rTitle = _resolveRoomTitle(r);
                final rImgUrl = _resolveRoomImage(r);
                final rPrice = double.tryParse(r['price']?.toString() ?? '') ?? 0;
                final rPriceFormatted =
                    NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
                        .format(rPrice);
                final rDist = _calculateDistance(r);
                final rDistWork = _calculateDistanceToWork(r);
                final isVisited = r['isVisited'] == true;
                final hasNote = (r['privateNote']?.toString() ?? '').isNotEmpty;

                return BounceClick(
                  scaleFactor: 0.95,
                  onPressed: () {
                    setState(() {
                      _selectedMapRoomId = rId;
                    });
                    final coord = _resolveRoomCoordinates(r);
                    if (coord != null) {
                      _mapController.move(coord, 16.0);
                    }

                    unawaited(
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => DraggableScrollableSheet(
                          initialChildSize: 1.0,
                          minChildSize: 0.0,
                          maxChildSize: 1.0,
                          snap: true,
                          builder: (_, sc) => GuestRoomDetailPremiumBottomSheet(
                            room: r,
                            scrollController: sc,
                          ),
                        ),
                      ),
                    );
                  },
                  child: AdaptiveGlass(
                    shape: const LiquidRoundedSuperellipse(borderRadius: 22),
                    settings: const LiquidGlassSettings(blur: 20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 295,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B).withValues(alpha: isSelected ? 0.96 : 0.88)
                            : Colors.white.withValues(alpha: isSelected ? 0.98 : 0.95),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : (isVisited
                                  ? const Color(0xFF10B981).withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: isDark ? 0.16 : 0.9)),
                          width: isSelected ? 2.0 : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? const Color(0xFF2563EB).withValues(alpha: 0.28)
                                : const Color(0xFF69B1FF).withValues(alpha: 0.15),
                            blurRadius: isSelected ? 22 : 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  child: rImgUrl.isNotEmpty
                                      ? SafeNetworkImage(
                                          url: rImgUrl,
                                          width: 48,
                                          height: 48,
                                          fit: BoxFit.cover,
                                          errorWidget: const Center(
                                            child: Icon(
                                              CupertinoIcons.house_fill,
                                              color: Color(0xFF69B1FF),
                                              size: 20,
                                            ),
                                          ),
                                        )
                                      : const Center(
                                          child: Icon(
                                            CupertinoIcons.house_fill,
                                            color: Color(0xFF69B1FF),
                                            size: 20,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      rTitle,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        height: 1.25,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      rPriceFormatted,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Nút đánh dấu đã xem & ghi chú nhanh
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  BounceClick(
                                    scaleFactor: 0.85,
                                    onPressed: () => _toggleVisited(r),
                                    child: Container(
                                      padding: const EdgeInsets.all(5.5),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isVisited
                                            ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                            : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                                      ),
                                      child: Icon(
                                        isVisited
                                            ? CupertinoIcons.checkmark_seal_fill
                                            : CupertinoIcons.checkmark_seal,
                                        size: 15,
                                        color: isVisited ? const Color(0xFF10B981) : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  BounceClick(
                                    scaleFactor: 0.85,
                                    onPressed: () => _showPrivateNoteDialog(r),
                                    child: Container(
                                      padding: const EdgeInsets.all(5.5),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: hasNote
                                            ? const Color(0xFF0284C7).withValues(alpha: 0.15)
                                            : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                                      ),
                                      child: Icon(
                                        hasNote
                                            ? CupertinoIcons.pencil_ellipsis_rectangle
                                            : CupertinoIcons.square_pencil,
                                        size: 15,
                                        color: hasNote ? const Color(0xFF0284C7) : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Khoảng cách tới Chỗ làm / GPS
                          Row(
                            children: [
                              if (rDistWork != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(CupertinoIcons.building_2_fill, size: 10, color: Color(0xFF2563EB)),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Cty: ${rDistWork.toStringAsFixed(1)}km (~${(rDistWork * 2.5).round()}ph)',
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ] else if (rDist != null) ...[
                                Text(
                                  '${rDist.toStringAsFixed(1)} km (~${(rDist * 2.5).round()} ph)',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (isVisited)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    '✓ Đã xem',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const Spacer(),
                          // Hàng dưới: Quick POI Radar Chips & Nút Chỉ đường
                          Row(
                            children: [
                              _buildMiniPoiChip('🛒 Siêu thị', isDark),
                              const SizedBox(width: 4),
                              _buildMiniPoiChip('🚌 Bus', isDark),
                              const Spacer(),
                              BounceClick(
                                scaleFactor: 0.90,
                                onPressed: () async {
                                  final coord = _resolveRoomCoordinates(r);
                                  if (coord != null) {
                                    final uri = Uri.parse(
                                      'https://www.google.com/maps/dir/?api=1&destination=${coord.latitude},${coord.longitude}&travelmode=two_wheeler',
                                    );
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                                    } else {
                                      await launchUrl(uri);
                                    }
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(50),
                                    border: Border.all(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                                      width: 0.9,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        CupertinoIcons.location_north_fill,
                                        size: 10,
                                        color: Color(0xFF2563EB),
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        'Chỉ đường',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF2563EB),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildMiniPoiChip(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          color: isDark ? Colors.white54 : const Color(0xFF64748B),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }



  // ─── List ────────────────────────────────────────────────────────────────────


  Widget _buildLiquidGlassRefreshIndicator(
    BuildContext context,
    RefreshIndicatorMode refreshState,
    double pulledExtent,
    double refreshTriggerPullDistance,
    double refreshIndicatorExtent,
    bool isDark,
  ) {
    final double percentage =
        (pulledExtent / refreshTriggerPullDistance).clamp(0.0, 1.0);

    // Haptic feedback khi kéo vừa tới ngưỡng kích hoạt
    if (percentage >= 1.0 && !_hasTriggeredRefreshHaptic) {
      _hasTriggeredRefreshHaptic = true;
      HapticFeedback.mediumImpact();
    } else if (percentage < 0.2) {
      _hasTriggeredRefreshHaptic = false;
    }

    final bool isRefreshing = refreshState == RefreshIndicatorMode.refresh ||
        refreshState == RefreshIndicatorMode.armed;

    if (pulledExtent <= 0 && !isRefreshing) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Opacity(
          opacity: isRefreshing ? 1.0 : (percentage * 1.2).clamp(0.0, 1.0),
          child: Transform.scale(
            scale: isRefreshing ? 1.0 : (0.70 + percentage * 0.30).clamp(0.70, 1.0),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.88)
                    : Colors.white.withValues(alpha: 0.92),
                border: Border.all(
                  color: percentage >= 1.0 || isRefreshing
                      ? const Color(0xFF69B1FF)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.22)
                          : const Color(0xFFE2E8F0)),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF69B1FF).withValues(
                      alpha: isRefreshing ? 0.32 : (percentage * 0.20),
                    ),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: isRefreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CupertinoActivityIndicator(
                          radius: 8.5,
                          color: Color(0xFF2563EB),
                        ),
                      )
                    : SizedBox(
                        width: 18,
                        height: 18,
                        child: CupertinoActivityIndicator.partiallyRevealed(
                          radius: 8.5,
                          progress: percentage,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(
    List<Map<String, dynamic>> rawRooms, {
    required List<Map<String, dynamic>> availableRooms,
    required _WishlistTabType tabType,
    required bool isDark,
  }) {
    final rooms = rawRooms;
    if (rooms.isEmpty) {
      return CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(
            refreshTriggerPullDistance: 90.0,
            refreshIndicatorExtent: 55.0,
            onRefresh: () async {
              HapticFeedback.lightImpact();
              await ref.read(wishlistProvider.notifier).load();
              HapticFeedback.selectionClick();
            },
            builder: (context, refreshState, pulledExtent, refreshTriggerPullDistance, refreshIndicatorExtent) =>
                _buildLiquidGlassRefreshIndicator(
                  context,
                  refreshState,
                  pulledExtent,
                  refreshTriggerPullDistance,
                  refreshIndicatorExtent,
                  isDark,
                ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmpty(tabType: tabType, isDark: isDark),
          ),
        ],
      );
    }
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(
          refreshTriggerPullDistance: 90.0,
          refreshIndicatorExtent: 55.0,
          onRefresh: () async {
            HapticFeedback.lightImpact();
            await ref.read(wishlistProvider.notifier).load();
            HapticFeedback.selectionClick();
          },
          builder: (context, refreshState, pulledExtent, refreshTriggerPullDistance, refreshIndicatorExtent) =>
              _buildLiquidGlassRefreshIndicator(
                context,
                refreshState,
                pulledExtent,
                refreshTriggerPullDistance,
                refreshIndicatorExtent,
                isDark,
              ),
        ),

          // ── Cards ───────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            sliver: AnimationLimiter(
              child: SliverList(
                delegate: SliverChildBuilderDelegate((ctx, i) {
                  if (i >= rooms.length) return null;
                  final room = rooms[i];
                  final roomId =
                      room['id']?.toString() ??
                      room['roomId']?.toString() ??
                      '';
                  final isSelected = _selectedRoomIds.contains(roomId);

                  Widget cardWidget = _WishlistCard(
                    room: room,
                    tabType: tabType,
                    isDark: isDark,
                    isEditMode: _isEditMode,
                    isSelected: isSelected,
                    isNotified: _notifiedRoomIds.contains(roomId),
                    distanceKm: _calculateDistance(room),
                    onToggleNotify: () => _toggleNotifyRoom(room),
                    onToggleVisited: () => _toggleVisited(room),
                    onShare: () => _shareRoom(room),
                    onEditNote: () => _showPrivateNoteDialog(room),
                    onFindAlternatives: tabType == _WishlistTabType.rented
                        ? () => _showAlternativeRoomsModal(
                              context,
                              room,
                              availableRooms,
                            )
                        : null,
                    onSelectChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedRoomIds.add(roomId);
                        } else {
                          _selectedRoomIds.remove(roomId);
                        }
                      });
                    },
                    onRemove: () => _remove(room),
                    onTap: () {
                      if (_isEditMode) {
                        setState(() {
                          if (isSelected) {
                            _selectedRoomIds.remove(roomId);
                          } else {
                            _selectedRoomIds.add(roomId);
                          }
                        });
                        return;
                      }
                      unawaited(
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          barrierColor: Colors.black.withValues(alpha: 0.5),
                          enableDrag: false,
                          builder: (context) {
                            return DraggableScrollableSheet(
                              initialChildSize: 1.0,
                              minChildSize: 0.0,
                              maxChildSize: 1.0,
                              snap: true,
                              snapSizes: const [1.0],
                              builder: (context, scrollController) {
                                return GuestRoomDetailPremiumBottomSheet(
                                  room: room,
                                  scrollController: scrollController,
                                );
                              },
                            );
                          },
                        ),
                      );
                    },
                  );

                  // Chỉ cho phép swipe-to-dismiss khi không ở chế độ chọn nhiều
                  if (!_isEditMode) {
                    cardWidget = Dismissible(
                      key: Key('wishlist_dismiss_$roomId'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemRed,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.trash,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Xóa',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      onDismissed: (direction) {
                        unawaited(_remove(room));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Đã bỏ lưu phòng ${room['roomName'] ?? room['name'] ?? ''}',
                            ),
                            duration: const Duration(seconds: 2),
                            action: SnackBarAction(
                              label: 'Hoàn tác',
                              onPressed: () {
                                unawaited(
                                  ref
                                      .read(wishlistProvider.notifier)
                                      .toggle(room),
                                );
                              },
                            ),
                          ),
                        );
                      },
                      child: cardWidget,
                    );
                  }

                  return AnimationConfiguration.staggeredList(
                    position: i,
                    duration: const Duration(milliseconds: 350),
                    child: SlideAnimation(
                      verticalOffset: 40,
                      child: FadeInAnimation(child: cardWidget),
                    ),
                  );
                }, childCount: rooms.length),
              ),
            ),
          ),
        ],
      );
  }

  // ─── Empty State ─────────────────────────────────────────────────────────────

  Widget _buildEmpty({
    required _WishlistTabType tabType,
    required bool isDark,
  }) {
    final String title;
    final String subtitle;
    final IconData icon;
    final List<Color> colors;
    final Color iconColor;

    switch (tabType) {
      case _WishlistTabType.available:
        title = 'Không có phòng nào đang trống';
        subtitle = 'Nhấn ❤️ trên phòng bất kỳ để lưu lại';
        icon = CupertinoIcons.heart_slash_fill;
        colors = [
          AppTheme.kBrand.withValues(alpha: 0.12),
          AppTheme.kBrandDeep.withValues(alpha: 0.08),
        ];
        iconColor = AppTheme.kBrand;
        break;
      case _WishlistTabType.upcoming:
        title = 'Chưa có phòng nào sắp trống';
        subtitle = 'Khi các phòng bạn lưu sắp hết hạn hợp đồng, chúng sẽ xuất hiện ở đây';
        icon = CupertinoIcons.sparkles;
        colors = [
          const Color(0xFFF59E0B).withValues(alpha: 0.14),
          const Color(0xFFFBBF24).withValues(alpha: 0.08),
        ];
        iconColor = const Color(0xFFD97706);
        break;
      case _WishlistTabType.rented:
        title = 'Không có phòng nào đang cho thuê';
        subtitle = 'Các phòng đã có người ở trong danh sách của bạn sẽ hiện ở đây';
        icon = CupertinoIcons.lock_open_fill;
        colors = [
          const Color(0xFFFF6B6B).withValues(alpha: 0.10),
          const Color(0xFFFF8E53).withValues(alpha: 0.07),
        ];
        iconColor = const Color(0xFFFF6B6B);
        break;
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: colors),
              borderRadius: BorderRadius.circular(44),
            ),
            child: Icon(
              icon,
              size: 40,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.45)
                    : Colors.black.withValues(alpha: 0.45),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (tabType == _WishlistTabType.available) ...[
            const SizedBox(height: 24),
            BounceClick(
              onPressed: () {
                try {
                  context.push('/guest-search');
                } catch (_) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GuestMainScaffold(initialTab: 1),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF69B1FF), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF69B1FF).withValues(alpha: 0.38),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Khám phá phòng ngay',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      CupertinoIcons.arrow_right,
                      size: 15,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Dialogs ─────────────────────────────────────────────────────────────────

  // ignore: unused_element
  void _showClearDialog() {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: const Text('Xóa tất cả?'),
          content: const Text(
            'Tất cả phòng đã lưu sẽ bị xóa khỏi danh sách yêu thích.',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Hủy'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Xóa hết'),
              onPressed: () async {
                await ref.read(wishlistProvider.notifier).clear();
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card Widget ─────────────────────────────────────────────────────────────

class _WishlistCard extends StatelessWidget {
  final Map<String, dynamic> room;
  final _WishlistTabType tabType;
  final bool isDark;
  final bool isEditMode;
  final bool isSelected;
  final bool isNotified;
  final double? distanceKm;
  final ValueChanged<bool?> onSelectChanged;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback? onToggleNotify;
  final VoidCallback? onToggleVisited;
  final VoidCallback? onShare;
  final VoidCallback? onFindAlternatives;
  final VoidCallback? onEditNote;

  const _WishlistCard({
    required this.room,
    required this.tabType,
    required this.isDark,
    this.isEditMode = false,
    this.isSelected = false,
    this.isNotified = false,
    this.distanceKm,
    required this.onSelectChanged,
    required this.onTap,
    required this.onRemove,
    this.onToggleNotify,
    this.onToggleVisited,
    this.onShare,
    this.onFindAlternatives,
    this.onEditNote,
  });

  String _img() => _WishlistScreenState._resolveRoomImage(room);

  String _title() {
    final title = room['title'] ?? room['postTitle'];
    if (title != null && title.toString().trim().isNotEmpty) {
      return title.toString().trim();
    }
    final branchName = room['branchName'];
    final rName = (room['roomName'] ?? room['name'] ?? 'Phòng').toString().trim();
    final formattedRoom = rName.startsWith('Phòng') ? rName : 'Phòng $rName';
    if (branchName != null && branchName.toString().trim().isNotEmpty) {
      return '$branchName - $formattedRoom';
    }
    return formattedRoom;
  }

  double _price() {
    final p = room['price'];
    if (p == null) return 0;
    if (p is num) return p.toDouble();
    return double.tryParse(p.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final imgUrl = _img();
    final price = _price();
    final name = _title();
    final address = room['address'] ?? 'Chưa cập nhật địa chỉ';
    final availableFrom = room['availableFrom'] != null
        ? _formatDate(room['availableFrom'].toString())
        : null;
    final savedAt = room['savedAt'] != null
        ? _formatDate(room['savedAt'].toString())
        : null;

    final isAvailable = tabType == _WishlistTabType.available;
    final isUpcoming = tabType == _WishlistTabType.upcoming;

    final Color badgeColor;
    final Color badgeTextColor;
    final String badgeLabel;
    final IconData badgeIcon;

    if (isAvailable) {
      badgeColor = const Color(0xFF10B981);
      badgeTextColor = Colors.white;
      badgeLabel = 'Còn trống';
      badgeIcon = CupertinoIcons.checkmark_alt;
    } else if (isUpcoming) {
      badgeColor = const Color(0xFFF59E0B);
      badgeTextColor = Colors.white;
      badgeLabel = 'Sắp trống';
      badgeIcon = CupertinoIcons.sparkles;
    } else {
      badgeColor = const Color(0xFFEF4444);
      badgeTextColor = Colors.white;
      badgeLabel = 'Đã thuê';
      badgeIcon = CupertinoIcons.lock_fill;
    }

    return BounceClick(
      scaleFactor: 0.98,
      onPressed: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        child: AdaptiveGlass(
          shape: const LiquidRoundedSuperellipse(borderRadius: 26),
          settings: const LiquidGlassSettings(blur: 20),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.60)
                  : Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.90),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF69B1FF).withValues(alpha: isDark ? 0.08 : 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isEditMode) ...[
                    GestureDetector(
                      onTap: () => onSelectChanged(!isSelected),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12, top: 36),
                        child: Icon(
                          isSelected
                              ? CupertinoIcons.checkmark_circle_fill
                              : CupertinoIcons.circle,
                          color: isSelected
                              ? const Color(0xFF69B1FF)
                              : AppTheme.kTextMuted.withValues(alpha: 0.35),
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                  // ── Thumbnail (18px Rounded + Liquid Glass status badge) ───
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      const Color(0xFF1E293B),
                                      const Color(0xFF0F172A),
                                    ]
                                  : [
                                      const Color(0xFFE0F2FE),
                                      const Color(0xFFBAE6FD),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: imgUrl.isNotEmpty
                              ? SafeNetworkImage(
                                  url: imgUrl,
                                  width: 96,
                                  height: 96,
                                  fit: BoxFit.cover,
                                  errorWidget: Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(
                                          alpha: isDark ? 0.12 : 0.65,
                                        ),
                                      ),
                                      child: Icon(
                                        CupertinoIcons.house_fill,
                                        color: isDark
                                            ? const Color(0xFF69B1FF)
                                            : const Color(0xFF0284C7),
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(
                                        alpha: isDark ? 0.12 : 0.65,
                                      ),
                                    ),
                                    child: Icon(
                                      CupertinoIcons.house_fill,
                                      color: isDark
                                          ? const Color(0xFF69B1FF)
                                          : const Color(0xFF0284C7),
                                      size: 24,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      // Status badge pill overlay
                      Positioned(
                        bottom: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.50),
                              width: 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: badgeColor.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                badgeIcon,
                                color: badgeTextColor,
                                size: 9,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                badgeLabel,
                                style: TextStyle(
                                  color: badgeTextColor,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // ── Info Column ────────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + Top-Right Action (Note / Bell)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                name.toString(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                  height: 1.25,
                                  letterSpacing: -0.3,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!isEditMode) ...[
                              // 1. Alert Bell Button (Theo dõi phòng & biến động giá)
                              if (onToggleNotify != null) ...[
                                const SizedBox(width: 5),
                                _buildActionButton(
                                  icon: isNotified
                                      ? CupertinoIcons.bell_fill
                                      : CupertinoIcons.bell,
                                  isActive: isNotified,
                                  activeColor: const Color(0xFFF59E0B),
                                  onTap: onToggleNotify!,
                                  isDark: isDark,
                                ),
                              ],
                              // 2. Mark as Visited Button (Đánh dấu đã đi xem phòng thực tế)
                              if (onToggleVisited != null) ...[
                                const SizedBox(width: 5),
                                _buildActionButton(
                                  icon: room['isVisited'] == true
                                      ? CupertinoIcons.checkmark_seal_fill
                                      : CupertinoIcons.checkmark_seal,
                                  isActive: room['isVisited'] == true,
                                  activeColor: const Color(0xFF10B981),
                                  onTap: onToggleVisited!,
                                  isDark: isDark,
                                ),
                              ],
                              // 3. Share Button (Chia sẻ liên kết phòng)
                              if (onShare != null) ...[
                                const SizedBox(width: 5),
                                _buildActionButton(
                                  icon: CupertinoIcons.share,
                                  isActive: false,
                                  activeColor: const Color(0xFF2563EB),
                                  onTap: onShare!,
                                  isDark: isDark,
                                ),
                              ],
                              // 4. Note Edit Button (Ghi chú riêng)
                              if (onEditNote != null) ...[
                                const SizedBox(width: 5),
                                _buildActionButton(
                                  icon: (room['privateNote'] != null &&
                                              room['privateNote']
                                                  .toString()
                                                  .trim()
                                                  .isNotEmpty)
                                      ? CupertinoIcons.pencil_ellipsis_rectangle
                                      : CupertinoIcons.pencil,
                                  isActive: (room['privateNote'] != null &&
                                          room['privateNote']
                                              .toString()
                                              .trim()
                                              .isNotEmpty),
                                  activeColor: const Color(0xFF0284C7),
                                  onTap: onEditNote!,
                                  isDark: isDark,
                                ),
                              ],
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Address Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 1.5),
                              child: Icon(
                                CupertinoIcons.location_solid,
                                size: 11.5,
                                color: Color(0xFF69B1FF),
                              ),
                            ),
                            const SizedBox(width: 3.5),
                            Expanded(
                              child: Text(
                                address.toString(),
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.55)
                                      : const Color(0xFF64748B),
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        // Price Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              fmt.format(price),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15.5,
                                color: isAvailable || isUpcoming
                                    ? const Color(0xFF2563EB)
                                    : isDark
                                        ? Colors.white.withValues(alpha: 0.4)
                                        : const Color(0xFF94A3B8),
                                letterSpacing: -0.4,
                              ),
                            ),
                            Text(
                              ' /tháng',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.45)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            // Price Drop Alert Badge
                            if (room['oldPrice'] != null &&
                                double.tryParse(room['oldPrice'].toString()) != null &&
                                double.parse(room['oldPrice'].toString()) > price) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5.5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                                    width: 0.7,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      CupertinoIcons.arrow_down_right,
                                      size: 9.5,
                                      color: Color(0xFFEF4444),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      'Giảm ${(double.parse(room['oldPrice'].toString()) - price) ~/ 1000}k',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        // Tags & Chips Row (Commute, Visited, Note)
                        if (distanceKm != null ||
                            room['isVisited'] == true ||
                            (room['privateNote'] != null &&
                                room['privateNote'].toString().trim().isNotEmpty)) ...[
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 5,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Commute info chip
                              if (distanceKm != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6.5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : const Color(0xFF69B1FF).withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        CupertinoIcons.car_detailed,
                                        size: 10.5,
                                        color: isDark
                                            ? const Color(0xFF69B1FF)
                                            : const Color(0xFF2563EB),
                                      ),
                                      const SizedBox(width: 3.5),
                                      Text(
                                        '${distanceKm!.toStringAsFixed(1)} km (~${(distanceKm! * 2.5).round()} ph)',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? const Color(0xFF93C5FD)
                                              : const Color(0xFF1D4ED8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              // Visited Badge
                              if (room['isVisited'] == true)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(50),
                                    border: Border.all(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.35),
                                      width: 0.7,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        CupertinoIcons.checkmark_seal_fill,
                                        size: 9.5,
                                        color: Color(0xFF10B981),
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        'Đã đi xem',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF059669),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              // Private Note chip
                              if (room['privateNote'] != null &&
                                  room['privateNote'].toString().trim().isNotEmpty)
                                GestureDetector(
                                  onTap: onEditNote,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6.5,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(50),
                                      border: Border.all(
                                        color: const Color(0xFF69B1FF).withValues(alpha: 0.3),
                                        width: 0.7,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          CupertinoIcons.pencil,
                                          size: 9.5,
                                          color: Color(0xFF2563EB),
                                        ),
                                        const SizedBox(width: 3),
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: 130),
                                          child: Text(
                                            room['privateNote'].toString(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontStyle: FontStyle.italic,
                                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                        // Footer: Date / Availability
                        if (isUpcoming && availableFrom != null) ...[
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                CupertinoIcons.calendar_badge_plus,
                                size: 11,
                                color: Color(0xFFD97706),
                              ),
                              const SizedBox(width: 3.5),
                              Text(
                                'Trống từ: $availableFrom',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        ] else if (savedAt != null) ...[
                          const SizedBox(height: 5),
                          Text(
                            'Đã lưu: $savedAt',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.35)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return BounceClick(
      scaleFactor: 0.85,
      onPressed: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? activeColor.withValues(alpha: isDark ? 0.22 : 0.12)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.85)),
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 0.65)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.16)
                    : const Color(0xFFE2E8F0)),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: (isActive ? activeColor : Colors.black).withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            size: 14,
            color: isActive
                ? activeColor
                : (isDark ? Colors.white70 : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return iso;
    }
  }
}
