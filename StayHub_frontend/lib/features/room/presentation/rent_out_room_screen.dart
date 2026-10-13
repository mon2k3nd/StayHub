import 'dart:async';
import 'package:flutter/cupertino.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/providers/core_providers.dart';
import '../application/room_notifier.dart';
import '../data/models/room_model.dart';
import '../../branch/application/branch_notifier.dart';
import '../../../core/components/app_error_widget.dart';
import 'package:stayhub_frontend/core/components/stayhub_logo_icon.dart';

class RentOutRoomScreen extends ConsumerStatefulWidget {
  const RentOutRoomScreen({super.key});

  @override
  ConsumerState<RentOutRoomScreen> createState() => _RentOutRoomScreenState();
}

class _RentOutRoomScreenState extends ConsumerState<RentOutRoomScreen> {
  @override
  Widget build(BuildContext context) {
    final roomsState = ref.watch(roomProvider);
    final branches = ref.watch(branchProvider).value ?? [];

    return LiquidGlassScaffold(
      title: 'Cho Thuê Phòng',
      backgroundColors: AppTheme.kBackgroundLight,
      child: roomsState.when(
        data: (rooms) {
          final emptyRooms = rooms.where((r) => r.status == 'TRONG').toList();

          if (emptyRooms.isEmpty) {
            return const Center(
              child: Text(
                'Hiện không có phòng trống nào.',
                style: TextStyle(color: AppTheme.kTextSecondary, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: emptyRooms.length,
            itemBuilder: (context, index) {
              final room = emptyRooms[index];
              final branchName = branches.isNotEmpty
                  ? branches
                        .firstWhere(
                          (b) => b.id == room.branchId,
                          orElse: () => branches.first,
                        )
                        .branchName
                  : 'Chưa có tên dãy';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: CupertinoColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CupertinoButton(
                  padding: const EdgeInsets.all(16),
                  onPressed: () => _showRentalModal(context, room, branchName),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.kSurfaceBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const StayHubLogoIcon(
                          color: AppTheme.kAccentColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              room.roomName,
                              style: const TextStyle(
                                color: AppTheme.kTextPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              branchName,
                              style: const TextStyle(
                                color: AppTheme.kTextMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        CupertinoIcons.chevron_right,
                        color: AppTheme.kBorderColor,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (err, _) => AppErrorWidget(error: err),
      ),
    );
  }

  void _showRentalModal(
    BuildContext context,
    RoomModel room,
    String branchName,
  ) {
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) =>
            _RentalModalContent(room: room, branchName: branchName),
      ),
    );
  }
}

class _RentalModalContent extends ConsumerStatefulWidget {
  final RoomModel room;
  final String branchName;

  const _RentalModalContent({required this.room, required this.branchName});

  @override
  ConsumerState<_RentalModalContent> createState() =>
      _RentalModalContentState();
}

class _RentalModalContentState extends ConsumerState<_RentalModalContent> {
  int _selectedSegment = 0; // 0: QR, 1: OTP

  Timer? _timer;
  int _secondsRemaining = 300; // 5 mins
  String _currentOtp = '';

  @override
  void initState() {
    super.initState();
    unawaited(_generateOtp());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _generateOtp() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post('/v1/rooms/${widget.room.id}/generate-otp');
      if (res.data != null && res.data['success'] == true) {
        final otp = res.data['data']['activeOtpCode'];
        if (mounted) {
          setState(() {
            _currentOtp = otp;
            _secondsRemaining = 300; // 5 mins
          });
          _startTimer();
        }
      } else {
        throw Exception(res.data['message'] ?? 'Lỗi không xác định');
      }
    } catch (e) {
      if (mounted) {
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Lỗi'),
              content: Text('Không thể tạo mã OTP: $e'),
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
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _formattedTime {
    final m = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final isExpired = _secondsRemaining == 0;
    final isWarning = _secondsRemaining < 60;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.kBorderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Tạo mã: ${widget.room.roomName} - ${widget.branchName}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.kTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: _selectedSegment,
                children: const {
                  0: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'MÃ QR CỐ ĐỊNH',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  1: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'MÃ CODE 5 PHÚT',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                },
                onValueChanged: (val) {
                  if (val != null) setState(() => _selectedSegment = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 40),

          Expanded(
            child: _selectedSegment == 0
                ? _buildQrSegment()
                : _buildOtpSegment(isExpired, isWarning),
          ),
        ],
      ),
    );
  }

  Widget _buildQrSegment() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: QrImageView(
            data: 'stayhub://room/${widget.room.id}',
            version: QrVersions.auto,
            size: 220.0,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: AppTheme.kTextPrimary,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: AppTheme.kTextPrimary,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            'Khách thuê sử dụng tính năng Quét Mã QR trên ứng dụng StayHub để liên kết tự động.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.kTextMuted,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpSegment(bool isExpired, bool isWarning) {
    return Column(
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isExpired ? 0.1 : 1.0,
          child: Container(
            width: 240,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: AppTheme.kSurfaceBlue,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.kAccentColor,
                width: 2,
                style: BorderStyle.solid,
              ), // Bỏ Dashed do không có package, thay bằng viền liền
              boxShadow: [
                BoxShadow(
                  color: AppTheme.kAccentColor.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _currentOtp,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 8,
                  color: AppTheme.kAccentColor,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        if (isExpired) ...[
          const Text(
            '⚠️ Mã bảo mật đã hết hạn!',
            style: TextStyle(
              color: CupertinoColors.systemRed,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            color: AppTheme.kAccentColor,
            borderRadius: BorderRadius.circular(24),
            onPressed: () {
              // Bug fix: không gọi async void trong setState
              setState(() {});
              unawaited(_generateOtp());
            },
            child: const Text(
              '🔄 Tạo mã mới',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ] else ...[
          Text(
            'Mã code có hiệu lực trong: $_formattedTime',
            style: TextStyle(
              color: isWarning
                  ? CupertinoColors.systemRed
                  : AppTheme.kTextSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: AppTheme.kBackgroundLightGray,
            borderRadius: BorderRadius.circular(20),
            onPressed: () {
              unawaited(Clipboard.setData(ClipboardData(text: _currentOtp)));
            },
            child: const Text(
              'Sao chép nhanh',
              style: TextStyle(
                color: AppTheme.kTextPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
