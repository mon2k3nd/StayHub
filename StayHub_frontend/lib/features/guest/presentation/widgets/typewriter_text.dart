import 'dart:async';

import 'package:flutter/material.dart';

/// Hiệu ứng "gõ chữ dần dần" (typewriter).
///
/// Khi [text] thay đổi, widget sẽ xoá chữ cũ và gõ lại từng ký tự một
/// thay vì hiện ra ngay lập tức — tạo cảm giác mượt mà, sống động.
///
/// Kèm theo một con trỏ nhấp nháy nhẹ ở cuối dòng trong lúc đang gõ.
class TypewriterText extends StatefulWidget {
  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.charDuration = const Duration(milliseconds: 38),
    this.startDelay = const Duration(milliseconds: 120),
    this.maxLines = 2,
  });

  /// Nội dung đầy đủ cần gõ ra.
  final String text;

  /// Style áp dụng cho văn bản.
  final TextStyle? style;

  /// Thời gian giữa mỗi ký tự.
  final Duration charDuration;

  /// Độ trễ trước khi bắt đầu gõ (giúp chuyển cảnh êm hơn).
  final Duration startDelay;

  /// Số dòng tối đa — giữ chiều cao ổn định, tránh layout nhảy.
  final int maxLines;

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  Timer? _timer;
  String _visible = '';
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(covariant TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _startTyping();
    }
  }

  void _startTyping() {
    _timer?.cancel();
    _index = 0;
    _visible = '';

    // Độ trễ nhỏ trước khi gõ để mắt kịp nhận ra sự thay đổi.
    _timer = Timer(widget.startDelay, () {
      if (!mounted) return;
      _timer = Timer.periodic(widget.charDuration, (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (_index >= widget.text.length) {
          timer.cancel();
          return;
        }
        setState(() {
          _index++;
          _visible = widget.text.substring(0, _index);
        });
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typing = _index < widget.text.length;
    return Text(
      typing ? '$_visible|' : _visible,
      maxLines: widget.maxLines,
      overflow: TextOverflow.ellipsis,
      style: widget.style,
    );
  }
}
