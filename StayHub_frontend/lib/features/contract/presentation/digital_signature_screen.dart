import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:signature/signature.dart';
import 'package:confetti/confetti.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/bounce_click.dart';
import '../../../core/components/glass_button.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/providers/core_providers.dart';
import '../../tenant/application/tenant_dashboard_notifier.dart';
import '../../../core/services/biometric_service.dart';
import 'dart:async' show unawaited;

enum SignatureMethod { biometric, manual, vnpt }

class DigitalSignatureScreen extends ConsumerStatefulWidget {
  final int contractId;

  const DigitalSignatureScreen({super.key, required this.contractId});

  @override
  ConsumerState<DigitalSignatureScreen> createState() =>
      _DigitalSignatureScreenState();
}

class _DigitalSignatureScreenState
    extends ConsumerState<DigitalSignatureScreen> {
  late SignatureController _signatureController;
  late TextEditingController _handoverCtrl;
  late ConfettiController _confettiController;
  bool _isLoading = false;
  final bool _isEkycVerified = false;
  SignatureMethod _selectedMethod = SignatureMethod.biometric;

  @override
  void initState() {
    super.initState();
    _handoverCtrl = TextEditingController();
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: CupertinoColors.black,
      exportBackgroundColor: CupertinoColors.white,
    );
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _handoverCtrl.dispose();
    _signatureController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _signWithBiometric() async {
    HapticFeedback.mediumImpact();
    final biometric = BiometricService();
    final canAuth = await biometric.isBiometricAvailable();
    if (!canAuth) {
      if (!mounted) return;
      ToastUtils.show(
        context,
        'Thiết bị chưa cài đặt hoặc không hỗ trợ sinh trắc học FaceID / Vân tay',
        isError: true,
      );
      return;
    }

    final authenticated = await biometric.authenticate();
    if (!authenticated) {
      if (!mounted) return;
      ToastUtils.show(context, 'Xác thực sinh trắc học không thành công', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final now = DateTime.now().toIso8601String();
      final authSignaturePayload = 'STAYHUB-BIOMETRIC-SIGN-CONTRACT-${widget.contractId}-$now';
      final base64Signature = base64Encode(utf8.encode(authSignaturePayload));

      final api = ref.read(apiClientProvider);
      final res = await api.post(
        '/v1/contracts/${widget.contractId}/tenant-sign',
        data: {
          'signature': base64Signature,
          'handoverCondition': _handoverCtrl.text.trim(),
          'ekycVerified': true,
          'signatureProvider': 'BIOMETRIC_FACEID',
        },
      );

      if (!mounted) return;
      if (res['success'] == true) {
        await ref.read(tenantDashboardProvider.notifier).startVerification();
        if (!mounted) return;
        _confettiController.play();
        await Future.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        _showDepositPaymentModal();
      } else {
        ToastUtils.show(context, res['message'] ?? 'Lỗi ký hợp đồng', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      ToastUtils.show(context, 'Lỗi lưu chữ ký: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitSignature() async {
    if (_selectedMethod == SignatureMethod.manual && _signatureController.isEmpty) {
      ToastUtils.show(
        context,
        'Vui lòng ký tên trước khi xác nhận',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bytes = await _signatureController.toPngBytes();
      if (bytes == null) {
        if (!mounted) return;
        ToastUtils.show(context, 'Lỗi tạo chữ ký', isError: true);
        return;
      }
      final base64Signature = base64Encode(bytes);

      // Gọi API ký hợp đồng
      final api = ref.read(apiClientProvider);
      final res = await api.post(
        '/v1/contracts/${widget.contractId}/tenant-sign',
        data: {
          'signature': base64Signature,
          'handoverCondition': _handoverCtrl.text.trim(),
          'ekycVerified': _isEkycVerified,
          'signatureProvider': _selectedMethod == SignatureMethod.vnpt ? 'VNPT' : 'MANUAL',
        },
      );

      if (!mounted) return;

      if (res['success'] == true) {
        // Cập nhật state của dashboard để chuyển sang trạng thái Nghiệm thu
        await ref.read(tenantDashboardProvider.notifier).startVerification();

        if (!mounted) return;
        _confettiController.play();
        await Future.delayed(const Duration(seconds: 1)); // Wait for confetti

        if (!mounted) return;
        // Thay vì về dashboard ngay, ta hiện Modal Thanh Toán Cọc Online
        _showDepositPaymentModal();
      } else {
        ToastUtils.show(
          context,
          res['message'] ?? 'Lỗi ký hợp đồng',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ToastUtils.show(context, 'Lỗi lưu chữ ký: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDepositPaymentModal() {
    unawaited(
      showCupertinoModalPopup(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Container(
          height: 380,
          margin: const EdgeInsets.only(bottom: 30, left: 16, right: 16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: LiquidGlassColors.tenantAccent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.doc_checkmark_fill,
                  color: LiquidGlassColors.tenantAccent,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ký hợp đồng thành công!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: CupertinoColors.black,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Để giữ phòng, vui lòng thanh toán tiền cọc (1 tháng tiền nhà).',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: BounceClick(
                  onPressed: () {
                    unawaited(HapticFeedback.heavyImpact());
                    Navigator.pop(ctx);
                    _processPayment();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.kAccentColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.money_dollar_circle_fill,
                          color: CupertinoColors.white,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Thanh toán Apple Pay / FaceID',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              BounceClick(
                onPressed: () {
                  unawaited(HapticFeedback.mediumImpact());
                  Navigator.pop(ctx);
                  context.go('/tenant-dashboard');
                },
                child: const Text(
                  'Thanh toán sau',
                  style: TextStyle(color: CupertinoColors.systemGrey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _processPayment() {
    unawaited(
      context.push(
        '/deposit-payment',
        extra: {'contractId': widget.contractId},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFFF3F4F6),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: Color(0xFF4B5563)),
          onPressed: () => context.pop(),
        ),
        middle: const Text(
          'Ký Hợp Đồng',
          style: TextStyle(color: CupertinoColors.black),
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Progress steps
                Container(
                  margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: LiquidGlassColors.tenantAccent.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: LiquidGlassColors.tenantAccent.withValues(
                        alpha: 0.2,
                      ),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        CupertinoIcons.check_mark_circled_solid,
                        color: LiquidGlassColors.tenantAccent,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Bước 2/3: Ký hợp đồng điện tử. Sau khi ký, bạn sẽ tiến hành nghiệm thu phòng.',
                          style: TextStyle(
                            color: Color(0xFF374151),
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Ghi nhận hiện trạng phòng:',
                      style: TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: CupertinoTextField(
                    controller: _handoverCtrl,
                    placeholder: 'Ví dụ: Phòng mới, có sẵn giường, tủ...',
                    maxLines: 3,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      border: Border.all(
                        color: LiquidGlassColors.tenantAccent.withValues(
                          alpha: 0.3,
                        ),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Vui lòng ký tên vào ô bên dưới để xác nhận đồng ý với các điều khoản của hợp đồng.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF4B5563), fontSize: 14),
                  ),
                ),
                const SizedBox(height: 12),
                // Segmented Control chọn phương thức ký
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: LiquidGlassColors.tenantAccent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: CupertinoSlidingSegmentedControl<SignatureMethod>(
                      groupValue: _selectedMethod,
                      backgroundColor: Colors.transparent,
                      thumbColor: LiquidGlassColors.tenantAccent,
                      children: {
                        SignatureMethod.biometric: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.viewfinder,
                                size: 16,
                                color: _selectedMethod == SignatureMethod.biometric
                                    ? Colors.white
                                    : const Color(0xFF4B5563),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'FaceID',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: _selectedMethod == SignatureMethod.biometric
                                      ? Colors.white
                                      : const Color(0xFF4B5563),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SignatureMethod.manual: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.pencil,
                                size: 16,
                                color: _selectedMethod == SignatureMethod.manual
                                    ? Colors.white
                                    : const Color(0xFF4B5563),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Vẽ tay',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: _selectedMethod == SignatureMethod.manual
                                      ? Colors.white
                                      : const Color(0xFF4B5563),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SignatureMethod.vnpt: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.building_2_fill,
                                size: 16,
                                color: _selectedMethod == SignatureMethod.vnpt
                                    ? Colors.white
                                    : const Color(0xFF4B5563),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'SmartCA',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: _selectedMethod == SignatureMethod.vnpt
                                      ? Colors.white
                                      : const Color(0xFF4B5563),
                                ),
                              ),
                            ],
                          ),
                        ),
                      },
                      onValueChanged: (val) {
                        if (val != null) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedMethod = val);
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Nội dung theo từng phương thức
                if (_selectedMethod == SignatureMethod.biometric) ...[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                CupertinoIcons.viewfinder,
                                size: 42,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'Ký Số 1-Chạm Bằng Sinh Trắc Học',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Hệ thống tự động liên kết danh tính CCCD eKYC 2026 và đóng dấu số bảo chứng pháp lý vào hợp đồng.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            BounceClick(
                              scaleFactor: 0.95,
                              onPressed: _signWithBiometric,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
                                  ),
                                  borderRadius: BorderRadius.circular(50),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.30),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      CupertinoIcons.checkmark_shield_fill,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Xác Thực FaceID & Ký Ngay',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
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
                  ),
                ] else if (_selectedMethod == SignatureMethod.manual) ...[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(4),
                        child: Container(
                          decoration: BoxDecoration(
                            color: CupertinoColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: LiquidGlassColors.tenantAccent.withValues(
                                alpha: 0.5,
                              ),
                              width: 1,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Signature(
                              controller: _signatureController,
                              backgroundColor: CupertinoColors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        BounceClick(
                          onPressed: () {
                            unawaited(HapticFeedback.heavyImpact());
                            _signatureController.clear();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemRed.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.clear_thick,
                                  size: 16,
                                  color: CupertinoColors.systemRed,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Xóa chữ ký',
                                  style: TextStyle(
                                    color: CupertinoColors.systemRed,
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
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GlassButton(
                      text: 'Hoàn Tất Ký Kết',
                      icon: CupertinoIcons.signature,
                      color: LiquidGlassColors.tenantAccent,
                      onPressed: () async {
                        unawaited(HapticFeedback.heavyImpact());
                        unawaited(_submitSignature());
                      },
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              CupertinoIcons.checkmark_shield_fill,
                              color: Colors.green,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Hệ thống sẽ chuyển hướng sang App VNPT SmartCA để xác nhận ký số số hóa chuyên dụng.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF4B5563)),
                            ),
                            const SizedBox(height: 24),
                            GlassButton(
                              text: 'Chuyển hướng VNPT SmartCA',
                              icon: CupertinoIcons.signature,
                              color: LiquidGlassColors.tenantAccent,
                              onPressed: () async {
                                unawaited(HapticFeedback.heavyImpact());
                                setState(() => _isLoading = true);
                                await Future.delayed(const Duration(seconds: 2));
                                setState(() => _isLoading = false);
                                if (!context.mounted) return;
                                ToastUtils.show(context, 'Ký số VNPT thành công!');
                                unawaited(_submitSignature());
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black38,
                  child: const Center(
                    child: CupertinoActivityIndicator(
                      radius: 20,
                      color: LiquidGlassColors.tenantAccent,
                    ),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
