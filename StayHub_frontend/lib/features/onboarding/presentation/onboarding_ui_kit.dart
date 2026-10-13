part of 'onboarding_screen.dart';

/// Bộ UI kit dùng chung cho các trang Onboarding.
///
/// Chỉ chứa các builder thuần tuý (mọi dữ liệu đều truyền qua tham số),
/// không phụ thuộc animation controller hay state của `_OnboardingScreenState`.
class _OnboardingUiKit {
  const _OnboardingUiKit._();

  /// Badge kính mờ (glass badge) hiển thị icon + nhãn ngắn.
  static Widget glassBadge(
    IconData icon,
    String text,
    Color accent, {
    bool isDark = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: (isDark ? const Color(0xFF0F172A) : CupertinoColors.white)
                .withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: CupertinoColors.white.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.1),
                blurRadius: 20,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: isDark
                      ? CupertinoColors.white
                      : const Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Thẻ hiển thị khoảng cách phòng trọ trong minh hoạ Radar Map.
  static Widget distanceCard(
    String title,
    String dist,
    bool isBest,
    double pulse,
    Color accent,
  ) {
    return Container(
      width: isBest ? 160 : 150,
      padding: EdgeInsets.all(isBest ? 14 : 10),
      decoration: BoxDecoration(
        color: isBest
            ? const Color(0xFF1E3A8A)
            : const Color(0xFF1E293B).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isBest
              ? accent.withValues(alpha: 0.5 + pulse * 0.5)
              : CupertinoColors.white.withValues(alpha: 0.1),
          width: isBest ? 2.0 : 1.0,
        ),
        boxShadow: isBest
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.4 + pulse * 0.2),
                  blurRadius: 25,
                  spreadRadius: 2,
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.3),
                  blurRadius: 15,
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Distance Badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isBest ? 12 : 8,
              vertical: isBest ? 8 : 4,
            ),
            decoration: BoxDecoration(
              color: isBest ? accent : const Color(0xFF334155),
              borderRadius: BorderRadius.circular(20),
              boxShadow: isBest
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.5),
                        blurRadius: 10,
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.location_solid,
                  size: isBest ? 14 : 10,
                  color: CupertinoColors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  dist,
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: isBest ? 16 : 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: isBest ? 14 : 10),
          // Room icon placeholder
          Container(
            height: isBest ? 60 : 50,
            width: double.infinity,
            decoration: BoxDecoration(
              color: CupertinoColors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              CupertinoIcons.house_fill,
              color: CupertinoColors.white.withValues(alpha: 0.3),
              size: isBest ? 28 : 22,
            ),
          ),
          SizedBox(height: isBest ? 12 : 8),
          // Title
          Text(
            title,
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: isBest ? 13 : 11,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
