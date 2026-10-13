import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async' show unawaited;

class Premium3DTextField extends StatefulWidget {
  final TextEditingController controller;
  final String placeholder;
  final IconData icon;
  final TextInputType keyboardType;
  final int? maxLength;
  final void Function(String)? onChanged;
  final bool readOnly;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;

  const Premium3DTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.maxLength,
    this.onChanged,
    this.readOnly = false,
    this.inputFormatters,
    this.focusNode,
  });

  @override
  State<Premium3DTextField> createState() => _Premium3DTextFieldState();
}

class _Premium3DTextFieldState extends State<Premium3DTextField> {
  late FocusNode _internalFocus;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _internalFocus = widget.focusNode ?? FocusNode();
    _internalFocus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _internalFocus.dispose();
    } else {
      _internalFocus.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _internalFocus.hasFocus;
    });
    if (_isFocused) {
      unawaited(HapticFeedback.lightImpact());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: widget.readOnly ? const Color(0xFFF3F4F6) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused ? const Color(0xFF298FFF) : Colors.transparent,
          width: _isFocused ? 1.5 : 0.0,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: const Color(0xFF298FFF).withValues(alpha: 0.15),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                widget.icon,
                key: ValueKey(_isFocused),
                color: _isFocused
                    ? const Color(0xFF298FFF)
                    : const Color(0xFF6B7280),
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _internalFocus,
              keyboardType: widget.keyboardType,
              maxLength: widget.maxLength,
              onChanged: widget.onChanged,
              readOnly: widget.readOnly,
              inputFormatters: widget.inputFormatters,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111827),
              ),
              decoration: InputDecoration(
                counterText: '',
                border: InputBorder.none,
                hintText: widget.placeholder,
                hintStyle: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                contentPadding: const EdgeInsets.only(
                  top: 16,
                  bottom: 16,
                  right: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
