import 'package:flutter/cupertino.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/glass_button.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/theme/app_theme.dart';
import 'dart:async' show unawaited;

class GlobalBroadcastScreen extends StatefulWidget {
  const GlobalBroadcastScreen({super.key});

  @override
  State<GlobalBroadcastScreen> createState() => _GlobalBroadcastScreenState();
}

class _GlobalBroadcastScreenState extends State<GlobalBroadcastScreen> {
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  bool _isSending = false;

  void _sendBroadcast() {
    if (_titleCtrl.text.isEmpty || _msgCtrl.text.isEmpty) return;

    setState(() => _isSending = true);

    // Simulate sending FCM to all users
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _isSending = false);

      unawaited(
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Thành công'),
            content: const Text(
              'Đã bắn Push Notification đến toàn bộ thiết bị đang cài đặt ứng dụng!',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Đóng'),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.kBackgroundLightGray,
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Phát Thanh Toàn Nền Tảng',
          style: TextStyle(color: CupertinoColors.black),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: CupertinoColors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                CupertinoIcons.speaker_3_fill,
                size: 80,
                color: CupertinoColors.activeOrange,
              ),
              const SizedBox(height: 24),
              const Text(
                'Lưu ý: Tin nhắn này sẽ được gửi dưới dạng Push Notification (FCM) đến tất cả Chủ trọ, Quản lý và Khách thuê trên hệ thống.',
                style: TextStyle(
                  color: CupertinoColors.systemRed,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tiêu đề thông báo',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      controller: _titleCtrl,
                      placeholder: 'VD: Bảo trì hệ thống đêm nay',
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Nội dung',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      controller: _msgCtrl,
                      placeholder: 'Nhập nội dung chi tiết...',
                      maxLines: 5,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _isSending
                  ? const Center(child: CupertinoActivityIndicator(radius: 16))
                  : GlassButton(
                      text: 'Bắn Thông Báo Khẩn',
                      icon: CupertinoIcons.paperplane_fill,
                      color: CupertinoColors.activeOrange,
                      onPressed: _sendBroadcast,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
