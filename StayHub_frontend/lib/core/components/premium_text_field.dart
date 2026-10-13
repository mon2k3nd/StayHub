import 'package:flutter/cupertino.dart';
import '../theme/app_theme.dart';

class PremiumTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String placeholder;
  final String? label;
  final IconData? prefixIcon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final String? errorText;
  final Function(String)? onChanged;
  final int maxLines;
  final int? maxLength;
  final TextAlign textAlign;
  final bool readOnly;
  final VoidCallback? onTap;

  /// Optional override for the field's background fill. When null the field
  /// keeps its default (white in light mode / gray-800 in dark mode). Screens
  /// that place the field on an already-white surface (e.g. the auth glass
  /// card) can pass a soft tint so the input stays visually distinct.
  final Color? fillColor;

  const PremiumTextField({
    super.key,
    this.controller,
    required this.placeholder,
    this.label,
    this.prefixIcon,
    this.isPassword = false,
    this.keyboardType,
    this.suffix,
    this.errorText,
    this.onChanged,
    this.maxLines = 1,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.readOnly = false,
    this.onTap,
    this.fillColor,
  });

  @override
  State<PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<PremiumTextField> {
  bool _obscureText = false;
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isFocused = _focusNode.hasFocus;
        });
      }
    });
  }

  @override
  void didUpdateWidget(PremiumTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPassword != oldWidget.isPassword) {
      _obscureText = widget.isPassword;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = CupertinoTheme.of(context).brightness == Brightness.dark;
    final defaultBg =
        widget.fillColor ??
        (isDark
            ? const Color(0xFF1F2937)
            : CupertinoColors.white); // Gray 800 or White
    final defaultBorder = isDark
        ? AppTheme.kBorderColorDark
        : AppTheme.kBorderColor;
    const activeBorder = AppTheme.kAccentColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              color: isDark ? AppTheme.kTextPrimaryDark : AppTheme.kTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: defaultBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.errorText != null
                  ? CupertinoColors.systemRed
                  : (_isFocused
                        ? activeBorder
                        : defaultBorder.withValues(alpha: 0.8)),
              width: _isFocused || widget.errorText != null ? 1.5 : 1,
            ),
            boxShadow: [
              if (_isFocused)
                BoxShadow(
                  color: AppTheme.kAccentColor.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: CupertinoTextField(
            focusNode: _focusNode,
            controller: widget.controller,
            placeholder: widget.placeholder,
            obscureText: _obscureText,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            maxLines: widget.maxLines,
            maxLength: widget.maxLength,
            textAlign: widget.textAlign,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            placeholderStyle: TextStyle(
              color: isDark
                  ? AppTheme.kTextSecondaryDark
                  : const Color(0xFF4B5563),
              fontSize: 15,
            ),
            // Compact vertical padding keeps forms comfortable on narrow
            // phones while remaining a 44pt+ touch target.
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            style: TextStyle(
              color: isDark ? AppTheme.kTextPrimaryDark : CupertinoColors.black,
              fontSize: 16,
            ),
            decoration: null, // Override default decoration
            prefix: widget.prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Icon(
                      widget.prefixIcon,
                      color: _isFocused ? activeBorder : AppTheme.kAccentColor,
                      size: 20,
                    ),
                  )
                : null,
            suffix: widget.isPassword
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.suffix != null) widget.suffix!,
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },
                        minimumSize: const Size(40.0, 40.0),
                        child: Icon(
                          _obscureText
                              ? CupertinoIcons.eye_slash
                              : CupertinoIcons.eye,
                          color: const Color(0xFF4B5563),
                          size: 20,
                        ),
                      ),
                    ],
                  )
                : (widget.suffix != null
                      ? Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: widget.suffix,
                        )
                      : null),
          ),
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(
              widget.errorText!,
              style: const TextStyle(
                color: CupertinoColors.systemRed,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
