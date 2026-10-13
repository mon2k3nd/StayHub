import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../../../../core/theme/app_theme.dart';
import 'dart:async' show unawaited;

class SmartOcrScannerSheet extends StatefulWidget {
  final Function(int, int) onScanComplete;

  const SmartOcrScannerSheet({super.key, required this.onScanComplete});

  @override
  State<SmartOcrScannerSheet> createState() => _SmartOcrScannerSheetState();
}

class _SmartOcrScannerSheetState extends State<SmartOcrScannerSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _laserController;
  bool _isScanning = false;
  String _statusText = 'Đưa camera hướng về đồng hồ điện/nước';

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    unawaited(_laserController.repeat(reverse: true));
  }

  @override
  void dispose() {
    _laserController.dispose();
    super.dispose();
  }

  Future<void> _startMockScan() async {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
      _statusText = 'Đang phân tích chỉ số AI...';
    });

    unawaited(HapticFeedback.mediumImpact());
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;
    unawaited(HapticFeedback.lightImpact());
    setState(() {
      _statusText = 'Trích xuất dữ liệu thành công!';
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    unawaited(HapticFeedback.lightImpact());
    // Generate mock readings:
    final elec = 2500 + Random().nextInt(100);
    final water = 150 + Random().nextInt(20);

    widget.onScanComplete(elec, water);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: CupertinoColors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Hủy',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const Text(
                  'AI Scanner',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: null,
                  child: Icon(CupertinoIcons.bolt_fill, color: Colors.white),
                ),
              ],
            ),
          ),

          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Fake camera view
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 250,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF1E293B,
                      ), // dark background instead of real camera
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.kBrand.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Viewfinder corners
                        const Positioned(
                          top: 0,
                          left: 0,
                          child: _Corner(angle: 0),
                        ),
                        const Positioned(
                          top: 0,
                          right: 0,
                          child: _Corner(angle: pi / 2),
                        ),
                        const Positioned(
                          bottom: 0,
                          right: 0,
                          child: _Corner(angle: pi),
                        ),
                        const Positioned(
                          bottom: 0,
                          left: 0,
                          child: _Corner(angle: -pi / 2),
                        ),

                        // Fake meter text
                        Center(
                          child: Text(
                            '00025${Random().nextInt(9)}',
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 48,
                              letterSpacing: 8,
                              color: Colors.white.withValues(alpha: 0.2),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        // Laser
                        AnimatedBuilder(
                          animation: _laserController,
                          builder: (context, child) {
                            return Positioned(
                              top: _laserController.value * 230,
                              left: 0,
                              right: 0,
                              child: child!,
                            );
                          },
                          child: Container(
                            height: 2,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppTheme.kBrand,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.kBrand.withValues(alpha: 0.8),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Status & Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Text(
                    _statusText,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: AppTheme.kBrand,
                      borderRadius: BorderRadius.circular(100),
                      onPressed: _isScanning ? null : () => _startMockScan(),
                      child: _isScanning
                          ? const CupertinoActivityIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'Bắt đầu Quét',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
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
}

class _Corner extends StatelessWidget {
  final double angle;
  const _Corner({required this.angle});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 30,
        height: 30,
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.kBrand, width: 4),
            left: BorderSide(color: AppTheme.kBrand, width: 4),
          ),
        ),
      ),
    );
  }
}
