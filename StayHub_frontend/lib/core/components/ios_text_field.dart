import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async' show unawaited;

class IOSTextField extends StatefulWidget {
  final TextEditingController controller;
  final String placeholder;
  final IconData icon;
  final TextInputType keyboardType;
  final FocusNode? focusNode;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final List<TextInputFormatter>? inputFormatters;

  const IOSTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.focusNode,
    this.maxLength,
    this.onChanged,
    this.readOnly = false,
    this.inputFormatters,
  });

  @override
  State<IOSTextField> createState() => _IOSTextFieldState();
}

class _IOSTextFieldState extends State<IOSTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      if (_isFocused) {
        unawaited(HapticFeedback.lightImpact());
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: widget.readOnly ? const Color(0xFFF9FAFB) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Icon(
              widget.icon,
              key: ValueKey(_isFocused),
              color: _isFocused
                  ? const Color(0xFF007AFF)
                  : const Color(0xFFAEAEB2),
              size: 19,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              keyboardType: widget.keyboardType,
              maxLength: widget.maxLength,
              onChanged: widget.onChanged,
              readOnly: widget.readOnly,
              inputFormatters: widget.inputFormatters,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Color(0xFF1C1C1E),
                letterSpacing: -0.3,
              ),
              decoration: InputDecoration(
                counterText: '',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                hintText: widget.placeholder,
                hintStyle: const TextStyle(
                  color: Color(0xFFC7C7CC),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
