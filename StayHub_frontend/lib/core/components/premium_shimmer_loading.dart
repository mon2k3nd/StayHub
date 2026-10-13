import 'package:flutter/cupertino.dart';
import 'dart:async' show unawaited;

class PremiumShimmerLoading extends StatefulWidget {
  final int itemCount;
  final double itemHeight;
  final bool isGrid;

  const PremiumShimmerLoading({
    super.key,
    this.itemCount = 3,
    this.itemHeight = 120.0,
    this.isGrid = false,
  });

  @override
  State<PremiumShimmerLoading> createState() => _PremiumShimmerLoadingState();
}

class _PremiumShimmerLoadingState extends State<PremiumShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    unawaited(_controller.repeat());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isGrid) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: widget.itemCount,
        itemBuilder: (context, index) => _buildShimmerItem(),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.itemCount,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: _buildShimmerItem(),
      ),
    );
  }

  Widget _buildShimmerItem() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          height: widget.itemHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                CupertinoColors.systemGrey5.withValues(alpha: 0.5),
                CupertinoColors.systemGrey6.withValues(alpha: 0.5),
                CupertinoColors.systemGrey5.withValues(alpha: 0.5),
              ],
              stops: [0.0, _controller.value, 1.0],
            ),
          ),
        );
      },
    );
  }
}
