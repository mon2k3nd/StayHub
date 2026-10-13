part of '../../create_branch_screen.dart';

// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api

/// đảm bảo giá trị được chọn luôn hiển thị đúng khi parent gọi setState().
class _AnimatedSelectField extends StatefulWidget {
  final String hint;
  final String? value;
  final IconData icon;
  final List<dynamic> items;
  final VoidCallback? onTap;

  const _AnimatedSelectField({
    required this.hint,
    required this.value,
    required this.icon,
    required this.items,
    required this.onTap,
  });

  @override
  State<_AnimatedSelectField> createState() => _AnimatedSelectFieldState();
}

class _AnimatedSelectFieldState extends State<_AnimatedSelectField> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.value != null;
    final locked = widget.onTap == null;
    return GestureDetector(
      onTapDown: locked ? null : (_) => setState(() => _pressed = true),
      onTapUp: locked
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            },
      onTapCancel: locked ? null : () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _pressed ? const Color(0xFFF2F2F7) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Icon(
              widget.icon,
              color: locked
                  ? const Color(0xFFC7C7CC)
                  : (hasValue
                        ? const Color(0xFF007AFF)
                        : const Color(0xFFAEAEB2)),
              size: 19,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                widget.value ?? widget.hint,
                style: TextStyle(
                  color: locked
                      ? const Color(0xFF8E8E93)
                      : (hasValue
                            ? const Color(0xFF1C1C1E)
                            : const Color(0xFFC7C7CC)),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.3,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (locked)
              const Icon(
                CupertinoIcons.lock_fill,
                color: Color(0xFFC7C7CC),
                size: 14,
              )
            else
              const Icon(
                CupertinoIcons.chevron_right,
                color: Color(0xFFC7C7CC),
                size: 15,
              ),
          ],
        ),
      ),
    );
  }
}

/// Tách thành widget riêng để AnimatedScale hoạt động không ảnh hưởng parent
class _AddressListItem extends StatefulWidget {
  final String display;
  final VoidCallback onTap;
  const _AddressListItem({required this.display, required this.onTap});
  @override
  State<_AddressListItem> createState() => _AddressListItemState();
}

class _AddressListItemState extends State<_AddressListItem> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _pressed ? const Color(0xFFF0F7FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _pressed
                ? const Color(0xFF0EA5E9).withValues(alpha: 0.3)
                : const Color(0xFFF3F4F6),
          ),
          boxShadow: _pressed
              ? []
              : [
                  const BoxShadow(
                    color: Color(0x05000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 130),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _pressed
                    ? const Color(0xFF0EA5E9).withValues(alpha: 0.12)
                    : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                CupertinoIcons.location_fill,
                size: 14,
                color: _pressed
                    ? const Color(0xFF0EA5E9)
                    : const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.display,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _pressed
                      ? const Color(0xFF0EA5E9)
                      : const Color(0xFF111827),
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: _pressed ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 130),
              child: const Icon(
                CupertinoIcons.checkmark_circle_fill,
                size: 18,
                color: Color(0xFF0EA5E9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinTailPainter extends CustomPainter {
  final Color color;
  const _PinTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTailPainter oldDelegate) => oldDelegate.color != color;
}
