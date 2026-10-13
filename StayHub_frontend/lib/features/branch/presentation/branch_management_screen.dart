import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/components/glass_container.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/providers/dashboard_refresh.dart';
import '../application/branch_notifier.dart';
import '../data/models/branch_model.dart';
import 'widgets/branch_wizard/branch_wizard_theme.dart';
import 'dart:async' show unawaited;

/// Màn hình "Quản lý chi nhánh" — thay thế hoàn toàn "Tạo khu trọ" cũ.
///
/// Chủ nhà xem/quản lý TẤT CẢ chi nhánh, nhóm theo 3 trạng thái:
///   • Đang hoạt động  (creationStatus == COMPLETED)
///   • Đang khởi tạo   (creationStatus == DRAFT — chưa đủ 4 bước)
///   • Ngừng hoạt động (creationStatus == SUSPENDED)
///
/// FAB "+" (góc phải dưới) mở wizard 4 bước dạng checklist bắt buộc.
///
/// Toàn bộ giao diện dùng chung design system [WzColors] / [WzText] /
/// [WzStatusPill] / [WzMetaChip] / [WzProgressBar] để đồng nhất với wizard.
class BranchManagementScreen extends ConsumerStatefulWidget {
  const BranchManagementScreen({super.key});

  @override
  ConsumerState<BranchManagementScreen> createState() =>
      _BranchManagementScreenState();
}

