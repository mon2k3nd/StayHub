import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material;
import '../../../core/theme/app_theme.dart';
import '../../../core/components/glass_button.dart';
import 'dart:async' show unawaited;

class ReviewModal extends StatefulWidget {
  final String title;
  final String targetName;
  final Future<void> Function(int rating, String feedback) onSubmit;

  const ReviewModal({
    super.key,
    required this.title,
    required this.targetName,
    required this.onSubmit,
  });

  static void show(
    BuildContext context, {
    required String title,
    required String targetName,
    required Future<void> Function(int rating, String feedback) onSubmit,
  }) {
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (context) => ReviewModal(
          title: title,
          targetName: targetName,
          onSubmit: onSubmit,
        ),
      ),
    );
  }

  @override
  State<ReviewModal> createState() => _ReviewModalState();
}

class _ReviewModalState extends State<ReviewModal> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_rating == 0) return;

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmit(_rating, _feedbackController.text);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        // Show error...
      }
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CupertinoColors.transparent,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: const BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          top: 24,
          left: 20,
          right: 20,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey4,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bạn đánh giá thế nào về ${widget.targetName}?',
                style: const TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(height: 32),

              // Stars
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() => _rating = index + 1);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: AnimatedScale(
                        scale: _rating > index ? 1.2 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.elasticOut,
                        child: Icon(
                          _rating > index
                              ? CupertinoIcons.star_fill
                              : CupertinoIcons.star,
                          color: _rating > index
                              ? CupertinoColors.systemYellow
                              : CupertinoColors.systemGrey4,
                          size: 40,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              // Feedback input
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CupertinoTextField(
                  controller: _feedbackController,
                  placeholder:
                      'Chia sẻ trải nghiệm của bạn (không bắt buộc)...',
                  maxLines: 4,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: null,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: GlassButton(
                  onPressed: _rating > 0 && !_isSubmitting
                      ? () => _submit()
                      : null,
                  text: 'Gửi Đánh Giá',
                  isLoading: _isSubmitting,
                  color: AppTheme.kAccentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
