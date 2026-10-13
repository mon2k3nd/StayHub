import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class GlassDropdownOverlay extends StatelessWidget {
  final Offset position;
  final Size size;
  final VoidCallback onDismiss;
  final Widget child;
  final double width;
  final double maxHeight;

  const GlassDropdownOverlay({
    super.key,
    required this.position,
    required this.size,
    required this.onDismiss,
    required this.child,
    this.width = 320,
    this.maxHeight = 400,
  });

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    final media = MediaQuery.of(context);
    // Trừ vùng an toàn (tai thỏ / thanh điều hướng) để overlay không bị che.
    final safeTop = media.padding.top + 8;
    final safeBottom = media.padding.bottom + 8;

    double left = position.dx;
    if (left + width > screenW - 16) {
      left = screenW - width - 16;
    }
    if (left < 16) left = 16;

    // BUGFIX (UI/layout): trước đây luôn đặt dropdown BÊN DƯỚI anchor và
    // height = screenH - top - 16. Khi anchor nằm gần đáy màn hình, height
    // trở thành ÂM hoặc 0 → Flutter ném lỗi layout
    // ("BoxConstraints has a negative minimum height") và dropdown biến mất.
    // Nay: chọn phía nào có nhiều chỗ hơn (dưới/trên) và luôn clamp height > 0.
    final spaceBelow = screenH - safeBottom - (position.dy + size.height + 8);
    final spaceAbove = (position.dy - 8) - safeTop;
    final bool openBelow = spaceBelow >= spaceAbove;

    final double available = (openBelow ? spaceBelow : spaceAbove).clamp(
      0.0,
      screenH,
    );
    final double height = maxHeight < available ? maxHeight : available;

    final double top = openBelow
        ? position.dy + size.height + 8
        : position.dy - 8 - height;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),
        Positioned(
          top: top,
          left: left,
          width: width,
          height: height,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            builder: (context, value, childWidget) {
              return Transform.scale(
                scale: 0.95 + (0.05 * value),
                alignment: Alignment.topCenter,
                child: Opacity(opacity: value, child: childWidget),
              );
            },
            child: Material(
              color: Colors.transparent,
              child: GlassContainer(child: child),
            ),
          ),
        ),
      ],
    );
  }
}
