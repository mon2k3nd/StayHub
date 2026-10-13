part of 'guest_home_screen.dart';

// ── Category Item (3D isometric + micro-animation) ────────────────────────────
class _CategoryItem extends StatefulWidget {
  final _Category category;
  final bool isActive;
  final VoidCallback onTap;

  const _CategoryItem({
    required this.category,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_CategoryItem> createState() => _CategoryItemState();
}

class _CategoryItemState extends State<_CategoryItem> {
  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 62,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: active ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              child: Image.asset(
                widget.category.imagePath,
                width: 48,
                height: 48,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                isAntiAlias: true,
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    CupertinoIcons.building_2_fill,
                    size: 32,
                    color: AppTheme.kBrand,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 16,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AppTheme.kBrandDeep : AppTheme.kTextSecondary,
                ),
                child: Text(
                  widget.category.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: active ? 22 : 0,
              height: 2.5,
              decoration: BoxDecoration(
                color: active ? AppTheme.kBrand : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Horizontal Section for Explore Feed ──────────────────────────────────────
class _HorizontalSection extends ConsumerWidget {
  final String title;
  final String? subtitle;
  final List<dynamic> properties;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;

  /// BUGFIX (UI/logic): nút "Xem thêm" trước đây có `onPressed: () {}` rỗng nên
  /// bấm vào không có tác dụng gì. Nay truyền callback để mở marketplace kèm
  /// bộ lọc tương ứng với section.
  final VoidCallback? onSeeMore;

  const _HorizontalSection({
    required this.title,
    this.subtitle,
    required this.properties,
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.onSeeMore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Cụm lỗi → hiển thị nút thử lại gọn gàng, không làm sập cả trang.
    if (error != null && properties.isEmpty) {
      return _SectionError(title: title, onRetry: onRetry);
    }
    // Cụm đang tải lần đầu → skeleton ngang mượt mà.
    if (isLoading && properties.isEmpty) {
      return _SectionSkeleton(title: title, subtitle: subtitle);
    }
    if (properties.isEmpty) return const SizedBox.shrink();

    final wishlistState = ref.watch(wishlistProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.kTextPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.kTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              BounceClick(
                onPressed: onSeeMore ?? () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.kSurface1Light,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  child: const Text(
                    'Xem thêm',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.kTextPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Mật độ hiển thị: thẻ gọn hơn (300px) + bề rộng 0.62 màn hình để
        // lộ ra ~1.6 thẻ → người dùng thấy nhiều lựa chọn hơn trên 1 màn hình.
        SizedBox(
          height: 300,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: properties.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (ctx, i) {
              final p = properties[i];
              final propId = (p['id'] ?? p['roomId'])?.toString() ?? '';
              final isWishlisted = propId.isNotEmpty && wishlistState.ids.contains(propId);

              return SizedBox(
                width: MediaQuery.of(context).size.width * 0.62,
                child: GuestPropertyCard(
                  property: p,
                  margin: EdgeInsets.zero,
                  imageHeight: 150,
                  isWishlisted: isWishlisted,
                  onToggleWishlist: () async {
                    if (ref.read(authProvider).value == null) {
                      unawaited(GuestAuthBottomSheet.show(ctx));
                      return;
                    }
                    unawaited(HapticFeedback.mediumImpact());
                    await ref.read(wishlistProvider.notifier).toggle(p);
                    if (ctx.mounted) {
                      ToastUtils.show(
                        ctx,
                        isWishlisted ? 'Đã bỏ lưu phòng' : 'Đã lưu phòng vào yêu thích',
                      );
                    }
                  },
                  onTap: () {
                    final id = p['id'];
                    final roomId = id is int
                        ? id
                        : int.tryParse(id?.toString() ?? '');
                    if (roomId == null || !ctx.mounted) return;
                    unawaited(
                      ctx.push('/guest-room-detail', extra: {'roomId': roomId}),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Section Skeleton (horizontal shimmer) ─────────────────────────────────────
class _SectionSkeleton extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionSkeleton({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.kTextPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.kTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 350,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 2,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, i) => SizedBox(
              width: MediaQuery.of(context).size.width * 0.75,
              child: _SkeletonCard(delay: i * 150),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Section Error (compact retry) ─────────────────────────────────────────────
class _SectionError extends StatelessWidget {
  final String title;
  final VoidCallback? onRetry;

  const _SectionError({required this.title, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppTheme.kTextPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.kSurface1Light,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.kBorderColor),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  color: AppTheme.kTextMuted,
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Không tải được mục này',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: AppTheme.kTextMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (onRetry != null)
                  BounceClick(
                    onPressed: onRetry!,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.kSurfaceBlue,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Text(
                        'Thử lại',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.kBrand,
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
  }
}

// ── Room List (Explore Feed) ─────────────────────────────────────────────────
class _RoomList extends ConsumerWidget {
  final AsyncValue<RoomSearchState> asyncState;
  final RoomSearchNotifier notifier;
  final double topPadding;

  const _RoomList({
    required this.asyncState,
    required this.notifier,
    required this.topPadding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = asyncState.value;
    final filter = state?.filter ?? RoomSearchFilter.empty;
    final items = state?.items ?? const <Map<String, dynamic>>[];
    final isLoading = asyncState.isLoading;
    final isLoadingMore = state?.isLoadingMore ?? false;
    final isFiltered = filter.activeCount > 0;

    if (isFiltered) {
      if (isLoading && items.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: topPadding + 24),
          child: const Center(
            child: CupertinoActivityIndicator(color: AppTheme.kBrand),
          ),
        );
      }
      if (asyncState.hasError && items.isEmpty) {
        return _ErrorView(onRetry: notifier.refresh);
      }
      if (items.isEmpty) {
        return const _EmptyView();
      }

      return AnimationLimiter(
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 120),
          physics: const BouncingScrollPhysics(),
          itemCount: items.length + (isLoadingMore ? 1 : 0),
          // Khoảng cách gọn hơn (12px) để hiển thị nhiều thẻ hơn trên 1 màn hình.
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == items.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CupertinoActivityIndicator(color: AppTheme.kBrand),
                ),
              );
            }
            final property = items[index];
            final propId = (property['id'] ?? property['roomId'])?.toString() ?? '';
            final wishlistState = ref.watch(wishlistProvider);
            final isWishlisted = propId.isNotEmpty && wishlistState.ids.contains(propId);

            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 375),
              child: SlideAnimation(
                verticalOffset: 50.0,
                child: FadeInAnimation(
                  child: GuestPropertyCard(
                    property: property,
                    // Ảnh thấp hơn (150px) → thẻ gọn, nhiều kết quả hơn mỗi màn hình.
                    imageHeight: 150,
                    isWishlisted: isWishlisted,
                    onToggleWishlist: () async {
                      if (ref.read(authProvider).value == null) {
                        unawaited(GuestAuthBottomSheet.show(context));
                        return;
                      }
                      unawaited(HapticFeedback.mediumImpact());
                      await ref.read(wishlistProvider.notifier).toggle(property);
                      if (context.mounted) {
                        ToastUtils.show(
                          context,
                          isWishlisted ? 'Đã bỏ lưu phòng' : 'Đã lưu phòng vào yêu thích',
                        );
                      }
                    },
                    onTap: () {
                      final id = property['id'];
                      final roomId = id is int
                          ? id
                          : int.tryParse(id?.toString() ?? '');
                      if (roomId == null || !context.mounted) return;
                      unawaited(
                        context.push(
                          '/guest-room-detail',
                          extra: {'roomId': roomId},
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    if (items.isEmpty && isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: topPadding + 24),
        child: const Center(
          child: CupertinoActivityIndicator(color: AppTheme.kBrand),
        ),
      );
    }

    // Dữ liệu Explore Feed lấy từ API (không còn mock data).
    final feed = ref.watch(exploreFeedProvider);
    final feedNotifier = ref.read(exploreFeedProvider.notifier);

    return ListView(
      padding: EdgeInsets.fromLTRB(0, topPadding + 16, 0, 120),
      physics: const BouncingScrollPhysics(),
      children: [
        for (final config in feed.configs) ...[
          Builder(
            builder: (_) {
              final s = feed.section(config.id);
              if (s.isEmpty) {
                return const SizedBox.shrink(); // Ẩn hoàn toàn nếu không có dữ liệu
              }
              return _HorizontalSection(
                title: config.title,
                subtitle: config.subtitle,
                properties: s.items,
                isLoading: s.isLoading,
                error: s.error,
                onRetry: () => feedNotifier.refreshSection(config.id),
                // BUGFIX (UI/logic): mở marketplace khi bấm "Xem thêm".
                onSeeMore: () {
                  if (!context.mounted) return;
                  unawaited(context.push('/guest-search'));
                },
              );
            },
          ),
          Builder(
            builder: (_) {
              final s = feed.section(config.id);
              if (s.isEmpty) return const SizedBox.shrink();
              return const SizedBox(height: 32);
            },
          ),
        ],
        if (isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: CupertinoActivityIndicator(color: AppTheme.kBrand),
            ),
          ),
      ],
    );
  }
}

// ── Empty & Error Views ───────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.kBrand.withValues(alpha: 0.15),
                  AppTheme.kBrand.withValues(alpha: 0.05),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: AppTheme.kBrand,
              size: 36,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Không tìm thấy phòng nào',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppTheme.kTextPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Thử điều chỉnh bộ lọc để xem thêm kết quả.',
            style: TextStyle(fontSize: 13.5, color: AppTheme.kTextMuted),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: Colors.orange,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Không tải được danh sách',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Kiểm tra kết nối và thử lại.',
              style: TextStyle(fontSize: 13.5, color: AppTheme.kTextMuted),
            ),
            const SizedBox(height: 24),
            BounceClick(
              onPressed: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  gradient: PremiumGradients.skyBrand,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.kBrand.withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Text(
                  'Thử lại',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
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

// ── Skeleton Loading ──────────────────────────────────────────────────────────
class _SkeletonList extends StatelessWidget {
  final double topPadding;
  const _SkeletonList({required this.topPadding});
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, topPadding + 16, 16, 200),
      itemCount: 4,
      itemBuilder: (_, i) => _SkeletonCard(delay: i * 150),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  final int delay;
  const _SkeletonCard({this.delay = 0});

  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) unawaited(_ctrl.repeat(reverse: true));
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        final shimmer = Color.lerp(
          const Color(0xFFE5EEF7),
          const Color(0xFFD6E7F8),
          t,
        )!;
        return Container(
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            color: AppTheme.kSurface1Light,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1469B1FF),
                blurRadius: 20,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: shimmer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 180,
                      height: 20,
                      decoration: BoxDecoration(
                        color: shimmer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      height: 14,
                      decoration: BoxDecoration(
                        color: shimmer,
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          width: 70,
                          height: 28,
                          decoration: BoxDecoration(
                            color: shimmer,
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 70,
                          height: 28,
                          decoration: BoxDecoration(
                            color: shimmer,
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                      ],
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

// ── Search Sheet (Liquid Glass, trượt xuống từ trên) ──────────────────────────
class _SearchSheet extends StatefulWidget {
  final String initial;
  final ValueChanged<String> onSearch;
  const _SearchSheet({required this.initial, required this.onSearch});

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit(String q) {
    widget.onSearch(q.trim());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final topSafe = MediaQuery.of(context).padding.top;

    return Padding(
      padding: EdgeInsets.only(top: topSafe + 8, left: 12, right: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: EdgeInsets.only(bottom: bottom + 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.kBrand.withValues(alpha: 0.18),
                  blurRadius: 40,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppTheme.kBorderColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 16),

                // Header row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF0F4FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: AppTheme.kTextPrimary,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Tìm kiếm',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.kTextPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          try {
                            unawaited(context.push('/qr-scanner'));
                          } catch (_) {}
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner_rounded,
                            size: 19,
                            color: AppTheme.kTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Card tìm kiếm ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppTheme.kBrand.withValues(alpha: 0.15),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.kBrand.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(18, 16, 18, 8),
                          child: Text(
                            'Lưu trú ở đâu?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.kTextPrimary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F4FF),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(left: 14),
                                  child: Icon(
                                    Icons.search_rounded,
                                    color: AppTheme.kBrand,
                                    size: 20,
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _ctrl,
                                    autofocus: true,
                                    onSubmitted: _submit,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.kTextPrimary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    decoration: const InputDecoration(
                                      hintText: 'Tìm kiếm điểm đến...',
                                      hintStyle: TextStyle(
                                        color: AppTheme.kTextMuted,
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(18, 4, 18, 6),
                          child: Text(
                            'Tìm kiếm gần đây',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.kTextMuted,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        ...['Hà Nội', 'TP. Hồ Chí Minh', 'Đà Nẵng'].map(
                          (r) => InkWell(
                            onTap: () => _submit(r),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: AppTheme.kSurfaceBlue,
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: const Icon(
                                      CupertinoIcons.building_2_fill,
                                      size: 18,
                                      color: AppTheme.kBrand,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    r,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.kTextPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Thời gian + Khách ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppTheme.kBorderColor.withValues(alpha: 0.6),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.kSurfaceBlue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              color: AppTheme.kBrand,
                              size: 20,
                            ),
                          ),
                          title: const Text(
                            'Thời gian',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.kTextPrimary,
                            ),
                          ),
                          trailing: const Text(
                            'Chọn',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.kBrand,
                            ),
                          ),
                        ),
                        Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: AppTheme.kBorderColor.withValues(alpha: 0.5),
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTheme.kSurfaceBlue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              CupertinoIcons.person_2_fill,
                              color: AppTheme.kBrand,
                              size: 18,
                            ),
                          ),
                          title: const Text(
                            'Khách',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.kTextPrimary,
                            ),
                          ),
                          trailing: const Text(
                            '1 Người lớn',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.kBrand,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Footer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _ctrl.clear()),
                        child: const Text(
                          'Xoá tất cả',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.kTextMuted,
                            decoration: TextDecoration.underline,
                            decorationColor: AppTheme.kTextMuted,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // ── The primary action is a piece of glass, not a pill ──
                      //
                      // It used to be a sky-brand gradient pill with a 0.4-alpha
                      // brand glow — the single most plastic object on the
                      // screen. A gradient fill is a fake material and a glow is
                      // light the object does not emit.
                      //
                      // What replaces it: a thick lens. The brand is carried as
                      // a tint *inside* the glass, so it is modulated by the same
                      // thickness field as everything else — denser at the rim,
                      // brighter at the centre. The label sits on top of the
                      // material, never inside it.
                      GlassInteractive(
                        onTap: () => _submit(_ctrl.text),
                        builder: (context, state) => GlassSurface(
                          thickness: GlassThickness.thick,
                          radius: 50,

                          elevation: 0.7,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Brand carried as optical tint, not as a fill.
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(50),
                                      color: AppTheme.kBrand.withValues(
                                        alpha: 0.16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 38,
                                  vertical: 15,
                                ),
                                child: Text(
                                  'Tìm kiếm',
                                  style: TextStyle(
                                    color: AppTheme.kBrandDeep,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
