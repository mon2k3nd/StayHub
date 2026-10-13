import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/glass_button.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/theme/app_theme.dart';

enum OcrScannerState { scanning, processing, success }

class OwnerOcrScannerScreen extends StatefulWidget {
  const OwnerOcrScannerScreen({super.key});

  @override
  State<OwnerOcrScannerScreen> createState() => _OwnerOcrScannerScreenState();
}

class _OwnerOcrScannerScreenState extends State<OwnerOcrScannerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanLineController;
  OcrScannerState _state = OcrScannerState.scanning;

  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;

  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );
  bool _isProcessing = false;

  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    unawaited(_scanLineController.repeat(reverse: true));

    unawaited(_initCamera());
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      final camera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      if (!mounted) return;

      setState(() {
        _isCameraInitialized = true;
      });

      unawaited(_controller!.startImageStream(_processCameraImage));
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || _state != OcrScannerState.scanning) return;
    _isProcessing = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      // Tìm chuỗi số (4-6 chữ số) thường là chỉ số đồng hồ
      final text = recognizedText.text;
      final regex = RegExp(r'\b\d{3,6}\b');
      final match = regex.firstMatch(text);

      if (match != null) {
        final result = match.group(0);
        if (result != null && mounted) {
          // unawaited(Ngừng stream khi nhận diện thành công)
          unawaited(_controller?.stopImageStream());
          setState(() {
            _state = OcrScannerState.success;
          });
          _showResultSheet(result);
        }
      }
    } catch (e) {
      debugPrint('ML Kit processing error: $e');
    } finally {
      if (mounted) _isProcessing = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;
    final camera = _cameras.firstWhere(
      (c) => c.lensDirection == _controller!.description.lensDirection,
      orElse: () => _cameras.first,
    );
    final rotation = InputImageRotationValue.fromRawValue(
      camera.sensorOrientation,
    );
    if (rotation == null) return null;
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;
    if (image.planes.isEmpty) return null;

    final allBytes = WriteBuffer();
    for (final plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    unawaited(_controller?.dispose());
    unawaited(_textRecognizer.close());
    _fallbackTimer?.cancel();
    super.dispose();
  }

  void _triggerManualCapture() {
    if (_state != OcrScannerState.scanning) return;

    // Nếu AI không bắt được, cho phép tự nhập tay
    setState(() => _state = OcrScannerState.success);
    unawaited(_controller?.stopImageStream());
    _showResultSheet(''); // Trống để người dùng tự nhập
  }

  void _showResultSheet(String aiResult) {
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (context) {
          return Container(
            decoration: const BoxDecoration(
              color: AppTheme.kBackgroundLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24).copyWith(bottom: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Icon(
                  aiResult.isNotEmpty
                      ? CupertinoIcons.checkmark_seal_fill
                      : CupertinoIcons.pencil_circle_fill,
                  color: aiResult.isNotEmpty
                      ? CupertinoColors.activeGreen
                      : CupertinoColors.activeBlue,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  aiResult.isNotEmpty
                      ? 'AI Nhận Diện Thành Công'
                      : 'Nhập Chỉ Số Thủ Công',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: CupertinoColors.black,
                  ),
                ),
                const SizedBox(height: 24),
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildResultRow('Phòng', 'Phòng 302'),
                      const SizedBox(height: 12),
                      _buildResultRow('Loại', 'Đồng Hồ Điện'),
                      const SizedBox(height: 12),
                      Container(height: 1, color: CupertinoColors.systemGrey4),
                      const SizedBox(height: 12),
                      _buildResultRow('Chỉ Số Cũ', '14,350 kWh'),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Chỉ Số Mới',
                            style: TextStyle(
                              color: CupertinoColors.activeBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          aiResult.isNotEmpty
                              ? Text(
                                  '$aiResult kWh',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                    color: CupertinoColors.activeBlue,
                                  ),
                                )
                              : const Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 16),
                                    child: CupertinoTextField(
                                      placeholder: 'Nhập số...',
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                GlassButton(
                  text: 'LƯU VÀ TÍNH TIỀN',
                  color: CupertinoColors.activeGreen,
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        },
      ).then((_) {
        if (mounted) {
          setState(() => _state = OcrScannerState.scanning);
          unawaited(_controller?.startImageStream(_processCameraImage));
        }
      }),
    );
  }

  Widget _buildResultRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: CupertinoColors.systemGrey)),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: CupertinoColors.black,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      title: 'Quét Đồng Hồ Điện Nước',
      backgroundColors: AppTheme.kBackgroundDark,
      useScrollView: false,
      child: Stack(
        children: [
          // ── Real Camera Viewfinder ──────────────────────────
          Positioned.fill(
            child: Container(
              color: CupertinoColors.black,
              child: (!_isCameraInitialized || _controller == null)
                  ? const Center(child: CupertinoActivityIndicator(radius: 20))
                  : ClipRect(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _controller!.value.previewSize?.height ?? 1,
                          height: _controller!.value.previewSize?.width ?? 1,
                          child: CameraPreview(_controller!),
                        ),
                      ),
                    ),
            ),
          ),

          // ── Khung scan và Line ─────────────────────────────
          Positioned.fill(
            child: Center(
              child: Container(
                width: 280,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _state == OcrScannerState.success
                        ? CupertinoColors.activeGreen
                        : CupertinoColors.white,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0x33000000), // Darken the inside slightly
                ),
                child: Stack(
                  children: [
                    // Animated Scan Line
                    AnimatedBuilder(
                      animation: _scanLineController,
                      builder: (context, child) {
                        return Positioned(
                          left: 0,
                          right: 0,
                          top: _scanLineController.value * 110,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: CupertinoColors.activeGreen,
                              boxShadow: [
                                BoxShadow(
                                  color: CupertinoColors.activeGreen.withValues(
                                    alpha: 0.8,
                                  ),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── UI Overlay ─────────────────────────────────────
          const Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: GlassContainer(
              padding: EdgeInsets.all(16),
              child: Text(
                'Hướng Camera vào dãy số trên đồng hồ điện/nước để AI tự động nhận diện chỉ số.',
                textAlign: TextAlign.center,
                style: TextStyle(color: CupertinoColors.white, fontSize: 13),
              ),
            ),
          ),

          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (_state == OcrScannerState.processing)
                  const GlassContainer(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CupertinoActivityIndicator(),
                        SizedBox(width: 12),
                        Text(
                          'AI Đang Trích Xuất Dữ Liệu...',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.black,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: [
                      const Text(
                        'Không tự động nhận diện được?',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _triggerManualCapture,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: CupertinoColors.white,
                            border: Border.all(
                              color: CupertinoColors.white,
                              width: 4,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: CupertinoColors
                                    .black, // Màu đen cho nút nhập thủ công
                              ),
                              child: const Icon(
                                CupertinoIcons.pencil,
                                color: CupertinoColors.white,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
