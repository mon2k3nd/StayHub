import 'package:flutter/material.dart'
    show LinearProgressIndicator, AlwaysStoppedAnimation, Divider;
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/components/glass_container.dart';
import '../../../../../core/components/liquid_background.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../application/owner_marketing_notifier.dart';

class OwnerMarketingCampaignScreen extends ConsumerWidget {
  const OwnerMarketingCampaignScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(marketingProvider);
    final notifier = ref.read(marketingProvider.notifier);
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Chiến Dịch Marketing AI'),
        backgroundColor: const Color(0x00000000),
        border: null,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add_circled),
          onPressed: () {},
        ),
      ),
      child: LiquidBackground(
        colors: AppTheme.kBackgroundLight,
        child: SafeArea(
          child: state.isLoading
              ? const Center(child: CupertinoActivityIndicator(radius: 20))
              : CustomScrollView(
                  slivers: [
                    CupertinoSliverRefreshControl(
                      onRefresh: () async {
                        await Future.delayed(
                          const Duration(milliseconds: 1000),
                        );
                      },
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final campaign = state.campaigns[index];
                          return _buildCampaignCard(
                            campaign,
                            notifier,
                            formatter,
                          );
                        }, childCount: state.campaigns.length),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildCampaignCard(
    Campaign campaign,
    MarketingNotifier notifier,
    NumberFormat formatter,
  ) {
    final isRunning = campaign.status == 'Đang chạy';
    final budgetPercent = campaign.budget > 0
        ? (campaign.spent / campaign.budget)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: GlassContainer(
        borderRadius: 24,
        blur: 20,
        color: CupertinoColors.white.withValues(alpha: 0.9),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        campaign.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: CupertinoColors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Target: ${campaign.target}',
                        style: const TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoSwitch(
                  value: isRunning,
                  activeTrackColor: AppTheme.kAccentColor,
                  onChanged: (val) =>
                      notifier.toggleCampaignStatus(campaign.id),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(color: CupertinoColors.systemGrey4),
            ),
            Row(
              children: [
                _buildStatItem(
                  'Lượt tiếp cận',
                  NumberFormat.compact().format(campaign.reachCount),
                  CupertinoIcons.eye_fill,
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: CupertinoColors.systemGrey4,
                ),
                _buildStatItem(
                  'Tương tác',
                  NumberFormat.compact().format(campaign.clickCount),
                  CupertinoIcons.hand_draw_fill,
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: CupertinoColors.systemGrey4,
                ),
                _buildStatItem(
                  'Chuyển đổi',
                  '${campaign.conversionCount} khách',
                  CupertinoIcons.person_add_solid,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ngân sách đã tiêu:',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${formatter.format(campaign.spent)} / ${formatter.format(campaign.budget)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: CupertinoColors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 8,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: budgetPercent.toDouble(),
                  backgroundColor: CupertinoColors.systemGrey5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    budgetPercent > 0.9
                        ? CupertinoColors.destructiveRed
                        : AppTheme.kAccentColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isRunning
                    ? AppTheme.kAccentColor.withValues(alpha: 0.1)
                    : CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isRunning
                        ? CupertinoIcons.rocket_fill
                        : CupertinoIcons.pause_fill,
                    size: 16,
                    color: isRunning
                        ? AppTheme.kAccentColor
                        : CupertinoColors.systemGrey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isRunning
                        ? 'Chiến dịch đang tối ưu AI'
                        : 'Chiến dịch đã tạm dừng',
                    style: TextStyle(
                      color: isRunning
                          ? AppTheme.kAccentColor
                          : CupertinoColors.systemGrey,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
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

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: AppTheme.kAccentColor),
              const SizedBox(width: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: CupertinoColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
