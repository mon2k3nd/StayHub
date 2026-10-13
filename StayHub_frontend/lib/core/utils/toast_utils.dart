import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async' show unawaited;

class ToastUtils {
  static void show(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final overlayEntry = OverlayEntry(
      builder: (context) => _AnimatedToast(message: message, isError: isError),
    );

    // Chèn overlay SAU frame hiện tại. Nếu show() được gọi ngay trước
    // Navigator.pop() (ví dụ khi lưu bước 1 của wizard), việc insert đồng bộ
    // sẽ đụng vào Navigator đang bị khoá → assertion _debugLocked.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!overlay.mounted) return;
      overlay.insert(overlayEntry);
      Future.delayed(const Duration(seconds: 3), () {
        if (overlayEntry.mounted) {
          overlayEntry.remove();
        }
      });
    });
  }

  static OverlayEntry? _loadingEntry;

  static void showLoading(BuildContext context) {
    if (_loadingEntry != null) return; // Already loading

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _loadingEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Semi-transparent background
          Container(color: CupertinoColors.black.withValues(alpha: 0.3)),
          // Loading indicator
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: CupertinoColors.systemBackground
                    .resolveFrom(context)
                    .withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const CupertinoActivityIndicator(radius: 16),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_loadingEntry!);
  }

  static void hideLoading() {
    if (_loadingEntry != null && _loadingEntry!.mounted) {
      _loadingEntry!.remove();
      _loadingEntry = null;
    }
  }
}

class _AnimatedToast extends StatefulWidget {
  final String message;
  final bool isError;

  const _AnimatedToast({required this.message, required this.isError});

  @override
  State<_AnimatedToast> createState() => _AnimatedToastState();
}

class _AnimatedToastState extends State<_AnimatedToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    unawaited(_controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 20,
      right: 20,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _offsetAnimation,
          child: FadeTransition(
            opacity: _opacityAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: widget.isError
                    ? CupertinoColors.systemRed.withValues(alpha: 0.95)
                    : const Color(
                        0xFF1C1C1E,
                      ).withValues(alpha: 0.95), // Dark pill style
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.isError
                        ? CupertinoIcons.exclamationmark_circle_fill
                        : CupertinoIcons.checkmark_alt_circle_fill,
                    color: CupertinoColors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
