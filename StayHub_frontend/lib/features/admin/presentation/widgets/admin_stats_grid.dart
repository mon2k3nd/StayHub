import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../../../core/components/glass_container.dart';
import '../../../../core/theme/liquid_glass_colors.dart';
import '../../../../core/theme/app_theme.dart';

class AdminStatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;

  const AdminStatsGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildRevenueCard(
                formatter.format(stats['totalRevenue'] ?? 0),
                'Doanh thu Tổng (Platform)',
                CupertinoIcons.money_dollar_circle_fill,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '${stats['totalOwners'] ?? 0}',
                'Chủ nhà (Đối tác)',
                CupertinoIcons.person_3_fill,
                PremiumGradients.oceanBlue,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                '${stats['totalRooms'] ?? 0}',
                'Phòng trên hệ thống',
                CupertinoIcons.building_2_fill,
                PremiumGradients.fireOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '${(stats['occupancyRate'] ?? 0).toStringAsFixed(1)}%',
                'Lấp đầy (Toàn sàn)',
                CupertinoIcons.chart_pie_fill,
                PremiumGradients.emeraldGreen,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                '99.9%',
                'Uptime',
                CupertinoIcons.check_mark_circled_solid,
                PremiumGradients.purpleNebula,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Thẻ doanh thu có giao diện "quyền lực" hơn với Gradient
  Widget _buildRevenueCard(String value, String label, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        gradient: PremiumGradients.purpleNebula,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: CupertinoColors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4C1D95).withValues(alpha: 0.3),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: CupertinoColors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: CupertinoColors.white, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: CupertinoColors.white,
              fontSize: 26,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: CupertinoColors.white.withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
    LinearGradient gradient,
  ) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 24,
      blur: 24,
      color: CupertinoColors.white.withValues(alpha: 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return gradient.createShader(bounds);
            },
            child: Icon(icon, color: CupertinoColors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: CupertinoColors.black,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
