import 'package:flutter/material.dart' show Divider;
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../../core/components/glass_container.dart';
import '../../../../../core/components/liquid_background.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../application/owner_lease_renewal_notifier.dart';
import 'dart:async' show unawaited;

class OwnerLeaseRenewalScreen extends ConsumerWidget {
  const OwnerLeaseRenewalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(leaseRenewalProvider);
    final notifier = ref.read(leaseRenewalProvider.notifier);
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text(
          'Tự Động Gia Hạn',
          style: TextStyle(color: CupertinoColors.black),
        ),
        backgroundColor: Color(0x00000000),
        border: null,
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
                      padding: const EdgeInsets.all(24.0),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final lease = state.leases[index];
                          return _buildLeaseCard(
                            context,
                            lease,
                            notifier,
                            formatter,
                          );
                        }, childCount: state.leases.length),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLeaseCard(
    BuildContext context,
    LeaseRenewal lease,
    LeaseRenewalNotifier notifier,
    NumberFormat formatter,
  ) {
    final isPending = lease.status == 'Sắp hết hạn';
    final daysLeft = lease.expireDate.difference(DateTime.now()).inDays;

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
                    CupertinoIcons.doc_text_search,
                    color: AppTheme.kAccentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phòng ${lease.roomName} - ${lease.tenantName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: CupertinoColors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Còn $daysLeft ngày (Hết hạn: ${DateFormat('dd/MM/yyyy').format(lease.expireDate)})',
                        style: const TextStyle(
                          color: CupertinoColors.destructiveRed,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
                const Text(
                  'Giá thuê hiện tại:',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 14,
                  ),
                ),
                Text(
                  formatter.format(lease.currentRent),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: CupertinoColors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Giá gia hạn (Dự kiến):',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: isPending
                      ? () => _showEditRentDialog(
                          context,
                          lease,
                          notifier,
                          formatter,
                        )
                      : null,
                  child: Row(
                    children: [
                      Text(
                        formatter.format(lease.proposedRent),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppTheme.kAccentColor,
                        ),
                      ),
                      if (isPending) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          CupertinoIcons.pencil_circle_fill,
                          color: AppTheme.kAccentColor,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (isPending)
              CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 14),
                color: AppTheme.kAccentColor,
                borderRadius: BorderRadius.circular(16),
                onPressed: () => notifier.sendRenewalOffer(lease.id),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.paperplane_fill,
                      color: CupertinoColors.white,
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Gửi đề nghị gia hạn (Smart Contract)',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey5,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Trạng thái: ${lease.status}',
                    style: const TextStyle(
                      color: CupertinoColors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showEditRentDialog(
    BuildContext context,
    LeaseRenewal lease,
    LeaseRenewalNotifier notifier,
    NumberFormat formatter,
  ) {
    double newRent = lease.proposedRent;
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (context) => Container(
          height: 300,
          color: CupertinoColors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Hủy'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    child: const Text(
                      'Lưu',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onPressed: () {
                      notifier.updateProposedRent(lease.id, newRent);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 40,
                  scrollController: FixedExtentScrollController(
                    initialItem: 5,
                  ), // Assuming some index, simplify for demo
                  onSelectedItemChanged: (index) {
                    // Giả lập tăng giảm 100k
                    newRent = lease.currentRent + (index - 5) * 100000;
                  },
                  children: List.generate(11, (index) {
                    final val = lease.currentRent + (index - 5) * 100000;
                    return Center(child: Text(formatter.format(val)));
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
