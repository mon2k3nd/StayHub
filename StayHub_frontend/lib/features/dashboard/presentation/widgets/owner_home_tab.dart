import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/liquid_glass_colors.dart';
import 'package:stayhub_frontend/core/components/stayhub_logo_icon.dart';

import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/components/app_error_widget.dart';
import '../../../../core/components/shimmer_loading.dart';
import '../../../../core/components/shimmer_block.dart';
import '../../../../core/components/empty_state_illustration.dart';
import '../../../../core/components/bounce_click.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../../branch/application/branch_notifier.dart';
import '../../../branch/data/models/branch_model.dart';
import '../../../notification/data/unread_notifications_count_provider.dart';
import '../../../chat/presentation/chat_list_screen.dart';
import '../../../ticket/application/ticket_provider.dart';
import '../../../ticket/data/models/ticket_model.dart';
import '../../../checkout/application/checkout_provider.dart';
import '../../../checkout/data/models/checkout_request_model.dart';
import '../../../contract/application/contract_notifier.dart';
import '../../application/dashboard_notifier.dart';
import '../../application/rental_request_notifier.dart';
import 'revenue_card.dart';
import '../../../../core/components/smart_greeting_widget.dart';
import '../owner_dashboard.dart';
import '../../application/suggested_features_provider.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:async' show unawaited;

// ─── Owner Home Tab ────────────────────────────────────────────────────────────
class OwnerHomeTab extends ConsumerWidget {
  const OwnerHomeTab({super.key});

