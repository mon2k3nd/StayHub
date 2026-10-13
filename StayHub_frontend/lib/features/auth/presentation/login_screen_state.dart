// ================================================================
//  Login Screen - Auth Screen State (fields, lifecycle, build, builders)
//  (split from login_screen.dart to keep files manageable)
// ================================================================
part of 'login_screen.dart';

class _AuthScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  // ————————————————————————————————————————————————————————————————————————————
  late TabController _tabCtrl;

  // ── Login state ───────────────────────────────────────────────────────────
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _phoneError, _passError, _loginError;
  bool _isBiometricAvailable = false;
  List<BiometricType> _availableBiometrics = [];
  bool _rememberMe = true;
  String? _lastPhone, _lastName, _lastAvatar;
  bool _showPasswordInput = false;

  // Wrong-password avatar state
  bool _isWrongPasswordState = false;
  String? _wrongPasswordAvatarUrl;
  String? _wrongPasswordName;

  // ── Register state ────────────────────────────────────────────────────────
  final _regTargetCtrl = TextEditingController();
  final _regExtraEmailCtrl = TextEditingController();
  bool _isRegisteringWithPhone = false;
  String? _firebaseVerificationId; // Firebase verificationId for SMS OTP
  final _regOtpCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  final _regConfirmPassCtrl = TextEditingController();
  RegisterStep _regStep = RegisterStep.emailInput;
  String? _regError;
  bool _regLoading = false;
  bool _isOtpError = false;
  String? _registrationToken;
  int _resendCountdown = 0;
  bool _hasResentOtp = false;

  final BiometricService _biometricService = BiometricService();
  late AnimationController _pulseCtrl;
  late AnimationController _blobCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _glowCtrl;
  late Animation<double> _pulseAnim;
  late AnimationController _enterCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _tabCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    unawaited(_pulseCtrl.repeat(reverse: true));
    _pulseAnim = Tween<double>(
      begin: 0.98,
      end: 1.02,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _blobCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    unawaited(_blobCtrl.repeat());
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    unawaited(_particleCtrl.repeat());
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    unawaited(_glowCtrl.repeat(reverse: true));

    _phoneCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _passCtrl.addListener(() {
      if (mounted) setState(() {});
    });

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _enterCtrl.addListener(() => setState(() {}));
    unawaited(_enterCtrl.forward());

    unawaited(_checkBiometric());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _pulseCtrl.dispose();
    _blobCtrl.dispose();
    _particleCtrl.dispose();
    _glowCtrl.dispose();
    _regTargetCtrl.dispose();
    _regExtraEmailCtrl.dispose();
    _regOtpCtrl.dispose();
    _regPassCtrl.dispose();
    _regConfirmPassCtrl.dispose();
    _enterCtrl.dispose();
    super.dispose();
  }

  // ─€─€ BIOMETRIC ─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€
  Future<void> _checkBiometric() async {
    final secureStorage = ref.read(secureStorageServiceProvider);
    final creds = await secureStorage.getLastUser();
    final isAvailable = await _biometricService.isBiometricAvailable();
    final biometrics = await _biometricService.getAvailableBiometrics();
    if (mounted) {
      setState(() {
        _lastPhone = creds['phone'];
        _lastName = creds['name'];
        _lastAvatar = creds['avatar'];
        _isBiometricAvailable = isAvailable;
        _availableBiometrics = biometrics;
        if (_lastPhone != null) _phoneCtrl.text = _lastPhone!;
        // Nếu có session cũ nhưng không có sinh trắc học → hiện thường form mật khẩu
        if (_lastPhone != null && !isAvailable) _showPasswordInput = true;
      });
      if (_lastPhone != null && isAvailable) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) unawaited(_loginWithBiometric());
        });
      }
    }
  }

  Future<void> _loginWithBiometric() async {
    if (_lastPhone == null) return;
    final success = await _biometricService.authenticate();
    if (success) {
      if (!mounted) return;
      try {
        await ref.read(authProvider.notifier).loginWithBiometric();
      } catch (e) {
        if (!mounted) return;
        ToastUtils.show(context, e.toString());
        setState(() => _showPasswordInput = true);
      }
    } else {
      if (mounted) setState(() => _showPasswordInput = true);
    }
  }

  Future<void> _clearLocalSession() async {
    await ref.read(secureStorageServiceProvider).clearLastUser();
    setState(() {
      _lastPhone = _lastName = _lastAvatar = null;
      _phoneCtrl.clear();
      _passCtrl.clear();
      _showPasswordInput = false;
      _isWrongPasswordState = false;
    });
  }

  // ─€─€ LOGIN ─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€
  /// SĐT VN hợp lệ hoặc Email hợp lệ (login chấp nhận cả hai).
  static final RegExp _phoneRegex = RegExp(r'^(0|\+84)[3-9]\d{8}$');
  static final RegExp _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]{2,}$');

  // Trả về Future<void> (không phải `void`) để lỗi async có thể lan truyền
  // tới caller và tránh unhandled-exception khi widget bị unmount giữa chừng.
  Future<void> _validateAndSubmit() async {
    setState(() {
      _phoneError = _passError = _loginError = null;
    });
    final phone = _phoneCtrl.text.trim();
    final password = _passCtrl.text;
    if (password.isEmpty && _isBiometricAvailable && _lastPhone != null) {
      await _loginWithBiometric();
      return;
    }
    bool isValid = true;
    if (phone.isEmpty) {
      setState(() => _phoneError = 'Số điện thoại không được để trống.');
      isValid = false;
    } else if (!_phoneRegex.hasMatch(phone) && !_emailRegex.hasMatch(phone)) {
      // Cho phép đăng nhập bằng SĐT hoặc Email — chỉ báo lỗi khi cả hai đều sai.
      setState(() => _phoneError = 'SĐT hoặc Email không đúng định dạng.');
      isValid = false;
    }
    if (password.isEmpty) {
      setState(() => _passError = 'Mật khẩu không được để trống.');
      isValid = false;
    } else if (password.length < 6) {
      // Backend yêu cầu tối thiểu 6 ký tự — đồng bộ với luồng đăng ký
      // (trước đây login chỉ check < 4 gây lệch chuẩn và round-trip vô ích).
      setState(() => _passError = 'Mật khẩu phải có ít nhất 6 ký tự.');
      isValid = false;
    }
    if (!isValid) return;
    try {
      await ref
          .read(authProvider.notifier)
          .login(phone, password, rememberMe: _rememberMe);
    } catch (e) {
      if (!mounted) return;
      final err = AppExceptionMapper.fromGeneric(e);
      setState(() => _loginError = err.message);
      // Check if it's a wrong-password scenario (account exists but wrong pw)
      _handleLoginError(err, phone);
      return;
    }
    if (!mounted) return;
    final authState = ref.read(authProvider);
    if (authState.hasError) {
      final err = AppExceptionMapper.fromGeneric(authState.error);
      setState(() => _loginError = err.message);
      _handleLoginError(err, phone);
    } else if (authState.hasValue && authState.value != null) {
      await _navigateBasedOnRole(authState.value!);
    }
  }

  void _handleLoginError(AppException err, String phone) {
    // ── Ưu tiên: WrongPasswordException mang theo name/avatar từ backend ──
    if (err is WrongPasswordException) {
      unawaited(HapticFeedback.heavyImpact());
      setState(() {
        _wrongPasswordName = err.userName ?? _lastName ?? phone;
        _wrongPasswordAvatarUrl = err.userAvatar ?? _lastAvatar;
        _isWrongPasswordState = true;
        _loginError = 'Mật khẩu không đúng. Vui lòng thử lại.';
      });
      _passCtrl.clear();
      return;
    }

    // ── Fallback: phân tích thông điệp lỗi (khi backend cũ / 401 không có metadata) ──
    final isWrongPassword =
        err.message.toLowerCase().contains('mật khẩu') ||
        err.message.toLowerCase().contains('password') ||
        err.message.toLowerCase().contains('sai') ||
        err.message.toLowerCase().contains('incorrect') ||
        (err.statusCode == 401);
    if (isWrongPassword) {
      unawaited(HapticFeedback.heavyImpact());
      setState(() {
        _wrongPasswordName = _lastName ?? phone;
        _wrongPasswordAvatarUrl = _lastAvatar;
        _isWrongPasswordState = true;
        _loginError = 'Mật khẩu không đúng. Vui lòng thử lại.';
      });
      _passCtrl.clear();
    } else {
      unawaited(HapticFeedback.heavyImpact());
      _showLoginErrorDialog(err.message);
    }
  }

  Future<void> _navigateBasedOnRole(dynamic user) async {
    final pending = await DeepLinkMemoryService.consumePendingRoute();
    if (!mounted) return;
    // await + try/catch: tránh unhandled async error khi sync wishlist thất bại
    // (mạng yếu) — lỗi này không được phép chặn luồng điều hướng chính.
    try {
      await WishlistService.syncLocalToServer(
        user.id.toString(),
        ref.read(apiClientProvider),
      );
    } catch (_) {}
    // Guard bắt buộc sau async gap trước khi dùng context.
    if (!mounted) return;

    if (user.requirePasswordSetup == true) {
      unawaited(context.push('/setup-social-password'));
      return;
    }

    final hasNoAvatar = user.avatar == null || user.avatar!.isEmpty;
    if (hasNoAvatar) {
      final prefs = await SharedPreferences.getInstance();
      final lastPrompt = prefs.getInt('last_avatar_prompt_${user.id}') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      // Chỉ hiện lại sau 7 ngày nếu người dùng chưa cập nhật
      if (now - lastPrompt > 7 * 24 * 60 * 60 * 1000) {
        if (mounted) context.go('/avatar-update');
        return;
      }
    }

    if (!mounted) return;

    final role = user.role;
    if (role == 'ADMIN') {
      context.go('/admin-panel');
    } else if (role == 'OWNER') {
      context.go('/owner-dashboard');
    } else if (role == 'STAFF') {
      if (user.status == 'PENDING_VERIFICATION') {
        unawaited(
          context.push(
            '/profile-update',
            extra: {'nextRoute': '/staff-dashboard'},
          ),
        );
      } else {
        context.go('/staff-dashboard');
      }
    } else {
      if (pending != null && pending['roomId'] != null) {
        context.go('/marketplace');
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            unawaited(
              context.push(
                '/guest-room-detail',
                extra: {'roomId': pending['roomId']},
              ),
            );
          }
        });
      } else {
        context.go('/marketplace');
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    try {
      final idToken = await GoogleAuthService.signIn();
      if (!mounted) return;
      await ref.read(authProvider.notifier).loginWithGoogle(idToken);
      if (!mounted) return;
      final authState = ref.read(authProvider);
      if (authState.hasError) {
        final err = AppExceptionMapper.fromGeneric(authState.error);
        _showLoginErrorDialog(err.message);
      } else if (authState.hasValue && authState.value != null) {
        unawaited(_navigateBasedOnRole(authState.value!));
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('cancel') || msg.contains('canceled')) return;
      _showLoginErrorDialog('Đăng nhập Google thất bại. Vui lòng thử lại.');
    }
  }

  Future<void> _loginWithFacebook() async {
    try {
      final accessToken = await FacebookAuthService.signIn();
      if (!mounted) return;
      await ref.read(authProvider.notifier).loginWithFacebook(accessToken);
      if (!mounted) return;
      final authState = ref.read(authProvider);
      if (authState.hasError) {
        final err = AppExceptionMapper.fromGeneric(authState.error);
        _showLoginErrorDialog(err.message);
      } else if (authState.hasValue && authState.value != null) {
        unawaited(_navigateBasedOnRole(authState.value!));
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('cancel') || msg.contains('canceled')) return;
      _showLoginErrorDialog('Đăng nhập Facebook thất bại. Vui lòng thử lại.');
    }
  }

  Future<void> _loginWithZalo() async {
    try {
      // Zalo OAuth cần App ID + redirect URI. Nếu chưa cấu hình, thông báo rõ.
      if (ZaloAuthService.appId.isEmpty) {
        _showLoginErrorDialog(
          'Đăng nhập Zalo chưa được cấu hình. Vui lòng liên hệ quản trị viên.',
        );
        return;
      }
      final accessToken = await ZaloAuthService.signIn();
      if (!mounted) return;
      await ref.read(authProvider.notifier).loginWithZalo(accessToken);
      if (!mounted) return;
      final authState = ref.read(authProvider);
      if (authState.hasError) {
        final err = AppExceptionMapper.fromGeneric(authState.error);
        _showLoginErrorDialog(err.message);
      } else if (authState.hasValue && authState.value != null) {
        unawaited(_navigateBasedOnRole(authState.value!));
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('cancel') || msg.contains('canceled')) return;
      _showLoginErrorDialog('Đăng nhập Zalo thất bại. Vui lòng thử lại.');
    }
  }

  Future<void> _loginWithApple() async {
    try {
      if (!AppleAuthService.isSupported) {
        _showLoginErrorDialog(
          'Đăng nhập Apple chỉ khả dụng trên thiết bị iOS/macOS.',
        );
        return;
      }
      final result = await AppleAuthService.signIn();
      if (!mounted) return;
      await ref
          .read(authProvider.notifier)
          .loginWithApple(
            result.identityToken,
            fullName: result.fullName,
            email: result.email,
          );
      if (!mounted) return;
      final authState = ref.read(authProvider);
      if (authState.hasError) {
        final err = AppExceptionMapper.fromGeneric(authState.error);
        _showLoginErrorDialog(err.message);
      } else if (authState.hasValue && authState.value != null) {
        unawaited(_navigateBasedOnRole(authState.value!));
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('cancel') || msg.contains('huỷ')) return;
      _showLoginErrorDialog('Đăng nhập Apple thất bại. Vui lòng thử lại.');
    }
  }

  void _showLoginErrorDialog(String message) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text(
            'Đăng Nhập Thất Bại',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(message),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đồng ý'),
            ),
          ],
        ),
      ),
    );
  }

  // ─€─€ REGISTER ─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€
  void _startCountdown() {
    unawaited(
      Future.doWhile(() async {
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return false;
        setState(() => _resendCountdown--);
        return _resendCountdown > 0;
      }),
    );
  }

  /// Email hợp lệ: có `@`, tên miền và phần mở rộng (>= 2 ký tự).
  static final RegExp _regEmailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]{2,}$');
  static final RegExp _regPhoneRegex = RegExp(r'^(0|\+84)[3-9]\d{8}$');

  Future<void> _sendOtp() async {
    final target = _regTargetCtrl.text.trim();

    if (target.isEmpty) {
      unawaited(HapticFeedback.heavyImpact());
      setState(() => _regError = 'Vui lòng nhập SĐT hoặc Email.');
      return;
    }

    final isEmail = target.contains('@');
    if (isEmail) {
      if (!_regEmailRegex.hasMatch(target)) {
        unawaited(HapticFeedback.heavyImpact());
        setState(
          () =>
              _regError = 'Email không đúng định dạng. Vui lòng kiểm tra lại.',
        );
        return;
      }
    } else {
      if (!_regPhoneRegex.hasMatch(target)) {
        unawaited(HapticFeedback.heavyImpact());
        setState(() => _regError = 'Số điện thoại không đúng định dạng.');
        return;
      }
    }

    unawaited(HapticFeedback.lightImpact());
    setState(() {
      _isRegisteringWithPhone = !isEmail;
      _regLoading = true;
      _regError = null;
    });

    if (!isEmail) {
      // --- Phone path: Firebase gửi SMS miễn phí ---
      try {
        await FirebasePhoneAuthService.sendSmsOtp(
          phoneNumber: target,
          onCodeSent: (verificationId) {
            if (!mounted) return;
            setState(() {
              _firebaseVerificationId = verificationId;
              _regStep = RegisterStep.otpVerification;
              _regLoading = false;
              _resendCountdown = 60;
            });
            _startCountdown();
          },
          onError: (error) {
            if (!mounted) return;
            unawaited(HapticFeedback.heavyImpact());
            setState(() {
              _regError = error;
              _regLoading = false;
            });
          },
        );
      } catch (e) {
        if (!mounted) return;
        unawaited(HapticFeedback.heavyImpact());
        setState(() {
          _regError = 'Lỗi hệ thống: $e';
          _regLoading = false;
        });
      }
    } else {
      // --- Email path: Backend gửi mail ---
      try {
        await ref.read(authProvider.notifier).sendOtp(target, 'email');
        if (!mounted) return;
        unawaited(HapticFeedback.lightImpact());
        setState(() {
          _regStep = RegisterStep.otpVerification;
          _regLoading = false;
          _resendCountdown = 60;
        });
        _startCountdown();
      } catch (e) {
        if (mounted) {
          unawaited(HapticFeedback.heavyImpact());
          setState(() {
            _regError = 'Lỗi gửi OTP: $e';
            _regLoading = false;
          });
        }
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _resendCountdown = 60;
      _hasResentOtp = true;
      _regError = null;
      _regOtpCtrl.clear();
      _isOtpError = false;
    });

    _startCountdown();

    if (_isRegisteringWithPhone) {
      // --- Phone path: Firebase gửi lại SMS ---
      await FirebasePhoneAuthService.resendSmsOtp(
        phoneNumber: _regTargetCtrl.text.trim(),
        onCodeSent: (verificationId) {
          if (!mounted) return;
          setState(() => _firebaseVerificationId = verificationId);
        },
        onError: (error) {
          if (!mounted) return;
          setState(() => _regError = error);
        },
      );
    } else {
      // --- Email path: Backend gửi lại ---
      try {
        final target = _regTargetCtrl.text.trim();
        await ref.read(authProvider.notifier).sendOtp(target, 'email');
      } catch (e) {
        if (mounted) setState(() => _regError = 'Lỗi gửi OTP: $e');
      }
    }
  }

  Future<void> _verifyOtpReal(String otp) async {
    setState(() {
      _regError = null;
      _regLoading = true;
    });
    try {
      String token;
      if (_isRegisteringWithPhone) {
        // --- Phone path: Xác thực OTP với Firebase, rồi gọi backend ---
        if (_firebaseVerificationId == null) {
          throw Exception('Phiên xác thực đã hết. Vui lòng gửi lại mã.');
        }
        final firebaseUser = await FirebasePhoneAuthService.verifySmsOtp(
          verificationId: _firebaseVerificationId!,
          smsCode: otp,
        );
        // Gọi backend để đổi firebaseUid -> registrationToken
        token = await ref
            .read(authProvider.notifier)
            .verifyPhoneWithFirebase(
              _regTargetCtrl.text.trim(),
              firebaseUser.uid,
            );
        // unawaited(Đăng xuất khỏi Firebase (chỉ dùng để xác thực, không giữ session))
        unawaited(FirebasePhoneAuthService.signOut());
      } else {
        // --- Email path: Xác thực OTP qua backend ---
        token = await ref
            .read(authProvider.notifier)
            .verifyOtp(_regTargetCtrl.text.trim(), 'email', otp);
      }
      unawaited(HapticFeedback.heavyImpact());
      setState(() {
        _registrationToken = token;
        _regStep = RegisterStep.passwordSetup;
        _regLoading = false;
      });
    } catch (e) {
      unawaited(HapticFeedback.heavyImpact());
      final errMsg = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _isOtpError = true;
        _regError = errMsg.isNotEmpty && errMsg != 'null'
            ? errMsg
            : (_isRegisteringWithPhone
                  ? 'Mã SMS không đúng hoặc đã hết hạn.'
                  : 'Mã OTP không hợp lệ hoặc đã hết hạn.');
        _regLoading = false;
      });
      _regOtpCtrl.clear();
    }
  }

  Future<void> _submitRegistration() async {
    setState(() => _regError = null);
    final target = _regTargetCtrl.text.trim();
    final email = _isRegisteringWithPhone
        ? _regExtraEmailCtrl.text.trim()
        : target;
    final phoneNumber = _isRegisteringWithPhone ? target : null;

    if (_isRegisteringWithPhone && !_regEmailRegex.hasMatch(email)) {
      setState(
        () => _regError = 'Email không đúng định dạng. Vui lòng kiểm tra lại.',
      );
      unawaited(HapticFeedback.heavyImpact());
      return;
    }

    final pass = _regPassCtrl.text;
    final confirmPass = _regConfirmPassCtrl.text;
    if (pass.isEmpty || pass.length < 8) {
      setState(() => _regError = 'Mật khẩu phải có ít nhất 8 ký tự.');
      unawaited(HapticFeedback.heavyImpact());
      return;
    }
    if (pass != confirmPass) {
      setState(() => _regError = 'Mật khẩu xác nhận không khớp.');
      unawaited(HapticFeedback.heavyImpact());
      return;
    }
    setState(() => _regLoading = true);
    try {
      if (_registrationToken == null) {
        setState(() => _regError = 'Phiên đăng ký đã hết hạn.');
        return;
      }
      await ref.read(authProvider.notifier).register({
        'fullName': 'Khách hàng StayHub',
        'email': email,
        'phoneNumber': phoneNumber,
        'password': pass,
        'confirmPassword': confirmPass,
        'registrationToken': _registrationToken,
      });
      if (!mounted) return;
      final authState = ref.read(authProvider);
      if (authState.hasError) {
        final err = AppExceptionMapper.fromGeneric(authState.error);
        setState(() => _regError = err.message);
        unawaited(HapticFeedback.heavyImpact());
      } else {
        unawaited(HapticFeedback.heavyImpact());
        _showRegSuccessDialog();
      }
    } catch (e) {
      unawaited(HapticFeedback.heavyImpact());
      setState(() => _regError = 'Đăng ký thất bại: $e');
    } finally {
      if (mounted) setState(() => _regLoading = false);
    }
  }

  void _showRegSuccessDialog() {
    unawaited(
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text(
            'Thành công',
            style: TextStyle(color: CupertinoColors.systemGreen),
          ),
          content: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Đăng ký thành công!'),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () {
                Navigator.pop(ctx);
                unawaited(_autoLoginAfterRegister());
              },
              child: const Text('Đăng nhập ngay'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _autoLoginAfterRegister() async {
    try {
      await ref
          .read(authProvider.notifier)
          .login(_regTargetCtrl.text.trim(), _regPassCtrl.text);
      final authState = ref.read(authProvider);
      if (authState.hasValue && authState.value != null) {
        final user = authState.value!;
        unawaited(
          WishlistService.syncLocalToServer(
            user.id.toString(),
            ref.read(apiClientProvider),
          ),
        );
        unawaited(_navigateBasedOnRole(user));
      }
    } catch (e) {
      if (mounted) context.go('/login');
    }
  }

  Future<void> _handleGoogleRegister() async {
    try {
      final idToken = await GoogleAuthService.signIn();
      if (!mounted) return;
      await ref.read(authProvider.notifier).loginWithGoogle(idToken);
      if (!mounted) return;
      final authState = ref.read(authProvider);
      if (authState.hasError) {
        final err = AppExceptionMapper.fromGeneric(authState.error);
        _showErrorToast(err.message);
      } else if (authState.hasValue && authState.value != null) {
        final user = authState.value!;
        unawaited(
          WishlistService.syncLocalToServer(
            user.id.toString(),
            ref.read(apiClientProvider),
          ),
        );
        if (user.role == 'OWNER') {
          context.go('/owner-dashboard');
        } else {
          context.go('/tenant-dashboard');
        }
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('cancel') || msg.contains('canceled')) return;
      unawaited(HapticFeedback.heavyImpact());
      _showErrorToast('Dang nhap Google that bai. Vui long thu lai.');
    }
  }

  Future<void> _handleFacebookRegister() async {
    try {
      final accessToken = await FacebookAuthService.signIn();
      if (!mounted) return;
      await ref.read(authProvider.notifier).loginWithFacebook(accessToken);
      if (!mounted) return;
      final authState = ref.read(authProvider);
      if (authState.hasError) {
        final err = AppExceptionMapper.fromGeneric(authState.error);
        _showErrorToast(err.message);
      } else if (authState.hasValue && authState.value != null) {
        final user = authState.value!;
        unawaited(
          WishlistService.syncLocalToServer(
            user.id.toString(),
            ref.read(apiClientProvider),
          ),
        );
        if (user.role == 'OWNER') {
          context.go('/owner-dashboard');
        } else {
          context.go('/tenant-dashboard');
        }
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('cancel') || msg.contains('canceled')) return;
      unawaited(HapticFeedback.heavyImpact());
      _showErrorToast('Đăng ký qua Facebook thất bại. Vui lòng thử lại.');
    }
  }

  // ═══════════════════════════════════════════════════════════════

  void _showErrorToast(String message) {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: MediaQuery.of(ctx).padding.top + 16,
        left: 24,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            builder: (_, v, child) => Opacity(
              opacity: v,
              child: Transform.translate(
                offset: Offset(0, -10 * (1 - v)),
                child: child,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFF3B30),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF3B30).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.exclamationmark_circle_fill,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) entry.remove();
    });
  }

  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;
    final mq = MediaQuery.of(context);
    final size = mq.size;
    // Keyboard-safe: reserve space equal to the on-screen keyboard so the
    // form is never covered on narrow phones.
    final keyboardInset = mq.viewInsets.bottom;
    // Responsive horizontal gutter: tighter on narrow devices (< 360dp).
    final hPad = size.width < 360 ? 16.0 : 24.0;

    return CupertinoTheme(
      data: const CupertinoThemeData(
        brightness: Brightness.light,
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(fontFamily: AppTheme.kFontFamily, color: _kText),
        ),
      ),
      child: AnimatedSkyBackground(
        child: CupertinoPageScaffold(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              // ─€─€ Background cũ (đã thay bằng AnimatedSkyBackground) ─€─€
              // Positioned.fill(child: _buildBackground()),

              // ─€─€ Main scroll ─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€
              SafeArea(
                bottom: false,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          -300 *
                              (1.0 -
                                  Curves.elasticOut.transform(
                                    _enterCtrl.value,
                                  )),
                        ),
                        child: _buildLogo(size),
                      ),
                    ),
                    // ─ Content (Tabs, Form, Footer) rises from bottom ─
                    SliverToBoxAdapter(
                      child: Transform.translate(
                        offset: Offset(
                          0,
                          size.height *
                              (1.0 -
                                  Curves.easeOutCubic.transform(
                                    _enterCtrl.value,
                                  )),
                        ),
                        child: Column(
                          children: [
                            if (!(_tabCtrl.index == 0 &&
                                _lastPhone != null &&
                                !_isWrongPasswordState))
                              _buildTabBarRow(),
                            if (_tabCtrl.index == 0 &&
                                _lastPhone != null &&
                                !_isWrongPasswordState)
                              const SizedBox(height: 16),

                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: hPad),
                              child: _buildGlassCard(
                                child: AnimatedSize(
                                  duration: const Duration(milliseconds: 220),
                                  reverseDuration: const Duration(
                                    milliseconds: 180,
                                  ),
                                  curve: Curves.easeOutBack,
                                  alignment: Alignment.topCenter,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    switchInCurve: Curves.easeOut,
                                    switchOutCurve: Curves.easeIn,
                                    layoutBuilder:
                                        (
                                          Widget? currentChild,
                                          List<Widget> previousChildren,
                                        ) {
                                          return Stack(
                                            alignment: Alignment.topCenter,
                                            children: <Widget>[
                                              ...previousChildren,
                                              if (currentChild != null)
                                                currentChild,
                                            ],
                                          );
                                        },
                                    transitionBuilder:
                                        (
                                          Widget child,
                                          Animation<double> animation,
                                        ) {
                                          return FadeTransition(
                                            opacity: CurvedAnimation(
                                              parent: animation,
                                              curve: Curves.easeOutCubic,
                                            ),
                                            child: child,
                                          );
                                        },
                                    child: _tabCtrl.index == 0
                                        ? _buildLoginTab(isLoading)
                                        : _buildRegisterTab(),
                                  ),
                                ),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.only(
                                top: 32,
                                bottom: 40,
                              ),
                              child: (_lastPhone != null && _tabCtrl.index == 0)
                                  ? _buildReturningUserFooter()
                                  : _buildSocialSection(
                                      _tabCtrl.index == 0
                                          ? _loginWithGoogle
                                          : _handleGoogleRegister,
                                      _tabCtrl.index == 0
                                          ? _loginWithFacebook
                                          : _handleFacebookRegister,
                                      zaloAction: _loginWithZalo,
                                      appleAction: _loginWithApple,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Keyboard spacer — đặt ở CUỐI danh sách (không phải đầu).
                    // Trước đây spacer nằm ở ĐẦU slivers → khi bàn phím mở, nó
                    // đẩy TOÀN BỘ nội dung (logo + các ô phía trên) xuống dưới
                    // → cảm giác "kéo xuống, giật giật". Đặt ở cuối thì nội
                    // dung giữ nguyên vị trí, chỉ phần đáy nở ra để ô đang gõ
                    // luôn nằm trên bàn phím.
                    SliverToBoxAdapter(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        height: keyboardInset,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─€─€ Footer: Returning User ─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€
  Widget _buildReturningUserFooter() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: _kBrand.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.transparent,
            onPressed: () {
              unawaited(HapticFeedback.lightImpact());
              unawaited(_clearLocalSession());
              _tabCtrl.animateTo(1);
            },
            child: const Text(
              'Tạo tài khoản',
              style: TextStyle(
                color: _kBrand,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Container(width: 1, height: 20, color: const Color(0xFFE2E8F0)),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: Colors.transparent,
            onPressed: () {
              unawaited(HapticFeedback.lightImpact());
              // Khách chưa đăng nhập → vào trải nghiệm guest, KHÔNG vào
              // tenant-dashboard (trước đây điều hướng sai gây lộ màn hình nội bộ).
              context.go('/guest');
            },
            child: const Text(
              'Khách',
              style: TextStyle(
                color: _kTextSub,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─€─€ Logo (1/3 screen) — shows avatar when returning user is on login tab ─€─€
  Widget _buildLogo(Size size) {
    // Avatar khi có returning user trên tab đăng nhập (cả biometric mode và password mode)
    final bool showAvatar =
        _tabCtrl.index == 0 &&
        _lastPhone != null &&
        !_isWrongPasswordState; // giữ avatar cả khi _showPasswordInput == true

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: showAvatar
          ? SizedBox(
              key: const ValueKey('avatar_logo'),
              height: size.height / 3 + 40,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo ở trên avatar
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: _kBrand.withValues(alpha: 0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const StayHubLogoIcon(
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Avatar
                    _buildAvatar(
                      avatarUrl: _lastAvatar,
                      name: _lastName ?? 'U',
                      size: 100,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _lastName ?? 'Người dùng',
                      style: const TextStyle(
                        color: _kText,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Xin chào trở lại 👋',
                      style: TextStyle(
                        color: _kTextSub,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SizedBox(
              key: const ValueKey('stayhub_logo'),
              height: size.height / 3,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: _kBrand.withValues(alpha: 0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const StayHubLogoIcon(
                        size: 160,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'StayHub',
                      style: TextStyle(
                        fontFamily: AppTheme.kFontFamily,
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1.0,
                        shadows: [
                          Shadow(
                            color: _kBrand.withValues(alpha: 0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ─€─€ Tab Bar Row & Guest Button ─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€
  Widget _buildTabBarRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: _kGlass,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: _kGlassB, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: _kBrand.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Sliding gradient indicator
                  AnimatedAlign(
                    alignment: _tabCtrl.index == 0
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    child: FractionallySizedBox(
                      widthFactor: 0.5,
                      child: Container(
                        height: 44,
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_kBrand, Color(0xFF0066CC)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: _kBrand.withValues(alpha: 0.50),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Tab labels
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            unawaited(HapticFeedback.lightImpact());
                            setState(() => _tabCtrl.animateTo(0));
                          },
                          child: Text(
                            'Đăng Nhập',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _tabCtrl.index == 0 ? _kText : _kTextSub,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            unawaited(HapticFeedback.lightImpact());
                            setState(() => _tabCtrl.animateTo(1));
                          },
                          child: Text(
                            'Đăng Ký',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: _tabCtrl.index == 1 ? _kText : _kTextSub,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  LOGIN TAB
  // ═══════════════════════════════════════════════════════════════
  Widget _buildLoginTab(bool isLoading) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: _isWrongPasswordState
          ? _buildWrongPasswordState(isLoading)
          : _buildNormalLoginState(isLoading),
    );
  }

  // ─€─€ Normal login form ─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€
  Widget _buildNormalLoginState(bool isLoading) {
    // Chế độ biometric: có session cũ, có sinh trắc học, chưa bấm dùng mật khẩu
    final bool isBiometricMode =
        _lastPhone != null && !_showPasswordInput && _isBiometricAvailable;

    return Column(
      key: const ValueKey('normal'),
      children: [
        // ─€─€ Biometric mode: chỉ hiện card nút sinh trắc học, ẩn toàn bộ form ─€─€
        if (isBiometricMode) ...[_buildReturningUserCard()],

        // ─€─€ Form mode: hiện khi không có session cũ hoặc user chọn "Dùng mật khẩu" ─€─€
        if (!isBiometricMode) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                // Chỉ hiện ô phone khi không có session cũ (new user)
                if (_lastPhone == null) ...[
                  _buildDarkTextField(
                    controller: _phoneCtrl,
                    placeholder: 'Số điện thoại hoặc Email',
                    prefixIcon: CupertinoIcons.phone_fill,
                    keyboardType: TextInputType.emailAddress,
                    errorText: _phoneError,
                  ),
                  const SizedBox(height: 14),
                ],
                // Ô mật khẩu luôn hiện khi ở form mode
                _buildDarkTextField(
                  controller: _passCtrl,
                  placeholder: 'Mật khẩu',
                  prefixIcon: CupertinoIcons.lock_fill,
                  isPassword: true,
                  errorText: _passError,
                ),
                if (_loginError != null && !_isWrongPasswordState) ...[
                  const SizedBox(height: 10),
                  Text(
                    _loginError!,
                    style: const TextStyle(
                      color: CupertinoColors.systemRed,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Khi là người dùng cũ: hiện "Tài khoản khác"
                    // Khi là người dùng mới: hiện ô "Duy trì đăng nhập"
                    if (_lastPhone != null)
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: _clearLocalSession,
                        child: const Text(
                          'Đăng nhập bằng tài khoản khác',
                          style: TextStyle(
                            color: _kTextSub,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () {
                          unawaited(HapticFeedback.selectionClick());
                          setState(() => _rememberMe = !_rememberMe);
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: _rememberMe
                                    ? _kBrand
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: _rememberMe
                                      ? _kBrand
                                      : _kTextSub.withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: _rememberMe
                                  ? const Icon(
                                      CupertinoIcons.checkmark_alt,
                                      size: 14,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Duy trì đăng nhập',
                              style: TextStyle(
                                color: _kTextSub,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => context.push('/forgot-password'),
                      child: const Text(
                        'Quên mật khẩu?',
                        style: TextStyle(
                          color: _kBrand,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildGradientButton(
                  text: 'ĐĂNG NHẬP',
                  isLoading: isLoading,
                  onTap: _validateAndSubmit,
                ),
                // Nút quay lại sinh trắc học (chỉ khi đã có session và chọn mật khẩu)
                if (_lastPhone != null &&
                    _showPasswordInput &&
                    _isBiometricAvailable) ...[
                  const SizedBox(height: 14),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => setState(() => _showPasswordInput = false),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _availableBiometrics.contains(BiometricType.face)
                              ? Icons.face
                              : Icons.fingerprint,
                          color: _kBrand,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Dùng sinh trắc học',
                          style: TextStyle(
                            color: _kBrand,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  // ─€─€ Returning user biometric card ─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€
  Widget _buildReturningUserCard() {
    return _buildGlassCard(
      child: Column(
        children: [
          const SizedBox(height: 8),
          ScaleTransition(
            scale: _pulseAnim,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_kBrand, _kBrand2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kBrand.withValues(alpha: 0.45),
                    blurRadius: 24,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _loginWithBiometric,
                child: Icon(
                  _availableBiometrics.contains(BiometricType.face)
                      ? Icons.face
                      : Icons.fingerprint,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _availableBiometrics.contains(BiometricType.face)
                ? 'Nhấn để xác thực Face ID'
                : 'Nhấn để xác thực vân tay',
            style: const TextStyle(color: _kTextSub, fontSize: 13),
          ),
          const SizedBox(height: 20),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              unawaited(HapticFeedback.lightImpact());
              setState(() => _showPasswordInput = true);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _kGlass,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _kBrand.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.lock_fill, color: _kBrand, size: 15),
                  SizedBox(width: 8),
                  Text(
                    'Đăng nhập bằng mật khẩu',
                    style: TextStyle(
                      color: _kBrand,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _clearLocalSession,
            child: const Text(
              'Đăng nhập tài khoản khác',
              style: TextStyle(
                color: _kTextSub,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ─€─€ Wrong password avatar state ─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€─€
  Widget _buildWrongPasswordState(bool isLoading) {
    return Padding(
      key: const ValueKey('wrongpw'),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: CupertinoColors.systemRed.withValues(alpha: 0.6),
                    width: 2.5,
                  ),
                ),
              ),
              _buildAvatar(
                avatarUrl: _wrongPasswordAvatarUrl,
                name: _wrongPasswordName ?? 'U',
                size: 74,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _wrongPasswordName ?? 'Người dùng',
            style: const TextStyle(
              color: _kText,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: CupertinoColors.systemRed.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: CupertinoColors.systemRed.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: const Text(
              '⚠ Mật khẩu không đúng',
              style: TextStyle(
                color: CupertinoColors.systemRed,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 22),
          _buildDarkTextField(
            controller: _passCtrl,
            placeholder: 'Nhập lại mật khẩu',
            prefixIcon: CupertinoIcons.lock_fill,
            isPassword: true,
            errorText: _passError,
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => context.push('/forgot-password'),
              child: const Text(
                'Quên mật khẩu?',
                style: TextStyle(
                  color: _kBrand,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildGradientButton(
            text: 'ĐĂNG NHẬP LẠI',
            isLoading: isLoading,
            onTap: _validateAndSubmit,
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              unawaited(HapticFeedback.lightImpact());
              setState(() {
                _isWrongPasswordState = false;
                _loginError = null;
                _passCtrl.clear();
                _phoneCtrl.clear();
              });
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _kGlass,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _kGlassB, width: 1),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.arrow_counterclockwise,
                    color: _kTextSub,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Không phải tôi — Đăng nhập lại',
                    style: TextStyle(
                      color: _kTextSub,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

  // ═══════════════════════════════════════════════════════════════
  //  REGISTER TAB
  // ═══════════════════════════════════════════════════════════════
  Widget _buildRegisterTab() {
    final defaultPinTheme = PinTheme(
      width: 45,
      height: 55,
      textStyle: const TextStyle(
        fontSize: 24,
        color: _kText,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: _kGlass,
        border: Border.all(color: _kGlassB),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return Padding(
      key: ValueKey('reg_step_${_regStep.index}'),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_regStep != RegisterStep.emailInput) ...[
            _buildStepProgress(),
            const SizedBox(height: 20),
          ],

          if (_regStep == RegisterStep.emailInput)
            _buildDarkTextField(
              controller: _regTargetCtrl,
              placeholder: 'Nhập địa chỉ Email hoặc Số điện thoại',
              prefixIcon: CupertinoIcons.person_solid,
              keyboardType: TextInputType.emailAddress,
            ),
          if (_regStep == RegisterStep.otpVerification) ...[
            Column(
              children: [
                Text(
                  _isRegisteringWithPhone
                      ? 'Mã SMS đã được gửi đến số điện thoại'
                      : 'Mã xác thực (OTP) đã được gửi đến',
                  style: const TextStyle(color: _kTextSub, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  _regTargetCtrl.text.trim(),
                  style: const TextStyle(
                    color: _kBrand,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Center(
                  child: Material(
                    color: const Color(0x00000000),
                    child: Pinput(
                      controller: _regOtpCtrl,
                      length: 6,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: defaultPinTheme.copyWith(
                        decoration: defaultPinTheme.decoration!.copyWith(
                          border: Border.all(color: _kBrand, width: 2),
                          color: _kGlass,
                        ),
                      ),
                      errorPinTheme: defaultPinTheme.copyWith(
                        decoration: defaultPinTheme.decoration!.copyWith(
                          border: Border.all(
                            color: CupertinoColors.systemRed,
                            width: 2,
                          ),
                        ),
                      ),
                      showCursor: true,
                      onChanged: (_) {
                        if (_isOtpError) setState(() => _isOtpError = false);
                      },
                      onCompleted: (pin) => _verifyOtpReal(pin),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (_hasResentOtp)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Lưu ý: Nếu email không tồn tại hoặc hộp thư đầy, mã sẽ không thể gửi đến. Vui lòng kiểm tra kỹ hộp thư và mục Spam.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _kTextSub.withValues(alpha: 0.8),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (_regStep == RegisterStep.otpVerification) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() {
                      _regStep = RegisterStep.emailInput;
                    });
                  },
                  child: const Text(
                    'Dùng Gmail khác',
                    style: TextStyle(
                      color: _kTextSub,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _resendCountdown > 0 ? null : () => _resendOtp(),
                  child: Text(
                    _resendCountdown > 0
                        ? 'Gửi lại sau $_resendCountdown giây'
                        : 'Gửi lại mã OTP',
                    style: TextStyle(
                      color: _resendCountdown > 0 ? _kTextSub : _kBrand,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_regStep == RegisterStep.passwordSetup) ...[
            if (_isRegisteringWithPhone) ...[
              _buildDarkTextField(
                controller: _regExtraEmailCtrl,
                placeholder: 'Nhập địa chỉ Email (Bắt buộc)',
                prefixIcon: CupertinoIcons.mail_solid,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
            ],
            _buildDarkTextField(
              controller: _regPassCtrl,
              placeholder: 'Mật khẩu (tối thiểu 8 ký tự)',
              prefixIcon: CupertinoIcons.lock_fill,
              isPassword: true,
            ),
            const SizedBox(height: 14),
            _buildDarkTextField(
              controller: _regConfirmPassCtrl,
              placeholder: 'Xác nhận mật khẩu',
              prefixIcon: CupertinoIcons.lock_fill,
              isPassword: true,
            ),
          ],
          if (_regError != null) ...[
            const SizedBox(height: 12),
            Text(
              _regError!,
              style: const TextStyle(
                color: CupertinoColors.systemRed,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (_regStep != RegisterStep.otpVerification) ...[
            const SizedBox(height: 20),
            if (_regStep == RegisterStep.passwordSetup) ...[
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    _regStep = RegisterStep.otpVerification;
                  });
                },
                child: const Text(
                  '← Quay lại',
                  style: TextStyle(
                    color: _kTextSub,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            _buildGradientButton(
              text: _regStep == RegisterStep.emailInput
                  ? 'GỬI MÃ KÍCH HOẠT'
                  : 'HOÀN TẤT ĐĂNG KÝ',
              isLoading: _regLoading,
              onTap: _regStep == RegisterStep.emailInput
                  ? () => _sendOtp()
                  : () => _submitRegistration(),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SHARED WIDGETS
  // ═══════════════════════════════════════════════════════════════

  // Glass card wrapper
  Widget _buildGlassCard({required Widget child}) =>
      _AuthUiKit.glassCard(child: child);

  // Dark glass text field
  Widget _buildDarkTextField({
    required TextEditingController controller,
    required String placeholder,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    String? errorText,
  }) => _AuthUiKit.darkTextField(
    controller: controller,
    placeholder: placeholder,
    prefixIcon: prefixIcon,
    keyboardType: keyboardType,
    isPassword: isPassword,
    errorText: errorText,
  );

  // Gradient CTA button
  Widget _buildGradientButton({
    required String text,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return Transform.scale(
      scale: isLoading ? _pulseAnim.value : 1.0,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          gradient: LinearGradient(
            colors: isLoading
                ? [
                    _kBrand.withValues(alpha: 0.7),
                    _kBrand2.withValues(alpha: 0.7),
                  ]
                : [_kBrand, _kBrand2],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: _kBrand.withValues(alpha: isLoading ? 0.5 : 0.35),
              blurRadius: isLoading ? 28 : 18,
              spreadRadius: isLoading ? 3 : 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: CupertinoButton(
          padding: const EdgeInsets.symmetric(vertical: 17),
          onPressed: isLoading ? null : onTap,
          child: isLoading
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CupertinoActivityIndicator(
                        color: Colors.white,
                        radius: 10,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Đang xử lý...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
        ),
      ),
    );
  }

  // Avatar widget
  Widget _buildAvatar({
    String? avatarUrl,
    required String name,
    required double size,
  }) => _AuthUiKit.avatar(avatarUrl: avatarUrl, name: name, size: size);

  // Social section
  Widget _buildSocialSection(
    VoidCallback googleAction,
    VoidCallback facebookAction, {
    VoidCallback? zaloAction,
    VoidCallback? appleAction,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'Hoặc tiếp tục với',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(
                      color: _kBrand.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildSocialButton(
              label: 'Google',
              imageUrl:
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png',
              onPressed: googleAction,
            ),
            _buildSocialButton(
              label: 'Facebook',
              imageUrl:
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/Facebook_Logo_%282019%29.png/120px-Facebook_Logo_%282019%29.png',
              onPressed: facebookAction,
            ),
            _buildSocialButton(
              label: 'Zalo',
              imageUrl:
                  'https://stc-zaloprofile.zdn.vn/pc/v1/images/zalo_sharelogo.png',
              onPressed: zaloAction ?? () {},
            ),
            if (defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.macOS)
              _buildSocialButton(
                label: 'Apple',
                iconData: Icons.apple,
                iconColor: _kText,
                onPressed: appleAction ?? () {},
              ),
            _buildSocialButton(
              label: 'Khách',
              iconData: CupertinoIcons.person_fill,
              iconColor: _kTextSub,
              onPressed: () {
                unawaited(HapticFeedback.lightImpact());
                // Trải nghiệm khách (chưa đăng nhập) — không vào tenant-dashboard.
                context.go('/guest');
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    String? label,
    String? imageUrl,
    IconData? iconData,
    Color? iconColor,
    required VoidCallback onPressed,
  }) => _AuthUiKit.socialButton(
    label: label,
    imageUrl: imageUrl,
    iconData: iconData,
    iconColor: iconColor,
    onPressed: onPressed,
  );

  // Step progress for register
  Widget _buildStepProgress() {
    return Row(
      children: [
        _buildStepDot(1, _regStep.index >= 0),
        Expanded(
          child: Container(
            height: 2,
            color: _regStep.index >= 1 ? _kBrand : _kGlassB,
          ),
        ),
        _buildStepDot(2, _regStep.index >= 1),
        Expanded(
          child: Container(
            height: 2,
            color: _regStep.index >= 2 ? _kBrand : _kGlassB,
          ),
        ),
        _buildStepDot(3, _regStep.index >= 2),
      ],
    );
  }

  Widget _buildStepDot(int step, bool active) =>
      _AuthUiKit.stepDot(step, active);
}
