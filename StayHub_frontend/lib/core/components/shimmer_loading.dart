import 'package:flutter/cupertino.dart';
import 'glass_container.dart';
import 'dart:async' show unawaited;

class ShimmerListLoading extends StatefulWidget {
  final int itemCount;

  const ShimmerListLoading({super.key, this.itemCount = 5});

  @override
  State<ShimmerListLoading> createState() => _ShimmerListLoadingState();
}

class _ShimmerListLoadingState extends State<ShimmerListLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController.unbounded(vsync: this);
    unawaited(
      _shimmerController.repeat(
        min: -0.5,
        max: 1.5,
        period: const Duration(milliseconds: 1500),
      ),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildLiquidSkeletonBox(
                  width: 50,
                  height: 50,
                  borderRadius: 12,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLiquidSkeletonBox(
                        width: double.infinity,
                        height: 16,
                        borderRadius: 8,
                      ),
                      const SizedBox(height: 8),
                      _buildLiquidSkeletonBox(
                        width: 150,
                        height: 14,
                        borderRadius: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLiquidSkeletonBox({
    required double width,
    required double height,
    required double borderRadius,
  }) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: const [
                Color(0x1AFFFFFF), // Low opacity white
                Color(0x66FFFFFF), // High opacity white (the sweep)
                Color(0x1AFFFFFF),
              ],
              stops: [
                _shimmerController.value - 0.3,
                _shimmerController.value,
                _shimmerController.value + 0.3,
              ],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
        );
      },
    );
  }
}
