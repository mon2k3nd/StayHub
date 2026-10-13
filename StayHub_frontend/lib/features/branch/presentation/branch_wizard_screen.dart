import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/components/glass_container.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/providers/dashboard_refresh.dart';
import '../application/branch_notifier.dart';
import '../data/models/branch_model.dart';
import 'create_branch_screen.dart';
import 'widgets/branch_wizard/branch_wizard_theme.dart';
import 'widgets/branch_wizard/step1_framework_screen.dart';
import 'widgets/branch_wizard/step2_shared_assets_screen.dart';
import 'widgets/branch_wizard/step3_spatial_structure_screen.dart';
import 'widgets/branch_wizard/step4_room_config_screen.dart';
import 'widgets/branch_wizard/step4_publish_screen.dart';
import 'dart:async' show unawaited;

/// Màn hình TỔNG QUAN "Tạo / Cấu hình chi nhánh".
///
/// Hiển thị TẤT CẢ 4 bước bắt buộc trên MỘT màn hình dưới dạng checklist.
/// Người dùng bấm vào một bước để mở MÀN HÌNH CHI TIẾT riêng của bước đó.
/// Các bước được KHOÁ TUẦN TỰ: chỉ mở được bước N khi bước N-1 đã hoàn tất.
///
/// Chi nhánh chỉ được coi là "đã tạo" (creationStatus = COMPLETED) khi
/// CẢ 4 bước đều hoàn tất. Nếu chưa đủ, chi nhánh nằm ở nhóm "Đang khởi tạo"
/// và KHÔNG được tính vào thống kê / không lên chợ trọ.
///
///   Bước 1 — Khung vận hành chi nhánh
///   Bước 2 — Tài sản chung của cả toà nhà (kế thừa Bước 1 + thêm mới + ảnh)
///   Bước 3 — Cấu trúc không gian (sơ đồ tầng/phòng) & khu vệ sinh chung
///   Bước 4 — Cấu hình phòng chi tiết
///   Bước 5 — Xác nhận & đăng bài
///
/// Toàn bộ giao diện dùng chung design system [WzColors] / [WzText] /
/// [WzStatusPill] / [WzProgressBar] / [WzPrimaryButton] để đồng nhất với
/// các màn hình chi tiết của từng bước.
class BranchWizardScreen extends ConsumerStatefulWidget {
  final BranchModel? branch;

  const BranchWizardScreen({super.key, this.branch});

  @override
  ConsumerState<BranchWizardScreen> createState() => _BranchWizardScreenState();
}

class _BranchWizardScreenState extends ConsumerState<BranchWizardScreen> {
  BranchModel? _branch;

  @override
  void initState() {
    super.initState();
    _branch = widget.branch;
    // Nạp lại chi nhánh từ server để lấy cờ `step1Done..step5Done` MỚI NHẤT.
    // Nếu chỉ dùng model truyền vào, các bước đã hoàn tất (vd Bước 5 — đăng
    // bài) vẫn hiển thị "Cần thực hiện"/đỏ cho tới khi mở lại màn unawaited(hình.)
    unawaited(_refreshFromServer());
  }

  Future<void> _refreshFromServer() async {
    final id = widget.branch?.id;
    if (id == null) return;
    final fresh = await ref.read(branchProvider.notifier).getById(id);
    if (!mounted || fresh == null) return;
    setState(() => _branch = fresh);
  }

  // ─────────────────────────── Step metadata ───────────────────────────

