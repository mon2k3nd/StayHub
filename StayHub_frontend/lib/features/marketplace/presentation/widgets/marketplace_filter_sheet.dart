import 'package:flutter/cupertino.dart';
import '../../../../core/constants/room_type_codes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../room/application/public_rooms_filter_provider.dart';

class MarketplaceFilterSheet extends StatefulWidget {
  /// Metadata bộ lọc thật từ backend (khoảng giá/diện tích, tỉnh/thành, loại
  /// phòng...). Nếu null sẽ dùng giá trị mặc định an toàn.
  final PublicRoomsFilterMetadata? metadata;
  final double? initialMinPrice;
  final double? initialMaxPrice;
  final double? initialMinArea;
  final double? initialMaxArea;
  final String? initialRoomType;
  final String? initialProvince;
  final String initialSortBy;
  final Set<String> initialAmenities;
  final Set<String> initialRoomFeatures;
  final int? initialBedrooms;
  final int? initialBathrooms;
  final int? initialMaxGuests;
  final String? initialUsageType;
  final int? initialBeds;
  final Function(
    double? minPrice,
    double? maxPrice,
    double? minArea,
    double? maxArea,
    String? roomType,
    String? province,
    String sortBy,
    Set<String> amenities,
    Set<String> roomFeatures,
    int? bedrooms,
    int? bathrooms,
    int? maxGuests,
    String? usageType,
    int? beds,
  )
  onApply;

  const MarketplaceFilterSheet({
    super.key,
    this.metadata,
    this.initialMinPrice,
    this.initialMaxPrice,
    this.initialMinArea,
    this.initialMaxArea,
    this.initialRoomType,
    this.initialProvince,
    required this.initialSortBy,
    required this.initialAmenities,
    required this.initialRoomFeatures,
    this.initialBedrooms,
    this.initialBathrooms,
    this.initialMaxGuests,
    this.initialUsageType,
    this.initialBeds,
    required this.onApply,
  });

  @override
  State<MarketplaceFilterSheet> createState() => _MarketplaceFilterSheetState();
}

class _MarketplaceFilterSheetState extends State<MarketplaceFilterSheet> {
  late double tempMinPrice;
  late double tempMaxPrice;
  late double tempMinArea;
  late double tempMaxArea;
  String? tempRoomType;
  String? tempProvince;
  late String tempSortBy;
  late Set<String> tempAmenities;
  late Set<String> tempRoomFeatures;
  int tempBedrooms = -1;
  int tempBathrooms = -1;
  int tempMaxGuests = -1;
  String? tempUsageType;
  int tempBeds = -1;

  // ── Giá trị mặc định (fallback khi chưa có metadata) ────────────────────────
  static const double _defaultMaxPrice = 20000000; // 20 triệu
  static const double _defaultMinArea = 5;
  static const double _defaultMaxArea = 150;

  final List<String> _fallbackProvinces = [
    'Hà Nội',
    'TP. Hồ Chí Minh',
    'Đà Nẵng',
    'Cần Thơ',
    'Hải Phòng',
    'Hội An',
    'Huế',
    'Nha Trang',
    'Đà Lạt',
    'Vũng Tàu',
    'Quy Nhơn',
    'Bình Dương',
  ];

  /// Fallback dùng MÃ canonical (không phải nhãn, KHÔNG alias) để luôn khớp
  /// backend. Lưu ý: 'KY_TUC_XA' là alias của 'O_GHEP_KTX' — phải dùng mã
  /// canonical, nếu không bộ lọc sẽ gửi alias lên backend.
  final List<String> _fallbackRoomTypes = const [
    'PHONG_TRO',
    'CHUNG_CU_MINI',
    'STUDIO',
    'GAC_LUNG',
    'CHUNG_CU',
    'NHA_NGUYEN_CAN',
    'O_GHEP_KTX',
    'OFFICE',
  ];

  /// Danh sách tỉnh/thành: ưu tiên dữ liệu thật từ backend, fallback hard-code.
  List<String> get provinces {
    final meta = widget.metadata;
    if (meta != null && meta.provinces.isNotEmpty) return meta.provinces;
    return _fallbackProvinces;
  }

  /// Danh sách loại phòng (dạng MÃ canonical): ưu tiên dữ liệu thật từ backend,
  /// fallback hard-code. Backend trả mã thô (PHONG_TRO…) nên ta chuẩn hoá lại
  /// qua [RoomTypeCodes.toCode] để loại bỏ giá trị lạ và sắp xếp ổn định.
  List<String> get roomTypes {
    final meta = widget.metadata;
    if (meta != null && meta.roomTypes.isNotEmpty) {
      final codes = RoomTypeCodes.toCodes(meta.roomTypes);
      if (codes.isNotEmpty) return codes;
    }
    return _fallbackRoomTypes;
  }

