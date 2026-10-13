import 'package:flutter/cupertino.dart';
import 'dart:math' as math;

import '../../../core/constants/room_type_codes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/liquid_glass_colors.dart';

import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart' show Colors, BoxShadow, Offset, showModalBottomSheet;
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/bounce_click.dart';
import '../../auth/application/auth_notifier.dart';
import '../../auth/presentation/widgets/guest_auth_bottom_sheet.dart';
import '../../marketplace/application/wishlist_provider.dart';
import '../../marketplace/presentation/ai_room_advisor_bottom_sheet.dart';
import '../../room/application/public_rooms_provider.dart';
import 'dart:convert';
import '../../../core/utils/image_url_helper.dart';
import 'dart:async' show unawaited;
import '../../../core/utils/toast_utils.dart';

class CommuteDestination {
  final String name;
  final String shortName;
  final String city;
  final String category;
  final double lat;
  final double lng;

  const CommuteDestination({
    required this.name,
    required this.shortName,
    required this.city,
    required this.category,
    required this.lat,
    required this.lng,
  });
}

class RoomSearchScreen extends ConsumerStatefulWidget {
  const RoomSearchScreen({super.key});

  @override
  ConsumerState<RoomSearchScreen> createState() => _RoomSearchScreenState();
}

class _RoomSearchScreenState extends ConsumerState<RoomSearchScreen> {
  // Commute Filter
  bool _isCommuteFilterEnabled = false;
  CommuteDestination? _selectedDestination;
  String _commuteMode = 'moto'; // 'moto' (xe máy) hoặc 'walk' (đi bộ)
  int _maxCommuteMinutes = 20;

  static const List<CommuteDestination> _presetDestinations = [
    // TP.HCM
    CommuteDestination(
      name: 'ĐH Bách Khoa TP.HCM (CS1 Q.10)',
      shortName: 'ĐH Bách Khoa HCM',
      city: 'Hồ Chí Minh',
      category: 'Đại học',
      lat: 10.7725,
      lng: 106.6578,
    ),
    CommuteDestination(
      name: 'ĐH Kinh Tế TP.HCM - UEH CS.B',
      shortName: 'UEH Q.10',
      city: 'Hồ Chí Minh',
      category: 'Đại học',
      lat: 10.7618,
      lng: 106.6669,
    ),
    CommuteDestination(
      name: 'KTX Khu B - ĐHQG TP.HCM (Thủ Đức)',
      shortName: 'KTX ĐHQG B',
      city: 'Hồ Chí Minh',
      category: 'Đại học',
      lat: 10.8752,
      lng: 106.7981,
    ),
    CommuteDestination(
      name: 'ĐH Sư Phạm Kỹ Thuật (Thủ Đức)',
      shortName: 'SPKT HCM',
      city: 'Hồ Chí Minh',
      category: 'Đại học',
      lat: 10.8507,
      lng: 106.7720,
    ),
    CommuteDestination(
      name: 'Tòa nhà Bitexco / Quận 1',
      shortName: 'Bitexco Q1',
      city: 'Hồ Chí Minh',
      category: 'Văn phòng',
      lat: 10.7716,
      lng: 106.7042,
    ),
    CommuteDestination(
      name: 'Landmark 81 (Bình Thạnh)',
      shortName: 'Landmark 81',
      city: 'Hồ Chí Minh',
      category: 'Văn phòng',
      lat: 10.7950,
      lng: 106.7218,
    ),
    // Hà Nội
    CommuteDestination(
      name: 'ĐH Bách Khoa Hà Nội (Hai Bà Trưng)',
      shortName: 'Bách Khoa HN',
      city: 'Hà Nội',
      category: 'Đại học',
      lat: 21.0056,
      lng: 105.8433,
    ),
    CommuteDestination(
      name: 'ĐH Quốc Gia Hà Nội (Cầu Giấy)',
      shortName: 'ĐHQG HN',
      city: 'Hà Nội',
      category: 'Đại học',
      lat: 21.0375,
      lng: 105.7820,
    ),
    CommuteDestination(
      name: 'ĐH Kinh Tế Quốc Dân (Hai Bà Trưng)',
      shortName: 'NEU Hà Nội',
      city: 'Hà Nội',
      category: 'Đại học',
      lat: 21.0003,
      lng: 105.8427,
    ),
    CommuteDestination(
      name: 'Keangnam Landmark 72 (Cầu Giấy)',
      shortName: 'Keangnam 72',
      city: 'Hà Nội',
      category: 'Văn phòng',
      lat: 21.0167,
      lng: 105.7836,
    ),
    CommuteDestination(
      name: 'Hồ Hoàn Kiếm / Phố Cổ',
      shortName: 'Hồ Gươm',
      city: 'Hà Nội',
      category: 'Trung tâm',
      lat: 21.0285,
      lng: 105.8542,
    ),
  ];

