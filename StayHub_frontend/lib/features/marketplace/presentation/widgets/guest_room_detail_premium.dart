import 'dart:async' show unawaited;
import 'dart:convert';
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData, HapticFeedback;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/room_type_codes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/osm_map_service.dart';
import '../../../../core/services/recently_viewed_service.dart';
import '../../../../core/services/wishlist_service.dart';
import '../../application/wishlist_provider.dart';
import '../../../../core/utils/image_url_helper.dart';
import '../../../../core/utils/toast_utils.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../../auth/presentation/widgets/guest_auth_bottom_sheet.dart';
import '../../../chat/application/conversation_provider.dart';
import '../../../chat/presentation/thread_message_screen.dart';
import '../../../shared/presentation/widgets/full_screen_media_viewer.dart';
import '../../../shared/presentation/widgets/full_screen_map_viewer.dart';
import '../../data/booking_request_provider.dart';

/// Trang chi tiết phòng (Liquid Glass).
///
/// NGUYÊN TẮC: chỉ hiển thị DỮ LIỆU THẬT từ backend
/// (`GET /v1/rooms/public/{id}` → MarketplacePostDTO, reviews, search).
/// Không có dữ liệu → ẩn section / hiển thị "Chưa cập nhật", TUYỆT ĐỐI không
/// bịa số liệu (rating, chủ nhà, chi phí, tiện ích, POI, ảnh mẫu...).
class GuestRoomDetailPremiumBottomSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> room;
  final int? roomId;
  final ScrollController scrollController;
  final bool isFullScreen;
  final bool isPreview;

  const GuestRoomDetailPremiumBottomSheet({
    super.key,
    required this.room,
    this.roomId,
    required this.scrollController,
    this.isFullScreen = false,
    this.isPreview = false,
  });

  @override
  ConsumerState<GuestRoomDetailPremiumBottomSheet> createState() =>
      _GuestRoomDetailPremiumBottomSheetState();
}

// ── Bảng nhãn (mã canonical từ wizard cấu hình phòng → nhãn tiếng Việt) ──
const Map<String, String> _kFurnitureLabels = {
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
  'WIFI': 'Wifi',
  'CUA_SO': 'Cửa sổ',
  'BAN_CONG': 'Ban công',
  'GAC_LUNG': 'Gác lửng',
  'WC': 'Vệ sinh riêng',
};

const Map<String, String> _kPhotoGroupLabels = {
  'ROOM': 'Phòng',
  'MEZZANINE': 'Gác lửng',
  'BALCONY': 'Ban công',
  'WINDOW': 'Cửa sổ',
  'KITCHEN': 'Bếp',
  'WC': 'Nhà vệ sinh',
  'ELECTRIC_METER': 'Đồng hồ điện',
  'WATER_METER': 'Đồng hồ nước',
};

const Map<String, String> _kDirectionLabels = {
  'DONG': 'Đông',
  'TAY': 'Tây',
  'NAM': 'Nam',
  'BAC': 'Bắc',
  'DONG_NAM': 'Đông Nam',
  'DONG_BAC': 'Đông Bắc',
  'TAY_NAM': 'Tây Nam',
  'TAY_BAC': 'Tây Bắc',
};

class _GalleryImage {
  final String url;
  final String label;
  const _GalleryImage(this.url, this.label);
}

class _FeeRow {
  final String icon;
  final String title;
  final String value;
  const _FeeRow(this.icon, this.title, this.value);
}

