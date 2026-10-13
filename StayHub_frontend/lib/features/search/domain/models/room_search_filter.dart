import 'package:flutter/foundation.dart';

import '../../../../core/constants/room_type_codes.dart';

/// Bộ lọc tìm phòng — mô hình bất biến (immutable) dùng chung cho UI + API.
///
/// Mọi trường đều nullable: `null` nghĩa là "không lọc theo tiêu chí này".
/// Lớp này là nguồn sự thật duy nhất cho bộ lọc; nó tự serialize thành query
/// params khớp 1-1 với `V1PublicRoomController#searchPublicRooms` ở backend.
@immutable
class RoomSearchFilter {
  final String keyword;

  // Giá thuê (VND/tháng)
  final double? minPrice;
  final double? maxPrice;

  // Diện tích (m²)
  final double? minArea;
  final double? maxArea;

  // Loại phòng (room_sub_type)
  final List<String> roomTypes;

  // Số phòng ngủ (5 = "5+")
  final int? bedrooms;

  // Số giường (5 = "5+")
  final int? beds;

  // Số phòng tắm / WC (5 = "5+")
  final int? bathrooms;

  // Số người tối đa (lọc "chứa được ít nhất N người")
  final int? maxGuests;

  // Hình thức sử dụng: 'WHOLE' | 'SHARED' | 'PRIVATE'
  final String? usageType;

  // Tỉnh / Thành phố
  final String? province;
  final String? district;
  final String? ward;

  // Hướng: 'DONG' | 'TAY' | 'NAM' | 'BAC'
  final String? direction;

  // Tiện ích / nội thất (mã: AC, WIFI, HEATER...)
  final List<String> amenities;

  // Đặc điểm
  final bool hasWindow;
  final bool hasBalcony;
  final bool privateBathroom;
  final bool onlyPromotion;

  // Sắp xếp: newest | price_asc | price_desc | area_asc | area_desc
  final String sortBy;

  // Vị trí
  final double? lat;
  final double? lng;
  final double? radius;

  const RoomSearchFilter({
    this.keyword = '',
    this.minPrice,
    this.maxPrice,
    this.minArea,
    this.maxArea,
    this.roomTypes = const [],
    this.bedrooms,
    this.beds,
    this.bathrooms,
    this.maxGuests,
    this.usageType,
    this.province,
    this.district,
    this.ward,
    this.direction,
    this.amenities = const [],
    this.hasWindow = false,
    this.hasBalcony = false,
    this.privateBathroom = false,
    this.onlyPromotion = false,
    this.sortBy = 'newest',
    this.lat,
    this.lng,
    this.radius,
  });

  /// Bộ lọc rỗng (mặc định).
  static const empty = RoomSearchFilter();

  /// Số tiêu chí đang bật (để hiển thị badge trên nút "Bộ lọc").
  int get activeCount {
    int n = 0;
    if (keyword.trim().isNotEmpty) n++;
    if (minPrice != null || maxPrice != null) n++;
    if (minArea != null || maxArea != null) n++;
    if (roomTypes.isNotEmpty) n++;
    if (bedrooms != null) n++;
    if (beds != null) n++;
    if (bathrooms != null) n++;
    if (maxGuests != null) n++;
    if (usageType != null) n++;
    if (province != null && province!.isNotEmpty) n++;
    if (district != null && district!.isNotEmpty) n++;
    if (ward != null && ward!.isNotEmpty) n++;
    if (direction != null) n++;
    n += amenities.length;
    if (hasWindow) n++;
    if (hasBalcony) n++;
    if (privateBathroom) n++;
    if (onlyPromotion) n++;
    return n;
  }

  bool get isEmpty => activeCount == 0;

