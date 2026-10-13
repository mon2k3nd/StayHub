// ================================================================
//  Guest Marketplace - Nearby Section Extension
//  (split from guest_marketplace_builders.dart to keep files manageable)
//  Contains: nearby branches carousel, permission nudge banner,
//            branch card, empty state.
// ================================================================
part of 'guest_marketplace_screen.dart';

mixin _GuestMarketplaceNearbyMixin on _GuestMarketplaceStateMixin {
  // ── Nearby Section ─────────────────────────────────────────────────────────
  Widget _buildNearbySection(BuildContext context, WidgetRef ref) {
    final locState = ref.watch(locationProvider);

    if (locState.status == LocationStatus.checking ||
        locState.isFetchingBranches) {
      // Loading skeleton
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: 3,
            itemBuilder: (ctx, idx) => Container(
              width: 240,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      );
    }

    if (locState.status == LocationStatus.denied ||
        locState.status == LocationStatus.deniedForever) {
      // Banner Nudge
      return Padding(
        padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.kAccentColor.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.location_slash_fill,
                  color: AppTheme.kAccentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Chưa bật vị trí',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bật vị trí để xem phòng trống gần bạn nhất',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                color: AppTheme.kAccentColor,
                borderRadius: BorderRadius.circular(20),
                onPressed: () {
                  if (locState.status == LocationStatus.deniedForever) {
                    unawaited(Geolocator.openAppSettings());
                  } else {
                    unawaited(
                      ref.read(locationProvider.notifier).requestPermission(),
                    );
                  }
                },
                child: const Text(
                  'Bật ngay',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (locState.nearbyBranches.isEmpty) {
      return const SizedBox();
    }

    // Horizontal Carousel
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.location_solid,
                  color: AppTheme.kAccentColor,
                  size: 14,
                ),
                SizedBox(width: 6),
                Text(
                  'Phòng gần bạn',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: locState.nearbyBranches.length,
              itemBuilder: (ctx, idx) {
                final branch = locState.nearbyBranches[idx];
                return _buildNearbyBranchCard(branch);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyBranchCard(Map<String, dynamic> branch) {
    final currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final distanceLabel = branch['distanceLabel'] ?? '';
    // BUGFIX: `imageUrls` là `dynamic` (JSON) → nếu backend trả String/Map
    // thay vì List thì `.isNotEmpty`/`[0]` ném NoSuchMethodError. Guard bằng
    // kiểm tra `is List` trước khi truy cập.
    final rawImageUrls = branch['imageUrls'];
    final imageUrl =
        branch['coverImageUrl'] ??
        (rawImageUrls is List && rawImageUrls.isNotEmpty
            ? rawImageUrls[0]
            : null);

    return GestureDetector(
      onTap: () {
        // Có thể mở bottom sheet detail nhánh hoặc list phòng của nhánh
      },
      child: Container(
        width: 260,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            // Image
            Container(
              width: 90,
              height: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(15),
                ),
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: Colors.grey[800],
              ),
              child: imageUrl == null
                  ? const Icon(
                      CupertinoIcons.building_2_fill,
                      color: Colors.white54,
                    )
                  : null,
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      branch['branchName'] ?? 'Chi nhánh',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.placemark_fill,
                          color: AppTheme.kAccentColor,
                          size: 10,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            distanceLabel,
                            style: const TextStyle(
                              color: AppTheme.kAccentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${branch['availableRooms'] ?? 0} phòng trống',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      // BUGFIX: `minPrice` có thể là String (JSON) → gọi thẳng
                      // NumberFormat.format sẽ ném TypeError. Dùng extractPrice
                      // (đã xử lý num/String/null) như ở map marker.
                      'Từ ${currencyFmt.format(extractPrice(branch['minPrice']))}',
                      style: const TextStyle(
                        color: Colors.greenAccent,
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
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    final filterState = ref.watch(publicRoomsFilterProvider);
    final bool hasActiveFilters =
        filterState.maxPrice != null ||
        filterState.minArea != null ||
        filterState.onlyPromo ||
        filterState.keyword.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0.8, end: 1.0),
              duration: const Duration(seconds: 1),
              curve: Curves.elasticOut,
              builder: (context, val, child) {
                return Transform.scale(
                  scale: val,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      // Nền tối (swipe view) ⇒ dùng tông sáng để không bị chìm.
                      color: Colors.white.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Icon(
                      CupertinoIcons.house_alt,
                      size: 56,
                      color: AppTheme.kBrandLight,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              hasActiveFilters
                  ? 'Không tìm thấy phòng nào'
                  : 'Chưa có phòng trống nào',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              hasActiveFilters
                  ? 'Rất tiếc, hiện không có phòng nào phù hợp với bộ lọc. Hãy thử điều chỉnh lại nhé!'
                  : 'Chủ nhà chưa đăng phòng nào. Kéo xuống để làm mới hoặc quay lại sau nhé!',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 15,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                if (hasActiveFilters) {
                  setState(() {
                    ref
                        .read(publicRoomsFilterProvider.notifier)
                        .updateFilters(maxPrice: -1);
                    ref
                        .read(publicRoomsFilterProvider.notifier)
                        .updateFilters(minArea: -1);
                    ref
                        .read(publicRoomsFilterProvider.notifier)
                        .updateFilters(onlyPromo: false);
                    ref
                        .read(publicRoomsFilterProvider.notifier)
                        .updateFilters(keyword: '');
                  });
                } else {
                  // Không có bộ lọc ⇒ có thể do mất kết nối backend.
                  // Cho người dùng thử tải lại thay vì màn hình trống.
                  unawaited(ref.read(publicRoomsProvider.notifier).refresh());
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.kBrandLight, AppTheme.kBrandDeep],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.kBrandDeep.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  hasActiveFilters ? 'Xóa bộ lọc & Thử lại' : 'Tải lại',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
