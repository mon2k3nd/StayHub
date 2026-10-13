import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter/material.dart'
    show
        Colors,
        CircularProgressIndicator,
        AlwaysStoppedAnimation,
        LinearGradient,
        showModalBottomSheet;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/utils/image_compress_helper.dart';
import 'smart_ocr_painters.dart';

part 'smart_ocr_camera_types.dart';

typedef ScanCompleteCallback =
    void Function(XFile photo, {Map<String, String>? extractedData});

enum OcrScanType { front, back, selfie, qr }

// ══════════════════════════════════════════════════════════════
// SmartOcrCamera Widget
// ══════════════════════════════════════════════════════════════
class SmartOcrCamera extends StatefulWidget {
  final String title;
  final String description;
  final ScanCompleteCallback onScanComplete;
  final OcrScanType scanType;
  final bool allowGallery;

  const SmartOcrCamera({
    super.key,
    required this.title,
    required this.description,
    required this.onScanComplete,
    required this.scanType,
    this.allowGallery = false,
  });

  @override
  State<SmartOcrCamera> createState() => _SmartOcrCameraState();
}

class _SmartOcrCameraState extends State<SmartOcrCamera>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // ── Camera ────────────────────────────────────────────────
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;

  // ── ML Kit ────────────────────────────────────────────────
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );
  final BarcodeScanner _barcodeScanner = BarcodeScanner(
    formats: [BarcodeFormat.qrCode],
  );
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableClassification: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.fast,
    ),
  ); // ── Audio ─────────────────────────────────────────────────
  final AudioPlayer _audioPlayer = AudioPlayer();

  // ── State ─────────────────────────────────────────────────
  bool _isProcessing = false;
  bool _hasCaptured = false;
  bool _isCapturing = false;
  Timer? _fallbackTimer;
  Map<String, String>? _lastExtractedData;
  // ignore: unused_field
  bool _isShowingMismatchDialog = false;
  // ignore: unused_field
  final int _failedAttempts = 0;
  bool _isTorchOn = false;
  Timer? _focusHelperTimer;

  // ── Saved QR Data across frames ──────────────────────────────
  String? _savedQrCccd;
  String? _savedQrName;
  String? _savedQrDob;
  String? _savedQrGender;
  String? _savedQrHometown;
  String? _savedQrIssueDate;

  // ignore: unused_field
  final List<String> _challengeSequence = [];
  // ignore: unused_field
  final int _currentChallengeIndex = 0;

  // ── 3-State UX ────────────────────────────────────────────
  _CaptureState _captureState = _CaptureState.idle;

  // ── Auto-capture Pipeline ─────────────────────────────────
  int _stableFrameCount = 0;
  // Mặt sau khó quét live hơn → Cần 6 frame ổn định
  int get _requiredStableFrames => widget.scanType == OcrScanType.back ? 6 : 4;

  // ── Frame Throttling (Tiết chế tốc độ xử lý – tối đa 8fps vào ML Kit) ───
  DateTime? _lastFrameProcessedAt;
  static const _minFrameInterval = Duration(milliseconds: 125); // ~8fps

  // ── Gate indicator state ──────────────────────────────────
  bool _gatePosition = false;
  bool _gateTilt = false;
  bool _gateBlur = false;
  bool _gateGlare = false;
  bool _hasDetectedText = false;

  // ── Context-driven error state ────────────────────────────
  _ErrorType _errorType = _ErrorType.none;
  DateTime? _lastHapticAt;

  // ── Status text ───────────────────────────────────────────
  String _statusText = 'Đưa CCCD vào khung hình';

  // ── Liveness ─────────────────────────────────────────────
  Color? _livenessFlashColor;
  Timer? _flashTimer;

  // ── Animations ────────────────────────────────────────────
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  /// Pulse animation cho state "stabilizing" – khung nảy nhẹ
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  /// Glow animation cho state "captured" – border phát sáng
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  /// Screen flash animation khi chụp thành công
  late AnimationController _screenFlashController;
  late Animation<double> _screenFlashAnimation;
  bool _showScreenFlash = false;

  /// Liveness animations (Passive mode)
  late AnimationController _spinController;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  Timer? _livenessTimeoutTimer;

  // ── Computed color/width từ _captureState ─────────────────
  // ── Smart border: error overrides state ──────────────────
  Color get _borderColor {
    if (_captureState == _CaptureState.captured) return _UXColors.captured;
    if (_captureState == _CaptureState.stabilizing) {
      return _UXColors.stabilizing;
    }
    if (_errorType.isError) return _errorType.frameBorderColor;
    return AppTheme.kBrandDeep; // Sky Blue idle
  }

  // ── Set error with haptic throttle ──────────────────────────
  void _setError(_ErrorType type, [String? statusMsg]) {
    if (!mounted) return;
    final now = DateTime.now();
    final changed = _errorType != type;
    setState(() {
      _errorType = type;
      if (statusMsg != null) _statusText = statusMsg;
    });
    // Rung 1 nhịp ngắn 50ms khi lỗi thay đổi, tối thiểu 500ms giữa 2 lần
    if (changed && type.isError) {
      final throttleOk =
          _lastHapticAt == null ||
          now.difference(_lastHapticAt!).inMilliseconds > 500;
      if (throttleOk) {
        unawaited(HapticFeedback.selectionClick());
        _lastHapticAt = now;
      }
    }
  }

  // ignore: unused_element
  double get _borderWidth {
    switch (_captureState) {
      case _CaptureState.idle:
        return 2.0;
      case _CaptureState.stabilizing:
        return 2.0;
      case _CaptureState.captured:
        return 4.0; // Dày hơn khi thành công
    }
  }

  double get _glowRadius {
    switch (_captureState) {
      case _CaptureState.captured:
        return 20.0 * _glowAnimation.value; // Glow phát sáng
      default:
        return 0.0;
    }
  }

  @override
  void initState() {
    super.initState();

    // Laser scan animation
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    unawaited(_laserController.repeat(reverse: true));
    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );

    // Pulse – chỉ hiển thị khi state = stabilizing
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    unawaited(_pulseController.repeat(reverse: true));
    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Glow – chỉ khi state = captured
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    unawaited(_glowController.repeat(reverse: true));
    _glowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    // Screen flash – khi tự động chụp
    _screenFlashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _screenFlashAnimation = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _screenFlashController, curve: Curves.easeOut),
    );

    // Liveness Spinner
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    unawaited(_spinController.repeat());

    // Liveness Progress (1.5s)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_progressController);

    unawaited(_initCamera());
    WidgetsBinding.instance.addObserver(this);
  }

  // ── Camera Init ────────────────────────────────────────────
  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      final CameraDescription camera;
      if (widget.scanType == OcrScanType.selfie) {
        camera = _cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
          orElse: () => _cameras.first,
        );
      } else {
        camera = _cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras.first,
        );
      }

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      await _controller!.initialize();
      await _controller!.setFocusMode(FocusMode.auto);
      await _controller!.setExposureMode(ExposureMode.auto);

      if (mounted) setState(() => _isCameraInitialized = true);

      if (widget.scanType == OcrScanType.selfie) {
        _livenessTimeoutTimer = Timer(const Duration(seconds: 15), () {
          if (!_hasCaptured && mounted) {
            _showLivenessTimeoutDialog();
          }
        });
      }

      unawaited(
        _controller!.startImageStream((CameraImage image) {
          if (_isProcessing || _hasCaptured || _isCapturing) return;
          unawaited(_runAutoCapturePipeline(image));
        }),
      );
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  // ── AppLifecycle: dừng camera khi app xuống nền (bảo mật & tiết kiệm pin) ──
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(_controller!.stopImageStream().catchError((_) {}));
      unawaited(_controller!.pausePreview().catchError((_) {}));
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_controller!.resumePreview().catchError((_) {}));
      if (!_hasCaptured && !_isCapturing) {
        unawaited(
          _controller!
              .startImageStream((CameraImage image) {
                if (_isProcessing || _hasCaptured || _isCapturing) return;
                unawaited(_runAutoCapturePipeline(image));
              })
              .catchError((_) {}),
        );
      }
    }
  }

  // ══════════════════════════════════════════════════════════════
  // AUTO-CAPTURE PIPELINE – 5 Trạm
  // ══════════════════════════════════════════════════════════════
  Future<void> _runAutoCapturePipeline(CameraImage image) async {
    // Frame Throttling: chỉ xử lý tối đa 8 frame/giây để giảm tải CPU/pin
    final now = DateTime.now();
    if (_lastFrameProcessedAt != null &&
        now.difference(_lastFrameProcessedAt!) < _minFrameInterval) {
      return;
    }
    _lastFrameProcessedAt = now;

    // Bắt đầu đếm giờ hỗ trợ lấy nét nếu chưa đếm
    if (_focusHelperTimer == null && widget.scanType != OcrScanType.selfie) {
      _focusHelperTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && _captureState == _CaptureState.idle) {
          setState(() {
            _statusText = 'Vui lòng lùi điện thoại ra xa một chút để lấy nét';
          });
          unawaited(HapticFeedback.vibrate());
        }
      });
    }

    _isProcessing = true;
    try {
      if (widget.scanType == OcrScanType.selfie) {
        await _runSelfieMode(image);
      } else {
        await _runOcrMode(image);
      }
    } catch (e) {
      debugPrint('Pipeline error: $e');
    }
    _isProcessing = false;
  }

  // ── CCCD Card Mode ─────────────────────────────────────────
  Future<void> _runOcrMode(CameraImage image) async {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;

    // Giai đoạn 1: Parallel Processing (Chạy song song cả Text, Barcode và Face Detection)
    final results = await Future.wait([
      _textRecognizer.processImage(inputImage),
      _barcodeScanner.processImage(inputImage),
      _faceDetector.processImage(inputImage),
    ]);

    final textData = results[0] as RecognizedText;
    final barcodes = results[1] as List<Barcode>;
    final faces = results[2] as List<Face>;

    final text = textData.text;
    final textLower = text.toLowerCase();

    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final raw = barcode.rawValue!;
        final parts = raw.split('|');
        if (parts.length >= 6) {
          _savedQrCccd = parts[0];
          _savedQrName = parts[2];

          final dobRaw = parts[3];
          if (dobRaw.length == 8) {
            _savedQrDob =
                '${dobRaw.substring(0, 2)}/${dobRaw.substring(2, 4)}/${dobRaw.substring(4, 8)}';
          } else {
            _savedQrDob = dobRaw;
          }

          _savedQrGender = parts[4];
          _savedQrHometown = parts[5];
          if (parts.length >= 7) {
            final rawIssue = parts[6];
            if (rawIssue.length == 8) {
              _savedQrIssueDate =
                  '${rawIssue.substring(0, 2)}/${rawIssue.substring(2, 4)}/${rawIssue.substring(4, 8)}';
            } else {
              _savedQrIssueDate = rawIssue;
            }
          }
          break;
        }
      }
    }

    bool hasQrData = _savedQrCccd != null;
    String? qrCccd = _savedQrCccd;
    String? qrName = _savedQrName;
    String? qrDob = _savedQrDob;
    String? qrGender = _savedQrGender;
    String? qrHometown = _savedQrHometown;
    String? qrIssueDate = _savedQrIssueDate;

    // Trạm 3 & 4: Blur + Glare
    final blurScore = _computeLaplacianVariance(image);
    final glareRatio = _computeGlareRatio(image);

    _hasDetectedText = textData.blocks.isNotEmpty;

    _GateStatus blurGate = blurScore > 10 ? _GateStatus.pass : _GateStatus.fail;
    _GateStatus glareGate = glareRatio < 0.03
        ? _GateStatus.pass
        : _GateStatus.fail;

    // Kiểm tra che khuất bằng phân tích pixel tối
    if (widget.scanType != OcrScanType.selfie) {
      final occlusionRatio = _computeOcclusionRatio(image);
      if (occlusionRatio > 0.45) {
        _setError(_ErrorType.occlusion);
        blurGate = _GateStatus.fail;
      }
    }

    _GateStatus positionGate = _GateStatus.fail;
    _GateStatus tiltGate = _GateStatus.fail;

    String? detectedCccd;
    String? detectedDob;
    String? detectedGender;
    String? detectedName;
    String? detectedHometown;
    bool backDetected = false;
    String? detectedIssueDate;
    String? detectedIssuePlace;
    String? detectedFeatures;

    if (textData.blocks.isNotEmpty) {
      bool isBackSide =
          textLower.contains('đặc điểm') ||
          textLower.contains('nơi cấp') ||
          textLower.contains('cục trưởng') ||
          textLower.contains('ngày, tháng, năm') ||
          textLower.contains('cấp ngày') ||
          textLower.contains('<<') ||
          textLower.contains('idvnm') ||
          textLower.contains('cục cảnh sát') ||
          textLower.contains('giám đốc công an') ||
          textLower.contains('công an');

      bool isFrontSide =
          textLower.contains('quê quán') ||
          textLower.contains('nơi thường trú') ||
          textLower.contains('nơi cư trú') ||
          textLower.contains('họ và tên') ||
          textLower.contains('ngày sinh') ||
          textLower.contains('giới tính');

      if (widget.scanType == OcrScanType.qr) {
        if (hasQrData) {
          positionGate = _GateStatus.pass;
          tiltGate = _GateStatus.pass;
          blurGate = _GateStatus.pass;
          glareGate = _GateStatus.pass;
          detectedCccd = qrCccd;
          detectedName = qrName;
          detectedDob = qrDob;
          detectedGender = qrGender;
          detectedHometown = qrHometown;
          detectedIssueDate = qrIssueDate;
          _setError(_ErrorType.none, 'Tuyệt vời, đã quét được mã QR...');
        } else {
          positionGate = _GateStatus.fail;
          _setError(_ErrorType.none, 'Đưa mã QR trên CCCD vào khung hình');
        }
      } else if (widget.scanType == OcrScanType.front) {
        if (isBackSide) {
          positionGate = _GateStatus.fail;
          _setError(
            _ErrorType.wrongSide,
            'Đây là mặt sau, hãy lật lại mặt trước',
          );
        } else {
          final cccdMatch = RegExp(
            r'[0-9O]{12}',
          ).firstMatch(text.replaceAll(' ', '').toUpperCase());
          double cardLeft = double.infinity;
          double cardTop = double.infinity;
          double cardRight = 0;
          double cardBottom = 0;

          for (final block in textData.blocks) {
            final box = block.boundingBox;
            if (box.left < cardLeft) cardLeft = box.left.toDouble();
            if (box.top < cardTop) cardTop = box.top.toDouble();
            if (box.right > cardRight) cardRight = box.right.toDouble();
            if (box.bottom > cardBottom) cardBottom = box.bottom.toDouble();
          }

          final cardWidth = cardRight - cardLeft;
          final cardHeight = cardBottom - cardTop;

          bool hasFaceOnCard = false;
          if (cardWidth > 0 && cardHeight > 0) {
            for (final face in faces) {
              final fBox = face.boundingBox;
              final relLeft = (fBox.left - cardLeft) / cardWidth;
              final relWidth = fBox.width / cardWidth;
              if (relLeft > -0.2 &&
                  relLeft < 0.45 &&
                  relWidth > 0.12 &&
                  relWidth < 0.38) {
                hasFaceOnCard = true;
                break;
              }
            }
          }

          int validZones = 0;
          if (cccdMatch != null) validZones++;
          if (hasFaceOnCard) validZones++;
          if (textLower.contains('cộng hòa') ||
              textLower.contains('việt nam')) {
            validZones++;
          }
          if (textLower.contains('căn cước') ||
              textLower.contains('công dân')) {
            validZones++;
          }
          if (textLower.contains('họ') || textLower.contains('tên')) {
            validZones++;
          }
          if (textLower.contains('sinh') || textLower.contains('birth')) {
            validZones++;
          }
          if (textLower.contains('quê') || textLower.contains('quán')) {
            validZones++;
          }
          if (textLower.contains('trú') || textLower.contains('thường')) {
            validZones++;
          }

          bool isFullyUncovered = validZones >= 7;

          if (isFullyUncovered) {
            detectedCccd = cccdMatch!.group(0)?.replaceAll('O', '0');
            positionGate = _GateStatus.pass;
            tiltGate = _GateStatus.pass;
            _setError(_ErrorType.none, 'Tuyệt vời, giữ yên tay...');
          } else {
            positionGate = _GateStatus.fail;
            tiltGate = _GateStatus.fail;
            if (cccdMatch != null && !hasFaceOnCard) {
              _setError(
                _ErrorType.occlusion,
                'Không được che ảnh chân dung trên thẻ!',
              );
            } else if (cccdMatch == null) {
              _setError(_ErrorType.occlusion, 'Không được che mã số CCCD!');
            } else {
              _setError(
                _ErrorType.tooFar,
                'Căn thẻ vào khung đầy đủ, không che góc nào',
              );
            }
          }
        }
      } else if (widget.scanType == OcrScanType.back) {
        if (isFrontSide) {
          positionGate = _GateStatus.fail;
          _setError(
            _ErrorType.wrongSide,
            'Đây là mặt trước, hãy lật lại mặt sau',
          );
        } else {
          // Trích xuất ngày cấp
          final dateMatch = RegExp(
            r'(?:ngày|ngay)\s+(\d{1,2})\s+(?:tháng|thang)\s+(\d{1,2})\s+(?:năm|nam)\s+(\d{4})',
            caseSensitive: false,
          ).firstMatch(textLower);
          if (dateMatch != null) {
            String d = dateMatch.group(1)!.padLeft(2, '0');
            String m = dateMatch.group(2)!.padLeft(2, '0');
            String y = dateMatch.group(3)!;
            detectedIssueDate = '$d/$m/$y';
          } else {
            final simpleDateMatch = RegExp(
              r'\b(\d{2})\s*[/.-]\s*(\d{2})\s*[/.-]\s*(\d{4})\b',
            ).firstMatch(text);
            if (simpleDateMatch != null) {
              detectedIssueDate =
                  '${simpleDateMatch.group(1)}/${simpleDateMatch.group(2)}/${simpleDateMatch.group(3)}';
            }
          }

          bool hasBackKeywords =
              isBackSide ||
              text.contains('<<') ||
              textLower.contains('cảnh') ||
              textLower.contains('công an') ||
              textLower.contains('cấp') ||
              textLower.contains('nơi cấp') ||
              textLower.contains('đặc điểm');

          // Mặt sau: chỉ cần đọc được keyword mặt sau (không yêu cầu MRZ)
          // MRZ thường ML Kit không đọc được qua camera live → loại bỏ yêu cầu này
          bool backOk = hasBackKeywords || detectedIssueDate != null;

          if (backOk) {
            // Set positionGate pass để bắt đầu đếm ổn định
            positionGate = _GateStatus.pass;
            tiltGate = _GateStatus.pass;
            backDetected = true;

            detectedFeatures = null;

            // Suy luận Nơi cấp từ Ngày cấp (Luật CCCD Việt Nam)
            if ((detectedIssueDate?.length ?? 0) >= 10) {
              try {
                final parts = detectedIssueDate!.split('/');
                if (parts.length == 3) {
                  final d = int.tryParse(parts[0]) ?? 0;
                  final m = int.tryParse(parts[1]) ?? 0;
                  final y = int.tryParse(parts[2]) ?? 0;
                  if (y > 0) {
                    final issueDateTime = DateTime(y, m, d);
                    if (issueDateTime.isAfter(DateTime(2024, 6, 30))) {
                      detectedIssuePlace = 'Bộ Công an';
                    } else if (issueDateTime.isAfter(DateTime(2018, 10, 9))) {
                      detectedIssuePlace =
                          'Cục trưởng Cục Cảnh sát quản lý hành chính về trật tự xã hội';
                    } else if (issueDateTime.isAfter(DateTime(2015, 12, 31))) {
                      detectedIssuePlace =
                          'Cục Cảnh sát đăng ký, quản lý cư trú và dữ liệu quốc gia về dân cư';
                    }
                  }
                }
              } catch (e) {
                debugPrint('Error inferring issuePlace from date: $e');
              }
            }

            // Fallback OCR nếu không suy luận được
            if (detectedIssuePlace == null || detectedIssuePlace.isEmpty) {
              if (textLower.contains('bộ công an') ||
                  textLower.contains('bo cong an')) {
                detectedIssuePlace = 'Bộ Công an';
              } else if (textLower.contains('đăng ký') ||
                  textLower.contains('dang ky') ||
                  textLower.contains('cư trú') ||
                  textLower.contains('cu tru') ||
                  textLower.contains('dữ liệu quốc gia') ||
                  textLower.contains('dan cu')) {
                detectedIssuePlace =
                    'Cục Cảnh sát đăng ký, quản lý cư trú và dữ liệu quốc gia về dân cư';
              } else if (textLower.contains('trật tự xã hội') ||
                  textLower.contains('trat tu xa hoi') ||
                  textLower.contains('cục trưởng') ||
                  textLower.contains('cuc truong') ||
                  textLower.contains('hành chính') ||
                  (textLower.contains('cảnh sát') &&
                      textLower.contains('quản lý'))) {
                detectedIssuePlace =
                    'Cục trưởng Cục Cảnh sát quản lý hành chính về trật tự xã hội';
              } else if (textLower.contains('công an tỉnh') ||
                  textLower.contains('công an tp') ||
                  textLower.contains('giám đốc công an')) {
                final caMatch = RegExp(
                  r'((?:gi\u00e1m \u0111\u1ed1c |giam doc )?(?:c\u00f4ng an|cong an)\s+(?:t\u1ec9nh|tinh|th\u00e0nh ph\u1ed1|thanh pho|tp\.?|t\.p\.?)\s+[\w\s\.]+)',
                  caseSensitive: false,
                ).firstMatch(textLower);
                detectedIssuePlace = caMatch != null
                    ? caMatch.group(1)!.replaceAll('\n', ' ').trim()
                    : 'Công an tỉnh/thành phố';
              }
            }
          } else {
            positionGate = _GateStatus.fail;
          }
        }
      }

      // Đã loại bỏ logic TiltGate gây lỗi ghi đè
    }

    final result = _PipelineResult(
      position: positionGate,
      tilt: tiltGate,
      blur: blurGate,
      glare: glareGate,
      hint: _buildSmartHint(
        positionGate,
        tiltGate,
        blurGate,
        glareGate,
        widget.scanType,
      ),
    );

    if (!mounted) return;

    // ── Trạm 5: Stability Counter ─────────────────────────────
    if (result.allPass) {
      _stableFrameCount++;

      if (mounted) {
        setState(() {
          if (_captureState == _CaptureState.idle && _stableFrameCount == 1) {
            unawaited(
              HapticFeedback.lightImpact(),
            ); // Haptic khi bắt đầu bắt nét thành công
            _focusHelperTimer?.cancel(); // Hủy nhắc nhở lấy nét
          }
          // State 2: Stabilizing – khung vàng #FFC107
          _captureState = _CaptureState.stabilizing;
          _statusText = _stableFrameCount >= _requiredStableFrames
              ? '✓ Đã chụp thành công!'
              : 'Vui lòng giữ nguyên điện thoại...';
          _gatePosition = true;
          _gateTilt = true;
          _gateBlur = true;
          _gateGlare = true;
        });
      }

      if (_stableFrameCount >= _requiredStableFrames) {
        if (detectedCccd != null || backDetected) {
          _lastExtractedData = {
            if (detectedCccd != null) 'cccd': detectedCccd,
            if (detectedDob != null) 'dob': detectedDob,
            if (detectedGender != null) 'gender': detectedGender,
            if (detectedName != null) 'name': detectedName,
            if (detectedHometown != null) 'hometown': detectedHometown,
            if (detectedIssueDate != null) 'issueDate': detectedIssueDate,
            if (detectedIssuePlace != null) 'issuePlace': detectedIssuePlace,
            if (detectedFeatures != null) 'features': detectedFeatures,
            if (hasQrData) 'from_qr': 'true',
          };
        }
        _triggerAutoCapture();
      }
    } else {
      _stableFrameCount = 0;
      if (mounted) {
        setState(() {
          // State 1: Idle – khung trắng (hoặc đỏ nhạt nếu blur/glare)
          _captureState = _CaptureState.idle;
          _statusText = result.hint;
          _gatePosition = result.position == _GateStatus.pass;
          _gateTilt = result.tilt == _GateStatus.pass;
          _gateBlur = result.blur == _GateStatus.pass;
          _gateGlare = result.glare == _GateStatus.pass;
        });
      }
    }
  }

  // ── Selfie / Liveness Mode (Passive Liveness + Smart Errors) ───────────────
  double _lastEulerY = 0.0;

  Future<void> _runSelfieMode(CameraImage image) async {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;

    final faces = await _faceDetector.processImage(inputImage);

    // Multiple faces check
    if (faces.length > 1) {
      _setError(_ErrorType.multipleFaces);
      _resetLivenessState(_ErrorType.multipleFaces.message);
      return;
    }

    if (faces.isEmpty) {
      _setError(_ErrorType.none);
      _resetLivenessState('Đưa khuôn mặt vào khung hình');
      return;
    }

    final face = faces.first;
    final imgWidth = inputImage.metadata?.size.width ?? 1080;
    final imgHeight = inputImage.metadata?.size.height ?? 1920;

    // Face size
    final faceArea = face.boundingBox.width * face.boundingBox.height;
    final totalArea = imgWidth * imgHeight;

    // Too far check
    if (faceArea < totalArea * 0.08) {
      _setError(_ErrorType.tooFar);
      _resetLivenessState(_ErrorType.tooFar.message);
      return;
    }

    // Too close check
    if (faceArea > totalArea * 0.50) {
      _setError(_ErrorType.tooClose);
      _resetLivenessState(_ErrorType.tooClose.message);
      return;
    }

    // Head turn too fast detection
    final currentEulerY = face.headEulerAngleY ?? 0.0;
    final eulerDelta = (currentEulerY - _lastEulerY).abs();
    _lastEulerY = currentEulerY;
    if (eulerDelta > 28) {
      _setError(_ErrorType.tooFast);
      _resetLivenessState(_ErrorType.tooFast.message);
      return;
    }

    // Centered check: handle portrait/landscape coordinates from ML Kit correctly
    final faceCenterX = face.boundingBox.center.dx;
    final faceCenterY = face.boundingBox.center.dy;

    // Check center relative to dimensions
    final isCenteredX =
        faceCenterX > imgWidth * 0.12 && faceCenterX < imgWidth * 0.88;
    final isCenteredY =
        faceCenterY > imgHeight * 0.12 && faceCenterY < imgHeight * 0.88;
    final tiltOk =
        face.headEulerAngleY == null || face.headEulerAngleY!.abs() < 36;

    if (!isCenteredX || !isCenteredY) {
      _setError(_ErrorType.none);
      _resetLivenessState('Đưa khuôn mặt vào giữa khung hình');
      return;
    }

    if (!tiltOk) {
      _setError(_ErrorType.none);
      _resetLivenessState('Nhìn thẳng vào camera...');
      return;
    }

    // All good – clear error
    _setError(_ErrorType.none);

    // Đạt điều kiện -> Đang quét (Giữ yên 1.5s ~ 12 frames)
    if (mounted) {
      if (_captureState != _CaptureState.stabilizing) {
        setState(() {
          _captureState = _CaptureState.stabilizing;
          _statusText = 'Giữ yên... đang xác thực';
        });
        unawaited(HapticFeedback.lightImpact());
        unawaited(_progressController.forward(from: 0.0)); // Chạy progress ring
      }

      _stableFrameCount++;
      if (_stableFrameCount >= 12) {
        _triggerAutoCapture();
      }
    }
  }

  void _resetLivenessState(String message) {
    _stableFrameCount = 0;
    if (mounted) {
      if (_captureState == _CaptureState.stabilizing) {
        _progressController.reset();
      }
      setState(() {
        _captureState = _CaptureState.idle;
        _statusText = message;
      });
    }
  }

  void _resetForRetry() {
    _isShowingMismatchDialog = false;
    _hasCaptured = false;
    _isCapturing = false;
    _resetLivenessState('Đưa khuôn mặt vào khung hình');
    unawaited(_controller?.resumePreview());
  }

  // ══════════════════════════════════════════════════════════════
  // Trạm 3 – Laplacian Variance (Blur Detection on YUV Y-plane)
  // ══════════════════════════════════════════════════════════════
  double _computeLaplacianVariance(CameraImage image) {
    try {
      final bytes = image.planes[0].bytes;
      final w = image.width;
      final h = image.height;
      final cx = w ~/ 2;
      final cy = h ~/ 2;
      const r = 100;
      double sumSq = 0;
      int count = 0;
      for (int y = cy - r; y < cy + r; y += 2) {
        for (int x = cx - r; x < cx + r; x += 2) {
          if (x <= 0 || x >= w - 1 || y <= 0 || y >= h - 1) continue;
          final idx = y * w + x;
          final lap =
              (bytes[idx] * 4) -
              bytes[(y - 1) * w + x] -
              bytes[(y + 1) * w + x] -
              bytes[y * w + (x - 1)] -
              bytes[y * w + (x + 1)];
          sumSq += lap * lap;
          count++;
        }
      }
      return count == 0 ? 0 : sqrt(sumSq / count);
    } catch (_) {
      return 200; // Default pass
    }
  }

  // ══════════════════════════════════════════════════════════════
  // Trạm 4 – Glare Ratio (pixels > 240 luma)
  // ══════════════════════════════════════════════════════════════
  double _computeGlareRatio(CameraImage image) {
    try {
      final bytes = image.planes[0].bytes;
      final w = image.width;
      final h = image.height;
      final cx = w ~/ 2;
      final cy = h ~/ 2;
      const r = 120;
      int overexposed = 0, total = 0;
      for (int y = cy - r; y < cy + r; y += 3) {
        for (int x = cx - r; x < cx + r; x += 3) {
          if (x < 0 || x >= w || y < 0 || y >= h) continue;
          if (bytes[y * w + x] > 240) overexposed++;
          total++;
        }
      }
      return total == 0 ? 0 : overexposed / total;
    } catch (_) {
      return 0;
    }
  }

  // ════════════════════════════════════════════════════════════
  // Trạm 5 – Occlusion Detection (phần trung tâm bị che khuất)
  // Kiểm tra nếu tỷ lệ pixel tối (luma < 40) ở vùng trung tâm quá cao
  // thì có khả năng tay/vật thể đang che CCCD
  // ════════════════════════════════════════════════════════════
  double _computeOcclusionRatio(CameraImage image) {
    try {
      final bytes = image.planes[0].bytes;
      final w = image.width;
      final h = image.height;
      final cx = w ~/ 2;
      final cy = h ~/ 2;
      // Quét vùng trung tâm 60% khại đị
      const r = 80;
      int dark = 0, total = 0;
      for (int y = cy - r; y < cy + r; y += 2) {
        for (int x = cx - r; x < cx + r; x += 2) {
          if (x < 0 || x >= w || y < 0 || y >= h) continue;
          if (bytes[y * w + x] < 45) dark++;
          total++;
        }
      }
      return total == 0 ? 0 : dark / total;
    } catch (_) {
      return 0;
    }
  }

  // ── Gợi ý theo trạm fail đầu tiên ────────────────────────
  // ignore: unused_element
  String _buildHint(
    _GateStatus pos,
    _GateStatus tilt,
    _GateStatus blur,
    _GateStatus glare,
  ) {
    if (pos == _GateStatus.fail) return 'Đưa CCCD vào khung hình';
    if (tilt == _GateStatus.fail) return 'Giữ điện thoại thẳng góc';
    if (blur == _GateStatus.fail) return 'Giữ vững tay, đang lấy nét...';
    if (glare == _GateStatus.fail) return 'Tránh ánh đèn chiếu trực tiếp';
    return 'Giữ nguyên vị trí...';
  }

  // ══════════════════════════════════════════════════════════════
  // AUTO-CAPTURE TRIGGER
  // Feedback: Flash màn hình + Haptic mediumImpact + Shutter sound
  // ══════════════════════════════════════════════════════════════
  void _triggerAutoCapture() {
    if (_hasCaptured || _isCapturing) return;
    _hasCaptured = true;
    _isCapturing = true;

    // ── State 3: Captured – khung xanh huỳnh quang #00E676 + Glow ──
    if (mounted) {
      setState(() {
        _captureState = _CaptureState.captured;
        _statusText = widget.scanType == OcrScanType.selfie
            ? '✓ Đã xác nhận người thật!'
            : '✓ Đã chụp thành công!';
        _showScreenFlash = true;
      });
    }

    // ── Feedback 1: Haptic – impactMedium (theo chuẩn UX) ──────────
    unawaited(HapticFeedback.mediumImpact());

    // ── Feedback 2: Shutter Sound – phát shutter_click.wav ─────────
    unawaited(_playShutterSound());

    // ── Feedback 3: Screen Flash – nháy sáng 0.2s ──────────────────
    unawaited(
      _screenFlashController.forward(from: 0).then((_) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) setState(() => _showScreenFlash = false);
          _screenFlashController.reset();
        });
      }),
    );

    // ── Chuyển cảnh sau 500ms ────────────────────────────────────────
    Timer(const Duration(milliseconds: 500), () async {
      if (!mounted || _controller == null) return;
      try {
        await _controller!.stopImageStream();
        if (widget.scanType == OcrScanType.selfie) {
          final selfieImage = await _controller!.takePicture();
          await _startFlashLivenessRecording(selfieImage);
        } else {
          final xfile = await _controller!.takePicture();
          // ── Scan static photo for QR (reliable on hi-res still) ──
          Map<String, String> mergedData = Map.from(_lastExtractedData ?? {});
          if (widget.scanType == OcrScanType.front) {
            try {
              final staticInput = InputImage.fromFilePath(xfile.path);

              // 1. Chạy OCR FULL trên ảnh tĩnh nét cao
              final staticText = await _textRecognizer.processImage(
                staticInput,
              );
              final text = staticText.text;
              final textLower = text.toLowerCase();

              // Extract CCCD robustly (must start with 0)
              String textNoSpaces = text
                  .replaceAll(RegExp(r'\s+'), '')
                  .toUpperCase();
              final cccdMatch = RegExp(r'0[0-9O]{11}').firstMatch(textNoSpaces);
              if (cccdMatch != null) {
                mergedData['cccd'] = cccdMatch.group(0)!.replaceAll('O', '0');
              }

              // Extract DOB
              String sanitizedText = text
                  .replaceAll('l', '1')
                  .replaceAll('I', '1')
                  .replaceAll('O', '0')
                  .replaceAll('o', '0');
              final dobMatch = RegExp(
                r'\b(\d{2}[\/\-\.]\d{2}[\/\-\.]\d{4})\b',
              ).firstMatch(sanitizedText);
              if (dobMatch != null) {
                mergedData['dob'] = dobMatch
                    .group(1)!
                    .replaceAll(RegExp(r'[\-\.]'), '/');
              }

              // Extract Gender robustly
              final genderMatch = RegExp(
                r'giới tính.*?(nam|nữ)',
                caseSensitive: false,
              ).firstMatch(textLower);
              if (genderMatch != null) {
                mergedData['gender'] =
                    genderMatch.group(1)!.toLowerCase() == 'nam' ? 'Nam' : 'Nữ';
              } else {
                for (final block in staticText.blocks) {
                  for (final line in block.lines) {
                    final lt = line.text.toLowerCase();
                    if (lt.contains('giới tính') ||
                        lt.contains('gioi tinh') ||
                        lt.contains('sex')) {
                      if (lt.contains('nữ') || lt.contains('nu')) {
                        mergedData['gender'] = 'Nữ';
                      } else if (lt.contains('nam')) {
                        mergedData['gender'] = 'Nam';
                      }
                    }
                  }
                }
              }

              // Extract Name robustly
              bool isNameSection = false;
              for (final block in staticText.blocks) {
                for (final line in block.lines) {
                  final lt = line.text.trim();
                  final ltl = lt.toLowerCase();
                  if (isNameSection) {
                    if (lt == lt.toUpperCase() &&
                        lt.length > 5 &&
                        !lt.contains(RegExp(r'[0-9]')) &&
                        !lt.contains('CĂN CƯỚC') &&
                        !lt.contains('CÔNG DÂN') &&
                        !lt.contains('VIỆT NAM')) {
                      mergedData['name'] = lt;
                      isNameSection = false;
                      break;
                    }
                  } else {
                    if (ltl.contains('họ và tên') ||
                        ltl.contains('ho va ten') ||
                        ltl.contains('full name')) {
                      isNameSection = true;
                      if (lt.contains(':')) {
                        String possibleName = lt
                            .substring(lt.indexOf(':') + 1)
                            .trim();
                        if (possibleName.length > 5 &&
                            possibleName == possibleName.toUpperCase()) {
                          mergedData['name'] = possibleName;
                          isNameSection = false;
                          break;
                        }
                      }
                    }
                  }
                }
                if (mergedData['name'] != null) break;
              }

              // Extract Hometown (Quê quán) robustly
              bool isHometownSection = false;
              String hometown = '';
              for (final block in staticText.blocks) {
                for (final line in block.lines) {
                  final lt = line.text.toLowerCase();
                  if (isHometownSection) {
                    if (lt.contains('thường trú') ||
                        lt.contains('thuong tru') ||
                        lt.contains('cư trú')) {
                      isHometownSection = false;
                      break;
                    }
                    hometown += '${line.text} ';
                  } else {
                    if (lt.contains('quê quán') ||
                        lt.contains('que quan') ||
                        lt.contains('khai sinh')) {
                      isHometownSection = true;
                      if (lt.contains(':')) {
                        hometown +=
                            '${line.text.substring(line.text.indexOf(':') + 1).trim()} ';
                      }
                    }
                  }
                }
              }
              if (hometown.trim().isNotEmpty) {
                mergedData['hometown'] = hometown.trim();
              }

              // 2. Chạy QR Code để bù đắp / sửa sai (QR Code là chuẩn nhất nếu có)
              final qrBarcodes = await _barcodeScanner.processImage(
                staticInput,
              );
              bool qrFound = false;
              for (final barcode in qrBarcodes) {
                if (barcode.rawValue != null) {
                  final parts = barcode.rawValue!.split('|');
                  if (parts.length >= 6) {
                    mergedData['cccd'] = parts[0];
                    mergedData['name'] = parts[2];
                    final rawDob = parts[3];
                    if (rawDob.length == 8) {
                      mergedData['dob'] =
                          '${rawDob.substring(0, 2)}/${rawDob.substring(2, 4)}/${rawDob.substring(4)}';
                    } else {
                      mergedData['dob'] = rawDob;
                    }
                    mergedData['gender'] = parts[4];
                    // Chỉ lấy địa chỉ QR nếu OCR không đọc được Quê quán, vì QR chứa Thường trú
                    if (mergedData['hometown'] == null ||
                        mergedData['hometown']!.isEmpty) {
                      mergedData['hometown'] = parts[5];
                    }
                    if (parts.length >= 7) {
                      final rawIssue = parts[6];
                      if (rawIssue.length == 8) {
                        mergedData['issueDate'] =
                            '${rawIssue.substring(0, 2)}/${rawIssue.substring(2, 4)}/${rawIssue.substring(4)}';
                      } else {
                        mergedData['issueDate'] = rawIssue;
                      }
                    }
                    mergedData['from_qr'] = 'true';
                    qrFound = true;
                    break;
                  }
                }
              }

              // Fallback từ QR live nếu ảnh tĩnh không quét được QR
              if (!qrFound && _savedQrCccd != null) {
                mergedData['cccd'] = _savedQrCccd!;
                mergedData['name'] = _savedQrName ?? mergedData['name'] ?? '';

                String rawDob = _savedQrDob ?? '';
                if (rawDob.length == 8) {
                  mergedData['dob'] =
                      '${rawDob.substring(0, 2)}/${rawDob.substring(2, 4)}/${rawDob.substring(4)}';
                } else if (rawDob.isNotEmpty) {
                  mergedData['dob'] = rawDob;
                }

                mergedData['gender'] =
                    _savedQrGender ?? mergedData['gender'] ?? '';
                if (mergedData['hometown'] == null ||
                    mergedData['hometown']!.isEmpty) {
                  mergedData['hometown'] = _savedQrHometown ?? '';
                }
                if (_savedQrIssueDate != null) {
                  mergedData['issueDate'] = _savedQrIssueDate!;
                }
                mergedData['from_qr'] = 'true';
              }
            } catch (e) {
              debugPrint('[QR-Static] Error: $e');
            }
          } else if (widget.scanType == OcrScanType.back) {
            try {
              final staticInput = InputImage.fromFilePath(xfile.path);
              final staticText = await _textRecognizer.processImage(
                staticInput,
              );
              final text = staticText.text;
              final textLower = text.toLowerCase();

              // 1. User requested to remove "Đặc điểm nhận dạng" logic
              // No features will be extracted.

              // 2. Trích xuất "Ngày cấp"
              final dateAnchorRegex = RegExp(
                r'(?:ng[àa]y|date)[\s\S]*?(\d{2})\s*[\/\-\.]\s*(\d{2})\s*[\/\-\.]\s*(\d{4})',
                caseSensitive: false,
              );
              final dateAnchorMatch = dateAnchorRegex.firstMatch(text);
              if (dateAnchorMatch != null) {
                mergedData['issueDate'] =
                    '${dateAnchorMatch.group(1)}/${dateAnchorMatch.group(2)}/${dateAnchorMatch.group(3)}';
              } else {
                final anyDateMatch = RegExp(
                  r'\b(\d{2})\s*[\/\-\.]\s*(\d{2})\s*[\/\-\.]\s*(\d{4})\b',
                ).firstMatch(text);
                if (anyDateMatch != null) {
                  mergedData['issueDate'] =
                      '${anyDateMatch.group(1)}/${anyDateMatch.group(2)}/${anyDateMatch.group(3)}';
                }
              }

              // 3. Trích xuất "Nơi cấp" – phân loại theo 4 thời kỳ phát hành CCCD/CMND
              String detectedIssuePlace = '';

              // Loại 1 (01/07/2024 – nay): Thẻ Căn cước → "BỘ CÔNG AN"
              if (textLower.contains('bộ công an') ||
                  textLower.contains('bo cong an')) {
                detectedIssuePlace = 'Bộ Công an';
              }
              // Loại 2 (10/10/2018 – 30/06/2024): CCCD gắn chip → "CỤC TRƯỞNG CỤC CẢNH SÁT QUẢN LÝ HÀNH CHÍNH VỀ TRẬT TỰ XÃ HỘI"
              else if (textLower.contains('trật tự xã hội') ||
                  textLower.contains('trat tu xa hoi') ||
                  textLower.contains('cục trưởng') ||
                  textLower.contains('cuc truong') ||
                  textLower.contains('hành chính') ||
                  textLower.contains('hanh chinh') ||
                  (textLower.contains('cảnh sát') &&
                      textLower.contains('quản lý'))) {
                detectedIssuePlace =
                    'Cục trưởng Cục Cảnh sát quản lý hành chính về trật tự xã hội';
              }
              // Loại 3 (01/01/2016 – 09/10/2018): CCCD mã vạch → "CỤC CẢNH SÁT ĐĂNG KÝ QUẢN LÝ CƯ TRÚ..."
              else if (textLower.contains('đăng ký') ||
                  textLower.contains('dang ky') ||
                  textLower.contains('cư trú') ||
                  textLower.contains('cu tru') ||
                  textLower.contains('dữ liệu quốc gia') ||
                  textLower.contains('du lieu quoc gia') ||
                  textLower.contains('dân cư') ||
                  textLower.contains('dan cu')) {
                detectedIssuePlace =
                    'Cục Cảnh sát đăng ký quản lý cư trú và dữ liệu quốc gia về dân cư';
              }
              // Loại 4 (Trước 2021): CMND → "CÔNG AN TỈNH/TP [Tên tỉnh]"
              else if (textLower.contains('công an tỉnh') ||
                  textLower.contains('cong an tinh') ||
                  textLower.contains('công an tp') ||
                  textLower.contains('cong an tp') ||
                  textLower.contains('công an thành phố') ||
                  textLower.contains('giám đốc công an')) {
                final caMatch = RegExp(
                  r'(?:gi[áa]m ?[đd][ốo]c )?(?:c[ôo]ng an|cong an)\s+(?:t[ỉi]nh|tinh|th[àa]nh ph[ốo]|thanh pho|tp\.?|t\.p\.?)\s+[\w\s\.]+',
                  caseSensitive: false,
                ).firstMatch(text);
                detectedIssuePlace = caMatch != null
                    ? caMatch.group(1)!.replaceAll('\n', ' ').trim()
                    : 'Công an tỉnh/thành phố';
              }
              // Fallback: chỉ thấy Cục/Cảnh sát chung chung
              else if (textLower.contains('cục') ||
                  textLower.contains('cảnh sát')) {
                detectedIssuePlace =
                    'Cục trưởng Cục Cảnh sát quản lý hành chính về trật tự xã hội';
              }

              if (detectedIssuePlace.isNotEmpty) {
                mergedData['issuePlace'] = detectedIssuePlace;
              }
              debugPrint(
                '[OCR-Back] issuePlace=$detectedIssuePlace | fullText=$text',
              );
            } catch (e) {
              debugPrint('[Static-Back] Error: $e');
            }
          }
          if (mounted) {
            widget.onScanComplete(
              xfile,
              extractedData: mergedData.isEmpty ? null : mergedData,
            );
          }
        }
      } catch (e) {
        debugPrint('Auto-capture error: $e');
        _isCapturing = false;
      }
    });
  }

  // Phát shutter click sound bằng audioplayers
  Future<void> _playShutterSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/shutter_click.wav'));
    } catch (e) {
      debugPrint('Sound error: $e');
      // Fallback: system click
      await SystemSound.play(SystemSoundType.click);
    }
  }

  // Tải từ thư viện (Gallery Fallback)
  // ignore: unused_element
  Future<void> _pickFromGallery() async {
    if (_hasCaptured || _isCapturing) return;
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final compressedFile = await ImageCompressHelper.compressXFile(
          pickedFile,
        );

        _hasCaptured = true;
        _isCapturing = true;
        if (mounted) {
          setState(() {
            _captureState = _CaptureState.captured;
            _statusText = '✓ Đã chọn ảnh và nén thành công';
            _showScreenFlash = true;
          });
        }
        unawaited(HapticFeedback.mediumImpact());
        unawaited(_playShutterSound());
        unawaited(
          _screenFlashController.forward(from: 0).then((_) {
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) setState(() => _showScreenFlash = false);
              _screenFlashController.reset();
            });
          }),
        );
        Timer(const Duration(milliseconds: 500), () async {
          await _controller?.stopImageStream();
          if (mounted) {
            widget.onScanComplete(
              compressedFile,
              extractedData: _lastExtractedData,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải ảnh thư viện: $e');
    }
  }

  // ── Liveness Video Recording ───────────────────────────────
  Future<void> _startFlashLivenessRecording(XFile selfieImage) async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      if (mounted) setState(() => _statusText = 'Đang ghi hình quang phổ...');

      await _controller!.startVideoRecording();

      final colors = [Colors.red, Colors.green, Colors.blue, Colors.white];
      int colorIndex = 0;
      _flashTimer = Timer.periodic(const Duration(milliseconds: 300), (t) {
        if (mounted) {
          setState(() {
            _livenessFlashColor = colors[colorIndex % colors.length];
            colorIndex++;
          });
        }
      });

      await Future.delayed(const Duration(seconds: 2));
      _flashTimer?.cancel();
      if (mounted) setState(() => _livenessFlashColor = null);

      final videoFile = await _controller!.stopVideoRecording();
      if (mounted) {
        final Map<String, String> data = Map.from(_lastExtractedData ?? {});
        data['selfieImagePath'] = selfieImage.path;
        widget.onScanComplete(videoFile, extractedData: data);
      }
    } catch (e) {
      debugPrint('Liveness recording error: $e');
    }
  }

  // ── ML Kit helper ──────────────────────────────────────────
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
    WidgetsBinding.instance.removeObserver(this);
    // Xóa cache dữ liệu nhạy cảm khỏi RAM trước khi giải phóng (Nghị định 13/2023)
    _lastExtractedData?.clear();
    _lastExtractedData = null;
    unawaited(_controller?.dispose());
    _laserController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    _screenFlashController.dispose();
    _spinController.dispose();
    _progressController.dispose();
    unawaited(_textRecognizer.close());
    unawaited(_barcodeScanner.close());
    unawaited(_faceDetector.close());
    unawaited(_audioPlayer.dispose());
    _flashTimer?.cancel();
    _fallbackTimer?.cancel();
    _focusHelperTimer?.cancel();
    _livenessTimeoutTimer?.cancel();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CupertinoActivityIndicator(radius: 20, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'Đang khởi động camera...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    final isSelfie = widget.scanType == OcrScanType.selfie;
    final isQr = widget.scanType == OcrScanType.qr;
    final isStabilizing = _captureState == _CaptureState.stabilizing;
    final isCaptured = _captureState == _CaptureState.captured;

    return Stack(
      children: [
        // ── Camera Feed ─────────────────────────────────────────
        Positioned.fill(
          child: ClipRect(
            child: AnimatedScale(
              scale: isCaptured || isStabilizing ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.elasticOut,
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

        // ── Flash Overlay ─────────────────────────────────────────
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: isCaptured ? 0.8 : 0.0,
              duration: Duration(milliseconds: isCaptured ? 50 : 300),
              curve: isCaptured ? Curves.easeOut : Curves.easeIn,
              child: Container(color: Colors.white),
            ),
          ),
        ),

        // ── Torch Button ─────────────────────────────────────────
        Positioned(
          top: 16,
          right: 16,
          child: SafeArea(
            child: GestureDetector(
              onTap: () async {
                if (_controller != null) {
                  try {
                    await _controller!.setFlashMode(
                      _isTorchOn ? FlashMode.off : FlashMode.torch,
                    );
                    setState(() {
                      _isTorchOn = !_isTorchOn;
                    });
                    unawaited(HapticFeedback.lightImpact());
                  } catch (e) {
                    debugPrint('Torch toggle error: $e');
                  }
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _isTorchOn
                      ? const Color(0xFFFACC15).withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isTorchOn
                        ? const Color(0xFFFACC15).withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _isTorchOn ? CupertinoIcons.bolt_fill : CupertinoIcons.bolt,
                  color: _isTorchOn
                      ? const Color(0xFFFACC15)
                      : Colors.white.withValues(alpha: 0.7),
                  size: 20,
                ),
              ),
            ),
          ),
        ),

        // ── Dark Overlay with transparent cutout ─────────────────
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: ScannerOverlayPainter(
                isSelfie: isSelfie,
                isQr: isQr,
                isBack: widget.scanType == OcrScanType.back,
                borderColor: _borderColor,
                borderWidth: _captureState == _CaptureState.captured
                    ? 3.5
                    : 2.5,
                glowRadius: _glowRadius,
                glowColor: _UXColors.captured,
              ),
            ),
          ),
        ),

        // ── Corner Bracket Frame ──────────────────────────────────
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _glowController,
                _pulseController,
                _spinController,
                _progressController,
              ]),
              builder: (context, _) {
                final scale = isStabilizing ? _pulseAnimation.value : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: CustomPaint(
                    painter: CornerBracketPainter(
                      isSelfie: isSelfie,
                      isQr: isQr,
                      color: _borderColor,
                      glowColor: _captureState == _CaptureState.captured
                          ? _UXColors.captured
                          : Colors.transparent,
                      glowRadius: _glowRadius,
                      spinValue: isStabilizing ? _spinController.value : 0.0,
                      progressValue: isStabilizing
                          ? _progressAnimation.value
                          : (isCaptured ? 1.0 : 0.0),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // ── Screen Flash (nháy sáng 0.2s khi chụp) ──────────────
        if (_showScreenFlash)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _screenFlashAnimation,
                builder: (ctx, _) => Container(
                  color: _UXColors.captured.withValues(
                    alpha: _screenFlashAnimation.value,
                  ),
                ),
              ),
            ),
          ),

        // ── Liveness Screen Flash ────────────────────────────────
        if (_livenessFlashColor != null)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: _livenessFlashColor!.withValues(alpha: 0.95),
              ),
            ),
          ),

        // ── Laser Scan Line ──────────────────────────────────────
        if (!_hasCaptured)
          Positioned.fill(
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final bw = isSelfie
                    ? constraints.maxWidth * 0.72
                    : isQr
                    ? constraints.maxWidth * 0.65
                    : constraints.maxWidth * 0.84;
                final bh = isSelfie
                    ? bw * 1.25
                    : isQr
                    ? bw
                    : bw * 0.63;
                final centerY =
                    constraints.maxHeight *
                    (isSelfie
                        ? 0.44
                        : isQr
                        ? 0.43
                        : 0.46);
                final top = centerY - bh / 2;

                return Stack(
                  children: [
                    AnimatedBuilder(
                      animation: _laserAnimation,
                      builder: (context, _) => Positioned(
                        top: top + (_laserAnimation.value * bh),
                        left: (constraints.maxWidth - bw) / 2,
                        width: bw,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                _borderColor.withValues(alpha: 0.9),
                                Colors.white.withValues(alpha: 0.8),
                                _borderColor.withValues(alpha: 0.9),
                                Colors.transparent,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: _borderColor.withValues(alpha: 0.6),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

        // ── Unified Bottom Panel (Professional) & Error Banner ──
        Positioned(
          bottom: 32,
          left: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildErrorBanner(),
              const SizedBox(height: 16),
              _buildBottomPanel(isSelfie: isSelfie, isQr: isQr),
            ],
          ),
        ),
      ],
    );
  }

  // ── Professional Bottom Panel ──────────────────────────────
  Widget _buildBottomPanel({required bool isSelfie, required bool isQr}) {
    final hasError = _errorType.isError;
    final isCaptured = _captureState == _CaptureState.captured;
    final isStabilizing = _captureState == _CaptureState.stabilizing;

    // Màu viền card phản hồi trạng thái
    final Color cardBorder = isCaptured
        ? _UXColors.captured
        : hasError
        ? _errorType.bannerBorder
        : AppTheme.kBrandLight.withValues(alpha: 0.25);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header Row ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.kBrandDeep.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isQr
                        ? CupertinoIcons.qrcode
                        : isSelfie
                        ? CupertinoIcons.person_fill
                        : CupertinoIcons.doc_text_fill,
                    color: AppTheme.kBrandLight,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 12,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Stability progress ring (nhỏ gọn)
                if (!isSelfie && !isQr && !_hasCaptured)
                  _buildCompactProgressRing(),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Divider ─────────────────────────────────────────
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.06),
            margin: const EdgeInsets.symmetric(horizontal: 18),
          ),

          // ── Status / Error Row ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 11, 18, 14),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Row(
                key: ValueKey(_errorType.isError ? _errorType : _captureState),
                children: [
                  // Status dot
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCaptured
                          ? _UXColors.captured
                          : hasError
                          ? _errorType.textColor
                          : isStabilizing
                          ? _UXColors.stabilizing
                          : AppTheme.kBrandLight,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasError ? _errorType.message : _statusText,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: hasError
                            ? _errorType.textColor
                            : isCaptured
                            ? _UXColors.captured
                            : Colors.white.withValues(alpha: 0.85),
                        height: 1.3,
                      ),
                    ),
                  ),

                  // Gate dots row (mặt trước / mặt sau)
                  if (!isSelfie && !isQr)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildGateDot(_gatePosition),
                        _buildGateDot(_gateBlur),
                        _buildGateDot(_gateGlare),
                        if (widget.scanType == OcrScanType.front)
                          _buildGateDot(_gateTilt),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Chấm tròn nhỏ thể hiện gate pass/fail – thay thế chip to
  Widget _buildGateDot(bool passed) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 7,
      height: 7,
      margin: const EdgeInsets.only(left: 5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: passed
            ? _UXColors.captured
            : _hasDetectedText
            ? AppTheme.kError
            : Colors.white.withValues(alpha: 0.2),
      ),
    );
  }

  // Compact progress ring thay cho stability badge to
  Widget _buildCompactProgressRing() {
    final progress = (_stableFrameCount / _requiredStableFrames).clamp(
      0.0,
      1.0,
    );
    return SizedBox(
      width: 32,
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 2.5,
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
              _captureState == _CaptureState.stabilizing
                  ? _UXColors.stabilizing
                  : _UXColors.captured,
            ),
          ),
          if (_captureState == _CaptureState.stabilizing)
            const CupertinoActivityIndicator(radius: 6, color: Colors.white54),
          if (_captureState == _CaptureState.captured)
            const Icon(
              CupertinoIcons.checkmark,
              size: 14,
              color: _UXColors.captured,
            ),
        ],
      ),
    );
  }

  // ── Status Bar helpers ─────────────────────────────────────
  // ignore: unused_element
  Color _statusBgColor() {
    switch (_captureState) {
      case _CaptureState.idle:
        return Colors.black.withValues(alpha: 0.45);
      case _CaptureState.stabilizing:
        return _UXColors.stabilizing.withValues(alpha: 0.2);
      case _CaptureState.captured:
        return _UXColors.captured.withValues(alpha: 0.2);
    }
  }

  // ignore: unused_element
  Color _statusTextColor() {
    switch (_captureState) {
      case _CaptureState.idle:
        return Colors.white;
      case _CaptureState.stabilizing:
        return _UXColors.stabilizing;
      case _CaptureState.captured:
        return _UXColors.captured;
    }
  }

  // ignore: unused_element
  Widget _statusIcon() {
    switch (_captureState) {
      case _CaptureState.idle:
        return const SizedBox(
          width: 12,
          height: 12,
          child: CupertinoActivityIndicator(radius: 6, color: Colors.white),
        );
      case _CaptureState.stabilizing:
        return const Icon(
          CupertinoIcons.timer,
          size: 14,
          color: _UXColors.stabilizing,
        );
      case _CaptureState.captured:
        return const Icon(
          CupertinoIcons.checkmark_circle_fill,
          size: 14,
          color: _UXColors.captured,
        );
    }
  }

  // ignore: unused_element
  Widget _buildGateChip(IconData icon, String label, bool passed) {
    final bool active = _hasDetectedText;
    final Color color;
    final Color bg;
    final IconData displayIcon;

    if (passed) {
      color = _UXColors.captured;
      bg = _UXColors.captured.withValues(alpha: 0.18);
      displayIcon = CupertinoIcons.checkmark_circle_fill;
    } else if (active) {
      color = AppTheme.kError; // Coral Red
      bg = AppTheme.kError.withValues(alpha: 0.12);
      displayIcon = CupertinoIcons.xmark_circle_fill;
    } else {
      color = Colors.white54;
      bg = Colors.black38;
      displayIcon = icon;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(displayIcon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ── Error Banner (Toast mượt mà, Glassmorphism) ────────────
  // ignore: unused_element
  Widget _buildErrorBanner() {
    final hasError = _errorType.isError;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
              .animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: hasError
          ? Container(
              key: ValueKey(_errorType),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _errorType.bannerBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _errorType.bannerBorder, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    _errorType.message.substring(0, 2), // Emoji prefix
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _errorType.message.length > 2
                          ? _errorType.message.substring(2).trim()
                          : _errorType.message,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _errorType.textColor,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(key: ValueKey('no-error')),
    );
  }

  // ── Stability Badge ────────────────────────────────────────
  // ignore: unused_element
  Widget _buildStabilityBadge() {
    final progress = (_stableFrameCount / _requiredStableFrames).clamp(
      0.0,
      1.0,
    );
    final color = _captureState == _CaptureState.stabilizing
        ? _UXColors.stabilizing
        : _UXColors.captured;

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.6),
        border: Border.all(color: Colors.white24),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation(color),
          ),
          const Icon(CupertinoIcons.camera_fill, color: Colors.white, size: 14),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Smart Hint Builder (theo Design Guidelines)
  // ══════════════════════════════════════════════════════════════
  String _buildSmartHint(
    _GateStatus pos,
    _GateStatus tilt,
    _GateStatus blur,
    _GateStatus glare,
    OcrScanType type,
  ) {
    // Priority order: position > glare > blur > tilt
    if (glare == _GateStatus.fail) {
      return 'Ánh sáng quá mạnh, vui lòng né đèn chiếu trực tiếp';
    }
    if (blur == _GateStatus.fail) return 'Giữ yên điện thoại trong 2 giây';
    if (pos == _GateStatus.fail) {
      if (type == OcrScanType.back) return 'Vui lòng lật sang mặt sau của CCCD';
      return 'Hãy đưa toàn bộ thẻ vào trong khung hình';
    }
    if (tilt == _GateStatus.fail) return 'Giữ thẻ cân bằng, tránh xết góc';
    return 'Giữ yên... đang chụp tự động';
  }

  // ══════════════════════════════════════════════════════════════
  // Mismatch / QR≠OCR Dialog
  // ══════════════════════════════════════════════════════════════
  // ignore: unused_element
  void _showMismatchDialog() {
    if (!mounted) return;
    unawaited(HapticFeedback.mediumImpact());
    unawaited(_controller?.pausePreview());
    final bool isThirdAttempt = _failedAttempts >= 3;
    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: false,
        enableDrag: false,
        builder: (ctx) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.exclamationmark_triangle_fill,
                  color: AppTheme.kError,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Lỗi xác thực',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isThirdAttempt
                    ? 'Xác thực thất bại nhiều lần. Vui lòng thử lại sau hoặc liên hệ hỗ trợ.'
                    : 'Dữ liệu khuôn mặt không khớp. Vui lòng quét lại.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Color(0xFF4B5563)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  color: AppTheme.kError,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (isThirdAttempt) {
                      Navigator.pop(context); // Thoát về màn trước
                    } else {
                      _resetForRetry();
                    }
                  },
                  child: Text(
                    isThirdAttempt ? 'Đóng' : 'Thử lại',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // Timeout Dialog (15s Liveness)
  // ══════════════════════════════════════════════════════════════
  void _showLivenessTimeoutDialog() {
    if (!mounted) return;
    unawaited(HapticFeedback.mediumImpact());
    unawaited(_controller?.pausePreview());
    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: false,
        enableDrag: false,
        builder: (ctx) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 64,
                height: 64,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFED7AA), width: 2),
                ),
                child: const Icon(
                  CupertinoIcons.clock_fill,
                  color: Color(0xFFF97316),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Xác thực quá lâu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Hệ thống không thể nhận diện khuôn mặt. Vui lòng đảm bảo bạn đang ở nơi có đủ ánh sáng và không đeo kính râm hay khẩu trang.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  _resetLivenessState('Đưa khuôn mặt vào khung hình');
                  _livenessTimeoutTimer?.cancel();
                  _livenessTimeoutTimer = Timer(
                    const Duration(seconds: 15),
                    () {
                      if (!_hasCaptured && mounted) {
                        _showLivenessTimeoutDialog();
                      }
                    },
                  );
                  unawaited(_controller?.resumePreview());
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.kBrand, AppTheme.kBrandLight],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.kBrand.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.refresh_thick,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Thử lại',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context); // Trở về màn hình trước
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Bỏ qua',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
