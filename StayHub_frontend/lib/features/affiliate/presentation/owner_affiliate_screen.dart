import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/bounce_click.dart';
import '../../../core/theme/app_theme.dart';
import 'dart:async' show unawaited;

class OwnerAffiliateScreen extends StatefulWidget {
  const OwnerAffiliateScreen({super.key});

  @override
  State<OwnerAffiliateScreen> createState() => _OwnerAffiliateScreenState();
}

class _OwnerAffiliateScreenState extends State<OwnerAffiliateScreen> {
  final String referralCode = 'STAYHUB-PHD99';
  final int totalReferred = 3;
  final String pendingReward = '3 Tháng Gói PRO';

  void _copyToClipboard(BuildContext context) {
    unawaited(Clipboard.setData(ClipboardData(text: referralCode)));
    // Ideally we would show a toast here.
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      title: 'Tiếp Thị Liên Kết',
      useScrollView: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            _buildHeroBanner(context),
            const SizedBox(height: 24),
            _buildReferralCodeSection(context),
            const SizedBox(height: 24),
            _buildStatsGrid(),
            const SizedBox(height: 24),
            _buildHowItWorks(),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [CupertinoColors.systemPurple, CupertinoColors.systemIndigo],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemPurple.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            CupertinoIcons.gift_fill,
            color: CupertinoColors.white,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Mời Bạn Bè, Nhận Gói PRO Miễn Phí!',
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Với mỗi Chủ nhà bạn mời thành công, cả hai đều nhận được 1 tháng dùng gói PRO trị giá 999.000đ.',
            style: TextStyle(
              color: CupertinoColors.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCodeSection(BuildContext context) {
    return GlassContainer(
      blur: 10,
      borderRadius: 20.0,
      border: Border.all(color: AppTheme.kBorderColor),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Mã Giới Thiệu Của Bạn',
              style: TextStyle(
                color: AppTheme.kTextSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: AppTheme.kSurfaceBlue,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.kAccentColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    referralCode,
                    style: const TextStyle(
                      color: AppTheme.kAccentColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            BounceClick(
              onPressed: () => _copyToClipboard(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.kTextPrimary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.doc_on_doc_fill,
                      color: CupertinoColors.white,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Sao Chép Mã',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Đã Mời',
            value: '$totalReferred người',
            icon: CupertinoIcons.person_3_fill,
            color: CupertinoColors.systemBlue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            title: 'Phần Thưởng',
            value: pendingReward,
            icon: CupertinoIcons.star_fill,
            color: CupertinoColors.systemYellow,
          ),
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
      borderRadius: 20.0,
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
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.kTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.kTextSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Cách Thức Hoạt Động',
          style: TextStyle(
            color: AppTheme.kTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildStepItem('1', 'Chia sẻ mã giới thiệu của bạn cho Chủ nhà khác.'),
        _buildStepItem('2', 'Chủ nhà mới đăng ký và nhập mã của bạn.'),
        _buildStepItem('3', 'Cả hai nhận ngay 1 tháng Gói PRO miễn phí!'),
      ],
    );
  }

  Widget _buildStepItem(String step, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppTheme.kTextPrimary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: const TextStyle(
                  color: AppTheme.kTextSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
