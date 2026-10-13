import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/providers/core_providers.dart';
import 'dart:async' show unawaited;

class AdminNotificationScreen extends ConsumerStatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  ConsumerState<AdminNotificationScreen> createState() =>
      _AdminNotificationScreenState();
}

class _AdminNotificationScreenState
    extends ConsumerState<AdminNotificationScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String _selectedScope = 'GLOBAL';
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty || _contentCtrl.text.trim().isEmpty) {
      unawaited(
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Lỗi'),
            content: const Text('Vui lòng nhập đầy đủ Tiêu đề và Nội dung'),
            actions: [
              CupertinoDialogAction(
                child: const Text('Đóng'),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final client = ref.read(apiClientProvider);
    try {
      await client.post(
        '/v1/admin/notifications/broadcast',
        data: {
          'scope': _selectedScope,
          'title': _titleCtrl.text.trim(),
          'content': _contentCtrl.text.trim(),
        },
      );

      if (!mounted) return;
      unawaited(
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Thành công'),
            content: const Text('Đã gửi thông báo hệ thống'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      unawaited(
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Lỗi'),
            content: Text('Không thể gửi thông báo: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('Đóng'),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      title: 'Tạo Thông Báo',
      backgroundColors: AppTheme.kBackgroundLight,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Phạm vi (Scope)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  CupertinoSlidingSegmentedControl<String>(
                    groupValue: _selectedScope,
                    children: const {
                      'GLOBAL': Text('Toàn bộ User'),
                      'OWNERS': Text('Chủ nhà'),
                      'TENANTS': Text('Người thuê'),
                    },
                    onValueChanged: (val) {
                      if (val != null) setState(() => _selectedScope = val);
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tiêu đề',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _titleCtrl,
                    placeholder: 'Nhập tiêu đề...',
                    padding: const EdgeInsets.all(12),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Nội dung',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _contentCtrl,
                    placeholder: 'Nhập nội dung...',
                    padding: const EdgeInsets.all(12),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            )
                          : const Text(
                              'Gửi Thông Báo',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
