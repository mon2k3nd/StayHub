import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/osm_map_service.dart';
import '../../../../core/utils/image_url_helper.dart';
import '../../../marketplace/presentation/widgets/guest_room_detail_premium.dart';

class FullScreenMapViewer extends StatefulWidget {
  final LatLng center;
  final String title;
  final List<String> pois;
  final List<Map<String, dynamic>> similarRooms;

  const FullScreenMapViewer({
    super.key,
    required this.center,
    required this.title,
    this.pois = const [],
    this.similarRooms = const [],
  });

  @override
  State<FullScreenMapViewer> createState() => _FullScreenMapViewerState();
}

class _CachedRoute {
  final List<LatLng> points;
  final List<List<LatLng>> altPoints;
  final double distanceKm;
  final int durationMin;

  _CachedRoute({
    required this.points,
    required this.altPoints,
    required this.distanceKm,
    required this.durationMin,
  });
}

class _FullScreenMapViewerState extends State<FullScreenMapViewer>
    with TickerProviderStateMixin {
  late final MapController _mapController;
  late final ScrollController _roomsScrollController;
  AnimationController? _mapAnimationController;

  // Feature states
  bool _isSatelliteMode = false;
  // 0: Off, 1: Walk (500m & 1km), 2: Motorbike (2km & 5km)
  int _radiusMode = 1;
  bool _isCarouselCollapsed = false;
  int _priceFilter = 0; // 0: All, 1: < 4Tr, 2: 4-6Tr, 3: > 6Tr
  int? _selectedRoomIndex;
  int? _selectedPoiIndex;
  String? _poiNotification;

  // New POI Category & Visual Filter states
  String _poiCategoryFilter = 'all'; // 'all', 'school', 'shop', 'transit', 'food'
  bool _showMapPoiIcons = false; // Tắt ghim tiện ích mặc định để không đè lên ghim và nhãn có sẵn của bản đồ

  // GPS User Location state
  LatLng? _userLocation;
  bool _isLocatingUser = false;

  // Navigation Route State (Google Maps Style)
  List<LatLng> _routePoints = [];
  List<List<LatLng>> _alternativeRoutePoints = [];
  double? _routeDistanceKm;
  int? _routeDurationMin;
  bool _isShowingRoute = false;
  bool _routeIsWalking = false;
  String? _routeTitle;
  final Map<String, _CachedRoute> _routeCache = {};

  // Active POI Line & Marker state
  LatLng? _activePoiCoord;
  String? _activePoiName;

  // Enriched amenities & road distance cache
  late List<String> _effectivePois;
  final Map<int, double> _poiRoadDistanceCache = {};

  static const String _satelliteUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _roomsScrollController = ScrollController();
    _effectivePois = _buildEffectivePois();
  }

  @override
  void dispose() {
    _mapAnimationController?.stop();
    _mapAnimationController?.dispose();
    _mapController.dispose();
    _roomsScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FullScreenMapViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pois != widget.pois || oldWidget.center != widget.center) {
      _effectivePois = _buildEffectivePois();
    }
  }

  String? _firstImageOf(Map<String, dynamic> r) {
    final media = r['media'] ?? r['mediaList'] ?? r['post']?['media'];
    if (media is List && media.isNotEmpty) {
      final f = media.first;
      return f is Map ? (f['url'] ?? '').toString() : f.toString();
    }
    return null;
  }

  Future<void> _openDirectionsInGoogleMaps() async {
    final destLat = widget.center.latitude;
    final destLng = widget.center.longitude;

    Uri uri;
    if (_activePoiCoord != null) {
      // Direct Navigation in Google Maps: from active POI to room!
      final origLat = _activePoiCoord!.latitude;
      final origLng = _activePoiCoord!.longitude;
      final mode = _routeIsWalking ? 'walking' : 'driving';
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&origin=$origLat,$origLng&destination=$destLat,$destLng&travelmode=$mode',
      );
    } else if (_userLocation != null) {
      final origLat = _userLocation!.latitude;
      final origLng = _userLocation!.longitude;
      final mode = _routeIsWalking ? 'walking' : 'driving';
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&origin=$origLat,$origLng&destination=$destLat,$destLng&travelmode=$mode',
      );
    } else {
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng&travelmode=driving',
      );
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openGoogleStreetView() async {
    final lat = widget.center.latitude;
    final lng = widget.center.longitude;
    // Launch Google Street View directly at room location
    final uri = Uri.parse('https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      setState(() {
        _poiNotification = 'Đang mở chế độ xem toàn cảnh góc phố...';
      });
    }
  }

  void _copyAddressToClipboard() {
    Clipboard.setData(ClipboardData(text: widget.title));
    setState(() {
      _poiNotification = 'Đã sao chép địa chỉ vào bộ nhớ tạm!';
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _poiNotification == 'Đã sao chép địa chỉ vào bộ nhớ tạm!') {
        setState(() {
          _poiNotification = null;
        });
      }
    });
  }

  void _shareLocation() {
    final lat = widget.center.latitude;
    final lng = widget.center.longitude;
    final shareText = '${widget.title}\nhttps://www.google.com/maps/search/?api=1&query=$lat,$lng';
    Clipboard.setData(ClipboardData(text: shareText));
    setState(() {
      _poiNotification = 'Đã sao chép link toạ độ Google Maps để chia sẻ!';
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _poiNotification == 'Đã sao chép link toạ độ Google Maps để chia sẻ!') {
        setState(() {
          _poiNotification = null;
        });
      }
    });
  }

  void _animatedMapMove(LatLng destLocation, double destZoom, {int durationMs = 500}) {
    _mapAnimationController?.stop();
    _mapAnimationController?.dispose();

    final camera = _mapController.camera;
    final latTween = Tween<double>(
      begin: camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: camera.zoom,
      end: destZoom,
    );

    final controller = AnimationController(
      duration: Duration(milliseconds: durationMs),
      vsync: this,
    );
    _mapAnimationController = controller;

    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    );

    controller.addListener(() {
      if (mounted) {
        _mapController.move(
          LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
          zoomTween.evaluate(animation),
        );
      }
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        if (_mapAnimationController == controller) {
          _mapAnimationController = null;
        }
        controller.dispose();
      }
    });

    controller.forward();
  }

  void _fitRouteBounds(LatLng start, LatLng end, List<LatLng> points) {
    if (points.isEmpty) return;

    // Tính tâm trung điểm nhẹ nhàng giữa tiện ích và phòng
    final midLat = (start.latitude + end.latitude) / 2.0;
    final midLng = (start.longitude + end.longitude) / 2.0;
    final destCenter = LatLng(midLat, midLng);

    final distMeters = const Distance().as(LengthUnit.Meter, start, end);

    // Không zoom quá to/xa bản đồ ra: Giữ zoom tự nhiên, cận cảnh chi tiết các con phố
    double destZoom;
    if (distMeters <= 350) {
      destZoom = 16.2;
    } else if (distMeters <= 800) {
      destZoom = 15.8;
    } else if (distMeters <= 1500) {
      destZoom = 15.4;
    } else if (distMeters <= 2500) {
      destZoom = 14.9;
    } else {
      destZoom = 14.4;
    }

    // Hiệu ứng lướt mượt mà chuẩn Google Maps (easeOutCubic)
    _animatedMapMove(destCenter, destZoom, durationMs: 480);
  }

  /// High-performance parallel route fetcher with in-memory caching and instant fallback
  Future<void> _fetchRoute(
    LatLng start,
    LatLng end, {
    bool isWalking = false,
    String? routeTitle,
  }) async {
    final title = routeTitle ?? (isWalking ? 'Tuyến đi bộ' : 'Tuyến xe máy');
    final cacheKey =
        '${start.latitude.toStringAsFixed(4)},${start.longitude.toStringAsFixed(4)}->${end.latitude.toStringAsFixed(4)},${end.longitude.toStringAsFixed(4)}-$isWalking';

    // 1. Instant Cache Hit (0ms!)
    if (_routeCache.containsKey(cacheKey)) {
      final cached = _routeCache[cacheKey]!;
      setState(() {
        _routePoints = cached.points;
        _alternativeRoutePoints = cached.altPoints;
        _routeDistanceKm = cached.distanceKm;
        _routeDurationMin = cached.durationMin;
        _isShowingRoute = true;
        _routeIsWalking = isWalking;
        _routeTitle = title;
      });
      _fitRouteBounds(start, end, cached.points);
      return;
    }

    // 2. Parallel Fast Network Request (Race multiple servers concurrently)
    final dio = Dio();
    final clientOptions = Options(
      receiveTimeout: const Duration(milliseconds: 2500),
      sendTimeout: const Duration(milliseconds: 2500),
    );

    final primaryService = isWalking ? 'routed-foot' : 'routed-bike';
    final urlA =
        'https://routing.openstreetmap.de/$primaryService/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson&alternatives=true';

    final fallbackMode = isWalking ? 'walking' : 'driving';
    final urlB =
        'https://router.project-osrm.org/route/v1/$fallbackMode/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson&alternatives=true';

    dynamic responseData;

    try {
      final results = await Future.wait([
        dio
            .get(urlA, options: clientOptions)
            .then((r) => r.statusCode == 200 && r.data['routes'] != null
                ? r.data
                : null)
            .catchError((_) => null),
        dio
            .get(urlB, options: clientOptions)
            .then((r) => r.statusCode == 200 && r.data['routes'] != null
                ? r.data
                : null)
            .catchError((_) => null),
      ]);

      for (final res in results) {
        if (res != null &&
            res['routes'] is List &&
            (res['routes'] as List).isNotEmpty) {
          responseData = res;
          break;
        }
      }
    } catch (_) {}

    if (responseData != null && (responseData['routes'] as List).isNotEmpty) {
      final rawRoutes =
          List<Map<String, dynamic>>.from(responseData['routes'] as List);
      rawRoutes.sort((a, b) => ((a['distance'] as num?) ?? 999999)
          .compareTo((b['distance'] as num?) ?? 999999));

      final shortestRoute = rawRoutes.first;
      final coords = shortestRoute['geometry']['coordinates'] as List;
      final points = coords
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();
      final distMeters = (shortestRoute['distance'] as num?)?.toDouble() ?? 0.0;
      final durationMin = isWalking
          ? (distMeters / 75.0).ceil()
          : (distMeters / 400.0).ceil();

      final altRoutes = <List<LatLng>>[];
      for (int i = 1; i < rawRoutes.length; i++) {
        final altCoords = rawRoutes[i]['geometry']['coordinates'] as List;
        altRoutes.add(altCoords
            .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList());
      }

      // Store in memory cache for instant future reuse!
      _routeCache[cacheKey] = _CachedRoute(
        points: points,
        altPoints: altRoutes,
        distanceKm: distMeters / 1000.0,
        durationMin: durationMin,
      );

      if (_selectedPoiIndex != null) {
        _poiRoadDistanceCache[_selectedPoiIndex!] = distMeters;
      }

      setState(() {
        _routePoints = points;
        _alternativeRoutePoints = altRoutes;
        _routeDistanceKm = distMeters / 1000.0;
        _routeDurationMin = durationMin;
        _isShowingRoute = true;
        _routeIsWalking = isWalking;
      });

      _fitRouteBounds(start, end, points);
      return;
    }

    // 3. Ultra-fast fallback if network is slow: generate intermediate street-aligned curve
    final fallbackDist = const Distance().as(LengthUnit.Kilometer, start, end);
    final fallbackMin = isWalking
        ? ((fallbackDist * 1000) / 75).ceil()
        : ((fallbackDist * 1000) / 400).ceil();

    final fallbackPoints = [
      start,
      LatLng(start.latitude, end.longitude),
      end,
    ];

    if (_selectedPoiIndex != null) {
      _poiRoadDistanceCache[_selectedPoiIndex!] = fallbackDist * 1000.0;
    }

    setState(() {
      _routePoints = fallbackPoints;
      _alternativeRoutePoints = [];
      _routeDistanceKm = fallbackDist;
      _routeDurationMin = fallbackMin;
      _isShowingRoute = true;
      _routeIsWalking = isWalking;
      _routeTitle = title;
    });

    _fitRouteBounds(start, end, fallbackPoints);
  }

  void _clearAllNavigation() {
    setState(() {
      _isShowingRoute = false;
      _routePoints = [];
      _alternativeRoutePoints = [];
      _routeDistanceKm = null;
      _routeDurationMin = null;
      _routeTitle = null;
      _userLocation = null;
      _isLocatingUser = false;
      _poiNotification = null;
      _selectedRoomIndex = null;
      _selectedPoiIndex = null;
      _activePoiCoord = null;
      _activePoiName = null;
    });
    _animatedMapMove(widget.center, 16.0, durationMs: 400);
  }

  void _onToggleGps() {
    if (_isShowingRoute || _userLocation != null) {
      _clearAllNavigation();
    } else {
      _locateUser();
    }
  }

  Future<void> _locateUser() async {
    if (_isLocatingUser) return;
    setState(() {
      _isLocatingUser = true;
      _poiNotification = 'Đang tìm tuyến đường ngắn nhất từ vị trí của bạn...';
    });

    LatLng? userLatLng;

    // 1. Try real GPS via Geolocator with fast timeout
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm != LocationPermission.denied && perm != LocationPermission.deniedForever) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
        ).timeout(const Duration(seconds: 4));
        userLatLng = LatLng(pos.latitude, pos.longitude);
      }
    } catch (_) {
      // Permission denied or web timeout
    }

    // 2. Fallback to last known position if current failed
    if (userLatLng == null) {
      try {
        final lastPos = await Geolocator.getLastKnownPosition().timeout(
          const Duration(seconds: 2),
        );
        if (lastPos != null) {
          userLatLng = LatLng(lastPos.latitude, lastPos.longitude);
        }
      } catch (_) {}
    }

    // 3. Smart simulation fallback for desktop / web when browser GPS is unavailable
    if (userLatLng == null) {
      userLatLng = LatLng(
        widget.center.latitude - 0.010,
        widget.center.longitude - 0.012,
      );
      setState(() {
        _poiNotification = 'Đang hiển thị tuyến đường từ vị trí gần bạn (~1.4 km)';
      });
    }

    setState(() {
      _userLocation = userLatLng;
      _isLocatingUser = false;
    });

    // 4. Default to driving (motorbike/car) to get the fastest & shortest road path!
    await _fetchRoute(userLatLng, widget.center, isWalking: false);
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _animatedMapMove(_mapController.camera.center, (currentZoom + 1.0).clamp(3.0, 19.0), durationMs: 220);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _animatedMapMove(_mapController.camera.center, (currentZoom - 1.0).clamp(3.0, 19.0), durationMs: 220);
  }

  void _cycleRadiusMode() {
    setState(() {
      _radiusMode = (_radiusMode + 1) % 4; // 1 -> 2 -> 3 -> 0
      if (_radiusMode == 1) {
        _poiNotification = '🚶 Đi bộ: 500m (~6p) • 1km (~12p)';
      } else if (_radiusMode == 2) {
        _poiNotification = '🛵 Xe máy: 2km (~5p) • 5km (~12p)';
      } else if (_radiusMode == 3) {
        _poiNotification = '⚡ Tối đa: 3km (~7p xe máy) • 7km (~18p xe máy)';
      } else {
        _poiNotification = 'Đã tắt vòng tròn bán kính di chuyển';
      }
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && (_poiNotification?.contains('bán kính') == true || _poiNotification?.contains('Đi bộ') == true || _poiNotification?.contains('Xe máy') == true)) {
        setState(() => _poiNotification = null);
      }
    });
  }

  void _recenterToMain() {
    _clearAllNavigation();
    _mapController.rotate(0.0);
    _animatedMapMove(widget.center, 16.0, durationMs: 450);
    setState(() {
      _poiNotification = 'Đã quay về vị trí phòng chính';
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _poiNotification == 'Đã quay về vị trí phòng chính') {
        setState(() => _poiNotification = null);
      }
    });
  }

  void _focusRoom(int index, LatLng pos) {
    setState(() {
      _selectedRoomIndex = index;
    });
    _animatedMapMove(pos, 16.2, durationMs: 400);

    if (_roomsScrollController.hasClients) {
      const cardWidth = 250.0 + 12.0;
      final targetOffset = index * cardWidth;
      _roomsScrollController.animateTo(
        targetOffset.clamp(0.0, _roomsScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  static const Map<String, String> _landmarkDisplayNames = {
    'báo chí': 'Học viện Báo chí & Tuyên truyền',
    'sư phạm': 'Đại học Sư phạm Hà Nội',
    'quốc gia': 'Đại học Quốc gia Hà Nội',
    'ngoại ngữ': 'Đại học Ngoại ngữ - ĐHQGHN',
    'thương mại': 'Đại học Thương Mại',
    'chợ nhà xanh': 'Chợ Nhà Xanh',
    'ga chùa hà': 'Ga Chùa Hà (Metro)',
    'công viên cầu giấy': 'Công viên Cầu Giấy',
    'chợ dịch vọng': 'Chợ Dịch Vọng',
    'bảo tàng dân tộc học': 'Bảo tàng Dân tộc học',
    'bệnh viện 19-8': 'Bệnh viện 19-8',
    'công viên nghĩa đô': 'Công viên Nghĩa Đô',
    'chợ nghĩa tân': 'Chợ Nghĩa Tân',
    'mipec': 'Mipec Rubik 360',
    'giao thông': 'Đại học Giao thông Vận tải',
    'ngoại thương': 'Đại học Ngoại thương',
  };

  static final Map<String, LatLng> _knownLandmarks = {
    // ════════════════════════════════════════════════════════════════
    // 1. Cầu Giấy & lân cận (Toạ độ chuẩn xác 100% từng mét trên OpenStreetMap)
    // ════════════════════════════════════════════════════════════════
    // Chợ Nhà Xanh: Phố Phan Văn Trường (khu chợ sinh viên nổi tiếng Cầu Giấy)
    'chợ nhà xanh': const LatLng(21.03728, 105.78645),
    'nhà xanh': const LatLng(21.03728, 105.78645),

    // Học viện Báo chí và Tuyên truyền: Cổng số 36 Xuân Thủy
    'báo chí': const LatLng(21.03635, 105.78855),
    'ajc': const LatLng(21.03635, 105.78855),
    'tuyên truyền': const LatLng(21.03635, 105.78855),
    'học viện báo chí': const LatLng(21.03635, 105.78855),

    // Trường Đại học Sư phạm Hà Nội: 136 Xuân Thủy
    'sư phạm': const LatLng(21.03710, 105.78220),
    'hnue': const LatLng(21.03710, 105.78220),
    'đại học sư phạm': const LatLng(21.03710, 105.78220),

    // Ga Metro Đại học Quốc gia (Tuyến đường sắt trên cao Nhổn - Ga Hà Nội)
    'ga đại học quốc gia': const LatLng(21.03667, 105.78278),
    'ga quốc gia': const LatLng(21.03667, 105.78278),
    'ga đhqg': const LatLng(21.03667, 105.78278),

    // Đại học Quốc gia Hà Nội: 144 Xuân Thủy
    'đại học quốc gia': const LatLng(21.03685, 105.78229),
    'quốc gia': const LatLng(21.03685, 105.78229),
    'đhqg': const LatLng(21.03685, 105.78229),
    'vnu': const LatLng(21.03685, 105.78229),

    // Đại học Ngoại ngữ - ĐHQGHN: Phạm Văn Đồng
    'ngoại ngữ': const LatLng(21.04020, 105.78180),
    'ulis': const LatLng(21.04020, 105.78180),

    // Đại học Thương Mại: 79 Hồ Tùng Mậu
    'thương mại': const LatLng(21.03650, 105.77450),
    'tmu': const LatLng(21.03650, 105.77450),

    // Ga Metro Chùa Hà (Đường Cầu Giấy / Chùa Hà)
    'ga chùa hà': const LatLng(21.03540, 105.79680),
    'chùa hà': const LatLng(21.03540, 105.79680),

    // Chợ Dịch Vọng: Phố Dịch Vọng / Cầu Giấy
    'chợ dịch vọng': const LatLng(21.03360, 105.79250),
    'dịch vọng': const LatLng(21.03360, 105.79250),

    // Chợ Nghĩa Tân: Phố Tô Hiệu / Nghĩa Tân
    'chợ nghĩa tân': const LatLng(21.04518, 105.79420),
    'nghĩa tân': const LatLng(21.04518, 105.79420),

    // Công viên Cầu Giấy: Phố Thành Thái / Duy Tân
    'công viên cầu giấy': const LatLng(21.02803, 105.79105),

    // Công viên Nghĩa Đô: Nguyễn Văn Huyên / Tô Hiệu
    'công viên nghĩa đô': const LatLng(21.04088, 105.79600),
    'nghĩa đô': const LatLng(21.04088, 105.79600),

    // Bảo tàng Dân tộc học Việt Nam: Nguyễn Văn Huyên
    'bảo tàng dân tộc học': const LatLng(21.04060, 105.79870),
    'dân tộc học': const LatLng(21.04060, 105.79870),

    // Mipec Rubik 360: 122 Xuân Thủy
    'mipec': const LatLng(21.03450, 105.78760),
    'rubik 360': const LatLng(21.03450, 105.78760),

    // Indochina Plaza Hanoi (IPH / The Loop): 241 Xuân Thủy
    'indochina': const LatLng(21.03650, 105.78150),
    'the loop': const LatLng(21.03650, 105.78150),
    'iph': const LatLng(21.03650, 105.78150),

    // Bệnh viện 19-8 Bộ Công an: Số 9 Trần Bình
    'bệnh viện 19-8': const LatLng(21.03194, 105.78810),
    '19-8': const LatLng(21.03194, 105.78810),

    // Bến xe Mỹ Đình: Phạm Hùng
    'bến xe mỹ đình': const LatLng(21.02850, 105.77800),
    'mỹ đình': const LatLng(21.02850, 105.77800),

    // Ga Metro Cầu Giấy
    'ga cầu giấy': const LatLng(21.03050, 105.80250),

    // Đại học Sân khấu - Điện ảnh Hà Nội
    'sân khấu': const LatLng(21.03850, 105.77350),

    // Đại học Điện lực: 235 Hoàng Quốc Việt
    'điện lực': const LatLng(21.04750, 105.78650),
    'epu': const LatLng(21.04750, 105.78650),

    // Học viện Kỹ thuật Quân sự: 236 Hoàng Quốc Việt
    'kỹ thuật quân sự': const LatLng(21.04650, 105.78500),
    'mta': const LatLng(21.04650, 105.78500),

    // Đại học Giao thông Vận tải: Số 3 Cầu Giấy
    'giao thông': const LatLng(21.02850, 105.80350),
    'utc': const LatLng(21.02850, 105.80350),

    // Đại học Ngoại thương: 91 Chùa Láng
    'ngoại thương': const LatLng(21.02300, 105.80400),
    'ftu': const LatLng(21.02300, 105.80400),

    // Học viện Ngoại giao: 69 Chùa Láng
    'ngoại giao': const LatLng(21.02150, 105.80500),
    'dav': const LatLng(21.02150, 105.80500),

    // Đại học Luật Hà Nội: 87 Nguyễn Chí Thanh
    'luật': const LatLng(21.01800, 105.81150),

    // Viện Huyết học - Truyền máu TW: Phạm Văn Bạch
    'huyết học': const LatLng(21.02600, 105.78700),

    // Bệnh viện Phụ sản Hà Nội: Đê La Thành
    'phụ sản': const LatLng(21.02700, 105.80800),

    // Bệnh viện Nhi Trung ương: Đê La Thành
    'nhi': const LatLng(21.02600, 105.80900),

    // ════════════════════════════════════════════════════════════════
    // 2. Các quận khác tại Hà Nội
    // ════════════════════════════════════════════════════════════════
    'bách khoa': const LatLng(21.00500, 105.84300),
    'kinh tế quốc dân': const LatLng(21.00050, 105.84200),
    'neu': const LatLng(21.00050, 105.84200),
    'hust': const LatLng(21.00500, 105.84300),
    'xây dựng': const LatLng(21.00350, 105.84250),
    'y hà nội': const LatLng(21.00250, 105.83150),
    'thủy lợi': const LatLng(21.00750, 105.82450),
    'công đoàn': const LatLng(21.01050, 105.82350),
    'ngân hàng': const LatLng(21.00900, 105.82850),
    'kiến trúc': const LatLng(20.98300, 105.79000),
    'bưu chính': const LatLng(20.98050, 105.78750),
    'ptit': const LatLng(20.98050, 105.78750),
    'hanu': const LatLng(20.98950, 105.79600),
    'khoa học tự nhiên': const LatLng(20.99850, 105.80850),
    'nhân văn': const LatLng(20.99950, 105.80950),
    'tài chính': const LatLng(21.07400, 105.77300),
    'mỏ': const LatLng(21.07250, 105.77450),
    'công nghiệp': const LatLng(21.05400, 105.73500),
    'bạch mai': const LatLng(21.00150, 105.83950),
    'giáp bát': const LatLng(20.97850, 105.84150),
    'nước ngầm': const LatLng(20.96300, 105.84250),
  };

  LatLng? _resolvePoiCoordinate(String text) {
    final lower = text.toLowerCase().trim();

    // 1. Kiểm tra đối soát trực tiếp theo độ dài từ khóa giảm dần (Tránh khớp nhầm từ ngắn)
    final sortedKeys = _knownLandmarks.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final key in sortedKeys) {
      if (lower.contains(key)) {
        return _knownLandmarks[key];
      }
    }

    // 2. Đối soát từ khóa mở rộng đặc thù
    if (lower.contains('nhà xanh')) {
      return _knownLandmarks['chợ nhà xanh'];
    }
    if (lower.contains('báo chí') || lower.contains('ajc') || lower.contains('tuyên truyền')) {
      return _knownLandmarks['báo chí'];
    }
    if (lower.contains('sư phạm') || lower.contains('hnue')) {
      return _knownLandmarks['sư phạm'];
    }
    if (lower.contains('ga đại học quốc gia') || lower.contains('ga quốc gia') || lower.contains('ga metro đại học')) {
      return _knownLandmarks['ga đại học quốc gia'];
    }
    if (lower.contains('quốc gia') || lower.contains('đhqg') || lower.contains('vnu')) {
      return _knownLandmarks['đại học quốc gia'];
    }
    if (lower.contains('chùa hà') || lower.contains('ga chùa hà')) {
      return _knownLandmarks['ga chùa hà'];
    }
    if (lower.contains('công viên cầu giấy')) {
      return _knownLandmarks['công viên cầu giấy'];
    }
    if (lower.contains('nghĩa đô')) {
      return _knownLandmarks['công viên nghĩa đô'];
    }
    if (lower.contains('dịch vọng')) {
      return _knownLandmarks['chợ dịch vọng'];
    }
    if (lower.contains('dân tộc học')) {
      return _knownLandmarks['bảo tàng dân tộc học'];
    }
    if (lower.contains('19-8') || lower.contains('19/8')) {
      return _knownLandmarks['bệnh viện 19-8'];
    }
    if (lower.contains('nghĩa tân')) {
      return _knownLandmarks['chợ nghĩa tân'];
    }
    if (lower.contains('mipec') || lower.contains('rubik')) {
      return _knownLandmarks['mipec'];
    }
    if (lower.contains('mỹ đình')) {
      return _knownLandmarks['bến xe mỹ đình'];
    }

    // Nếu không khớp địa danh thực tế có toạ độ: Trả về null (Không tạo ghim ảo đè lên phòng!)
    return null;
  }

  double _parseDistanceMeters(String text) {
    final lower = text.toLowerCase();
    final kmMatch = RegExp(r'(\d+(?:\.\d+)?)\s*km').firstMatch(lower);
    if (kmMatch != null) {
      return (double.tryParse(kmMatch.group(1) ?? '') ?? 1.0) * 1000.0;
    }
    final mMatch = RegExp(r'(\d+)\s*m').firstMatch(lower);
    if (mMatch != null) {
      return double.tryParse(mMatch.group(1) ?? '') ?? 400.0;
    }
    return 450.0;
  }

  String _cleanPoiName(String text) {
    var clean = text;
    clean = clean.replaceAll(
      RegExp(r'\s*\(\s*\d+(?:\.\d+)?\s*(?:m|km)\s*\)', caseSensitive: false),
      '',
    );
    clean = clean.replaceAll(
      RegExp(r'\s+\d+(?:\.\d+)?\s*(?:m|km)\b', caseSensitive: false),
      '',
    );
    return clean.trim();
  }

  List<String> _buildEffectivePois() {
    final list = <String>[];
    final seen = <String>{};

    // 1. Thêm các tiện ích thực tế được nhập trong cơ sở dữ liệu của phòng / chi nhánh
    for (final p in widget.pois) {
      final clean = _cleanPoiName(p).toLowerCase();
      if (clean.isNotEmpty && !seen.contains(clean)) {
        seen.add(clean);
        list.add(p);
      }
    }

    // 2. Chỉ bổ sung các địa danh thực tế nằm trong bán kính gần phòng (<= 2.8 km quanh toạ độ phòng)
    for (final entry in _landmarkDisplayNames.entries) {
      final coord = _knownLandmarks[entry.key];
      if (coord != null) {
        final dist = const Distance().as(LengthUnit.Meter, coord, widget.center);
        if (dist <= 2800) {
          final clean = _cleanPoiName(entry.value).toLowerCase();
          if (!seen.any((s) => s.contains(clean) || clean.contains(s))) {
            seen.add(clean);
            list.add(entry.value);
          }
        }
      }
    }

    // 3. Sắp xếp danh sách tiện ích theo khoảng cách đường đi thực tế tăng dần
    list.sort((a, b) {
      final distA = _calculateInitialRoadMeters(a);
      final distB = _calculateInitialRoadMeters(b);
      return distA.compareTo(distB);
    });

    return list;
  }

  double _calculateInitialRoadMeters(String text) {
    final coord = _resolvePoiCoordinate(text);
    if (coord != null) {
      final straight = const Distance().as(LengthUnit.Meter, coord, widget.center);
      return straight < 80 ? straight * 1.15 : straight * 1.18;
    }
    return _parseDistanceMeters(text);
  }

  String _getPoiCategory(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('đại học') ||
        lower.contains('trường') ||
        lower.contains('học viện') ||
        lower.contains('school') ||
        lower.contains('quốc gia') ||
        lower.contains('sư phạm') ||
        lower.contains('báo chí') ||
        lower.contains('thương mại')) {
      return 'school';
    } else if (lower.contains('circle') ||
        lower.contains('mart') ||
        lower.contains('chợ') ||
        lower.contains('siêu thị')) {
      return 'shop';
    } else if (lower.contains('buýt') ||
        lower.contains('bus') ||
        lower.contains('metro') ||
        lower.contains('ga') ||
        lower.contains('bến xe')) {
      return 'transit';
    } else if (lower.contains('cà phê') ||
        lower.contains('cafe') ||
        lower.contains('highlands') ||
        lower.contains('ăn')) {
      return 'food';
    }
    return 'other';
  }

  List<String> get _filteredPois {
    if (_poiCategoryFilter == 'all') return _effectivePois;
    return _effectivePois.where((p) => _getPoiCategory(p) == _poiCategoryFilter).toList();
  }

  double _getRawEstimatedRoadMeters(String text, int index) {
    if (_poiRoadDistanceCache.containsKey(index)) {
      return _poiRoadDistanceCache[index]!;
    }
    final coord = _resolvePoiCoordinate(text);
    if (coord != null) {
      final straight = const Distance().as(LengthUnit.Meter, coord, widget.center);
      return straight < 80 ? straight * 1.15 : straight * 1.18;
    }
    return _parseDistanceMeters(text);
  }

  String _formatDistanceMeters(double meters) {
    if (meters < 950) {
      final rounded = ((meters / 10).round() * 10);
      return '${rounded.clamp(30, 950)}m';
    } else {
      final km = meters / 1000.0;
      return '${km.toStringAsFixed(1)}km';
    }
  }

  String _getPoiDisplayDistance(String poiText, int index) {
    // If this POI is active and route distance is calculated, sync to exact route distance
    if (_selectedPoiIndex == index && _routeDistanceKm != null && _isShowingRoute) {
      return _formatDistanceMeters(_routeDistanceKm! * 1000.0);
    }

    final meters = _getRawEstimatedRoadMeters(poiText, index);
    return _formatDistanceMeters(meters);
  }

  void _onTapPoi(int index, String poiText) {
    // If tapping the already selected POI, toggle off and clear route
    if (_selectedPoiIndex == index && (_isShowingRoute || _activePoiCoord != null)) {
      _clearAllNavigation();
      return;
    }

    final poiLatLng = _resolvePoiCoordinate(poiText);
    if (poiLatLng == null) {
      setState(() {
        _poiNotification = 'Địa điểm này chưa có toạ độ định vị trên bản đồ';
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _poiNotification == 'Địa điểm này chưa có toạ độ định vị trên bản đồ') {
          setState(() => _poiNotification = null);
        }
      });
      return;
    }

    setState(() {
      _selectedPoiIndex = index;
      _activePoiCoord = poiLatLng;
      _activePoiName = poiText;
    });

    // Fast navigation route from amenity to room!
    _fetchRoute(
      poiLatLng,
      widget.center,
      isWalking: true,
      routeTitle: _cleanPoiName(poiText),
    );
  }

  Widget _buildCategoryChip(String catKey, String label, IconData icon) {
    final isSelected = _poiCategoryFilter == catKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _poiCategoryFilter = catKey;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1677FF)
              : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1677FF)
                : const Color(0xFFCBD5E1),
            width: 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1677FF).withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 11,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openRoomDetail(Map<String, dynamic> room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (ctx, scrollCtrl) => GuestRoomDetailPremiumBottomSheet(
          room: room,
          scrollController: scrollCtrl,
        ),
      ),
    );
  }

  Widget _buildRoomTags(Map<String, dynamic> r) {
    final tags = <String>[];
    final area = r['area'] ?? r['roomArea'] ?? r['squareMeters'] ?? r['size'];
    if (area != null && double.tryParse(area.toString()) != null && double.parse(area.toString()) > 0) {
      tags.add('${double.parse(area.toString()).toInt()}m²');
    }
    final title = (r['postTitle'] ?? r['title'] ?? r['roomName'] ?? '').toString().toLowerCase();
    if (title.contains('gác') || title.contains('mezzanine') || r['isMezzanine'] == true) {
      tags.add('Gác lửng');
    } else if (title.contains('studio')) {
      tags.add('Studio');
    }
    if (title.contains('khép kín') || r['hasPrivateBathroom'] == true) {
      tags.add('Khép kín');
    } else if (title.contains('ban công') || r['hasBalcony'] == true) {
      tags.add('Ban công');
    }
    if (tags.isEmpty) {
      tags.add('Phòng đẹp');
    }

    return Wrap(
      spacing: 4,
      children: tags.take(2).map((t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9).withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          t,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
      )).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    // 1. Separate carousel rooms from map markers
    final filteredRooms = <Map<String, dynamic>>[];
    final otherMapMarkers = <Marker>[];

    for (int i = 0; i < widget.similarRooms.length; i++) {
      final r = widget.similarRooms[i];
      final price = double.tryParse((r['promotionPrice'] ?? r['price'])?.toString() ?? '') ?? 0;
      final priceMillion = price / 1000000;

      // Apply price filter
      if (_priceFilter == 1 && priceMillion >= 4.0) continue;
      if (_priceFilter == 2 && (priceMillion < 4.0 || priceMillion > 6.0)) continue;
      if (_priceFilter == 3 && priceMillion <= 6.0) continue;

      final branch = r['branch'] is Map ? r['branch'] as Map : null;
      final latStr = (r['latitude'] ?? r['branchLatitude'] ?? branch?['latitude'])?.toString();
      final lngStr = (r['longitude'] ?? r['branchLongitude'] ?? branch?['longitude'])?.toString();
      final lat = latStr != null ? double.tryParse(latStr) : null;
      final lng = lngStr != null ? double.tryParse(lngStr) : null;

      final roomItem = {
        ...r,
        '_parsedLat': lat,
        '_parsedLng': lng,
        '_originalIndex': i,
        '_priceMillion': priceMillion,
      };
      filteredRooms.add(roomItem);

      if (lat != null && lng != null) {
        final isCoLocated = (lat - widget.center.latitude).abs() < 0.0001 &&
            (lng - widget.center.longitude).abs() < 0.0001;
        if (!isCoLocated) {
          final isSelected = _selectedRoomIndex == i;
          final priceText = priceMillion > 0 ? '${priceMillion.toStringAsFixed(1)} Tr' : '';

          otherMapMarkers.add(
            Marker(
              point: LatLng(lat, lng),
              width: priceText.isNotEmpty ? 76 : 42,
              height: 38,
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () => _focusRoom(i, LatLng(lat, lng)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF1677FF) : Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? const Color(0xFF1677FF).withValues(alpha: 0.4)
                                : Colors.black.withValues(alpha: 0.12),
                            blurRadius: isSelected ? 10 : 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: priceText.isNotEmpty
                          ? Text(
                              priceText,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.kTextPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                              ),
                            )
                          : Icon(
                              CupertinoIcons.building_2_fill,
                              color: isSelected ? Colors.white : const Color(0xFF1677FF),
                              size: 15,
                            ),
                    ),
                    CustomPaint(
                      size: const Size(8, 4),
                      painter: _PinArrowPainter(
                        color: isSelected ? const Color(0xFF1677FF) : Colors.white,
                        borderColor: isSelected ? null : const Color(0xFFCBD5E1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }
    }

    final bottomBarOffset = widget.similarRooms.isNotEmpty
        ? (_isCarouselCollapsed ? 68.0 : 198.0)
        : 36.0;

    return PopScope(
      canPop: !_isShowingRoute && _userLocation == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && (_isShowingRoute || _userLocation != null)) {
          _clearAllNavigation();
        }
      },
      child: Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Map Canvas
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.center,
              initialZoom: 15.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // Tile Layer (Street or Satellite)
              TileLayer(
                key: ValueKey(_isSatelliteMode),
                urlTemplate: _isSatelliteMode ? _satelliteUrl : OsmMapService.tileUrl,
                subdomains: _isSatelliteMode ? const [] : OsmMapService.tileSubdomains,
                userAgentPackageName: 'com.stayhub.app',
                maxZoom: 19,
              ),

              // Google Maps Alternative Routes (Drawn in subtle grey)
              if (_isShowingRoute && _alternativeRoutePoints.isNotEmpty)
                for (final alt in _alternativeRoutePoints)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: alt,
                        strokeWidth: 4.5,
                        color: const Color(0xFF94A3B8).withValues(alpha: 0.65),
                      ),
                    ],
                  ),

              // Google Maps Signature 3D Navigation Route Polylines (Shortest Route)
              if (_isShowingRoute && _routePoints.isNotEmpty) ...[
                // Outer Deep Blue Casing / Shadow Line
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 8.0,
                      color: const Color(0xFF1D4ED8).withValues(alpha: 0.95),
                    ),
                  ],
                ),
                // Main Google Maps Vibrant Blue Line
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5.5,
                      color: const Color(0xFF2563EB),
                    ),
                  ],
                ),
                // Inner Highlight Core Line
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 2.2,
                      color: const Color(0xFF93C5FD),
                    ),
                  ],
                ),
              ],

              // Polyline connecting main property to selected POI
              if (_activePoiCoord != null && !_isShowingRoute)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [widget.center, _activePoiCoord!],
                      strokeWidth: 3.5,
                      color: const Color(0xFF1677FF),
                    ),
                  ],
                ),

              // Radius Circles (Walk or Motorbike mode)
              if (_radiusMode == 1)
                CircleLayer(
                  circles: [
                    // 1000m (1km) circle - ~12 min walk
                    CircleMarker(
                      point: widget.center,
                      radius: 1000,
                      useRadiusInMeter: true,
                      color: const Color(0xFF1677FF).withValues(alpha: 0.04),
                      borderColor: const Color(0xFF1677FF).withValues(alpha: 0.25),
                      borderStrokeWidth: 1.2,
                    ),
                    // 500m circle - ~6 min walk
                    CircleMarker(
                      point: widget.center,
                      radius: 500,
                      useRadiusInMeter: true,
                      color: const Color(0xFF69B1FF).withValues(alpha: 0.12),
                      borderColor: const Color(0xFF1677FF).withValues(alpha: 0.55),
                      borderStrokeWidth: 1.8,
                    ),
                  ],
                )
              else if (_radiusMode == 2)
                CircleLayer(
                  circles: [
                    // 5000m (5km) circle - ~12 min motorbike
                    CircleMarker(
                      point: widget.center,
                      radius: 5000,
                      useRadiusInMeter: true,
                      color: const Color(0xFF1677FF).withValues(alpha: 0.03),
                      borderColor: const Color(0xFF1677FF).withValues(alpha: 0.20),
                      borderStrokeWidth: 1.2,
                    ),
                    // 2000m (2km) circle - ~5 min motorbike
                    CircleMarker(
                      point: widget.center,
                      radius: 2000,
                      useRadiusInMeter: true,
                      color: const Color(0xFF69B1FF).withValues(alpha: 0.09),
                      borderColor: const Color(0xFF1677FF).withValues(alpha: 0.50),
                      borderStrokeWidth: 1.8,
                    ),
                  ],
                )
              else if (_radiusMode == 3)
                CircleLayer(
                  circles: [
                    // 7000m (7km) circle - ~18 min motorbike
                    CircleMarker(
                      point: widget.center,
                      radius: 7000,
                      useRadiusInMeter: true,
                      color: const Color(0xFF10B981).withValues(alpha: 0.02),
                      borderColor: const Color(0xFF10B981).withValues(alpha: 0.20),
                      borderStrokeWidth: 1.2,
                    ),
                    // 3000m (3km) circle - ~7 min motorbike
                    CircleMarker(
                      point: widget.center,
                      radius: 3000,
                      useRadiusInMeter: true,
                      color: const Color(0xFF10B981).withValues(alpha: 0.06),
                      borderColor: const Color(0xFF10B981).withValues(alpha: 0.45),
                      borderStrokeWidth: 1.8,
                    ),
                  ],
                ),

              // Pin Radar Ring
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: widget.center,
                    radius: 20,
                    useRadiusInMeter: false,
                    color: const Color(0xFF1677FF).withValues(alpha: 0.15),
                    borderColor: const Color(0xFF1677FF).withValues(alpha: 0.5),
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),

              // Markers Layer (Tự động xoay ngược để ghim và chữ luôn thẳng đứng khi xoay bản đồ)
              MarkerLayer(
                rotate: true,
                markers: [
                  // Similar Rooms Markers from other locations
                  ...otherMapMarkers,

                  // User GPS Location Marker (Pulsating Dot with Direction Indicator)
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1677FF).withValues(alpha: 0.22),
                            ),
                          ),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF1677FF),
                              border: Border.all(color: Colors.white, width: 3.5),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 6),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                CupertinoIcons.location_north_fill,
                                color: Colors.white,
                                size: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Active POI Marker (Minimalist Origin Indicator that doesn't blot out map tile text)
                  if (_activePoiCoord != null)
                    Marker(
                      point: _activePoiCoord!,
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1677FF), width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1677FF).withValues(alpha: 0.35),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1677FF),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Ambient Map POI Markers (Interactive icon pins directly on map canvas)
                  if (_showMapPoiIcons)
                    ..._buildAmbientPoiMarkers(),

                  // Main Room Location (Unibody Teardrop Pin - Mũi ghim cắm chính xác vào toạ độ phòng và khớp 100% với điểm kết thúc chỉ đường)
                  Marker(
                    point: widget.center,
                    width: 120,
                    height: 78,
                    alignment: Alignment.topCenter,
                    child: _UnibodyMainPin(title: widget.title),
                  ),
                ],
              ),
            ],
          ),

          // 2. Unified Liquid Glass Top Header
          Positioned(
            top: topPadding + 10,
            left: 16,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Address & Actions Row
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_isShowingRoute || _userLocation != null) {
                              _clearAllNavigation();
                            } else {
                              Navigator.of(context).pop();
                            }
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 4),
                              ],
                            ),
                            child: const Icon(
                              CupertinoIcons.back,
                              color: AppTheme.kTextPrimary,
                              size: 19,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Tap Address to Copy
                        Expanded(
                          child: GestureDetector(
                            onTap: _copyAddressToClipboard,
                            child: Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.placemark_fill,
                                  color: Color(0xFF1677FF),
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    widget.title,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.kTextPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Street View 360 Button
                        GestureDetector(
                          onTap: _openGoogleStreetView,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6.5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.streetview_rounded,
                                  color: Color(0xFF1677FF),
                                  size: 14,
                                ),
                                SizedBox(width: 3.5),
                                Text(
                                  '360°',
                                  style: TextStyle(
                                    color: Color(0xFF1677FF),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        // Share Location Button
                        Tooltip(
                          message: 'Chia sẻ toạ độ vị trí phòng',
                          child: GestureDetector(
                            onTap: _shareLocation,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: const Center(
                                child: Icon(
                                  CupertinoIcons.share,
                                  color: Color(0xFF1677FF),
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        // Directions Button
                        GestureDetector(
                          onTap: _openDirectionsInGoogleMaps,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6.5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1677FF),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1677FF)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.arrow_turn_up_right,
                                  color: Colors.white,
                                  size: 13,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Chỉ đường',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Embedded Amenities & Category Filter (Tự động thu gọn khi đang xem lộ trình chỉ đường)
                    if (_effectivePois.isNotEmpty && !_isShowingRoute) ...[
                      const SizedBox(height: 8),
                      // 1. POI Category Selector Row
                      SizedBox(
                        height: 26,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _buildCategoryChip('all', 'Tất cả', CupertinoIcons.square_grid_2x2_fill),
                            const SizedBox(width: 6),
                            _buildCategoryChip('school', 'Trường học', CupertinoIcons.book_fill),
                            const SizedBox(width: 6),
                            _buildCategoryChip('shop', 'Chợ & Tiện ích', CupertinoIcons.cart_fill),
                            const SizedBox(width: 6),
                            _buildCategoryChip('transit', 'Giao thông', CupertinoIcons.bus),
                            const SizedBox(width: 6),
                            _buildCategoryChip('food', 'Ăn uống', Icons.local_cafe_rounded),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 2. Filtered Amenities Horizontal Strip
                      SizedBox(
                        height: 34,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: _filteredPois.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (_, i) {
                            final poiItem = _filteredPois[i];
                            final originalIndex = _effectivePois.indexOf(poiItem);
                            return _PoiChip(
                              label: _cleanPoiName(poiItem),
                              distance: _getPoiDisplayDistance(poiItem, originalIndex >= 0 ? originalIndex : i),
                              isSelected: _selectedPoiIndex == originalIndex,
                              onTap: () => _onTapPoi(originalIndex >= 0 ? originalIndex : i, poiItem),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // 3. Google Maps Style Directions HUD Banner (When route is active)
          if (_isShowingRoute && _routePoints.isNotEmpty)
            Positioned(
              top: topPadding + 74,
              left: 16,
              right: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      // Mode Icon
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1677FF).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _activePoiName != null
                              ? _getPoiIcon(_activePoiName!)
                              : (_routeIsWalking
                                  ? Icons.directions_walk_rounded
                                  : Icons.two_wheeler_rounded),
                          color: const Color(0xFF1677FF),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '~${_routeDurationMin ?? 0} phút',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _routeDistanceKm != null &&
                                          _routeDistanceKm! < 1.0
                                      ? '(${(_routeDistanceKm! * 1000).toInt()} m)'
                                      : '(${_routeDistanceKm?.toStringAsFixed(1) ?? "0"} km)',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              _routeTitle != null
                                  ? 'Từ ${_cleanPoiName(_routeTitle!)} đến phòng'
                                  : (_activePoiName != null
                                      ? 'Từ ${_cleanPoiName(_activePoiName!)} đến phòng'
                                      : (_routeIsWalking
                                          ? 'Tuyến đường đi bộ ngắn nhất'
                                          : 'Tuyến đường ngắn nhất (${_routeDistanceKm?.toStringAsFixed(1)} km)')),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Switch Transit Mode
                      GestureDetector(
                        onTap: () {
                          final startPoint = _activePoiCoord ?? _userLocation;
                          if (startPoint != null) {
                            _fetchRoute(
                              startPoint,
                              widget.center,
                              isWalking: !_routeIsWalking,
                              routeTitle: _activePoiName,
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _routeIsWalking ? Icons.two_wheeler_rounded : Icons.directions_walk_rounded,
                                size: 14,
                                color: const Color(0xFF1677FF),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                _routeIsWalking ? 'Xe máy' : 'Đi bộ',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1677FF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Open Route in Google Maps Native
                      Tooltip(
                        message: 'Mở chỉ đường trên Google Maps',
                        child: GestureDetector(
                          onTap: _openDirectionsInGoogleMaps,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1677FF).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF1677FF).withValues(alpha: 0.4),
                                width: 1.0,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                CupertinoIcons.arrow_turn_up_right,
                                size: 14,
                                color: Color(0xFF1677FF),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Prominent Circular Exit Route Button (Never clipped)
                      GestureDetector(
                        onTap: _clearAllNavigation,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.45),
                              width: 1.2,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              CupertinoIcons.xmark,
                              size: 14,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          // Normal Notification Toast Banner (When no active route)
          else if (_poiNotification != null)
            Positioned(
              top: topPadding + (widget.pois.isNotEmpty ? 134 : 86),
              left: 20,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.compass_fill,
                        color: Color(0xFF1677FF),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _poiNotification!,
                          style: const TextStyle(
                            color: AppTheme.kTextPrimary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _poiNotification = null),
                        child: const Icon(
                          CupertinoIcons.xmark_circle_fill,
                          color: Color(0xFF94A3B8),
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 4. Zoom Controls (Top-Right Floating Liquid Glass Dock - Auto shifts to never overlap)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            right: 16,
            top: topPadding + (_isShowingRoute ? 142 : (_effectivePois.isNotEmpty ? 172 : 82)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _zoomIn,
                      child: Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.plus,
                          size: 18,
                          color: AppTheme.kTextPrimary,
                        ),
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 1,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: const Color(0xFFCBD5E1).withValues(alpha: 0.5),
                    ),
                    GestureDetector(
                      onTap: _zoomOut,
                      child: Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.minus,
                          size: 18,
                          color: AppTheme.kTextPrimary,
                        ),
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 1,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: const Color(0xFFCBD5E1).withValues(alpha: 0.5),
                    ),
                    // Compass Reset North Button
                    Tooltip(
                      message: 'Xoay về hướng Bắc chuẩn',
                      child: GestureDetector(
                        onTap: () {
                          _mapController.rotate(0.0);
                          setState(() {
                            _poiNotification = 'Đã xoay bản đồ về hướng Bắc chuẩn (0°)';
                          });
                          Future.delayed(const Duration(seconds: 2), () {
                            if (mounted && _poiNotification == 'Đã xoay bản đồ về hướng Bắc chuẩn (0°)') {
                              setState(() => _poiNotification = null);
                            }
                          });
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.compass,
                            size: 19,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5. Floating Bottom-Right Action Dock (Animated Position)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            right: 16,
            bottom: bottomBarOffset,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Street View 360 Panoramic Button (Google Street View)
                _MapActionButton(
                  icon: Icons.streetview_rounded,
                  isActive: false,
                  tooltip: 'Xem ảnh ngõ & góc phố 360° (Street View)',
                  onTap: _openGoogleStreetView,
                ),
                const SizedBox(height: 10),

                // 2. Toggle Ambient Map POI Pins
                _MapActionButton(
                  icon: _showMapPoiIcons ? Icons.pin_drop_rounded : Icons.pin_drop_outlined,
                  isActive: _showMapPoiIcons,
                  tooltip: _showMapPoiIcons ? 'Ẩn ghim tiện ích trên bản đồ' : 'Hiện ghim tiện ích trên bản đồ',
                  onTap: () {
                    setState(() {
                      _showMapPoiIcons = !_showMapPoiIcons;
                    });
                  },
                ),
                const SizedBox(height: 10),

                // 3. Satellite Mode Toggle
                _MapActionButton(
                  icon: _isSatelliteMode
                      ? Icons.map_rounded
                      : Icons.satellite_alt_rounded,
                  isActive: _isSatelliteMode,
                  tooltip: _isSatelliteMode ? 'Bản đồ phố' : 'Bản đồ vệ tinh',
                  onTap: () {
                    setState(() {
                      _isSatelliteMode = !_isSatelliteMode;
                    });
                  },
                ),
                const SizedBox(height: 10),

                // 4. GPS My Location & Navigation Route Trigger (Toggle On/Off)
                _MapActionButton(
                  icon: Icons.my_location_rounded,
                  isActive: _userLocation != null || _isShowingRoute,
                  isLoading: _isLocatingUser,
                  tooltip: (_userLocation != null || _isShowingRoute)
                      ? 'Thoát định vị & chỉ đường'
                      : 'Chỉ đường từ vị trí của tôi',
                  onTap: _onToggleGps,
                ),
                const SizedBox(height: 10),

                // 5. Recenter to Property Button
                _MapActionButton(
                  icon: CupertinoIcons.location_fill,
                  isActive: false,
                  tooltip: 'Về vị trí phòng',
                  onTap: _recenterToMain,
                ),
                const SizedBox(height: 10),

                // 6. Commute Radius Mode Toggle (Walking / Motorbike / Max / Off)
                _MapActionButton(
                  icon: _radiusMode == 3
                      ? Icons.bolt_rounded
                      : (_radiusMode == 2
                          ? Icons.two_wheeler_rounded
                          : Icons.directions_walk_rounded),
                  isActive: _radiusMode > 0,
                  tooltip: _radiusMode == 1
                      ? 'Đi bộ: 500m & 1km'
                      : (_radiusMode == 2
                          ? 'Xe máy: 2km & 5km'
                          : (_radiusMode == 3 ? 'Phạm vi tối đa: 3km & 7km' : 'Tắt bán kính')),
                  onTap: _cycleRadiusMode,
                ),
              ],
            ),
          ),

          // 6. Radius Mode Badge (Walking or Motorbike) aligned with bottom button
          if (_radiusMode > 0 && !_isShowingRoute)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              right: 68,
              bottom: bottomBarOffset + 8,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _radiusMode == 3
                            ? Icons.bolt_rounded
                            : (_radiusMode == 2
                                ? Icons.two_wheeler_rounded
                                : Icons.directions_walk_rounded),
                        size: 14,
                        color: _radiusMode == 3
                            ? const Color(0xFF10B981)
                            : const Color(0xFF1677FF),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _radiusMode == 3
                            ? '⚡ 3km (~7p) • 7km (~18p)'
                            : (_radiusMode == 2
                                ? '🛵 2km (~5p) • 5km (~12p)'
                                : '🚶 500m (~6p) • 1km (~12p)'),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 7. Dynamic Map Scale Bar (Bottom-Left)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            left: 16,
            bottom: bottomBarOffset + 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 3,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1677FF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      '100 m',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 8. Bottom Carousel: Collapsible Similar Rooms Platter
          if (widget.similarRooms.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.only(top: 6, bottom: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header & Price Filters with Collapse/Expand Button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: GlassCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            child: Row(
                              children: [
                                // Collapse / Expand Chevron Button
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isCarouselCollapsed = !_isCarouselCollapsed;
                                    });
                                  },
                                  child: Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _isCarouselCollapsed
                                          ? CupertinoIcons.chevron_up
                                          : CupertinoIcons.chevron_down,
                                      size: 13,
                                      color: AppTheme.kTextPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  'Lân cận (${filteredRooms.length})',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.kTextPrimary,
                                  ),
                                ),
                                const Spacer(),
                                // Quick Filter Chips
                                _PriceFilterChip(
                                  label: 'Tất cả',
                                  isSelected: _priceFilter == 0,
                                  onTap: () => setState(() => _priceFilter = 0),
                                ),
                                const SizedBox(width: 4),
                                _PriceFilterChip(
                                  label: '< 4Tr',
                                  isSelected: _priceFilter == 1,
                                  onTap: () => setState(() => _priceFilter = 1),
                                ),
                                const SizedBox(width: 4),
                                _PriceFilterChip(
                                  label: '4-6Tr',
                                  isSelected: _priceFilter == 2,
                                  onTap: () => setState(() => _priceFilter = 2),
                                ),
                                const SizedBox(width: 4),
                                _PriceFilterChip(
                                  label: '> 6Tr',
                                  isSelected: _priceFilter == 3,
                                  onTap: () => setState(() => _priceFilter = 3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Animated Collapsible Cards List
                      AnimatedCrossFade(
                        firstChild: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: SizedBox(
                            height: 124,
                            child: filteredRooms.isEmpty
                                ? Center(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: const GlassCard(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          'Không có phòng nào trong mức giá này',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    controller: _roomsScrollController,
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 16),
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    clipBehavior: Clip.none,
                                    itemCount: filteredRooms.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 12),
                                    itemBuilder: (_, i) {
                                      final r = filteredRooms[i];
                                      final img = _firstImageOf(r);
                                      final priceMil =
                                          r['_priceMillion'] as double;
                                      final title = (r['postTitle'] ??
                                              r['title'] ??
                                              r['roomName'] ??
                                              '')
                                          .toString();
                                      final origIndex =
                                          r['_originalIndex'] as int;

                                      return GestureDetector(
                                        onTap: () {
                                          final lat = r['_parsedLat'] as double?;
                                          final lng = r['_parsedLng'] as double?;
                                          if (lat != null && lng != null) {
                                            _focusRoom(origIndex, LatLng(lat, lng));
                                          } else {
                                            _openRoomDetail(r);
                                          }
                                        },
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(24),
                                          child: GlassCard(
                                            padding: const EdgeInsets.all(8),
                                            child: SizedBox(
                                              width: 250,
                                              child: Row(
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(16),
                                                    child: img != null &&
                                                            img.isNotEmpty
                                                        ? CachedNetworkImage(
                                                            imageUrl:
                                                                ImageUrlHelper
                                                                        .buildUrl(
                                                                            img) ??
                                                                    img,
                                                            width: 90,
                                                            height: 106,
                                                            fit: BoxFit.cover,
                                                            errorWidget:
                                                                (_, __, ___) =>
                                                                    _buildFallbackImage(),
                                                          )
                                                        : _buildFallbackImage(),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.center,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          title,
                                                          style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 13,
                                                            color: AppTheme
                                                                .kTextPrimary,
                                                            height: 1.25,
                                                          ),
                                                          maxLines: 2,
                                                          overflow:
                                                              TextOverflow.ellipsis,
                                                        ),
                                                        const SizedBox(height: 4),
                                                        // Informative Quick Tags
                                                        _buildRoomTags(r),
                                                        const SizedBox(height: 5),
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                priceMil > 0
                                                                    ? '${priceMil.toStringAsFixed(1)} Tr/tháng'
                                                                    : 'Thoả thuận',
                                                                style: const TextStyle(
                                                                  color:
                                                                      Color(0xFF1677FF),
                                                                  fontWeight:
                                                                      FontWeight.w700,
                                                                  fontSize: 12.5,
                                                                ),
                                                              ),
                                                            ),
                                                            // Quick Action Contact Icon
                                                            GestureDetector(
                                                              onTap: () => _openRoomDetail(r),
                                                              child: Container(
                                                                width: 26,
                                                                height: 26,
                                                                decoration: BoxDecoration(
                                                                  color: const Color(0xFF1677FF).withValues(alpha: 0.12),
                                                                  shape: BoxShape.circle,
                                                                ),
                                                                child: const Icon(
                                                                  CupertinoIcons.chat_bubble_fill,
                                                                  size: 13,
                                                                  color: Color(0xFF1677FF),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                        secondChild: const SizedBox.shrink(),
                        crossFadeState: _isCarouselCollapsed
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 250),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }

  List<Marker> _buildAmbientPoiMarkers() {
    final markers = <Marker>[];
    for (int i = 0; i < _effectivePois.length; i++) {
      if (_selectedPoiIndex == i) continue;
      final poiText = _effectivePois[i];
      final cat = _getPoiCategory(poiText);
      if (_poiCategoryFilter != 'all' && cat != _poiCategoryFilter) continue;
      final poiCoord = _resolvePoiCoordinate(poiText);
      if (poiCoord == null) continue; // Chỉ vẽ ghim khi có toạ độ thực tế, không vẽ ghim ảo sai vị trí!
      final icon = _getPoiIcon(poiText);
      final cleanName = _cleanPoiName(poiText);

      markers.add(
        Marker(
          point: poiCoord,
          width: 80,
          height: 48,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => _onTapPoi(i, poiText),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF1677FF).withValues(alpha: 0.35),
                      width: 0.8,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    cleanName,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 1.5),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF1677FF), width: 1.8),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: 12,
                      color: const Color(0xFF1677FF),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return markers;
  }

  Widget _buildFallbackImage() {
    return Container(
      width: 90,
      height: 106,
      color: const Color(0xFFF1F5F9).withValues(alpha: 0.8),
      child: const Icon(
        CupertinoIcons.house_alt,
        color: Color(0xFF94A3B8),
        size: 26,
      ),
    );
  }
}

/// Helper to get POI icon
IconData _getPoiIcon(String label) {
  final lower = label.toLowerCase();
  if (lower.contains('đại học') || lower.contains('trường') || lower.contains('học viện') || lower.contains('school')) {
    return CupertinoIcons.book_fill;
  } else if (lower.contains('circle') || lower.contains('siêu thị') || lower.contains('mart') || lower.contains('chợ')) {
    return CupertinoIcons.cart_fill;
  } else if (lower.contains('xe buýt') || lower.contains('bus') || lower.contains('bến xe') || lower.contains('ga')) {
    return CupertinoIcons.bus;
  } else if (lower.contains('công viên') || lower.contains('park') || lower.contains('hồ')) {
    return Icons.park_rounded;
  } else if (lower.contains('bệnh viện') || lower.contains('y tế') || lower.contains('viện')) {
    return Icons.local_hospital_rounded;
  } else if (lower.contains('cà phê') || lower.contains('cafe')) {
    return Icons.local_cafe_rounded;
  }
  return CupertinoIcons.placemark_fill;
}

/// Unibody Main Property Pin (Integrated luxury teardrop pin with precise tip)
class _UnibodyMainPin extends StatelessWidget {
  final String title;

  const _UnibodyMainPin({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Top Pill Label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1677FF).withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.house_fill,
                size: 11,
                color: Color(0xFF1677FF),
              ),
              SizedBox(width: 3.5),
              Text(
                'Vị trí phòng',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1677FF),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),

        // Unibody Pin Head & Arrow
        SizedBox(
          width: 44,
          height: 48,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              // Pin Circle Head
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF69B1FF), Color(0xFF1677FF)],
                  ),
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1677FF).withValues(alpha: 0.45),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    CupertinoIcons.house_fill,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              // Pointer Needle Tip
              Positioned(
                bottom: 0,
                child: CustomPaint(
                  size: const Size(10, 8),
                  painter: _PinArrowPainter(
                    color: const Color(0xFF1677FF),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Ground Contact Shadow Dot
        Container(
          width: 10,
          height: 3,
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    );
  }
}

/// Floating Action Button for Map Controls (Using Genuine Liquid Glass)
class _MapActionButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final bool isLoading;
  final String tooltip;
  final VoidCallback onTap;

  const _MapActionButton({
    required this.icon,
    required this.isActive,
    this.isLoading = false,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: ClipOval(
          child: GlassCard(
            padding: EdgeInsets.zero,
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              color: isActive
                  ? const Color(0xFF1677FF).withValues(alpha: 0.88)
                  : Colors.white.withValues(alpha: 0.25),
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF1677FF)),
                      ),
                    )
                  : Icon(
                      icon,
                      color: isActive ? Colors.white : const Color(0xFF1677FF),
                      size: 20,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small Price Filter Chip (Frosted Platter Style)
class _PriceFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PriceFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1677FF)
              : Colors.white.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.7),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF1677FF).withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}

/// Floating Amenities (POIs) Chip with high contrast, colorful category icon, and distance badge
class _PoiChip extends StatelessWidget {
  final String label;
  final String? distance;
  final bool isSelected;
  final VoidCallback onTap;

  const _PoiChip({
    required this.label,
    this.distance,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = _getPoiIcon(label);
    final lower = label.toLowerCase();
    Color iconColor = const Color(0xFF0284C7);

    if (lower.contains('đại học') || lower.contains('trường') || lower.contains('học viện') || lower.contains('school')) {
      iconColor = const Color(0xFF4F46E5);
    } else if (lower.contains('circle') || lower.contains('siêu thị') || lower.contains('mart') || lower.contains('chợ')) {
      iconColor = const Color(0xFF0D9488);
    } else if (lower.contains('xe buýt') || lower.contains('bus') || lower.contains('bến xe') || lower.contains('ga')) {
      iconColor = const Color(0xFF2563EB);
    } else if (lower.contains('công viên') || lower.contains('park') || lower.contains('hồ')) {
      iconColor = const Color(0xFF16A34A);
    } else if (lower.contains('bệnh viện') || lower.contains('y tế') || lower.contains('viện')) {
      iconColor = const Color(0xFFDC2626);
    } else if (lower.contains('cà phê') || lower.contains('cafe')) {
      iconColor = const Color(0xFFD97706);
    }

    String name = label;
    String? distText = distance;
    if (distText == null) {
      final match = RegExp(r'^(.*?)\s*\((.*?)\)$').firstMatch(label);
      if (match != null) {
        name = match.group(1)?.trim() ?? label;
        distText = match.group(2)?.trim();
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1677FF).withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1677FF)
                : Colors.white.withValues(alpha: 0.8),
            width: isSelected ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF69B1FF).withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, size: 13, color: iconColor),
            const SizedBox(width: 5),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF1677FF)
                    : const Color(0xFF1E293B),
              ),
            ),
            if (distText != null && distText.isNotEmpty) ...[
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF1677FF)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  distText,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF1D4ED8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small triangular pointer for pins
class _PinArrowPainter extends CustomPainter {
  final Color color;
  final Color? borderColor;

  _PinArrowPainter({required this.color, this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    if (borderColor != null) {
      final borderPaint = Paint()
        ..color = borderColor!
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PinArrowPainter oldDelegate) =>
      color != oldDelegate.color || borderColor != oldDelegate.borderColor;
}
