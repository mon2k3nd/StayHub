import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/theme/app_theme.dart';

enum SmartKeyState { disconnected, scanning, unlocked }

class TenantSmartKeyScreen extends StatefulWidget {
  const TenantSmartKeyScreen({super.key});

  @override
  State<TenantSmartKeyScreen> createState() => _TenantSmartKeyScreenState();
}

class _TenantSmartKeyScreenState extends State<TenantSmartKeyScreen>
    with TickerProviderStateMixin {
  SmartKeyState _state = SmartKeyState.disconnected;
  late AnimationController _radarController;
  late AnimationController _tiltController;
  Timer? _timer;

  final List<String> _vehicles = ['29A - 123.45'];

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _tiltController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _radarController.dispose();
    _tiltController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleUnlock() async {
    if (_state != SmartKeyState.disconnected) return;

    if (mounted) {
      setState(() => _state = SmartKeyState.scanning);
      unawaited(_radarController.repeat());
      unawaited(HapticFeedback.lightImpact());
      unawaited(
        _tiltController.forward().then((_) => _tiltController.reverse()),
      );
    }

    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _state = SmartKeyState.unlocked);
        _radarController.stop();
        unawaited(HapticFeedback.heavyImpact());

        // Auto reset
        _timer = Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _state = SmartKeyState.disconnected);
          }
        });
      }
    });
  }

  void _showAddVehicleSheet() {
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (context) {
          return Container(
            height: 300,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đăng Ký Xe Mới',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: CupertinoColors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hệ thống camera AI sẽ tự động nhận diện biển số và mở barie cho bạn.',
                  style: TextStyle(
                    color: AppTheme.kTextSecondary.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                CupertinoTextField(
                  placeholder: 'Nhập biển số xe (VD: 29A-12345)',
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.kSurfaceBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: AppTheme.kBrand,
                    borderRadius: BorderRadius.circular(16),
                    onPressed: () {
                      setState(() => _vehicles.add('29M1 - 999.99'));
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Xác Nhận',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      title: 'Smart Access',
      useScrollView: true,
      backgroundColors: AppTheme.kBackgroundLight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            _buildSmartKeyCard(),
            const SizedBox(height: 40),
            _buildVehicleSection(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartKeyCard() {
    final isScanning = _state == SmartKeyState.scanning;
    final isUnlocked = _state == SmartKeyState.unlocked;

    Color glowColor = isUnlocked
        ? CupertinoColors.activeGreen
        : (isScanning
              ? AppTheme.kBrandLight
              : CupertinoColors.white.withValues(alpha: 0.2));

    return GestureDetector(
      onTap: _handleUnlock,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radar ripples
          if (isScanning || isUnlocked)
            AnimatedBuilder(
              animation: _radarController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: List.generate(3, (index) {
                    final value = isUnlocked
                        ? 1.0
                        : (_radarController.value + (index * 0.3)) % 1.0;
                    return Container(
                      width: 250 + (value * 150),
                      height: 350 + (value * 150),
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: glowColor.withValues(
                            alpha: isUnlocked ? 0.3 : (1.0 - value) * 0.5,
                          ),
                          width: 2,
                        ),
                      ),
                    );
                  }),
                );
              },
            ),

          // Digital Card
          AnimatedBuilder(
            animation: _tiltController,
            builder: (context, child) {
              final angle = _tiltController.value * pi / 12; // slight tilt
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(angle)
                  ..rotateY(angle),
                alignment: FractionalOffset.center,
                child: child,
              );
            },
            child: Container(
              width: double.infinity,
              height: 400,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E293B), AppTheme.kTextPrimary],
                ),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(alpha: isUnlocked ? 0.5 : 0.2),
                    blurRadius: 30,
                    spreadRadius: isScanning ? 10 : 0,
                  ),
                  const BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: glowColor.withValues(alpha: 0.8),
                  width: isUnlocked ? 3 : 1,
                ),
              ),
              child: Stack(
                children: [
                  // Holographic overlay
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          image: const DecorationImage(
                            image: NetworkImage(
                              'https://www.transparenttextures.com/patterns/cubes.png',
                            ),
                            repeat: ImageRepeat.repeat,
                          ),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  CupertinoIcons.building_2_fill,
                                  color: AppTheme.kBrandLight,
                                  size: 24,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'StayHub Residence',
                                  style: TextStyle(
                                    color: CupertinoColors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              CupertinoIcons.wifi,
                              color: isScanning
                                  ? AppTheme.kBrandLight
                                  : AppTheme.kTextSecondary,
                              size: 24,
                            ),
                          ],
                        ),
                        const Spacer(),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: CupertinoColors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              CupertinoIcons.qrcode,
                              size: 80,
                              color: CupertinoColors.black,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'CƯ DÂN',
                          style: TextStyle(
                            color: AppTheme.kBrandLight,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Nguyễn Văn A',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Phòng 302',
                              style: TextStyle(
                                color: AppTheme.kTextSecondary,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              isUnlocked
                                  ? 'ĐÃ MỞ KHÓA'
                                  : (isScanning
                                        ? 'ĐANG QUÉT...'
                                        : 'CHẠM ĐỂ MỞ'),
                              style: TextStyle(
                                color: glowColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Đăng ký xe & Nhận diện AI',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: CupertinoColors.black,
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _showAddVehicleSheet,
              child: const Icon(
                CupertinoIcons.add_circled_solid,
                color: AppTheme.kBrand,
                size: 28,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._vehicles.map((v) => _buildLicensePlate(v)),
      ],
    );
  }

  Widget _buildLicensePlate(String plate) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CupertinoColors.black, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                plate,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: CupertinoColors.black,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Xe máy cá nhân',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.checkmark_seal_fill,
                        color: CupertinoColors.activeGreen,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Đã tích hợp camera AI',
                        style: TextStyle(
                          color: CupertinoColors.activeGreen.withValues(
                            alpha: 0.8,
                          ),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