  /// Giá tối đa cho slider (làm tròn lên mốc 1 triệu, tối thiểu 20 triệu).
  double get maxPriceBound {
    final meta = widget.metadata;
    if (meta == null || meta.maxPrice <= 0) return _defaultMaxPrice;
    final rounded = (meta.maxPrice / 1e6).ceil() * 1e6;
    return rounded < _defaultMaxPrice ? _defaultMaxPrice : rounded;
  }

  /// Diện tích tối đa cho slider (làm tròn lên mốc 5 m², tối thiểu 150 m²).
  double get maxAreaBound {
    final meta = widget.metadata;
    if (meta == null || meta.maxArea <= 0) return _defaultMaxArea;
    final rounded = (meta.maxArea / 5).ceil() * 5.0;
    return rounded < _defaultMaxArea ? _defaultMaxArea : rounded;
  }

  final List<(String, String)> sortOptions = [
    ('newest', 'Mới nhất'),
    ('distance', 'Gần tôi nhất'),
    ('price_asc', 'Giá thấp → cao'),
    ('price_desc', 'Giá cao → thấp'),
    ('area_asc', 'Diện tích nhỏ → lớn'),
  ];
  final List<(String, String)> roomFeatureOptions = [
    ('gac_lung', '🏗️ Gác lửng'),
    ('studio', '🛋️ Studio'),
    ('ban_cong', '🌅 Ban công'),
    ('cua_so', '🪟 Cửa sổ lớn'),
    ('khep_kin', '🚪 Khép kín'),
    ('full_noi_that', '🛏️ Full nội thất'),
  ];
  // BUGFIX: trước đây dùng mã CHỮ THƯỜNG ('wifi','ac','kitchen','washer'…).
  // Backend lọc `furniture` bằng LIKE trên mã HOA nên:
  //   - 'kitchen' → 'KITCHEN' KHÔNG tồn tại trong DB (thật là 'TU_BEP'/'BEP_TU')
  //   - 'washer'  → 'WASHER'  KHÔNG tồn tại (thật là 'MAY_GIAT')
  //   → chọn 2 chip này luôn trả RỖNG. Ngoài ra state lưu chữ thường khiến
  //   chip không hiển thị "đang chọn" và pill lọc hiển thị mã thô. Nay dùng
  //   đúng MÃ CANONICAL mà luồng tạo phòng ghi vào cột `furniture`.
  final List<(String, String)> amenityOptions = [
    ('WIFI', '📡 WiFi'),
    ('AC', '❄️ Điều hòa'),
    ('PARKING', '🚗 Chỗ xe'),
    ('TU_BEP', '🍳 Bếp'),
    ('MAY_GIAT', '🧴 Máy giặt'),
    ('SECURITY', '🔒 Bảo vệ'),
    ('BINH_NONG_LANH', '🚿 Nóng lạnh'),
    ('TU_LANH', '🧊 Tủ lạnh'),
    ('GIUONG', '🛏️ Giường'),
    ('ELEVATOR', '🛗 Thang máy'),
  ];

  @override
  void initState() {
    super.initState();
    tempMinPrice = widget.initialMinPrice ?? 0;
    tempMaxPrice = widget.initialMaxPrice ?? maxPriceBound;
    tempMinArea = widget.initialMinArea ?? _defaultMinArea;
    tempMaxArea = widget.initialMaxArea ?? maxAreaBound;
    tempRoomType = widget.initialRoomType;
    tempProvince = widget.initialProvince;
    tempSortBy = widget.initialSortBy;
    tempAmenities = Set.from(widget.initialAmenities);
    tempRoomFeatures = Set.from(widget.initialRoomFeatures);
    tempBedrooms = widget.initialBedrooms ?? -1;
    tempBathrooms = widget.initialBathrooms ?? -1;
    tempMaxGuests = widget.initialMaxGuests ?? -1;
    tempUsageType = widget.initialUsageType;
    tempBeds = widget.initialBeds ?? -1;
  }