  // Filters
  double _maxPrice = 10000000;
  double _minArea = 0;
  String _selectedRegion = 'Tất cả';
  int _maxOccupants = 2;
  int _bedrooms = 1;
  int _bathrooms = 1;
  String _searchText = '';
  final TextEditingController _searchCtrl = TextEditingController();

  // Tags
  final Map<String, List<String>> _tagsByType = {
    'Tất cả': [
      'Có gác xép',
      'Cho nuôi thú cưng',
      'Có máy giặt',
      'Thang máy',
      'Ban công',
      'Giờ giấc tự do',
      'Bảo vệ 24/7',
    ],
    'Phòng trọ': [
      'Có gác xép',
      'Giờ giấc tự do',
      'Không chung chủ',
      'Chỗ để xe',
      'Có máy lạnh',
      'Cho nuôi thú cưng',
    ],
    'Chung cư mini': [
      'Bảo vệ 24/7',
      'Thang máy',
      'Bếp tách biệt',
      'Có ban công',
      'Full nội thất',
      'Hầm để xe',
    ],
    'Studio': [
      'Cửa sổ lớn',
      'Full nội thất',
      'Thang máy',
      'Giờ giấc tự do',
      'Máy giặt riêng',
    ],
    'Ở ghép': [
      'Bao điện nước',
      'Tìm nam',
      'Tìm nữ',
      'Có sẵn nội thất',
      'Giờ giấc tự do',
      'Bếp chung',
    ],
  };
  final Set<String> _selectedTags = {};

