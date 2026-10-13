import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/providers/core_providers.dart';
import 'package:stayhub_frontend/core/components/stayhub_logo_icon.dart';
import 'dart:async' show unawaited;

class RoomQrScreen extends ConsumerStatefulWidget {
  final int roomId;
  final String roomName;
  final int branchId;
  final String branchName;
  final double price;

  const RoomQrScreen({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.branchId,
    required this.branchName,
    required this.price,
  });

  @override
  ConsumerState<RoomQrScreen> createState() => _RoomQrScreenState();
}

class _RoomQrScreenState extends ConsumerState<RoomQrScreen>
    with SingleTickerProviderStateMixin {
  String? _qrData;
  bool _isLoading = true;
  String? _error;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    unawaited(_pulseCtrl.repeat(reverse: true));
    _pulseAnim = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    unawaited(_generateQr());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _generateQr() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.post(
        '/v1/rooms/${widget.roomId}/generate-qr',
        data: {},
      );
      if (res['success'] == true) {
        // BUGFIX (data): `res['data']` có thể là null/không phải Map → tránh
        // TypeError khi backend trả payload rỗng.
        final rawData = res['data'];
        final data = rawData is Map ? rawData : const <String, dynamic>{};
        setState(() => _qrData = data['qrData']?.toString());
      } else {
        setState(() => _error = 'Không thể tạo mã QR');
      }
    } catch (e) {
      setState(() => _error = 'Lỗi: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _copyLink() {
    if (_qrData == null) return;
    unawaited(Clipboard.setData(ClipboardData(text: _qrData!)));
    unawaited(HapticFeedback.lightImpact());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Đã sao chép link!'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _regenerateQr() async {
    unawaited(HapticFeedback.mediumImpact());
    setState(() {
      _qrData = null;
      _isLoading = true;
    });
    // Force regenerate: a new QR token by calling backend (it will keep same token if already exists,
    // so we clear on server side manually for now - in practice, a refresh would be explicit)
    await _generateQr();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Mã QR Phòng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0B192C),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(CupertinoIcons.back, color: Colors.white),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _regenerateQr(),
          child: const Icon(
            CupertinoIcons.refresh,
            color: Color(0xFF298FFF),
            size: 20,
          ),
        ),
      ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B192C), Color(0xFF0F2850), Color(0xFF0D1F3C)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Room info card
                _buildRoomInfoCard(),
                const SizedBox(height: 32),

                // QR Area
                _buildQrArea(),

                const SizedBox(height: 32),

                // Instructions
                _buildInstructionCard(),

                const SizedBox(height: 28),

                // Action buttons
                _buildActionButtons(),

                const SizedBox(height: 24),

                // Deep-link text
                if (_qrData != null) _buildDeepLinkText(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoomInfoCard() {
    final priceM = widget.price / 1000000;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF298FFF).withValues(alpha: 0.2),
            const Color(0xFF298FFF).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF298FFF).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF298FFF).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const StayHubLogoIcon(color: Color(0xFF298FFF), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.roomName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.branchName,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '${priceM.toStringAsFixed(1)} triệu/tháng',
                        style: const TextStyle(
                          color: Color(0xFF10B981),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrArea() {
    if (_isLoading) {
      return Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoActivityIndicator(radius: 16, color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Đang tạo mã QR...',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null || _qrData == null) {
      return Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                color: Colors.red,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                _error ?? 'Không tải được QR',
                style: const TextStyle(color: Colors.red, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                color: const Color(0xFF298FFF),
                borderRadius: BorderRadius.circular(12),
                onPressed: _generateQr,
                child: const Text(
                  'Thử lại',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ScaleTransition(
      scale: _pulseAnim,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF298FFF).withValues(alpha: 0.4),
              blurRadius: 40,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          children: [
            QrImageView(
              data: _qrData!,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF0B192C),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF298FFF),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'STH-${widget.roomId}',
                style: const TextStyle(
                  color: Color(0xFF0B192C),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.info_circle_fill,
                color: Color(0xFF298FFF),
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Hướng dẫn sử dụng',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _InstructionRow(
            step: '1',
            text: 'Khách thuê quét mã QR bằng app StayHub',
          ),
          SizedBox(height: 8),
          _InstructionRow(
            step: '2',
            text:
                'Hệ thống sẽ tự động điền thông tin phòng khi gửi yêu cầu thuê',
          ),
          SizedBox(height: 8),
          _InstructionRow(
            step: '3',
            text: 'Bạn phê duyệt yêu cầu và tạo hợp đồng điện tử ngay lập tức',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _qrData == null ? null : _copyLink,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Column(
                children: [
                  Icon(
                    CupertinoIcons.doc_on_clipboard_fill,
                    color: Colors.white,
                    size: 22,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Sao chép link',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _qrData == null
                ? null
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chức năng chia sẻ đang phát triển')));
                    unawaited(HapticFeedback.lightImpact());
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Tính năng chia sẻ sẽ có trong bản cập nhật tiếp theo',
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF298FFF), Color(0xFF1A6FD4)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                children: [
                  Icon(
                    CupertinoIcons.share_solid,
                    color: Colors.white,
                    size: 22,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Chia sẻ cho khách',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeepLinkText() {
    final shortLink = _qrData!.length > 60
        ? '${_qrData!.substring(0, 60)}...'
        : _qrData!;
    return GestureDetector(
      onTap: _copyLink,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            const Icon(CupertinoIcons.link, color: Color(0xFF6B7280), size: 14),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                shortLink,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const Icon(
              CupertinoIcons.doc_on_clipboard,
              color: Color(0xFF6B7280),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructionRow extends StatelessWidget {
  final String step;
  final String text;
  const _InstructionRow({required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFF298FFF).withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: const TextStyle(
                color: Color(0xFF298FFF),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFD1D5DB),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
