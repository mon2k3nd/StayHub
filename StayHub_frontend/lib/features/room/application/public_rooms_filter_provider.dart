import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/room_type_codes.dart';
import '../../../core/providers/core_providers.dart';

class PublicRoomsFilterState {
  final String keyword;
  final double? minPrice;
  final double? maxPrice;
  final double? minArea;
  final double? maxArea;
  final List<String> roomTypes;
  final String? province;
  // Quận/Huyện + Phường/Xã: bản đồ trước đây chỉ lọc tới cấp tỉnh nên khi đồng
  // bộ bộ lọc từ màn Danh sách sang Bản đồ, các cấp này bị MẤT → bản đồ hiển thị
  // thừa kết quả. Nay giữ lại để bộ lọc khớp đúng cả 2 màn.
  final String? district;
  final String? ward;
  // Hướng phòng ('DONG'|'TAY'|'NAM'|'BAC') — cũng bị mất khi đồng bộ trước đây.
  final String? direction;
  final String sortBy;
  final List<String> amenities;
  final List<String> roomFeatures;
  final bool onlyPromo;
  final double? lat;
  final double? lng;
  final double? radius;
  final int? bedrooms;
  final int? bathrooms;
  final int? maxGuests;
  final String? usageType;
  final int? beds;

  PublicRoomsFilterState({
    this.keyword = '',
    this.minPrice,
    this.maxPrice,
    this.minArea,
    this.maxArea,
    this.roomTypes = const [],
    this.province,
    this.district,
    this.ward,
    this.direction,
    this.sortBy = 'newest',
    this.amenities = const [],
    this.roomFeatures = const [],
    this.onlyPromo = false,
    this.lat,
    this.lng,
    this.radius,
    this.bedrooms,
    this.bathrooms,
    this.maxGuests,
    this.usageType,
    this.beds,
  });

  PublicRoomsFilterState copyWith({
    String? keyword,
    double? minPrice,
    double? maxPrice,
    double? minArea,
    double? maxArea,
    List<String>? roomTypes,
    String? province,
    String? district,
    String? ward,
    String? direction,
    String? sortBy,
    List<String>? amenities,
    List<String>? roomFeatures,
    bool? onlyPromo,
    int? bedrooms,
    int? bathrooms,
    int? maxGuests,
    String? usageType,
    int? beds,
    double? lat,
    double? lng,
    double? radius,
  }) {
    return PublicRoomsFilterState(
      keyword: keyword ?? this.keyword,
      minPrice: minPrice == -1 ? null : (minPrice ?? this.minPrice),
      maxPrice: maxPrice == -1 ? null : (maxPrice ?? this.maxPrice),
      minArea: minArea == -1 ? null : (minArea ?? this.minArea),
      maxArea: maxArea == -1 ? null : (maxArea ?? this.maxArea),
      roomTypes: roomTypes ?? this.roomTypes,
      province: province == '' ? null : (province ?? this.province),
      district: district == '' ? null : (district ?? this.district),
      ward: ward == '' ? null : (ward ?? this.ward),
      direction: direction == '' ? null : (direction ?? this.direction),
      sortBy: sortBy ?? this.sortBy,
      amenities: amenities ?? this.amenities,
      roomFeatures: roomFeatures ?? this.roomFeatures,
      onlyPromo: onlyPromo ?? this.onlyPromo,
      bedrooms: bedrooms == -1 ? null : (bedrooms ?? this.bedrooms),
      bathrooms: bathrooms == -1 ? null : (bathrooms ?? this.bathrooms),
      maxGuests: maxGuests == -1 ? null : (maxGuests ?? this.maxGuests),
      usageType: usageType == '' ? null : (usageType ?? this.usageType),
      beds: beds == -1 ? null : (beds ?? this.beds),
      lat: lat == -999 ? null : (lat ?? this.lat),
      lng: lng == -999 ? null : (lng ?? this.lng),
      radius: radius == -1 ? null : (radius ?? this.radius),
    );
  }

