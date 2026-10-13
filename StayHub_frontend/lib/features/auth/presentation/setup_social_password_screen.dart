import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/auth_notifier.dart';
import '../../../core/theme/app_theme.dart';

const _kBrand = Color(0xFF298FFF);
const _kText = Color(0xFF0F172A);
const _kTextSub = Color(0xFF475569);

class SetupSocialPasswordScreen extends ConsumerStatefulWidget {
  const SetupSocialPasswordScreen({super.key});

  @override
  ConsumerState<SetupSocialPasswordScreen> createState() =>
      _SetupSocialPasswordScreenState();
}

class _SetupSocialPasswordScreenState
    extends ConsumerState<SetupSocialPasswordScreen> {
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _isLoading = false;
  String? _errorText;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pass = _passCtrl.text.trim();
    final confirm = _confirmPassCtrl.text.trim();

    if (pass.length < 6) {
      setState(() => _errorText = 'Mật khẩu phải có ít nhất 6 ký tự');
      return;
    }
    if (pass != confirm) {
      setState(() => _errorText = 'Mật khẩu xác nhận không khớp');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.setupPassword(pass);

      if (!mounted) return;
      // Navigate based on role after setting password
      final authState = ref.read(authProvider);
      if (authState.hasValue && authState.value != null) {
        final role = authState.value!.role.toUpperCase();
        if (role == 'ADMIN') {
          context.go('/admin-panel');
        } else if (role == 'OWNER') {
          context.go('/owner-dashboard');
        } else if (role == 'STAFF') {
          context.go('/staff-dashboard');
        } else {
          context.go('/tenant-dashboard');
        }
      } else {
        // Không có user trong state (session hỏng) → không được "im lặng"
        // đứng yên tại màn này, đưa user về đăng nhập để xác thực lại.
        context.go('/login');
      }
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _errorText = e.toString().replaceAll('Exception:', '').trim(),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              28,
              24,
              28,
              24 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 48,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  // Lock icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _kBrand.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.lock_shield_fill,
                      size: 44,
                      color: _kBrand,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Bảo mật tài khoản',
                    style: TextStyle(
                      fontFamily: AppTheme.kFontFamily,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: _kText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Tạo mật khẩu để bạn có thể đăng nhập bằng Email + Mật khẩu ở những lần sau.',
                    style: TextStyle(
                      fontFamily: AppTheme.kFontFamily,
                      fontSize: 14,
                      color: _kTextSub,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                  // Password field
                  _buildTextField(
                    controller: _passCtrl,
                    placeholder: 'Mật khẩu mới',
                    obscure: _obscurePass,
                    onToggleObscure: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                  const SizedBox(height: 16),
                  // Confirm password field
                  _buildTextField(
                    controller: _confirmPassCtrl,
                    placeholder: 'Xác nhận mật khẩu',
                    obscure: _obscureConfirm,
                    onToggleObscure: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _errorText!,
                        style: const TextStyle(
                          fontFamily: AppTheme.kFontFamily,
                          color: CupertinoColors.systemRed,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  // Submit button
                  GestureDetector(
                    onTap: _isLoading ? null : _submit,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF298FFF), Color(0xFF6FA8FF)],
                        ),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: _kBrand.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isLoading
                            ? const CupertinoActivityIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'CẬP NHẬT MẬT KHẨU',
                                style: TextStyle(
                                  fontFamily: AppTheme.kFontFamily,
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String placeholder,
    required bool obscure,
    required VoidCallback onToggleObscure,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        placeholderStyle: const TextStyle(
          fontFamily: AppTheme.kFontFamily,
          color: _kTextSub,
          fontSize: 15,
        ),
        prefix: const Padding(
          padding: EdgeInsets.only(left: 16.0),
          child: Icon(CupertinoIcons.lock_fill, color: _kTextSub, size: 18),
        ),
        suffix: CupertinoButton(
          padding: const EdgeInsets.only(right: 12),
          onPressed: onToggleObscure,
          minimumSize: const Size(0, 0),
          child: Icon(
            obscure ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
            color: _kTextSub,
            size: 18,
          ),
        ),
        obscureText: obscure,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: const BoxDecoration(color: Colors.transparent),
        style: const TextStyle(
          fontFamily: AppTheme.kFontFamily,
          color: _kText,
          fontSize: 15,
        ),
      ),
    );
  }
}
