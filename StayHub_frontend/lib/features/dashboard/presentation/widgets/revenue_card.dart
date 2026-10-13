import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../../../core/components/shimmer_block.dart';
import 'dart:async' show unawaited;

class RevenueCard extends StatefulWidget {
  final bool isPlanFree;
  final String netProfit;
  final String totalRevenue;
  final String totalExpense;
  final double growthRate;
  final int paidBills;
  final int totalBills;
  final double unpaidAmount;

  const RevenueCard({
    super.key,
    required this.isPlanFree,
    required this.netProfit,
    required this.totalRevenue,
    required this.totalExpense,
    required this.growthRate,
    required this.paidBills,
    required this.totalBills,
    required this.unpaidAmount,
  });

  @override
  State<RevenueCard> createState() => _RevenueCardState();
}

class _RevenueCardState extends State<RevenueCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    unawaited(_controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPositiveGrowth = widget.growthRate >= 0;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _animation.value)),
          child: Opacity(
            opacity: _animation.value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF298FFF), Color(0xFF1A6FD4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF298FFF).withValues(alpha: 0.25),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative subtle shapes for premium feel
            Positioned(
              top: -50,
              right: -30,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'L?I NHU?N THU?N',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      // Growth Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isPositiveGrowth
                              ? const Color(0xFF10B981) // Success
                              : const Color(0xFFEF4444), // Error
                          borderRadius: BorderRadius.circular(
                            100,
                          ), // Pill shape
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isPositiveGrowth
                                  ? CupertinoIcons.arrow_up_right
                                  : CupertinoIcons.arrow_down_right,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.growthRate.abs().toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.netProfit,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Revenue & Expense Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildSubCard(
                          icon: CupertinoIcons.arrow_down_left_circle_fill,
                          imagePath:
                              'assets/images/features/auto_rent_collection.png',
                          iconColor: const Color(0xFF10B981), // Success
                          title: 'T?ng Thu',
                          value: widget.totalRevenue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSubCard(
                          icon: CupertinoIcons.arrow_up_right_circle_fill,
                          imagePath:
                              'assets/images/features/expense_scanner.png',
                          iconColor: const Color(0xFFEF4444), // Error
                          title: 'T?ng Chi',
                          value: widget.totalExpense,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubCard({
    required IconData icon,
    String? imagePath,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (imagePath != null)
                Image.asset(
                  imagePath,
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  isAntiAlias: true,
                  errorBuilder: (_, __, ___) =>
                      Icon(icon, color: iconColor, size: 20),
                )
              else
                Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RevenueCardSkeleton extends StatelessWidget {
  const RevenueCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShimmerLoading(
      width: double.infinity,
      height: 250,
      borderRadius: 24,
    );
  }
}