  /// True khi người dùng đang áp ít nhất một bộ lọc (không tính sortBy).
  /// Dùng để hiển thị badge "đang lọc" trên nút Bộ lọc.
  bool get hasActiveFilters =>
      keyword.isNotEmpty ||
      minPrice != null ||
      maxPrice != null ||
      minArea != null ||
      maxArea != null ||
      roomTypes.isNotEmpty ||
      (province != null && province!.isNotEmpty) ||
      (district != null && district!.isNotEmpty) ||
      (ward != null && ward!.isNotEmpty) ||
      (direction != null && direction!.isNotEmpty) ||
      amenities.isNotEmpty ||
      roomFeatures.isNotEmpty ||
      onlyPromo ||
      bedrooms != null ||
      bathrooms != null ||
      maxGuests != null ||
      (usageType != null && usageType!.isNotEmpty) ||
      beds != null ||
      (lat != null && lng != null);

  /// Số lượng bộ lọc đang áp (để hiển thị badge số).
  int get activeFilterCount {
    var count = 0;
    if (keyword.isNotEmpty) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (minArea != null || maxArea != null) count++;
    if (roomTypes.isNotEmpty) count++;
    if (province != null && province!.isNotEmpty) count++;
    if (district != null && district!.isNotEmpty) count++;
    if (ward != null && ward!.isNotEmpty) count++;
    if (direction != null && direction!.isNotEmpty) count++;
    if (amenities.isNotEmpty) count++;
    if (roomFeatures.isNotEmpty) count++;
    if (onlyPromo) count++;
    if (bedrooms != null) count++;
    if (bathrooms != null) count++;
    if (maxGuests != null) count++;
    if (usageType != null && usageType!.isNotEmpty) count++;
    if (beds != null) count++;
    if (lat != null && lng != null) count++;
    return count;
  }

  /// Chuẩn hoá sortBy về tập canonical mà backend hiểu:
  /// newest | price_asc | price_desc | area_asc | area_desc | distance.
  ///
  /// Chấp nhận cả alias cũ (recommend, createdAt, price, area...) để không
  /// phá vỡ các call-site hiện có.
  static String normalizeSortBy(String raw) {
    final s = raw.trim().toLowerCase();
    if (s.isEmpty) return 'newest';
    final comma = s.indexOf(',');
    final field = comma >= 0 ? s.substring(0, comma).trim() : s;
    final dir = comma >= 0 ? s.substring(comma + 1).trim() : '';
    switch (field) {
      case 'price':
      case 'rentingprice':
      case 'renting_price':
        return dir.startsWith('desc') ? 'price_desc' : 'price_asc';
      case 'area':
      case 'floorarea':
      case 'floor_area':
        return dir.startsWith('desc') ? 'area_desc' : 'area_asc';
      case 'distance':
      case 'near':
      case 'nearby':
        return 'distance';
      case 'createdat':
      case 'created_at':
      case 'newest':
      case 'recommend':
      case 'latest':
        return 'newest';
      case 'price_asc':
      case 'price_desc':
      case 'area_asc':
      case 'area_desc':
        return field;
      default:
        return 'newest';
    }
  }

