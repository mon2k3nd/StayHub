import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import '../components/liquid_glass_scaffold.dart';
import '../components/glass_container.dart';
import '../theme/liquid_glass_colors.dart';
import 'package:stayhub_frontend/core/components/stayhub_logo_icon.dart';

class NotFoundScreen extends StatelessWidget {
  final String? error;

  const NotFoundScreen({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      title: 'Không tìm thấy',
      useScrollView: false,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.exclamationmark_triangle_fill,
                  color: CupertinoColors.systemRed,
                  size: 60,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Oops! 404',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.black,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tính năng này đang được cập nhật hoặc đường dẫn không tồn tại. Vui lòng quay lại trang chủ!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 24),
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  color: CupertinoColors.systemRed.withValues(alpha: 0.05),
                  child: Text(
                    error!,
                    style: const TextStyle(
                      color: CupertinoColors.systemRed,
                      fontSize: 12,
                      fontFamily: 'Courier',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 48),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                color: LiquidGlassColors.ownerAccent,
                borderRadius: BorderRadius.circular(24),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StayHubLogoIcon(color: CupertinoColors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Về Trang Chủ',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