  static const _stepMeta = <_StepMeta>[
    _StepMeta(
      index: 0,
      number: 1,
      title: 'Khung vận hành chi nhánh',
      subtitle:
          'Ảnh, tên, mã (ID), địa chỉ ghim bản đồ, mô hình, '
          'quy chế chung & tiện ích, bộ đơn giá.',
      icon: CupertinoIcons.briefcase_fill,
    ),
    _StepMeta(
      index: 1,
      number: 2,
      title: 'Tài sản chung của toà nhà',
      subtitle:
          'Kế thừa tài sản chung từ Bước 1, thêm tài sản mới và '
          'upload ảnh thực tế. Tài sản dùng chung cho mọi phòng.',
      icon: CupertinoIcons.cube_box_fill,
    ),
    _StepMeta(
      index: 2,
      number: 3,
      title: 'Cấu trúc không gian & WC chung',
      subtitle:
          'Vẽ sơ đồ toà nhà: số tầng, số phòng mỗi tầng. Khai báo khu '
          'vệ sinh chung và gán phòng dùng chung khu WC nào.',
      icon: CupertinoIcons.rectangle_grid_1x2_fill,
    ),
    _StepMeta(
      index: 3,
      number: 4,
      title: 'Cấu hình phòng chi tiết',
      subtitle:
          'Giá thuê, tiền cọc, diện tích, số khách, chỉ số ban đầu, '
          'tài sản trong phòng và ghi đè dịch vụ.',
      icon: CupertinoIcons.square_grid_2x2,
    ),
    _StepMeta(
      index: 4,
      number: 5,
      title: 'Xác nhận & đăng bài',
      subtitle:
          'Kiểm tra toàn bộ cấu hình và chính thức đưa chi nhánh '
          'vào hoạt động, xuất hiện trên chợ trọ.',
      icon: CupertinoIcons.paperplane_fill,
    ),
  ];

  // ─────────────────────────── State helpers ───────────────────────────

  bool _isStepDone(int index) {
    final b = _branch;
    if (b == null) return false;
    return switch (index) {
      0 => b.step1Done,
      1 => b.step2Done,
      2 => b.step3Done,
      3 => b.step4Done,
      // Bước 5 (đăng bài) hoàn tất khi cờ step5Done được bật.
      _ => b.step5Done,
    };
  }

  /// Bước có được phép mở không: bước 1 luôn mở; bước N cần bước N-1 xong.
  bool _isStepUnlocked(int index) {
    if (index == 0) return true;
    return _isStepDone(index - 1);
  }

  /// Tổng số bước bắt buộc của wizard (1..5).
  static const int _totalSteps = 5;

  int get _doneCount {
    var n = 0;
    for (var i = 0; i < _totalSteps; i++) {
      if (_isStepDone(i)) n++;
    }
    return n;
  }

  bool get _allDone => _doneCount == _totalSteps;

  // ─────────────────────────── Build ───────────────────────────

  /// Chi nhánh đang TẠM NGỪNG: không cho cấu hình lại, chỉ có thể kích hoạt lại.
  bool get _isSuspended => _branch?.creationStatus == 'SUSPENDED';

