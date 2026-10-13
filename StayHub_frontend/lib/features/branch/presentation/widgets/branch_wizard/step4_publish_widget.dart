import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/components/glass_container.dart';
import '../../../../../core/utils/toast_utils.dart';
import '../../../application/branch_notifier.dart';
import '../../../data/models/branch_model.dart';
import 'branch_wizard_theme.dart';
import 'step4_room_config_widget.dart' show roomsProvider, facilitiesProvider;

/// BƯỚC 5 — Xác nhận & Đăng bài.
///
/// Chỉ khi CẢ 5 bước đều hoàn tất thì hệ thống mới ghi nhận chi nhánh là
/// "đã tạo" (creationStatus = COMPLETED) và đưa vào thống kê / chợ trọ.
/// Nếu còn bước chưa xong, chi nhánh nằm ở trạng thái "đang cấu hình"
/// và KHÔNG được tính vào bất kỳ thống kê nào.
///
/// Việc chuyển trạng thái COMPLETED do backend tự xử lý trong `markStep`
/// khi cả 5 cờ step đều true — frontend chỉ cần gọi `markStep(id, 5, true)`.
class Step4PublishWidget extends ConsumerStatefulWidget {
  final BranchModel? branch;
  final ValueChanged<BranchModel> onCompleted;

  const Step4PublishWidget({
    super.key,
    required this.branch,
    required this.onCompleted,
  });

  @override
  ConsumerState<Step4PublishWidget> createState() => _Step4PublishWidgetState();
}

