import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show ScaffoldMessenger, SnackBar, SnackBarBehavior, Colors;
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/application/auth_notifier.dart';
import 'dart:async' show unawaited;

class RentalScanLandingScreen extends ConsumerStatefulWidget {
  const RentalScanLandingScreen({super.key});

  @override
  ConsumerState<RentalScanLandingScreen> createState() =>
      _RentalScanLandingScreenState();
}

class _RentalScanLandingScreenState
    extends ConsumerState<RentalScanLandingScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _ctrl = MobileScannerController();
  bool _scanned = false;
  final ValueNotifier<bool> _isTorchOn = ValueNotifier(false);
  late AnimationController _scanAnimController;

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    unawaited(_scanAnimController.repeat(reverse: true));
  }

  @override
  void dispose() {
    unawaited(_ctrl.dispose());
    _isTorchOn.dispose();
    _scanAnimController.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanned) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final raw = barcode.rawValue!;

    if (!raw.startsWith('stayhub://room?')) {
      if (!mounted) return;
      _showError(
        context,
        'Mã QR không hợp lệ. Vui lòng quét mã QR phòng StayHub.',
      );
      return;
    }

    setState(() => _scanned = true);

    final uri = Uri.parse(raw);
    final roomId = int.tryParse(uri.queryParameters['id'] ?? '');
    final roomName = Uri.decodeComponent(
      uri.queryParameters['name'] ?? 'Phòng',
    );
    final branchId = int.tryParse(uri.queryParameters['branchId'] ?? '');
    final branchName = Uri.decodeComponent(
      uri.queryParameters['branchName'] ?? '',
    );
    final price = double.tryParse(uri.queryParameters['price'] ?? '0') ?? 0;

    if (roomId == null || branchId == null) {
      if (!mounted) return;
      _showError(context, 'Dữ liệu mã QR bị lỗi. Hãy thử lại.');
      setState(() => _scanned = false);
      return;
    }

    final authState = ref.read(authProvider);
    final user = authState.value;

    if (user != null && (user.role == 'STAFF' || user.role == 'OWNER')) {
      _showStaffOwnerOptions(roomId, roomName);
      return;
    }

    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.get('/v1/rooms/$roomId');
      if (res['success'] == true) {
        final roomData = res['data'];
        if (roomData['status'] == 'CLEANING_TURNOVER') {
          if (!mounted) return;
          _showError(
            context,
            'Phòng đang trong quá trình hoàn tất thủ tục bàn giao và vệ sinh. Vui lòng liên hệ chủ nhà hoặc quay lại sau!',
          );
          setState(() => _scanned = false);
          return;
        }
        if (roomData['status'] != 'TRONG' &&
            roomData['status'] != 'CHO_DUYET') {
          if (!mounted) return;
          _showError(
            context,
            'Phòng này hiện không trống. Vui lòng thử mã khác.',
          );
          setState(() => _scanned = false);
          return;
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showError(
        context,
        'Không thể lấy thông tin phòng. Vui lòng thử lại sau.',
      );
      setState(() => _scanned = false);
      return;
    }

    final extraData = {
      'roomId': roomId,
      'roomName': roomName,
      'branchId': branchId,
      'branchName': branchName,
      'price': price,
    };

    if (user != null &&
        (user.cccdNumber == null ||
            user.cccdNumber!.isEmpty ||
            user.hometown == null ||
            user.hometown!.isEmpty)) {
      if (!mounted) return;
      context.replace(
        '/profile-update',
        extra: {'nextRoute': '/rental-request', 'extraData': extraData},
      );
      return;
    }

    if (!mounted) return;
    context.replace('/rental-request', extra: extraData);
  }

  void _showStaffOwnerOptions(int roomId, String roomName) {
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: Text(
            'Phòng: $roomName',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          message: const Text('Chọn thao tác bạn muốn thực hiện'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                context.pop();
                unawaited(
                  context.push('/guest-room-detail', extra: {'roomId': roomId}),
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.house_alt, color: CupertinoColors.black),
                  SizedBox(width: 8),
                  Text(
                    'Chi tiết phòng',
                    style: TextStyle(color: CupertinoColors.black),
                  ),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                context.pop();
                unawaited(context.push('/bill', extra: {'roomId': roomId}));
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.doc_text,
                    color: CupertinoColors.systemGreen,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Xem hóa đơn',
                    style: TextStyle(color: CupertinoColors.systemGreen),
                  ),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                context.pop();
                unawaited(context.push('/ticket', extra: {'roomId': roomId}));
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.wrench,
                    color: CupertinoColors.systemOrange,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Sự cố (Ticket)',
                    style: TextStyle(color: CupertinoColors.systemOrange),
                  ),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _scanned = false);
              unawaited(_ctrl.start());
            },
            isDestructiveAction: true,
            child: const Text('Đóng'),
          ),
        ),
      ).then((_) {
        if (_scanned) {
          setState(() => _scanned = false);
          unawaited(_ctrl.start());
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      title: 'Thuê phòng',
      backgroundColors: AppTheme.kBackgroundLight,
      useScrollView: false,
      child: Column(
        children: [
          // ── Nửa Màn Hình Trên: Live Camera ──
          Container(
            height: MediaQuery.of(context).size.height * 0.45,
            margin: const EdgeInsets.only(left: 16, right: 16, top: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              color: CupertinoColors.black,
              boxShadow: [
                BoxShadow(
                  color: LiquidGlassColors.tenantAccent.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _ctrl,
                    onDetect: (capture) => _onDetect(capture),
                  ),
                  _buildScannerOverlay(),
                  Positioned(
                    top: 20,
                    right: 20,
                    left: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ValueListenableBuilder<bool>(
                          valueListenable: _isTorchOn,
                          builder: (context, isOn, _) {
                            return _buildControlButton(
                              icon: isOn
                                  ? CupertinoIcons.bolt_fill
                                  : CupertinoIcons.bolt_slash_fill,
                              label: 'Flash',
                              onTap: () async {
                                await _ctrl.toggleTorch();
                                _isTorchOn.value = !_isTorchOn.value;
                              },
                            );
                          },
                        ),
                        _buildControlButton(
                          icon: CupertinoIcons.photo,
                          label: 'Thư viện',
                          onTap: () {
                            if (!mounted) return;
                            _showError(
                              this.context,
                              'Tính năng chọn ảnh đang phát triển.',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Nút Nhập mã thủ công ──
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: LiquidGlassColors.tenantAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            onPressed: () => _showManualInputDialog(context, ref),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.keyboard,
                  color: LiquidGlassColors.tenantAccent,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Nhập mã phòng thủ công',
                  style: TextStyle(
                    color: LiquidGlassColors.tenantAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Nửa Màn Hình Dưới: Hướng dẫn & Cảnh báo ──
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: const BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(top: 24, bottom: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hướng dẫn Thuê Phòng',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: CupertinoColors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStep(
                      stepNumber: '1',
                      title: 'Quét mã QR hoặc Nhập mã phòng',
                      desc:
                          'Tìm mã QR trên cửa phòng hoặc hỏi chủ trọ mã phòng 6 chữ số.',
                      icon: CupertinoIcons.qrcode_viewfinder,
                    ),
                    _buildStep(
                      stepNumber: '2',
                      title: 'Xem chi tiết & Ký hợp đồng',
                      desc:
                          'Hệ thống sẽ hiển thị thông tin phòng, giá thuê. Bạn sẽ ký hợp đồng số (eKYC) ngay trên ứng dụng.',
                      icon: CupertinoIcons.doc_text_fill,
                    ),
                    _buildStep(
                      stepNumber: '3',
                      title: 'Thanh toán & Nhận phòng',
                      desc:
                          'Thanh toán tiền cọc, tháng đầu qua mã QR định danh và chuyển vào ở ngay!',
                      icon: CupertinoIcons.check_mark_circled_solid,
                      isLast: true,
                    ),

                    const SizedBox(height: 24),
                    // Safety Warning
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            CupertinoIcons.exclamationmark_triangle_fill,
                            color: Color(0xFFD97706),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  color: Color(0xFF92400E),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Cảnh báo an toàn:\n',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text:
                                        'Chỉ quét mã QR được dán chính thức trên cửa phòng hoặc do chủ trọ cung cấp qua app StayHub để tránh lừa đảo.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth * 0.6;
        final top = (constraints.maxHeight - size) / 2;
        final left = (constraints.maxWidth - size) / 2;
        return Stack(
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                CupertinoColors.black.withValues(alpha: 0.6),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: CupertinoColors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    top: top,
                    left: left,
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: CupertinoColors.black,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Corner Brackets
            Positioned(
              top: top,
              left: left,
              child: _buildCorner(Alignment.topLeft),
            ),
            Positioned(
              top: top,
              left: left + size - 30,
              child: _buildCorner(Alignment.topRight),
            ),
            Positioned(
              top: top + size - 30,
              left: left,
              child: _buildCorner(Alignment.bottomLeft),
            ),
            Positioned(
              top: top + size - 30,
              left: left + size - 30,
              child: _buildCorner(Alignment.bottomRight),
            ),

            // Scanning Line
            Positioned(
              top: top,
              left: left,
              child: AnimatedBuilder(
                animation: _scanAnimController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, size * _scanAnimController.value),
                    child: Container(
                      width: size,
                      height: 2,
                      decoration: BoxDecoration(
                        color: LiquidGlassColors.tenantAccent,
                        boxShadow: [
                          BoxShadow(
                            color: LiquidGlassColors.tenantAccent.withValues(
                              alpha: 0.8,
                            ),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCorner(Alignment alignment) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top:
              (alignment == Alignment.topLeft ||
                  alignment == Alignment.topRight)
              ? const BorderSide(color: Colors.white, width: 3)
              : BorderSide.none,
          bottom:
              (alignment == Alignment.bottomLeft ||
                  alignment == Alignment.bottomRight)
              ? const BorderSide(color: Colors.white, width: 3)
              : BorderSide.none,
          left:
              (alignment == Alignment.topLeft ||
                  alignment == Alignment.bottomLeft)
              ? const BorderSide(color: Colors.white, width: 3)
              : BorderSide.none,
          right:
              (alignment == Alignment.topRight ||
                  alignment == Alignment.bottomRight)
              ? const BorderSide(color: Colors.white, width: 3)
              : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required String stepNumber,
    required String title,
    required String desc,
    required IconData icon,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: LiquidGlassColors.tenantAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  stepNumber,
                  style: const TextStyle(
                    color: LiquidGlassColors.tenantAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: LiquidGlassColors.tenantAccent.withValues(alpha: 0.2),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: LiquidGlassColors.tenantAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: CupertinoColors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                desc,
                style: const TextStyle(
                  color: Color(0xFF4A5568),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  void _showManualInputDialog(BuildContext context, WidgetRef ref) {
    final TextEditingController codeCtrl = TextEditingController();
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Nhập Mã Code'),
          content: Column(
            children: [
              const SizedBox(height: 8),
              const Text(
                'Vui lòng nhập mã code 6 số do chủ nhà cung cấp (Mã có hiệu lực 5 phút).',
              ),
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: codeCtrl,
                placeholder: 'VD: 123456',
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  letterSpacing: 8,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text(
                'Hủy',
                style: TextStyle(color: AppTheme.kTextSecondary),
              ),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Xác nhận'),
              onPressed: () async {
                if (codeCtrl.text.trim().isNotEmpty) {
                  Navigator.pop(ctx);
                  await _verifyOtp(context, ref, codeCtrl.text.trim());
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyOtp(
    BuildContext context,
    WidgetRef ref,
    String otp,
  ) async {
    if (otp.isEmpty) return;
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.get('/v1/rooms/by-otp/$otp');
      if (res['success'] == true) {
        final data = res['data'];
        if (!context.mounted) return;

        if (data['status'] == 'CLEANING_TURNOVER') {
          if (!mounted) return;
          _showError(
            this.context,
            'Phòng đang trong quá trình hoàn tất thủ tục bàn giao và vệ sinh. Vui lòng liên hệ chủ nhà hoặc quay lại sau!',
          );
          return;
        }
        if (data['status'] != 'TRONG' && data['status'] != 'CHO_DUYET') {
          if (!mounted) return;
          _showError(
            this.context,
            'Phòng này hiện không trống. Vui lòng thử mã khác.',
          );
          return;
        }

        final extraData = {
          'roomId': data['id'],
          'roomName': data['roomName'],
          'branchId': data['branchId'],
          'branchName': data['branchName'],
          'price': data['price'],
        };

        final user = ref.read(authProvider).value;
        if (user != null &&
            (user.cccdNumber == null ||
                user.cccdNumber!.isEmpty ||
                user.hometown == null ||
                user.hometown!.isEmpty)) {
          context.replace(
            '/profile-update',
            extra: {'nextRoute': '/rental-request', 'extraData': extraData},
          );
          return;
        }

        context.replace('/rental-request', extra: extraData);
      }
    } catch (e) {
      if (context.mounted) {
        if (!mounted) return;
        _showError(this.context, 'Mã phòng không hợp lệ hoặc đã hết hạn.');
      }
    }
  }

  void _showError(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: CupertinoColors.systemRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
