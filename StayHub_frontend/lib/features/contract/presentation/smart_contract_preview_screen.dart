import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Colors, ScaffoldMessenger, SnackBar, showModalBottomSheet;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/services.dart';
import '../../../core/components/liquid_background.dart';
import '../../../core/components/bounce_click.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../application/electronic_contract_provider.dart';
import '../../auth/application/auth_notifier.dart';
import '../../../core/providers/core_providers.dart';
import '../../tenant/presentation/ekyc_verification_screen.dart';

import '../../voucher/application/voucher_provider.dart';
import '../../voucher/presentation/voucher_selection_sheet.dart';
import '../../../core/components/audit_logs_sheet.dart';
import 'dart:async' show unawaited;

class SmartContractPreviewScreen extends ConsumerStatefulWidget {
  final int contractId;
  final String pdfUrl;
  final String aiAppendix;
  final int roomId;

  const SmartContractPreviewScreen({
    super.key,
    required this.contractId,
    required this.pdfUrl,
    required this.aiAppendix,
    required this.roomId,
  });

  @override
  ConsumerState<SmartContractPreviewScreen> createState() =>
      _SmartContractPreviewScreenState();
}

class _SmartContractPreviewScreenState
    extends ConsumerState<SmartContractPreviewScreen> {
  final _otpCtrl = TextEditingController();
  late ConfettiController _confettiController;
  bool _isEkycVerified = false;
  int? _selectedVoucherId;
  bool _isSigning = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(electronicContractProvider.notifier).startCountdown();
      ref
          .read(electronicContractProvider.notifier)
          .listenToContractEvents(widget.roomId);
    });
  }

  void _showVoucherBottomSheet(List<dynamic> vouchers) {
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => VoucherSelectionSheet(
          vouchers: vouchers,
          initialVoucherId: _selectedVoucherId,
          onVoucherSelected: (id) {
            setState(() {
              _selectedVoucherId = id;
            });
          },
        ),
      ),
    );
  }

  Future<void> _signContract() async {
    if (_isSigning) return;

    final otp = _otpCtrl.text.trim();
    if (otp.length != 6 || int.tryParse(otp) == null) {
      _showError('Vui lòng nhập đúng 6 số OTP.');
      return;
    }

    setState(() {
      _isSigning = true;
    });

    final user = ref.read(authProvider).value;
    final role = user?.role == 'STAFF' || user?.role == 'ADMIN'
        ? 'OWNER'
        : 'TENANT'; // Lấy role thực tế

    try {
      await ref
          .read(electronicContractProvider.notifier)
          .signContract(
            widget.contractId,
            role,
            otp,
            voucherId: _selectedVoucherId,
          );
    } finally {
      if (mounted) {
        setState(() {
          _isSigning = false;
        });
      }
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Lỗi Ký Số'),
          content: Text(msg),
          actions: [
            CupertinoDialogAction(
              child: const Text('Đóng'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otpCtrl.dispose();
    _confettiController.dispose();
    // ref.read(electronicContractProvider.notifier).unsubscribe(); // Cần gọi nếu không dùng autoDispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(electronicContractProvider);

    // Listen to success event to trigger confetti
    ref.listen(electronicContractProvider, (previous, next) {
      if (next.error.isNotEmpty &&
          (previous == null || previous.error != next.error)) {
        _showError(next.error);
      }
      if (next.isSignatureSuccess &&
          (previous == null || !previous.isSignatureSuccess)) {
        _confettiController.play();
        Future.delayed(const Duration(seconds: 3), () {
          if (!context.mounted) return;
          if (mounted) context.go('/tenant-dashboard');
        });
      }
    });

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          LiquidBackground(
            colors: AppTheme.kBackgroundLight,
            child: Column(
              children: [
                CupertinoNavigationBar(
                  middle: const Text(
                    'Hợp Đồng Điện Tử',
                    style: TextStyle(color: CupertinoColors.black),
                  ),
                  backgroundColor: const Color(0x00000000),
                  border: null,
                  leading: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(
                      CupertinoIcons.back,
                      color: CupertinoColors.black,
                    ),
                    onPressed: () => context.pop(),
                  ),
                  trailing: CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(
                      CupertinoIcons.doc_text_search,
                      color: Color(0xFF6366F1),
                    ),
                    onPressed: () {
                      unawaited(HapticFeedback.lightImpact());
                      unawaited(
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => AuditLogsSheet(
                            entityType: 'CONTRACT',
                            entityId: widget.contractId,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // AI Highlight Banner
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE3F0FF), Color(0xFFF0FDF4)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF9CCBFF),
                        width: 1.5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x339CCBFF),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF298FFF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.sparkles,
                                color: CupertinoColors.white,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Bổ sung bởi StayHub AI',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A6FD4),
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        widget.aiAppendix.isNotEmpty
                            ? MarkdownBody(
                                data: widget.aiAppendix,
                                styleSheet: MarkdownStyleSheet(
                                  p: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF334155),
                                    height: 1.5,
                                  ),
                                ),
                              )
                            : const Text(
                                'Không có phụ lục thêm.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF4B5563),
                                  height: 1.5,
                                ),
                              ),
                      ],
                    ),
                  ),
                ),

                // PDF Viewer Area
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 24,
                          spreadRadius: -6,
                          offset: Offset(0, 12),
                        ),
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          spreadRadius: -4,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: SfPdfViewer.network(widget.pdfUrl),
                    ),
                  ),
                ),

                // OTP Signature Area
                if (!state.isSignatureSuccess)
                  Container(
                    padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 24,
                      bottom: MediaQuery.of(context).padding.bottom + 24,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white.withValues(alpha: 0.95),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF298FFF).withValues(alpha: 0.1),
                          blurRadius: 30,
                          offset: const Offset(0, -10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Nhập mã OTP để xác nhận ký',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: CupertinoColors.black,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Neon Countdown
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: state.countdownSeconds > 0
                                ? const Color(0xFFF3F4F6)
                                : const Color(
                                    0xFF298FFF,
                                  ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: state.countdownSeconds > 0
                                  ? Colors.transparent
                                  : const Color(
                                      0xFF298FFF,
                                    ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            state.countdownSeconds > 0
                                ? 'Gửi lại mã sau ${state.countdownSeconds}s'
                                : 'Bạn chưa nhận được mã? Gửi lại',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: state.countdownSeconds > 0
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF298FFF),
                              shadows: state.countdownSeconds == 0
                                  ? [
                                      const Shadow(
                                        color: Color(0x66298FFF),
                                        blurRadius: 10,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (ref.read(authProvider).value?.role == 'TENANT') ...[
                          Consumer(
                            builder: (context, ref, _) {
                              final vouchersAsync = ref.watch(
                                applicableVouchersProvider(widget.roomId),
                              );
                              return vouchersAsync.when(
                                data: (vouchers) {
                                  if (vouchers.isEmpty) {
                                    return const SizedBox.shrink();
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 16.0,
                                    ),
                                    child: BounceClick(
                                      onPressed: () =>
                                          _showVoucherBottomSheet(vouchers),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.elasticOut,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _selectedVoucherId == null
                                              ? const Color(0xFFF9FAFB)
                                              : const Color(
                                                  0xFF10B981,
                                                ).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          border: Border.all(
                                            color: _selectedVoucherId == null
                                                ? const Color(0xFFE5E7EB)
                                                : const Color(0xFF10B981),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _selectedVoucherId == null
                                                    ? 'Chọn mã giảm giá (Không bắt buộc)'
                                                    : 'Đã áp dụng: ${vouchers.firstWhere((v) => v.id == _selectedVoucherId, orElse: () => vouchers.first).code}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      _selectedVoucherId == null
                                                      ? const Color(0xFF6B7280)
                                                      : const Color(0xFF10B981),
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Icon(
                                              CupertinoIcons.ticket,
                                              size: 20,
                                              color: _selectedVoucherId == null
                                                  ? const Color(0xFF9CA3AF)
                                                  : const Color(0xFF10B981),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              );
                            },
                          ),
                        ],
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: CupertinoTextField(
                            controller: _otpCtrl,
                            placeholder: '------',
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: null,
                            readOnly:
                                state.isLoading ||
                                state.isTenantSigned ||
                                state.isOwnerSigned,
                            style: const TextStyle(
                              fontSize: 28,
                              letterSpacing: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1C1C1E),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (state.isTenantSigned)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 16.0),
                            child: Text(
                              'Khách thuê đã ký - Đang chờ Chủ nhà xác thực',
                              style: TextStyle(
                                color: CupertinoColors.activeGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (ref.read(authProvider).value?.role == 'TENANT' &&
                            !_isEkycVerified) ...[
                          BounceClick(
                            onPressed: () {
                              unawaited(HapticFeedback.heavyImpact());
                              unawaited(
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) =>
                                        EkycVerificationScreen(
                                          onVerificationComplete: () async {
                                            try {
                                              final api = ref.read(
                                                apiClientProvider,
                                              );
                                              final res = await api.post(
                                                '/v1/tenant/ekyc',
                                                data: {},
                                              );
                                              if (res['success'] == true) {
                                                if (context.mounted) {
                                                  Navigator.pop(context);
                                                  setState(
                                                    () =>
                                                        _isEkycVerified = true,
                                                  );
                                                }
                                              } else {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        res['message'] ??
                                                            'Lỗi xác thực eKYC',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Lỗi mạng: $e',
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                        ),
                                  ),
                                ),
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.elasticOut,
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFF59E0B),
                                    Color(0xFFD97706),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                  100,
                                ), // Pill shape
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFF59E0B,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CupertinoIcons
                                        .person_crop_circle_badge_checkmark,
                                    color: CupertinoColors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Xác thực định danh (eKYC) để Ký',
                                    style: TextStyle(
                                      color: CupertinoColors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          GestureDetector(
                            onTap:
                                _isSigning ||
                                    state.isLoading ||
                                    state.isSignatureSuccess
                                ? null
                                : () {
                                    unawaited(HapticFeedback.heavyImpact());
                                    unawaited(_signContract());
                                  },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.elasticOut,
                              width: state.isLoading ? 56 : double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF298FFF),
                                    Color(0xFF1A6FD4),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                  state.isLoading ? 28 : 100,
                                ), // Morphing circle to pill
                                boxShadow: state.isLoading
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF298FFF,
                                          ).withValues(alpha: 0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                              ),
                              child: Center(
                                child: state.isLoading
                                    ? const CupertinoActivityIndicator(
                                        color: CupertinoColors.white,
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            CupertinoIcons.signature,
                                            color: CupertinoColors.white,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Xác nhận Ký số',
                                            style: TextStyle(
                                              color: CupertinoColors.white,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality:
                  BlastDirectionality.explosive, // radial explosive
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
    );
  }
}