  /// Serialize thành query params cho `GET /v1/rooms/public/search`.
  ///
  /// Bỏ qua mọi trường null/rỗng để URL gọn và backend nhận đúng "không lọc".
  Map<String, dynamic> toQueryParameters({int page = 0, int size = 20}) {
    final params = <String, dynamic>{'page': page, 'size': size};

    if (keyword.trim().isNotEmpty) params['keyword'] = keyword.trim();
    if (minPrice != null) params['minPrice'] = minPrice;
    if (maxPrice != null) params['maxPrice'] = maxPrice;
    if (minArea != null) params['minArea'] = minArea;
    if (maxArea != null) params['maxArea'] = maxArea;
    // BUGFIX: canonical hoá TRƯỚC khi gửi. Trước đây gửi thẳng `roomTypes`
    // (có thể chứa alias như KIOT_BAN_LE/VAN_PHONG/KHO_XUONG) — chỉ đúng nhờ
    // backend tự canonical hoá. Nay chuẩn hoá ở client để URL luôn dùng mã
    // canonical, khớp `RoomTypeCodes.canonicalCodes` và tránh phụ thuộc ngầm.
    if (roomTypes.isNotEmpty) {
      final canonical = RoomTypeCodes.toCodes(roomTypes);
      if (canonical.isNotEmpty) params['roomTypes'] = canonical;
    }
    if (bedrooms != null) params['bedrooms'] = bedrooms;
    if (beds != null) params['beds'] = beds;
    if (bathrooms != null) params['bathrooms'] = bathrooms;
    if (maxGuests != null) params['maxGuests'] = maxGuests;
    if (usageType != null) params['usageType'] = usageType;
    if (province != null && province!.isNotEmpty) params['province'] = province;
    if (district != null && district!.isNotEmpty) params['district'] = district;
    if (ward != null && ward!.isNotEmpty) params['ward'] = ward;
    if (direction != null) params['direction'] = direction;
    if (amenities.isNotEmpty) params['amenities'] = amenities;
    if (hasWindow) params['hasWindow'] = true;
    if (hasBalcony) params['hasBalcony'] = true;
    if (privateBathroom) params['privateBathroom'] = true;
    if (onlyPromotion) params['onlyPromotion'] = true;
    if (sortBy.isNotEmpty) params['sortBy'] = sortBy;
    if (lat != null && lng != null) {
      params['lat'] = lat;
      params['lng'] = lng;
      if (radius != null) params['radius'] = radius;
    }
    return params;
  }

  RoomSearchFilter copyWith({
    String? keyword,
    double? minPrice,
    double? maxPrice,
    double? minArea,
    double? maxArea,
    List<String>? roomTypes,
    int? bedrooms,
    int? beds,
    int? bathrooms,
    int? maxGuests,
    String? usageType,
    String? province,
    String? district,
    String? ward,
    String? direction,
    List<String>? amenities,
    bool? hasWindow,
    bool? hasBalcony,
    bool? privateBathroom,
    bool? onlyPromotion,
    String? sortBy,
    double? lat,
    double? lng,
    double? radius,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
    bool clearMinArea = false,
    bool clearMaxArea = false,
    bool clearBedrooms = false,
    bool clearBeds = false,
    bool clearBathrooms = false,
    bool clearMaxGuests = false,
    bool clearUsageType = false,
    bool clearProvince = false,
    bool clearDistrict = false,
    bool clearWard = false,
    bool clearDirection = false,
    bool clearLocation = false,
  }) {
    return RoomSearchFilter(
      keyword: keyword ?? this.keyword,
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      minArea: clearMinArea ? null : (minArea ?? this.minArea),
      maxArea: clearMaxArea ? null : (maxArea ?? this.maxArea),
      roomTypes: roomTypes ?? this.roomTypes,
      bedrooms: clearBedrooms ? null : (bedrooms ?? this.bedrooms),
      beds: clearBeds ? null : (beds ?? this.beds),
      bathrooms: clearBathrooms ? null : (bathrooms ?? this.bathrooms),
      maxGuests: clearMaxGuests ? null : (maxGuests ?? this.maxGuests),
      usageType: clearUsageType ? null : (usageType ?? this.usageType),
      province: clearProvince ? null : (province ?? this.province),
      district: clearDistrict ? null : (district ?? this.district),
      ward: clearWard ? null : (ward ?? this.ward),
      direction: clearDirection ? null : (direction ?? this.direction),
      amenities: amenities ?? this.amenities,
      hasWindow: hasWindow ?? this.hasWindow,
      hasBalcony: hasBalcony ?? this.hasBalcony,
      privateBathroom: privateBathroom ?? this.privateBathroom,
      onlyPromotion: onlyPromotion ?? this.onlyPromotion,
      sortBy: sortBy ?? this.sortBy,
      lat: clearLocation ? null : (lat ?? this.lat),
      lng: clearLocation ? null : (lng ?? this.lng),
      radius: clearLocation ? null : (radius ?? this.radius),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoomSearchFilter &&
        other.keyword == keyword &&
        other.minPrice == minPrice &&
        other.maxPrice == maxPrice &&
        other.minArea == minArea &&
        other.maxArea == maxArea &&
        listEquals(other.roomTypes, roomTypes) &&
        other.bedrooms == bedrooms &&
        other.beds == beds &&
        other.bathrooms == bathrooms &&
        other.maxGuests == maxGuests &&
        other.usageType == usageType &&
        other.province == province &&
        other.district == district &&
        other.ward == ward &&
        other.direction == direction &&
        listEquals(other.amenities, amenities) &&
        other.hasWindow == hasWindow &&
        other.hasBalcony == hasBalcony &&
        other.privateBathroom == privateBathroom &&
        other.onlyPromotion == onlyPromotion &&
        other.sortBy == sortBy &&
        other.lat == lat &&
        other.lng == lng &&
        other.radius == radius;
  }

  @override
  int get hashCode => Object.hash(
    keyword,
    minPrice,
    maxPrice,
    minArea,
    maxArea,
    Object.hashAll(roomTypes),
    bedrooms,
    beds,
    bathrooms,
    maxGuests,
    usageType,
    Object.hash(province, district, ward, direction),
    Object.hashAll(amenities),
    hasWindow,
    hasBalcony,
    privateBathroom,
    onlyPromotion,
    sortBy,
    Object.hash(lat, lng, radius),
  );
}

/// Hồ sơ tiêu chí lọc theo TỪNG danh mục bất động sản.
///
/// Mỗi loại hình chỉ có những tiêu chí thực sự có nghĩa với nó — ví dụ
/// "Phòng trọ" là một phòng đơn nên KHÔNG hỏi số phòng ngủ / số giường /
/// số WC; còn "Nhà ở" (nguyên căn) thì mới cần. Nhờ vậy bộ lọc không còn
/// hiển thị thừa/thiếu tiêu chí so với mô hình dữ liệu của từng loại.
@immutable
class RoomFilterProfile {
  /// Hiện mục "Hình thức sử dụng" (nguyên căn / ở ghép / phòng riêng).
  final bool usageType;

