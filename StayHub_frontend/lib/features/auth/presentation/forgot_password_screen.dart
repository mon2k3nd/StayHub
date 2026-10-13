import 'package:flutter/cupertino.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/liquid_background.dart';
import '../../../core/components/glass_button.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/components/premium_text_field.dart';
import 'dart:async' show unawaited;

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _otpSent = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  /// Email hợp lệ: có `@`, có tên miền và phần mở rộng (>= 2 ký tự).
  static final RegExp _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]{2,}$');

  /// Trích xuất thông điệp lỗi từ response backend.
  ///
  /// Backend luôn bọc dữ liệu trong `ApiResponse { success, message, data }`.
  /// Với `forgot-password`, message thực nằm trong `data.message`.
  String _extractMessage(Map<String, dynamic> res, String fallback) {
    final data = res['data'];
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return res['message']?.toString() ?? fallback;
  }

  // Trả về Future<void> thay vì `void` để lỗi async lan truyền được tới caller.
  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Vui lòng nhập Email.');
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      setState(
        () => _error = 'Email không đúng định dạng. Vui lòng kiểm tra lại.',
      );
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.post(
        '/v1/auth/forgot-password',
        data: {'email': email},
      );
      if (!mounted) return;
      // Backend trả ApiResponse{success:true, data:{message, devOtp}}.
      // Chỉ coi là thành công khi success != false (tránh false-negative khi
      // backend không set cờ success).
      if (res['success'] != false) {
        setState(() {
          _otpSent = true;
        });
        _showSuccessDialog('Đã gửi mã OTP đến email của bạn');
      } else {
        setState(() {
          _error = _extractMessage(res, 'Lỗi không xác định');
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Lỗi gửi yêu cầu: $e';
      });
    } finally {
      // finally đảm bảo spinner luôn được tắt kể cả khi dialog/setState ném lỗi.
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    setState(() => _error = null);
    final email = _emailCtrl.text.trim();
    final otp = _otpCtrl.text.trim();
    final newPass = _passCtrl.text;
    final confirmPass = _confirmPassCtrl.text;

    if (otp.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      setState(() => _error = 'Vui lòng điền đủ thông tin.');
      return;
    }
    if (otp.length != 6) {
      setState(() => _error = 'Mã OTP phải gồm 6 chữ số.');
      return;
    }
    // Backend yêu cầu tối thiểu 6 ký tự — validate sớm để tránh round-trip.
    if (newPass.length < 6) {
      setState(() => _error = 'Mật khẩu phải có ít nhất 6 ký tự.');
      return;
    }
    if (newPass != confirmPass) {
      setState(() => _error = 'Mật khẩu xác nhận không khớp.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.post(
        '/v1/auth/reset-password',
        data: {'email': email, 'otp': otp, 'newPassword': newPass},
      );

      if (!mounted) return;
      if (res['success'] != false) {
        _showSuccessDialog(
          'Mật khẩu đã được cập nhật thành công!',
          goBackToLogin: true,
        );
      } else {
        setState(() => _error = _extractMessage(res, 'Lỗi cập nhật mật khẩu'));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Lỗi cập nhật: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String message, {bool goBackToLogin = false}) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (dialogCtx) => CupertinoAlertDialog(
          title: const Text(
            'Thành công',
            style: TextStyle(color: CupertinoColors.systemGreen),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(message),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Đồng ý'),
              onPressed: () {
                Navigator.pop(dialogCtx);
                if (goBackToLogin && mounted) {
                  context.pop(); // Go back to login
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black.withValues(alpha: 0.5),
        middle: const Text(
          'Lấy lại mật khẩu',
          style: TextStyle(
            color: CupertinoColors.black,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: CupertinoColors.black),
          onPressed: () => context.pop(),
        ),
      ),
      child: LiquidBackground(
        colors: AppTheme.kBackgroundLight,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              MediaQuery.of(context).size.width < 360 ? 16 : 24,
              20,
              MediaQuery.of(context).size.width < 360 ? 16 : 24,
              20 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              children: [
                // Icon Header
                Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(top: 20, bottom: 24),
                  decoration: BoxDecoration(
                    color: AppTheme.kAccentColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      _otpSent
                          ? CupertinoIcons.lock_rotation
                          : CupertinoIcons.mail,
                      size: 40,
                      color: AppTheme.kAccentColor,
                    ),
                  ),
                ),

                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.1),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: _otpSent ? _buildResetForm() : _buildEmailForm(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Column(
      key: const ValueKey('email_form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NHẬP EMAIL CỦA BẠN',
          style: TextStyle(
            color: CupertinoColors.black,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Chúng tôi sẽ gửi mã OTP gồm 6 chữ số để bạn đặt lại mật khẩu.',
          style: TextStyle(color: AppTheme.kTextSecondary, fontSize: 13),
        ),
        const SizedBox(height: 24),
        PremiumTextField(
          controller: _emailCtrl,
          placeholder: 'VD: stayhub@example.com',
          prefixIcon: CupertinoIcons.mail_solid,
          keyboardType: TextInputType.emailAddress,
        ),
        if (_error != null) _buildError(),
        const SizedBox(height: 32),
        GlassButton(
          text: 'Gửi mã xác nhận',
          onPressed: _isLoading ? null : _sendOtp,
          isLoading: _isLoading,
          color: AppTheme.kAccentColor,
        ),
      ],
    );
  }

  Widget _buildResetForm() {
    return Column(
      key: const ValueKey('reset_form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'NHẬP MÃ OTP & MẬT KHẨU MỚI',
                style: TextStyle(
                  color: CupertinoColors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => setState(() {
                _otpSent = false;
                _error = null;
              }),
              child: const Text(
                'Đổi Email',
                style: TextStyle(fontSize: 12, color: AppTheme.kAccentColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Modern OTP Input Style
        PremiumTextField(
          controller: _otpCtrl,
          placeholder: 'Mã OTP (6 số)',
          prefixIcon: CupertinoIcons.lock_shield_fill,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        PremiumTextField(
          controller: _passCtrl,
          placeholder: 'Mật khẩu mới',
          prefixIcon: CupertinoIcons.lock_fill,
          isPassword: true,
        ),
        const SizedBox(height: 16),
        PremiumTextField(
          controller: _confirmPassCtrl,
          placeholder: 'Xác nhận mật khẩu mới',
          prefixIcon: CupertinoIcons.lock_fill,
          isPassword: true,
        ),
        if (_error != null) _buildError(),
        const SizedBox(height: 32),
        GlassButton(
          text: 'Xác nhận đổi mật khẩu',
          onPressed: _resetPassword,
          isLoading: _isLoading,
          color: CupertinoColors.black,
        ),
      ],
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Center(
        child: Text(
          _error!,
          style: const TextStyle(
            color: CupertinoColors.systemRed,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
