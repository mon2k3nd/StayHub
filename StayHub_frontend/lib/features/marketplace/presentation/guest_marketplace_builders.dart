// ================================================================
//  Guest Marketplace - State Class (fields, lifecycle, build)
//  Split into focused parts:
//    • guest_marketplace_map.dart      → map view, geocoding, radius
//    • guest_marketplace_filters.dart  → search sheet, filters, sorting
//    • guest_marketplace_nearby.dart   → nearby carousel, empty state
// ================================================================
part of 'guest_marketplace_screen.dart';

/// Shared state fields for every split part of the Guest Marketplace screen.
/// Declared in a mixin so all `part` files can read/write them while still
/// being able to call the protected `setState`.
mixin _GuestMarketplaceStateMixin on ConsumerState<GuestMarketplaceScreen> {
  // ── Geocoding cache ────────────────────────────────────────────────────────
  final Map<String, LatLng> _geocodedAddresses = {};
  final Set<String> _pendingGeocode = {};

  // ── Map state ──────────────────────────────────────────────────────────────
  bool _isMapView = false;
  LatLng _mapCenter = const LatLng(21.028511, 105.804817); // Default Hanoi
  final MapController _mapController = MapController();
  final TextEditingController _mapSearchController = TextEditingController();
  // Controller cho sheet tìm kiếm ở chế độ Danh sách. Trước đây tạo cục bộ
  // trong _buildSearchSheet → rò rỉ bộ nhớ vì không bao giờ được dispose.
  final TextEditingController _listSearchController = TextEditingController();
  final PageController _mapCarouselController = PageController(
    viewportFraction: 0.88,
  );
  int _currentCarouselIndex = 0;
  bool _isLocating = false;
  bool _isReloading = false;
  bool _showDistancePicker = false;
  String? _userAddress; // Địa chỉ thực tế của người dùng
  double _mapSearchRadius = 5.0; // km - mặc định ban đầu là 5km
  String? _mapSearchAddress; // Địa chỉ đang tìm kiếm trên bản đồ

  /// Safely coerces a raw price value (num / String / null) to a double.
  double extractPrice(dynamic priceRaw) {
    if (priceRaw == null) return 0.0;
    if (priceRaw is num) return priceRaw.toDouble();
    if (priceRaw is String) return double.tryParse(priceRaw) ?? 0.0;
    return 0.0;
  }
}