  /// Hiện mục "Số phòng ngủ".
  final bool bedrooms;

  /// Hiện mục "Số giường".
  final bool beds;

  /// Hiện mục "Số phòng tắm / WC".
  final bool bathrooms;

  /// Hiện mục "Số người tối đa".
  final bool maxGuests;

  /// Hiện mục "Hướng phòng".
  final bool direction;

  /// Hiện mục "Đặc điểm" (cửa sổ / ban công / WC riêng / khuyến mãi).
  final bool features;

  const RoomFilterProfile({
    this.usageType = true,
    this.bedrooms = true,
    this.beds = true,
    this.bathrooms = true,
    this.maxGuests = true,
    this.direction = true,
    this.features = true,
  });

  /// Hồ sơ mặc định khi chưa chọn danh mục nào (hiện đầy đủ).
  static const all = RoomFilterProfile();

  /// Tra hồ sơ theo mã loại phòng (`room_sub_type`) của danh mục đang chọn.
  ///
  /// - `PHONG_TRO` / `O_GHEP_KTX`: phòng đơn → ẩn phòng ngủ/giường/WC,
  ///   nhưng vẫn hỏi "số người tối đa" (phòng trọ giới hạn số người).
  /// - `CHUNG_CU` / `NHA_NGUYEN_CAN`: nhà nguyên căn → hiện đầy đủ.
  /// - `KIOT_BAN_LE` / `VAN_PHONG` / `KHO_XUONG` / `KHONG_GIAN_CD` /
  ///   `DAT_CHO_THUE`: mặt bằng thương mại → chỉ diện tích, giá, khu vực,
  ///   hướng; ẩn mọi tiêu chí dân dụng.
  /// - `LUU_TRU`: lưu trú (homestay/khách sạn) → hiện số người, giường;
  ///   ẩn phòng ngủ/WC/hướng.
  static RoomFilterProfile forRoomType(String? roomType) {
    switch (roomType) {
      case 'PHONG_TRO':
      case 'O_GHEP_KTX':
        return const RoomFilterProfile(
          usageType: false,
          bedrooms: false,
          beds: false,
          bathrooms: false,
          maxGuests: true,
          direction: true,
          features: true,
        );
      case 'CHUNG_CU':
      case 'NHA_NGUYEN_CAN':
        return const RoomFilterProfile();
      // BUGFIX: trước đây switch trên ALIAS (KIOT_BAN_LE/VAN_PHONG/KHO_XUONG).
      // Từ khi các danh mục gửi MÃ canonical (KIOT/OFFICE/KHO_BAI), các case
      // alias không còn khớp → rơi vào `default` (hồ sơ dân dụng đầy đủ) thay
      // vì hồ sơ mặt bằng thương mại. Nay dùng canonical + giữ alias để tương
      // thích ngược.
      case 'KIOT':
      case 'KIOT_BAN_LE':
      case 'OFFICE':
      case 'VAN_PHONG':
      case 'KHO_BAI':
      case 'KHO_XUONG':
      case 'KHONG_GIAN_CD':
      case 'DAT_CHO_THUE':
        return const RoomFilterProfile(
          usageType: false,
          bedrooms: false,
          beds: false,
          bathrooms: false,
          maxGuests: false,
          direction: true,
          features: false,
        );
      case 'LUU_TRU':
        return const RoomFilterProfile(
          usageType: false,
          bedrooms: false,
          beds: true,
          bathrooms: false,
          maxGuests: true,
          direction: false,
          features: true,
        );
      default:
        return const RoomFilterProfile();
    }
  }
}
