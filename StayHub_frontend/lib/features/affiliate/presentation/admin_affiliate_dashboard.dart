import 'package:flutter/cupertino.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/theme/app_theme.dart';

class AdminAffiliateDashboard extends StatelessWidget {
  const AdminAffiliateDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      title: 'Quản Lý Affiliate',
      useScrollView: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            _buildStatsOverview(),
            const SizedBox(height: 24),
            _buildTopReferrers(),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tổng Quan',
          style: TextStyle(
            color: AppTheme.kTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Tổng Lượt Mời',
                value: '1,250',
                icon: CupertinoIcons.person_2_fill,
                color: CupertinoColors.systemIndigo,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Thành Công',
                value: '450',
                icon: CupertinoIcons.check_mark_circled_solid,
                color: CupertinoColors.systemGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Tỷ Lệ Chuyển Đổi',
                value: '36%',
                icon: CupertinoIcons.chart_pie_fill,
                color: CupertinoColors.systemOrange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: 'Chi Phí (Gói Tặng)',
                value: '145tr',
                icon: CupertinoIcons.money_dollar_circle_fill,
                color: CupertinoColors.systemRed,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return GlassContainer(
      blur: 10,
      borderRadius: 16.0,
      border: Border.all(color: AppTheme.kBorderColor),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.kTextPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.kTextSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopReferrers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Chủ Nhà Giới Thiệu',
          style: TextStyle(
            color: AppTheme.kTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GlassContainer(
          blur: 10,
          borderRadius: 20.0,
          border: Border.all(color: AppTheme.kBorderColor),
          child: Column(
            children: [
              _buildLeaderboardItem(
                1,
                'Trần Minh Đức',
                'STAYHUB-DUC99',
                45,
                CupertinoColors.systemYellow,
              ),
              _buildDivider(),
              _buildLeaderboardItem(
                2,
                'Lê Hải Yến',
                'STAYHUB-YEN88',
                38,
                CupertinoColors.systemGrey,
              ),
              _buildDivider(),
              _buildLeaderboardItem(
                3,
                'Nguyễn Văn Nam',
                'STAYHUB-NAM77',
                29,
                CupertinoColors.systemBrown,
              ),
              _buildDivider(),
              _buildLeaderboardItem(
                4,
                'Phạm Thu Trang',
                'STAYHUB-TRANG',
                20,
                null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardItem(
    int rank,
    String name,
    String code,
    int count,
    Color? medalColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: medalColor ?? AppTheme.kBorderColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppTheme.kTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  code,
                  style: const TextStyle(
                    color: AppTheme.kAccentColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$count',
            style: const TextStyle(
              color: AppTheme.kTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'người',
            style: TextStyle(color: AppTheme.kTextSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: AppTheme.kBorderColor.withValues(alpha: 0.5),
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
