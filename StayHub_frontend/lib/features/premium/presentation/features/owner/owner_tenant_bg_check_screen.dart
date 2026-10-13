import 'package:flutter/material.dart' show Divider;
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/components/glass_container.dart';
import '../../../../../core/components/liquid_background.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../application/owner_tenant_bg_check_notifier.dart';

class OwnerTenantBgCheckScreen extends ConsumerWidget {
  const OwnerTenantBgCheckScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(tenantBgCheckProvider);
    final notifier = ref.read(tenantBgCheckProvider.notifier);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Kiểm Tra Lý Lịch Khách Thuê'),
        backgroundColor: const Color(0x00000000),
        border: null,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.search),
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
                          final req = state.requests[index];
                          return _buildRequestCard(req, notifier);
                        }, childCount: state.requests.length),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(
    BackgroundCheckRequest req,
    TenantBgCheckNotifier notifier,
  ) {
    final isProcessing = req.status == 'Đang kiểm tra';
    final isDone = req.status == 'Hoàn tất';
    final isGood = req.trustScore >= 70;

    Color statusColor;
    if (isProcessing) {
      statusColor = CupertinoColors.activeBlue;
    } else if (isDone && isGood) {
      statusColor = CupertinoColors.activeGreen;
    } else if (isDone && !isGood) {
      statusColor = CupertinoColors.destructiveRed;
    } else {
      statusColor = CupertinoColors.systemOrange;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: GlassContainer(
        borderRadius: 24,
        blur: 20,
        color: CupertinoColors.white.withValues(alpha: 0.8),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.kAccentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.person_crop_circle_badge_exclam,
                    color: AppTheme.kAccentColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.tenantName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                          color: CupertinoColors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'CCCD/CMND: ${req.identityNumber}',
                        style: const TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  req.requestDate,
                  style: const TextStyle(
                    color: CupertinoColors.systemGrey2,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Divider(color: CupertinoColors.systemGrey5),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Trạng thái: ${req.status}',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (isDone)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Điểm Tín Nhiệm: ${req.trustScore}',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (isDone && req.issues.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CupertinoColors.destructiveRed.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: CupertinoColors.destructiveRed.withValues(
                      alpha: 0.3,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          CupertinoIcons.exclamationmark_triangle_fill,
                          color: CupertinoColors.destructiveRed,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Cảnh báo hệ thống (CIC/Blacklist):',
                          style: TextStyle(
                            color: CupertinoColors.destructiveRed,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...req.issues.map(
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          '• $i',
                          style: const TextStyle(
                            color: CupertinoColors.black,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (req.status == 'Chờ duyệt') ...[
              const SizedBox(height: 24),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: AppTheme.kAccentColor,
                borderRadius: BorderRadius.circular(16),
                onPressed: () => notifier.startCheck(req.id),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.sparkles,
                      color: CupertinoColors.white,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Chạy AI Kiểm Tra Lý Lịch',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (isProcessing) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: CupertinoColors.activeBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoActivityIndicator(),
                    SizedBox(width: 12),
                    Text(
                      'Đang quét cơ sở dữ liệu quốc gia...',
                      style: TextStyle(
                        color: CupertinoColors.activeBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
