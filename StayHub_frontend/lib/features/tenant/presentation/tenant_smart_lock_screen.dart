import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../application/smart_lock_notifier.dart';
import 'dart:async' show unawaited;

class TenantSmartLockScreen extends ConsumerStatefulWidget {
  const TenantSmartLockScreen({super.key});

  @override
  ConsumerState<TenantSmartLockScreen> createState() =>
      _TenantSmartLockScreenState();
}

class _TenantSmartLockScreenState extends ConsumerState<TenantSmartLockScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    unawaited(_pulseController.repeat(reverse: true));
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(smartLockProvider);
    final statusColor = lockState.isLocked
        ? AppTheme.kError
        : AppTheme.kSuccess;
    final statusGradient = lockState.isLocked
        ? const LinearGradient(
            colors: [Color(0xFFFEE2E2), Color(0xFFFFEDD5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFD1FAE5), Color(0xFFECFDF5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    ref.listen<SmartLockState>(smartLockProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Lỗi Kết Nối'),
              content: Text(next.error!),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      }
    });

    return LiquidGlassScaffold(
      title: 'Smart Lock',
      backgroundColors: AppTheme.kBackgroundLight,
      useScrollView: false,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            // Status badge
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: statusGradient,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      lockState.isLocked
                          ? CupertinoIcons.lock_fill
                          : CupertinoIcons.lock_open_fill,
                      color: statusColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      lockState.isLocked ? 'Đang khoá' : 'Đang mở',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Lock button
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: lockState.isProcessing
                      ? null
                      : () => ref.read(smartLockProvider.notifier).toggleLock(),
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: lockState.isProcessing
                            ? 1.0
                            : _scaleAnimation.value,
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: CupertinoColors.white,
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.25),
                                blurRadius: 60,
                                spreadRadius: lockState.isProcessing ? 0 : 16,
                              ),
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.1),
                                blurRadius: 20,
                                spreadRadius: 4,
                              ),
                            ],
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.5),
                              width: 6,
                            ),
                          ),
                          child: lockState.isProcessing
                              ? const Center(
                                  child: CupertinoActivityIndicator(radius: 28),
                                )
                              : Center(
                                  child: Icon(
                                    lockState.isLocked
                                        ? CupertinoIcons.lock_fill
                                        : CupertinoIcons.lock_open_fill,
                                    size: 72,
                                    color: statusColor,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Text(
                'Chạm vào ổ khóa để Mở/Đóng cửa',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 15),
              ),
            ),

            // Battery status card
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: GlassContainer(
                borderRadius: 20,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        CupertinoIcons.battery_25,
                        color: AppTheme.kWarning,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Pin khóa cửa',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '24%',
                        style: TextStyle(
                          color: AppTheme.kWarning,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
