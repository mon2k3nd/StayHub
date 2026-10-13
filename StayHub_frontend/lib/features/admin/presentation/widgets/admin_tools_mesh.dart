import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/liquid_glass_colors.dart';
import '../global_broadcast_screen.dart';
import '../admin_saas_management_screen.dart';
import '../admin_audit_logs_screen.dart';
import '../admin_geo_map_screen.dart';
import '../admin_legal_blueprints_screen.dart';
import '../admin_helpdesk_screen.dart';
import '../admin_payment_config_screen.dart';
import '../admin_system_settings_screen.dart';
import '../../../../core/components/glass_container.dart';
import '../../../owner/presentation/owner_dashboard_screen.dart'
    as owner_dashboard;
import '../../../tenant/presentation/tenant_dashboard_screen.dart'
    as tenant_dashboard;
import 'dart:async' show unawaited;

class AdminToolsMesh extends StatelessWidget {
  const AdminToolsMesh({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      childAspectRatio: 0.8,
      children: [
        _buildToolIcon(
          context,
          CupertinoIcons.doc_text_fill,
          'Pháp lý',
          CupertinoColors.systemPurple,
          () {
            unawaited(
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (c) => const AdminLegalBlueprintsScreen(),
                ),
              ),
            );
          },
          imagePath: 'assets/images/features/smart_contract.png',
        ),
        _buildToolIcon(
          context,
          CupertinoIcons.cart_fill,
          'SaaS',
          CupertinoColors.systemPink,
          () {
            unawaited(
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (c) => const AdminSaasManagementScreen(),
                ),
              ),
            );
          },
          imagePath: 'assets/images/features/marketing_campaign.png',
        ),
        _buildToolIcon(
          context,
          CupertinoIcons.map_fill,
          'Bản đồ',
          CupertinoColors.systemGreen,
          () {
            unawaited(
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (c) => const AdminGeoMapScreen()),
              ),
            );
          },
          imagePath: 'assets/images/features/competitor_analysis.png',
        ),
        _buildToolIcon(
          context,
          CupertinoIcons.speaker_3_fill,
          'Phát thanh',
          CupertinoColors.activeOrange,
          () {
            unawaited(
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (c) => const GlobalBroadcastScreen(),
                ),
              ),
            );
          },
          imagePath: 'assets/images/features/broadcast_msg.png',
        ),
        _buildToolIcon(
          context,
          CupertinoIcons.home,
          'Owner App',
          CupertinoColors.systemIndigo,
          () {
            unawaited(
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (c) => const owner_dashboard.OwnerDashboardScreen(),
                ),
              ),
            );
          },
          imagePath: 'assets/images/features/multi_property.png',
        ),
        _buildToolIcon(
          context,
          CupertinoIcons.headphones,
          'Helpdesk',
          LiquidGlassColors.adminAccent,
          () {
            unawaited(
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (c) => const AdminHelpdeskScreen()),
              ),
            );
          },
          imagePath: 'assets/images/features/chatbot.png',
        ),
        _buildToolIcon(
          context,
          CupertinoIcons.money_dollar_circle_fill,
          'Thanh toán',
          const Color(0xFFA50064),
          () {
            unawaited(
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (c) => const AdminPaymentConfigScreen(),
                ),
              ),
            );
          },
          imagePath: 'assets/images/features/one_tap_payment.png',
        ),
        _buildToolIcon(
          context,
          CupertinoIcons.shield_fill,
          'Audit Log',
          CupertinoColors.systemIndigo,
          () {
            unawaited(
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (c) => const AdminAuditLogsScreen(),
                ),
              ),
            );
          },
          imagePath: 'assets/images/features/rbac.png',
        ),
        _buildToolIcon(
          context,
          CupertinoIcons.person_alt,
          'Tenant App',
          CupertinoColors.systemTeal,
          () {
            unawaited(
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (c) =>
                      const tenant_dashboard.TenantDashboardScreen(),
                ),
              ),
            );
          },
          imagePath: 'assets/images/features/tenant_bg_check.png',
        ),
        _buildToolIcon(
          context,
          CupertinoIcons.settings_solid,
          'Hệ thống',
          CupertinoColors.systemGrey,
          () {
            unawaited(
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (c) => const AdminSystemSettingsScreen(),
                ),
              ),
            );
          },
          imagePath: 'assets/images/features/feat_settings.png',
        ),
        _buildToolIcon(
          context,
          CupertinoIcons.gift_fill,
          'Affiliate',
          CupertinoColors.systemPurple,
          () {
            unawaited(context.push('/admin-affiliate'));
          },
          imagePath: 'assets/images/features/loyalty_rewards.png',
        ),
      ],
    );
  }

  Widget _buildToolIcon(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap, {
    String? imagePath,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min, // Đảm bảo Column thu gọn theo nội dung
        children: [
          GlassContainer(
            padding: const EdgeInsets.all(16),
            child: imagePath != null
                ? Image.asset(
                    imagePath,
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    isAntiAlias: true,
                    errorBuilder: (_, __, ___) =>
                        Icon(icon, color: color, size: 28),
                  )
                : Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.black,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