class _Step4PublishWidgetState extends ConsumerState<Step4PublishWidget> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.branch;
    final done = b?.step5Done ?? false;

    return WzStepScaffold(
      title: 'Bước 5 · Xác nhận & đăng bài',
      subtitle: 'Kiểm tra lại toàn bộ cấu hình trước khi hoạt động',
      bottomBar: _buildActionButton(b, done),
      children: [
        const WzInfoCard(
          icon: CupertinoIcons.paperplane_fill,
          title: 'Xác nhận & đăng bài',
          description:
              'Kiểm tra lại toàn bộ cấu hình. Khi bạn xác nhận, chi nhánh sẽ '
              'chính thức hoạt động và xuất hiện trên chợ trọ.',
        ),
        const SizedBox(height: WzSpacing.md),
        _buildStepSummary(b),
        const SizedBox(height: WzSpacing.md),
        const WzNoticeCard(
          tone: WzNoticeTone.warning,
          message:
              'Chi nhánh chỉ được tính vào thống kê và hiển thị trên chợ trọ '
              'khi hoàn tất đủ 5 bước. Nếu còn bước chưa xong, chi nhánh sẽ '
              'nằm ở nhóm "Đang khởi tạo".',
        ),
      ],
    );
  }

  Widget _buildStepSummary(BranchModel? b) {
    final steps = <(String, bool)>[
      ('Khung vận hành chi nhánh', b?.step1Done ?? false),
      ('Tài sản chung của toà nhà', b?.step2Done ?? false),
      ('Cấu trúc không gian & WC chung', b?.step3Done ?? false),
      ('Cấu hình phòng chi tiết', b?.step4Done ?? false),
      ('Xác nhận & đăng bài', b?.step5Done ?? false),
    ];

    return GlassContainer(
      padding: const EdgeInsets.symmetric(
        horizontal: WzSpacing.lg,
        vertical: WzSpacing.xs,
      ),
      child: Column(
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: WzSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: steps[i].$2
                          ? WzColors.success
                          : WzColors.surfaceMuted,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: steps[i].$2
                          ? const Icon(
                              CupertinoIcons.checkmark_alt,
                              size: 14,
                              color: Colors.white,
                            )
                          : Text(
                              '${i + 1}',
                              style: WzText.label.copyWith(
                                color: WzColors.textFaint,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: WzSpacing.md),
                  Expanded(
                    child: Text(
                      steps[i].$1,
                      style: WzText.rowTitle.copyWith(
                        color: steps[i].$2
                            ? WzColors.textPrimary
                            : WzColors.textFaint,
                      ),
                    ),
                  ),
                  WzStatusPill(
                    label: steps[i].$2 ? 'Hoàn tất' : 'Chưa xong',
                    color: steps[i].$2 ? WzColors.success : WzColors.warning,
                  ),
                ],
              ),
            ),
            if (i != steps.length - 1)
              const Divider(height: 1, color: WzColors.divider),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(BranchModel? b, bool done) {
    final enabled = b != null;
    final allDone =
        (b?.step1Done ?? false) &&
        (b?.step2Done ?? false) &&
        (b?.step3Done ?? false) &&
        (b?.step4Done ?? false);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        WzPrimaryButton(
          label: done ? 'Chi nhánh đã hoạt động' : 'Xác nhận & đăng bài',
          icon: done
              ? CupertinoIcons.checkmark_alt_circle_fill
              : CupertinoIcons.paperplane_fill,
          color: done ? WzColors.success : WzColors.brand,
          loading: _busy,
          enabled: enabled && !done,
          onPressed: enabled && !done ? () => _publish(b) : null,
        ),
        if (enabled && !allDone && !done) ...[
          const SizedBox(height: WzSpacing.sm),
          Text(
            'Cần hoàn tất Bước 1, 2, 3 và 4 trước khi đăng bài.',
            textAlign: TextAlign.center,
            style: WzText.caption.copyWith(color: WzColors.warning),
          ),
        ],
      ],
    );
  }

  /// Kiểm tra TẤT CẢ phòng & WC chung đã được cấu hình đầy đủ chưa.
  ///
  /// Dùng đúng tiêu chí của Bước 4: phòng đạt khi `status != KHOA_CHO_CAP_NHAT`
  /// (đã có giá/diện tích/ảnh...), WC đạt khi đã có `equipment` hoặc `images`.
  /// Trả về danh sách tên các mục còn thiếu để hiển thị lỗi cụ thể.
  Future<List<String>> _findIncompleteRooms(BranchModel b) async {
    final rooms = await ref.read(roomsProvider(b.id).future);
    final facilities = await ref.read(facilitiesProvider(b.id).future);

    final missing = <String>[];
    for (final r in rooms) {
      final ok = r['status'] != 'KHOA_CHO_CAP_NHAT';
      if (!ok) {
        final name = '${r['roomName'] ?? r['roomCode'] ?? r['id']}';
        missing.add(
          name.toLowerCase().startsWith('phòng') ? name : 'Phòng $name',
        );
      }
    }
    for (final f in facilities) {
      final ok = f['equipment'] != null || f['images'] != null;
      if (!ok) {
        missing.add('WC chung ${f['name'] ?? f['id']}');
      }
    }
    return missing;
  }

  Future<void> _publish(BranchModel b) async {
    final allDone = b.step1Done && b.step2Done && b.step3Done && b.step4Done;
    if (!allDone) {
      ToastUtils.show(
        context,
        'Vui lòng hoàn tất Bước 1, 2, 3 và 4 trước khi đăng bài.',
        isError: true,
      );
      return;
    }

    setState(() => _busy = true);
    try {
      // Chặn ở Bước 5: mọi phòng & WC chung phải được cấu hình đầy đủ
      // (giá, diện tích, ảnh, tiện nghi...) trước khi chi nhánh được khởi tạo.
      final missing = await _findIncompleteRooms(b);
      if (missing.isNotEmpty) {
        if (!mounted) return;
        final preview = missing.take(5).join(', ');
        final more = missing.length > 5 ? '… (+${missing.length - 5})' : '';
        ToastUtils.show(
          context,
          'Còn ${missing.length} mục chưa cấu hình đầy đủ: $preview$more. '
          'Vui lòng hoàn tất Bước 4 trước khi đăng bài.',
          isError: true,
        );
        return;
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.show(
          context,
          'Không kiểm tra được cấu hình phòng: $e',
          isError: true,
        );
      }
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }

    setState(() => _busy = true);
    try {
      final updated = await ref
          .read(branchProvider.notifier)
          .markStep(b.id, 5, true);
      if (!mounted) return;
      widget.onCompleted(updated ?? b);
      ToastUtils.show(context, 'Chi nhánh "${b.branchName}" đã hoạt động');
    } catch (e) {
      if (mounted) {
        ToastUtils.show(context, 'Không thể đăng bài: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