  // Room Types
  final List<String> _roomTypes = [
    'Phòng trọ',
    'Chung cư mini',
    'Studio',
    'Ở ghép',
  ];
  String _selectedType = 'Tất cả';
  final List<String> _regions = [
    'Tất cả',
    'Hà Nội',
    'Hồ Chí Minh',
    'Đà Nẵng',
    'Cần Thơ',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getDetailedInfo(dynamic info) {
    if (info == null) return {};
    if (info is Map<String, dynamic>) return info;
    if (info is String) {
      try {
        final decoded = jsonDecode(info);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (e) {
        debugPrint('Error: $e');
      }
    }
    if (info is Map) {
      return Map<String, dynamic>.from(info);
    }
    return {};
  }

  List<String> _extractImages(dynamic roomImages) {
    if (roomImages == null) {
      return ['https://images.unsplash.com/photo-1555854877-bab0e564b8d5'];
    }
    String imgStr = roomImages.toString();
    if (imgStr.isEmpty) {
      return ['https://images.unsplash.com/photo-1555854877-bab0e564b8d5'];
    }
    List<String> rawUrls = imgStr.split(',').map((e) => e.trim()).toList();
    return rawUrls.map((url) {
      return ImageUrlHelper.buildUrlOrFallback(
        url,
        'https://images.unsplash.com/photo-1555854877-bab0e564b8d5',
      );
    }).toList();
  }

  // ignore: unused_element
  String _extractImage(dynamic roomImages) {
    if (roomImages == null) {
      return 'https://images.unsplash.com/photo-1555854877-bab0e564b8d5';
    }
    String imgStr = roomImages.toString();
    if (imgStr.isEmpty) {
      return 'https://images.unsplash.com/photo-1555854877-bab0e564b8d5';
    }
    String firstImg = imgStr.contains(',')
        ? imgStr.split(',')[0].trim()
        : imgStr.trim();
    return ImageUrlHelper.buildUrlOrFallback(
      firstImg,
      'https://images.unsplash.com/photo-1555854877-bab0e564b8d5',
    );
  }

  List<String> _extractTags(Map<String, dynamic> info) {
    final tagsRaw = info['amenities'] ?? info['tags'];
    if (tagsRaw == null) return [];
    if (tagsRaw is List) {
      return tagsRaw.map((e) => e.toString().toLowerCase()).toList();
    }
    if (tagsRaw is String) {
      return tagsRaw.split(',').map((e) => e.trim().toLowerCase()).toList();
    }
    return [];
  }

  double _extractPrice(dynamic priceRaw) {
    if (priceRaw == null) return 0.0;
    if (priceRaw is num) return priceRaw.toDouble();
    if (priceRaw is String) return double.tryParse(priceRaw) ?? 0.0;
    return 0.0;
  }

  /// Uỷ quyền cho nguồn chân lý duy nhất [RoomTypeCodes] — không tự khai báo
  /// map riêng (trước đây map cục bộ bị lệch: thiếu CHUNG_CU/GAC_LUNG/CHDV…,
  /// và coi 'O_GHEP' là canonical trong khi canonical thật là 'O_GHEP_KTX').
  String _getRoomTypeLabel(String code) => RoomTypeCodes.labelOf(code);

  String _getRoomTypeCode(String label) => RoomTypeCodes.toCode(label) ?? label;

  void _openAiAdvisor() {
    unawaited(HapticFeedback.mediumImpact());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AiRoomAdvisorBottomSheet(
        onFiltersRecommended: (filters) {
          setState(() {
            if (filters.containsKey('maxPrice')) {
              final p = filters['maxPrice'];
              if (p is num) _maxPrice = p.toDouble().clamp(500000.0, 15000000.0);
            }
            if (filters.containsKey('minArea')) {
              final a = filters['minArea'];
              if (a is num) _minArea = a.toDouble().clamp(0.0, 100.0);
            }
            if (filters.containsKey('region')) {
              final r = filters['region'].toString();
              for (final reg in _regions) {
                if (reg != 'Tất cả' && r.toLowerCase().contains(reg.toLowerCase())) {
                  _selectedRegion = reg;
                  break;
                }
              }
            }
            if (filters.containsKey('roomType')) {
              final t = filters['roomType'].toString();
              for (final rt in _roomTypes) {
                if (t.toLowerCase().contains(rt.toLowerCase())) {
                  _selectedType = rt;
                  break;
                }
              }
            }
          });
          ToastUtils.show(context, '✨ Đã áp dụng gợi ý tìm phòng từ AI!');
        },
      ),
    );
  }

  double _calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742 * math.asin(math.sqrt(a));
  }

