import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/network/api_client.dart';
import 'dart:async';

class StaffAttendanceScreen extends ConsumerStatefulWidget {
  const StaffAttendanceScreen({super.key});

  @override
  ConsumerState<StaffAttendanceScreen> createState() =>
      _StaffAttendanceScreenState();
}

class _StaffAttendanceScreenState extends ConsumerState<StaffAttendanceScreen>
    with SingleTickerProviderStateMixin {
  bool _isCheckingIn = false;
  late ApiClient _apiClient;
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    unawaited(_scanController.repeat(reverse: true));
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckIn() async {
    setState(() => _isCheckingIn = true);

    // Simulate Face ID / eKYC Scanning delay
    await Future.delayed(const Duration(seconds: 2));

    try {
      final response = await _apiClient.dio.post(
        '/v1/attendance/check-in',
        data: {
          'latitude': 21.028511, // Mock Hanoi GPS
          'longitude': 105.804817,
          'location': 'Khu trọ Cầu Giấy',
          'photoBase64': 'base64_mock_string',
          'branchId': 1,
        },
      );
      if (response.statusCode == 200) {
        if (mounted) {
          ToastUtils.show(context, 'Check-in thành công!', isError: false);
        }
      }
    } catch (e) {
      if (mounted) ToastUtils.show(context, 'Lỗi Check-in: $e');
    } finally {
      setState(() => _isCheckingIn = false);
    }
  }

  Future<void> _handleCheckOut() async {
    setState(() => _isCheckingIn = true);
    await Future.delayed(const Duration(seconds: 1));
    try {
      final response = await _apiClient.dio.post(
        '/v1/attendance/check-out',
        data: {
          'latitude': 21.028511,
          'longitude': 105.804817,
          'location': 'Khu trọ Cầu Giấy',
          'photoBase64': 'base64_mock_string',
        },
      );
      if (response.statusCode == 200) {
        if (mounted) {
          ToastUtils.show(context, 'Check-out thành công!', isError: false);
        }
      }
    } catch (e) {
      if (mounted) ToastUtils.show(context, 'Lỗi Check-out: $e');
    } finally {
      setState(() => _isCheckingIn = false);
    }
  }

  Widget _buildCameraPreview() {
    return Container(
      height: 300,
      width: 300,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(150),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kBrand.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Mock Camera feed
          const Icon(
            CupertinoIcons.camera_fill,
            color: Colors.white24,
            size: 80,
          ),

          // Face scanning overlay
          if (_isCheckingIn)
            AnimatedBuilder(
              animation: _scanController,
              builder: (context, child) {
                return Positioned(
                  top: 30 + (_scanController.value * 240),
                  child: Container(
                    width: 200,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.kSuccess,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.kSuccess.withValues(alpha: 0.8),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // eKYC Frame
          CustomPaint(
            size: const Size(200, 200),
            painter: FaceFramePainter(
              color: _isCheckingIn ? AppTheme.kSuccess : AppTheme.kBrand,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundLight,
      appBar: AppBar(
        title: const Text('Chấm công (eKYC)'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Đưa khuôn mặt vào khung hình',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hệ thống sẽ đối chiếu với GPS của Khu trọ',
              style: TextStyle(color: AppTheme.kTextSecondary),
            ),
            const SizedBox(height: 40),
            _buildCameraPreview(),
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCheckingIn ? null : _handleCheckIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.kBrand,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child: _isCheckingIn
                          ? const CupertinoActivityIndicator(
                              color: Colors.white,
                            )
                          : const Text('Vào ca (Check-in)'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isCheckingIn ? null : _handleCheckOut,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                      ),
                      child: const Text('Tan ca (Check-out)'),
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

class FaceFramePainter extends CustomPainter {
  final Color color;
  FaceFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    const length = 30.0;

    // Top Left
    canvas.drawLine(const Offset(0, 0), const Offset(length, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, length), paint);

    // Top Right
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width - length, 0),
      paint,
    );
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, length), paint);

    // Bottom Left
    canvas.drawLine(Offset(0, size.height), Offset(length, size.height), paint);
    canvas.drawLine(
      Offset(0, size.height),
      Offset(0, size.height - length),
      paint,
    );

    // Bottom Right
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - length, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width, size.height - length),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