  Widget _buildChecklistItem({
    required String title,
    required bool isCompleted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isCompleted
                ? CupertinoIcons.checkmark_alt_circle_fill
                : CupertinoIcons.circle,
            color: isCompleted ? AppTheme.kSuccess : const Color(0xFF9CA3AF),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: isCompleted
                  ? const Color(0xFF9CA3AF)
                  : const Color(0xFF111827),
              decoration: isCompleted ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showSwitchToGuestSheet(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text(
          'Chuyển sang giao diện Khách thuê',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        message: const Text(
          'Bạn sẽ chuyển về màn hình khám phá phòng thuê để trải nghiệm góc nhìn của người đi thuê.',
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/guest');
            },
            child: const Text(
              'Vào giao diện Khách thuê',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Hủy'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);
    final user = authAsync.value;

    // Guard: while auth is loading (e.g. after web page refresh), show skeleton
    if (authAsync.isLoading) {
      return const _AnimatedSkyBackground(
        child: Center(child: CupertinoActivityIndicator(radius: 16)),
      );
    }

    // Guard: if auth finished loading but user is null, redirect to login
    if (!authAsync.isLoading && user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/login');
      });
      return const SizedBox.shrink();
    }

    final statsAsync = ref.watch(dashboardStatsProvider());
    final branchAsync = ref.watch(branchProvider);
    final pendingList = ref.watch(pendingRequestsProvider);
    final ticketsAsync = ref.watch(ticketProvider);
    final checkoutsAsync = ref.watch(ownerCheckoutRequestsProvider);
    final draftBranchesAsync = ref.watch(draftBranchesProvider);
    final fmt = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );

    final isPlanFree =
        user == null || user.planType == 'FREE' || user.planType.isEmpty;

    final pendingTickets =
        ticketsAsync.value
            ?.where((t) => t.status == 'OPEN' || t.status == 'PENDING')
            .take(3)
            .toList() ??
        [];
    final pendingCheckouts =
        checkoutsAsync.value
            ?.where(
              (c) => c.status == 'PENDING' || c.status == 'PAYMENT_PENDING',
            )
            .take(3)
            .toList() ??
        [];
    final hasPendingTasks =
        pendingTickets.isNotEmpty || pendingCheckouts.isNotEmpty;
    final isLoadingTasks = ticketsAsync.isLoading || checkoutsAsync.isLoading;

    final topPadding = MediaQuery.of(context).padding.top;
    final headerHeight = topPadding + 78.0;

    return _AnimatedSkyBackground(
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Stack(
          children: [
            // 1. Vùng cuộn Dashboard bên dưới
            CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(height: headerHeight),
                ),
                CupertinoSliverRefreshControl(
              refreshTriggerPullDistance: 120,
              refreshIndicatorExtent: 70,
              builder:
                  (
                    context,
                    refreshState,
                    pulledExtent,
                    refreshTriggerPullDistance,
                    refreshIndicatorExtent,
                  ) {
                    return CustomPaint(
                      painter: _LiquidDropPainter(
                        color: AppTheme.kBrand,
                        pulledExtent: pulledExtent,
                        refreshState: refreshState,
                      ),
                      child: SizedBox(
                        height: pulledExtent,
                        width: double.infinity,
                        child:
                            (refreshState == RefreshIndicatorMode.refresh ||
                                refreshState == RefreshIndicatorMode.done)
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    );
                  },
              onRefresh: () async {
                ref.invalidate(dashboardStatsProvider());
                ref.invalidate(branchProvider);
                ref.invalidate(ownerCheckoutRequestsProvider);
                ref.invalidate(ticketProvider);
                await Future.delayed(const Duration(seconds: 1));
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 0,
                ), // Card itself has margin
                child: statsAsync.when(
                  data: (stats) {
                    final revenue =
                        (stats['totalRevenueThisMonth'] as num?)?.toDouble() ??
                        0.0;
                    final expenses =
                        (stats['totalExpensesThisMonth'] as num?)?.toDouble() ??
                        0.0;
                    final netProfit =
                        (stats['netProfitThisMonth'] as num?)?.toDouble() ??
                        0.0;
                    final totalBills =
                        (stats['totalBillsThisMonth'] as num?)?.toInt() ?? 0;
                    final paidBills =
                        (stats['paidBillsThisMonth'] as num?)?.toInt() ?? 0;
                    final unpaidAmount =
                        (stats['unpaidBillsAmount'] as num?)?.toDouble() ?? 0.0;
                    final growthRate =
                        (stats['profitGrowthRate'] as num?)?.toDouble() ?? 0.0;

                    return GestureDetector(
                      onTap: () {
                        unawaited(HapticFeedback.lightImpact());
                        unawaited(context.push('/control-center'));
                      },
                      child: RevenueCard(
                        isPlanFree: isPlanFree,
                        netProfit: fmt.format(netProfit),
                        totalRevenue: fmt.format(revenue),
                        totalExpense: fmt.format(expenses),
                        growthRate: growthRate,
                        paidBills: paidBills,
                        totalBills: totalBills,
                        unpaidAmount: unpaidAmount,
                      ),
                    );
                  },
                  loading: () => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: () {
                        unawaited(HapticFeedback.lightImpact());
                        unawaited(context.push('/control-center'));
                      },
                      child: const RevenueCardSkeleton(),
                    ),
                  ),
                  error: (e, _) => const SizedBox.shrink(),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ─── Onboarding Checklist (For New Users) ──────────────────────
            SliverToBoxAdapter(
              child: branchAsync.when(
                data: (branches) {
                  if (branches.isNotEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                CupertinoIcons.sparkles,
                                color: AppTheme.kBrand,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Các bước tiếp theo',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.kBrandDeep,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Chào mừng bạn đến với StayHub! Hãy hoàn tất các bước sau để bắt đầu kinh doanh.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildChecklistItem(
                            title: 'Tạo dãy trọ đầu tiên',
                            isCompleted: false,
                          ),
                          _buildChecklistItem(
                            title: 'Thêm phòng và thiết lập giá',
                            isCompleted: false,
                          ),
                          _buildChecklistItem(
                            title: 'Đăng tin lên Chợ trọ',
                            isCompleted: false,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              color: AppTheme.kBrand,
                              borderRadius: BorderRadius.circular(100),
                              onPressed: () =>
                                  context.push('/owner/create-branch'),
                              child: const Text(
                                'Tạo Dãy Trọ Ngay',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ─── Alerts & Action Required (Carousel) ──────────────────────
            SliverToBoxAdapter(
              child: _ActionRequiredCarousel(
                pendingList: pendingList,
                draftBranchesAsync: draftBranchesAsync,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ─── Quick Actions (2x2 Grid) ─────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TÍNH NĂNG GỢI Ý',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.kTextSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            unawaited(HapticFeedback.lightImpact());
                            unawaited(
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (ctx) => const LiquidBottomSheet(),
                              ),
                            );
                          },
                          child: const Text(
                            'Xem thêm',
                            style: TextStyle(
                              color: AppTheme.kBrand,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Consumer(
                      builder: (context, ref, _) {
                        final features = ref.watch(suggestedFeaturesProvider);
                        final user = ref.watch(authProvider).value;
                        final isPendingKYC =
                            user != null && user.kycStatus == 'PENDING';
                        final allCategories = getOwnerActionCategories(
                          context,
                          user,
                          isPendingKYC,
                        );
                        // BUGFIX (data): tránh `as List<ActionItem>` ném
                        // TypeError khi 'items' null/sai kiểu — coerce an toàn.
                        final allItems = allCategories
                            .expand(
                              (c) => (c['items'] is List)
                                  ? (c['items'] as List).whereType<ActionItem>()
                                  : const <ActionItem>[],
                            )
                            .toList();

                        return GridView.count(
                          crossAxisCount: 4,
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 4,
                          childAspectRatio: 0.92,
                          children: features.take(8).map((featureId) {
                            final item = allItems
                                .where((i) => i.label == featureId)
                                .firstOrNull;
                            if (item == null) return const SizedBox.shrink();

                            return FadeIn(
                              key: ValueKey(item.label),
                              duration: const Duration(milliseconds: 300),
                              child: _FeatureIcon(
                                icon: item.icon,
                                label: item.label,
                                iconColor: item.iconColor,
                                bgColor: item.bgColor,
                                imagePath: item.imagePath,
                                onTap: () {
                                  unawaited(
                                    ref
                                        .read(
                                          suggestedFeaturesProvider.notifier,
                                        )
                                        .prioritizeFeature(item.label),
                                  );
                                  item.onTap();
                                },
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'TỔNG QUAN',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.kTextSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    statsAsync.when(
                      data: (stats) {
                        final totalRooms =
                            (stats['totalRooms'] as num?)?.toInt() ?? 0;
                        final occupiedRooms =
                            (stats['occupiedRooms'] as num?)?.toInt() ?? 0;
                        final vacantRooms = totalRooms - occupiedRooms;
                        final pendingBills =
                            (stats['pendingBills'] as num?)?.toInt() ?? 0;
                        final unpublishedRooms =
                            (stats['unpublishedRooms'] as num?)?.toInt() ?? 0;
                        final openTickets =
                            ticketsAsync.value
                                ?.where(
                                  (t) =>
                                      t.status == 'OPEN' ||
                                      t.status == 'PENDING',
                                )
                                .length ??
                            0;

                        return GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 12,
                          childAspectRatio: 2.3,
                          children: [
                            _GlassInfoCard(
                              icon: CupertinoIcons.bed_double_fill,
                              imagePath: 'assets/images/features/feat_room.png',
                              title: 'Phòng trống',
                              value: '$vacantRooms',
                              subtitle: 'trên tổng $totalRooms',
                              color: AppTheme.kSuccess,
                              onTap: () => context.push('/branch'),
                            ),
                            _GlassInfoCard(
                              icon: CupertinoIcons.doc_text_fill,
                              imagePath:
                                  'assets/images/features/feat_payments.png',
                              title: 'Chưa thu tiền',
                              value: '$pendingBills',
                              subtitle: 'hóa đơn',
                              color: AppTheme.kError,
                              onTap: () => context.push('/bill'),
                            ),
                            _GlassInfoCard(
                              icon: CupertinoIcons.speaker_slash_fill,
                              imagePath:
                                  'assets/images/features/marketing_campaign.png',
                              title: 'Chưa đăng',
                              value: '$unpublishedRooms',
                              subtitle: 'phòng',
                              color: AppTheme.kWarning,
                              onTap: () =>
                                  context.push('/owner/post-management'),
                            ),
                            _GlassInfoCard(
                              icon: CupertinoIcons.wrench_fill,
                              imagePath:
                                  'assets/images/features/video_maintenance.png',
                              title: 'Sửa chữa',
                              value: '$openTickets',
                              subtitle: 'yêu cầu mở',
                              color: const Color(0xFF8B5CF6),
                              onTap: () => context.push('/ticket'),
                            ),
                          ],
                        );
                      },
                      loading: () => GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 2.2,
                        children: List.generate(
                          4,
                          (_) => const ShimmerLoading(
                            width: double.infinity,
                            height: double.infinity,
                            borderRadius: 24,
                          ),
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            if (isLoadingTasks)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: ShimmerListLoading(itemCount: 2),
                ),
              )
            else if (hasPendingTasks) ...[
              // ─── Công Việc Cần Xử Lý ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CÔNG VIỆC CHƯA HOÀN THÀNH',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.white.withValues(alpha: 0.5),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              if (pendingTickets.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 300 + (i * 60)),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) => Transform.translate(
                        offset: Offset(0, 15 * (1 - value)),
                        child: Opacity(opacity: value, child: child),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        child: _TicketCard(
                          ticket: pendingTickets[i],
                          onTap: () => context.push('/ticket'),
                        ),
                      ),
                    ),
                    childCount: pendingTickets.length,
                  ),
                ),

              if (pendingCheckouts.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 350 + (i * 60)),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) => Transform.translate(
                        offset: Offset(0, 15 * (1 - value)),
                        child: Opacity(opacity: value, child: child),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        child: _CheckoutCard(
                          request: pendingCheckouts[i],
                          onTap: () async {
                            try {
                              final contracts = await ref.read(
                                contractProvider.future,
                              );
                              final contract = contracts
                                  .where(
                                    (c) =>
                                        c.id == pendingCheckouts[i].contractId,
                                  )
                                  .firstOrNull;
                              if (!context.mounted) return;
                              if (contract != null) {
                                unawaited(
                                  context.push(
                                    '/owner/checkout-detail/${pendingCheckouts[i].id}',
                                    extra: {
                                      'request': pendingCheckouts[i],
                                      'contract': contract,
                                    },
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Không tìm thấy hợp đồng'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lỗi: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ),
                    childCount: pendingCheckouts.length,
                  ),
                ),
            ],

            // ─── Danh sách Dãy Trọ ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'DÃY TRỌ CỦA BẠN',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.kTextMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/branch'),
                      child: const Text(
                        'Quản lý',
                        style: TextStyle(
                          color: AppTheme.kAccentColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            branchAsync.when(
              data: (branches) {
                if (branches.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: EmptyStateIllustration(
                        icon: CupertinoIcons.building_2_fill,
                        imagePath: 'assets/images/features/multi_property.png',
                        title: 'Chưa có dãy trọ nào',
                        subtitle: 'Bấm dấu + để thêm',
                      ),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 350 + (i * 60)),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(opacity: value, child: child),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        child: _BranchCard(
                          branch: branches[i],
                          onTap: () => context.push(
                            '/room',
                            extra: {
                              'ownerId': branches[i].ownerId,
                              'branchId': branches[i].id,
                              'branchName': branches[i].branchName,
                            },
                          ),
                        ),
                      ),
                    ),
                    childCount: branches.length,
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: ShimmerListLoading(itemCount: 2),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: AppErrorWidget(
                    error: e,
                    compact: true,
                    onRetry: () => ref.invalidate(branchProvider),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),

        // 2. Sticky Glass Header ghim cố định 100% trên đỉnh
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                color: Colors.white.withValues(alpha: 0.85),
                padding: EdgeInsets.fromLTRB(24, topPadding + 10, 24, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    BounceClick(
                      onPressed: () {
                        unawaited(HapticFeedback.lightImpact());
                        unawaited(context.push('/settings'));
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.kBrand,
                        ),
                        child: (user?.avatar != null && user!.avatar!.isNotEmpty)
                            ? ClipOval(
                                child: Image.network(
                                  user.avatar!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Center(
                                    child: Text(
                                      user.fullName.trim().isNotEmpty
                                          ? user.fullName.trim()[0].toUpperCase()
                                          : 'C',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  user != null && user.fullName.trim().isNotEmpty
                                      ? user.fullName.trim()[0].toUpperCase()
                                      : 'C',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(child: SmartGreetingWidget()),
                    _IconBtn(
                      icon: CupertinoIcons.chat_bubble_2_fill,
                      imagePath: 'assets/images/features/e2e_chat.png',
                      badgeCount: 0,
                      onTap: () {
                        unawaited(HapticFeedback.lightImpact());
                        unawaited(
                          Navigator.push(
                            context,
                            CupertinoPageRoute(builder: (c) => const ChatListScreen()),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    _IconBtn(
                      icon: CupertinoIcons.bell_fill,
                      imagePath: 'assets/images/features/push_alerts.png',
                      badgeCount: ref.watch(unreadNotificationsCountProvider).value ?? 0,
                      onTap: () {
                        unawaited(HapticFeedback.lightImpact());
                        unawaited(context.push('/notifications'));
                      },
                    ),
                    const SizedBox(width: 12),
                    _IconBtn(
                      icon: CupertinoIcons.arrow_2_squarepath,
                      badgeCount: 0,
                      onTap: () {
                        unawaited(HapticFeedback.lightImpact());
                        _showSwitchToGuestSheet(context);
                      },
                    ),
                  ],
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
}

// ─── Revenue Card (Purple) ───────────────────────────────────────────────────

// ─── Ticket Card ─────────────────────────────────────────────────────────────
class _TicketCard extends StatelessWidget {
  final TicketModel ticket;
  final VoidCallback onTap;

  const _TicketCard({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final categoryIcon = _iconForCategory(ticket.category);

    return GestureDetector(
      onTap: () {
        unawaited(HapticFeedback.lightImpact());
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: AppTheme.kWarning.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                categoryIcon,
                color: const Color(0xFFD97706),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.category,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${ticket.roomName ?? 'Phòng'} • ${ticket.branchName ?? ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.kTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF298FFF), AppTheme.kBrandDeep],
                ),
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF298FFF).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Text(
                'Xử lý',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForCategory(String cat) {
    switch (cat.toLowerCase()) {
      case 'điện':
      case 'electrical':
        return CupertinoIcons.bolt_fill;
      case 'nước':
      case 'plumbing':
        return CupertinoIcons.drop_fill;
      default:
        return CupertinoIcons.wrench_fill;
    }
  }
}

// ─── Branch Card ─────────────────────────────────────────────────────────────
class _BranchCard extends StatelessWidget {
  final BranchModel branch;
  final VoidCallback onTap;

  const _BranchCard({required this.branch, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        unawaited(HapticFeedback.lightImpact());
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF298FFF).withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.kAccentColor, AppTheme.kBrandDeep],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.kAccentColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.building_2_fill,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    branch.branchName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    branch.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.kTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.kAccentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${branch.totalRooms} phòng',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.kAccentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: AppTheme.kTextSecondaryDark,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty Card ──────────────────────────────────────────────────────────────

// ─── Icon Button with badge ───────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String? imagePath;
  final int badgeCount;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    this.imagePath,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (imagePath != null)
            Image.asset(
              imagePath!,
              width: 28,
              height: 28,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              isAntiAlias: true,
              errorBuilder: (_, __, ___) =>
                  Icon(icon, size: 26, color: AppTheme.kBorderColorDark),
            )
          else
            Icon(icon, size: 26, color: AppTheme.kBorderColorDark),
          if (badgeCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _TransactionRow extends StatelessWidget {
  final String title;
  final String date;
  final String amount;
  final bool isPositive;

  const _TransactionRow({
    required this.title,
    required this.date,
    required this.amount,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white, width: 1.5),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isPositive
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.red.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPositive
                  ? CupertinoIcons.arrow_down_left
                  : CupertinoIcons.arrow_up_right,
              color: isPositive ? Colors.green[700] : Colors.red[700],
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isPositive ? Colors.green[700] : Colors.red[700],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Checkout Card ───────────────────────────────────────────────────────────
class _CheckoutCard extends StatelessWidget {
  final CheckoutRequestModel request;
  final VoidCallback onTap;

  const _CheckoutCard({required this.request, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color badgeColor = AppTheme.kAccentColor;
    String badgeText = 'Chờ thẩm định';
    if (request.status == 'PAYMENT_PENDING') {
      badgeColor = CupertinoColors.systemOrange;
      badgeText = 'Chờ TT';
    } else if (request.status == 'COMPLETED') {
      badgeColor = CupertinoColors.systemGreen;
      badgeText = 'Hoàn tất';
    } else if (request.status == 'CANCELLED' || request.status == 'REJECTED') {
      badgeColor = CupertinoColors.systemRed;
      badgeText = 'Đã hủy/Từ chối';
    }

    return GestureDetector(
      onTap: () {
        unawaited(HapticFeedback.lightImpact());
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: badgeColor.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: CupertinoColors.systemRed.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                CupertinoIcons.arrow_right_square_fill,
                color: CupertinoColors.systemRed,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Yêu cầu trả phòng',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.kTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: badgeColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Phòng: ${request.roomId} • Mã HĐ: ${request.contractId}',
                    style: const TextStyle(
                      color: AppTheme.kTextMuted,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Action Required Carousel ──────────────────────────────────────────────────
class _ActionRequiredCarousel extends ConsumerWidget {
  final List pendingList;
  final AsyncValue<List<BranchModel>> draftBranchesAsync;

  const _ActionRequiredCarousel({
    required this.pendingList,
    required this.draftBranchesAsync,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractsAsync = ref.watch(contractProvider);

    List<Widget> alertCards = [];

    // Pending requests
    if (pendingList.isNotEmpty) {
      alertCards.add(
        _AlertCard(
          icon: CupertinoIcons.person_add_solid,
          imagePath: 'assets/images/features/tenant_bg_check.png',
          color: const Color(0xFFD97706),
          title: '${pendingList.length} yêu cầu thuê',
          subtitle: 'Chờ phê duyệt',
          onTap: () => context.push('/rental-requests'),
        ),
      );
    }

    // Expiring contracts
    contractsAsync.whenData((contracts) {
      final now = DateTime.now();
      final expiring = contracts.where((c) {
        if (c.status != 'ACTIVE') return false;
        final diff = c.endDate.difference(now).inDays;
        return diff >= 0 && diff <= 30;
      }).toList();

      if (expiring.isNotEmpty) {
        alertCards.add(
          _AlertCard(
            icon: CupertinoIcons.exclamationmark_triangle_fill,
            imagePath: 'assets/images/features/smart_contract.png',
            color: const Color(0xFFEAB308),
            title: '${expiring.length} hợp đồng',
            subtitle: 'Sắp hết hạn',
            onTap: () => context.push('/contract'),
          ),
        );
      }
    });

    // Draft Branches — chi nhánh đang cấu hình dở, mở thẳng wizard 4 bước
    draftBranchesAsync.whenData((drafts) {
      for (var draft in drafts) {
        alertCards.add(
          _AlertCard(
            icon: CupertinoIcons.building_2_fill,
            imagePath: 'assets/images/features/multi_property.png',
            color: const Color(0xFFEF4444),
            title: draft.branchName,
            subtitle: 'Đang cấu hình',
            onTap: () =>
                context.push('/branch/wizard', extra: {'branch': draft}),
          ),
        );
      }
    });

    if (alertCards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'CẦN XỬ LÝ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.kTextSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: alertCards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) => alertCards[index],
          ),
        ),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final IconData icon;
  final String? imagePath;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AlertCard({
    required this.icon,
    this.imagePath,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BounceClick(
      onPressed: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                if (imagePath != null)
                  Image.asset(
                    imagePath!,
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    isAntiAlias: true,
                    errorBuilder: (_, __, ___) =>
                        Icon(icon, color: color, size: 20),
                  )
                else
                  Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: color.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Glass Info Card ─────────────────────────────────────────────────────────
class _GlassInfoCard extends StatelessWidget {
  final IconData icon;
  final String? imagePath;
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _GlassInfoCard({
    required this.icon,
    this.imagePath,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BounceClick(
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: imagePath != null
                  ? Image.asset(
                      imagePath!,
                      width: 26,
                      height: 26,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      isAntiAlias: true,
                      errorBuilder: (_, __, ___) =>
                          Icon(icon, color: color, size: 20),
                    )
                  : Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: color,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Occupancy Bar Chart ─────────────────────────────────────────────────────
// ignore: unused_element
class _OccupancyBarChart extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _OccupancyBarChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = (stats['totalRooms'] as num?)?.toInt() ?? 0;
    final occupied = (stats['occupiedRooms'] as num?)?.toInt() ?? 0;
    final vacant = total - occupied;
    final maintenance = (stats['maintenanceRooms'] as num?)?.toInt() ?? 0;
    final pendingConfig = (stats['pendingConfigRooms'] as num?)?.toInt() ?? 0;

    if (total == 0) return const SizedBox.shrink();

    final occRate = occupied / total;
    final vacRate = vacant / total;
    final mainRate = maintenance / total;
    final pendRate = pendingConfig / total;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TỶ LỆ LẤP ĐẦY',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.kTextSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${(occRate * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.kTextPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 16,
              child: Row(
                children: [
                  if (occRate > 0)
                    Expanded(
                      flex: (occRate * 100).toInt(),
                      child: Container(color: AppTheme.kSuccess),
                    ),
                  if (vacRate > 0)
                    Expanded(
                      flex: (vacRate * 100).toInt(),
                      child: Container(color: const Color(0xFFE2E8F0)),
                    ),
                  if (mainRate > 0)
                    Expanded(
                      flex: (mainRate * 100).toInt(),
                      child: Container(color: AppTheme.kError),
                    ),
                  if (pendRate > 0)
                    Expanded(
                      flex: (pendRate * 100).toInt(),
                      child: Container(color: AppTheme.kWarning),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _BarLegend(color: AppTheme.kSuccess, label: 'Đã thuê'),
              _BarLegend(color: Color(0xFFE2E8F0), label: 'Trống'),
              _BarLegend(color: AppTheme.kError, label: 'Bảo trì'),
              _BarLegend(color: AppTheme.kWarning, label: 'Chờ setup'),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _BarLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.kTextSecondary),
        ),
      ],
    );
  }
}

// ─── Animated Sky Background ─────────────────────────────────────────────────
class _FeatureIcon extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;
  final String? imagePath;

  const _FeatureIcon({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return BounceClick(
      onPressed: onTap,
      child: Align(
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.8),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: bgColor.withValues(alpha: 0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: imagePath != null
                    ? Padding(
                        padding: const EdgeInsets.all(6),
                        child: Image.asset(
                          imagePath!,
                          width: 48,
                          height: 48,
                          filterQuality: FilterQuality.high,
                        ),
                      )
                    : icon == null
                    ? StayHubLogoIcon(size: 28, color: iconColor)
                    : Icon(icon, color: iconColor, size: 28),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedSkyBackground extends StatefulWidget {
  final Widget child;
  const _AnimatedSkyBackground({required this.child});

  @override
  State<_AnimatedSkyBackground> createState() => _AnimatedSkyBackgroundState();
}

class _AnimatedSkyBackgroundState extends State<_AnimatedSkyBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
    unawaited(_controller.repeat(reverse: true));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Sky Blue Color
        Container(color: const Color(0xFFF2F8FF)),

        // Animated Blobs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                // Blob 1: Top Left
                Align(
                  alignment: Alignment(
                    -1.2 + (_controller.value * 0.6),
                    -1.2 + (_controller.value * 0.4),
                  ),
                  child: Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF9CCBFF).withValues(alpha: 0.6),
                    ),
                  ),
                ),
                // Blob 2: Top Right
                Align(
                  alignment: Alignment(
                    1.2 - (_controller.value * 0.5),
                    -0.5 + (_controller.value * 0.6),
                  ),
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF5FAEFF).withValues(alpha: 0.4),
                    ),
                  ),
                ),
                // Blob 3: Bottom Center/Left
                Align(
                  alignment: Alignment(
                    -0.5 + (_controller.value * 0.4),
                    1.2 - (_controller.value * 0.5),
                  ),
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFC7E2FF).withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            );
          },
        ),

        // Heavy Blur to create the smooth, glassy moving background effect
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: const SizedBox(),
          ),
        ),

        // The actual page content
        widget.child,
      ],
    );
  }
}

class _LiquidDropPainter extends CustomPainter {
  final Color color;
  final double pulledExtent;
  final RefreshIndicatorMode refreshState;

  _LiquidDropPainter({
    required this.color,
    required this.pulledExtent,
    required this.refreshState,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.height <= 0) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    double centerX = size.width / 2;
    double maxDropY = size.height;

    if (refreshState == RefreshIndicatorMode.refresh ||
        refreshState == RefreshIndicatorMode.done ||
        refreshState == RefreshIndicatorMode.armed) {
      double radius = 22.0;
      canvas.drawCircle(Offset(centerX, size.height / 2), radius, paint);
      return;
    }

    Path path = Path();
    path.moveTo(0, 0);

    // Full width liquid membrane (Sexy Bell Curve shape)
    path.cubicTo(
      size.width * 0.2,
      0, // Control point 1: Starts horizontal from left edge
      centerX - 25,
      maxDropY, // Control point 2: Dips down to the drop base
      centerX,
      maxDropY, // End point: Bottom center of drop
    );

    path.cubicTo(
      centerX + 25,
      maxDropY, // Control point 1: Rises up from the drop base
      size.width * 0.8,
      0, // Control point 2: Ends horizontal near right edge
      size.width,
      0, // End point: Top right corner
    );

    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidDropPainter oldDelegate) {
    return oldDelegate.pulledExtent != pulledExtent ||
        oldDelegate.refreshState != refreshState;
  }
}
