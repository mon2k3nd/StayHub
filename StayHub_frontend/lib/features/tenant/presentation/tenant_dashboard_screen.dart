import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/tenant_owner_feature_provider.dart';
import 'tenant_smart_key_screen.dart' as tenant_smart_key;
import 'tenant_payment_screen.dart' as tenant_payment;
import 'tenant_services_screen.dart';
import '../../chat/presentation/chat_list_screen.dart';

import '../../../core/components/smart_greeting_widget.dart';
import 'dart:async' show unawaited;

class TenantDashboardScreen extends ConsumerWidget {
  const TenantDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = ref.watch(dynamicFeaturesProvider);

    return LiquidGlassScaffold(
      title: 'Nhà Của Tôi',
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
      },
      trailing: GestureDetector(
        onTap: () {
          unawaited(
            Navigator.push(
              context,
              CupertinoPageRoute(builder: (c) => const ChatListScreen()),
            ),
          );
        },
        child: const Icon(
          CupertinoIcons.chat_bubble_2_fill,
          color: AppTheme.kAccentColor,
        ),
      ),
      backgroundColors: AppTheme.kBackgroundLight,
      useScrollView: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const SmartGreetingWidget(),
            const SizedBox(height: 8),
            const Text(
              'Phòng 302 - Tòa nhà Sunshine, Quận 7',
              style: TextStyle(fontSize: 14, color: AppTheme.kTextSecondary),
            ),
            const SizedBox(height: 24),

            // --- 1. IoT Smart Key ---
            if (features['tenant_iot_smart_key'] == true) ...[
              GestureDetector(
                onTap: () {
                  unawaited(
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (c) =>
                            const tenant_smart_key.TenantSmartKeyScreen(),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: AppTheme.kPremiumShadowLight,
                    border: Border.all(
                      color: AppTheme.kBorderColor.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.kBrand.withValues(alpha: 0.1),
                            border: Border.all(
                              color: AppTheme.kBrand,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            CupertinoIcons.lock_open_fill,
                            size: 48,
                            color: AppTheme.kBrand,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Chạm để mở khóa cửa chính',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppTheme.kTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Bluetooth Đã Kết Nối',
                          style: TextStyle(
                            color: CupertinoColors.activeGreen,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // --- 2. Billing & One-tap Payment ---
            if (features['tenant_one_tap_payment'] == true) ...[
              const Text(
                'HÓA ĐƠN THÁNG NÀY',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.kTextSecondary,
                  fontSize: 13,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFF8FAFC),
                      Color(0xFFF1F5F9),
                    ], // Soft surface
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: AppTheme.kPremiumShadowLight,
                  border: Border.all(
                    color: AppTheme.kBorderColor.withValues(alpha: 0.6),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tháng 06/2026',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.kTextPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.destructiveRed.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Text(
                            'CHƯA THANH TOÁN',
                            style: TextStyle(
                              color: CupertinoColors.destructiveRed,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '4,500,000 đ',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        color: CupertinoColors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hạn chót: 05/07/2026',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.kTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        color: AppTheme.kBrand,
                        borderRadius: BorderRadius.circular(50),
                        onPressed: () {
                          unawaited(
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (c) =>
                                    const tenant_payment.TenantPaymentScreen(),
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Thanh toán 1-chạm (Apple Pay)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // --- 3. Bill Splitting ---
            if (features['tenant_bill_splitting'] == true) ...[
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: CupertinoColors.activeOrange.withValues(
                          alpha: 0.1,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.group_solid,
                        color: CupertinoColors.activeOrange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chia tiền phòng',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            'Bạn cùng phòng nợ bạn: 2,250k',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.kTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Đòi tiền'),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // --- 4. Grid Features (Dynamic) ---
            const Text(
              'TIỆN ÍCH KHU TRỌ',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.kTextSecondary,
                fontSize: 13,
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
                if (features['tenant_video_maintenance'] == true)
                  _buildGridItem(
                    icon: CupertinoIcons.wrench_fill,
                    color: CupertinoColors.systemRed,
                    imagePath: 'assets/images/features/video_maintenance.png',
                    title: 'Báo Sự Cố\n(Video)',
                  ),
                if (features['tenant_utilities_dashboard'] == true)
                  _buildGridItem(
                    icon: CupertinoIcons.drop_fill,
                    color: CupertinoColors.activeBlue,
                    imagePath: 'assets/images/features/utilities_dashboard.png',
                    title: 'Số Điện Nước',
                  ),
                if (features['tenant_community_board'] == true)
                  GestureDetector(
                    onTap: () => context.push('/community'),
                    child: _buildGridItem(
                      icon: CupertinoIcons.person_3_fill,
                      color: CupertinoColors.activeOrange,
                      imagePath: 'assets/images/features/community_board.png',
                      title: 'Bảng Tin\nCộng Đồng',
                    ),
                  ),
                if (features['tenant_ai_roommate'] == true)
                  _buildGridItem(
                    icon: CupertinoIcons.person_2_fill,
                    color: CupertinoColors.systemPurple,
                    imagePath: 'assets/images/features/ai_roommate.png',
                    title: 'Tìm Người\nỞ Ghép',
                  ),
                if (features['tenant_local_services'] == true)
                  GestureDetector(
                    onTap: () {
                      unawaited(
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (c) => const TenantServicesScreen(),
                          ),
                        ),
                      );
                    },
                    child: _buildGridItem(
                      icon: CupertinoIcons.bag_fill,
                      color: CupertinoColors.systemPink,
                      imagePath: 'assets/images/features/local_services.png',
                      title: 'Chợ Dịch Vụ',
                    ),
                  ),
                GestureDetector(
                  onTap: () => context.push('/contract-list'),
                  child: _buildGridItem(
                    icon: CupertinoIcons.doc_text_fill,
                    color: CupertinoColors.systemIndigo,
                    imagePath: 'assets/images/features/smart_contract.png',
                    title: 'Hợp Đồng\nĐiện Tử',
                  ),
                ),
                if (features['tenant_smart_locker'] == true)
                  _buildGridItem(
                    icon: CupertinoIcons.cube_box_fill,
                    color: CupertinoColors.systemTeal,
                    imagePath: 'assets/images/features/smart_locker.png',
                    title: 'Tủ Đồ\nThông Minh',
                  ),
              ],
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildGridItem({
    required IconData icon,
    required Color color,
    required String title,
    String? imagePath,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.kBorderColor.withValues(alpha: 0.4)),
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
            padding: EdgeInsets.all(imagePath == null ? 12 : 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: imagePath == null
                ? Icon(icon, color: color, size: 28)
                : Image.asset(
                    imagePath,
                    width: 44,
                    height: 44,
                    filterQuality: FilterQuality.high,
                  ),
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
    );
  }
}
