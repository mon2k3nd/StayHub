import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter/material.dart'
    show LinearProgressIndicator, AlwaysStoppedAnimation;
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

class ProfitCard extends StatelessWidget {
  final Map<String, dynamic> stats;

  ProfitCard({super.key, required this.stats});

  final _currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: '');

  @override
  Widget build(BuildContext context) {
    final netProfit = (stats['netProfitThisMonth'] as num?)?.toDouble() ?? 0.0;
    final planName = stats['currentPlanName'] as String? ?? 'CHƯA ĐĂNG KÝ GÓI';
    final growthRate = (stats['profitGrowthRate'] as num?)?.toDouble() ?? 0.0;
    final isGrowthPositive = growthRate >= 0;
    final growthLabel = isGrowthPositive ? '+$growthRate%' : '$growthRate%';
    final prevMonthLabel =
        stats['previousMonthLabel'] as String? ?? 'tháng trước';

    // BUGFIX (data): `paidBillsThisMonth`/`totalBillsThisMonth` có thể là
    // String/double → tránh TypeError khi backend trả giá trị không phải int.
    final rawPaid = stats['paidBillsThisMonth'];
    final paidBills = rawPaid is num
        ? rawPaid.toInt()
        : int.tryParse(rawPaid?.toString() ?? '') ?? 0;
    final rawTotal = stats['totalBillsThisMonth'];
    final totalBills = rawTotal is num
        ? rawTotal.toInt()
        : int.tryParse(rawTotal?.toString() ?? '') ?? 1; // avoid divide by zero
    final paidRatio = totalBills > 0 ? (paidBills / totalBills) : 0.0;
    final paidPercent = (paidRatio * 100).toInt();

    return GestureDetector(
      onTap: () => context.push('/control-center'),
      child: Container(
        padding: const EdgeInsets.all(24),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.sparkles,
                        color: CupertinoColors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        planName.toUpperCase(),
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lợi nhuận gộp (Tháng này)',
                      style: TextStyle(
                        color: CupertinoColors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currencyFmt.format(netProfit),
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 4.0, left: 2.0),
                          child: Text(
                            '₫',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isGrowthPositive
                        ? CupertinoColors.systemGreen.withValues(alpha: 0.2)
                        : CupertinoColors.systemRed.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isGrowthPositive
                            ? CupertinoIcons.arrow_up
                            : CupertinoIcons.arrow_down,
                        color: isGrowthPositive
                            ? CupertinoColors.systemGreen
                            : CupertinoColors.systemRed,
                        size: 14,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        growthLabel,
                        style: TextStyle(
                          color: isGrowthPositive
                              ? CupertinoColors.systemGreen
                              : CupertinoColors.systemRed,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        prevMonthLabel,
                        style: TextStyle(
                          color: CupertinoColors.white.withValues(alpha: 0.8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: paidRatio,
                minHeight: 4,
                backgroundColor: CupertinoColors.white.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  CupertinoColors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Thu được $paidPercent% hóa đơn tháng này',
                  style: TextStyle(
                    color: CupertinoColors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
                Text(
                  '$paidBills/$totalBills HD',
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