  /// Builds query parameters for Dio.
  ///
  /// Lưu ý: [roomTypes] và [amenities] được gửi dưới dạng List để Dio serialize
  /// thành các tham số lặp (`roomTypes=A&roomTypes=B`) — đúng contract của
  /// backend (`@RequestParam List<String>`). KHÔNG join bằng dấu phẩy vì
  /// backend sẽ hiểu cả chuỗi CSV là một phần tử duy nhất.
  Map<String, dynamic> toQueryParams() {
    final Map<String, dynamic> params = {};
    if (keyword.isNotEmpty) params['keyword'] = keyword;
    if (minPrice != null) params['minPrice'] = minPrice;
    if (maxPrice != null) params['maxPrice'] = maxPrice;
    if (minArea != null) params['minArea'] = minArea;
    if (maxArea != null) params['maxArea'] = maxArea;

    // Loại phòng: LUÔN chuẩn hoá về MÃ canonical (PHONG_TRO, CHUNG_CU_MINI…).
    // UI có thể truyền nhãn cũ ('Phòng trọ') → tự động quy đổi sang mã để
    // backend `upper(room_sub_type) = code` khớp được. Bỏ qua giá trị lạ.
    if (roomTypes.isNotEmpty) {
      final codes = RoomTypeCodes.toCodes(roomTypes);
      if (codes.isNotEmpty) params['roomTypes'] = codes;
    }

    if (province != null && province!.isNotEmpty) params['province'] = province;
    if (district != null && district!.isNotEmpty) params['district'] = district;
    if (ward != null && ward!.isNotEmpty) params['ward'] = ward;
    if (direction != null && direction!.isNotEmpty) {
      params['direction'] = direction;
    }
    // Luôn gửi sortBy (đã chuẩn hoá) để backend sắp xếp đúng thay vì mặc định.
    params['sortBy'] = normalizeSortBy(sortBy);

    // Tiện ích: gộp cả `amenities` (chip tiện ích) lẫn các `roomFeatures`
    // dạng nội thất (gác lửng, full nội thất…) vì backend so khớp trên cùng
    // cột `furniture` (JSON array mã hoá hoa).
    final amenityCodes = <String>{
      ...amenities.map((a) => a.trim().toUpperCase()),
      ..._featureFurnitureCodes(roomFeatures),
    }..removeWhere((e) => e.isEmpty);
    if (amenityCodes.isNotEmpty) params['amenities'] = amenityCodes.toList();

    if (onlyPromo) params['onlyPromotion'] = true;

    // Đặc điểm phòng → boolean field của backend.
    // Hỗ trợ cả key mới (ban_cong/cua_so/khep_kin) lẫn key cũ (balcony/window/private_wc).
    if (roomFeatures.contains('cua_so') || roomFeatures.contains('window')) {
      params['hasWindow'] = true;
    }
    if (roomFeatures.contains('ban_cong') || roomFeatures.contains('balcony')) {
      params['hasBalcony'] = true;
    }
    if (roomFeatures.contains('khep_kin') ||
        roomFeatures.contains('private_wc')) {
      params['privateBathroom'] = true;
    }

    if (lat != null) params['lat'] = lat;
    if (lng != null) params['lng'] = lng;
    if (radius != null) params['radius'] = radius;
    if (bedrooms != null) params['bedrooms'] = bedrooms;
    if (bathrooms != null) params['bathrooms'] = bathrooms;
    if (maxGuests != null) params['maxGuests'] = maxGuests;
    if (usageType != null && usageType!.isNotEmpty) {
      params['usageType'] = usageType;
    }
    if (beds != null) params['beds'] = beds;

    return params;
  }

  /// Ánh xạ các "đặc điểm phòng" dạng nội thất sang MÃ trong cột `furniture`
  /// để backend lọc được (backend chỉ có boolean cho cửa sổ/ban công/WC riêng,
  /// còn gác lửng / full nội thất nằm trong `furniture`).
  static List<String> _featureFurnitureCodes(Iterable<String> features) {
    // BUGFIX: 'nong_lanh' trước đây map sang 'HEATER' — mã này KHÔNG tồn tại
    // trong cột `furniture` thật (DB lưu 'BINH_NONG_LANH'). Lọc theo nóng lạnh
    // vì thế không khớp phòng nào. Nay dùng đúng mã lưu trong DB.
    // BUGFIX 2: 'nha_bep' trước đây map sang 'NHA_BEP' — cũng KHÔNG tồn tại;
    // luồng tạo phòng ghi 'TU_BEP'/'BEP_TU'. 'full_noi_that' map sang
    // 'FULL_NOI_THAT' cũng không tồn tại — full nội thất là một MỨC
    // (`furnitureLevel`), không phải một mã trong `furniture`, nên bỏ ánh xạ
    // này để tránh gửi mã rác lên backend (lọc rỗng).
    const map = {
      'gac_lung': 'GAC_LUNG',
      'studio': 'STUDIO',
      'nha_bep': 'TU_BEP',
      'nong_lanh': 'BINH_NONG_LANH',
    };
    final out = <String>[];
    for (final f in features) {
      final code = map[f];
      if (code != null) out.add(code);
    }
    return out;
  }
}

class PublicRoomsFilterNotifier extends Notifier<PublicRoomsFilterState> {
  @override
  PublicRoomsFilterState build() {
    return PublicRoomsFilterState();
  }

