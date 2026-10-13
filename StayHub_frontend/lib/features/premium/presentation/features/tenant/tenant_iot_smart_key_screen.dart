import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../../../core/components/glass_container.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../tenant/application/smart_device_provider.dart';
import 'dart:async' show unawaited;

class TenantIotSmartKeyScreen extends ConsumerStatefulWidget {
  final int roomId; // Added roomId
  const TenantIotSmartKeyScreen({
    super.key,
    this.roomId = 1,
  }); // Default for mock

  @override
  ConsumerState<TenantIotSmartKeyScreen> createState() =>
      _TenantIotSmartKeyScreenState();
}

class _TenantIotSmartKeyScreenState
    extends ConsumerState<TenantIotSmartKeyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleLock(int deviceId, String currentStatus) async {
    if (_isAnimating) return;

    unawaited(HapticFeedback.mediumImpact());
    setState(() => _isAnimating = true);

    unawaited(_pulseController.forward(from: 0));

    final newStatus = currentStatus == 'LOCKED' ? 'UNLOCKED' : 'LOCKED';
    await ref
        .read(smartDeviceProvider(widget.roomId).notifier)
        .toggleDevice(deviceId, newStatus);

    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() => _isAnimating = false);
      if (newStatus == 'UNLOCKED') {
        unawaited(HapticFeedback.lightImpact());
      } else {
        unawaited(HapticFeedback.lightImpact());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(smartDeviceProvider(widget.roomId));

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Khóa thông minh', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        border: null,
        previousPageTitle: 'Trở về',
      ),
      backgroundColor: const Color(0xFF0F172A),
      child: SafeArea(
        child: devicesAsync.when(
          loading: () => const Center(
            child: CupertinoActivityIndicator(color: Colors.white),
          ),
          error: (err, stack) => Center(
            child: Text(
              'Lỗi kết nối: $err',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          data: (devices) {
            final locks = devices
                .where((d) => d.deviceType == 'SMART_LOCK')
                .toList();
            if (locks.isEmpty) {
              return _buildEmptyState();
            }

            final lock = locks.first;
            final isLocked = lock.status == 'LOCKED';

            return Column(
              children: [
                const SizedBox(height: 24),
                // Lock Status Header
                Text(
                  isLocked ? 'Cửa Đang Khóa' : 'Cửa Đã Mở',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isLocked
                        ? AppTheme.kTextSecondary
                        : AppTheme.kSuccess,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  lock.name,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),

                const Spacer(),

                // Big Interactive Button
                GestureDetector(
                  onTap: () => _toggleLock(lock.id!, lock.status),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulse effect
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 250 + (_pulseController.value * 50),
                            height: 250 + (_pulseController.value * 50),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  (isLocked
                                          ? AppTheme.kSuccess
                                          : AppTheme.kBrand)
                                      .withValues(
                                        alpha:
                                            (1 - _pulseController.value) * 0.3,
                                      ),
                            ),
                          );
                        },
                      ),

                      // Main Button
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isLocked
                                ? [
                                    const Color(0xFF334155),
                                    const Color(0xFF1E293B),
                                  ]
                                : [
                                    AppTheme.kSuccess,
                                    const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.8),
                                  ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isLocked ? Colors.black : AppTheme.kSuccess)
                                      .withValues(alpha: 0.5),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                          border: Border.all(
                            color: isLocked
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            isLocked
                                ? CupertinoIcons.lock_fill
                                : CupertinoIcons.lock_open_fill,
                            size: 80,
                            color: isLocked ? Colors.white54 : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Bottom Actions
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: 24,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionItem(
                          icon: CupertinoIcons.qrcode,
                          label: 'Mã khách',
                          onTap: () {
                            // Show temporary password generator
                          },
                        ),
                        Container(width: 1, height: 40, color: Colors.white24),
                        _buildActionItem(
                          icon: CupertinoIcons.time,
                          label: 'Lịch sử',
                          onTap: () {},
                        ),
                        Container(width: 1, height: 40, color: Colors.white24),
                        _buildActionItem(
                          icon: CupertinoIcons.battery_25,
                          label: '64%',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 60,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'Chưa kết nối thiết bị',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vui lòng liên hệ chủ nhà để cài đặt khóa thông minh cho phòng của bạn.',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
