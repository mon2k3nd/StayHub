import '../../room/application/public_rooms_filter_provider.dart';
import '../domain/models/room_search_filter.dart';

/// Cầu nối chuyển đổi giữa HAI hệ bộ lọc của màn tìm phòng:
///
/// - **Danh sách** (`GuestHomeScreen`) dùng [`RoomSearchFilter`] +
///   `roomSearchProvider` (server-driven, có phân trang tích luỹ).
/// - **Bản đồ** (`GuestMarketplaceScreen`) dùng [`PublicRoomsFilterState`] +
///   `publicRoomsFilterProvider`.
///
/// Trước đây hai hệ này hoàn toàn tách rời → bộ lọc áp ở màn Danh sách KHÔNG
/// mang sang màn Bản đồ (và ngược lại). File này là nguồn chuyển đổi duy nhất
/// để hai màn luôn chia sẻ CÙNG một bộ lọc.
///
/// Quy ước quan trọng:
/// - `RoomSearchFilter` dùng `null` = "không lọc"; `PublicRoomsFilterState`
///   cũng dùng `null` = "không lọc" (sentinel -1/''/-999 chỉ dùng ở `copyWith`).
/// - Loại phòng luôn được chuẩn hoá về MÃ canonical ở cả hai phía.
class RoomFilterSync {
  RoomFilterSync._();

  /// Danh sách → Bản đồ.
  ///
  /// Chuyển [`RoomSearchFilter`] (màn Danh sách) sang
  /// [`PublicRoomsFilterState`] (màn Bản đồ) để bộ lọc áp ở danh sách được
  /// mang nguyên vẹn sang bản đồ.
  static PublicRoomsFilterState toMapFilter(RoomSearchFilter f) {
    return PublicRoomsFilterState(
      keyword: f.keyword,
      minPrice: f.minPrice,
      maxPrice: f.maxPrice,
      minArea: f.minArea,
      maxArea: f.maxArea,
      roomTypes: List<String>.from(f.roomTypes),
      province: f.province,
      // Giữ nguyên cấp quận/huyện + phường/xã + hướng để bản đồ lọc khớp danh
      // sách (trước đây bị bỏ → bản đồ hiển thị thừa kết quả).
      district: f.district,
      ward: f.ward,
      direction: f.direction,
      sortBy: PublicRoomsFilterState.normalizeSortBy(f.sortBy),
      amenities: List<String>.from(f.amenities),
      // Đặc điểm boolean của danh sách → roomFeatures của bản đồ để không
      // mất thông tin khi chuyển đổi (bản đồ gộp chúng vào query params).
      roomFeatures: _featuresFromBooleans(f),
      onlyPromo: f.onlyPromotion,
      lat: f.lat,
      lng: f.lng,
      radius: f.radius,
      bedrooms: f.bedrooms,
      bathrooms: f.bathrooms,
      maxGuests: f.maxGuests,
      usageType: f.usageType,
      beds: f.beds,
    );
  }

  /// Bản đồ → Danh sách.
  ///
  /// Chuyển [`PublicRoomsFilterState`] (màn Bản đồ) ngược về
  /// [`RoomSearchFilter`] (màn Danh sách) để khi người dùng lọc trên bản đồ
  /// rồi quay lại danh sách, bộ lọc vẫn được giữ đúng.
  static RoomSearchFilter toListFilter(PublicRoomsFilterState s) {
    final features = s.roomFeatures;
    return RoomSearchFilter(
      keyword: s.keyword,
      minPrice: s.minPrice,
      maxPrice: s.maxPrice,
      minArea: s.minArea,
      maxArea: s.maxArea,
      roomTypes: List<String>.from(s.roomTypes),
      bedrooms: s.bedrooms,
      beds: s.beds,
      bathrooms: s.bathrooms,
      maxGuests: s.maxGuests,
      usageType: s.usageType,
      province: s.province,
      district: s.district,
      ward: s.ward,
      direction: s.direction,
      amenities: List<String>.from(s.amenities),
      hasWindow: features.contains('cua_so') || features.contains('window'),
      hasBalcony: features.contains('ban_cong') || features.contains('balcony'),
      privateBathroom:
          features.contains('khep_kin') || features.contains('private_wc'),
      onlyPromotion: s.onlyPromo,
      sortBy: s.sortBy,
      lat: s.lat,
      lng: s.lng,
      radius: s.radius,
    );
  }

  /// Ánh xạ các cờ boolean đặc điểm của danh sách sang danh sách `roomFeatures`
  /// của bản đồ (dùng key canonical mà `toQueryParams` hiểu).
  static List<String> _featuresFromBooleans(RoomSearchFilter f) {
    final out = <String>[];
    if (f.hasWindow) out.add('cua_so');
    if (f.hasBalcony) out.add('ban_cong');
    if (f.privateBathroom) out.add('khep_kin');
    return out;
  }
}
