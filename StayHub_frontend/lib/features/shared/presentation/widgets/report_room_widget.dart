import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/deep_link_memory_service.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../../../core/providers/core_providers.dart';
import 'dart:async' show unawaited;

/// Widget báo cáo bài đăng vi phạm
/// Tuân thủ Luật Kinh doanh BĐS 2023 & NĐ 13/2023
class ReportRoomWidget extends ConsumerStatefulWidget {
  final String roomId;
  final String roomName;
  final Widget Function(VoidCallback onTap)? customBuilder;

  const ReportRoomWidget({
    super.key,
    required this.roomId,
    required this.roomName,
    this.customBuilder,
  });

  @override
  ConsumerState<ReportRoomWidget> createState() => _ReportRoomWidgetState();
}

class _ReportRoomWidgetState extends ConsumerState<ReportRoomWidget> {
  int? _selectedReason;
  final TextEditingController _detailCtrl = TextEditingController();
  bool _submitted = false;

  static const List<String> _reasons = [
    '🖼️ Ảnh không trung thực / chỉnh sửa quá mức',
    '💰 Giá đăng khác giá thực tế',
    '📍 Địa chỉ sai / không tồn tại',
    '🚫 Phòng đã cho thuê nhưng vẫn đăng',
    '⚠️ Nghi ngờ lừa đảo',
    '📵 Thông tin liên hệ giả',
    '🔞 Nội dung không phù hợp',
    '📝 Lý do khác',
  ];

  @override
  void dispose() {
    _detailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.customBuilder != null) {
      return widget.customBuilder!(() => _showReportModal(context));
    }
    return GestureDetector(
      onTap: () => _showReportModal(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: CupertinoColors.systemRed.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: CupertinoColors.systemRed.withValues(alpha: 0.2),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.flag_fill,
              color: CupertinoColors.systemRed,
              size: 14,
            ),
            SizedBox(width: 6),
            Text(
              'Báo cáo vi phạm',
              style: TextStyle(
                color: CupertinoColors.systemRed,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReportModal(BuildContext context) async {
    final isLoggedIn = ref.read(authProvider).value != null;
    if (!isLoggedIn) {
      await DeepLinkMemoryService.savePendingRoute(
        '/guest-room-detail',
        roomId: int.tryParse(widget.roomId),
      );

      if (context.mounted) {
        unawaited(
          showCupertinoModalPopup(
            context: context,
            builder: (_) => const CupertinoActionSheet(
              message: Text(
                'Vui lòng đăng nhập để báo cáo bài đăng này',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        );
        Future.delayed(const Duration(seconds: 1), () {
          if (!context.mounted) return;
          if (Navigator.canPop(context)) Navigator.pop(context);
          unawaited(context.push('/login'));
        });
      }
      return;
    }

    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (_) => StatefulBuilder(
          builder: (ctx, setModal) => Container(
            height: _submitted ? 280 : 520,
            decoration: const BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: _submitted ? _buildSuccess() : _buildForm(ctx, setModal),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: CupertinoColors.systemGreen.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          CupertinoIcons.checkmark_seal_fill,
          color: CupertinoColors.systemGreen,
          size: 36,
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        'Đã gửi báo cáo!',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
      ),
      const SizedBox(height: 8),
      const Text(
        'Cảm ơn bạn đã góp phần xây dựng\ncộng đồng StayHub lành mạnh.',
        style: TextStyle(
          color: CupertinoColors.systemGrey,
          fontSize: 14,
          height: 1.5,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 20),
      const Text(
        'Đội ngũ kiểm duyệt sẽ xem xét trong 24h.',
        style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 12),
      ),
    ],
  );

  Widget _buildForm(BuildContext ctx, StateSetter setModal) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey4,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        '🚩 Báo cáo bài đăng',
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
      ),
      const SizedBox(height: 4),
      Text(
        'Phòng: ${widget.roomName}',
        style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 13),
      ),
      const SizedBox(height: 16),
      const Text(
        'Lý do báo cáo',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      const SizedBox(height: 10),
      Expanded(
        child: ListView.builder(
          itemCount: _reasons.length,
          itemBuilder: (_, i) => GestureDetector(
            onTap: () => setModal(() => _selectedReason = i),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _selectedReason == i
                    ? AppTheme.kAccentColor.withValues(alpha: 0.1)
                    : CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _selectedReason == i
                      ? AppTheme.kAccentColor
                      : CupertinoColors.systemGrey5,
                  width: _selectedReason == i ? 1.5 : 1,
                ),
              ),
              child: Text(
                _reasons[i],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: _selectedReason == i
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: _selectedReason == i
                      ? AppTheme.kAccentColor
                      : CupertinoColors.label,
                ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: CupertinoButton(
          color: _selectedReason != null
              ? CupertinoColors.systemRed
              : CupertinoColors.systemGrey4,
          borderRadius: BorderRadius.circular(14),
          onPressed: _selectedReason != null
              ? () async {
                  try {
                    final dio = ref.read(apiClientProvider).dio;
                    await dio.post(
                      '/v1/rooms/reports',
                      data: {
                        'roomId': int.tryParse(widget.roomId) ?? 0,
                        'reason': _reasons[_selectedReason!],
                      },
                    );
                    setModal(() => _submitted = true);
                  } catch (e) {
                    if (ctx.mounted) {
                      unawaited(
                        showCupertinoDialog(
                          context: ctx,
                          builder: (context) => CupertinoAlertDialog(
                            title: const Text('Lỗi'),
                            content: Text(e.toString()),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text('Đóng'),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  }
                }
              : null,
          child: const Text(
            'Gửi báo cáo',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: CupertinoColors.white,
            ),
          ),
        ),
      ),
    ],
  );
}
