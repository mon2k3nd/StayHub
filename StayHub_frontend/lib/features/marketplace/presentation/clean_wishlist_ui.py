# -*- coding: utf-8 -*-
file_path = r"c:\Users\PHD\Desktop\StayHub\StayHub_frontend\lib\features\marketplace\presentation\wishlist_screen.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# 1. Bỏ Collection Filter Chips khỏi giao diện chính
# Tìm vị trí _buildCollectionFilterChips(isDark),
old_chip_call = """                // ── Liquid Glass Segmented Pill Tab Bar ──────────────
                _buildTabBar(
                  isDark,
                  available.length,
                  upcoming.length,
                  rented.length,
                ),

                // ── Liquid Glass Collection Filter Chips ──────────────
                _buildCollectionFilterChips(isDark),"""

new_chip_call = """                // ── Liquid Glass Segmented Pill Tab Bar ──────────────
                _buildTabBar(
                  isDark,
                  available.length,
                  upcoming.length,
                  rented.length,
                ),"""

if old_chip_call in content:
    content = content.replace(old_chip_call, new_chip_call)
    print("1. Removed collection filter chips row from UI")
else:
    print("Warning: old_chip_call not found")

# 2. Bỏ banner thông báo màu xanh rườm rà trong _buildList
old_banner_call = """        // ── Header Notice (Liquid Glass Platter) ─────────────────
        SliverToBoxAdapter(
          child: _buildNoticeBanner(tabType, isDark),
        ),"""

if old_banner_call in content:
    content = content.replace(old_banner_call, "")
    print("2. Removed notice banner from list view")
else:
    print("Warning: old_banner_call not found")

# 3. Tinh gọn lại _buildLiquidGlassRefreshIndicator:
# Thu nhỏ padding, chỉ hiện khi thực sự kéo, không chiếm chỗ cố định
old_refresh_builder = """    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Opacity(
          opacity: percentageComplete.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.7 + (percentageComplete * 0.3),
            child: AdaptiveGlass(
              shape: const LiquidRoundedSuperellipse(borderRadius: 50),
              settings: const LiquidGlassSettings(blur: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF1E293B).withValues(alpha: 0.85),
                            const Color(0xFF0F172A).withValues(alpha: 0.85),
                          ]
                        : [
                            Colors.white.withValues(alpha: 0.90),
                            const Color(0xFFF0F9FF).withValues(alpha: 0.85),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: const Color(0xFF69B1FF).withValues(
                      alpha: isDark ? 0.45 : 0.65,
                    ),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF69B1FF).withValues(
                        alpha: isRefreshing ? 0.35 : 0.15,
                      ),
                      blurRadius: isRefreshing ? 18 : 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isRefreshing) ...[
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CupertinoActivityIndicator(
                          radius: 7,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Đang cập nhật...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ] else ...[
                      Transform.rotate(
                        angle: percentageComplete * 3.14159 * 2,
                        child: Icon(
                          CupertinoIcons.arrow_2_circlepath,
                          size: 14,
                          color: percentageComplete >= 1.0
                              ? const Color(0xFF2563EB)
                              : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        percentageComplete >= 1.0
                            ? 'Thả tay để tải lại'
                            : 'Kéo để làm mới',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: percentageComplete >= 1.0
                              ? const Color(0xFF2563EB)
                              : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );"""

new_refresh_builder = """    if (pulledExtent <= 0) return const SizedBox.shrink();

    return Center(
      child: Container(
        height: 38,
        margin: const EdgeInsets.only(top: 6, bottom: 6),
        child: Opacity(
          opacity: percentageComplete.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.8 + (percentageComplete * 0.2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.90)
                    : Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: const Color(0xFF69B1FF).withValues(
                    alpha: isDark ? 0.35 : 0.6,
                  ),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF69B1FF).withValues(
                      alpha: isRefreshing ? 0.25 : 0.10,
                    ),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isRefreshing) ...[
                    const CupertinoActivityIndicator(radius: 7),
                    const SizedBox(width: 7),
                    Text(
                      'Đang cập nhật...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ] else ...[
                    Transform.rotate(
                      angle: percentageComplete * 3.14159 * 2,
                      child: Icon(
                        CupertinoIcons.arrow_2_circlepath,
                        size: 13,
                        color: percentageComplete >= 1.0
                            ? const Color(0xFF2563EB)
                            : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      percentageComplete >= 1.0
                          ? 'Thả để làm mới'
                          : 'Kéo để làm mới',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: percentageComplete >= 1.0
                            ? const Color(0xFF2563EB)
                            : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );"""

if old_refresh_builder in content:
    content = content.replace(old_refresh_builder, new_refresh_builder)
    print("3. Compacted liquid refresh indicator")
else:
    print("Warning: old_refresh_builder not found")

# 4. Tinh giản Card:
# Thay vì hiển thị cụm nút [Bút] [Tim] [Xem] xếp dọc làm hẹp cột tiêu đề và ép chữ rớt dòng:
# Chuyển thành: Thẻ phòng có tiêu đề dài tối đa 2 dòng, giá tiền to rõ,
# chỉ giữ Nút Tim và Nút Ghi chú gọn gàng ở góc trên bên phải!
old_card_title_and_actions = """                        Text(
                          name.toString().startsWith('Phòng')
                              ? name.toString()
                              : 'Phòng $name',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            letterSpacing: -0.3,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),"""

new_card_title_and_actions = """                        Text(
                          name.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            height: 1.25,
                            letterSpacing: -0.3,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),"""

if old_card_title_and_actions in content:
    content = content.replace(old_card_title_and_actions, new_card_title_and_actions)
    print("4. Updated card title to allow 2 lines naturally without ugly 'Phòng ' prefix repetition")
else:
    print("Warning: old_card_title_and_actions not found")

# Bỏ nút "Xem" xanh thừa thãi (vì bấm vào cả thẻ card đã mở xem chi tiết rồi)
old_view_btn = """                        if (isAvailable) ...[
                          const SizedBox(height: 8),
                          BounceClick(
                            scaleFactor: 0.92,
                            onPressed: onTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 5.5,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF69B1FF), Color(0xFF2563EB)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.35),
                                  width: 0.8,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2563EB)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Xem',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                        ],"""

if old_view_btn in content:
    content = content.replace(old_view_btn, "")
    print("5. Removed redundant 'Xem' button (tapping anywhere on the card opens detail)")
else:
    print("Warning: old_view_btn not found")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("All layout cleanups applied successfully!")