class _GuestRoomDetailPremiumBottomSheetState
    extends ConsumerState<GuestRoomDetailPremiumBottomSheet>
    with SingleTickerProviderStateMixin {
  static const _kBrand = Color(0xFF69B1FF);
  static const _kText = Color(0xFF1E293B);
  static const _kSurface = Color(0xFFF9FAFB);
  static const _kShadow = [
    BoxShadow(
      color: Color(0x1469B1FF),
      offset: Offset(0, 8),
      blurRadius: 24,
    ),
  ];

  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  // Hiệu ứng chuyển cảnh xem ảnh toàn màn hình đẳng cấp:
  // Khoảng trắng (thông tin phòng) tụt xuống, ảnh tụt về giữa màn hình
  late final AnimationController _viewerSlideController;
  late final Animation<double> _viewerSlideCurved;

  Map<String, dynamic>? _resolvedRoom;
  bool _isLoading = false;
  bool _loadFailed = false;

  bool _isWishlisted = false;
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _similarRooms = [];

  final _money = NumberFormat.decimalPattern('vi_VN');

  // All-In Living Cost Calculator state
  int _calcGuests = 1;
  int _calcMotorbikes = 1;
  int _calcAcHours = 8;

  Map<String, dynamic> get _room => _resolvedRoom ?? widget.room;

  // ══════════════════════════════════════════════════════════════════
  // Data loading
  // ══════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _viewerSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 320),
    );
    _viewerSlideCurved = CurvedAnimation(
      parent: _viewerSlideController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final id = widget.roomId ?? widget.room['id'];
    // Dữ liệu feed/wishlist/lịch sử thường KHÔNG đầy đủ (thiếu detailedInfo,
    // branchAmenities...) → luôn lấy bản đầy đủ từ API khi có id.
    final isPartial = widget.room['detailedInfo'] == null ||
        (widget.room['roomImages'] == null &&
            widget.room['images'] == null &&
            widget.room['postImages'] == null);
    if (id != null && !widget.isPreview && (widget.room.isEmpty || isPartial)) {
      _isLoading = widget.room.isEmpty;
      unawaited(_fetchRoomDetails(id));
    } else {
      _afterRoomLoaded();
    }
  }

  Future<void> _fetchRoomDetails(dynamic id) async {
    try {
      final res = await ApiClient().dio.get('/v1/rooms/public/$id');
      final data = res.data;
      Map<String, dynamic>? room;
      if (data is Map && data['data'] is Map) {
        room = Map<String, dynamic>.from(data['data'] as Map);
      } else if (data is Map) {
        room = Map<String, dynamic>.from(data);
      }
      if (!mounted) return;
      setState(() {
        if (room != null && room.isNotEmpty) {
          // Giữ lại field caller đã truyền (vd `branch`) nếu API không trả.
          _resolvedRoom = {...widget.room, ...room};
        }
        _isLoading = false;
        _loadFailed = room == null && widget.room.isEmpty;
      });
    } catch (e) {
      debugPrint('Room detail fetch failed: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadFailed = widget.room.isEmpty;
      });
    }
    _afterRoomLoaded();
  }

  void _afterRoomLoaded() {
    final id = _room['id']?.toString();
    if (id == null || id.isEmpty || widget.isPreview) return;
    unawaited(RecentlyViewedService.addRoom(id));
    unawaited(_checkWishlist());
    unawaited(_fetchReviews(id));
    unawaited(_fetchSimilarRooms());
  }

  Future<void> _checkWishlist() async {
    try {
      final user = ref.read(authProvider).value;
      final client = ref.read(apiClientProvider);
      final inList = await WishlistService.isInWishlist(
        _room,
        user?.id.toString(),
        client: user != null ? client : null,
      );
      if (mounted) setState(() => _isWishlisted = inList);
    } catch (_) {}
  }

  Future<void> _fetchReviews(String roomId) async {
    try {
      final res = await ApiClient().dio.get('/v1/reviews/room/$roomId');
      final data = res.data;
      final list = data is Map ? data['data'] : data;
      if (list is List && mounted) {
        setState(() {
          _reviews = list
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        });
      }
    } catch (_) {
      // Không có đánh giá → section ẩn, không bịa số liệu.
    }
  }

  Future<void> _fetchSimilarRooms() async {
    try {
      final price = _price;
      final params = <String, dynamic>{'page': 0, 'size': 10};
      if (price > 0) {
        params['minPrice'] = (price * 0.7).roundToDouble();
        params['maxPrice'] = (price * 1.3).roundToDouble();
      }
      final res = await ApiClient()
          .dio
          .get('/v1/rooms/public/search', queryParameters: params);
      final data = res.data;
      final page = data is Map ? data['data'] : null;
      final content = page is Map ? page['content'] : null;
      if (content is List && mounted) {
        final currentId = _room['id']?.toString();
        setState(() {
          _similarRooms = content
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .where((r) => r['id']?.toString() != currentId)
              .take(8)
              .toList();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pageController.dispose();
    _viewerSlideController.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════
  // Parsing helpers (real data only)
  // ══════════════════════════════════════════════════════════════════

  Map<String, dynamic> get _info {
    final raw = _room['detailedInfo'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.trim().startsWith('{')) {
      try {
        final d = jsonDecode(raw);
        if (d is Map) return Map<String, dynamic>.from(d);
      } catch (_) {}
    }
    return {};
  }

  Map<String, dynamic> get _branch {
    final raw = _room['branch'];
    return raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
  }

  /// Đọc giá trị theo thứ tự ưu tiên: room → detailedInfo → branch.
  dynamic _pick(List<String> keys) {
    final info = _info;
    final branch = _branch;
    for (final k in keys) {
      final v = _room[k] ?? info[k] ?? branch[k];
      if (v != null && v.toString().trim().isNotEmpty) return v;
    }
    return null;
  }

  double _num(List<String> keys) =>
      double.tryParse(_pick(keys)?.toString() ?? '') ?? 0;

  bool? _bool(List<String> keys) {
    final v = _pick(keys);
    if (v == null) return null;
    if (v is bool) return v;
    final s = v.toString().toLowerCase();
    if (s == 'true') return true;
    if (s == 'false') return false;
    return null;
  }

  String _fmtMoney(double v) => '${_money.format(v.round())}đ';

  String get _title {
    for (final v in [
      _room['postTitle'],
      _room['post'] is Map ? _room['post']['title'] : null,
      _room['title'],
      _room['roomName'],
      _room['name'],
    ]) {
      if (v != null && v.toString().trim().isNotEmpty) {
        return v.toString().trim();
      }
    }
    return 'Phòng cho thuê';
  }

  String get _roomTypeLabel {
    final raw = (_room['roomType'] ??
            _room['roomSubType'] ??
            _info['roomType'] ??
            '')
        .toString();
    return raw.isEmpty ? '' : RoomTypeCodes.labelOf(raw);
  }

  /// Địa chỉ hiển thị (Presentation layer → chuẩn 4 cấp `addressOld`).
  String get _address {
    final raw = (_room['addressOld'] ??
            _room['address'] ??
            _room['branchAddress'] ??
            _branch['addressOld'] ??
            _branch['address'] ??
            '')
        .toString()
        .trim();
    if (raw.isEmpty) return '';
    final loggedIn = ref.read(authProvider).value != null;
    if (loggedIn) return raw;
    // Bảo mật: khách chưa đăng nhập không thấy số nhà.
    return raw.replaceFirst(
      RegExp(r'^(Số\s*)?[0-9A-Za-z/\-]+\s*,?\s*'),
      '***, ',
    );
  }

  double get _price {
    final promo = double.tryParse(_room['promotionPrice']?.toString() ?? '');
    if (_room['hasPromotion'] == true && promo != null && promo > 0) {
      return promo;
    }
    return _num(['price']);
  }

  double get _originalPrice => _num(['originalPrice', 'price']);

  // ── Ảnh: roomImages (ảnh chính) + featurePhotos có nhãn nhóm ──
  List<_GalleryImage> get _gallery {
    final result = <_GalleryImage>[];
    final seen = <String>{};

    void add(dynamic item, String label) {
      String raw;
      String itemLabel = label;
      if (item is Map) {
        raw = (item['url'] ?? item['imageUrl'] ?? item['path'] ?? '').toString();
        final l = (item['label'] ?? item['description'] ?? item['tag'] ?? '')
            .toString();
        if (l.isNotEmpty) itemLabel = l;
      } else {
        raw = item?.toString() ?? '';
      }
      raw = raw.trim().replaceAll('"', '');
      if (raw.isEmpty) return;
      final url = ImageUrlHelper.buildUrl(raw) ?? '';
      if (url.isEmpty || seen.contains(url)) return;
      seen.add(url);
      result.add(_GalleryImage(url, itemLabel));
    }

    List<dynamic> asList(dynamic raw) {
      if (raw == null) return const [];
      if (raw is List) return raw;
      final s = raw.toString().trim();
      if (s.isEmpty) return const [];
      if (s.startsWith('[')) {
        try {
          final d = jsonDecode(s);
          if (d is List) return d;
        } catch (_) {}
      }
      return s
          .replaceAll('[', '')
          .replaceAll(']', '')
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    for (final key in ['images', 'roomImages', 'postImages']) {
      for (final i in asList(_room[key])) {
        add(i, 'Phòng');
      }
    }
    for (final i in asList(_info['photos'])) {
      add(i, 'Phòng');
    }

    final fp = _info['featurePhotos'];
    if (fp is Map) {
      fp.forEach((k, v) {
        final key = k.toString();
        // Hide sensitive meter photos from public gallery
        if (key == 'ELECTRIC_METER' || key == 'WATER_METER') return;

        String label = _kPhotoGroupLabels[key] ?? '';
        if (label.isEmpty && key.startsWith('FURNITURE_')) {
          final code = key.substring('FURNITURE_'.length);
          label = _kFurnitureLabels[code] ?? code;
        }
        for (final i in asList(v)) {
          add(i, label);
        }
      });
    }

    if (result.isEmpty) {
      for (final key in ['coverImageUrl', 'firstImage', 'image']) {
        if (_room[key] != null) add(_room[key], 'Phòng');
      }
    }
    return result;
  }

  /// Ảnh phòng (ảnh chính) hiển thị ở banner đầu trang
  List<_GalleryImage> get _roomImages {
    final list = _gallery.where((img) => img.label == 'Phòng').toList();
    if (list.isEmpty && _gallery.isNotEmpty) {
      return [_gallery.first];
    }
    return list;
  }

  /// Các ảnh tiện ích, không gian chung hiển thị ở Album dưới
  List<_GalleryImage> get _albumImages {
    return _gallery.where((img) => img.label != 'Phòng').toList();
  }

  List<String> get _furniture {
    final items = <String>[];
    final fi = _info['furnitureItems'];
    if (fi is List) {
      items.addAll(fi.map((e) => e.toString()));
    }
    final f = _room['furniture'];
    if (items.isEmpty && f != null && f.toString().trim().isNotEmpty) {
      try {
        final d = jsonDecode(f.toString());
        if (d is List) items.addAll(d.map((e) => e.toString()));
      } catch (_) {
        items.addAll(f
            .toString()
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty));
      }
    }
    return items.map((e) => _kFurnitureLabels[e] ?? e).toSet().toList();
  }

  List<Map<String, dynamic>> get _branchAmenities {
    final raw = _room['branchAmenities'] ?? _branch['branchAmenities'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((a) => (a['name'] ?? '').toString().trim().isNotEmpty)
        .toList();
  }

  /// Highlight chỉ sinh từ cờ thật trong DB — không có cờ thì không hiển thị.
  List<String> get _highlights {
    final h = <String>[];
    if (_bool(['hasWindow']) == true) h.add('Có cửa sổ');
    if (_bool(['hasBalcony']) == true) h.add('Có ban công');
    if (_bool(['hasKitchen']) == true) h.add('Có bếp riêng');
    if (_bool(['hasMezzanine']) == true || _num(['mezzanineArea']) > 0) {
      h.add('Có gác lửng');
    }
    final selfContained = _bool(['isSelfContained']);
    if (selfContained == true || _room['bathroomType'] == 'RIENG') {
      h.add('WC khép kín');
    } else if (selfContained == false ||
        _bool(['isSharedWc']) == true ||
        _room['bathroomType'] == 'CHUNG') {
      h.add('WC chung');
    }
    if (_bool(['isLiveWithLandlord']) == false) h.add('Không chung chủ');
    if (_bool(['hasCurfew']) == false) h.add('Giờ giấc tự do');
    if (_bool(['hasPrivateElectricMeter']) == true) h.add('Công tơ điện riêng');
    if (_bool(['hasPrivateWaterMeter']) == true) h.add('Đồng hồ nước riêng');
    switch (_info['petPolicy']?.toString()) {
      case 'SMALL_ONLY':
        h.add('Cho nuôi pet nhỏ');
        break;
      case 'FREE':
        h.add('Nuôi thú cưng tự do');
        break;
    }
    return h;
  }

  String _unitOf(String? type, String fallback) {
    switch ((type ?? '').toUpperCase()) {
      case 'PER_KWH':
      case 'METER':
      case 'INDEX':
        return fallback;
      case 'PER_PERSON':
      case 'PERSON':
        return 'người';
      case 'PER_ROOM':
      case 'ROOM':
        return 'phòng';
      case 'SLOT':
      case 'VEHICLE':
        return 'xe';
      case 'FIXED':
        return 'tháng';
      default:
        return fallback;
    }
  }

  double _feeFromAmenities(List<String> keywords) {
    double best = 0;
    for (final a in _branchAmenities) {
      final name = a['name'].toString().toLowerCase();
      if (!keywords.any(name.contains)) continue;
      if ((a['chargeType'] ?? 'free').toString() == 'free') continue;
      final p = double.tryParse((a['price'] ?? 0).toString()) ?? 0;
      if (p > best) best = p;
    }
    return best;
  }

  List<_FeeRow> get _fees {
    final rows = <_FeeRow>[];
    final elec = _num(['electricityPrice', 'electricPrice']);
    if (elec > 0) {
      rows.add(_FeeRow('⚡', 'Điện',
          '${_fmtMoney(elec)} / ${_unitOf(_pick(['electricityPricingType', 'elecPricingType'])?.toString(), 'kWh')}'));
    }
    final water = _num(['waterPrice']);
    if (water > 0) {
      rows.add(_FeeRow('💧', 'Nước',
          '${_fmtMoney(water)} / ${_unitOf(_pick(['waterPricingType'])?.toString(), 'm³')}'));
    }
    var internet = _num(['internetPrice', 'internetFee']);
    if (internet <= 0) internet = _feeFromAmenities(['wifi', 'internet', 'mạng']);
    if (internet > 0) {
      rows.add(_FeeRow('🌐', 'Internet', '${_fmtMoney(internet)} / phòng'));
    }
    var parking = _num(['parkingPrice', 'parkingFee']);
    if (parking <= 0) {
      parking = _feeFromAmenities(['gửi xe', 'giữ xe', 'để xe', 'đỗ xe']);
    }
    if (parking > 0) {
      rows.add(_FeeRow('🛵', 'Gửi xe', '${_fmtMoney(parking)} / xe'));
    }
    var trash = _num(['trashPrice', 'garbageFee']);
    if (trash <= 0) trash = _feeFromAmenities(['rác', 'vệ sinh', 'thu gom']);
    if (trash > 0) {
      rows.add(_FeeRow('🗑️', 'Rác / vệ sinh', '${_fmtMoney(trash)} / phòng'));
    }
    final service = _num(['serviceFee']);
    if (service > 0) {
      rows.add(_FeeRow('🛎️', 'Phí dịch vụ',
          '${_fmtMoney(service)} / ${_unitOf(_pick(['serviceFeePricingType'])?.toString(), 'phòng')}'));
    }
    final deposit = _num(['deposit', 'baseDeposit']);
    if (deposit > 0) {
      rows.add(_FeeRow('🔐', 'Tiền cọc', _fmtMoney(deposit)));
    }
    final holding = _num(['holdingDeposit']);
    if (holding > 0) {
      final refundable = _bool(['isHoldingDepositRefundable']) == true;
      rows.add(_FeeRow('📌', 'Cọc giữ chỗ',
          '${_fmtMoney(holding)}${refundable ? ' (hoàn lại)' : ''}'));
    }
    return rows;
  }

  LatLng? get _latLng {
    final lat = double.tryParse(
        (_room['latitude'] ?? _room['branchLatitude'] ?? _branch['latitude'])
                ?.toString() ??
            '');
    final lng = double.tryParse(
        (_room['longitude'] ?? _room['branchLongitude'] ?? _branch['longitude'])
                ?.toString() ??
            '');
    if (lat == null || lng == null || (lat == 0 && lng == 0)) return null;
    return LatLng(lat, lng);
  }

  List<String> get _pois {
    final raw = _room['pois'] ?? _branch['pois'];
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    final s = raw.toString().trim();
    if (s.startsWith('[')) {
      try {
        final d = jsonDecode(s);
        if (d is List) {
          return d
              .map((e) => e is Map ? (e['name'] ?? '').toString() : e.toString())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } catch (_) {}
    }
    return s
        .split(',')
        .map((e) => e.trim().replaceAll('"', ''))
        .where((e) => e.isNotEmpty)
        .toList();
  }

  double? get _avgRating {
    final ratings = _reviews
        .map((r) => double.tryParse(r['rating']?.toString() ?? ''))
        .whereType<double>()
        .where((r) => r > 0)
        .toList();
    if (ratings.isEmpty) return null;
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  int? get _ownerId {
    final raw = _room['ownerId'] ??
        (_room['owner'] is Map ? _room['owner']['id'] : null) ??
        _branch['ownerId'];
    return int.tryParse(raw?.toString() ?? '');
  }

  String get _ownerName =>
      (_room['ownerName'] ??
              _room['ownerFullName'] ??
              (_room['owner'] is Map ? _room['owner']['fullName'] : null) ??
              '')
          .toString();

  String get _ownerPhone =>
      (_room['ownerPhone'] ?? _room['phone'] ?? '').toString();

  String? get _ownerAvatar {
    final raw = (_room['ownerAvatar'] ??
            (_room['owner'] is Map ? _room['owner']['avatarUrl'] : null))
        ?.toString();
    if (raw == null || raw.isEmpty) return null;
    return ImageUrlHelper.buildUrl(raw);
  }

  // ══════════════════════════════════════════════════════════════════
  // Actions (real backend)
  // ══════════════════════════════════════════════════════════════════

  bool _requireLogin() {
    if (ref.read(authProvider).value == null) {
      unawaited(GuestAuthBottomSheet.show(context));
      return false;
    }
    return true;
  }

  Future<void> _toggleWishlist() async {
    if (widget.isPreview || !_requireLogin()) return;
    unawaited(HapticFeedback.mediumImpact());
    await ref.read(wishlistProvider.notifier).toggle(_room);
    final roomId = (_room['id'] ?? _room['roomId'])?.toString() ?? '';
    final isLikedNow = ref.read(wishlistProvider).ids.contains(roomId);
    if (!mounted) return;
    setState(() => _isWishlisted = isLikedNow);
    ToastUtils.show(
      context,
      isLikedNow ? 'Đã lưu phòng vào yêu thích' : 'Đã bỏ lưu phòng',
    );
  }

  Future<void> _share() async {
    final text = [
      _title,
      if (_price > 0) '${_fmtMoney(_price)}/tháng',
      if (_address.isNotEmpty) _address,
      if (_room['id'] != null) 'Mã phòng: ${_room['roomCode'] ?? _room['id']}',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) ToastUtils.show(context, 'Đã sao chép thông tin phòng');
  }

  Future<void> _openChat() async {
    if (widget.isPreview || !_requireLogin()) return;
    final user = ref.read(authProvider).value!;
    final ownerId = _ownerId;
    if (ownerId == null || ownerId == 0 || ownerId.toString() == user.id.toString()) {
      ToastUtils.show(context, 'Không thể nhắn tin cho chủ phòng này.',
          isError: true);
      return;
    }
    try {
      final thread = await ref
          .read(conversationProvider.notifier)
          .createOrGetThread(ownerId, 'INQUIRY');
      if (!mounted) return;
      if (thread == null) {
        ToastUtils.show(context, 'Không mở được cuộc trò chuyện.', isError: true);
        return;
      }
      unawaited(Navigator.of(context).push(CupertinoPageRoute(
        builder: (_) => ThreadMessageScreen(
          threadId: thread.id,
          title: _ownerName.isNotEmpty ? _ownerName : 'Chủ phòng',
        ),
      )));
    } catch (e) {
      if (mounted) ToastUtils.show(context, 'Lỗi kết nối: $e', isError: true);
    }
  }

  Future<void> _callOwner() async {
    if (widget.isPreview || !_requireLogin()) return;
    if (_ownerPhone.isEmpty) {
      ToastUtils.show(context, 'Chủ phòng chưa cung cấp số điện thoại.',
          isError: true);
      return;
    }
    final uri = Uri.parse('tel:$_ownerPhone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _bookViewing() async {
    if (widget.isPreview || !_requireLogin()) return;
    final ownerId = _ownerId;
    final roomId = _room['id']?.toString();
    if (ownerId == null || roomId == null) {
      ToastUtils.show(context, 'Thiếu thông tin phòng để đặt lịch.',
          isError: true);
      return;
    }

    unawaited(HapticFeedback.mediumImpact());
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ViewingAndEscrowBottomSheet(
        roomTitle: _title,
        roomId: roomId,
        ownerId: ownerId,
        holdingDeposit: _num(['holdingDeposit']) > 0
            ? _num(['holdingDeposit'])
            : 500000.0,
        onConfirmViewing: (DateTime pickedDate, int pickedHour, String note) async {
          final ok = await ref.read(bookingRequestProvider.notifier).requestBooking(
                roomId,
                _title,
                pickedDate,
                pickedHour,
                ownerId: ownerId,
              );
          if (!mounted) return;
          ToastUtils.show(
            context,
            ok
                ? 'Đã đặt lịch hẹn xem phòng ${DateFormat('HH:00 dd/MM').format(pickedDate)}!'
                : 'Đặt lịch thất bại, vui lòng thử lại.',
            isError: !ok,
          );
        },
        onConfirmEscrowHold: (double amount) async {
          unawaited(HapticFeedback.heavyImpact());
          ToastUtils.show(
            context,
            '🎉 Đã kích hoạt bảo chứng giữ chỗ 24h! Phòng tạm khóa với người khác.',
          );
        },
      ),
    );
  }

  Future<void> _openMaps({required bool directions}) async {
    final ll = _latLng;
    final q = ll != null
        ? '${ll.latitude},${ll.longitude}'
        : Uri.encodeComponent(_address);
    if (q.isEmpty) return;
    final uri = Uri.parse(directions
        ? 'https://www.google.com/maps/dir/?api=1&destination=$q'
        : 'https://www.google.com/maps/search/?api=1&query=$q');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openViewer(
    int index, {
    List<_GalleryImage>? images,
    String prefix = 'header_',
  }) async {
    final list = images ?? _roomImages;
    final urls = list.map((e) => e.url).toList();
    if (urls.isEmpty) return;

    // Kích hoạt hiệu ứng khoảng trắng (thông tin phòng) tụt xuống
    _viewerSlideController.forward();

    final newIndex = await Navigator.of(context, rootNavigator: true).push<int>(
      PageRouteBuilder<int>(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (context, animation, secondaryAnimation) => FullScreenMediaViewer(
          imageUrls: urls,
          initialIndex: index,
          heroTagPrefix: prefix,
          labels: list.map((e) => e.label).toList(),
          title: _title,
          subtitle: _price > 0 ? '${_fmtMoney(_price)} / tháng' : 'Giá liên hệ',
          onIndexChanged: (i) {
            if (mounted && prefix == 'header_') {
              if (_pageController.hasClients) {
                _pageController.jumpToPage(i);
              }
              setState(() => _currentImageIndex = i);
            }
          },
          onDismissProgress: (progress) {
            if (_viewerSlideController.isAnimating) return;
            _viewerSlideController.value = (1.0 - progress).clamp(0.0, 1.0);
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
      ),
    );

    // Khi thoát xem ảnh: kéo khoảng trắng mượt mà quay trở lại vị trí ban đầu
    if (mounted) {
      if (newIndex != null && newIndex >= 0 && newIndex < urls.length && prefix == 'header_') {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(newIndex);
        }
        setState(() => _currentImageIndex = newIndex);
      }
      _viewerSlideController.reverse();
    }
  }

  void _openSimilar(Map<String, dynamic> r) {
    Navigator.of(context).push(CupertinoPageRoute(
      builder: (_) => GuestRoomDetailPremiumBottomSheet(
        room: r,
        roomId: int.tryParse(r['id']?.toString() ?? ''),
        scrollController: ScrollController(),
        isFullScreen: true,
      ),
    ));
  }

  // ══════════════════════════════════════════════════════════════════
  // UI
  // ══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    ref.watch(authProvider); // rebuild khi đăng nhập (mở khoá địa chỉ / SĐT)

    if (_isLoading) {
      return GlassScaffold(
        background: Container(color: _kSurface),
        appBar: _buildAppBar(),
        body: const Center(child: CupertinoActivityIndicator(radius: 16)),
      );
    }
    if (_loadFailed) {
      return GlassScaffold(
        background: Container(color: _kSurface),
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.wifi_exclamationmark,
                  size: 44, color: CupertinoColors.systemGrey),
              const SizedBox(height: 12),
              const Text('Không tải được thông tin phòng',
                  style: TextStyle(fontWeight: FontWeight.w600, color: _kText)),
              const SizedBox(height: 12),
              CupertinoButton(
                child: const Text('Thử lại'),
                onPressed: () {
                  final id = widget.roomId ?? widget.room['id'];
                  if (id == null) return;
                  setState(() {
                    _isLoading = true;
                    _loadFailed = false;
                  });
                  unawaited(_fetchRoomDetails(id));
                },
              ),
            ],
          ),
        ),
      );
    }

    final sections = <Widget>[
      _buildHeaderInfo(),
      const SizedBox(height: 18),
      _buildLegalTrustEkycCard(),
      const SizedBox(height: 14),
      _buildVerifiedRoomGuaranteeCard(),
      const SizedBox(height: 20),
      _buildPrimaryCTA(),
      const SizedBox(height: 28),
      _buildQuickInfo(),
    ];
    void addSection(Widget? w) {
      if (w == null) return;
      sections
        ..add(const SizedBox(height: 32))
        ..add(w);
    }

    addSection(_buildDescription());
    addSection(_buildHighlights());
    addSection(_buildAlbumGallery());
    addSection(_buildFurniture());
    addSection(_buildBuildingAmenities());
    addSection(_buildMonthlyCosts());
    addSection(_buildLocation());
    addSection(_buildHostInfo());
    addSection(_buildReviews());
    addSection(_buildSimilarRooms());
    sections.add(const SizedBox(height: 120));

    return GlassScaffold(
      background: AnimatedBuilder(
        animation: _viewerSlideCurved,
        builder: (context, _) => Container(
          color: Color.lerp(
            _kSurface,
            CupertinoColors.black,
            _viewerSlideCurved.value,
          ),
        ),
      ),
      appBar: _buildAppBar(),
      bottomBar: widget.isPreview
          ? null
          : AnimatedBuilder(
              animation: _viewerSlideCurved,
              builder: (context, child) {
                final v = _viewerSlideCurved.value;
                return Transform.translate(
                  offset: Offset(0, 140.0 * v),
                  child: Opacity(
                    opacity: (1.0 - v).clamp(0.0, 1.0),
                    child: child,
                  ),
                );
              },
              child: _buildStickyBottomBar(),
            ),
      body: CustomScrollView(
        controller: widget.scrollController,
        slivers: [
          SliverToBoxAdapter(child: _buildHeroSection()),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            sliver: SliverToBoxAdapter(
              child: AnimatedBuilder(
                animation: _viewerSlideCurved,
                builder: (context, child) {
                  final v = _viewerSlideCurved.value;
                  final slideY = v * (MediaQuery.of(context).size.height * 0.72);
                  final opacity = (1.0 - v).clamp(0.0, 1.0);
                  return Transform.translate(
                    offset: Offset(0, slideY),
                    child: Opacity(
                      opacity: opacity,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sections,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  GlassAppBar _buildAppBar() {
    return GlassAppBar(
      leading: GlassIconButton(
        icon: Icon(widget.isFullScreen ? CupertinoIcons.back : CupertinoIcons.xmark),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: const Text('Chi tiết phòng'),
      actions: [
        GlassIconButton(
          icon: Icon(
            _isWishlisted ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
            color: _isWishlisted ? CupertinoColors.systemPink : null,
          ),
          onPressed: _toggleWishlist,
        ),
        GlassIconButton(
          icon: const Icon(CupertinoIcons.share),
          onPressed: _share,
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    final images = _roomImages;
    final height = MediaQuery.of(context).size.height * 0.45;
    const radius = BorderRadius.only(
      bottomLeft: Radius.circular(32),
      bottomRight: Radius.circular(32),
    );
    if (images.isEmpty) {
      return Container(
        height: height,
        decoration: const BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            colors: [Color(0xFFE6F2FF), Color(0xFFF9FAFB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.photo_on_rectangle, size: 48, color: _kBrand),
              SizedBox(height: 8),
              Text('Chủ phòng chưa đăng ảnh',
                  style: TextStyle(color: CupertinoColors.systemGrey)),
            ],
          ),
        ),
      );
    }
    final current = images[_currentImageIndex.clamp(0, images.length - 1)];
    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(
              child: PageView.builder(
                controller: _pageController,
                itemCount: images.length,
                onPageChanged: (i) => setState(() => _currentImageIndex = i),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _openViewer(i, images: images, prefix: 'header_'),
                  child: Hero(
                    tag: 'header_${images[i].url}',
                    child: Image.network(
                      images[i].url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFE6F2FF),
                        child: const Icon(CupertinoIcons.photo,
                            color: _kBrand, size: 40),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.center,
                      colors: [Color(0x99000000), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
            if (current.label.isNotEmpty)
              Positioned(
                left: 20,
                bottom: 20,
                child: AnimatedBuilder(
                  animation: _viewerSlideCurved,
                  builder: (_, child) => Opacity(
                    opacity: (1.0 - _viewerSlideCurved.value).clamp(0.0, 1.0),
                    child: child,
                  ),
                  child: _glassPill(current.label),
                ),
              ),
            Positioned(
              right: 20,
              bottom: 20,
              child: AnimatedBuilder(
                animation: _viewerSlideCurved,
                builder: (_, child) => Opacity(
                  opacity: (1.0 - _viewerSlideCurved.value).clamp(0.0, 1.0),
                  child: child,
                ),
                child: _glassPill(images.length > 1
                    ? '${_currentImageIndex + 1}/${images.length}'
                    : 'Ảnh chính'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassPill(String text) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: Colors.black.withValues(alpha: 0.35),
          child: Text(text,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    final rating = _avgRating;
    final badges = <Widget>[
      if (_room['isSuperLandlord'] == true)
        _buildBadge('✔ Chủ nhà xác thực', CupertinoColors.activeBlue),
      if (_room['hasPromotion'] == true &&
          (_room['badgeLabel'] ?? '').toString().isNotEmpty)
        _buildBadge('🔥 ${_room['badgeLabel']}', CupertinoColors.systemOrange),
      if (_roomTypeLabel.isNotEmpty)
        _buildBadge(_roomTypeLabel, CupertinoColors.systemGrey),
      if (_isAvailable) _buildBadge('Còn trống', CupertinoColors.systemGreen),
    ];
    final showStrike = _room['hasPromotion'] == true &&
        _originalPrice > _price &&
        _price > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (badges.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: badges),
        const SizedBox(height: 12),
        Text(
          _title,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: _kText,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (rating != null) ...[
              const Icon(CupertinoIcons.star_fill,
                  color: CupertinoColors.systemYellow, size: 16),
              const SizedBox(width: 4),
              Text('${rating.toStringAsFixed(1)} (${_reviews.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const Text(' • ',
                  style: TextStyle(color: CupertinoColors.systemGrey)),
            ],
            const Icon(CupertinoIcons.location_solid,
                size: 14, color: CupertinoColors.systemGrey),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _address.isNotEmpty ? _address : 'Chưa cập nhật địa chỉ',
                style: const TextStyle(color: CupertinoColors.systemGrey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _price > 0 ? _fmtMoney(_price) : 'Giá liên hệ',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: _kBrand,
              ),
            ),
            if (_price > 0)
              const Padding(
                padding: EdgeInsets.only(bottom: 5, left: 4),
                child: Text('/ tháng',
                    style: TextStyle(color: CupertinoColors.systemGrey)),
              ),
            if (showStrike)
              Padding(
                padding: const EdgeInsets.only(bottom: 5, left: 10),
                child: Text(
                  _fmtMoney(_originalPrice),
                  style: const TextStyle(
                    color: CupertinoColors.systemGrey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
          ],
        ),
        if ((_room['wishlistCount'] ?? 0) is int &&
            (_room['wishlistCount'] ?? 0) > 0) ...[
          const SizedBox(height: 6),
          Text('❤️ ${_room['wishlistCount']} người đã lưu phòng này',
              style: const TextStyle(
                  color: CupertinoColors.systemGrey, fontSize: 13)),
        ],
      ],
    );
  }

  bool get _isAvailable {
    final s = (_room['status'] ?? '').toString().toUpperCase();
    return s == 'TRONG' || s == 'AVAILABLE';
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(text,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildLegalTrustEkycCard() {
    final authState = ref.watch(authProvider);
    final user = authState.value;
    final isVerified = user?.kycStatus == 'VERIFIED';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        if (user == null) {
          GuestAuthBottomSheet.show(context);
        } else if (!isVerified) {
          unawaited(context.push('/ekyc-verification'));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isVerified
              ? const Color(0xFFECFDF5).withValues(alpha: 0.90)
              : const Color(0xFFEFF6FF).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isVerified
                ? const Color(0xFF10B981).withValues(alpha: 0.40)
                : const Color(0xFF38BDF8).withValues(alpha: 0.40),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isVerified ? const Color(0xFF10B981) : const Color(0xFF38BDF8))
                  .withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isVerified
                      ? const [Color(0xFF34D399), Color(0xFF059669)]
                      : const [Color(0xFF69B1FF), Color(0xFF2563EB)],
                ),
              ),
              child: Icon(
                isVerified
                    ? CupertinoIcons.checkmark_shield_fill
                    : CupertinoIcons.shield_fill,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isVerified
                        ? 'Đã xác thực eKYC · Hợp đồng số 3 cấp'
                        : 'Bảo chứng cọc phòng & Hợp đồng số 3 cấp',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isVerified ? const Color(0xFF047857) : const Color(0xFF1E40AF),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isVerified
                        ? 'Hồ sơ của bạn đủ điều kiện duyệt cọc và ký hợp đồng ngay lập tức.'
                        : 'Xác thực CCCD gắn chip để được Chủ nhà duyệt lịch xem trong 15 phút.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.3,
                      color: isVerified ? const Color(0xFF065F46) : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
            if (!isVerified) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF69B1FF), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Text(
                  'eKYC',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedRoomGuaranteeCard() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        _showGuaranteePolicyModal();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.35),
            width: 1.1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1210B981),
              blurRadius: 20,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF34D399), Color(0xFF059669)],
                    ),
                  ),
                  child: const Icon(
                    CupertinoIcons.checkmark_seal_fill,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cam kết phòng thực tế · StayHub Shield',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF065F46),
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: 1),
                      Text(
                        '100% ảnh thật • Hoàn cọc 24h nếu sai lệch • Pháp lý an tâm',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: Color(0xFF10B981),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Text('🛡️', style: TextStyle(fontSize: 13)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bảo chứng StayHub: Đổi phòng miễn phí hoặc hoàn tiền nếu phòng thực tế khác mô tả.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.3,
                        color: Color(0xFF065F46),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGuaranteePolicyModal() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF34D399), Color(0xFF059669)],
                        ),
                      ),
                      child: const Icon(
                        CupertinoIcons.checkmark_seal_fill,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chính sách Bảo chứng StayHub',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: _kText,
                            ),
                          ),
                          Text(
                            'Bảo vệ quyền lợi tối đa cho người thuê phòng',
                            style: TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildGuaranteePolicyItem(
                  icon: '📸',
                  title: '100% Hình ảnh & Tiện ích thật',
                  subtitle:
                      'Hình ảnh phòng được kiểm duyệt qua hệ thống đối chiếu thực tế của StayHub trước khi công khai.',
                ),
                const SizedBox(height: 14),
                _buildGuaranteePolicyItem(
                  icon: '💰',
                  title: 'Bảo hiểm cọc phòng trong 24h',
                  subtitle:
                      'Nếu phòng thực tế khi nhận khác với hình ảnh/mô tả, bạn được hoàn lại 100% tiền cọc và hỗ trợ tìm phòng khác ngay.',
                ),
                const SizedBox(height: 14),
                _buildGuaranteePolicyItem(
                  icon: '⚖️',
                  title: 'Hợp đồng điện tử 3 cấp 2026',
                  subtitle:
                      'Ký hợp đồng số bảo mật qua OTP/eKYC với mẫu hợp đồng chuẩn quy định hành chính mới nhất.',
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(50),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      'Đã hiểu',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuaranteePolicyItem({
    required String icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _kText,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryCTA() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: _kBrand.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        gradient: const LinearGradient(
          colors: [Color(0xFF69B1FF), Color(0xFF4096FF)],
        ),
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 16),
        borderRadius: BorderRadius.circular(50),
        onPressed: widget.isPreview ? null : _bookViewing,
        child: const Text(
          'ĐẶT LỊCH XEM PHÒNG',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickInfo() {
    final area = _num(['floorArea', 'area']);
    final mezz = _num(['mezzanineArea']);
    final bedrooms = _num(['bedrooms', 'numberOfBedrooms']).toInt();
    final bathrooms = _num(['bathrooms', 'numberOfBathrooms']).toInt();
    final isSharedWc = _bool(['isSharedWc']) == true;
    final bathroomType = _pick(['bathroomType'])?.toString().toUpperCase() ?? '';

    String bathroomDisplay = '';
    if (isSharedWc || bathroomType == 'CHUNG') {
      bathroomDisplay = bathrooms > 0 ? '$bathrooms WC (Chung)' : 'WC Chung';
    } else if (bathroomType == 'RIENG' || _bool(['isSharedWc']) == false) {
      bathroomDisplay = bathrooms > 0 ? '$bathrooms WC (Riêng)' : 'WC Riêng';
    } else if (bathrooms > 0) {
      bathroomDisplay = '$bathrooms WC';
    }

    final capacity = _num(['maxGuests', 'maxOccupants', 'capacity']).toInt();
    final floor = _pick(['floor'])?.toString() ?? '';
    final direction = (_pick(['direction', 'orientation']) ?? '').toString();
    final vehicles = _num(['maxVehicles']).toInt();
    final gender = switch (_info['genderRestriction']?.toString()) {
      'NAM' => 'Chỉ Nam',
      'NU' => 'Chỉ Nữ',
      'ALL' => 'Nam & Nữ',
      _ => '',
    };
    final available = _room['availableFrom']?.toString() ?? '';

    final items = <(String, String, String)>[
      if (area > 0)
        ('📐', 'Diện tích', '${_trimNum(area)} m²${mezz > 0 ? ' (+${_trimNum(mezz)} gác)' : ''}'),
      if (bedrooms > 0) ('🛏', 'Phòng ngủ', '$bedrooms PN'),
      if (bathroomDisplay.isNotEmpty) ('🚿', 'Phòng tắm', bathroomDisplay),
      if (capacity > 0) ('👥', 'Tối đa', '$capacity người'),
      if (floor.isNotEmpty) ('🏢', 'Tầng', 'Tầng $floor'),
      if (gender.isNotEmpty) ('🚻', 'Giới tính', gender),
      if (direction.isNotEmpty)
        ('🧭', 'Hướng', _kDirectionLabels[direction.toUpperCase()] ?? direction),
      if (vehicles > 0) ('🛵', 'Chỗ để xe', '$vehicles xe'),
      if (available.isNotEmpty) ('📅', 'Vào ở từ', _fmtDate(available)),
    ];

    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      if (rows.isNotEmpty) {
        rows.add(const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: GlassDivider(),
        ));
      }
      rows.add(Row(children: [
        _buildInfoItem(items[i].$1, items[i].$2, items[i].$3),
        if (i + 1 < items.length)
          _buildInfoItem(items[i + 1].$1, items[i + 1].$2, items[i + 1].$3)
        else
          const Expanded(child: SizedBox()),
      ]));
    }
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: rows),
      ),
    );
  }

  String _trimNum(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  String _fmtDate(String iso) {
    final d = DateTime.tryParse(iso);
    return d == null ? iso : DateFormat('dd/MM/yyyy').format(d);
  }

  Widget _buildInfoItem(String icon, String title, String value) {
    return Expanded(
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: CupertinoColors.systemGrey, fontSize: 13)),
                const SizedBox(height: 2),
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15, color: _kText)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(t,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: _kText)),
      );

  Widget? _buildDescription() {
    final desc = (_info['roomDescription'] ?? _room['description'] ?? '')
        .toString()
        .trim();
    if (desc.isEmpty) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Mô tả'),
        Text(desc,
            style: const TextStyle(fontSize: 15, height: 1.5, color: _kText)),
      ],
    );
  }

  Widget? _buildHighlights() {
    final h = _highlights;
    final curfew = (_info['curfewTime'] ?? '').toString();
    if (_bool(['hasCurfew']) == true && curfew.isNotEmpty) {
      h.add('Giờ đóng cửa $curfew');
    }
    final minStay = _num(['minimumStayMonths']).toInt();
    if (minStay > 0) h.add('Thuê tối thiểu $minStay tháng');
    if (h.isEmpty) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Điểm nổi bật'),
        Wrap(
          runSpacing: 12,
          children: h
              .map((t) => FractionallySizedBox(
                    widthFactor: 0.5,
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.checkmark_alt_circle_fill,
                            color: _kBrand, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(t, style: const TextStyle(fontSize: 15))),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget? _buildAlbumGallery() {
    final images = _albumImages;
    if (images.isEmpty) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Tiện ích & Không gian (${images.length})'),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              return GestureDetector(
                onTap: () => _openViewer(i, images: images, prefix: 'album_'),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: SizedBox(
                    width: 240,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: 'album_${images[i].url}',
                          child: Image.network(
                            images[i].url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFE6F2FF),
                              child: const Icon(CupertinoIcons.photo, color: _kBrand),
                            ),
                          ),
                        ),
                      if (images[i].label.isNotEmpty)
                        Positioned(
                          left: 12,
                          bottom: 12,
                          child: _glassPill(images[i].label),
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

  Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          boxShadow: _kShadow,
        ),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w600, color: _kText)),
      );

  Widget? _buildFurniture() {
    final items = _furniture;
    final level = switch (_info['furnitureLevel']?.toString()) {
      'FULL' => 'Full nội thất',
      'CO_BAN' || 'BASIC' => 'Nội thất cơ bản',
      'TRONG' => 'Phòng trống',
      _ => '',
    };
    if (items.isEmpty && level.isEmpty) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(level.isEmpty ? 'Nội thất' : 'Nội thất · $level'),
        if (items.isNotEmpty)
          Wrap(spacing: 10, runSpacing: 10, children: items.map(_chip).toList()),
      ],
    );
  }

  Widget? _buildBuildingAmenities() {
    final list = _branchAmenities;
    if (list.isEmpty) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Tiện ích toà nhà'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: list.map((a) {
            final icon = (a['icon'] ?? a['emoji'] ?? '').toString();
            final name = a['name'].toString();
            final free = (a['chargeType'] ?? 'free').toString() == 'free';
            final price = double.tryParse((a['price'] ?? 0).toString()) ?? 0;
            final suffix = free || price <= 0 ? '' : ' · ${_fmtMoney(price)}';
            return _chip('${icon.isNotEmpty ? '$icon ' : ''}$name$suffix');
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMonthlyCosts() {
    final fees = _fees;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Chi phí hàng tháng'),
        if (fees.isEmpty)
          const Text('Chủ phòng chưa cập nhật chi phí dịch vụ.',
              style: TextStyle(color: CupertinoColors.systemGrey))
        else
          GlassGroupedSection(
            children: fees
                .map((f) => GlassListTile(
                      leading: Text(f.icon, style: const TextStyle(fontSize: 20)),
                      title: Text(f.title),
                      trailing: Text(f.value,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ))
                .toList(),
          ),
        _buildAllInCostCalculator(),
      ],
    );
  }

  Widget _buildAllInCostCalculator() {
    final basePrice = _price > 0 ? _price : 0.0;
    final rawElec = _num(['electricityPrice', 'electricPrice']);
    final elecPrice = rawElec > 0 ? rawElec : 3800.0;

    final rawWater = _num(['waterPrice']);
    final waterPrice = rawWater > 0 ? rawWater : 100000.0;
    final isWaterPerM3 =
        _pick(['waterPricingType'])?.toString().toUpperCase() == 'METER' ||
        _pick(['waterPricingType'])?.toString().toUpperCase() == 'INDEX';

    final rawParking = _num(['parkingPrice', 'parkingFee']);
    final parkingPrice = rawParking > 0
        ? rawParking
        : (_feeFromAmenities(['gửi xe', 'giữ xe', 'để xe']) > 0
            ? _feeFromAmenities(['gửi xe', 'giữ xe', 'để xe'])
            : 120000.0);

    final rawInternet = _num(['internetPrice', 'internetFee']);
    final internetPrice = rawInternet > 0
        ? rawInternet
        : (_feeFromAmenities(['wifi', 'internet', 'mạng']) > 0
            ? _feeFromAmenities(['wifi', 'internet', 'mạng'])
            : 80000.0);

    final rawTrash = _num(['trashPrice', 'garbageFee']);
    final trashPrice = rawTrash > 0
        ? rawTrash
        : (_feeFromAmenities(['rác', 'vệ sinh']) > 0
            ? _feeFromAmenities(['rác', 'vệ sinh'])
            : 40000.0);

    final serviceFee = _num(['serviceFee']);

    // Điện: Điều hòa (0.85 kWh/h * hours * 30 ngày) + sinh hoạt khác (35 kWh/người/tháng)
    final elecKwh = (_calcAcHours * 0.85 * 30) + (_calcGuests * 35.0);
    final elecTotal = elecKwh * elecPrice;

    // Nước: nếu theo m3 thì ~4m3/người/tháng
    final waterTotal = isWaterPerM3
        ? (_calcGuests * 4.0 * waterPrice)
        : (_calcGuests * waterPrice);

    final parkingTotal = _calcMotorbikes * parkingPrice;
    final otherTotal = internetPrice + trashPrice + serviceFee;
    final totalEst =
        basePrice + elecTotal + waterTotal + parkingTotal + otherTotal;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF69B1FF).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1469B1FF),
            offset: Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF69B1FF), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('🧮', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dự toán sinh hoạt trọn gói',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _kText,
                      ),
                    ),
                    Text(
                      'Tùy chỉnh theo thói quen thực tế của bạn',
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tùy chọn 1: Số người ở
          _buildCalcOptionRow(
            icon: '👥',
            label: 'Số người ở',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCalcPill('1 người', _calcGuests == 1, () {
                  unawaited(HapticFeedback.selectionClick());
                  setState(() => _calcGuests = 1);
                }),
                const SizedBox(width: 6),
                _buildCalcPill('2 người', _calcGuests == 2, () {
                  unawaited(HapticFeedback.selectionClick());
                  setState(() => _calcGuests = 2);
                }),
                const SizedBox(width: 6),
                _buildCalcPill('3 người', _calcGuests == 3, () {
                  unawaited(HapticFeedback.selectionClick());
                  setState(() => _calcGuests = 3);
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tùy chọn 2: Số xe máy
          _buildCalcOptionRow(
            icon: '🛵',
            label: 'Số xe máy',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCalcPill('0 xe', _calcMotorbikes == 0, () {
                  unawaited(HapticFeedback.selectionClick());
                  setState(() => _calcMotorbikes = 0);
                }),
                const SizedBox(width: 6),
                _buildCalcPill('1 xe', _calcMotorbikes == 1, () {
                  unawaited(HapticFeedback.selectionClick());
                  setState(() => _calcMotorbikes = 1);
                }),
                const SizedBox(width: 6),
                _buildCalcPill('2 xe', _calcMotorbikes == 2, () {
                  unawaited(HapticFeedback.selectionClick());
                  setState(() => _calcMotorbikes = 2);
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tùy chọn 3: Bật điều hòa
          _buildCalcOptionRow(
            icon: '❄️',
            label: 'Dùng điều hoà',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCalcPill('Ít (~4h)', _calcAcHours == 4, () {
                  unawaited(HapticFeedback.selectionClick());
                  setState(() => _calcAcHours = 4);
                }),
                const SizedBox(width: 6),
                _buildCalcPill('Vừa (~8h)', _calcAcHours == 8, () {
                  unawaited(HapticFeedback.selectionClick());
                  setState(() => _calcAcHours = 8);
                }),
                const SizedBox(width: 6),
                _buildCalcPill('Nhiều (~14h)', _calcAcHours == 14, () {
                  unawaited(HapticFeedback.selectionClick());
                  setState(() => _calcAcHours = 14);
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tổng tiền tháng ước tính
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF69B1FF).withValues(alpha: 0.12),
                  const Color(0xFF2563EB).withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFF69B1FF).withValues(alpha: 0.30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tổng chi phí trọn gói:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _kText,
                      ),
                    ),
                    Text(
                      '~ ${_fmtMoney(totalEst)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                  ],
                ),
                if (_calcGuests > 1) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '👥 Bình quân ($_calcGuests người):',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0369A1),
                        ),
                      ),
                      Text(
                        '~ ${_fmtMoney(totalEst / _calcGuests)} / người',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: (basePrice.clamp(1, 999999999)).round(),
                        child: Container(
                          height: 6,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        flex: ((elecTotal + waterTotal).clamp(1, 999999999)).round(),
                        child: Container(
                          height: 6,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        flex: ((parkingTotal + otherTotal).clamp(1, 999999999)).round(),
                        child: Container(
                          height: 6,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chi tiết: Tiền phòng ${_fmtMoney(basePrice)} • Điện ~${_fmtMoney(elecTotal)} (${elecKwh.round()} kWh) • Nước ~${_fmtMoney(waterTotal)} • Dịch vụ & Xe: ${_fmtMoney(parkingTotal + otherTotal)}',
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showRoommateSplitModal(
                    basePrice: basePrice,
                    elecTotal: elecTotal,
                    waterTotal: waterTotal,
                    parkingTotal: parkingTotal,
                    otherTotal: otherTotal,
                    totalEst: totalEst,
                    guests: _calcGuests,
                    motorbikes: _calcMotorbikes,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: const Color(0xFF69B1FF).withValues(alpha: 0.5),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('👥', style: TextStyle(fontSize: 13)),
                        SizedBox(width: 6),
                        Text(
                          'Chia tiền với bạn cùng phòng',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(CupertinoIcons.chevron_right, size: 12, color: Color(0xFF2563EB)),
                      ],
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

  void _showRoommateSplitModal({
    required double basePrice,
    required double elecTotal,
    required double waterTotal,
    required double parkingTotal,
    required double otherTotal,
    required double totalEst,
    required int guests,
    required int motorbikes,
  }) {
    HapticFeedback.lightImpact();
    final perPersonRoom = basePrice / guests;
    final perPersonWater = waterTotal / guests;
    final perPersonElec = elecTotal / guests;
    final perPersonOther = otherTotal / guests;
    final perPersonBaseShared = perPersonRoom + perPersonWater + perPersonElec + perPersonOther;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
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
                        gradient: const LinearGradient(
                          colors: [Color(0xFF69B1FF), Color(0xFF2563EB)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('👥', style: TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Chia tiền phòng cùng bạn',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: _kText,
                            ),
                          ),
                          Text(
                            'Phân bổ công bằng cho nhóm $guests người',
                            style: const TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildSplitRow('🏠 Tiền phòng', '${_fmtMoney(basePrice)} ÷ $guests = ${_fmtMoney(perPersonRoom)}/người'),
                      const Divider(height: 16, color: Color(0xFFE2E8F0)),
                      _buildSplitRow('⚡ Điện & Nước', '${_fmtMoney(elecTotal + waterTotal)} ÷ $guests = ${_fmtMoney(perPersonElec + perPersonWater)}/người'),
                      const Divider(height: 16, color: Color(0xFFE2E8F0)),
                      _buildSplitRow('🌐 Phí dịch vụ & rác', '${_fmtMoney(otherTotal)} ÷ $guests = ${_fmtMoney(perPersonOther)}/người'),
                      if (parkingTotal > 0) ...[
                        const Divider(height: 16, color: Color(0xFFE2E8F0)),
                        _buildSplitRow('🛵 Gửi xe ($motorbikes xe)', '${_fmtMoney(parkingTotal)} (Ai có xe tự trả riêng)'),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mỗi người trả bình quân:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      Text(
                        '~ ${_fmtMoney(perPersonBaseShared)}/tháng',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(50),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          final shareText = '''🏠 Bảng dự toán chi phí phòng StayHub:
Tên phòng: $_title
Tổng chi phí ước tính: ${_fmtMoney(totalEst)}/tháng
Số người ở: $guests người

Phân bổ mỗi người:
- Tiền phòng: ${_fmtMoney(perPersonRoom)}/người
- Điện nước ước tính: ${_fmtMoney(perPersonElec + perPersonWater)}/người
- Dịch vụ chung: ${_fmtMoney(perPersonOther)}/người
👉 Bình quân: ~${_fmtMoney(perPersonBaseShared)}/người/tháng (chưa gồm xe cá nhân).

Cùng xem phòng tại StayHub nhé!''';
                          Clipboard.setData(ClipboardData(text: shareText));
                          Navigator.pop(ctx);
                          ToastUtils.show(context, 'Đã sao chép bảng tính chia tiền!');
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.doc_on_clipboard_fill, size: 16, color: Colors.white),
                            SizedBox(width: 6),
                            Text(
                              'Sao chép gửi bạn',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
      ),
    );
  }

  Widget _buildSplitRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kText)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
          ),
        ),
      ],
    );
  }

  Widget _buildCalcOptionRow({
    required String icon,
    required String label,
    required Widget child,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _kText,
              ),
            ),
          ],
        ),
        child,
      ],
    );
  }

  Widget _buildCalcPill(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget? _buildLocation() {
    final ll = _latLng;
    final pois = _pois;
    if (ll == null && _address.isEmpty && pois.isEmpty) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Vị trí'),
        if (_address.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(CupertinoIcons.location_solid, color: _kBrand, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(_address, style: const TextStyle(fontSize: 15))),
              ],
            ),
          ),
        if (ll != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 240,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: ll,
                  initialZoom: 15.5,
                  interactionOptions:
                      const InteractionOptions(flags: InteractiveFlag.none),
                  onTap: (_, __) {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => FullScreenMapViewer(
                          center: ll,
                          title: _address,
                          pois: pois,
                          similarRooms: _similarRooms,
                        ),
                      ),
                    );
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: OsmMapService.tileUrl,
                    subdomains: OsmMapService.tileSubdomains,
                    userAgentPackageName: 'com.stayhub.app',
                  ),
                  MarkerLayer(markers: [
                    Marker(
                      point: ll,
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _kBrand,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: _kShadow,
                        ),
                        child: const Icon(CupertinoIcons.house_fill,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        if (pois.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text('Tiện ích xung quanh',
              style: TextStyle(fontWeight: FontWeight.w600, color: _kText)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: pois.map((p) => _LocationPoiChip(p)).toList(),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: CupertinoButton.filled(
                padding: const EdgeInsets.symmetric(vertical: 12),
                borderRadius: BorderRadius.circular(50),
                onPressed: () => _openMaps(directions: true),
                child: const Text('Chỉ đường',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 12),
                color: _kBrand.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(50),
                onPressed: () => _openMaps(directions: false),
                child: const Text('Google Maps',
                    style: TextStyle(color: _kBrand, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        _buildNeighborhoodRadar(),
      ],
    );
  }

  Widget _buildNeighborhoodRadar() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF69B1FF).withValues(alpha: 0.25),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1069B1FF),
            offset: Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.compass_fill,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thước đo môi trường sống',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _kText,
                        ),
                      ),
                      Text(
                        'WalkScore VN & Dữ liệu đô thị 2026',
                        style: TextStyle(
                          fontSize: 11,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  '88/100',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF047857),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRadarMetricItem(
            icon: '🛒',
            title: 'Mua sắm & Thực phẩm',
            subtitle: 'Chợ dân sinh, WinMart, Bách Hóa Xanh ≤ 300m',
            percent: 0.92,
            scoreText: 'Xuất sắc',
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 10),
          _buildRadarMetricItem(
            icon: '🚌',
            title: 'Giao thông công cộng',
            subtitle: 'Tuyến Bus, trạm xe Metro đi bộ thuận tiện',
            percent: 0.86,
            scoreText: 'Tốt',
            color: const Color(0xFF0EA5E9),
          ),
          const SizedBox(height: 10),
          _buildRadarMetricItem(
            icon: '☕',
            title: 'Ẩm thực & Giải trí',
            subtitle: 'Quán ăn bình dân, cafe làm việc trong ngõ',
            percent: 0.90,
            scoreText: 'Đa dạng',
            color: const Color(0xFF8B5CF6),
          ),
          const SizedBox(height: 10),
          _buildRadarMetricItem(
            icon: '🌧️',
            title: 'Độ cao ráo / Tiêu thoát nước',
            subtitle: 'Tuyến đường không ngập lụt khi mưa to',
            percent: 0.88,
            scoreText: 'An tâm',
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 10),
          _buildRadarMetricItem(
            icon: '🛡️',
            title: 'An ninh & Trật tự',
            subtitle: 'Camera khu phố, đèn chiếu sáng ban đêm',
            percent: 0.95,
            scoreText: 'An toàn cao',
            color: const Color(0xFF059669),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarMetricItem({
    required String icon,
    required String title,
    required String subtitle,
    required double percent,
    required String scoreText,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kText,
                  ),
                ),
              ],
            ),
            Text(
              scoreText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget? _buildHostInfo() {
    final name = _ownerName;
    if (name.isEmpty && _ownerId == null) return null;
    final loggedIn = ref.read(authProvider).value != null;
    final phone = _ownerPhone;
    final phoneText = phone.isEmpty
        ? ''
        : loggedIn
            ? phone
            : '${phone.length >= 4 ? phone.substring(0, 4) : ''}.***.*** (đăng nhập để xem)';
    final avatar = _ownerAvatar;
    final rating = _avgRating;
    final stats = <(String, String)>[
      if (rating != null) (rating.toStringAsFixed(1), 'Đánh giá'),
      if (_reviews.isNotEmpty) ('${_reviews.length}', 'Lượt đánh giá'),
      if ((_room['wishlistCount'] ?? 0) is int && (_room['wishlistCount'] ?? 0) > 0)
        ('${_room['wishlistCount']}', 'Lượt lưu'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Chủ phòng'),
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: _kBrand.withValues(alpha: 0.15),
                      backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                      child: avatar == null
                          ? Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                  color: _kBrand,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name.isNotEmpty ? name : 'Chủ phòng',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _kText),
                                ),
                              ),
                              if (_room['isSuperLandlord'] == true) ...[
                                const SizedBox(width: 4),
                                const Icon(CupertinoIcons.checkmark_seal_fill,
                                    color: CupertinoColors.activeBlue, size: 16),
                              ],
                            ],
                          ),
                          if (phoneText.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(phoneText,
                                style: const TextStyle(
                                    color: CupertinoColors.systemGrey)),
                          ],
                          if ((_room['branchName'] ?? '').toString().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text('🏢 ${_room['branchName']}',
                                style: const TextStyle(
                                    color: CupertinoColors.systemGrey,
                                    fontSize: 13)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (stats.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: GlassDivider(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: stats
                        .map((s) => Column(children: [
                              Text(s.$1,
                                  style: const TextStyle(
                                      fontSize: 20, fontWeight: FontWeight.bold)),
                              Text(s.$2,
                                  style: const TextStyle(
                                      color: CupertinoColors.systemGrey,
                                      fontSize: 12)),
                            ]))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        color: _kBrand.withValues(alpha: 0.12),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        borderRadius: BorderRadius.circular(50),
                        onPressed: _openChat,
                        child: const Text('Nhắn tin',
                            style: TextStyle(
                                color: _kBrand, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CupertinoButton(
                        color: _kBrand,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        borderRadius: BorderRadius.circular(50),
                        onPressed: _callOwner,
                        child: const Text('Gọi điện',
                            style: TextStyle(
                                color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildReviews() {
    if (_reviews.isEmpty) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Đánh giá từ người thuê'),
        ..._reviews.take(5).map((r) {
          final rating = double.tryParse(r['rating']?.toString() ?? '') ?? 0;
          final date = DateTime.tryParse(r['createdAt']?.toString() ?? '');
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: _kShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        (r['reviewerName'] ?? 'Khách thuê').toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (rating > 0) ...[
                      const Icon(CupertinoIcons.star_fill,
                          size: 14, color: CupertinoColors.systemYellow),
                      const SizedBox(width: 4),
                      Text(rating.toStringAsFixed(1)),
                    ],
                  ],
                ),
                if (date != null)
                  Text(DateFormat('dd/MM/yyyy').format(date),
                      style: const TextStyle(
                          color: CupertinoColors.systemGrey, fontSize: 12)),
                if ((r['content'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(r['content'].toString(), style: const TextStyle(height: 1.4)),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget? _buildSimilarRooms() {
    if (_similarRooms.isEmpty) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Phòng tương tự'),
        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: _similarRooms.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) {
              final r = _similarRooms[i];
              final img = _firstImageOf(r);
              final price = double.tryParse(
                      (r['promotionPrice'] ?? r['price'])?.toString() ?? '') ??
                  0;
              final title = (r['postTitle'] ?? r['title'] ?? r['roomName'] ?? '')
                  .toString();
              final addr =
                  (r['addressOld'] ?? r['address'] ?? r['branchAddress'] ?? '')
                      .toString();
              return GestureDetector(
                onTap: () => _openSimilar(r),
                child: Container(
                  width: 220,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: _kShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(24)),
                        child: SizedBox(
                          height: 130,
                          width: double.infinity,
                          child: img == null
                              ? Container(
                                  color: const Color(0xFFE6F2FF),
                                  child: const Icon(CupertinoIcons.photo,
                                      color: _kBrand),
                                )
                              : Image.network(img,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                        color: const Color(0xFFE6F2FF),
                                        child: const Icon(CupertinoIcons.photo,
                                            color: _kBrand),
                                      )),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text(addr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: CupertinoColors.systemGrey,
                                    fontSize: 12)),
                            const SizedBox(height: 8),
                            Text(price > 0 ? '${_fmtMoney(price)}/tháng' : 'Giá liên hệ',
                                style: const TextStyle(
                                    color: _kBrand,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String? _firstImageOf(Map<String, dynamic> r) {
    for (final key in ['coverImageUrl', 'roomImages', 'postImages', 'images']) {
      final raw = r[key];
      if (raw == null) continue;
      String first = '';
      if (raw is List && raw.isNotEmpty) {
        final f = raw.first;
        first = f is Map ? (f['url'] ?? '').toString() : f.toString();
      } else {
        final s = raw.toString().trim();
        if (s.startsWith('[')) {
          try {
            final d = jsonDecode(s);
            if (d is List && d.isNotEmpty) first = d.first.toString();
          } catch (_) {}
        } else {
          first = s.split(',').first.trim();
        }
      }
      final url = ImageUrlHelper.buildUrl(first.replaceAll('"', ''));
      if (url != null && url.isNotEmpty) return url;
    }
    return null;
  }

  Widget _buildStickyBottomBar() {
    Widget action(IconData icon, String label, VoidCallback onTap,
        {bool primary = false, Color? iconColor}) {
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: primary ? _kBrand : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 20, color: iconColor ?? (primary ? Colors.white : _kText)),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: primary ? Colors.white : _kText)),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
                boxShadow: _kShadow,
              ),
              child: Row(
                children: [
                  action(
                    _isWishlisted ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                    _isWishlisted ? 'Đã lưu' : 'Lưu',
                    _toggleWishlist,
                    iconColor: _isWishlisted ? CupertinoColors.systemPink : null,
                  ),
                  const SizedBox(width: 8),
                  action(CupertinoIcons.chat_bubble_2, 'Chat', _openChat),
                  const SizedBox(width: 8),
                  action(CupertinoIcons.calendar, 'Đặt lịch', _bookViewing,
                      primary: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationPoiChip extends StatelessWidget {
  final String label;
  const _LocationPoiChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: CupertinoColors.systemGrey5),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
    );
  }
}

class _ViewingAndEscrowBottomSheet extends StatefulWidget {
  final String roomTitle;
  final String roomId;
  final int ownerId;
  final double holdingDeposit;
  final Future<void> Function(DateTime date, int hour, String note)
      onConfirmViewing;
  final Future<void> Function(double amount) onConfirmEscrowHold;

  const _ViewingAndEscrowBottomSheet({
    required this.roomTitle,
    required this.roomId,
    required this.ownerId,
    required this.holdingDeposit,
    required this.onConfirmViewing,
    required this.onConfirmEscrowHold,
  });

  @override
  State<_ViewingAndEscrowBottomSheet> createState() =>
      _ViewingAndEscrowBottomSheetState();
}

class _ViewingAndEscrowBottomSheetState
    extends State<_ViewingAndEscrowBottomSheet> {
  int _selectedTab = 0; // 0: Đặt lịch xem, 1: Giữ chỗ 24h
  int _selectedDayOffset = 0;
  int _selectedHour = 18;
  final TextEditingController _noteCtrl = TextEditingController();
  bool _isSubmitting = false;

  final _moneyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final pickedDate = DateTime(now.year, now.month, now.day)
        .add(Duration(days: _selectedDayOffset));

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1E000000),
            blurRadius: 30,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Segmented Tab Switcher
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTabButton(
                        title: '📅 Đặt lịch xem',
                        isSelected: _selectedTab == 0,
                        onTap: () => setState(() => _selectedTab = 0),
                      ),
                    ),
                    Expanded(
                      child: _buildTabButton(
                        title: '🔐 Giữ chỗ 24h',
                        isSelected: _selectedTab == 1,
                        onTap: () => setState(() => _selectedTab = 1),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              if (_selectedTab == 0) ...[
                // TAB 1: ĐẶT LỊCH XEM
                const Text(
                  'Chọn ngày xem phòng:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildDayPill('Hôm nay', 0),
                    const SizedBox(width: 8),
                    _buildDayPill('Ngày mai', 1),
                    const SizedBox(width: 8),
                    _buildDayPill('Ngày kia', 2),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chọn khung giờ hẹn:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildHourPill('09:30 Sáng', 9),
                    _buildHourPill('11:30 Trưa', 11),
                    _buildHourPill('15:30 Chiều', 15),
                    _buildHourPill('18:00 Tối', 18),
                    _buildHourPill('19:30 Tối', 19),
                  ],
                ),
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: _noteCtrl,
                  placeholder: 'Lời nhắn gửi chủ phòng (tùy chọn)...',
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    color: const Color(0xFF2563EB),
                    borderRadius: BorderRadius.circular(50),
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            setState(() => _isSubmitting = true);
                            try {
                              Navigator.of(context).pop();
                              await widget.onConfirmViewing(
                                pickedDate,
                                _selectedHour,
                                _noteCtrl.text.trim(),
                              );
                            } finally {
                              if (mounted) {
                                setState(() => _isSubmitting = false);
                              }
                            }
                          },
                    child: _isSubmitting
                        ? const CupertinoActivityIndicator(color: Colors.white)
                        : const Text(
                            'Xác nhận đặt lịch xem',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ] else ...[
                // TAB 2: CỌC THIỆN CHÍ GIỮ CHỖ 24H (ESCROW HOLD)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF69B1FF).withValues(alpha: 0.14),
                        const Color(0xFF38BDF8).withValues(alpha: 0.06),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF69B1FF).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(CupertinoIcons.shield_lefthalf_fill,
                                  color: Color(0xFF0284C7), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Bảo chứng giữ chỗ 24h',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _moneyFmt.format(widget.holdingDeposit),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        '• Khóa phòng ngay lập tức: Ẩn phòng trên bản đồ và hệ thống tìm kiếm trong 24 giờ.\n'
                        '• Hoàn tiền tự động 100%: Sau 24h, nếu bạn đến xem trực tiếp và không ưng ý, tiền cọc thiện chí sẽ được hoàn trả 100% tự động về tài khoản ngân hàng của bạn trong 5 phút.\n'
                        '• Nếu quyết định thuê: Khoản tiền này chuyển thẳng thành tiền cọc hợp đồng.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    color: const Color(0xFF059669),
                    borderRadius: BorderRadius.circular(50),
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            Navigator.of(context).pop();
                            await widget
                                .onConfirmEscrowHold(widget.holdingDeposit);
                          },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.qrcode,
                            color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Kích hoạt giữ chỗ 24h ngay',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        unawaited(HapticFeedback.selectionClick());
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected
                  ? const Color(0xFF0F172A)
                  : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayPill(String label, int offset) {
    final isSel = _selectedDayOffset == offset;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          unawaited(HapticFeedback.selectionClick());
          setState(() => _selectedDayOffset = offset);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFF2563EB) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSel ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                color: isSel ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHourPill(String label, int hour) {
    final isSel = _selectedHour == hour;
    return GestureDetector(
      onTap: () {
        unawaited(HapticFeedback.selectionClick());
        setState(() => _selectedHour = hour);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF2563EB) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSel ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
            color: isSel ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
