import 'package:flutter/cupertino.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/liquid_background.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/utils/toast_utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../application/dashboard_notifier.dart';
import '../../../core/providers/dashboard_refresh.dart';
import '../../../core/components/app_error_widget.dart';
import 'dart:async' show unawaited;

class OwnerSubscriptionScreen extends ConsumerStatefulWidget {
  const OwnerSubscriptionScreen({super.key});

  @override
  ConsumerState<OwnerSubscriptionScreen> createState() =>
      _OwnerSubscriptionScreenState();
}

final saasPlansProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final client = ref.watch(apiClientProvider);
  try {
    final response = await client.get('/v1/owner/saas/plans');
    if (response['success'] == true && response['data'] != null) {
      // BUGFIX (data): tránh `as List<dynamic>` ném TypeError khi `data`
      // không phải List.
      final raw = response['data'];
      return raw is List ? raw : const <dynamic>[];
    }
  } catch (e) {
    debugPrint('Error fetching saas plans: $e');
  }
  return [];
});

class _OwnerSubscriptionScreenState
    extends ConsumerState<OwnerSubscriptionScreen> {
  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(
      dashboardStatsProvider(month: null, year: null),
    );

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text(
          'Quản lý Gói & Thống kê',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        previousPageTitle: 'Quay lại',
      ),
      child: LiquidBackground(
        colors: AppTheme.kBackgroundLight,
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: statsAsync.when(
                  data: (stats) {
                    final planName =
                        stats['currentPlanName'] as String? ??
                        'CHƯA ĐĂNG KÝ GÓI';
                    final plansAsync = ref.watch(saasPlansProvider);

                    return SliverList(
                      delegate: SliverChildListDelegate([
                        _buildCurrentPlanCard(planName),
                        const SizedBox(height: 32),
                        const Text(
                          'CÁC GÓI NÂNG CẤP',
                          style: TextStyle(
                            color: Color(0xFF4B5563),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        plansAsync.when(
                          data: (plans) => AnimationLimiter(
                            child: Column(
                              children: AnimationConfiguration.toStaggeredList(
                                duration: const Duration(milliseconds: 600),
                                childAnimationBuilder: (widget) =>
                                    SlideAnimation(
                                      verticalOffset: 50.0,
                                      child: FadeInAnimation(child: widget),
                                    ),
                                children: plans
                                    .map(
                                      (plan) => _buildPlanCard(
                                        plan,
                                        currentPlan: planName,
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                          loading: () => const Center(
                            child: CupertinoActivityIndicator(radius: 12),
                          ),
                          error: (e, _) => AppErrorWidget(error: e),
                        ),
                      ]),
                    );
                  },
                  loading: () => const SliverFillRemaining(
                    child: Center(
                      child: CupertinoActivityIndicator(radius: 16),
                    ),
                  ),
                  error: (e, _) =>
                      SliverFillRemaining(child: AppErrorWidget(error: e)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPlanCard(String planName) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      border: Border.all(
        color: AppTheme.kAccentColor.withValues(alpha: 0.3),
        width: 1.5,
      ),
      color: CupertinoColors.white.withValues(alpha: 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8C00), Color(0xFFE65100)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF8C00).withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.sparkles,
                  color: CupertinoColors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gói hiện tại của bạn',
                      style: TextStyle(color: Color(0xFF4B5563), fontSize: 14),
                    ),
                    Text(
                      planName.toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.kAccentColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Bạn đang sử dụng phiên bản hệ thống quản lý phòng trọ hiện đại nhất. Để mở rộng quy mô, hãy tham khảo các gói nâng cấp bên dưới.',
            style: TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(dynamic plan, {required String currentPlan}) {
    // BUGFIX (data): trước đây ép `plan['planType']` không an toàn và
    // `(plan['price'] as num)` — nếu price là String/null thì ném TypeError
    // và cả danh sách gói không render. Coerce an toàn.
    final String planType = plan['planType']?.toString() ?? '';
    final bool isPopular = planType == 'PRO';
    final bool isVIP = planType == 'ENTERPRISE';
    final isCurrent =
        currentPlan.toUpperCase().contains(
          plan['name'].toString().toUpperCase(),
        ) ||
        currentPlan.toUpperCase() == planType;
    final num planPrice = plan['price'] is num
        ? plan['price'] as num
        : num.tryParse(plan['price']?.toString() ?? '') ?? 0;
    final formattedPrice = planPrice == 0
        ? 'Miễn phí'
        : '${planPrice.toInt()} đ/tháng';
    final description = plan['description'] as String? ?? '';
    final maxRoomsText = (plan['maxRooms'] == null || plan['maxRooms'] > 900)
        ? 'Không giới hạn phòng'
        : 'Quản lý ${plan['maxRooms']} phòng';

    final List<String> features = [
      maxRoomsText,
      description,
      if (isPopular || isVIP) 'Hỗ trợ ưu tiên',
      if (isVIP) 'Phân tích & Heatmap',
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        borderRadius: 28,
        color: isVIP
            ? AppTheme.kTextPrimary.withValues(alpha: 0.85)
            : CupertinoColors.white.withValues(alpha: 0.7),
        border: isVIP
            ? Border.all(
                color: const Color(0xFFEAB308).withValues(alpha: 0.5),
                width: 1.5,
              )
            : (isPopular
                  ? Border.all(
                      color: AppTheme.kAccentColor.withValues(alpha: 0.5),
                      width: 1.5,
                    )
                  : Border.all(color: CupertinoColors.white, width: 2)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPopular || isVIP)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: isVIP
                      ? const LinearGradient(
                          colors: [Color(0xFFEAB308), Color(0xFFD97706)],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFFFF8C00), Color(0xFFE65100)],
                        ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isVIP
                                  ? const Color(0xFFEAB308)
                                  : const Color(0xFFFF8C00))
                              .withValues(alpha: 0.5),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isVIP)
                      const Icon(
                        CupertinoIcons.star_fill,
                        color: CupertinoColors.white,
                        size: 14,
                      ),
                    if (isVIP) const SizedBox(width: 6),
                    Text(
                      isVIP ? 'LỰA CHỌN DOANH NGHIỆP' : 'ĐƯỢC YÊU THÍCH',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    plan['name'],
                    style: TextStyle(
                      color: isVIP
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              formattedPrice,
              style: TextStyle(
                color: isVIP ? AppTheme.kBrandLight : AppTheme.kAccentColor,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 1,
              color: (isVIP ? AppTheme.kTextSecondary : AppTheme.kBorderColor)
                  .withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),
            ...List.generate(features.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.check_mark_circled_solid,
                      color: isVIP
                          ? const Color(0xFF34D399)
                          : CupertinoColors.systemGreen,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        features[index],
                        style: TextStyle(
                          color: isVIP
                              ? const Color(0xFFE2E8F0)
                              : const Color(0xFF4B5563),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: isCurrent
                    ? null
                    : () {
                        unawaited(HapticFeedback.lightImpact());
                        unawaited(_mockUpgrade(plan, isVIP));
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: isCurrent ? const Color(0xFFD1D5DB) : null,
                    gradient: isCurrent
                        ? null
                        : (isVIP
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFEAB308),
                                    Color(0xFFD97706),
                                  ],
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFFFF8C00),
                                    Color(0xFFE65100),
                                  ],
                                )),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isCurrent
                        ? null
                        : [
                            BoxShadow(
                              color:
                                  (isVIP
                                          ? const Color(0xFFEAB308)
                                          : const Color(0xFFFF8C00))
                                      .withValues(alpha: 0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                  ),
                  child: Center(
                    child: Text(
                      isCurrent ? 'Đang sử dụng' : 'Nâng cấp ngay',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isCurrent
                            ? const Color(0xFF6B7280)
                            : CupertinoColors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mockUpgrade(dynamic plan, bool isVIP) async {
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => Container(
          height: 400,
          decoration: BoxDecoration(
            color: isVIP ? AppTheme.kTextPrimary : CupertinoColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Thanh toán Gói ${plan['name']}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isVIP
                            ? CupertinoColors.white
                            : CupertinoColors.black,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: AppTheme.kTextSecondary,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isVIP
                        ? const Color(0xFF1E293B)
                        : AppTheme.kSurfaceBlue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.cube_box_fill,
                        color: isVIP ? AppTheme.kBrand : AppTheme.kAccentColor,
                        size: 40,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nâng cấp lên',
                              style: TextStyle(
                                color: AppTheme.kTextSecondary,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              plan['name'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isVIP
                                    ? CupertinoColors.white
                                    : CupertinoColors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: isVIP ? AppTheme.kBrand : AppTheme.kAccentColor,
                    borderRadius: BorderRadius.circular(16),
                    onPressed: () async {
                      try {
                        await ref
                            .read(apiClientProvider)
                            .post(
                              '/v1/owner/saas/buy',
                              data: {'planType': plan['planType']},
                            );
                      } catch (_) {}
                      refreshOwnerDashboardFromWidget(ref);

                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (!mounted) return;
                      ToastUtils.show(
                        context,
                        'Thanh toán Gói ${plan['name']} thành công!',
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.check_mark_circled_solid,
                          color: CupertinoColors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Xác nhận thanh toán',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.white,
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
      ),
    );
  }
}