  Widget section(String title) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
    child: Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
        color: Color(0xFF9CA3AF),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemGroupedBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Bộ Lọc Tìm Kiếm',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: const Text(
                    'Xóa tất cả',
                    style: TextStyle(
                      color: CupertinoColors.systemRed,
                      fontSize: 14,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      tempMinPrice = 0;
                      tempMaxPrice = maxPriceBound;
                      tempMinArea = _defaultMinArea;
                      tempMaxArea = maxAreaBound;
                      tempRoomType = null;
                      tempProvince = null;
                      tempSortBy = 'newest';
                      tempAmenities.clear();
                      tempRoomFeatures.clear();
                      tempBedrooms = -1;
                      tempBathrooms = -1;
                      tempMaxGuests = -1;
                      tempUsageType = null;
                      tempBeds = -1;
                    });
                  },
                ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: const Text(
                    'Xong',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  onPressed: () {
                    widget.onApply(
                      tempMinPrice > 0 ? tempMinPrice : null,
                      tempMaxPrice < maxPriceBound ? tempMaxPrice : null,
                      tempMinArea > _defaultMinArea ? tempMinArea : null,
                      tempMaxArea < maxAreaBound ? tempMaxArea : null,
                      tempRoomType,
                      tempProvince,
                      tempSortBy,
                      tempAmenities,
                      tempRoomFeatures,
                      tempBedrooms == -1 ? null : tempBedrooms,
                      tempBathrooms == -1 ? null : tempBathrooms,
                      tempMaxGuests == -1 ? null : tempMaxGuests,
                      tempUsageType,
                      tempBeds == -1 ? null : tempBeds,
                    );
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  section('Sắp xếp'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: sortOptions.map((opt) {
                      final isSelected = tempSortBy == opt.$1;
                      return GestureDetector(
                        onTap: () => setState(() => tempSortBy = opt.$1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.kAccentColor
                                : CupertinoColors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.kAccentColor
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Text(
                            opt.$2,
                            style: TextStyle(
                              color: isSelected
                                  ? CupertinoColors.white
                                  : const Color(0xFF374151),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  section('Khu vực'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: provinces.map((p) {
                      final isSelected = tempProvince == p;
                      return GestureDetector(
                        onTap: () => setState(
                          () => tempProvince = isSelected ? null : p,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.kAccentColor
                                : CupertinoColors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.kAccentColor
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Text(
                            p,
                            style: TextStyle(
                              color: isSelected
                                  ? CupertinoColors.white
                                  : const Color(0xFF374151),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  section('Phân loại'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: roomTypes.map((code) {
                      // `code` là MÃ canonical; hiển thị NHÃN thân thiện.
                      final isSelected = tempRoomType == code;
                      return GestureDetector(
                        onTap: () => setState(
                          () => tempRoomType = isSelected ? null : code,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.kAccentColor
                                : CupertinoColors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.kAccentColor
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Text(
                            RoomTypeCodes.labelOf(code),
                            style: TextStyle(
                              color: isSelected
                                  ? CupertinoColors.white
                                  : const Color(0xFF374151),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  section('Khoảng giá (triệu VNĐ/tháng)'),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Từ: ${(tempMinPrice / 1e6).toStringAsFixed(1)}tr',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppTheme.kAccentColor,
                              ),
                            ),
                            CupertinoSlider(
                              value: tempMinPrice.clamp(0, maxPriceBound),
                              min: 0,
                              max: maxPriceBound,
                              divisions: (maxPriceBound / 1e5).round().clamp(
                                1,
                                400,
                              ),
                              onChanged: (v) => setState(
                                () => tempMinPrice = v < tempMaxPrice
                                    ? v
                                    : tempMaxPrice - 500000,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Đến: ${(tempMaxPrice / 1e6).toStringAsFixed(1)}tr',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppTheme.kAccentColor,
                              ),
                            ),
                            CupertinoSlider(
                              value: tempMaxPrice.clamp(0, maxPriceBound),
                              min: 0,
                              max: maxPriceBound,
                              divisions: (maxPriceBound / 1e5).round().clamp(
                                1,
                                400,
                              ),
                              onChanged: (v) => setState(
                                () => tempMaxPrice = v > tempMinPrice
                                    ? v
                                    : tempMinPrice + 500000,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  section('Diện tích (m²)'),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Từ: ${tempMinArea.toInt()} m²',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppTheme.kAccentColor,
                              ),
                            ),
                            CupertinoSlider(
                              value: tempMinArea.clamp(
                                _defaultMinArea,
                                maxAreaBound,
                              ),
                              min: _defaultMinArea,
                              max: maxAreaBound,
                              divisions: ((maxAreaBound - _defaultMinArea) / 5)
                                  .round()
                                  .clamp(1, 200),
                              onChanged: (v) => setState(
                                () => tempMinArea = v < tempMaxArea
                                    ? v
                                    : tempMaxArea - 5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'Đến: ${tempMaxArea.toInt()} m²',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppTheme.kAccentColor,
                              ),
                            ),
                            CupertinoSlider(
                              value: tempMaxArea.clamp(
                                _defaultMinArea,
                                maxAreaBound,
                              ),
                              min: _defaultMinArea,
                              max: maxAreaBound,
                              divisions: ((maxAreaBound - _defaultMinArea) / 5)
                                  .round()
                                  .clamp(1, 200),
                              onChanged: (v) => setState(
                                () => tempMaxArea = v > tempMinArea
                                    ? v
                                    : tempMinArea + 5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (RoomTypeCodes.isApartmentLike(tempRoomType)) ...[
                    section('Chi tiết '),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Phòng ngủ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.kTextMuted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              CupertinoSegmentedControl<int>(
                                groupValue: tempBedrooms == -1
                                    ? null
                                    : tempBedrooms,
                                selectedColor: AppTheme.kAccentColor,
                                borderColor: AppTheme.kBorderColor,
                                children: const {
                                  -1: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text('Bất kỳ'),
                                  ),
                                  1: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text('1'),
                                  ),
                                  2: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text('2'),
                                  ),
                                  3: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text('3+'),
                                  ),
                                },
                                onValueChanged: (v) =>
                                    setState(() => tempBedrooms = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Phòng tắm / WC',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.kTextMuted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              CupertinoSegmentedControl<int>(
                                groupValue: tempBathrooms == -1
                                    ? null
                                    : tempBathrooms,
                                selectedColor: AppTheme.kAccentColor,
                                borderColor: AppTheme.kBorderColor,
                                children: const {
                                  -1: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text('Bất kỳ'),
                                  ),
                                  1: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text('1'),
                                  ),
                                  2: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text('2+'),
                                  ),
                                },
                                onValueChanged: (v) =>
                                    setState(() => tempBathrooms = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (RoomTypeCodes.isDormLike(tempRoomType)) ...[
                    section('Ký túc xá'),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Số giường',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.kTextMuted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              CupertinoSegmentedControl<int>(
                                groupValue: tempBeds == -1 ? null : tempBeds,
                                selectedColor: AppTheme.kAccentColor,
                                borderColor: AppTheme.kBorderColor,
                                children: const {
                                  -1: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text('Bất kỳ'),
                                  ),
                                  1: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text('1'),
                                  ),
                                  2: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text('2'),
                                  ),
                                  4: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text('4'),
                                  ),
                                  6: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: Text('6+'),
                                  ),
                                },
                                onValueChanged: (v) =>
                                    setState(() => tempBeds = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (RoomTypeCodes.isRoomLike(tempRoomType)) ...[
                    section('Loại hình sử dụng'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          [
                            {
                              'label': 'Phòng khép kín (WC Riêng)',
                              'val': 'PRIVATE',
                            },
                            {
                              'label': 'Phòng chung chủ (WC Chung)',
                              'val': 'SHARED',
                            },
                          ].map((opt) {
                            final isSelected = tempUsageType == opt['val'];
                            return GestureDetector(
                              onTap: () => setState(
                                () => tempUsageType = isSelected
                                    ? null
                                    : opt['val']?.toString(),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.kAccentColor
                                      : CupertinoColors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.kAccentColor
                                        : const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Text(
                                  (opt['label'] ?? '').toString(),
                                  style: TextStyle(
                                    color: isSelected
                                        ? CupertinoColors.white
                                        : const Color(0xFF374151),
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (tempRoomType != null &&
                      !RoomTypeCodes.isRoomLike(tempRoomType)) ...[
                    section('Số người tối đa'),
                    CupertinoSegmentedControl<int>(
                      groupValue: tempMaxGuests == -1 ? null : tempMaxGuests,
                      selectedColor: AppTheme.kAccentColor,
                      borderColor: AppTheme.kBorderColor,
                      children: const {
                        -1: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('Bất kỳ'),
                        ),
                        1: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('1'),
                        ),
                        2: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('2'),
                        ),
                        4: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('4+'),
                        ),
                      },
                      onValueChanged: (v) => setState(() => tempMaxGuests = v),
                    ),
                    const SizedBox(height: 16),
                  ],
                  section('Đặc điểm phòng'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: roomFeatureOptions.map((opt) {
                      final isSelected = tempRoomFeatures.contains(opt.$1);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (isSelected) {
                            tempRoomFeatures.remove(opt.$1);
                          } else {
                            tempRoomFeatures.add(opt.$1);
                          }
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.kAccentColor
                                : CupertinoColors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.kAccentColor
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Text(
                            opt.$2,
                            style: TextStyle(
                              color: isSelected
                                  ? CupertinoColors.white
                                  : const Color(0xFF374151),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  section('Tiện ích'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: amenityOptions.map((opt) {
                      final isSelected = tempAmenities.contains(opt.$1);
                      return GestureDetector(
                        onTap: () => setState(() {
                          if (isSelected) {
                            tempAmenities.remove(opt.$1);
                          } else {
                            tempAmenities.add(opt.$1);
                          }
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.kAccentColor
                                : CupertinoColors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.kAccentColor
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Text(
                            opt.$2,
                            style: TextStyle(
                              color: isSelected
                                  ? CupertinoColors.white
                                  : const Color(0xFF374151),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
