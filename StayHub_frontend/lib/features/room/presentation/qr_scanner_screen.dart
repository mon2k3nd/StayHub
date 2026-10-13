import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../auth/application/auth_notifier.dart';
import '../../../core/providers/core_providers.dart';
import 'dart:async' show unawaited;

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final MobileScannerController _ctrl = MobileScannerController();
  bool _scanned = false;
  final ValueNotifier<bool> _isTorchOn = ValueNotifier(false);

  @override
  void dispose() {
    unawaited(_ctrl.dispose());
    _isTorchOn.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanned) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final raw = barcode.rawValue!;

    if (!raw.startsWith('stayhub://room?')) {
      _showError('Mã QR không hợp lệ. Vui lòng quét mã QR phòng StayHub.');
      return;
    }

    setState(() => _scanned = true);

    final uri = Uri.parse(raw);

    // Hỗ trợ cả 2 format:
    // Format mới (generate-qr): ?token=...&roomId=...&roomName=...
    // Format cũ (legacy):       ?id=...&name=...&branchId=...
    final roomIdStr =
        uri.queryParameters['roomId'] ?? uri.queryParameters['id'];
    final roomId = int.tryParse(roomIdStr ?? '');
    final roomName = Uri.decodeComponent(
      uri.queryParameters['roomName'] ?? uri.queryParameters['name'] ?? 'Phòng',
    );
    final branchIdStr = uri.queryParameters['branchId'];
    final branchId = int.tryParse(branchIdStr ?? '');
    final branchName = Uri.decodeComponent(
      uri.queryParameters['branchName'] ?? '',
    );
    final price = double.tryParse(uri.queryParameters['price'] ?? '0') ?? 0;

    if (roomId == null) {
      _showError('Dữ liệu mã QR bị lỗi. Hãy thử lại.');
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
          _showError(
            'Phòng đang trong quá trình hoàn tất thủ tục bàn giao và vệ sinh. Vui lòng liên hệ chủ nhà hoặc quay lại sau!',
          );
          setState(() => _scanned = false);
          return;
        }
        if (roomData['status'] != 'TRONG' &&
            roomData['status'] != 'CHO_DUYET') {
          _showError('Phòng này hiện không trống. Vui lòng thử mã khác.');
          setState(() => _scanned = false);
          return;
        }
        // Ưu tiên thông tin từ API (đảm bảo dữ liệu mới nhất)
        final resolvedBranchId = branchId ?? roomData['branchId'];
        final resolvedBranchName = branchName.isNotEmpty
            ? branchName
            : (roomData['branchName'] ?? '');
        final resolvedPrice = price > 0
            ? price
            : ((roomData['price'] as num?)?.toDouble() ?? 0);

        final extraData = {
          'roomId': roomId,
          'roomName': roomData['roomName'] ?? roomName,
          'branchId': resolvedBranchId,
          'branchName': resolvedBranchName,
          'price': resolvedPrice,
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
        return;
      }
    } catch (e) {
      _showError('Không thể lấy thông tin phòng. Vui lòng thử lại sau.');
      setState(() => _scanned = false);
      return;
    }

    // Fallback nếu API không trả về dữ liệu
    final extraData = {
      'roomId': roomId,
      'roomName': roomName,
      'branchId': branchId ?? 0,
      'branchName': branchName,
      'price': price,
    };

    if (!mounted) return;
    context.replace('/rental-request', extra: extraData);
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: CupertinoColors.systemRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                  context.push('/room-detail', extra: {'roomId': roomId}),
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
                unawaited(
                  context.push('/bill', extra: {'roomId': roomId}),
                ); // Mở tab hóa đơn
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
                unawaited(
                  context.push('/ticket', extra: {'roomId': roomId}),
                ); // Mở tab sự cố
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
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black.withValues(alpha: 0.5),
        middle: const Text(
          'Quét Mã QR Phòng',
          style: TextStyle(color: CupertinoColors.black),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: CupertinoColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: _isTorchOn,
              builder: (context, isOn, _) {
                return CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(
                    isOn
                        ? CupertinoIcons.bolt_fill
                        : CupertinoIcons.bolt_slash_fill,
                    color: isOn
                        ? AppTheme.kAccentColor
                        : CupertinoColors.black.withValues(alpha: 0.5),
                  ),
                  onPressed: () async {
                    await _ctrl.toggleTorch();
                    _isTorchOn.value = !_isTorchOn.value;
                  },
                );
              },
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(
                CupertinoIcons.switch_camera,
                color: CupertinoColors.black.withValues(alpha: 0.5),
              ),
              onPressed: () => _ctrl.switchCamera(),
            ),
          ],
        ),
      ),
      child: Stack(
        children: [
          MobileScanner(
            controller: _ctrl,
            onDetect: (capture) => _onDetect(capture),
          ),
          _buildOverlay(),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: CupertinoColors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(0xFF4B5563).withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.qrcode_viewfinder,
                      color: AppTheme.kAccentColor,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Hướng camera vào mã QR của phòng',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: 0,
            right: 0,
            child: Center(
              child: CupertinoButton(
                color: LiquidGlassColors.tenantAccent,
                borderRadius: BorderRadius.circular(20),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                onPressed: _showOtpDialog,
                child: const Text(
                  'Nhập mã Code 5 phút',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOtpDialog() {
    final ctrl = TextEditingController();
    unawaited(
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(
            'Nhập Mã Code',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Vui lòng nhập mã code 6 số do chủ nhà cung cấp (Mã có hiệu lực 5 phút).',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  hintText: 'VD: 123456',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  letterSpacing: 8,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.pop(ctx),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: LiquidGlassColors.tenantAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Xác nhận'),
              onPressed: () async {
                Navigator.pop(ctx);
                await _verifyOtp(ctrl.text.trim());
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyOtp(String otp) async {
    if (otp.isEmpty) return;
    try {
      final apiClient = ref.read(apiClientProvider);
      final res = await apiClient.get('/v1/rooms/by-otp/$otp');
      if (res['success'] == true) {
        final data = res['data'];
        if (!mounted) return;

        if (data['status'] == 'CLEANING_TURNOVER') {
          _showError(
            'Phòng đang trong quá trình hoàn tất thủ tục bàn giao và vệ sinh. Vui lòng liên hệ chủ nhà hoặc quay lại sau!',
          );
          return;
        }
        if (data['status'] != 'TRONG' && data['status'] != 'CHO_DUYET') {
          _showError('Phòng này hiện không trống. Vui lòng thử mã khác.');
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
    } catch (e) {
      _showError('Mã phòng không hợp lệ hoặc đã hết hạn.');
    }
  }

  Widget _buildOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth * 0.65;
        final top = (constraints.maxHeight - size) / 2.5;
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
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: top,
              left: left,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppTheme.kAccentColor.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