  Map<String, double> _getOrEstimateRoomCoordinates(
    dynamic room,
    Map<String, dynamic> detailedInfo,
  ) {
    final lat = detailedInfo['lat'] ?? detailedInfo['latitude'] ?? room['latitude'];
    final lng = detailedInfo['lng'] ?? detailedInfo['longitude'] ?? room['longitude'];
    if (lat is num && lng is num && lat != 0 && lng != 0) {
      return {'lat': lat.toDouble(), 'lng': lng.toDouble()};
    }

    final addr =
        '${room['address'] ?? ''} ${detailedInfo['region'] ?? ''} ${room['roomName'] ?? ''}'
            .toLowerCase();

    // TP.HCM
    if (addr.contains('quận 10') || addr.contains('q10') || addr.contains('q.10')) {
      return {'lat': 10.7715, 'lng': 106.6672};
    }
    if (addr.contains('quận 1') || addr.contains('q1') || addr.contains('q.1')) {
      return {'lat': 10.7769, 'lng': 106.7009};
    }
    if (addr.contains('quận 3') || addr.contains('q3') || addr.contains('q.3')) {
      return {'lat': 10.7844, 'lng': 106.6844};
    }
    if (addr.contains('bình thạnh') || addr.contains('binh thanh')) {
      return {'lat': 10.8015, 'lng': 106.7112};
    }
    if (addr.contains('thủ đức') || addr.contains('thu duc') || addr.contains('quận 9') || addr.contains('quận 2')) {
      return {'lat': 10.8500, 'lng': 106.7600};
    }
    if (addr.contains('tân bình') || addr.contains('tan binh')) {
      return {'lat': 10.8010, 'lng': 106.6550};
    }
    if (addr.contains('phú nhuận') || addr.contains('phu nhuan')) {
      return {'lat': 10.7990, 'lng': 106.6800};
    }
    if (addr.contains('gò vấp') || addr.contains('go vap')) {
      return {'lat': 10.8380, 'lng': 106.6660};
    }
    if (addr.contains('quận 7') || addr.contains('q7')) {
      return {'lat': 10.7340, 'lng': 106.7210};
    }
    if (addr.contains('quận 5') || addr.contains('q5')) {
      return {'lat': 10.7540, 'lng': 106.6630};
    }

    // Hà Nội
    if (addr.contains('cầu giấy') || addr.contains('cau giay')) {
      return {'lat': 21.0333, 'lng': 105.7944};
    }
    if (addr.contains('hai bà trưng') || addr.contains('hai ba trung')) {
      return {'lat': 21.0069, 'lng': 105.8524};
    }
    if (addr.contains('đống đa') || addr.contains('dong da')) {
      return {'lat': 21.0180, 'lng': 105.8299};
    }
    if (addr.contains('thanh xuân') || addr.contains('thanh xuan')) {
      return {'lat': 20.9980, 'lng': 105.8080};
    }
    if (addr.contains('nam từ liêm') || addr.contains('nam tu liem')) {
      return {'lat': 21.0182, 'lng': 105.7663};
    }
    if (addr.contains('bắc từ liêm') || addr.contains('bac tu liem')) {
      return {'lat': 21.0600, 'lng': 105.7500};
    }
    if (addr.contains('ba đình') || addr.contains('ba dinh')) {
      return {'lat': 21.0350, 'lng': 105.8250};
    }
    if (addr.contains('hoàng mai') || addr.contains('hoang mai')) {
      return {'lat': 20.9760, 'lng': 105.8500};
    }
    if (addr.contains('hà đông') || addr.contains('ha dong')) {
      return {'lat': 20.9720, 'lng': 105.7740};
    }

    if (addr.contains('hà nội') || addr.contains('ha noi')) {
      return {'lat': 21.0285, 'lng': 105.8542};
    }
    return {'lat': 10.7769, 'lng': 106.7009};
  }

  ({int minutes, double distanceKm})? _getCommuteInfo(
    dynamic room,
    Map<String, dynamic> detailedInfo,
  ) {
    if (!_isCommuteFilterEnabled || _selectedDestination == null) return null;
    final coords = _getOrEstimateRoomCoordinates(room, detailedInfo);
    final distKm = _calculateDistanceKm(
      coords['lat']!,
      coords['lng']!,
      _selectedDestination!.lat,
      _selectedDestination!.lng,
    );
    final minutes = _commuteMode == 'moto'
        ? (distKm * 1.35 / 25.0 * 60).round().clamp(1, 180)
        : (distKm * 1.25 / 4.5 * 60).round().clamp(1, 300);
    return (minutes: minutes, distanceKm: distKm);
  }

