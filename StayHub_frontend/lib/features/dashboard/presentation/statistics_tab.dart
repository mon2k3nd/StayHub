import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Material, DefaultMaterialLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../application/ai_advice_provider.dart';
import '../../branch/application/branch_notifier.dart';
import '../../room/application/room_notifier.dart';
import 'widgets/statistics_floor_map.dart';
import '../../../core/components/app_error_widget.dart';

class StatisticsTab extends ConsumerStatefulWidget {
  const StatisticsTab({super.key});

  @override
  ConsumerState<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends ConsumerState<StatisticsTab> {
  @override
  Widget build(BuildContext context) {
    final branchesAsync = ref.watch(branchProvider);
    final roomsAsync = ref.watch(allOwnerRoomsProvider);
    final aiAdviceAsync = ref.watch(aiAdviceProvider);

    return Material(
      color: AppTheme.kBackgroundLight,
      child: Localizations.override(
        context: context,
        delegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultCupertinoLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        child: CupertinoPageScaffold(
          backgroundColor: const Color(0x00000000),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  ref.invalidate(branchProvider);
                  ref.invalidate(roomProvider);
                  try {
                    await ref.read(branchProvider.future);
                    await ref.read(roomProvider.future);
                  } catch (e, st) {
                    debugPrint('Error: $e\n$st');
                  }
                },
              ),
              const CupertinoSliverNavigationBar(
                largeTitle: Text(
                  'Thống kê & Sơ đồ',
                  style: TextStyle(color: CupertinoColors.black),
                ),
                backgroundColor: Color(0x00000000),
                border: null,
                transitionBetweenRoutes: false,
              ),
              SliverToBoxAdapter(
                child: roomsAsync.when(
                  data: (rooms) {
                    if (rooms.isEmpty) return const SizedBox.shrink();

                    int total = rooms.length;
                    int rented = rooms.where((r) => r.isDaThue).length;
                    double revenue = rooms
                        .where((r) => r.isDaThue)
                        .fold(0.0, (sum, r) => sum + (r.price ?? 0.0));

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TỔNG QUAN',
                            style: TextStyle(
                              color: AppTheme.kTextSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: GlassContainer(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(
                                            CupertinoIcons.building_2_fill,
                                            color: AppTheme.kAccentColor,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Phòng đang thuê',
                                            style: TextStyle(
                                              color: AppTheme.kTextSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            '$rented',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 24,
                                              color: AppTheme.kTextPrimary,
                                            ),
                                          ),
                                          Text(
                                            '/$total',
                                            style: const TextStyle(
                                              color: AppTheme.kTextMuted,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GlassContainer(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(
                                            CupertinoIcons
                                                .money_dollar_circle_fill,
                                            color: CupertinoColors.activeGreen,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Doanh thu dự kiến',
                                            style: TextStyle(
                                              color: AppTheme.kTextSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        NumberFormat.currency(
                                          locale: 'vi_VN',
                                          symbol: 'đ',
                                        ).format(revenue),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 18,
                                          color: AppTheme.kTextPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          GlassContainer(
                            padding: const EdgeInsets.all(16),
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
                                      'Phân Tích AI',
                                      style: TextStyle(
                                        color: AppTheme.kTextSecondary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                aiAdviceAsync.when(
                                  data: (advice) => MarkdownBody(
                                    data: advice,
                                    styleSheet: MarkdownStyleSheet(
                                      p: const TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.kTextPrimary,
                                        height: 1.5,
                                      ),
                                      strong: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.kBrand,
                                      ),
                                    ),
                                  ),
                                  loading: () => const Center(
                                    child: CupertinoActivityIndicator(),
                                  ),
                                  error: (err, _) =>
                                      AppErrorWidget(error: err, compact: true),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () =>
                                context.push('/owner-advanced-analytics'),
                            child: GlassContainer(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              color: CupertinoColors.activeOrange.withValues(
                                alpha: 0.1,
                              ),
                              border: Border.all(
                                color: CupertinoColors.activeOrange.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons.graph_square_fill,
                                    color: CupertinoColors.activeOrange,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Business Intelligence (Advanced)',
                                    style: TextStyle(
                                      color: CupertinoColors.activeOrange,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (e, st) => const SizedBox.shrink(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: branchesAsync.when(
                  data: (branches) {
                    if (branches.isEmpty) {
                      return const SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'Chưa có dữ liệu dãy trọ',
                            style: TextStyle(color: Color(0xFF4B5563)),
                          ),
                        ),
                      );
                    }
                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final branch = branches[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.building_2_fill,
                                    color: AppTheme.kAccentColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      branch.branchName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                        color: CupertinoColors.black,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${roomsAsync.value?.where((r) => r.branchId == branch.id).length ?? branch.totalRooms} phòng',
                                    style: const TextStyle(
                                      color: Color(0xFF4B5563),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              roomsAsync.when(
                                data: (rooms) {
                                  final branchRooms = rooms
                                      .where((r) => r.branchId == branch.id)
                                      .toList();
                                  if (branchRooms.isEmpty) {
                                    return const GlassContainer(
                                      padding: EdgeInsets.all(16),
                                      child: Center(
                                        child: Text(
                                          'Chưa có phòng nào.',
                                          style: TextStyle(
                                            color: Color(0xFF4B5563),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                  return GlassContainer(
                                    padding: const EdgeInsets.all(16),
                                    child: StatisticsFloorMap(
                                      branchRooms: branchRooms,
                                    ),
                                  );
                                },
                                loading: () => const Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: CupertinoActivityIndicator(),
                                ),
                                error: (err, _) => Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text('Lỗi: $err'),
                                ),
                              ),
                            ],
                          ),
                        );
                      }, childCount: branches.length),
                    );
                  },
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CupertinoActivityIndicator()),
                  ),
                  error: (err, _) =>
                      SliverFillRemaining(child: AppErrorWidget(error: err)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