  void updateFilters({
    String? keyword,
    double? minPrice,
    double? maxPrice,
    double? minArea,
    double? maxArea,
    List<String>? roomTypes,
    String? province,
    String? district,
    String? ward,
    String? direction,
    String? sortBy,
    List<String>? amenities,
    List<String>? roomFeatures,
    bool? onlyPromo,
    int? bedrooms,
    int? bathrooms,
    int? maxGuests,
    String? usageType,
    int? beds,
  }) {
    state = state.copyWith(
      keyword: keyword,
      minPrice: minPrice,
      maxPrice: maxPrice,
      minArea: minArea,
      maxArea: maxArea,
      roomTypes: roomTypes,
      province: province,
      district: district,
      ward: ward,
      direction: direction,
      sortBy: sortBy,
      amenities: amenities,
      roomFeatures: roomFeatures,
      onlyPromo: onlyPromo,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      maxGuests: maxGuests,
      usageType: usageType,
      beds: beds,
    );
  }

  /// Thay TOÀN BỘ state bằng [next] (dùng khi đồng bộ bộ lọc từ màn Danh sách
  /// sang màn Bản đồ). Khác [updateFilters] ở chỗ gán trực tiếp — không đi qua
  /// các sentinel (-1/''/-999) nên không có nguy cơ "xoá nhầm" trường null.
  void setFrom(PublicRoomsFilterState next) {
    state = next;
  }

  void updateLocation(double lat, double lng, double radius) {
    state = state.copyWith(lat: lat, lng: lng, radius: radius);
  }

  void clearLocation() {
    state = state.copyWith(lat: -999, lng: -999, radius: -1);
  }

  void reset() {
    state = PublicRoomsFilterState();
  }
}

final publicRoomsFilterProvider =
    NotifierProvider<PublicRoomsFilterNotifier, PublicRoomsFilterState>(
      PublicRoomsFilterNotifier.new,
    );

/// Metadata bộ lọc lấy từ backend (`GET /v1/rooms/public/filters`).
///
/// Chứa khoảng giá/diện tích THỰC TẾ trong DB + danh sách loại phòng, tiện ích,
/// hướng, tỉnh/thành đang có. Nhờ vậy slider giá/diện tích và chip lọc luôn khớp
/// dữ liệu thật thay vì hard-code.
class PublicRoomsFilterMetadata {
  final double minPrice;
  final double maxPrice;
  final double minArea;
  final double maxArea;
  final List<String> roomTypes;
  final List<String> amenities;
  final List<String> directions;
  final List<String> provinces;
  final List<int> bedrooms;
  final int totalActivePosts;

  const PublicRoomsFilterMetadata({
    this.minPrice = 0,
    this.maxPrice = 50000000,
    this.minArea = 0,
    this.maxArea = 200,
    this.roomTypes = const [],
    this.amenities = const [],
    this.directions = const [],
    this.provinces = const [],
    this.bedrooms = const [],
    this.totalActivePosts = 0,
  });

  factory PublicRoomsFilterMetadata.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v, double fallback) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    List<String> toStrList(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      return const [];
    }

    List<int> toIntList(dynamic v) {
      if (v is List) {
        return v
            .map((e) => e is num ? e.toInt() : int.tryParse(e.toString()))
            .whereType<int>()
            .toList();
      }
      return const [];
    }

    return PublicRoomsFilterMetadata(
      minPrice: toDouble(json['minPrice'], 0),
      maxPrice: toDouble(json['maxPrice'], 50000000),
      minArea: toDouble(json['minArea'], 0),
      maxArea: toDouble(json['maxArea'], 200),
      roomTypes: toStrList(json['roomTypes']),
      amenities: toStrList(json['amenities']),
      directions: toStrList(json['directions']),
      provinces: toStrList(json['provinces']),
      bedrooms: toIntList(json['bedrooms']),
      totalActivePosts: json['totalActivePosts'] is num
          ? (json['totalActivePosts'] as num).toInt()
          : 0,
    );
  }
}

/// Provider tải metadata bộ lọc (cache theo session, refresh khi cần).
final publicRoomsFilterMetadataProvider =
    FutureProvider<PublicRoomsFilterMetadata>((ref) async {
      final dio = ref.read(dioProvider);
      final res = await dio.get('/v1/rooms/public/filters');
      final data = res.data['data'] ?? res.data;
      if (data is Map<String, dynamic>) {
        return PublicRoomsFilterMetadata.fromJson(data);
      }
      return const PublicRoomsFilterMetadata();
    });
