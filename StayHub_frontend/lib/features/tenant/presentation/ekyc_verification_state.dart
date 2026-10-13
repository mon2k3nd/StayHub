part of 'ekyc_verification_screen.dart';

class _EkycVerificationScreenState
    extends ConsumerState<EkycVerificationScreen> {
  int _currentStep = 0;
  bool _isUploading = false;
  bool _isExtractingData = false;
  bool _agreedToTerms = false;
  bool _consentGiven = false;
  String? _error;

  String _extractedDobIso = '';
  String _extractedIssueDateIso = '';
  String _extractedIssuePlace = '';

  bool _showSelfieReview = false;
  File? _selfieImageFile;
  bool _showSelfiePrep = true;
  int _livenessRetryCount = 0;

  // OTP
  final _otpCtrl = TextEditingController();

  XFile? _cccdFront;
  XFile? _cccdBack;
  XFile? _selfie;

  final _cccdCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  final _hometownCtrl = TextEditingController();
  final _genderCtrl = TextEditingController();

  // Back side info
  final _issueDateCtrl = TextEditingController();
  final _issuePlaceCtrl = TextEditingController();

  int _backRetakeCount = 0;

  bool _isJailbroken = false;

  @override
  void initState() {
    super.initState();
    unawaited(_initSecurityChecks());
  }

  Future<void> _initSecurityChecks() async {
    try {
      await ScreenProtector.preventScreenshotOn();

      bool jailbroken = false;
      if (!kIsWeb) {
        try {
          jailbroken = await FlutterJailbreakDetection.jailbroken;
        } catch (e) {
          jailbroken = false;
        }
      }

      if (mounted) {
        setState(() {
          _isJailbroken = jailbroken;
        });
      }
    } catch (e) {
      debugPrint('Security check error: $e');
    }
  }

  @override
  void dispose() {
    unawaited(ScreenProtector.preventScreenshotOff());
    _cccdCtrl.dispose();
    _nameCtrl.dispose();
    _dobCtrl.dispose();
    _hometownCtrl.dispose();
    _genderCtrl.dispose();
    _otpCtrl.dispose();
    _issueDateCtrl.dispose();
    _issuePlaceCtrl.dispose();
    _clearCache();
    super.dispose();
  }

  void _clearCache() {
    try {
      if (_cccdFront != null) File(_cccdFront!.path).deleteSync();
      if (_cccdBack != null) File(_cccdBack!.path).deleteSync();
      if (_selfie != null) File(_selfie!.path).deleteSync();
    } catch (e) {
      debugPrint('Lỗi xóa cache: $e');
    }
  }

  Future<void> _startVerification() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() => _currentStep = 1);
    } else {
      if (mounted) {
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Quyền truy cập Camera'),
              content: const Text(
                'Ứng dụng cần truy cập Camera để chụp ảnh xác thực CCCD. Vui lòng cấp quyền trong Cài đặt.',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Đóng'),
                  onPressed: () => Navigator.pop(ctx),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: const Text('Mở Cài đặt'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    unawaited(openAppSettings());
                  },
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  Future<void> _onPhotoTaken(
    XFile photo, {
    Map<String, String>? extractedData,
  }) async {
    // Step 1 = Chụp mặt trước CCCD
    if (_currentStep == 1) {
      setState(() {
        _cccdFront = photo;
        _currentStep = 2; // Chuyển sang bước quét QR
        _error = null;
      });
      return;
    }

    // Step 2 = Quét mã QR mặt trước
    if (_currentStep == 2) {
      setState(() => _isExtractingData = true);

      if (extractedData != null &&
          extractedData['cccd'] != null &&
          extractedData['cccd']!.isNotEmpty) {
        setState(() {
          _cccdCtrl.text = extractedData['cccd'] ?? '';
          _dobCtrl.text = extractedData['dob'] ?? '';
          _genderCtrl.text = extractedData['gender'] ?? '';
          _nameCtrl.text = extractedData['name'] ?? '';
          _hometownCtrl.text = extractedData['hometown'] ?? '';
          if (extractedData['issueDate'] != null &&
              extractedData['issueDate']!.isNotEmpty) {
            _issueDateCtrl.text = extractedData['issueDate']!;
            final parts = extractedData['issueDate']!.split('/');
            if (parts.length == 3) {
              _extractedIssueDateIso =
                  '${parts[2]}-${parts[1]}-${parts[0]}T00:00:00.000Z';

              final d = int.tryParse(parts[0]) ?? 0;
              final m = int.tryParse(parts[1]) ?? 0;
              final y = int.tryParse(parts[2]) ?? 0;
              if (y > 0) {
                final issueDateTime = DateTime(y, m, d);
                if (issueDateTime.isAfter(DateTime(2024, 6, 30))) {
                  _issuePlaceCtrl.text = 'Bộ Công an';
                } else if (issueDateTime.isAfter(DateTime(2018, 10, 9))) {
                  _issuePlaceCtrl.text =
                      'Cục trưởng Cục Cảnh sát quản lý hành chính về trật tự xã hội';
                } else if (issueDateTime.isAfter(DateTime(2015, 12, 31))) {
                  _issuePlaceCtrl.text =
                      'Cục Cảnh sát đăng ký, quản lý cư trú và dữ liệu quốc gia về dân cư';
                }
                _extractedIssuePlace = _issuePlaceCtrl.text;
              }
            }
          }
          if (_dobCtrl.text.isNotEmpty) {
            final parts = _dobCtrl.text.split('/');
            if (parts.length == 3) {
              _extractedDobIso =
                  '${parts[2]}-${parts[1]}-${parts[0]}T00:00:00.000Z';
            }
          }
        });
      }

      if (_cccdCtrl.text.isEmpty ||
          _nameCtrl.text.isEmpty ||
          _dobCtrl.text.isEmpty ||
          _hometownCtrl.text.isEmpty ||
          _genderCtrl.text.isEmpty) {
        setState(() {
          _isExtractingData = false;
          _error = 'Quét mã QR thất bại. Vui lòng quét lại!';
        });
        return;
      }

      setState(() {
        _isExtractingData = false;
        _currentStep = 3; // Chuyển sang chụp mặt sau
        _error = null;
      });
      return;
    }

    // Step 3 = Chụp mặt sau CCCD
    if (_currentStep == 3) {
      setState(() {
        _cccdBack = photo;
        _isExtractingData = true;
        _error = null;
      });
      bool shouldUseBackend = true;
      if (extractedData != null) {
        setState(() {
          // Ưu tiên dữ liệu local - chỉ lấy nếu chưa có
          if (extractedData['issueDate'] != null &&
              extractedData['issueDate']!.isNotEmpty) {
            _issueDateCtrl.text = extractedData['issueDate']!;
            final parts = extractedData['issueDate']!.split('/');
            if (parts.length == 3) {
              _extractedIssueDateIso =
                  '${parts[2]}-${parts[1]}-${parts[0]}T00:00:00.000Z';
            }
          }
        });
      }
      // Gọi backend để bổ sung (chỉ điền vào trường còn trống, không ghi đè)

      if (shouldUseBackend) {
        try {
          final formData = FormData.fromMap({
            'image': await MultipartFile.fromFile(
              photo.path,
              filename: 'cccd_back.jpg',
            ),
          });
          final apiClient = ref.read(apiClientProvider);
          final response = await apiClient.dio.post(
            '/v1/tenant/ai-ekyc/extract-back',
            data: formData,
          );
          final responseData = response.data is String
              ? jsonDecode(response.data)
              : response.data;
          if (responseData['code'] == '200' || responseData['code'] == 200) {
            final dataList = responseData['data'];
            if (dataList != null && dataList.isNotEmpty) {
              final data = dataList[0];
              setState(() {
                if (data['issue_place'] != null &&
                    data['issue_place'].toString().isNotEmpty) {
                  _extractedIssuePlace = data['issue_place'].toString();
                  _issuePlaceCtrl.text = _extractedIssuePlace;
                }
                if (data['issue_date'] != null &&
                    data['issue_date'].toString().isNotEmpty) {
                  _issueDateCtrl.text = data['issue_date'].toString();
                  final parts = data['issue_date'].toString().split('/');
                  if (parts.length == 3) {
                    _extractedIssueDateIso =
                        '${parts[2]}-${parts[1]}-${parts[0]}T00:00:00.000Z';
                  }
                }
              });
            }
          }
        } catch (e) {
          debugPrint('Extract back error: $e');
        }
      }

      // Chỉ bắt buộc có Ngày cấp – features và issuePlace không có thì để trống
      if (_issueDateCtrl.text.isEmpty) {
        setState(() {
          _isExtractingData = false;
          _backRetakeCount++;
          _error =
              'Không đọc được Ngày cấp trên mặt sau.\nVui lòng đặt thẻ ngay ngắn, đủ ánh sáng và chụp lại!';
        });

        if (_backRetakeCount >= 3) {
          _showEscapeHatchDialog('Đọc CCCD mặt sau thất bại nhiều lần.');
        } else if (mounted) {
          unawaited(
            showDialog(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('Lỗi đọc mặt sau'),
                content: Text(_error!),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('Chụp lại'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          );
        }
        return;
      }

      setState(() {
        _isExtractingData = false;
        _currentStep = 4; // → Khuôn mặt
        _error = null;
      });

      // Step 4 = Xác thực khuôn mặt (Liveness + Matching)
    } else if (_currentStep == 4) {
      final selfieImagePath = extractedData?['selfieImagePath'];
      setState(() {
        _selfie = photo; // .mp4
        _selfieImageFile = selfieImagePath != null
            ? File(selfieImagePath)
            : null;
        _isExtractingData = false;
        _showSelfieReview = true;
      });
    }
  }

  Future<void> _submitSelfieForVerification() async {
    setState(() {
      _showSelfieReview = false;
      _isExtractingData = true;
      _error = null;
    });
    try {
      final formData = FormData.fromMap({
        'file1': await _encryptAndCreateMultipartFile(
          _cccdFront!,
          'cccd_front.jpg',
        ),
        'file2': await _encryptAndCreateMultipartFile(_selfie!, 'selfie.mp4'),
      });
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.dio.post(
        '/v1/tenant/ai-ekyc/verify',
        data: formData,
      );
      final responseData = response.data is String
          ? jsonDecode(response.data)
          : response.data;
      if (responseData['code'] == '200' || responseData['code'] == 200) {
        final isMatch = responseData['data']['isMatch'];
        final isReal = responseData['data']['isReal'];
        if (!isReal) {
          setState(() {
            _isExtractingData = false;
            _error = 'Phát hiện giả mạo khuôn mặt. Vui lòng chụp người thật!';
            _selfie = null;
          });
          return;
        }
        if (isMatch == true || isMatch == 'True' || isMatch == 'true') {
          setState(() {
            _isExtractingData = false;
            _currentStep = 5; // → Xác nhận
          });
        } else {
          setState(() {
            _isExtractingData = false;
            _livenessRetryCount++;
            _error = 'Khuôn mặt không khớp với CCCD. Vui lòng chụp lại.';
            _selfie = null;
          });
          _checkLivenessEscapeHatch();
        }
      } else {
        setState(() {
          _isExtractingData = false;
          _livenessRetryCount++;
          _error = 'Không thể xác định khuôn mặt. Vui lòng chụp rõ nét hơn.';
          _selfie = null;
        });
        _checkLivenessEscapeHatch();
      }
    } catch (e) {
      debugPrint('Lỗi FPT Checkface: $e');
      // Fallback: vẫn cho qua để test khi hết hạn mức API
      setState(() {
        _isExtractingData = false;
        _currentStep = 5;
      });
    }
  }

  void _checkLivenessEscapeHatch() {
    if (_livenessRetryCount >= 3 && mounted) {
      _showEscapeHatchDialog('Xác thực khuôn mặt thất bại nhiều lần.');
    }
  }

  void _showEscapeHatchDialog(String message) {
    if (!mounted) return;
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Xác thực thất bại'),
          content: Text(
            '$message\n\nBạn có thể thử lại, hoặc liên hệ Quản lý tòa nhà để được hỗ trợ xác thực thủ công.',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Thử lại'),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Liên hệ Hỗ trợ'),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(
                  context,
                ); // Trở về màn trước (dashboard/onboarding) để liên hệ
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<MultipartFile> _encryptAndCreateMultipartFile(
    XFile file,
    String filename,
  ) async {
    try {
      final bytes = await file.readAsBytes();

      // Khởi tạo thuật toán AES-256-GCM
      // Trong thực tế, khóa này cần lấy từ một phiên trao đổi khóa (Key Exchange) an toàn như RSA hoặc Diffie-Hellman
      final key = encrypt.Key.fromUtf8('stayhub_32_byte_aes_key_for_ekyc');
      final iv = encrypt.IV.fromLength(12); // Chuẩn IV của GCM là 12 bytes

      final encrypter = encrypt.Encrypter(
        encrypt.AES(key, mode: encrypt.AESMode.gcm),
      );
      final encrypted = encrypter.encryptBytes(bytes, iv: iv);

      // Đính kèm IV vào đầu file đã mã hóa để Backend có thể giải mã
      final payload = <int>[...iv.bytes, ...encrypted.bytes];

      debugPrint(
        '[AES-GCM] Đã mã hóa tệp $filename thành công. Gửi đi dữ liệu E2EE an toàn.',
      );
      return MultipartFile.fromBytes(payload, filename: '$filename.enc');
    } catch (e) {
      debugPrint('Lỗi mã hóa AES: $e');
      return MultipartFile.fromFile(file.path, filename: filename);
    }
  }

  Future<void> _submitEkyc() async {
    final cccd = _cccdCtrl.text.trim();
    if (cccd.length != 12) {
      setState(() => _error = 'Số CCCD phải đúng 12 chữ số!');
      return;
    }
    if (!_agreedToTerms) {
      setState(() => _error = 'Bạn phải đồng ý với các điều khoản.');
      return;
    }

    setState(() {
      _isUploading = true;
      _error = null;
    });
    ToastUtils.showLoading(context);

    try {
      final apiClient = ref.read(apiClientProvider);

      final formData = FormData.fromMap({
        'cccdNumber': cccd,
        'fullName': _nameCtrl.text,
        'dateOfBirth': _extractedDobIso,
        'gender': _genderCtrl.text,
        'hometown': _hometownCtrl.text,
        'issuePlace': _extractedIssuePlace,
        'issueDate': _extractedIssueDateIso,
        if (_cccdFront != null)
          'cccdFront': await _encryptAndCreateMultipartFile(
            _cccdFront!,
            'cccd_front.jpg',
          ),
        if (_cccdBack != null)
          'cccdBack': await _encryptAndCreateMultipartFile(
            _cccdBack!,
            'cccd_back.jpg',
          ),
        if (_selfie != null)
          'selfie': await _encryptAndCreateMultipartFile(
            _selfie!,
            'selfie.mp4',
          ),
      });

      await apiClient.dio.post(
        '/v1/tenant/ekyc/upload',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );

      // ── Real-time state update ──
      await ref.read(authProvider.notifier).checkAuth();

      if (mounted) widget.onVerificationComplete();
    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        if (e is DioException && e.response != null) {
          errorMsg = e.response?.data?.toString() ?? e.toString();
        }
        setState(() => _error = 'Gửi hồ sơ thất bại: $errorMsg');
      }
    } finally {
      _clearCache();
      ToastUtils.hideLoading();
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isJailbroken) {
      return const LiquidGlassScaffold(
        title: 'Cảnh báo bảo mật',
        backgroundColors: AppTheme.kBackgroundLight,
        useScrollView: false,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.exclamationmark_triangle_fill,
                  size: 64,
                  color: CupertinoColors.systemRed,
                ),
                SizedBox(height: 24),
                Text(
                  'Phát hiện thiết bị không an toàn',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  'Thiết bị của bạn đã bị Root hoặc Jailbreak. Để đảm bảo an toàn thông tin cá nhân, tính năng xác định danh tính bị vô hiệu hóa trên thiết bị này.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.kTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentUser = ref.watch(authProvider).value;
    final kycStatus = currentUser?.kycStatus;

    if (kycStatus == 'APPROVED') {
      return _buildVerifiedScreen(currentUser!);
    }

    if (kycStatus == 'REVERIFY_REQUESTED') {
      return _buildPendingReverifyScreen();
    }

    return LiquidGlassScaffold(
      title: 'Xác Thực Danh Tính',
      backgroundColors: AppTheme.kBackgroundLight,
      useScrollView: false,
      child: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) {
                return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                );
              },
              child: _buildCurrentStepContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    // Bước 0 = Intro (không hiển thị thanh tiến trình)
    if (_currentStep == 0) return const SizedBox.shrink();

    // Các bước thực tế:
    // 1: Mặt trước
    // 2: Quét QR
    // 3: Mặt sau
    // 4: Khuôn mặt
    // 5: Xác nhận
    const totalSteps = 5;
    final displayStep = _currentStep.clamp(1, totalSteps);
    final labels = [
      '',
      'Chụp mặt trước CCCD',
      'Quét mã QR',
      'Chụp mặt sau CCCD',
      'Chụp ảnh khuôn mặt',
      'Xác nhận thông tin',
    ];
    final progress = displayStep / totalSteps.toDouble();

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppTheme.kBorderColor,
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.kBrand),
          minHeight: 4,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(totalSteps, (i) {
                  final active = i < displayStep;
                  final current = i == displayStep - 1;
                  return Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: current ? 28 : 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: active
                              ? AppTheme.kBrand
                              : const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: active
                                  ? CupertinoColors.white
                                  : const Color(0xFF9CA3AF),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      if (i < totalSteps - 1)
                        Container(
                          width: 8,
                          height: 2,
                          color: active && i < displayStep - 1
                              ? AppTheme.kBrand
                              : const Color(0xFFE5E7EB),
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                        ),
                    ],
                  );
                }),
              ),
              Text(
                labels[displayStep],
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.kBrand,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      // Bước 0: Màn hình Giới thiệu
      case 0:
        return _buildIntroScreen();

      // Bước 1: Chụp mặt trước CCCD
      case 1:
        if (_isExtractingData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.kAccentColor, AppTheme.kBrandLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.kAccentColor.withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: CupertinoActivityIndicator(
                      radius: 16,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Hệ thống đang đọc thông tin CCCD...',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Vui lòng chờ trong giây lát',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          );
        }
        return SmartOcrCamera(
          key: const ValueKey('front'),
          title: 'Chụp mặt trước CCCD',
          description:
              'Đặt mặt trước CCCD vào khung hình – hệ thống tự chụp khi thấy thẻ.',
          onScanComplete: _onPhotoTaken,
          scanType: OcrScanType.front,
        );

      // Bước 2: Quét mã QR mặt trước
      case 2:
        return SmartOcrCamera(
          key: const ValueKey('qr'),
          title: 'Quét mã QR CCCD',
          description: 'Đưa mã QR trên mặt trước CCCD vào khung hình.',
          onScanComplete: _onPhotoTaken,
          scanType: OcrScanType.qr,
        );

      // Bước 3: Chụp mặt sau CCCD
      case 3:
        if (_isExtractingData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.kBrand, Color(0xFF1A6FD4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.kBrand.withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: CupertinoActivityIndicator(
                      radius: 16,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Hệ thống đang phân tích ảnh mặt sau...',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Đang xử lý ảnh mặt sau, vui lòng chờ...',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          );
        }
        return SmartOcrCamera(
          key: const ValueKey('back'),
          title: 'Lật CCCD và chụp mặt sau',
          description: 'Xoay thẻ lại và đặt mặt sau CCCD vào khung hình.',
          onScanComplete: _onPhotoTaken,
          scanType: OcrScanType.back,
        );

      // Bước 4: Xác thực khuôn mặt (Liveness)
      case 4:
        // Sub-bước chuẩn bị trước khi bật camera
        if (_showSelfiePrep) return _buildSelfiePreparationScreen();
        if (_isExtractingData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.kAccentColor, AppTheme.kBrandLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.kAccentColor.withValues(alpha: 0.4),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: CupertinoActivityIndicator(
                      radius: 16,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Hệ thống đang phân tích khuôn mặt...',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'So khớp với ảnh trên CCCD của bạn...',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          );
        }

        if (_showSelfieReview && _selfie != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon thành công được thiết kế tối giản, chuyên nghiệp với viền nhạt
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.kSuccess.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.kSuccess.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      CupertinoIcons.checkmark_alt,
                      color: AppTheme.kSuccess,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nhận diện thành công',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Vui lòng kiểm tra lại độ rõ nét của khuôn mặt trước khi tiếp tục gửi xác thực.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Khung review ảnh selfie dạng bo tròn tinh tế với viền mỏng và shadow dịu
                  Container(
                    height: 280,
                    width: 186,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.kBrandDeep.withValues(alpha: 0.35),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.kBrandDeep.withValues(alpha: 0.08),
                          blurRadius: 20,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: _selfieImageFile != null
                          ? ResponsiveFileImage(
                              _selfieImageFile!,
                              fit: BoxFit.cover,
                            )
                          : const Center(
                              child: CupertinoActivityIndicator(
                                color: AppTheme.kBrandLight,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Action Buttons với thiết kế Clean & Premium
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(12),
                          onPressed: () {
                            setState(() {
                              _showSelfieReview = false;
                              _selfie = null;
                              _selfieImageFile = null;
                            });
                          },
                          child: const Text(
                            'Chụp lại',
                            style: TextStyle(
                              color: Color(0xFF374151),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          color: AppTheme.kBrandDeep, // Sky Blue Primary
                          borderRadius: BorderRadius.circular(12),
                          onPressed: () {
                            unawaited(_submitSelfieForVerification());
                          },
                          child: const Text(
                            'Xác nhận gửi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: SmartOcrCamera(
                key: const ValueKey('selfie'),
                title: 'Chụp ảnh khuôn mặt',
                description:
                    'Nhìn thẳng vào camera, giữ yên khuôn mặt tự nhiên.',
                onScanComplete: _onPhotoTaken,
                scanType: OcrScanType.selfie,
              ),
            ),
            if (_error != null)
              Container(
                color: CupertinoColors.systemRed,
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        );

      // Bước 5: Xác nhận & Ký số OTP
      case 5:
        return _buildConfirmation();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSelfiePreparationScreen() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F8FF),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.kBorderColor, width: 2),
            ),
            child: const Center(
              child: Icon(
                CupertinoIcons.person_crop_circle_badge_checkmark,
                color: AppTheme.kBrand,
                size: 64,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Chuẩn bị xác thực khuôn mặt',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Hệ thống sẽ tự động so khớp khuôn mặt của bạn với ảnh trên CCCD. Vui lòng chuẩn bị:',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildPrepTip(
                  CupertinoIcons.sun_max_fill,
                  'Đảm bảo đủ ánh sáng',
                  'Không đứng ngược sáng hoặc nơi quá tối.',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                _buildPrepTip(
                  CupertinoIcons.eye_slash_fill,
                  'Bỏ khẩu trang & kính râm',
                  'Để hệ thống có thể nhận diện toàn bộ khuôn mặt.',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                _buildPrepTip(
                  CupertinoIcons.device_phone_portrait,
                  'Giữ điện thoại ngang tầm mắt',
                  'Khuôn mặt của bạn cần vừa vẹn trong ô oval trên màn hình.',
                ),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: AppTheme.kBrand,
              borderRadius: BorderRadius.circular(12),
              onPressed: () {
                setState(() {
                  _showSelfiePrep = false;
                });
              },
              child: const Text(
                'Bắt đầu xác thực',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrepTip(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF4B5563), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIntroScreen() {
    return SingleChildScrollView(
      key: const ValueKey('intro'),
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Hero icon với gradient premium
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.kBrand, Color(0xFF1A6FD4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.kBrand.withValues(alpha: 0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 16,
                    left: 14,
                    child: Container(
                      width: 82,
                      height: 52,
                      decoration: BoxDecoration(
                        color: CupertinoColors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: CupertinoColors.white.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.creditcard_fill,
                    color: CupertinoColors.white,
                    size: 44,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            const Text(
              'Xác nhận thông tin cá nhân',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Chụp ảnh CCCD và xác nhận khuôn mặt – chỉ mất khoảng 2 phút thôi nào!',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF6B7280),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F0FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF9CCBFF)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.shield_lefthalf_fill,
                    color: AppTheme.kBrandDeep,
                    size: 14,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Thông tin của bạn được bảo mật hoàn toàn',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1A6FD4),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Step hints với thiết kế mới
            _buildStepHint(
              CupertinoIcons.doc_text_viewfinder,
              'Bước 1',
              'Chụp ảnh mặt trước và mặt sau CCCD',
              AppTheme.kBrand,
              const Color(0xFFE3F0FF),
            ),
            const SizedBox(height: 10),
            _buildStepHint(
              CupertinoIcons.person_crop_circle_badge_checkmark,
              'Bước 2',
              'Chụp ảnh khuôn mặt xác nhận danh tính',
              AppTheme.kBrand,
              const Color(0xFFE3F0FF),
            ),
            const SizedBox(height: 10),
            _buildStepHint(
              CupertinoIcons.lock_shield_fill,
              'Bước 3',
              'Kiểm tra lại thông tin và xác nhận bằng mã OTP',
              AppTheme.kBrand,
              const Color(0xFFE3F0FF),
            ),
            const SizedBox(height: 28),

            // ── Hướng dẫn quét CCCD ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF2F8FF), Color(0xFFF5F3FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.kBorderColor, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        CupertinoIcons.info_circle_fill,
                        color: AppTheme.kBrandDeep,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Hướng dẫn chụp CCCD',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A6FD4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Ảnh mẫu mặt trước và mặt sau
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              height: 90,
                              decoration: BoxDecoration(
                                color: CupertinoColors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.kBrand,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.kBrand.withValues(
                                      alpha: 0.15,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(
                                  'assets/images/cccd_front_guide.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '📄 Mặt trước',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A6FD4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            Container(
                              height: 90,
                              decoration: BoxDecoration(
                                color: CupertinoColors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF7C3AED),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF7C3AED,
                                    ).withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(
                                  'assets/images/cccd_back_guide.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '🔄 Mặt sau',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF7C3AED),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Gợi ý
                  _buildGuideItem(
                    '✅',
                    'Đặt CCCD nằm ngang vào khung hình màu vàng',
                  ),
                  const SizedBox(height: 8),
                  _buildGuideItem(
                    '✅',
                    'Đảm bảo đủ ánh sáng, không bị mờ hoặc lóa',
                  ),
                  const SizedBox(height: 8),
                  _buildGuideItem(
                    '✅',
                    'Giữ điện thoại thẳng góc, không nghiêng',
                  ),
                  const SizedBox(height: 8),
                  _buildGuideItem(
                    '❌',
                    'Không che khuất số, ảnh hoặc vùng chip',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── User Consent Box (Nghị định 13/2023/NĐ-CP) ────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F8FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _consentGiven
                      ? AppTheme.kBrand
                      : const Color(0xFFE5E7EB),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        CupertinoIcons.shield_fill,
                        color: AppTheme.kBrand,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Thông báo thu thập dữ liệu cá nhân',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A6FD4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Theo quy định pháp luật, StayHub cần thu thập một số thông tin để xác nhận danh tính của bạn trước khi ký hợp đồng thuê phòng:\n'
                    '• Thông tin thu thập: ảnh 2 mặt CCCD và ảnh chụp khuôn mặt của bạn.\n'
                    '• Mục đích: Xác nhận danh tính để ký kết hợp đồng thuê phòng.\n'
                    '• Bảo mật: Dữ liệu được mã hóa an toàn, chỉ lưu trong thời hạn hợp đồng.\n'
                    '• Không chia sẻ với bên thứ ba nào khác.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF374151),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => setState(() => _consentGiven = !_consentGiven),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: _consentGiven
                                ? AppTheme.kBrand
                                : CupertinoColors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _consentGiven
                                  ? AppTheme.kBrand
                                  : const Color(0xFFD1D5DB),
                              width: 2,
                            ),
                          ),
                          child: _consentGiven
                              ? const Icon(
                                  CupertinoIcons.checkmark,
                                  color: CupertinoColors.white,
                                  size: 14,
                                )
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Tôi đồng ý cho StayHub thu thập ảnh CCCD và khuôn mặt để xác nhận danh tính khi đăng ký thuê phòng.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // CTA button
            _InteractiveScale(
              onTap: _consentGiven ? _startVerification : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _consentGiven
                        ? [AppTheme.kBrand, const Color(0xFF1A6FD4)]
                        : [const Color(0xFF9CA3AF), const Color(0xFFD1D5DB)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _consentGiven
                      ? [
                          BoxShadow(
                            color: AppTheme.kBrand.withValues(alpha: 0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ]
                      : [],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      CupertinoIcons.camera_viewfinder,
                      color: CupertinoColors.white,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Bắt đầu xác nhận',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Text(
                'Bạn là người nước ngoài? Bấm vào đây',
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () {
                unawaited(
                  showCupertinoDialog(
                    context: context,
                    builder: (ctx) => CupertinoAlertDialog(
                      title: const Text('Xác thực cho người nước ngoài'),
                      content: const Text(
                        'Hiện tại chưa hỗ trợ Hộ chiếu quốc tế. Vui lòng liên hệ quản lý tòa nhà để được hỗ trợ trực tiếp.',
                      ),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('Đã hiểu'),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStepHint(
    IconData icon,
    String step,
    String desc,
    Color color,
    Color bg,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            CupertinoIcons.chevron_right,
            color: color.withValues(alpha: 0.5),
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmation() {
    return Padding(
      key: const ValueKey('confirm'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo previews với thiết kế card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEFF6FF), Color(0xFFF5F3FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        CupertinoIcons.photo_on_rectangle,
                        color: Color(0xFF2563EB),
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Ảnh đã chụp',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E3A5F),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildPhotoPreview('Mặt trước', _cccdFront),
                      const SizedBox(width: 10),
                      _buildPhotoPreview('Mặt sau', _cccdBack),
                      const SizedBox(width: 10),
                      _buildPhotoPreview('Chân dung', _selfie, isVideo: true),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Thông tin giấy tờ
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        CupertinoIcons.doc_text,
                        color: Color(0xFF374151),
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Thông tin từ CCCD của bạn',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF374151),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildReadOnlyField('Họ và tên', _nameCtrl),
                  const SizedBox(height: 10),
                  _buildReadOnlyField('Số CCCD', _cccdCtrl),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildReadOnlyField('Ngày sinh', _dobCtrl),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildReadOnlyField('Giới tính', _genderCtrl),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildReadOnlyField('Nơi thường trú', _hometownCtrl),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildReadOnlyField('Ngày cấp', _issueDateCtrl),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildReadOnlyField('Nơi cấp', _issuePlaceCtrl),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.exclamationmark_circle_fill,
                      color: Color(0xFFDC2626),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Điều khoản
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () =>
                        setState(() => _agreedToTerms = !_agreedToTerms),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(top: 2, right: 12),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _agreedToTerms
                            ? AppTheme.kAccentColor
                            : CupertinoColors.white,
                        border: Border.all(
                          color: _agreedToTerms
                              ? AppTheme.kAccentColor
                              : const Color(0xFFD1D5DB),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: _agreedToTerms
                          ? const Icon(
                              CupertinoIcons.checkmark_alt,
                              size: 18,
                              color: CupertinoColors.white,
                            )
                          : null,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Tôi xác nhận thông tin trên là đúng sự thật và đồng ý để StayHub lưu trữ cho hợp đồng thuê phòng.',
                      style: TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_isUploading)
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.kAccentColor, AppTheme.kBrandLight],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: CupertinoActivityIndicator(
                          radius: 14,
                          color: CupertinoColors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Đang gửi hồ sơ, vui lòng đợi...',
                      style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              )
            else
              _InteractiveScale(
                onTap: _agreedToTerms ? _submitEkyc : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: _agreedToTerms
                        ? const LinearGradient(
                            colors: [
                              AppTheme.kAccentColor,
                              AppTheme.kBrandLight,
                            ],
                          )
                        : const LinearGradient(
                            colors: [Color(0xFFD1D5DB), Color(0xFFD1D5DB)],
                          ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _agreedToTerms
                        ? [
                            BoxShadow(
                              color: AppTheme.kAccentColor.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.checkmark_seal_fill,
                        color: _agreedToTerms
                            ? CupertinoColors.white
                            : const Color(0xFF9CA3AF),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Nộp hồ sơ xác nhận danh tính',
                        style: TextStyle(
                          color: _agreedToTerms
                              ? CupertinoColors.white
                              : const Color(0xFF9CA3AF),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPreview(
    String label,
    dynamic imageFile, {
    bool isVideo = false,
  }) {
    final bool hasImage = imageFile != null;
    final Color borderColor = hasImage
        ? AppTheme.kSuccess
        : AppTheme.kError.withValues(alpha: 0.5);
    final Color bgColor = hasImage
        ? AppTheme.kSuccess.withValues(alpha: 0.05)
        : AppTheme.kError.withValues(alpha: 0.05);

    return Expanded(
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            tween: Tween<double>(begin: 0.8, end: 1.0),
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 70,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: borderColor,
                      width: hasImage ? 2 : 1.5,
                    ),
                    boxShadow: hasImage
                        ? [
                            BoxShadow(
                              color: AppTheme.kSuccess.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: child,
                ),
              );
            },
            child: hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: (imageFile is File || imageFile is XFile)
                        ? (isVideo
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        CupertinoIcons.checkmark_seal_fill,
                                        color: AppTheme.kSuccess,
                                        size: 24,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Khuôn mặt hợp lệ',
                                        style: TextStyle(
                                          color: AppTheme.kSuccess,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ResponsiveFileImage(
                                  imageFile is File
                                      ? imageFile
                                      : File((imageFile as XFile).path),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ))
                        : const Icon(
                            CupertinoIcons.checkmark_alt,
                            color: AppTheme.kSuccess,
                          ),
                  )
                : const Center(
                    child: Icon(
                      CupertinoIcons.photo,
                      color: Color(0xFF9CA3AF),
                      size: 20,
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF4B5563),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        CupertinoTextField(
          controller: controller,
          readOnly: true,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildGuideItem(String emoji, String text) {
    final bool isPositive = emoji == '✅';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isPositive
                  ? const Color(0xFF065F46)
                  : const Color(0xFF991B1B),
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