class _GuestMarketplaceScreenState extends ConsumerState<GuestMarketplaceScreen>
    with
        _GuestMarketplaceStateMixin,
        _GuestMarketplaceMapMixin,
        _GuestMarketplaceFiltersMixin,
        _GuestMarketplaceNearbyMixin {
  @override
  void initState() {
    super.initState();
    // Route riêng `/marketplace-map` mở thẳng chế độ Bản đồ.
    _isMapView = widget.initialMapView;
    unawaited(_getUserLocation());
  }

  @override
  void dispose() {
    _mapController.dispose();
    _mapSearchController.dispose();
    _listSearchController.dispose();
    _mapCarouselController.dispose();
    super.dispose();
  }

  // ── Feed shimmer ───────────────────────────────────────────────────────────
  // Light-theme shimmer: nền trắng, hiệu ứng xám nhạt.
  // Shimmer đen cũ (dark-mode) khiến màn hình chết đen hoàn toàn khi loading.
  Widget _buildFeedShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE5E7EB), // gray-200
      highlightColor: const Color(0xFFF9FAFB), // gray-50
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: Stack(
          children: [
            Container(color: const Color(0xFFF3F4F6)), // gray-100
            Positioned(
              right: 16,
              bottom: 100,
              child: Column(
                children: List.generate(
                  4,
                  (index) => Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 200, height: 24, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(width: 150, height: 16, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(width: 250, height: 16, color: Colors.white),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header actions ─────────────────────────────────────────────────────────
  void _openRoute(Widget screen) {
    try {
      unawaited(
        Navigator.push(context, CupertinoPageRoute(builder: (_) => screen)),
      );
    } catch (_) {
      // Navigation failure is non-fatal for guest browsing.
    }
  }

  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(publicRoomsFilterProvider);
    ref.listen<Map<String, dynamic>?>(mapSearchLocationProvider, (prev, next) {
      if (next != null && next['latLng'] != null) {
        final target = next['latLng'] as LatLng;
        setState(() {
          _mapCenter = target;
          // BUGFIX (data): trước đây ép `as String?` — nếu `query` là số/object
          // (JSON lỗi) thì ném TypeError. Dùng toString an toàn.
          _mapSearchAddress = next['query']?.toString();
        });
        _mapController.move(target, 14.0);
        _mapController.fitCamera(_getMapFit());
      }
    });

    final authUser = ref.watch(authProvider).value;
    final roomsAsync = ref.watch(sortedPublicRoomsProvider);
    final paginationStateAsync = ref.watch(publicRoomsProvider);
    final currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Scaffold(
      // Nền trắng — app dùng light theme. Nền đen cũ là thiết kế dark-mode
      // không nhất quán vđ làm màn hình chết đen khi API load chậm/fail.
      backgroundColor: AppTheme.kBackgroundLight,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background Layer: The Feed or Map ──
          _isMapView
              ? roomsAsync.when(
                  data: (rooms) => _buildMap(rooms, currencyFmt),
                  loading: () => const Center(
                    child: CupertinoActivityIndicator(color: Colors.white),
                  ),
                  error: (e, _) => AppErrorWidget(error: e),
                )
              : roomsAsync.when(
                  data: (rooms) {
                    final paginationState = paginationStateAsync.asData?.value;
                    final filteredRooms = rooms;
                    final wishlistState = ref.watch(wishlistProvider);
                    if (filteredRooms.isEmpty) {
                      return _buildEmptyState();
                    }
                    return GuestFeedView(
                      isGuest: authUser == null,
                      isKycVerified:
                          authUser != null && authUser.kycStatus == 'APPROVED',
                      rooms: filteredRooms,
                      currencyFmt: currencyFmt,
                      wishlistIds: wishlistState.ids,
                      bottomInset: widget.bottomInset,
                      isLoadingMore: paginationState?.isLoadingMore ?? false,
                      onLoadMore: (paginationState?.hasMore ?? false)
                          ? () => ref
                                .read(publicRoomsProvider.notifier)
                                .loadMore()
                          : null,
                      onToggleWishlist: (id) async {
                        if (authUser == null) {
                          GuestAuthBottomSheet.show(context);
                          return;
                        }

                        final roomData = rooms.firstWhere(
                          (r) =>
                              (r['id']?.toString() ??
                                  r['roomId']?.toString() ??
                                  '') ==
                              id,
                          orElse: () => <String, dynamic>{},
                        );
                        if (roomData.isNotEmpty) {
                          final wasLiked = wishlistState.ids.contains(id);
                          if (wasLiked) {
                            unawaited(HapticFeedback.mediumImpact());
                          } else {
                            unawaited(HapticFeedback.lightImpact());
                          }
                          await ref
                              .read(wishlistProvider.notifier)
                              .toggle(roomData);
                        }
                      },
                      onChatPressed: (room) {
                        if (authUser == null) {
                          GuestAuthBottomSheet.show(context);
                        } else {
                          final isKycVerified =
                              authUser.kycStatus == 'APPROVED';
                          if (!isKycVerified) {
                            unawaited(
                              showCupertinoDialog(
                                context: context,
                                builder: (ctx) => const EkycVerificationDialog(
                                  customContent:
                                      'Tài khoản của bạn cần được xác thực danh tính (EKYC) để nhắn tin cho chủ nhà.',
                                ),
                              ),
                            );
                            return;
                          }

                          final ownerId = room['ownerId'];
                          if (ownerId != null) {
                            unawaited(
                              ref
                                  .read(conversationProvider.notifier)
                                  .createOrGetThread(
                                    int.parse(ownerId.toString()),
                                    'INQUIRY',
                                  )
                                  .then((thread) {
                                    if (thread != null && context.mounted) {
                                      final ownerName =
                                          room['ownerName'] ??
                                          room['landlordName'] ??
                                          'Chủ nhà';
                                      unawaited(
                                        context.push(
                                          '/thread-message/${thread.id}',
                                          extra: {
                                            'title': ownerName,
                                            'initialRoomAttachment': room,
                                          },
                                        ),
                                      );
                                    }
                                  }),
                            );
                          }
                        }
                      },
                    );
                  },
                  loading: () => _buildFeedShimmer(),
                  error: (e, _) => AppErrorWidget(error: e),
                ),

          // ── Top Floating Header Layer ──
          // Ẩn khi được nhúng trong GuestHomeScreen (showTopHeader = false)
          // để tránh chồng lên toggle Danh sách/Lướt của màn cha.
          if (widget.showTopHeader)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  bottom: _isMapView ? 0 : 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black.withValues(alpha: 0.0),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              // Nếu mở qua route → quay lại màn trước
                              // Nếu embedded (showTopHeader=false) → không làm gì
                              if (widget.showTopHeader != false) {
                                unawaited(Navigator.of(context).maybePop());
                              }
                            },
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'StayHub',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black45,
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              if (authUser != null) ...[
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () =>
                                      _openRoute(const ChatListScreen()),
                                  child: const Icon(
                                    CupertinoIcons.chat_bubble_fill,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () => _openRoute(
                                    const RentalScanLandingScreen(),
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.qrcode_viewfinder,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () =>
                                      _openRoute(const BusinessLandingScreen()),
                                  child: const Icon(
                                    CupertinoIcons.briefcase_fill,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () =>
                                      _openRoute(const ProfileScreen()),
                                  child:
                                      authUser.avatar != null &&
                                          authUser.avatar!.isNotEmpty
                                      ? Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 1.5,
                                            ),
                                            image: DecorationImage(
                                              image: NetworkImage(
                                                authUser.avatar!,
                                              ),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        )
                                      : const Icon(
                                          CupertinoIcons
                                              .person_crop_circle_fill,
                                          color: Colors.white,
                                          size: 30,
                                        ),
                                ),
                              ] else ...[
                                // Guest mode: KHÔNG hiển thị nút Đăng nhập ở đây.
                                // Việc đăng nhập đã có ở tab \"Tôi\" (bottom nav),
                                // tránh nhồi nhét nhiều CTA vào màn lướt phòng.
                                const SizedBox.shrink(),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Bottom Search Layer ──
          // Khi nhúng trong GuestHomeScreen (showTopHeader = false), màn cha đã
          // chiếm phần trên bằng brand bar (cao ~62px) nên phải đẩy thanh tìm
          // kiếm xuống dưới brand bar để không đè lên logo/toggle.
          if (widget.showTopHeader)
            Positioned(
              top: _isMapView
                  ? null
                  : MediaQuery.of(context).padding.top +
                        (widget.showTopHeader ? 60 : 74),
              bottom: _isMapView
                  ? (widget.bottomInset +
                        MediaQuery.of(context).padding.bottom +
                        190)
                  : null,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quick Filters (map view only)
                  if (_isMapView)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 8,
                        left: 12,
                        right: 12,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildQuickFilterChip('🔥 Khuyến mãi', () {
                              ref
                                  .read(publicRoomsFilterProvider.notifier)
                                  .updateFilters(
                                    onlyPromo: !filterState.onlyPromo,
                                  );
                            }, filterState.onlyPromo),
                            _buildQuickFilterChip('Dưới 3tr', () {
                              if (filterState.maxPrice == 3000000) {
                                ref
                                    .read(publicRoomsFilterProvider.notifier)
                                    .updateFilters(maxPrice: -1);
                              } else {
                                ref
                                    .read(publicRoomsFilterProvider.notifier)
                                    .updateFilters(
                                      maxPrice: 3000000,
                                      minPrice: -1,
                                    );
                              }
                            }, filterState.maxPrice == 3000000),
                            _buildQuickFilterChip(
                              'Trọ',
                              () {
                                // Dùng MÃ canonical (PHONG_TRO) để khớp backend.
                                final has = filterState.roomTypes
                                    .map(RoomTypeCodes.toCode)
                                    .contains('PHONG_TRO');
                                ref
                                    .read(publicRoomsFilterProvider.notifier)
                                    .updateFilters(
                                      roomTypes: has ? [] : ['PHONG_TRO'],
                                    );
                              },
                              filterState.roomTypes
                                  .map(RoomTypeCodes.toCode)
                                  .contains('PHONG_TRO'),
                            ),
                            _buildQuickFilterChip(
                              'CC Mini',
                              () {
                                // Dùng MÃ canonical (CHUNG_CU_MINI) để khớp backend.
                                final has = filterState.roomTypes
                                    .map(RoomTypeCodes.toCode)
                                    .contains('CHUNG_CU_MINI');
                                ref
                                    .read(publicRoomsFilterProvider.notifier)
                                    .updateFilters(
                                      roomTypes: has ? [] : ['CHUNG_CU_MINI'],
                                    );
                              },
                              filterState.roomTypes
                                  .map(RoomTypeCodes.toCode)
                                  .contains('CHUNG_CU_MINI'),
                            ),
                            // BUGFIX: "VSKK" (vệ sinh khép kín) trước đây ghi mã
                            // tiện ích GIẢ 'private_bathroom' vào `amenities`.
                            // Backend lọc `furniture` bằng LIKE trên mã hoa nên
                            // 'PRIVATE_BATHROOM' KHÔNG tồn tại trong DB → chip
                            // này luôn trả về RỖNG. WC riêng là một BOOLEAN của
                            // backend (`privateBathroom`), nên phải đi qua
                            // `roomFeatures: ['khep_kin']` (được toQueryParams
                            // dịch thành `privateBathroom=true`).
                            _buildQuickFilterChip(
                              'VSKK',
                              () {
                                final has = filterState.roomFeatures.contains(
                                  'khep_kin',
                                );
                                ref
                                    .read(publicRoomsFilterProvider.notifier)
                                    .updateFilters(
                                      roomFeatures: has
                                          ? filterState.roomFeatures
                                                .where((f) => f != 'khep_kin')
                                                .toList()
                                          : [
                                              ...filterState.roomFeatures,
                                              'khep_kin',
                                            ],
                                    );
                              },
                              filterState.roomFeatures.contains('khep_kin'),
                            ),
                            // BUGFIX: dùng MÃ canonical 'AC' (không phải 'ac').
                            // Backend upper() nên 'ac' vẫn khớp, NHƯNG state lưu
                            // chữ thường khiến chip trong FilterSheet (so sánh mã
                            // hoa) không hiển thị "đang chọn" và pill lọc hiển
                            // thị mã thô. Nay đồng bộ mã canonical.
                            _buildQuickFilterChip('Điều hòa', () {
                              ref
                                  .read(publicRoomsFilterProvider.notifier)
                                  .updateFilters(
                                    amenities:
                                        filterState.amenities.contains('AC')
                                        ? filterState.amenities
                                              .where((a) => a != 'AC')
                                              .toList()
                                        : [...filterState.amenities, 'AC'],
                                  );
                            }, filterState.amenities.contains('AC')),
                            // BUGFIX: 'heater' KHÔNG tồn tại trong cột `furniture`
                            // (DB lưu 'BINH_NONG_LANH') → chip "Nóng lạnh" luôn
                            // trả RỖNG. Nay dùng đúng mã canonical.
                            _buildQuickFilterChip(
                              'Nóng lạnh',
                              () {
                                ref
                                    .read(publicRoomsFilterProvider.notifier)
                                    .updateFilters(
                                      amenities:
                                          filterState.amenities.contains(
                                            'BINH_NONG_LANH',
                                          )
                                          ? filterState.amenities
                                                .where(
                                                  (a) => a != 'BINH_NONG_LANH',
                                                )
                                                .toList()
                                          : [
                                              ...filterState.amenities,
                                              'BINH_NONG_LANH',
                                            ],
                                    );
                              },
                              filterState.amenities.contains('BINH_NONG_LANH'),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // ── Search Bar Row ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: Row(
                      children: [
                        // ── Search Field ──
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (_isMapView) {
                                unawaited(
                                  showCupertinoModalPopup(
                                    context: context,
                                    builder: (ctx) => _buildMapSearchSheet(ctx),
                                  ),
                                );
                              } else {
                                unawaited(
                                  showCupertinoModalPopup(
                                    context: context,
                                    builder: (ctx) => _buildSearchSheet(ctx),
                                  ),
                                );
                              }
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: _isMapView ? 10 : 0,
                                  sigmaY: _isMapView ? 10 : 0,
                                ),
                                child: Container(
                                  height: 46,
                                  decoration: BoxDecoration(
                                    // Ở chế độ Lướt (nền tối) dùng nền kính sáng
                                    // hơn để chữ trắng đủ tương phản, tránh chìm.
                                    color: _isMapView
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(50),
                                    border: Border.all(
                                      color: _isMapView
                                          ? Colors.white
                                          : Colors.white.withValues(
                                              alpha: 0.45,
                                            ),
                                      width: 1,
                                    ),
                                    boxShadow: _isMapView
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.1,
                                              ),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _isMapView
                                            ? CupertinoIcons.map_pin_ellipse
                                            : (filterState.keyword.isNotEmpty
                                                  ? CupertinoIcons.search
                                                  : (_userAddress != null
                                                        ? CupertinoIcons
                                                              .location_fill
                                                        : CupertinoIcons
                                                              .search)),
                                        color: _isMapView
                                            ? AppTheme.kBrandDeep
                                            : (_userAddress != null &&
                                                      filterState
                                                          .keyword
                                                          .isEmpty
                                                  ? AppTheme.kBrandLight
                                                  : Colors.white70),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _isMapView
                                            ? Text(
                                                _mapSearchAddress != null
                                                    ? _mapSearchAddress!
                                                    : (_userAddress != null
                                                          ? _userAddress!
                                                          : 'Nhập địa chỉ...'),
                                                style: TextStyle(
                                                  color:
                                                      (_mapSearchAddress !=
                                                              null ||
                                                          _userAddress != null)
                                                      ? AppTheme.kTextPrimary
                                                      : AppTheme.kTextSecondary,
                                                  fontSize: 14,
                                                  fontWeight:
                                                      (_mapSearchAddress !=
                                                              null ||
                                                          _userAddress != null)
                                                      ? FontWeight.w600
                                                      : FontWeight.normal,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              )
                                            : (_isLocating &&
                                                      filterState
                                                          .keyword
                                                          .isEmpty
                                                  ? const Text(
                                                      'Đang xác định vị trí...',
                                                      style: TextStyle(
                                                        color: Colors.white60,
                                                        fontSize: 14,
                                                      ),
                                                    )
                                                  : Text(
                                                      filterState
                                                              .keyword
                                                              .isNotEmpty
                                                          ? filterState.keyword
                                                          : (_userAddress !=
                                                                    null
                                                                ? _userAddress!
                                                                : 'Tìm kiếm phòng trọ...'),
                                                      style: TextStyle(
                                                        color:
                                                            filterState
                                                                    .keyword
                                                                    .isEmpty &&
                                                                _userAddress ==
                                                                    null
                                                            ? Colors.white60
                                                            : Colors.white,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            filterState
                                                                    .keyword
                                                                    .isNotEmpty ||
                                                                _userAddress !=
                                                                    null
                                                            ? FontWeight.w600
                                                            : FontWeight.normal,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    )),
                                      ),
                                      if (!_isMapView &&
                                          filterState.keyword.isNotEmpty)
                                        GestureDetector(
                                          onTap: () => ref
                                              .read(
                                                publicRoomsFilterProvider
                                                    .notifier,
                                              )
                                              .updateFilters(keyword: ''),
                                          child: const Icon(
                                            CupertinoIcons.xmark_circle_fill,
                                            color: Colors.white60,
                                            size: 16,
                                          ),
                                        ),
                                      if (_isMapView &&
                                          _mapSearchAddress != null)
                                        GestureDetector(
                                          onTap: () => setState(() {
                                            _mapSearchAddress = null;
                                          }),
                                          child: const Icon(
                                            CupertinoIcons.xmark_circle_fill,
                                            color: Colors.white60,
                                            size: 16,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // ── Radius Dropdown (Map View only) ──
                        if (_isMapView) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _showRadiusPicker,
                            child: Container(
                              height: 46,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.circle_grid_hex_fill,
                                    color: AppTheme.kAccentColor,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_mapSearchRadius.toStringAsFixed(0)}km',
                                    style: const TextStyle(
                                      color: AppTheme.kTextPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        // ── Filter Button ──
                        GestureDetector(
                          onTap: () => _showFilterModal(context),
                          child: Container(
                            height: 46,
                            width: 46,
                            decoration: BoxDecoration(
                              // Khi có bộ lọc đang bật ⇒ dùng gradient Sky Blue
                              // để nổi bật; ngược lại dùng nền kính đồng bộ với
                              // thanh tìm kiếm.
                              gradient:
                                  (filterState.maxPrice != null ||
                                      filterState.minPrice != null ||
                                      filterState.minArea != null ||
                                      (filterState.roomTypes.isNotEmpty
                                              ? filterState.roomTypes.first
                                              : null) !=
                                          null ||
                                      filterState.province != null ||
                                      filterState.onlyPromo ||
                                      filterState.amenities.isNotEmpty)
                                  ? PremiumGradients.skyBrand
                                  : null,
                              color:
                                  (filterState.maxPrice != null ||
                                      filterState.minPrice != null ||
                                      filterState.minArea != null ||
                                      (filterState.roomTypes.isNotEmpty
                                              ? filterState.roomTypes.first
                                              : null) !=
                                          null ||
                                      filterState.province != null ||
                                      filterState.onlyPromo ||
                                      filterState.amenities.isNotEmpty)
                                  ? null
                                  : (_isMapView
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.22)),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                color: _isMapView
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.45),
                                width: 1,
                              ),
                              boxShadow: _isMapView
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.slider_horizontal_3,
                                  color:
                                      (filterState.maxPrice != null ||
                                          filterState.minPrice != null ||
                                          filterState.minArea != null ||
                                          (filterState.roomTypes.isNotEmpty
                                                  ? filterState.roomTypes.first
                                                  : null) !=
                                              null ||
                                          filterState.province != null ||
                                          filterState.onlyPromo ||
                                          filterState.amenities.isNotEmpty)
                                      ? Colors.white
                                      : (_isMapView
                                            ? AppTheme.kAccentColor
                                            : Colors.white),
                                  size: 20,
                                ),
                                if (filterState.maxPrice != null ||
                                    filterState.minPrice != null ||
                                    filterState.minArea != null ||
                                    (filterState.roomTypes.isNotEmpty
                                            ? filterState.roomTypes.first
                                            : null) !=
                                        null ||
                                    filterState.province != null ||
                                    filterState.onlyPromo ||
                                    filterState.amenities.isNotEmpty)
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.orangeAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        // ── Map Toggle Button (List View only) ──
                        // Ẩn khi nhúng trong GuestHomeScreen vì màn cha đã có
                        // nút Bản đồ riêng ở header.
                        if (!_isMapView && widget.showTopHeader) ...[
                          const SizedBox(width: 8),
                          // ── Map Entry → mở route riêng /marketplace-map ──
                          GestureDetector(
                            onTap: () {
                              try {
                                unawaited(context.push('/marketplace-map'));
                              } catch (_) {
                                // Bỏ qua lỗi điều hướng trong guest mode.
                              }
                            },
                            child: Container(
                              height: 46,
                              width: 46,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                CupertinoIcons.map,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Filter Pills (kept if user has applied filters)
                  if (filterState.maxPrice != null ||
                      filterState.minPrice != null ||
                      filterState.minArea != null ||
                      filterState.maxArea != null ||
                      (filterState.roomTypes.isNotEmpty
                              ? filterState.roomTypes.first
                              : null) !=
                          null ||
                      filterState.province != null ||
                      filterState.onlyPromo ||
                      filterState.amenities.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 8,
                        left: 12,
                        right: 12,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (filterState.province != null)
                              _buildFilterPill(
                                '📍 $filterState.province',
                                () => ref
                                    .read(publicRoomsFilterProvider.notifier)
                                    .updateFilters(province: ''),
                              ),
                            if (filterState.onlyPromo)
                              _buildFilterPill(
                                '🔥 Khuyến mãi',
                                () => ref
                                    .read(publicRoomsFilterProvider.notifier)
                                    .updateFilters(onlyPromo: false),
                              ),
                            if ((filterState.roomTypes.isNotEmpty
                                    ? filterState.roomTypes.first
                                    : null) !=
                                null)
                              _buildFilterPill(
                                // BUGFIX: trước đây hiển thị MÃ THÔ (vd
                                // 'PHONG_TRO') trên pill → người dùng thấy mã
                                // kỹ thuật. Nay dùng nhãn tiếng Việt canonical.
                                '🏠 ${RoomTypeCodes.labelOf(filterState.roomTypes.first)}',
                                () => ref
                                    .read(publicRoomsFilterProvider.notifier)
                                    .updateFilters(roomTypes: []),
                              ),
                            if (filterState.minPrice != null ||
                                filterState.maxPrice != null)
                              _buildFilterPill(
                                'Giá: ${filterState.minPrice != null ? '${(filterState.minPrice! / 1e6).toStringAsFixed(0)}tr' : '0'} – ${filterState.maxPrice != null ? '${(filterState.maxPrice! / 1e6).toStringAsFixed(0)}tr' : '∞'}',
                                () {
                                  ref
                                      .read(publicRoomsFilterProvider.notifier)
                                      .updateFilters(minPrice: -1);
                                  ref
                                      .read(publicRoomsFilterProvider.notifier)
                                      .updateFilters(maxPrice: -1);
                                },
                              ),
                            if (filterState.minArea != null ||
                                filterState.maxArea != null)
                              _buildFilterPill(
                                'DT: ${filterState.minArea ?? 0}m² – ${filterState.maxArea ?? "∞"}m²',
                                () {
                                  ref
                                      .read(publicRoomsFilterProvider.notifier)
                                      .updateFilters(minArea: -1, maxArea: -1);
                                },
                              ),
                            for (final a in filterState.amenities)
                              _buildFilterPill(_amenityLabel(a), () {
                                final newAmenities = List<String>.from(
                                  filterState.amenities,
                                );
                                newAmenities.remove(a);
                                ref
                                    .read(publicRoomsFilterProvider.notifier)
                                    .updateFilters(amenities: newAmenities);
                              }),
                          ],
                        ),
                      ),
                    ),

                  // ── Nearby Section / Location Banner ──
                  if (!_isMapView) _buildNearbySection(context, ref),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
