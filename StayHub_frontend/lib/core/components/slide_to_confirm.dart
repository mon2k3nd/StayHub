import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';

class SlideToConfirm extends StatefulWidget {
  final Future<void> Function() onConfirm;
  final String text;
  final Color activeColor;

  const SlideToConfirm({
    super.key,
    required this.onConfirm,
    this.text = 'Vuốt để xác nhận',
    this.activeColor = AppTheme.kAccentColor,
  });

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0;
  bool _isConfirmed = false;
  bool _isLoading = false;
  final double _buttonSize = 56;
  final GlobalKey _containerKey = GlobalKey();
  double _containerWidth = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box =
          _containerKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        setState(() => _containerWidth = box.size.width);
      }
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isConfirmed || _isLoading || _containerWidth == 0) return;

    setState(() {
      _dragPosition += details.delta.dx;
      if (_dragPosition < 0) _dragPosition = 0;
      if (_dragPosition > _containerWidth - _buttonSize - 8) {
        _dragPosition = _containerWidth - _buttonSize - 8;
      }
    });
  }

  Future<void> _onPanEnd(DragEndDetails details) async {
    if (_isConfirmed || _isLoading || _containerWidth == 0) return;

    if (_dragPosition > (_containerWidth - _buttonSize) * 0.75) {
      setState(() {
        _dragPosition = _containerWidth - _buttonSize - 8;
        _isLoading = true;
      });

      try {
        await widget.onConfirm();
        if (mounted) {
          setState(() {
            _isConfirmed = true;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _dragPosition = 0;
            _isLoading = false;
          });
        }
      }
    } else {
      setState(() {
        _dragPosition = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _containerKey,
      height: 64,
      decoration: BoxDecoration(
        color: widget.activeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          Center(
            child: Opacity(
              opacity: _isConfirmed || _isLoading
                  ? 0
                  : 1 -
                        (_dragPosition /
                            (_containerWidth == 0 ? 1 : _containerWidth)),
              child: Text(
                widget.text,
                style: TextStyle(
                  color: widget.activeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          Positioned(
            left: 4,
            child: AnimatedContainer(
              duration: _dragPosition == 0
                  ? const Duration(milliseconds: 300)
                  : Duration.zero,
              curve: Curves.easeOut,
              width: _dragPosition == 0
                  ? _buttonSize
                  : _dragPosition + _buttonSize,
              height: _buttonSize,
              decoration: BoxDecoration(
                color: widget.activeColor.withValues(
                  alpha: _dragPosition == 0 ? 0 : 0.2,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: _dragPosition == 0
                ? const Duration(milliseconds: 300)
                : Duration.zero,
            curve: Curves.easeOut,
            left: 4 + _dragPosition,
            child: GestureDetector(
              onPanUpdate: _onPanUpdate,
              onPanEnd: (details) => _onPanEnd(details),
              child: Container(
                width: _buttonSize,
                height: _buttonSize,
                decoration: BoxDecoration(
                  color: widget.activeColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.activeColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _isLoading
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : _isConfirmed
                      ? const Icon(
                          CupertinoIcons.checkmark_alt,
                          color: Colors.white,
                          size: 28,
                        )
                      : const Icon(
                          CupertinoIcons.chevron_right_2,
                          color: Colors.white,
                          size: 28,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
