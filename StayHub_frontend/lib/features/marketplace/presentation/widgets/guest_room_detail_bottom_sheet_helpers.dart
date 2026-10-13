part of 'guest_room_detail_bottom_sheet.dart';

final NumberFormat _globalFmt = NumberFormat.currency(
  locale: 'vi_VN',
  symbol: 'đ',
);

/// Pure UI helpers, dialogs and small builders for
/// [_GuestRoomDetailBottomSheetState].
///
/// Extracted to keep the main state file focused. None of these members call
/// `setState`, so they are safe to live in an extension on the state class.
extension _GuestRoomDetailHelpers on _GuestRoomDetailBottomSheetState {
  /// Mask phone number: 0912345678 → 09*****78
  /// Tuân thủ NĐ 13/2023/NĐ-CP về bảo vệ dữ liệu cá nhân
  // ignore: unused_element
  String _maskPhone(String phone) {
    if (phone.isEmpty) return 'Chưa cập nhật';
    if (phone.length <= 4) return '****';
    final start = phone.substring(0, 2);
    final end = phone.substring(phone.length - 2);
    final mask = '*' * (phone.length - 4);
    return '$start$mask$end';
  }

  // ignore: unused_element
  Widget _buildPillStat(IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.kBackgroundLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.kAccentColor, size: 20),
          const SizedBox(width: 10),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ],
      ),
    );
  }

  /// New stat chip: icon + value (large) + label (small below)
  // ignore: unused_element
  Widget _buildStatChip(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.kBackgroundLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.kBorderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.kAccentColor, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.kTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showToast(BuildContext ctx, String msg) {
    final overlay = Overlay.of(ctx);
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 24,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: CupertinoColors.darkBackgroundGray.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              msg,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () {
      if (entry.mounted) entry.remove();
    });
  }

  // ignore: unused_element
  Widget _buildSimilarRooms(String currentRoomId, double currentPrice) {
    return Consumer(
      builder: (context, ref, child) {
        final roomsAsync = ref.watch(publicRoomsProvider);
        return roomsAsync.when(
          data: (state) {
            final similarRooms = state.rooms
                .where((r) => r['id'].toString() != currentRoomId)
                .take(4)
                .toList();
            if (similarRooms.isEmpty) return const SizedBox();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Phòng tương tự',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: similarRooms.length,
                    itemBuilder: (context, index) {
                      final r = similarRooms[index];
                      final images = _extractImages(r);
                      final imgUrl = images.isNotEmpty
                          ? images.first
                          : 'https://via.placeholder.com/300x200';
                      final priceStr = _globalFmt.format(
                        _extractPrice(r['price']),
                      );

                      return GestureDetector(
                        onTap: () {
                          // Pass roomId to match app_router.dart expectation
                          final id = r['id'];
                          final roomId = id is int
                              ? id
                              : int.tryParse(id?.toString() ?? '');
                          if (roomId != null) {
                            context.pushReplacement(
                              '/guest-room-detail',
                              extra: {'roomId': roomId},
                            );
                          }
                        },
                        child: Container(
                          width: 160,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.kBackgroundLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.kBorderColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: CachedNetworkImage(
                                  imageUrl:
                                      ImageUrlHelper.buildUrl(imgUrl) ?? imgUrl,
                                  height: 110,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 400,
                                  errorWidget: (_, __, ___) => Container(
                                    height: 110,
                                    color: AppTheme.kSurfaceBlue,
                                    child: const Icon(
                                      CupertinoIcons.photo,
                                      color: AppTheme.kTextSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Phòng ${r['roomName'] ?? r['name']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      priceStr,
                                      style: const TextStyle(
                                        color: AppTheme.kAccentColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(
                                          CupertinoIcons.location_solid,
                                          size: 10,
                                          color: AppTheme.kTextSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            r['address'] ?? 'Khu vực này',
                                            style: const TextStyle(
                                              color: AppTheme.kTextSecondary,
                                              fontSize: 11,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox(),
          error: (_, __) => const SizedBox(),
        );
      },
    );
  }

  // ignore: unused_element
  Widget _buildTwoWayReviews() {
    if (_isLoadingReviews) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_reviews.isEmpty) return const SizedBox();

    // Calculate average rating
    double avgRating = 0.0;
    for (var r in _reviews) {
      avgRating += (r['rating'] != null
          ? double.tryParse(r['rating'].toString()) ?? 5.0
          : 5.0);
    }
    avgRating = _reviews.isNotEmpty ? avgRating / _reviews.length : 5.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.kBackgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.kTextMuted),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Đánh giá từ người thuê trước',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.star_fill,
                    color: CupertinoColors.systemYellow,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    avgRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${_reviews.length})',
                    style: TextStyle(
                      color: AppTheme.kTextSecondary.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._reviews.take(3).map((r) {
            String rawDate = r['createdAt'] ?? '';
            String formattedDate = 'Gần đây';
            try {
              if (rawDate.isNotEmpty) {
                DateTime dt = DateTime.parse(rawDate);
                formattedDate = 'Tháng ${dt.month}/${dt.year}';
              }
            } catch (_) {}

            return Column(
              children: [
                _buildReviewItem(
                  r['reviewerName'] ?? 'Người dùng',
                  formattedDate,
                  r['content'] ?? '',
                ),
                if (_reviews.indexOf(r) < _reviews.length - 1 &&
                    _reviews.indexOf(r) < 2)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: AppTheme.kBorderColor, height: 1),
                  ),
              ],
            );
          }),
          if (_reviews.length > 3) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 10),
                color: AppTheme.kSurfaceBlue,
                borderRadius: BorderRadius.circular(10),
                onPressed: () {
                  _showToast(
                    context,
                    'Tính năng xem tất cả đánh giá đang hoàn thiện',
                  );
                },
                child: Text(
                  'Xem tất cả ${_reviews.length} đánh giá',
                  style: const TextStyle(
                    color: CupertinoColors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewItem(String name, String date, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.kAccentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  // `name` có thể rỗng (reviewerName = '') → tránh RangeError.
                  name.isNotEmpty ? name[0] : '?',
                  style: const TextStyle(
                    color: AppTheme.kAccentColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: const TextStyle(
                    color: AppTheme.kTextSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.4,
            color: CupertinoColors.darkBackgroundGray,
          ),
        ),
      ],
    );
  }
}
