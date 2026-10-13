// ================================================================
//  Guest Marketplace - Filters & Search Extension
//  (split from guest_marketplace_builders.dart to keep files manageable)
//  Contains: search sheet, filter modal, quick-filter chips, filter pills,
//            amenity labels, room filtering & sorting.
// ================================================================
part of 'guest_marketplace_screen.dart';

mixin _GuestMarketplaceFiltersMixin on _GuestMarketplaceStateMixin {
  // ── Search sheet ───────────────────────────────────────────────────────────
  Widget _buildSearchSheet(BuildContext ctx) {
    // Dùng lại controller đã được quản lý & dispose ở State thay vì tạo mới
    // mỗi lần build (trước đây tạo TextEditingController cục bộ → RÒ RỈ BỘ NHỚ).
    final controller = _listSearchController;
    // BUGFIX: KHÔNG gán `controller.text` trong build(). Trước đây dòng
    // `controller.text = filterState.keyword;` chạy mỗi lần rebuild → đặt lại
    // con trỏ về vị trí 0 và "giật" chữ đang gõ (mỗi lần provider notify do
    // gõ phím, cursor nhảy về đầu). Chỉ seed text MỘT LẦN khi mở sheet và
    // controller còn rỗng, để giữ nguyên nội dung người dùng đang nhập.
    if (controller.text.isEmpty) {
      final seed = ref.read(publicRoomsFilterProvider).keyword;
      if (seed.isNotEmpty) {
        controller.text = seed;
        controller.selection = TextSelection.collapsed(
          offset: controller.text.length,
        );
      }
    }

    // Áp dụng từ khoá: lưu lịch sử + cập nhật filter + đóng sheet.
    void applyKeyword(String value) {
      final v = value.trim();
      if (v.isEmpty) return;
      unawaited(RecentSearchService.add(v));
      ref
          .read(publicRoomsFilterProvider.notifier)
          .updateFilters(keyword: v.toLowerCase());
      Navigator.pop(ctx);
    }

    return Container(
      height: MediaQuery.of(ctx).size.height * 0.72,
      decoration: const BoxDecoration(
        color: AppTheme.kBackgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.kBorderColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tìm kiếm phòng trọ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.kTextPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tìm theo tên phòng, địa chỉ hoặc khu vực bạn muốn ở',
            style: TextStyle(fontSize: 13, color: AppTheme.kTextMuted),
          ),
          const SizedBox(height: 14),
          // Search input — pill kính, chữ rõ, đồng bộ design system.
          CupertinoTextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.search,
            placeholder: 'Nhập tên phòng, địa chỉ, khu vực...',
            placeholderStyle: const TextStyle(
              color: AppTheme.kTextMuted,
              fontSize: 15,
            ),
            style: const TextStyle(
              color: AppTheme.kTextPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            prefix: const Padding(
              padding: EdgeInsets.only(left: 14),
              child: Icon(
                CupertinoIcons.search,
                color: AppTheme.kBrand,
                size: 19,
              ),
            ),
            suffix: CupertinoButton(
              padding: const EdgeInsets.only(right: 10),
              onPressed: () => controller.clear(),
              child: const Icon(
                CupertinoIcons.clear_circled_solid,
                size: 18,
                color: AppTheme.kTextMuted,
              ),
            ),
            decoration: BoxDecoration(
              color: AppTheme.kSurface1Light,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: AppTheme.kBorderColor.withValues(alpha: 0.7),
              ),
              boxShadow: AppTheme.kPremiumShadowLight,
            ),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
            onSubmitted: applyKeyword,
          ),
          const SizedBox(height: 18),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Lịch sử tìm kiếm gần đây ──
                  FutureBuilder<List<String>>(
                    future: RecentSearchService.getSearches(),
                    builder: (context, snapshot) {
                      final items = snapshot.data ?? const <String>[];
                      if (items.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.time,
                                    size: 15,
                                    color: AppTheme.kTextMuted,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Tìm kiếm gần đây',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.kTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.kTextMuted.withValues(
                                    alpha: 0.05,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppTheme.kBorderColor.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      CupertinoIcons.search_circle,
                                      size: 32,
                                      color: AppTheme.kTextMuted.withValues(
                                        alpha: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Chưa có lịch sử tìm kiếm',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.kTextMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                CupertinoIcons.time,
                                size: 15,
                                color: AppTheme.kTextMuted,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Tìm kiếm gần đây',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.kTextSecondary,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () async {
                                  await RecentSearchService.clear();
                                  // BUGFIX: trước đây pop sheet rồi mở lại
                                  // `_buildSearchSheet` qua showCupertinoModalPopup
                                  // → sheet mới KHÔNG có `FutureBuilder` được
                                  // refresh (vẫn dùng future cũ đã cache) nên
                                  // danh sách lịch sử vẫn hiển thị dù đã xoá.
                                  // Nay chỉ cần setState để FutureBuilder chạy lại
                                  // `RecentSearchService.getSearches()` (future mới)
                                  // và cập nhật ngay tại chỗ, không đóng sheet.
                                  if (mounted) setState(() {});
                                },
                                child: const Text(
                                  'Xoá',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.kBrand,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: items
                                .map(
                                  (label) => _buildSearchChip(
                                    label,
                                    CupertinoIcons.time,
                                    () => applyKeyword(label),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),
                  // ── Gợi ý khu vực phổ biến ──
                  const Text(
                    'Khu vực phổ biến',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.kTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final label in const [
                        'Hà Nội',
                        'TP. Hồ Chí Minh',
                        'Đà Nẵng',
                        'Cần Thơ',
                        'Hải Phòng',
                        'Bình Dương',
                      ])
                        _buildSearchChip(
                          label,
                          CupertinoIcons.location,
                          () => applyKeyword(label),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // ── Lọc nhanh theo nhu cầu ──
                  const Text(
                    'Lọc nhanh theo nhu cầu',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.kTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildSearchChip(
                        'Phòng trọ giá rẻ',
                        CupertinoIcons.money_dollar_circle,
                        () {
                          // BUGFIX: trước đây chỉ set maxPrice/minPrice mà KHÔNG
                          // xoá keyword đang gõ → nếu người dùng đã nhập từ khoá
                          // rồi bấm chip này, kết quả vẫn bị lọc theo keyword cũ
                          // (giao của hai điều kiện) → ra rỗng/không như ý. Nay
                          // xoá keyword để chip lọc thuần theo giá.
                          ref
                              .read(publicRoomsFilterProvider.notifier)
                              .updateFilters(
                                maxPrice: 3000000,
                                minPrice: -1,
                                keyword: '',
                              );
                          Navigator.pop(ctx);
                        },
                      ),
                      // BUGFIX: trước đây gửi mã CHỮ THƯỜNG 'ac'/'wifi' và
                      // append thẳng vào danh sách → (1) backend so khớp token
                      // đã upper() nên 'ac' vẫn khớp, NHƯNG state lưu chữ thường
                      // khiến chip lọc trong FilterSheet không hiển thị "đang
                      // chọn" (so sánh với mã canonical 'AC'/'WIFI'); (2) bấm
                      // nhiều lần sẽ thêm trùng lặp vào mảng amenities. Nay dùng
                      // mã canonical + chống trùng.
                      _buildSearchChip('Có điều hòa', CupertinoIcons.snow, () {
                        final current = ref
                            .read(publicRoomsFilterProvider)
                            .amenities;
                        final next = {...current, 'AC'}.toList();
                        ref
                            .read(publicRoomsFilterProvider.notifier)
                            .updateFilters(amenities: next);
                        Navigator.pop(ctx);
                      }),
                      _buildSearchChip('Có WiFi', CupertinoIcons.wifi, () {
                        final current = ref
                            .read(publicRoomsFilterProvider)
                            .amenities;
                        final next = {...current, 'WIFI'}.toList();
                        ref
                            .read(publicRoomsFilterProvider.notifier)
                            .updateFilters(amenities: next);
                        Navigator.pop(ctx);
                      }),
                      _buildSearchChip(
                        'Chung cư mini',
                        CupertinoIcons.building_2_fill,
                        () {
                          // Gửi MÃ canonical (CHUNG_CU_MINI) để khớp backend.
                          // BUGFIX: xoá keyword đang gõ để chip lọc thuần theo
                          // loại phòng (trước đây giữ keyword cũ → giao điều kiện
                          // ra rỗng).
                          ref
                              .read(publicRoomsFilterProvider.notifier)
                              .updateFilters(
                                roomTypes: ['CHUNG_CU_MINI'],
                                keyword: '',
                              );
                          Navigator.pop(ctx);
                        },
                      ),
                      _buildSearchChip(
                        'Đang khuyến mãi',
                        CupertinoIcons.tag_fill,
                        () {
                          ref
                              .read(publicRoomsFilterProvider.notifier)
                              .updateFilters(onlyPromo: true);
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Confirm button — pill gradient Sky Blue đồng bộ toàn app.
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: PremiumGradients.skyBrand,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.kBrand.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(50),
                onPressed: () => applyKeyword(controller.text),
                child: const Text(
                  'Tìm kiếm',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search suggestion chip ─────────────────────────────────────────────────
  Widget _buildSearchChip(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppTheme.kSurfaceBlue,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: AppTheme.kBorderColor.withValues(alpha: 0.8),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.kBrandDeep),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.kBrandDeep,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Filter modal ───────────────────────────────────────────────────────────
  void _showFilterModal(BuildContext context) {
    final filterState = ref.watch(publicRoomsFilterProvider);
    // Metadata thật từ backend để slider giá/diện tích + chip tỉnh/thành,
    // loại phòng luôn khớp dữ liệu (fallback an toàn nếu chưa tải xong).
    final metadata = ref.read(publicRoomsFilterMetadataProvider).asData?.value;
    unawaited(
      GlassModalSheet.show(
        context: context,
        builder: (ctx) => MarketplaceFilterSheet(
          metadata: metadata,
          initialMinPrice: filterState.minPrice,
          initialMaxPrice: filterState.maxPrice,
          initialMinArea: filterState.minArea,
          initialMaxArea: filterState.maxArea,
          initialRoomType: filterState.roomTypes.isNotEmpty
              ? filterState.roomTypes.first
              : null,
          initialProvince: filterState.province,
          initialBedrooms: filterState.bedrooms,
          initialBathrooms: filterState.bathrooms,
          initialMaxGuests: filterState.maxGuests,
          initialUsageType: filterState.usageType,
          initialBeds: filterState.beds,
          initialSortBy: filterState.sortBy,
          initialAmenities: filterState.amenities.toSet(),
          initialRoomFeatures: filterState.roomFeatures.toSet(),
          onApply:
              (
                minPrice,
                maxPrice,
                minArea,
                maxArea,
                roomType,
                province,
                sortBy,
                amenities,
                roomFeatures,
                bedrooms,
                bathrooms,
                maxGuests,
                usageType,
                beds,
              ) {
                ref
                    .read(publicRoomsFilterProvider.notifier)
                    .updateFilters(
                      minPrice: minPrice ?? -1,
                      maxPrice: maxPrice ?? -1,
                      minArea: minArea ?? -1,
                      maxArea: maxArea ?? -1,
                      roomTypes: roomType != null ? [roomType] : [],
                      province: province ?? '',
                      sortBy: sortBy,
                      amenities: amenities.toList(),
                      roomFeatures: roomFeatures.toList(),
                      bedrooms: bedrooms ?? -1,
                      bathrooms: bathrooms ?? -1,
                      maxGuests: maxGuests ?? -1,
                      usageType: usageType ?? '',
                      beds: beds ?? -1,
                    );
              },
        ),
      ),
    );
  }

  // ── Quick filter chip ──────────────────────────────────────────────────────
  Widget _buildQuickFilterChip(
    String label,
    VoidCallback onTap,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          gradient: isSelected ? PremiumGradients.skyBrand : null,
          color: isSelected ? null : AppTheme.kBackgroundLight,
          borderRadius: BorderRadius.circular(50),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.kBrand.withValues(alpha: 0.32)
                  : Colors.black.withValues(alpha: 0.06),
              blurRadius: isSelected ? 14 : 8,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppTheme.kBorderColor.withValues(alpha: 0.9),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.kTextPrimary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ── Filter pill ────────────────────────────────────────────────────────────
  Widget _buildFilterPill(String label, VoidCallback onClear) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.kBrand.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: AppTheme.kBrand.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.kBrandDeep,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onClear,
            child: const Icon(
              CupertinoIcons.xmark_circle_fill,
              size: 15,
              color: AppTheme.kBrandDeep,
            ),
          ),
        ],
      ),
    );
  }

  String _amenityLabel(String key) {
    // BUGFIX: trước đây map chỉ có khoá CHỮ THƯỜNG ('wifi','ac'…) nên khi
    // state lưu MÃ CANONICAL HOA ('AC','WIFI','BINH_NONG_LANH'…) — đúng mã
    // backend so khớp trên cột `furniture` — pill lọc hiển thị mã thô thay vì
    // nhãn tiếng Việt. Nay dùng đúng mã canonical (đồng bộ với
    // room_search_filter_sheet._amenityLabel) và tra cứu không phân biệt
    // hoa/thường để dữ liệu legacy vẫn có nhãn.
    const map = {
      // ── Mã thật do luồng tạo phòng ghi vào cột `furniture` ──
      'AC': '❄️ Điều hoà',
      'TU_LANH': '🧊 Tủ lạnh',
      'MAY_GIAT': '🫧 Máy giặt',
      'GIUONG': '🛏️ Giường đệm',
      'TU_QUAN_AO': '🚪 Tủ quần áo',
      'BAN_GHE': '🪑 Bàn ghế',
      'SOFA': '🛋️ Sofa',
      'TU_BEP': '🗄️ Tủ bếp',
      'BEP_TU': '🔥 Bếp từ/gas',
      'LO_VI_SONG': '📻 Lò vi sóng',
      'HUT_MUI': '💨 Hút mùi',
      'BINH_NONG_LANH': '🚿 Bình nóng lạnh',
      'VOI_SEN': '🚿 Vòi sen',
      'BET': '🚽 Bệt xịt',
      // ── Alias/legacy (seed cũ, dữ liệu nhập tay) ──
      'WIFI': '📡 WiFi',
      'HEATER': '🚿 Bình nóng lạnh',
      'FRIDGE': '🧊 Tủ lạnh',
      'WASHER': '🫧 Máy giặt',
      'TV': '📺 Tivi',
      'BED': '🛏️ Giường',
      'WARDROBE': '🚪 Tủ quần áo',
      'KITCHEN': '🍳 Bếp',
      'PARKING': '🚗 Chỗ đỗ xe',
      'ELEVATOR': '🛗 Thang máy',
      'SECURITY': '🔒 Bảo vệ',
      'CAMERA': '📷 Camera',
      'BALCONY': '🌇 Ban công',
      'WINDOW': '🪟 Cửa sổ',
    };
    return map[key.toUpperCase()] ?? key;
  }
}