  List<dynamic> _applyFilters(List<dynamic> allRooms) {
    return allRooms.where((r) {
      final detailedInfo = _getDetailedInfo(r['detailedInfo']);
      final typeRaw =
          (detailedInfo['type'] ??
                  r['roomSubType'] ??
                  r['roomType'] ??
                  r['type'] ??
                  r['category'] ??
                  'PHONG_TRO')
              .toString()
              .trim()
              .toUpperCase();
      final region = detailedInfo['region'] ?? r['address'] ?? 'Hà Nội';
      final tags = _extractTags(detailedInfo);
      final price = _extractPrice(r['price']);
      final occupants = _extractPrice(r['maxGuests']).toInt();
      final area = _extractPrice(detailedInfo['area']);
      final beds = _extractPrice(detailedInfo['bedroomCount']).toInt();
      final baths = _extractPrice(detailedInfo['bathroomCount']).toInt();
      final name = (r['roomName'] ?? r['name'] ?? '').toString().toLowerCase();
      final address = (r['address'] ?? '').toString().toLowerCase();

      if (_searchText.isNotEmpty) {
        final q = _searchText.toLowerCase();
        if (!name.contains(q) && !address.contains(q)) return false;
      }
      if (_selectedRegion != 'Tất cả' &&
          !region.toString().contains(_selectedRegion)) {
        return false;
      }
      if (_selectedType != 'Tất cả') {
        final selectedCode = _getRoomTypeCode(_selectedType);
        // Match the raw key or fallback to the exact selected type for safety
        if (typeRaw != selectedCode && typeRaw != _selectedType.toUpperCase()) {
          return false;
        }
      }
      if (price > _maxPrice) return false;
      if (area > 0 && area < _minArea) return false;
      if (beds > 0 && beds < _bedrooms) return false;
      if (baths > 0 && baths < _bathrooms) return false;
      if (occupants > _maxOccupants) return false;
      if (_selectedTags.isNotEmpty) {
        if (!_selectedTags.every((tag) => tags.contains(tag.toLowerCase()))) {
          return false;
        }
      }
      if (_isCommuteFilterEnabled && _selectedDestination != null) {
        final commuteInfo = _getCommuteInfo(r, detailedInfo);
        if (commuteInfo != null && commuteInfo.minutes > _maxCommuteMinutes) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final roomsStateAsync = ref.watch(publicRoomsProvider);

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text(
              'Tìm Phòng',
              style: TextStyle(color: CupertinoColors.black),
            ),
            backgroundColor: const Color(0xFFF3F4F6),
            border: null,
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => context.pop(),
              child: const Icon(CupertinoIcons.back, color: Color(0xFF4B5563)),
            ),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                ToastUtils.show(context, 'Tính năng bản đồ đang phát triển');
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.map_pin_ellipse, size: 20),
                  SizedBox(width: 4),
                  Text(
                    'Bản đồ',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          // Search bar + AI Advisor
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      controller: _searchCtrl,
                      placeholder: 'Tìm theo tên, địa chỉ...',
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: Icon(
                          CupertinoIcons.search,
                          color: Color(0xFF9CA3AF),
                          size: 18,
                        ),
                      ),
                      clearButtonMode: OverlayVisibilityMode.editing,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      onChanged: (v) => setState(() => _searchText = v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  BounceClick(
                    onPressed: _openAiAdvisor,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF69B1FF), Color(0xFF298FFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF69B1FF).withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.sparkles,
                            color: CupertinoColors.white,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Hỏi AI',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
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

          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyFilterDelegate(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: _regions
                      .map(
                        (r) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildPill(
                            r,
                            isSelected: _selectedRegion == r,
                            onTap: () => setState(() => _selectedRegion = r),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(child: _buildFilterSection()),

          // Rooms count badge + results
          roomsStateAsync.when(
            loading: () => _buildSkeletonSliver(),
            error: (err, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      CupertinoIcons.wifi_slash,
                      color: AppTheme.kError,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      err.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF4B5563)),
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton.filled(
                      borderRadius: BorderRadius.circular(12),
                      child: const Text('Thử lại'),
                      onPressed: () => ref.refresh(publicRoomsProvider),
                    ),
                  ],
                ),
              ),
            ),
            data: (state) {
              final results = _applyFilters(state.rooms);
              return _buildResultsSliver(results, state);
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildResultsSliver(List<dynamic> results, PublicRoomsState state) {
    if (results.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.search,
                size: 48,
                color: const Color(0xFF4B5563).withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              const Text(
                'Không tìm thấy phòng phù hợp.',
                style: TextStyle(color: Color(0xFF4B5563)),
              ),
              const SizedBox(height: 8),
              if (state.hasMore)
                CupertinoButton(
                  onPressed: () =>
                      ref.read(publicRoomsProvider.notifier).loadMore(),
                  child: const Text('Tải thêm phòng'),
                ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            // Last item → load more trigger
            if (index == results.length) {
              if (state.isLoadingMore) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CupertinoActivityIndicator()),
                );
              }
              if (state.hasMore) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: CupertinoButton(
                    onPressed: () =>
                        ref.read(publicRoomsProvider.notifier).loadMore(),
                    child: const Text('Tải thêm phòng'),
                  ),
                );
              }
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    '✅ Đã tải hết tất cả phòng',
                    style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                  ),
                ),
              );
            }

            final room = results[index];
            return _buildRoomCard(room, index);
          },
          childCount: results.length + 1, // +1 for footer
        ),
      ),
    );
  }

  Widget _buildRoomCard(dynamic room, int index) {
    final detailedInfo = _getDetailedInfo(room['detailedInfo']);
    final tags = _extractTags(detailedInfo);
    final price = _extractPrice(room['price']);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + index * 50),
      curve: Curves.easeOut,
      builder: (ctx, val, child) => Opacity(
        opacity: val,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - val)),
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF298FFF).withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () =>
              context.push('/guest-room-detail', extra: {'roomId': room['id']}),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Stack(
                children: [
                  SizedBox(
                    height: 170,
                    child: PageView.builder(
                      itemCount: _extractImages(
                        room['roomImages'] ?? room['image'],
                      ).length,
                      itemBuilder: (context, idx) {
                        return Image.network(
                          _extractImages(
                            room['roomImages'] ?? room['image'],
                          )[idx],
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFE5E7EB),
                            child: const Center(
                              child: Icon(
                                CupertinoIcons.photo,
                                color: Color(0xFF9CA3AF),
                                size: 48,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Badges: HOT & Room type on the left
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemRed,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'HOT',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            _getRoomTypeLabel(
                              (detailedInfo['type'] ??
                                      room['roomSubType'] ??
                                      room['roomType'] ??
                                      room['type'] ??
                                      room['category'] ??
                                      'Phòng trọ')
                                  .toString()
                                  .trim(),
                            ),
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Interactive Heart Button on the right
                  Builder(
                    builder: (context) {
                      final propId = (room['id'] ?? room['roomId'])?.toString() ?? '';
                      final wishlistState = ref.watch(wishlistProvider);
                      final isWishlisted = propId.isNotEmpty && wishlistState.ids.contains(propId);

                      return Positioned(
                        top: 12,
                        right: 12,
                        child: BounceClick(
                          onPressed: () async {
                            if (ref.read(authProvider).value == null) {
                              unawaited(GuestAuthBottomSheet.show(context));
                              return;
                            }
                            unawaited(HapticFeedback.mediumImpact());
                            await ref.read(wishlistProvider.notifier).toggle(room);
                            if (context.mounted) {
                              ToastUtils.show(
                                context,
                                isWishlisted ? 'Đã bỏ lưu phòng' : 'Đã lưu phòng vào yêu thích',
                              );
                            }
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutCubic,
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isWishlisted
                                      ? Colors.white.withValues(alpha: 0.95)
                                      : Colors.black.withValues(alpha: 0.32),
                                  border: Border.all(
                                    color: isWishlisted
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.28),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    if (isWishlisted) ...[
                                      BoxShadow(
                                        color: const Color(0xFFFF3366).withValues(alpha: 0.35),
                                        blurRadius: 16,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 4),
                                      ),
                                    ] else ...[
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ],
                                ),
                                child: Center(
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 320),
                                    transitionBuilder: (child, anim) => ScaleTransition(
                                      scale: CurvedAnimation(
                                        parent: anim,
                                        curve: Curves.elasticOut,
                                      ),
                                      child: child,
                                    ),
                                    child: Icon(
                                      isWishlisted
                                          ? CupertinoIcons.heart_fill
                                          : CupertinoIcons.heart,
                                      key: ValueKey(isWishlisted),
                                      color: isWishlisted
                                          ? const Color(0xFFFF2D55)
                                          : Colors.white,
                                      size: isWishlisted ? 20 : 19,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Price badge
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF298FFF),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: const [
                          BoxShadow(color: Color(0x33298FFF), blurRadius: 12),
                        ],
                      ),
                      child: Text(
                        '${(price / 1000000).toStringAsFixed(1)} Triệu/tháng',
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Info
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room['roomName'] ?? room['name'] ?? 'Phòng trống',
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.location_solid,
                          size: 13,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            detailedInfo['region'] ??
                                room['address'] ??
                                'Hà Nội',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (_isCommuteFilterEnabled && _selectedDestination != null) ...[
                      Builder(
                        builder: (context) {
                          final commuteInfo = _getCommuteInfo(room, detailedInfo);
                          if (commuteInfo == null) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF69B1FF).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: const Color(0xFF69B1FF).withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _commuteMode == 'moto'
                                        ? CupertinoIcons.car_detailed
                                        : CupertinoIcons.person_badge_minus,
                                    size: 13,
                                    color: const Color(0xFF0284C7),
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      '~${commuteInfo.minutes} phút ${_commuteMode == 'moto' ? 'xe máy' : 'đi bộ'} đến ${_selectedDestination!.shortName} (${commuteInfo.distanceKm.toStringAsFixed(1)} km)',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0369A1),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: tags
                            .take(4)
                            .map(
                              (t) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Text(
                                  t,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF4B5563),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonSliver() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, i) => _SkeletonCard(),
          childCount: 4,
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Room Type
            _buildSectionTitle('Loại phòng'),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Tất cả', ..._roomTypes]
                    .map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildPill(
                          t,
                          isSelected: _selectedType == t,
                          onTap: () => setState(() {
                            _selectedType = t;
                            _selectedTags
                                .clear(); // Xóa tag cũ khi đổi loại phòng

                            // Cập nhật giá/diện tích default cho phù hợp với loại phòng
                            if (t == 'Ở ghép') {
                              _maxPrice = 3000000;
                            } else if (t == 'Studio') {
                              _maxPrice = 8000000;
                            } else if (t == 'Chung cư mini') {
                              _maxPrice = 12000000;
                            } else {
                              _maxPrice = 10000000;
                            }
                          }),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Price & Area
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Giá tối đa'),
                      CupertinoSlider(
                        value: _maxPrice,
                        min: 500000,
                        max: 15000000,
                        divisions: 29, // Bước nhảy 500k
                        activeColor: const Color(0xFF298FFF),
                        onChanged: (val) => setState(() => _maxPrice = val),
                      ),
                      Text(
                        'Dưới ${(_maxPrice / 1000000).toStringAsFixed(1)} Triệu',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Diện tích min'),
                      CupertinoSlider(
                        value: _minArea,
                        min: 0,
                        max: 100,
                        divisions: 20, // Bước nhảy 5m2
                        activeColor: const Color(0xFF298FFF),
                        onChanged: (val) => setState(() => _minArea = val),
                      ),
                      Text(
                        'Từ ${_minArea.toInt()} m²',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Counters
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCounter(
                  'Số người',
                  _maxOccupants,
                  (val) => setState(() => _maxOccupants = val),
                ),
                if (_selectedType == 'Tất cả' ||
                    _selectedType == 'Chung cư mini') ...[
                  _buildCounter(
                    'Phòng ngủ',
                    _bedrooms,
                    (val) => setState(() => _bedrooms = val),
                  ),
                  _buildCounter(
                    'Phòng tắm',
                    _bathrooms,
                    (val) => setState(() => _bathrooms = val),
                  ),
                ] else ...[
                  const Spacer(),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Tags
            _buildSectionTitle('Tiện ích'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (_tagsByType[_selectedType] ?? _tagsByType['Tất cả']!)
                  .map(
                    (t) => _buildPill(
                      t,
                      isSelected: _selectedTags.contains(t),
                      onTap: () => setState(() {
                        if (_selectedTags.contains(t)) {
                          _selectedTags.remove(t);
                        } else {
                          _selectedTags.add(t);
                        }
                      }),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 18),
            // Commute Filter Container
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isCommuteFilterEnabled
                    ? const Color(0xFF69B1FF).withValues(alpha: 0.08)
                    : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isCommuteFilterEnabled
                      ? const Color(0xFF69B1FF).withValues(alpha: 0.35)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.compass_fill,
                            size: 18,
                            color: _isCommuteFilterEnabled
                                ? const Color(0xFF0284C7)
                                : const Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Bán kính đi học / đi làm',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _isCommuteFilterEnabled
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFF374151),
                            ),
                          ),
                        ],
                      ),
                      CupertinoSwitch(
                        value: _isCommuteFilterEnabled,
                        activeTrackColor: const Color(0xFF298FFF),
                        onChanged: (val) {
                          setState(() {
                            _isCommuteFilterEnabled = val;
                            if (val && _selectedDestination == null) {
                              _selectedDestination = _presetDestinations.first;
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  if (_isCommuteFilterEnabled) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Chọn trường học / nơi làm việc:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _presetDestinations.map((dest) {
                          final isSel = _selectedDestination?.name == dest.name;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: BounceClick(
                              onPressed: () =>
                                  setState(() => _selectedDestination = dest),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? const Color(0xFF298FFF)
                                      : CupertinoColors.white,
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(
                                    color: isSel
                                        ? const Color(0xFF298FFF)
                                        : const Color(0xFFD1D5DB),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      dest.category == 'Đại học'
                                          ? '🎓 '
                                          : (dest.category == 'Văn phòng'
                                              ? '🏢 '
                                              : '📍 '),
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    Text(
                                      dest.shortName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSel
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSel
                                            ? CupertinoColors.white
                                            : const Color(0xFF1F2937),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Phương tiện & Thời gian di chuyển
                    Row(
                      children: [
                        // Chế độ xe máy / đi bộ
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: CupertinoColors.white,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildCommuteModeBtn('moto', '🛵 Xe máy'),
                              _buildCommuteModeBtn('walk', '🚶 Đi bộ'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Slider thời gian tối đa
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tối đa: $_maxCommuteMinutes phút',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0369A1),
                                ),
                              ),
                              CupertinoSlider(
                                value: _maxCommuteMinutes.toDouble(),
                                min: 5,
                                max: 45,
                                divisions: 8,
                                activeColor: const Color(0xFF298FFF),
                                onChanged: (v) => setState(
                                  () => _maxCommuteMinutes = v.round(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommuteModeBtn(String mode, String label) {
    final isSel = _commuteMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _commuteMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFF298FFF) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
            color: isSel ? CupertinoColors.white : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }

  Widget _buildCounter(String title, int value, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(title),
        Row(
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: value > 1 ? () => onChanged(value - 1) : null,
              child: Icon(
                CupertinoIcons.minus_circle,
                color: value > 1
                    ? const Color(0xFF298FFF)
                    : const Color(0xFFD1D5DB),
              ),
            ),
            Text(
              '$value',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: value < 10 ? () => onChanged(value + 1) : null,
              child: Icon(
                CupertinoIcons.add_circled,
                color: value < 10
                    ? const Color(0xFF298FFF)
                    : const Color(0xFFD1D5DB),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF6B7280),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildPill(
    String text, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF298FFF) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF298FFF)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? CupertinoColors.white : const Color(0xFF4B5563),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ── Skeleton Card ─────────────────────────────────────────────────────────────
class _SkeletonCard extends StatefulWidget {
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    unawaited(_ctrl.repeat(reverse: true));
    _anim = Tween<double>(
      begin: 0.06,
      end: 0.14,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final shimmer = Color.fromRGBO(0, 0, 0, _anim.value);
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Color(0x08000000), blurRadius: 16),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 170,
                color: shimmer,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 18,
                      width: 200,
                      decoration: BoxDecoration(
                        color: shimmer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 13,
                      width: 140,
                      decoration: BoxDecoration(
                        color: shimmer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: List.generate(
                        3,
                        (_) => Container(
                          margin: const EdgeInsets.only(right: 8),
                          height: 26,
                          width: 70,
                          decoration: BoxDecoration(
                            color: shimmer,
                            borderRadius: BorderRadius.circular(8),
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
      },
    );
  }
}

class _StickyFilterDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyFilterDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: const Color(0xFFF3F4F6), child: child);
  }

  @override
  double get maxExtent => 56;

  @override
  double get minExtent => 56;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
