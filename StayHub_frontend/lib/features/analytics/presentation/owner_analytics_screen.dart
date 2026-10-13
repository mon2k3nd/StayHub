import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import '../application/analytics_provider.dart';
import 'widgets/revenue_line_chart.dart';
import 'widgets/room_performance_list.dart';
import 'dart:async' show unawaited;

class OwnerAnalyticsScreen extends ConsumerStatefulWidget {
  final int ownerId;
  const OwnerAnalyticsScreen({super.key, required this.ownerId});

  @override
  ConsumerState<OwnerAnalyticsScreen> createState() =>
      _OwnerAnalyticsScreenState();
}

class _OwnerAnalyticsScreenState extends ConsumerState<OwnerAnalyticsScreen> {
  late final TextEditingController _monthsCtrl;

  @override
  void initState() {
    super.initState();
    _monthsCtrl = TextEditingController(text: '6');
  }

  @override
  void dispose() {
    _monthsCtrl.dispose();
    super.dispose();
  }

  void _applyMonths() {
    final val = int.tryParse(_monthsCtrl.text);
    if (val != null && val >= 1 && val <= 60) {
      ref.read(analyticsMonthsProvider.notifier).setMonths(val);
    } else {
      _monthsCtrl.text = ref.read(analyticsMonthsProvider).toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final analyticsAsync = ref.watch(ownerAnalyticsProvider(widget.ownerId));
    final months = ref.watch(analyticsMonthsProvider);
    final currencyFmt = NumberFormat.compactCurrency(
      locale: 'vi_VN',
      symbol: 'đ',
    );

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            ref.invalidate(ownerAnalyticsProvider(widget.ownerId));
            await ref.read(ownerAnalyticsProvider(widget.ownerId).future);
          },
        ),
        SliverToBoxAdapter(
          child: analyticsAsync.when(
            data: (data) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Color(0xFF1A6FD4), Color(0xFF298FFF)],
                      ).createShader(bounds),
                      child: const Text(
                        'Thống Kê Sức Khỏe',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Header (Owner Info)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF298FFF,
                            ).withValues(alpha: 0.07),
                            blurRadius: 24,
                            spreadRadius: -2,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.kAccentColor.withValues(
                                alpha: 0.1,
                              ),
                              border: Border.all(
                                color: CupertinoColors.white,
                                width: 2,
                              ),
                              image:
                                  data.avatarUrl != null &&
                                      data.avatarUrl!.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(data.avatarUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child:
                                data.avatarUrl == null ||
                                    data.avatarUrl!.isEmpty
                                ? const Icon(
                                    CupertinoIcons.person_solid,
                                    color: AppTheme.kAccentColor,
                                    size: 28,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data.fullName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: CupertinoColors.black,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      CupertinoIcons.star_fill,
                                      color: CupertinoColors.systemYellow,
                                      size: 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${data.trustScore}',
                                      style: const TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.kAccentColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        data.packageStatus,
                                        style: const TextStyle(
                                          color: AppTheme.kAccentColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              unawaited(
                                context.push('/subscription-management'),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemOrange,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: CupertinoColors.systemOrange
                                        .withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.arrow_up_circle_fill,
                                    size: 16,
                                    color: CupertinoColors.white,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Nâng gói',
                                    style: TextStyle(
                                      color: CupertinoColors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'DÒNG TIỀN ($months THÁNG GẦN NHẤT)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                            letterSpacing: 0.8,
                          ),
                        ),
                        // Free-form months input
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 52,
                              height: 36,
                              decoration: BoxDecoration(
                                color: CupertinoColors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.kAccentColor.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: Center(
                                child: CupertinoTextField(
                                  controller: _monthsCtrl,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: CupertinoColors.black,
                                  ),
                                  decoration: null,
                                  onSubmitted: (_) => _applyMonths(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'tháng',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _applyMonths,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.kAccentColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Áp dụng',
                                  style: TextStyle(
                                    color: CupertinoColors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GlassContainer(
                      padding: const EdgeInsets.all(0),
                      child: RevenueLineChart(points: data.revenueTrend),
                    ),

                    const SizedBox(height: 32),

                    // Summary Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Doanh thu ($months tháng)',
                            currencyFmt.format(data.totalRevenue),
                            CupertinoIcons.money_dollar_circle_fill,
                            CupertinoColors.systemGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            'Lấp đầy',
                            '${data.occupancyRate.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}%',
                            CupertinoIcons.chart_pie_fill,
                            CupertinoColors.systemBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            'Tổng phòng',
                            '${data.totalRooms}',
                            CupertinoIcons.building_2_fill,
                            AppTheme.kAccentColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            'Công nợ ($months tháng)',
                            currencyFmt.format(data.unpaidDebt),
                            CupertinoIcons.exclamationmark_circle_fill,
                            CupertinoColors.systemRed,
                          ),
                        ),
                      ],
                    ),

                    if (data.roomPerformanceRank.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      const Text(
                        'CƠ CẤU DOANH THU',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 16),
                      RoomPerformanceList(rooms: data.roomPerformanceRank),
                    ],

                    const SizedBox(height: 100), // padding for bottom nav
                  ],
                ),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 150),
                child: CupertinoActivityIndicator(
                  radius: 16,
                  color: AppTheme.kAccentColor,
                ),
              ),
            ),
            error: (err, stack) => Padding(
              padding: const EdgeInsets.only(top: 100, left: 24, right: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemRed.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.exclamationmark_triangle_fill,
                      size: 48,
                      color: CupertinoColors.systemRed,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Không thể tải thống kê',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Hệ thống đang gặp sự cố khi lấy dữ liệu thống kê của bạn. Vui lòng thử lại sau.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  CupertinoButton(
                    onPressed: () {
                      ref.invalidate(ownerAnalyticsProvider(widget.ownerId));
                    },
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    color: AppTheme.kAccentColor,
                    borderRadius: BorderRadius.circular(24),
                    child: const Text(
                      'Tải lại dữ liệu',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9CA3AF).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: CupertinoColors.systemGrey6, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: CupertinoColors.black,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
