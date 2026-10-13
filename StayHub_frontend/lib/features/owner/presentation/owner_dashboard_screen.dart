import 'package:flutter/cupertino.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/theme/app_theme.dart';
import 'owner_feature_config_screen.dart';
import 'owner_building_map_screen.dart' as owner_building_map;
import '../../contract/presentation/contract_list_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../marketplace/data/booking_request_provider.dart';
import 'expense_management_screen.dart';
import 'dart:async' show unawaited;

class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LiquidGlassScaffold(
      title: 'Chủ Nhà',
      backgroundColors: AppTheme.kBackgroundLight,
      useScrollView: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildBookingApprovalBanner(ref),
            const Text(
              'TỔNG QUAN TÀI SẢN',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: AppTheme.kPremiumShadowLight,
                border: Border.all(
                  color: AppTheme.kBorderColor.withValues(alpha: 0.6),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Doanh Thu',
                    '45.2tr',
                    CupertinoColors.activeGreen,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: CupertinoColors.systemGrey5,
                  ),
                  _buildStatItem('Trống', '2', CupertinoColors.destructiveRed),
                  Container(
                    width: 1,
                    height: 40,
                    color: CupertinoColors.systemGrey5,
                  ),
                  _buildStatItem('Nợ Cước', '1', CupertinoColors.activeOrange),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'CÔNG CỤ QUẢN LÝ (OWNER MESH)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildGridItem(
                  context: context,
                  icon: CupertinoIcons.settings_solid,
                  color: CupertinoColors.systemIndigo,
                  title: 'Cấu Hình\n50 Tính Năng',
                  onTap: () {
                    unawaited(
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (c) => const OwnerFeatureConfigScreen(),
                        ),
                      ),
                    );
                  },
                ),
                _buildGridItem(
                  context: context,
                  icon: CupertinoIcons.building_2_fill,
                  color: CupertinoColors.systemTeal,
                  title: 'Quản Lý\nDãy Trọ',
                  onTap: () {
                    unawaited(
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (c) =>
                              const owner_building_map.OwnerBuildingMapScreen(),
                        ),
                      ),
                    );
                  },
                ),
                _buildGridItem(
                  context: context,
                  icon: CupertinoIcons.person_2_square_stack,
                  color: CupertinoColors.activeOrange,
                  title: 'Hợp Đồng &\nKhách Thuê',
                  onTap: () {
                    unawaited(
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (c) => const ContractListScreen(),
                        ),
                      ),
                    );
                  },
                ),
                _buildGridItem(
                  context: context,
                  icon: CupertinoIcons.money_dollar_circle_fill,
                  color: CupertinoColors.systemRed,
                  title: 'Quản Lý\nChi Phí',
                  onTap: () {
                    unawaited(
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (c) => const ExpenseManagementScreen(),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 26,
            letterSpacing: -0.5,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.kTextSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildGridItem({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.kBorderColor.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppTheme.kTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingApprovalBanner(WidgetRef ref) {
    final state = ref.watch(bookingRequestProvider);
    final isPending = state != null && state.status == BookingStatus.pending;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: !isPending
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: PremiumGradients.oceanBlue,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A6FD4).withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(2), // Viền gradient mỏng
                child: Container(
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: PremiumGradients.oceanBlue,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF1A6FD4,
                                  ).withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              CupertinoIcons.calendar_badge_plus,
                              color: CupertinoColors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Text(
                              'Lịch hẹn xem phòng 🛎️',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Khách hàng muốn hẹn xem Phòng ${state.roomName} vào ngày ${state.date.day}/${state.date.month} lúc ${state.hour}:00.',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.kTextSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => ref
                                  .read(bookingRequestProvider.notifier)
                                  .rejectRequest(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemGrey6,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'Từ Chối',
                                  style: TextStyle(
                                    color: CupertinoColors.systemRed,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => ref
                                  .read(bookingRequestProvider.notifier)
                                  .approveRequest(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  gradient: PremiumGradients.oceanBlue,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF1A6FD4,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'Chốt Lịch',
                                  style: TextStyle(
                                    color: CupertinoColors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
