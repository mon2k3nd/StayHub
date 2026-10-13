import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/biometric_provider.dart';
import 'dart:async' show unawaited;

class BiometricUtils {
  static Future<bool> authenticate(BuildContext context, WidgetRef ref) async {
    final isEnabled = ref.read(biometricEnabledProvider);
    if (!isEnabled) return true; // Bypass if not enabled

    bool authenticated = false;

    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 350,
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A0A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Xác thực bảo mật',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Vui lòng xác nhận để tiếp tục giao dịch',
                style: TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              _BiometricPopupContent(
                onSuccess: () {
                  authenticated = true;
                  Navigator.pop(ctx);
                },
              ),
              const Spacer(),
              CupertinoButton(
                child: const Text(
                  'Hủy',
                  style: TextStyle(color: CupertinoColors.systemRed),
                ),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );

    return authenticated;
  }
}

class _BiometricPopupContent extends StatefulWidget {
  final VoidCallback onSuccess;
  const _BiometricPopupContent({required this.onSuccess});

  @override
  State<_BiometricPopupContent> createState() => _BiometricPopupContentState();
}

class _BiometricPopupContentState extends State<_BiometricPopupContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    unawaited(_pulseController.repeat(reverse: true));
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      widget.onSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: GestureDetector(
        onTap: _authenticate,
        child: Container(
          width: 90,
          height: 90,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF298FFF), Color(0xFF298FFF)],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF298FFF),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: _isAuthenticating
              ? const CupertinoActivityIndicator(color: CupertinoColors.white)
              : const Icon(
                  CupertinoIcons.lock_shield_fill,
                  color: CupertinoColors.white,
                  size: 40,
                ),
        ),
      ),
    );
  }
}
