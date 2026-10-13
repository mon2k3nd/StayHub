import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/liquid_glass_colors.dart';
import '../../../../core/components/glass_container.dart';
import '../../../../core/components/animated_list_wrapper.dart';
import '../../application/rental_request_notifier.dart';
import 'dart:async' show unawaited;

class OwnerStatsGrid extends ConsumerWidget {
  final Map<String, dynamic> stats;
  final VoidCallback onShowPendingRequests;

  const OwnerStatsGrid({
    super.key,
    required this.stats,
    required this.onShowPendingRequests,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final occupied = stats['occupiedRooms'] ?? 0;
    final total = stats['totalRooms'] ?? 0;
    final expiring = stats['expiringContracts'] ?? 0;

    final pendingList = ref.watch(pendingRequestsProvider);
    final newRequests = pendingList.length;

    final unpaidBills = stats['unpaidBillsCount'] ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.6,
      children:
          [
                _buildStatCard(
                  '$occupied/$total',
                  'Phòng đã thuê',
                  CupertinoIcons.house_fill,
                  PremiumGradients.oceanBlue,
                  imagePath: 'assets/images/features/feat_room.png',
                ),
                _buildStatCard(
                  expiring.toString().padLeft(2, '0'),
                  'HĐ hết hạn',
                  CupertinoIcons.doc_text_fill,
                  PremiumGradients.purpleNebula,
                  imagePath: 'assets/images/features/smart_contract.png',
                ),
                GestureDetector(
                  onTap: onShowPendingRequests,
                  child: newRequests > 0
                      ? _buildRequestStatCard(
                          newRequests.toString().padLeft(2, '0'),
                          'Yêu cầu mới',
                        )
                      : _buildStatCard(
                          '00',
                          'Yêu cầu mới',
                          CupertinoIcons.bell_fill,
                          PremiumGradients.emeraldGreen,
                          imagePath: 'assets/images/features/push_alerts.png',
                        ),
                ),
                _buildStatCard(
                  unpaidBills.toString().padLeft(2, '0'),
                  'Hóa đơn nợ',
                  CupertinoIcons.doc_text,
                  PremiumGradients.fireOrange,
                  imagePath: 'assets/images/features/feat_payments.png',
                ),
              ]
              .asMap()
              .entries
              .map(
                (e) => AnimatedEntrance(
                  delay: Duration(milliseconds: 100 + e.key * 50),
                  child: e.value,
                ),
              )
              .toList(),
    );
  }

  Widget _buildRequestStatCard(String val, String label) {
    return Container(
      decoration: BoxDecoration(
        gradient: PremiumGradients.fireOrange,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemRed.withValues(alpha: 0.3),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(
                CupertinoIcons.bell_solid,
                color: CupertinoColors.white,
                size: 24,
              ),
              _PulseBadge(),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                val,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: CupertinoColors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String val,
    String label,
    IconData icon,
    LinearGradient gradient, {
    String? imagePath,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      blur: 24,
      color: CupertinoColors.white.withValues(alpha: 0.8),
      border: Border.all(
        color: CupertinoColors.white.withValues(alpha: 0.5),
        width: 1,
      ),
      child: Stack(
        children: [
          // Background glow
          Positioned(
            top: -10,
            right: -10,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    gradient.colors.first.withValues(alpha: 0.15),
                    CupertinoColors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.colors.first.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: imagePath == null
                    ? Icon(icon, color: CupertinoColors.white, size: 20)
                    : Image.asset(
                        imagePath,
                        width: 28,
                        height: 28,
                        filterQuality: FilterQuality.high,
                      ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    val,
                    style: const TextStyle(
                      color: CupertinoColors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulseBadge extends StatefulWidget {
  @override
  _PulseBadgeState createState() => _PulseBadgeState();
}

class _PulseBadgeState extends State<_PulseBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    unawaited(_ctrl.repeat(reverse: true));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: CupertinoColors.white.withValues(
              alpha: 0.5 + _ctrl.value * 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.white.withValues(
                  alpha: _ctrl.value * 0.5,
                ),
                blurRadius: 4 * _ctrl.value,
                spreadRadius: 2 * _ctrl.value,
              ),
            ],
          ),
        );
      },
    );
  }
}
