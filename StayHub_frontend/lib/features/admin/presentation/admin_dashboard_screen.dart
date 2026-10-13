import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/providers/core_providers.dart';
import '../../notification/data/notification_provider.dart';
import '../../../core/components/premium_shimmer_loading.dart';

import 'widgets/admin_stats_grid.dart';
import 'widgets/admin_saas_chart.dart';
import 'widgets/admin_action_feed.dart';
import 'admin_omni_search.dart';
import 'widgets/system_health_radar.dart';
import 'widgets/admin_tools_mesh.dart';
import '../../auth/application/auth_notifier.dart';
import '../../../core/components/app_error_widget.dart';
import 'dart:async' show unawaited;

final adminDashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) async {
    final client = ref.watch(apiClientProvider);
    final response = await client.get('/v1/admin/dashboard');
    if (response['success'] == true) {
      final rawData = response['data'];
      if (rawData is Map<String, dynamic>) return rawData;
    }
    throw Exception(
      response['message'] ?? 'Không tải được dữ liệu dashboard admin.',
    );
  },
);

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardProvider);
    final notificationsAsync = ref.watch(notificationsProvider);

    return LiquidGlassScaffold(
      title: 'StayHub Admin Hub',
      backgroundColors: AppTheme.kBackgroundLight,
      useScrollView: false,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(
              CupertinoIcons.search,
              color: CupertinoColors.black,
              size: 28,
            ),
            onPressed: () {
              unawaited(
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (c) => const AdminOmniSearchScreen(),
                  ),
                ),
              );
            },
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(
              CupertinoIcons.square_arrow_right,
              color: CupertinoColors.systemRed,
              size: 28,
            ),
            onPressed: () async {
              unawaited(HapticFeedback.heavyImpact());
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              ref.invalidate(adminDashboardProvider);
              ref.invalidate(notificationsProvider);
              try {
                await ref.read(adminDashboardProvider.future);
                await ref.read(notificationsProvider.future);
              } catch (e, st) {
                debugPrint('Error: $e\n$st');
              }
            },
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
            sliver: statsAsync.when(
              data: (stats) {
                return SliverList(
                  delegate: SliverChildListDelegate([
                    SystemHealthRadar(stats: stats),
                    const SizedBox(height: 24),
                    AdminStatsGrid(stats: stats),
                    const SizedBox(height: 28),
                    _buildSectionHeader('PHÂN BỔ GÓI SAAS', [
                      const Color(0xFF298FFF),
                      const Color(0xFF298FFF),
                    ]),
                    const SizedBox(height: 14),
                    AdminSaasChart(stats: stats),
                    const SizedBox(height: 28),
                    _buildSectionHeader('HOẠT ĐỘNG GẦN ĐÂY', [
                      const Color(0xFF10B981),
                      const Color(0xFF298FFF),
                    ]),
                    const SizedBox(height: 14),
                    AdminActionFeed(notificationsAsync: notificationsAsync),
                    const SizedBox(height: 28),
                    _buildSectionHeader('CÔNG CỤ QUẢN TRỊ', [
                      const Color(0xFFF59E0B),
                      const Color(0xFFEF4444),
                    ]),
                    const SizedBox(height: 14),
                    const AdminToolsMesh(),
                  ]),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: PremiumShimmerLoading(itemCount: 4, itemHeight: 120),
                ),
              ),
              error: (err, _) =>
                  SliverFillRemaining(child: AppErrorWidget(error: err)),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildSectionHeader(String title, List<Color> gradientColors) {
  return Row(
    children: [
      Container(
        width: 4,
        height: 20,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 10),
      Text(
        title,
        style: const TextStyle(
          color: Color(0xFF1F2937),
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    ],
  );
}
