import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:stayhub_frontend/core/utils/image_url_helper.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:stayhub_frontend/core/services/osm_map_service.dart';
import 'package:stayhub_frontend/core/components/safe_network_image.dart';

final Map<String, List<String>> _globalPoisCache = {};

List<String> _getParsedPois(dynamic poisRaw) {
  if (poisRaw == null) return [];
  final cacheKey = poisRaw.toString();
  if (_globalPoisCache.containsKey(cacheKey)) {
    return _globalPoisCache[cacheKey]!;
  }

  List<String> pois = [];
  if (poisRaw is List) {
    pois = poisRaw.map((e) => e.toString()).toList();
  } else if (poisRaw is String) {
    if (poisRaw.trim().startsWith('[')) {
      try {
        final List parsed = jsonDecode(poisRaw);
        pois = parsed.map((e) => e.toString()).toList();
      } catch (_) {
        pois = poisRaw
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
      pois = poisRaw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
  }

  if (_globalPoisCache.length > 50) _globalPoisCache.clear(); // simple eviction
  _globalPoisCache[cacheKey] = pois;
  return pois;
}

class ChoTotRoomDetailLayout extends StatelessWidget {
  final Map<String, dynamic> room;
  final Map<String, dynamic> info;
  final Map<String, dynamic> branchMap;
  final List<String> images;
  final String roomName;
  final String address;
  final double price;
  final double area;
  final double baseDeposit;
  final String roomTypeLabel;
  final String description;
  final String resolvedOwnerName;
  final dynamic resolvedOwnerAvatar;
  final String ownerSubtitle;
  final bool isWishlisted;
  final VoidCallback onToggleWishlist;
  final VoidCallback onRequireLogin;
  final List<String> amenities;
  final double elecPrice;
  final double waterPrice;
  final double internetPrice;
  final double parkingPrice;
  final double trashPrice;
  final double serviceFee;
  final String waterPricingType;
  final String elecPricingType;
  final String internetPricingType;
  final String parkingPricingType;
  final String trashPricingType;
  final String servicePricingType;
  final VoidCallback? onMapTap;

  const ChoTotRoomDetailLayout({
    super.key,
    required this.room,
    required this.info,
    required this.branchMap,
    required this.images,
    required this.roomName,
    required this.address,
    required this.price,
    required this.area,
    required this.baseDeposit,
    required this.roomTypeLabel,
    required this.description,
    required this.resolvedOwnerName,
    required this.resolvedOwnerAvatar,
    required this.ownerSubtitle,
    required this.isWishlisted,
    required this.onToggleWishlist,
    required this.onRequireLogin,
    this.amenities = const [],
    this.elecPrice = 0,
    this.waterPrice = 0,
    this.internetPrice = 0,
    this.parkingPrice = 0,
    this.trashPrice = 0,
    this.serviceFee = 0,
    this.waterPricingType = '',
    this.elecPricingType = '',
    this.internetPricingType = '',
    this.parkingPricingType = '',
    this.trashPricingType = '',
    this.servicePricingType = '',
    this.onMapTap,
  });

  static final _formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '');

  String _formatPrice(double val) {
    if (val == 0) return 'Miễn phí';
    return _formatter.format(val).trim();
  }

  String _mapChargeType(String type, String fallback) {
    if (type.isEmpty) return fallback;
    final t = type.toUpperCase();
    if (t == 'ROOM') return 'phòng';
    if (t == 'PERSON') return 'người';
    if (t == 'METER') return fallback;
    if (t == 'SLOT' || t == 'VEHICLE') return 'xe';
    if (t == 'INDEX') return fallback;
    return fallback;
  }

  Widget _buildModernCard(Widget child) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1469b1ff),
            offset: Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      child: child,
    );
  }

  String? _getFeaturePhotoUrl(Map<String, dynamic> info, String group) {
    try {
      final fp = info['featurePhotos'];
      if (fp is Map) {
        final val = fp[group];
        if (val is String && val.isNotEmpty) {
          return ImageUrlHelper.buildUrl(val);
        } else if (val is List && val.isNotEmpty) {
          return ImageUrlHelper.buildUrl(val.first.toString());
        }
      }
    } catch (_) {}
    return null;
  }

  Widget _buildStatRow(
    IconData icon,
    Color iconColor,
    String label,
    String value, {
    bool isHighlight = false,
    String? photoUrl,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 15, color: Colors.black54),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                    color: isHighlight
                        ? const Color(0xFF69b1ff)
                        : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (photoUrl != null && photoUrl.isNotEmpty) ...[
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 60,
                height: 60,
                child: SafeNetworkImage(url: photoUrl, fit: BoxFit.cover),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getAmenityIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('điều hoà') || n.contains('máy lạnh') || n.contains('ac')) {
      return CupertinoIcons.snow;
    }
    if (n.contains('nóng lạnh') || n.contains('nước')) {
      return CupertinoIcons.drop_fill;
    }
    if (n.contains('tủ lạnh')) {
      return CupertinoIcons.snow;
    }
    if (n.contains('quần áo')) {
      return CupertinoIcons.archivebox_fill;
    }
    if (n.contains('bếp')) {
      return CupertinoIcons.house_alt_fill;
    }
    if (n.contains('vi sóng')) {
      return CupertinoIcons.flame_fill;
    }
    if (n.contains('hút mùi')) {
      return CupertinoIcons.wind;
    }
    if (n.contains('cửa sổ')) {
      return CupertinoIcons.square_split_2x2_fill;
    }
    if (n.contains('ban công')) {
      return CupertinoIcons.building_2_fill;
    }
    if (n.contains('giặt')) {
      return CupertinoIcons.archivebox_fill;
    }
    if (n.contains('giường') || n.contains('đệm')) {
      return CupertinoIcons.bed_double_fill;
    }
    if (n.contains('wifi') || n.contains('mạng') || n.contains('internet')) {
      return CupertinoIcons.wifi;
    }
    if (n.contains('bảo vệ') || n.contains('an ninh') || n.contains('camera')) {
      return CupertinoIcons.shield_fill;
    }
    if (n.contains('vệ sinh') || n.contains('wc')) {
      return CupertinoIcons.drop_fill;
    }
    if (n.contains('bàn')) {
      return CupertinoIcons.square_on_square;
    }
    if (n.contains('tv') || n.contains('tivi')) {
      return CupertinoIcons.tv_fill;
    }
    if (n.contains('thang máy')) {
      return CupertinoIcons.arrow_up_down_square_fill;
    }
    if (n.contains('gác')) {
      return CupertinoIcons.layers_alt_fill;
    }
    if (n.contains('sofa')) {
      return CupertinoIcons.bed_double_fill;
    }
    if (n.contains('chỗ để xe') || n.contains('bãi xe') || n.contains('gửi xe')) {
      return CupertinoIcons.car_detailed;
    }
    return CupertinoIcons.checkmark_alt;
  }

  @override
  Widget build(BuildContext context) {
    final floorStr = room['floor']?.toString() ?? '';
    int numberOfBedrooms =
        int.tryParse(
          room['bedrooms']?.toString() ??
              info['numberOfBedrooms']?.toString() ??
              '',
        ) ??
        0;
    if (numberOfBedrooms == 0) numberOfBedrooms = 1;

    int numberOfBathrooms =
        int.tryParse(
          room['bathrooms']?.toString() ??
              info['numberOfBathrooms']?.toString() ??
              '',
        ) ??
        0;
    if (numberOfBathrooms == 0) numberOfBathrooms = 1;
    final capacity =
        int.tryParse(
          room['maxGuests']?.toString() ??
              room['capacity']?.toString() ??
              info['capacity']?.toString() ??
              '',
        ) ??
        0;
    final genderString =
        room['gender']?.toString() ?? info['gender']?.toString() ?? 'Tất cả';
    final status =
        room['status']?.toString() ??
        room['postStatus']?.toString() ??
        'AVAILABLE';
    final isAvailable = status == 'TRONG' || status == 'AVAILABLE';
    final poisRaw =
        room['pois'] ??
        (room['branch'] is Map ? room['branch']['pois'] : null) ??
        room['poi'] ??
        room['placesOfInterest'];

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
    final lat = double.tryParse(latStr) ?? 21.028511; // default Hanoi
    final lng = double.tryParse(lngStr) ?? 105.804817; // default Hanoi
    final center = LatLng(lat, lng);

    List<String> pois = _getParsedPois(poisRaw);
    int poiCount = pois.length;

    // --- Extended Info Variables ---
    final mezzanineArea =
        double.tryParse(room['mezzanineArea']?.toString() ?? info['mezzanineArea']?.toString() ?? '') ?? 0;
    final maxVehicles =
        int.tryParse(
          info['maxVehicles']?.toString() ??
              room['maxVehicles']?.toString() ??
              '',
        ) ??
        0;
    final hasPavement = info['hasPavement'] == true || info['hasPavement'] == 'true';
    final truckAccess = info['truckAccess'] == true || info['truckAccess'] == 'true';
    final minimumStayMonths =
        int.tryParse(info['minimumStayMonths']?.toString() ?? '') ?? 0;
    final noticePeriodDays =
        int.tryParse(info['noticePeriodDays']?.toString() ?? '') ?? 0;
    final hasCurfew = info['hasCurfew'] == true || info['hasCurfew'] == 'true';
    final curfewTime = info['curfewTime']?.toString() ?? '';
    final isLiveWithLandlord = info['isLiveWithLandlord'] == true || info['isLiveWithLandlord'] == 'true';
    final hasWindow = room['hasWindow'] == true || room['hasWindow'] == 'true' || info['hasWindow'] == true || info['hasWindow'] == 'true';
    final hasBalcony = room['hasBalcony'] == true || room['hasBalcony'] == 'true' || info['hasBalcony'] == true || info['hasBalcony'] == 'true';
    final bedType = info['bedType']?.toString() ?? '';
    final hasKitchen = info['hasKitchen'] == true || info['hasKitchen'] == 'true';

    final windowPhoto = _getFeaturePhotoUrl(info, 'WINDOW');
    final balconyPhoto = _getFeaturePhotoUrl(info, 'BALCONY');
    final kitchenPhoto = _getFeaturePhotoUrl(info, 'KITCHEN');
    final mezzaninePhoto = _getFeaturePhotoUrl(info, 'MEZZANINE');

    // Count how many extended stats we have to conditionally render the section
    int extendedStatsCount = 0;
    if (mezzanineArea > 0) extendedStatsCount++;
    if (maxVehicles > 0) extendedStatsCount++;
    if (hasPavement || truckAccess) extendedStatsCount++;
    if (minimumStayMonths > 0) extendedStatsCount++;
    if (noticePeriodDays > 0) extendedStatsCount++;
    if (hasCurfew || curfewTime.isNotEmpty) extendedStatsCount++;
    if (isLiveWithLandlord) extendedStatsCount++;
    if (hasWindow) extendedStatsCount++;
    if (hasBalcony) extendedStatsCount++;
    if (hasKitchen) extendedStatsCount++;
    if (bedType.isNotEmpty) extendedStatsCount++;

    return Container(
      color: Colors.white, // Allow Liquid Glass from bottom sheet to show
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header (Tên phòng, Giá, Thông tin chung)
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(
              20,
              0,
              20,
              24,
            ), // Sát mép, liền khối với ảnh
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF69b1ff).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        roomTypeLabel.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF69b1ff),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (!isAvailable)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              CupertinoIcons.circle_fill,
                              size: 8,
                              color: Colors.red,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Đã thuê',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  roomName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                    color: Color(0xFF0F172A),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_formatPrice(price)} đ/tháng',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                        color: Color(0xFF69b1ff),
                      ),
                    ), // Primary Color
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1469b1ff),
                        offset: Offset(0, 8),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildQuickStat(
                        CupertinoIcons.square_split_2x2_fill,
                        '${area.toInt()} m²',
                      ),
                      _buildQuickStat(
                        CupertinoIcons.bed_double_fill,
                        '$numberOfBedrooms PN',
                      ),
                      _buildQuickStat(
                        CupertinoIcons.drop_fill,
                        '$numberOfBathrooms WC\n${room['hasPrivateBathroom'] == true || room['hasPrivateBathroom'] == 'true' || info['hasPrivateBathroom'] == true || info['hasPrivateBathroom'] == 'true' ? 'Khép kín' : 'Chung'}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Chi tiết phòng (Sức chứa, Giới tính, v.v)
          _buildModernCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đặc điểm nổi bật',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 20),
                _buildStatRow(
                  CupertinoIcons.person_3_fill,
                  const Color(0xFF69b1ff),
                  'Sức chứa',
                  capacity > 0 ? 'Tối đa $capacity người' : 'Không giới hạn',
                ),
                _buildStatRow(
                  CupertinoIcons.person_crop_circle_badge_exclam,
                  const Color(0xFF69b1ff),
                  'Giới tính',
                  genderString,
                ),
                if (floorStr.isNotEmpty)
                  _buildStatRow(
                    CupertinoIcons.building_2_fill,
                    const Color(0xFF69b1ff),
                    'Tầng',
                    floorStr,
                  ),
                _buildStatRow(
                  CupertinoIcons.shield_fill,
                  const Color(0xFF69b1ff),
                  'Tiền cọc',
                  '${_formatPrice(baseDeposit)} đ',
                  isHighlight: true,
                ),
              ],
            ),
          ),

          // 2.5. Thông tin mở rộng (Extended Info)
          if (extendedStatsCount > 0)
            _buildModernCard(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin chi tiết',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (mezzanineArea > 0)
                    _buildStatRow(
                      CupertinoIcons.layers_alt_fill,
                      const Color(0xFF69b1ff),
                      'Gác lửng',
                      '$mezzanineArea m²',
                      photoUrl: mezzaninePhoto,
                    ),
                  if (hasBalcony)
                    _buildStatRow(
                      CupertinoIcons.building_2_fill,
                      const Color(0xFF69b1ff),
                      'Ban công',
                      'Có ban công',
                      photoUrl: balconyPhoto,
                    ),
                  if (hasWindow)
                    _buildStatRow(
                      CupertinoIcons.square_split_2x2_fill,
                      const Color(0xFF69b1ff),
                      'Cửa sổ',
                      'Có cửa sổ',
                      photoUrl: windowPhoto,
                    ),
                  if (hasKitchen)
                    _buildStatRow(
                      CupertinoIcons.flame_fill,
                      const Color(0xFF69b1ff),
                      'Khu vực bếp',
                      'Có bếp nấu ăn',
                      photoUrl: kitchenPhoto,
                    ),
                  if (bedType.isNotEmpty)
                    _buildStatRow(
                      CupertinoIcons.bed_double_fill,
                      const Color(0xFF69b1ff),
                      'Loại giường',
                      bedType,
                    ),
                  if (maxVehicles > 0)
                    _buildStatRow(
                      CupertinoIcons.car_detailed,
                      const Color(0xFF69b1ff),
                      'Chỗ để xe',
                      'Tối đa $maxVehicles xe',
                    ),
                  if (hasPavement || truckAccess)
                    _buildStatRow(
                      CupertinoIcons.car_fill,
                      const Color(0xFF69b1ff),
                      'Giao thông',
                      truckAccess ? 'Ô tô đỗ cửa' : 'Có vỉa hè',
                    ),
                  if (minimumStayMonths > 0)
                    _buildStatRow(
                      CupertinoIcons.doc_text_fill,
                      const Color(0xFF69b1ff),
                      'Hợp đồng tối thiểu',
                      '$minimumStayMonths tháng',
                    ),
                  if (noticePeriodDays > 0)
                    _buildStatRow(
                      CupertinoIcons.bell_fill,
                      const Color(0xFF69b1ff),
                      'Báo trước khi huỷ',
                      '$noticePeriodDays ngày',
                    ),
                  if (isLiveWithLandlord)
                    _buildStatRow(
                      CupertinoIcons.person_2_fill,
                      const Color(0xFF69b1ff),
                      'Chung chủ',
                      'Có',
                    ),
                  if (hasCurfew || curfewTime.isNotEmpty)
                    _buildStatRow(
                      CupertinoIcons.clock_fill,
                      const Color(0xFF69b1ff),
                      'Giờ giấc',
                      hasCurfew && curfewTime.isNotEmpty
                          ? 'Đóng cửa lúc $curfewTime'
                          : 'Giờ giấc tự do',
                    ),
                ],
              ),
            ),

          // 3. Tiện ích & Nội thất
          if (amenities.isNotEmpty)
            _buildModernCard(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nội thất & Tiện ích',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisExtent: 44,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: amenities.length,
                    itemBuilder: (context, index) {
                      final e = amenities[index];
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF69b1ff,
                              ).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getAmenityIcon(e),
                              size: 16,
                              color: const Color(0xFF69b1ff),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              e,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF1E293B),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

          // 4. Chi phí hàng tháng
          _buildModernCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chi phí hàng tháng',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 20),
                _buildStatRow(
                  CupertinoIcons.bolt_fill,
                  const Color(0xFF69b1ff),
                  'Điện',
                  elecPrice > 0
                      ? '${_formatPrice(elecPrice)} đ/${_mapChargeType(elecPricingType, 'kWh')}'
                      : 'Miễn phí',
                ),
                _buildStatRow(
                  CupertinoIcons.drop_fill,
                  const Color(0xFF69b1ff),
                  'Nước',
                  waterPrice > 0
                      ? '${_formatPrice(waterPrice)} đ/${_mapChargeType(waterPricingType, 'm³')}'
                      : 'Miễn phí',
                ),
                if (internetPrice > 0)
                  _buildStatRow(
                    CupertinoIcons.wifi,
                    const Color(0xFF69b1ff),
                    'Internet',
                    '${_formatPrice(internetPrice)} đ/${_mapChargeType(internetPricingType, 'phòng')}',
                  ),
                if (parkingPrice > 0)
                  _buildStatRow(
                    CupertinoIcons.car_detailed,
                    const Color(0xFF69b1ff),
                    'Gửi xe',
                    '${_formatPrice(parkingPrice)} đ/${_mapChargeType(parkingPricingType, 'xe')}',
                  ),
                if (trashPrice > 0)
                  _buildStatRow(
                    CupertinoIcons.trash_fill,
                    const Color(0xFF69b1ff),
                    'Rác',
                    '${_formatPrice(trashPrice)} đ/${_mapChargeType(trashPricingType, 'phòng')}',
                  ),
                if (serviceFee > 0)
                  _buildStatRow(
                    CupertinoIcons.wrench_fill,
                    const Color(0xFF69b1ff),
                    'Phí dịch vụ',
                    '${_formatPrice(serviceFee)} đ/${_mapChargeType(servicePricingType, 'phòng')}',
                  ),
              ],
            ),
          ),

          // 5. Bản đồ & Địa chỉ (To và rõ ràng)
          _buildModernCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Vị trí',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    if (poiCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$poiCount tiện ích gần đây',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      CupertinoIcons.location_solid,
                      color: Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        address,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: onMapTap,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 180, // Bản đồ gọn gàng hơn
                      width: double.infinity,
                      child: Stack(
                        children: [
                          AbsorbPointer(
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: center,
                                initialZoom:
                                    16.5, // Zoom gần hơn để thấy tên đường
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: OsmMapService.tileUrl,
                                  subdomains: OsmMapService.tileSubdomains,
                                  userAgentPackageName: 'com.stayhub.app',
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: center,
                                      width: 40,
                                      height: 40,
                                      alignment: Alignment.topCenter,
                                      child: const Icon(
                                        CupertinoIcons.location_solid,
                                        color: Colors.red,
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            left: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(
                                  alpha: 0.9,
                                ), // Hiệu ứng trong suốt kính
                                borderRadius: BorderRadius.circular(
                                  50,
                                ), // Pill-shape
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 12,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.map_fill,
                                    size: 18,
                                    color: Color(0xFF69b1ff),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Mở bản đồ toàn màn hình',
                                    style: TextStyle(
                                      color: Color(0xFF69b1ff),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (pois.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: pois.map((poi) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.building_2_fill,
                              size: 14,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              poi,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),

          // 6. Mô tả
          if (description.isNotEmpty)
            _buildModernCard(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mô tả chi tiết',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF1E293B),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

          // 7. Chủ nhà
          _buildModernCard(
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage:
                          resolvedOwnerAvatar != null &&
                              resolvedOwnerAvatar.toString().isNotEmpty
                          ? NetworkImage(
                              ImageUrlHelper.buildUrl(resolvedOwnerAvatar) ??
                                  resolvedOwnerAvatar.toString(),
                            )
                          : null,
                      child:
                          resolvedOwnerAvatar == null ||
                              resolvedOwnerAvatar.toString().isEmpty
                          ? const Icon(
                              CupertinoIcons.person_fill,
                              color: Colors.grey,
                              size: 28,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resolvedOwnerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ownerSubtitle,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: onRequireLogin,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF69b1ff),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x3369b1ff),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Liên hệ',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildQuickStat(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF69b1ff).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 26, color: const Color(0xFF69b1ff)),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