class _BranchManagementScreenState
    extends ConsumerState<BranchManagementScreen> {
  String _selectedGroup = 'ACTIVE';

  @override
  Widget build(BuildContext context) {
    final asyncBranches = ref.watch(managedBranchesProvider);

    return LiquidGlassScaffold(
      title: 'Quản lý chi nhánh',
      useScrollView: false,
      onRefresh: () async {
        ref.invalidate(managedBranchesProvider);
        await ref.read(managedBranchesProvider.future);
      },
      child: Stack(
        children: [
          asyncBranches.when(
            loading: () =>
                const Center(child: CupertinoActivityIndicator(radius: 14)),
            error: (e, _) => _buildError(e),
            data: (branches) => _buildBody(branches),
          ),
          Positioned(right: WzSpacing.xl, bottom: 28, child: _buildFab()),
        ],
      ),
    );
  }

  // ─────────────────────────── Body ───────────────────────────

  Widget _buildBody(List<BranchModel> all) {
    final active = all
        .where((b) => b.creationStatus == 'COMPLETED' && !b.isDeleted)
        .toList();
    final initializing = all
        .where((b) => b.creationStatus == 'DRAFT' && !b.isDeleted)
        .toList();
    final suspended = all
        .where((b) => b.creationStatus == 'SUSPENDED' && !b.isDeleted)
        .toList();

    final groups = <String, List<BranchModel>>{
      'ACTIVE': active,
      'INIT': initializing,
      'SUSPENDED': suspended,
    };

    final current = groups[_selectedGroup] ?? const <BranchModel>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSummaryHeader(
          active.length,
          initializing.length,
          suspended.length,
        ),
        const SizedBox(height: WzSpacing.md),
        _buildGroupTabs(active.length, initializing.length, suspended.length),
        const SizedBox(height: WzSpacing.sm),
        Expanded(
          child: current.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    WzSpacing.lg,
                    WzSpacing.sm,
                    WzSpacing.lg,
                    120,
                  ),
                  itemCount: current.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: WzSpacing.md),
                  itemBuilder: (context, i) => _buildBranchCard(current[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildSummaryHeader(int active, int init, int suspended) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WzSpacing.lg,
        WzSpacing.lg,
        WzSpacing.lg,
        0,
      ),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(
          horizontal: WzSpacing.lg,
          vertical: WzSpacing.lg,
        ),
        child: Row(
          children: [
            _buildSummaryItem(
              icon: CupertinoIcons.checkmark_seal_fill,
              color: WzColors.success,
              value: '$active',
              label: 'Hoạt động',
            ),
            _buildSummaryDivider(),
            _buildSummaryItem(
              icon: CupertinoIcons.time_solid,
              color: WzColors.warning,
              value: '$init',
              label: 'Khởi tạo',
            ),
            _buildSummaryDivider(),
            _buildSummaryItem(
              icon: CupertinoIcons.pause_circle_fill,
              color: WzColors.textFaint,
              value: '$suspended',
              label: 'Tạm ngừng',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: WzText.statValue.copyWith(fontSize: 20)),
          const SizedBox(height: 2),
          Text(label, style: WzText.statLabel),
        ],
      ),
    );
  }

  Widget _buildSummaryDivider() =>
      Container(width: 1, height: 44, color: WzColors.border);

  Widget _buildGroupTabs(int active, int init, int suspended) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: WzSpacing.screenH,
      child: Row(
        children: [
          _buildGroupChip('ACTIVE', 'Đang hoạt động', active),
          const SizedBox(width: WzSpacing.sm),
          _buildGroupChip('INIT', 'Đang khởi tạo', init),
          const SizedBox(width: WzSpacing.sm),
          _buildGroupChip('SUSPENDED', 'Ngừng hoạt động', suspended),
        ],
      ),
    );
  }

  Widget _buildGroupChip(String key, String label, int count) {
    final selected = _selectedGroup == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedGroup = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: WzSpacing.lg,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: selected ? WzColors.brand : WzColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? WzColors.brand : WzColors.border,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: WzColors.brand.withValues(alpha: 0.28),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : WzColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.25)
                    : WzColors.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : WzColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── Branch card ───────────────────────────

  Widget _buildBranchCard(BranchModel b) {
    final isCompleted = b.creationStatus == 'COMPLETED';
    final isSuspended = b.creationStatus == 'SUSPENDED';
    final doneSteps = _countDoneSteps(b);

    return GestureDetector(
      // Chi nhánh tạm ngừng KHÔNG mở lại wizard cấu hình (dữ liệu đã chốt,
      // chỉ có thể kích hoạt lại). Mở sheet trạng thái tạm ngừng thay vì
      // đưa người dùng vào luồng cấu hình.
      onTap: () => isSuspended ? _showSuspendedSheet(b) : _openWizard(b),
      child: GlassContainer(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCover(b),
                const SizedBox(width: WzSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              b.branchName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: WzText.cardTitle.copyWith(fontSize: 16),
                            ),
                          ),
                          _buildStatusBadge(b),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        b.displayCode.isNotEmpty ? b.displayCode : 'Chưa có mã',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: WzColors.brand,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            CupertinoIcons.location_solid,
                            size: 12,
                            color: WzColors.textFaint,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              b.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: WzColors.textMuted,
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
            const SizedBox(height: WzSpacing.md),
            if (!isCompleted) ...[
              WzProgressBar(
                done: doneSteps,
                height: 6,
                caption: 'Hoàn tất $doneSteps/4 bước cấu hình',
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                WzMetaChip(
                  icon: CupertinoIcons.building_2_fill,
                  label: '${b.totalRooms} phòng',
                ),
                const SizedBox(width: WzSpacing.sm),
                if (isCompleted)
                  const WzMetaChip(
                    icon: CupertinoIcons.checkmark_alt_circle_fill,
                    label: 'Đã đăng bài',
                  )
                else if (isSuspended)
                  const WzMetaChip(
                    icon: CupertinoIcons.pause_circle_fill,
                    label: 'Tạm ngừng',
                  )
                else
                  WzMetaChip(
                    icon: CupertinoIcons.time_solid,
                    label: 'Bước $doneSteps/4',
                  ),
                const Spacer(),
                _buildCardAction(b),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(BranchModel b) {
    final url = ImageUrlHelper.buildUrl(b.coverImage);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 64,
        height: 64,
        color: WzColors.surfaceMuted,
        child: url == null
            ? const Icon(
                CupertinoIcons.building_2_fill,
                color: WzColors.textFaint,
                size: 26,
              )
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    const Center(child: CupertinoActivityIndicator(radius: 8)),
                errorWidget: (_, __, ___) => const Icon(
                  CupertinoIcons.building_2_fill,
                  color: WzColors.textFaint,
                  size: 26,
                ),
              ),
      ),
    );
  }

  Widget _buildStatusBadge(BranchModel b) {
    final (Color color, String label) = switch (b.creationStatus) {
      'COMPLETED' => (WzColors.success, 'Hoạt động'),
      'SUSPENDED' => (WzColors.textFaint, 'Tạm ngừng'),
      _ => (WzColors.warning, 'Khởi tạo'),
    };
    return WzStatusPill(label: label, color: color);
  }

  Widget _buildCardAction(BranchModel b) {
    final isCompleted = b.creationStatus == 'COMPLETED';
    final isSuspended = b.creationStatus == 'SUSPENDED';

    return GestureDetector(
      onTap: () => _showCardMenu(b),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: WzColors.surfaceMuted,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isCompleted
              ? CupertinoIcons.ellipsis
              : (isSuspended
                    ? CupertinoIcons.play_fill
                    : CupertinoIcons.arrow_right),
          size: 15,
          color: WzColors.textSecondary,
        ),
      ),
    );
  }

  // ─────────────────────────── Empty / Error ───────────────────────────

  Widget _buildEmptyState() {
    final (icon, title, subtitle) = switch (_selectedGroup) {
      'INIT' => (
        CupertinoIcons.time_solid,
        'Không có chi nhánh đang khởi tạo',
        'Nhấn nút + để bắt đầu tạo chi nhánh mới.',
      ),
      'SUSPENDED' => (
        CupertinoIcons.pause_circle,
        'Không có chi nhánh tạm ngừng',
        'Các chi nhánh bạn tạm ngừng sẽ hiển thị ở đây.',
      ),
      _ => (
        CupertinoIcons.building_2_fill,
        'Chưa có chi nhánh nào hoạt động',
        'Hoàn tất đủ 4 bước cấu hình để chi nhánh hoạt động.',
      ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: WzColors.brand.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: WzColors.brand),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: WzText.cardTitle.copyWith(fontSize: 16),
            ),
            const SizedBox(height: WzSpacing.sm),
            Text(subtitle, textAlign: TextAlign.center, style: WzText.body),
          ],
        ),
      ),
    );
  }

  Widget _buildError(Object e) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              size: 40,
              color: WzColors.warning,
            ),
            const SizedBox(height: 14),
            const Text(
              'Không tải được danh sách chi nhánh',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: WzColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$e',
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: WzText.caption,
            ),
            const SizedBox(height: WzSpacing.lg),
            CupertinoButton(
              color: WzColors.brand,
              borderRadius: BorderRadius.circular(12),
              onPressed: () => ref.invalidate(managedBranchesProvider),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── FAB ───────────────────────────

  Widget _buildFab() {
    return GestureDetector(
      onTap: _startNewBranch,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: WzColors.fabGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: WzColors.brand.withValues(alpha: 0.38),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(CupertinoIcons.add, color: Colors.white, size: 28),
      ),
    );
  }

  // ─────────────────────────── Actions ───────────────────────────

  Future<void> _startNewBranch() async {
    final created = await context.push<BranchModel>('/branch/wizard');
    if (created != null) {
      refreshOwnerDashboardFromWidget(ref);
    }
  }

  /// Sheet trạng thái cho chi nhánh ĐANG TẠM NGỪNG.
  ///
  /// Chi nhánh tạm ngừng đã chốt cấu hình nên KHÔNG mở lại wizard; người dùng
  /// chỉ có thể xem thông tin tóm tắt và kích hoạt lại (hoặc đóng).
  void _showSuspendedSheet(BranchModel b) {
    unawaited(
      showCupertinoModalPopup<void>(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: Text(b.branchName),
          message: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(b.displayCode),
              const SizedBox(height: 6),
              const Text(
                'Chi nhánh đang tạm ngừng hoạt động.\n'
                'Dữ liệu phòng được giữ nguyên và không hiển thị trên chợ trọ.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                unawaited(_resume(b));
              },
              child: const Text('Kích hoạt lại'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ),
      ),
    );
  }

  Future<void> _openWizard(BranchModel b) async {
    final result = await context.push<BranchModel>(
      '/branch/wizard',
      extra: {'branch': b},
    );
    if (result != null) {
      refreshOwnerDashboardFromWidget(ref);
    }
  }

  void _showCardMenu(BranchModel b) {
    final isCompleted = b.creationStatus == 'COMPLETED';
    final isSuspended = b.creationStatus == 'SUSPENDED';
    final isDraft = !isCompleted && !isSuspended;

    unawaited(
      showCupertinoModalPopup<void>(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: Text(b.branchName),
          message: Text(b.displayCode),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                unawaited(_openWizard(b));
              },
              child: Text(isCompleted ? 'Xem cấu hình' : 'Tiếp tục cấu hình'),
            ),
            if (isCompleted)
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(ctx);
                  unawaited(_confirmSuspend(b));
                },
                child: const Text('Ngừng hoạt động'),
              ),
            if (isDraft)
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: () {
                  Navigator.pop(ctx);
                  unawaited(_confirmCancelDraft(b));
                },
                child: const Text('Hủy chi nhánh'),
              ),
            if (isSuspended)
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(ctx);
                  unawaited(_resume(b));
                },
                child: const Text('Kích hoạt lại'),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ),
      ),
    );
  }

  /// DRAFT → "Hủy": xóa hẳn chi nhánh, mã được giải phóng hoàn toàn
  /// (coi như chưa từng xuất hiện) để có thể tạo lại cùng tên.
  Future<void> _confirmCancelDraft(BranchModel b) async {
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
      if (mounted) {
        ToastUtils.show(
          context,
          'Đã hủy "${b.branchName}". Mã đã được giải phóng!',
        );
      }
    } catch (e) {
      if (mounted) ToastUtils.show(context, 'Lỗi: $e', isError: true);
    }
  }

  Future<void> _confirmSuspend(BranchModel b) async {
    final ok = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Tạm ngừng chi nhánh'),
        content: Text(
          'Chi nhánh "${b.branchName}" sẽ bị ẩn khỏi chợ trọ và không tính vào thống kê. '
          'Dữ liệu phòng vẫn được giữ nguyên.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tạm ngừng'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(branchProvider.notifier).suspendBranch(b.id);
      if (mounted) {
        ToastUtils.show(context, 'Đã tạm ngừng "${b.branchName}"');
      }
    } catch (e) {
      if (mounted) ToastUtils.show(context, 'Lỗi: $e', isError: true);
    }
  }

  Future<void> _resume(BranchModel b) async {
    try {
      await ref.read(branchProvider.notifier).resumeBranch(b.id);
      if (mounted) {
        ToastUtils.show(context, 'Đã kích hoạt lại "${b.branchName}"');
      }
    } catch (e) {
      if (mounted) ToastUtils.show(context, 'Lỗi: $e', isError: true);
    }
  }

  int _countDoneSteps(BranchModel b) {
    var n = 0;
    if (b.step1Done) n++;
    if (b.step2Done) n++;
    if (b.step3Done) n++;
    if (b.step4Done) n++;
    if (b.step5Done) n++;
    return n;
  }
}
