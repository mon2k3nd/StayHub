import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'glass_container.dart';
import '../error/app_exception.dart';
import '../providers/theme_provider.dart';

class AppErrorWidget extends ConsumerWidget {
  final Object error;
  final VoidCallback? onRetry;
  final String? title;
  final bool compact;

  const AppErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.title,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider);
    final appException = AppExceptionMapper.fromGeneric(error);
    final errorMessage = appException.message;

    if (compact) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              color: CupertinoColors.systemRed.withValues(alpha: 0.8),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
                fontSize: 12,
              ),
            ),
            if (onRetry != null)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onRetry,
                child: const Text('Thử lại', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GlassContainer(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.exclamationmark_circle_fill,
                  color: CupertinoColors.systemRed,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title ?? 'Đã xảy ra lỗi!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? CupertinoColors.white.withValues(alpha: 0.7)
                      : CupertinoColors.black.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: onRetry,
                    borderRadius: BorderRadius.circular(12),
                    child: const Text(
                      'Thử Lại',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
