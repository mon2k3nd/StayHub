import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Material;
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../auth/application/auth_notifier.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/core_providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/payment_remote_data_source.dart';

enum PaymentState { initial, scanningFaceId, processing, success }

class TenantPaymentScreen extends StatefulWidget {
  const TenantPaymentScreen({super.key});

  @override
  State<TenantPaymentScreen> createState() => _TenantPaymentScreenState();
}

class _TenantPaymentScreenState extends State<TenantPaymentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPaid = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    unawaited(_pulseController.repeat(reverse: true));
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startPaymentFlow() {
    unawaited(
      showCupertinoModalPopup(
        context: context,
        barrierDismissible: false,
        builder: (context) => const _PaymentBottomSheet(),
      ).then((success) {
        if (success == true && mounted) {
          setState(() => _isPaid = true);
          unawaited(HapticFeedback.heavyImpact());
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      title: 'Thanh Toán Hóa Đơn',
      backgroundColors: AppTheme.kBackgroundLight,
      useScrollView: true,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'HÓA ĐƠN KỲ: THÁNG 06/2026',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppTheme.kTextSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                // Hóa Đơn Lấp Lánh
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: _isPaid
                        ? PremiumGradients.emeraldGreen
                        : const LinearGradient(
                            colors: [Color(0xFFFFEDD5), Color(0xFFFEE2E2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: _isPaid
                            ? AppTheme.kSuccess.withValues(alpha: 0.3)
                            : CupertinoColors.systemRed.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(2), // Viền gradient mỏng
                  child: Container(
                    decoration: BoxDecoration(
                      color: CupertinoTheme.of(
                        context,
                      ).scaffoldBackgroundColor.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tổng số tiền',
                              style: TextStyle(
                                color: AppTheme.kTextSecondary,
                                fontSize: 14,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _isPaid
                                    ? CupertinoColors.systemGreen.withValues(
                                        alpha: 0.1,
                                      )
                                    : CupertinoColors.destructiveRed.withValues(
                                        alpha: 0.1,
                                      ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _isPaid ? 'ĐÃ THANH TOÁN' : 'CHƯA THANH TOÁN',
                                style: TextStyle(
                                  color: _isPaid
                                      ? CupertinoColors.systemGreen
                                      : CupertinoColors.destructiveRed,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              '4,500,000',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                color: _isPaid
                                    ? AppTheme.kSuccess
                                    : CupertinoColors.black,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'VNĐ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.kTextSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Dấu gạch đứt đoạn (Dashed line)
                        Row(
                          children: List.generate(
                            30,
                            (index) => Expanded(
                              child: Container(
                                color: index.isEven
                                    ? AppTheme.kTextMuted
                                    : Colors.transparent,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildLineItem(
                          'Tiền thuê phòng (P.302)',
                          '3,500,000 đ',
                          CupertinoIcons.house_fill,
                          AppTheme.kBrand,
                          imagePath: 'assets/images/features/feat_room.png',
                        ),
                        const SizedBox(height: 16),
                        _buildLineItem(
                          'Tiền điện (100 kWh)',
                          '350,000 đ',
                          CupertinoIcons.bolt_fill,
                          AppTheme.kWarning,
                          imagePath: 'assets/images/features/ocr_meter.png',
                        ),
                        const SizedBox(height: 16),
                        _buildLineItem(
                          'Tiền nước (5 khối)',
                          '150,000 đ',
                          CupertinoIcons.drop_fill,
                          AppTheme.kBrand,
                          imagePath:
                              'assets/images/features/utilities_dashboard.png',
                        ),
                        const SizedBox(height: 16),
                        _buildLineItem(
                          'Phí dịch vụ & Quản lý',
                          '500,000 đ',
                          CupertinoIcons.shield_fill,
                          AppTheme.kBrand,
                          imagePath:
                              'assets/images/features/local_services.png',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                if (!_isPaid)
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: PremiumGradients.oceanBlue,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.kBrandDeep.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        onPressed: _startPaymentFlow,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.barcode_viewfinder,
                              color: CupertinoColors.white,
                              size: 24,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Thanh Toán 1-Chạm',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                if (_isPaid)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.kSurfaceBlue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.cloud_download,
                            color: CupertinoColors.systemBlue,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Tải biên lai PDF',
                            style: TextStyle(
                              color: CupertinoColors.systemBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineItem(
    String title,
    String amount,
    IconData icon,
    Color color, {
    String? imagePath,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(imagePath == null ? 8 : 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: imagePath == null
              ? Icon(icon, color: color, size: 16)
              : Image.asset(
                  imagePath,
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  isAntiAlias: true,
                  errorBuilder: (_, __, ___) =>
                      Icon(icon, color: color, size: 16),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 14, color: CupertinoColors.black),
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.black,
          ),
        ),
      ],
    );
  }
}

class _PaymentBottomSheet extends ConsumerStatefulWidget {
  const _PaymentBottomSheet();

  @override
  ConsumerState<_PaymentBottomSheet> createState() =>
      _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends ConsumerState<_PaymentBottomSheet>
    with SingleTickerProviderStateMixin {
  PaymentState _state = PaymentState.initial;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    unawaited(_glowController.repeat(reverse: true));
    _glowAnimation = Tween<double>(begin: 0.0, end: 15.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    unawaited(_processPayment());
  }

  Future<void> _processPayment() async {
    // 1. Scanning FaceID Phase
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _state = PaymentState.scanningFaceId);
    unawaited(HapticFeedback.lightImpact());

    // 2. API Call Phase
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _state = PaymentState.processing);

    try {
      final apiClient = ref.read(apiClientProvider);
      final ds = PaymentRemoteDataSource(apiClient.dio);
      final user = ref.read(authProvider).value;
      if (user == null) throw Exception('User not found');

      final billId = await ds.getLatestPendingBillId(user.id) ?? 1;

      // Simulate real API Payment
      await ds.simulateOnlinePayment(billId);

      if (!mounted) return;
      setState(() => _state = PaymentState.success);
      unawaited(HapticFeedback.heavyImpact());

      // Đóng popup sau 1.5s báo thành công
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _state = PaymentState.initial);
        // Error handling could be here
        Navigator.pop(context, false);
      }
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: _buildStateIcon(),
            ),
            const SizedBox(height: 32),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _getStateText(),
                key: ValueKey(_state),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: CupertinoColors.black,
                ),
              ),
            ),
            if (_state != PaymentState.success) ...[
              const SizedBox(height: 24),
              const Text(
                'Apple Pay',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.kTextSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStateIcon() {
    switch (_state) {
      case PaymentState.initial:
        return const Icon(
          CupertinoIcons.viewfinder,
          size: 80,
          color: AppTheme.kTextSecondary,
        );
      case PaymentState.scanningFaceId:
        return AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.kBrand.withValues(alpha: 0.5),
                    blurRadius: _glowAnimation.value,
                    spreadRadius: _glowAnimation.value / 2,
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.person_crop_square_fill,
                size: 80,
                color: AppTheme.kBrand,
              ),
            );
          },
        );
      case PaymentState.processing:
        return const SizedBox(
          width: 80,
          height: 80,
          child: CupertinoActivityIndicator(radius: 20),
        );
      case PaymentState.success:
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.kSuccess.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            CupertinoIcons.checkmark_alt,
            size: 80,
            color: AppTheme.kSuccess,
          ),
        );
    }
  }

  String _getStateText() {
    switch (_state) {
      case PaymentState.initial:
        return 'Xác thực thanh toán...';
      case PaymentState.scanningFaceId:
        return 'Đang nhận diện Face ID';
      case PaymentState.processing:
        return 'Đang xử lý giao dịch...';
      case PaymentState.success:
        return 'Thanh toán thành công! 🎉';
    }
  }
}
