# -*- coding: utf-8 -*-
file_path = r"c:\Users\PHD\Desktop\StayHub\StayHub_frontend\lib\features\marketplace\presentation\wishlist_screen.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# 1. Thêm hàm _buildWishlistSkeleton để thay thế spinner giữa màn hình
skeleton_method = """  // ─── Liquid Glass Shimmer Skeleton Loading ─────────────────────────────────
  Widget _buildWishlistSkeleton(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          child: AdaptiveGlass(
            shape: const LiquidRoundedSuperellipse(borderRadius: 26),
            settings: const LiquidGlassSettings(blur: 20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.85),
                  width: 1.2,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Skeleton thumbnail
                  Container(
                    width: 94,
                    height: 94,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFFE2E8F0).withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(width: 13),
                  // Skeleton lines
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 130,
                          height: 14,
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: 90,
                          height: 18,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF69B1FF).withValues(alpha: 0.15)
                                : const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
"""

if "_buildWishlistSkeleton" not in content:
    content = content.replace(
        "  // ─── Quản lý Địa chỉ Cơ quan / Trường học (Tính năng 1) ───────────────────",
        skeleton_method + "\n  // ─── Quản lý Địa chỉ Cơ quan / Trường học (Tính năng 1) ───────────────────"
    )

# 2. Thay thế loading spinner giữa màn hình (CupertinoActivityIndicator giữa màn hình)
old_loading_indicator = """                // ── Tab View Content OR Map View ─────────────────────
                Expanded(
                  child: loading
                      ? const Center(
                          child: CupertinoActivityIndicator(radius: 14),
                        )
                      : _isMapView"""

new_loading_indicator = """                // ── Tab View Content OR Map View ─────────────────────
                Expanded(
                  child: loading && total == 0
                      ? _buildWishlistSkeleton(isDark)
                      : _isMapView"""

if old_loading_indicator in content:
    content = content.replace(old_loading_indicator, new_loading_indicator)
    print("Replaced central loading spinner with skeleton & seamless in-place refresh!")
else:
    print("Warning: old_loading_indicator not found")

# 3. Nâng cấp _buildLiquidGlassRefreshIndicator:
# Thiết kế hiệu ứng Dynamic Island / Liquid Droplet siêu đẹp mắt ở đỉnh:
# Khác biệt hoàn toàn so với vòng tròn đơn điệu
old_refresh_indicator = """  Widget _buildLiquidGlassRefreshIndicator(
    BuildContext context,
    RefreshIndicatorMode refreshState,
    double pulledExtent,
    double refreshTriggerPullDistance,
    double refreshIndicatorExtent,
    bool isDark,
  ) {
    final double percentageComplete =
        (pulledExtent / refreshTriggerPullDistance).clamp(0.0, 1.0);

    // Kích hoạt rung nhẹ Haptic Feedback khi kéo vừa tới ngưỡng
    if (percentageComplete >= 1.0 && !_hasTriggeredRefreshHaptic) {
      _hasTriggeredRefreshHaptic = true;
      HapticFeedback.mediumImpact();
    } else if (percentageComplete < 0.3) {
      _hasTriggeredRefreshHaptic = false;
    }

    final bool isRefreshing = refreshState == RefreshIndicatorMode.refresh ||
        refreshState == RefreshIndicatorMode.armed;

    if (pulledExtent <= 0) return const SizedBox.shrink();

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
    );
  }"""

new_refresh_indicator = """  Widget _buildLiquidGlassRefreshIndicator(
    BuildContext context,
    RefreshIndicatorMode refreshState,
    double pulledExtent,
    double refreshTriggerPullDistance,
    double refreshIndicatorExtent,
    bool isDark,
  ) {
    final double percentage =
        (pulledExtent / refreshTriggerPullDistance).clamp(0.0, 1.0);

    // Haptic feedback khi kéo vừa tới ngưỡng kích hoạt
    if (percentage >= 1.0 && !_hasTriggeredRefreshHaptic) {
      _hasTriggeredRefreshHaptic = true;
      HapticFeedback.mediumImpact();
    } else if (percentage < 0.3) {
      _hasTriggeredRefreshHaptic = false;
    }

    final bool isRefreshing = refreshState == RefreshIndicatorMode.refresh ||
        refreshState == RefreshIndicatorMode.armed;

    if (pulledExtent <= 0 && !isRefreshing) return const SizedBox.shrink();

    // Tính toán chiều rộng viên thuốc co giãn đàn hồi theo lực kéo (từ 38px -> 130px)
    final double pillWidth = isRefreshing
        ? 135.0
        : (38.0 + (percentage * 92.0)).clamp(38.0, 130.0);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          height: 36,
          width: pillWidth,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      const Color(0xFF1E293B).withValues(alpha: 0.90),
                      const Color(0xFF0F172A).withValues(alpha: 0.95),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.95),
                      const Color(0xFFEFF6FF).withValues(alpha: 0.90),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: percentage >= 1.0 || isRefreshing
                  ? const Color(0xFF69B1FF)
                  : Colors.white.withValues(alpha: isDark ? 0.2 : 0.85),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF69B1FF).withValues(
                  alpha: isRefreshing ? 0.35 : (percentage * 0.20),
                ),
                blurRadius: isRefreshing ? 16 : 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: isRefreshing
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CupertinoActivityIndicator(radius: 7),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Đang làm mới',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  )
                : percentage < 0.6
                    ? Transform.rotate(
                        angle: percentage * 3.14159 * 2,
                        child: Icon(
                          CupertinoIcons.arrow_down,
                          size: 15,
                          color: isDark ? Colors.white70 : const Color(0xFF2563EB),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.rotate(
                            angle: percentage * 3.14159 * 2,
                            child: Icon(
                              CupertinoIcons.arrow_2_circlepath,
                              size: 14,
                              color: percentage >= 1.0
                                  ? const Color(0xFF2563EB)
                                  : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            percentage >= 1.0 ? 'Thả tay' : 'Kéo tiếp',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: percentage >= 1.0
                                  ? const Color(0xFF2563EB)
                                  : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }"""

if old_refresh_indicator in content:
    content = content.replace(old_refresh_indicator, new_refresh_indicator)
    print("Upgraded to elastic Liquid Island droplet pull-to-refresh!")
else:
    print("Warning: old_refresh_indicator not found")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("All smooth refresh upgrades applied successfully!")