  @override
  Widget build(BuildContext context) {
    if (_isSuspended) {
      return LiquidGlassScaffold(
        title: 'Chi nhánh đang tạm ngừng',
        useScrollView: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: WzSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.pause_circle_fill,
                  size: 56,
                  color: WzColors.textFaint,
                ),
                const SizedBox(height: WzSpacing.lg),
                Text(
                  _branch?.branchName ?? 'Chi nhánh',
                  textAlign: TextAlign.center,
                  style: WzText.screenTitle,
                ),
                const SizedBox(height: WzSpacing.xs),
                Text(
                  _branch?.displayCode ?? '',
                  textAlign: TextAlign.center,
                  style: WzText.caption,
                ),
                const SizedBox(height: WzSpacing.lg),
                const Text(
                  'Chi nhánh này đang tạm ngừng hoạt động nên không thể '
                  'cấu hình. Hãy kích hoạt lại từ màn hình Quản lý chi nhánh '
                  'nếu muốn tiếp tục sử dụng.',
                  textAlign: TextAlign.center,
                  style: WzText.body,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return LiquidGlassScaffold(
      title: _branch == null ? 'Tạo chi nhánh mới' : 'Cấu hình chi nhánh',
      useScrollView: false,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          WzSpacing.lg,
          WzSpacing.md,
          WzSpacing.lg,
          WzSpacing.xxl,
        ),
        children: [
          _buildProgressHeader(),
          const SizedBox(height: WzSpacing.lg),
          const Padding(
            padding: EdgeInsets.only(left: WzSpacing.xs),
            child: Text('CÁC BƯỚC BẮT BUỘC', style: WzText.label),
          ),
          const SizedBox(height: WzSpacing.sm),
          for (final meta in _stepMeta) ...[
            _buildStepCard(meta),
            const SizedBox(height: WzSpacing.md),
          ],
          const SizedBox(height: WzSpacing.xs),
          _buildPublishButton(),
          // Chỉ hiện khi chi nhánh đã được tạo nháp (có ID) và chưa hoàn tất.
          if (_branch != null && !_allDone) ...[
            const SizedBox(height: WzSpacing.md),
            _buildCancelDraftButton(),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────── Header ───────────────────────────

  Widget _buildProgressHeader() {
    return GlassContainer(
      padding: const EdgeInsets.all(WzSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _branch?.branchName ?? 'Chi nhánh chưa đặt tên',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: WzText.screenTitle,
                ),
              ),
              const SizedBox(width: WzSpacing.sm),
              WzStatusPill(
                label: _allDone ? 'Đã hoàn tất' : 'Đang cấu hình',
                color: _allDone ? WzColors.success : WzColors.warning,
              ),
            ],
          ),
          const SizedBox(height: WzSpacing.md),
          WzProgressBar(
            done: _doneCount,
            caption: 'Hoàn tất $_doneCount/$_totalSteps bước bắt buộc',
          ),
          if (!_allDone) ...[
            const SizedBox(height: WzSpacing.sm),
            const Text(
              'Chi nhánh chỉ được đăng bài và tính vào thống kê khi đủ 5 bước.',
              style: WzText.caption,
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────── Step card ───────────────────────────

  Widget _buildStepCard(_StepMeta meta) {
    final done = _isStepDone(meta.index);
    final unlocked = _isStepUnlocked(meta.index);
    final isNext = unlocked && !done;

    final Color accent = done
        ? WzColors.success
        : (unlocked ? WzColors.brand : WzColors.textFaint);

    return Opacity(
      opacity: unlocked ? 1 : 0.55,
      child: GestureDetector(
        onTap: unlocked ? () => _openStep(meta) : () => _toastLocked(meta),
        child: GlassContainer(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Số thứ tự / dấu tick / ổ khoá
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: done
                      ? WzColors.success
                      : (unlocked
                            ? WzColors.brand.withValues(alpha: 0.1)
                            : WzColors.surfaceMuted),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: done
                        ? WzColors.success
                        : (unlocked
                              ? WzColors.brand.withValues(alpha: 0.35)
                              : WzColors.border),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: done
                      ? const Icon(
                          CupertinoIcons.checkmark_alt,
                          size: 18,
                          color: Colors.white,
                        )
                      : unlocked
                      ? Text(
                          '${meta.number}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: WzColors.brand,
                          ),
                        )
                      : const Icon(
                          CupertinoIcons.lock_fill,
                          size: 15,
                          color: WzColors.textFaint,
                        ),
                ),
              ),
              const SizedBox(width: WzSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(meta.icon, size: 15, color: accent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(meta.title, style: WzText.rowTitle),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(meta.subtitle, style: WzText.caption),
                    const SizedBox(height: WzSpacing.sm),
                    Row(
                      children: [
                        WzStatusPill(
                          label: done
                              ? 'Hoàn tất'
                              : (unlocked ? 'Cần thực hiện' : 'Chưa mở khoá'),
                          color: done
                              ? WzColors.success
                              : (unlocked
                                    ? WzColors.warning
                                    : WzColors.textFaint),
                        ),
                        const Spacer(),
                        if (unlocked)
                          Row(
                            children: [
                              Text(
                                done ? 'Xem lại' : 'Thực hiện',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: WzColors.brand,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                CupertinoIcons.chevron_forward,
                                size: 13,
                                color: WzColors.brand,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isNext) ...[
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: WzColors.warning,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────── Publish button ───────────────────────────

  /// Nút cuối màn hình tổng quan.
  ///
  /// KHÔNG tự đăng bài (tránh trùng lặp với Bước 4) — chỉ mở Bước 4 để người
  /// dùng xác nhận lần cuối. Nhờ vậy chỉ có MỘT nơi duy nhất gọi publish.
  Widget _buildPublishButton() {
    final bool ready = _allDone;
    return WzPrimaryButton(
      label: ready
          ? 'Xem lại & đăng bài'
          : 'Còn ${_totalSteps - _doneCount} bước chưa xong',
      icon: ready ? CupertinoIcons.paperplane_fill : CupertinoIcons.lock_fill,
      color: ready ? WzColors.success : WzColors.brand,
      enabled: _branch != null,
      onPressed: _branch == null ? null : () => _openStep(_stepMeta[4]),
    );
  }

  /// Nút "Hủy khởi tạo": xóa cứng chi nhánh nháp + giải phóng mã.
  Widget _buildCancelDraftButton() {
    return WzPrimaryButton(
      label: 'Hủy khởi tạo',
      icon: CupertinoIcons.xmark_circle_fill,
      color: WzColors.error,
      enabled: true,
      onPressed: _confirmCancelDraft,
    );
  }

  Future<void> _confirmCancelDraft() async {
    final b = _branch;
    if (b == null) return;
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Hủy chi nhánh đang khởi tạo'),
        content: Text(
          'Chi nhánh "${b.branchName}" chưa hoàn tất cấu hình. '
          'Khi hủy, toàn bộ dữ liệu nháp sẽ bị xóa và mã '
          '"${b.displayCode}" được giải phóng hoàn toàn — '
          'bạn có thể tạo lại chi nhánh với cùng tên.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Giữ lại'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hủy chi nhánh'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(branchProvider.notifier).cancelDraftBranch(b.id);
      if (!mounted) return;
      ToastUtils.show(
        context,
        'Đã hủy "${b.branchName}". Mã đã được giải phóng!',
      );
      // Đóng wizard TRƯỚC khi invalidate để tránh rebuild trên context đã hủy.
      Navigator.of(context).pop();
      refreshOwnerDashboardFromWidget(ref);
    } catch (e) {
      if (mounted) ToastUtils.show(context, 'Lỗi: $e', isError: true);
    }
  }

  // ─────────────────────────── Navigation ───────────────────────────

  Future<void> _openStep(_StepMeta meta) async {
    final b = _branch;
    if (b == null && meta.index != 0) {
      _toast('Vui lòng hoàn tất Bước 1 trước.');
      return;
    }

    BranchModel? updated;
    switch (meta.index) {
      case 0:
        updated = await Navigator.of(context).push<BranchModel>(
          CupertinoPageRoute(builder: (_) => Step1FrameworkScreen(branch: b)),
        );
        break;
      case 1:
        updated = await Navigator.of(context).push<BranchModel>(
          CupertinoPageRoute(
            builder: (_) => Step2SharedAssetsScreen(branch: b!),
          ),
        );
        break;
      case 2:
        updated = await Navigator.of(context).push<BranchModel>(
          CupertinoPageRoute(
            builder: (_) => Step3SpatialStructureScreen(branch: b!),
          ),
        );
        break;
      case 3:
        updated = await Navigator.of(context).push<BranchModel>(
          CupertinoPageRoute(builder: (_) => Step4RoomConfigScreen(branch: b!)),
        );
        break;
      default:
        updated = await Navigator.of(context).push<BranchModel>(
          CupertinoPageRoute(builder: (_) => Step4PublishScreen(branch: b!)),
        );
    }

    if (!mounted) return;
    if (updated != null) {
      setState(() => _branch = updated);
      // Chỉ trả kết quả về màn quản lý khi đã hoàn tất CẢ 5 bước
      // (bao gồm Bước 5 — Xác nhận & đăng bài).
      if (_allDone) Navigator.of(context).pop(updated);
    }
  }

  void _toastLocked(_StepMeta meta) {
    _toast(
      'Bước ${meta.number} chưa mở khoá. '
      'Hãy hoàn tất Bước ${meta.number - 1} trước.',
    );
  }

  void _toast(String msg) => ToastUtils.show(context, msg, isError: true);
}

/// Metadata mô tả một bước trong wizard.
class _StepMeta {
  final int index;
  final int number;
  final String title;
  final String subtitle;
  final IconData icon;

  const _StepMeta({
    required this.index,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

/// Mở màn hình tạo chi nhánh cũ (dùng cho Bước 1) rồi quay lại wizard.
Future<BranchModel?> openLegacyCreateBranch(BuildContext context) {
  return Navigator.of(context).push<BranchModel>(
    CupertinoPageRoute(builder: (_) => const CreateBranchScreen()),
  );
}
