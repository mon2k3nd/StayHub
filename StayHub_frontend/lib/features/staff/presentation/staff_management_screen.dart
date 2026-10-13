import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart' show RefreshIndicator;
import 'package:intl/intl.dart';

import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/glass_button.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/components/liquid_glass_loader.dart';
import '../application/staff_notifier.dart';

export '../application/staff_notifier.dart'
    show StaffModel, staffListNotifierProvider;
import 'dart:async' show unawaited;

// ─── Screen ────────────────────────────────────────────────
class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  ConsumerState<StaffManagementScreen> createState() =>
      _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isCreating = false;

  String _searchQuery = '';
  int _selectedFilterIndex = 0;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _showCreateDialog() {
    _nameCtrl.clear();
    _phoneCtrl.clear();
    _passwordCtrl.clear();

    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => CupertinoAlertDialog(
            title: const Text('Thêm Nhân Viên Mới'),
            content: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                children: [
                  CupertinoTextField(
                    controller: _nameCtrl,
                    placeholder: 'Họ tên nhân viên',
                    placeholderStyle: const TextStyle(
                      color: CupertinoColors.placeholderText,
                    ),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _phoneCtrl,
                    placeholder: 'Số điện thoại (dùng để đăng nhập)',
                    keyboardType: TextInputType.phone,
                    placeholderStyle: const TextStyle(
                      color: CupertinoColors.placeholderText,
                    ),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _passwordCtrl,
                    placeholder: 'Mật khẩu tạm thời',
                    obscureText: true,
                    placeholderStyle: const TextStyle(
                      color: CupertinoColors.placeholderText,
                    ),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text(
                  'Hủy',
                  style: TextStyle(color: CupertinoColors.systemRed),
                ),
                onPressed: () => Navigator.pop(ctx),
              ),
              CupertinoDialogAction(
                isDefaultAction: true,
                child: _isCreating
                    ? const LiquidGlassLoader(size: 30, text: null)
                    : const Text('Tạo'),
                onPressed: () async {
                  final name = _nameCtrl.text.trim();
                  final phone = _phoneCtrl.text.trim();
                  final pass = _passwordCtrl.text.trim();
                  if (name.isEmpty || phone.isEmpty || pass.isEmpty) return;

                  setDialogState(() => _isCreating = true);
                  final ok = await ref
                      .read(staffListNotifierProvider.notifier)
                      .createStaff(name, phone, pass, []);
                  setDialogState(() => _isCreating = false);
                  if (ctx.mounted) Navigator.pop(ctx);

                  if (ok && mounted) {
                    _showAlert(
                      'Thành công',
                      'Đã tạo tài khoản nhân viên $name.\nĐăng nhập bằng SĐT: $phone',
                    );
                  } else if (mounted) {
                    _showAlert(
                      'Lỗi',
                      'Không thể tạo nhân viên. Kiểm tra SĐT đã tồn tại chưa.',
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(int staffId, String name) {
    final reasonCtrl = TextEditingController();
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Cho nghỉ việc?'),
          content: Column(
            children: [
              Text('Tài khoản "$name" sẽ bị vô hiệu hóa hoàn toàn.'),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: reasonCtrl,
                placeholder: 'Lý do nghỉ việc (Bắt buộc)',
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Hủy'),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Nghỉ việc'),
              onPressed: () async {
                final reason = reasonCtrl.text.trim();
                if (reason.isEmpty) {
                  ToastUtils.show(ctx, 'Vui lòng nhập lý do');
                  return;
                }
                Navigator.pop(ctx);
                final ok = await ref
                    .read(staffListNotifierProvider.notifier)
                    .resignStaff(staffId, reason);
                if (mounted && ok) {
                  _showAlert(
                    'Thành công',
                    'Đã chuyển nhân viên $name sang trạng thái Đã nghỉ việc.',
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmToggleStatus(int staffId, String name, String currentStatus) {
    final isLocked = currentStatus == 'LOCKED';
    final actionName = isLocked ? 'Mở khóa' : 'Tạm khóa';
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text('$actionName Nhân Viên?'),
          content: Text(
            !isLocked
                ? 'Tài khoản "$name" sẽ không thể đăng nhập được nữa.'
                : 'Tài khoản "$name" sẽ được phép đăng nhập trở lại.',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Hủy'),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              isDestructiveAction: !isLocked,
              child: Text(actionName),
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await ref
                    .read(staffListNotifierProvider.notifier)
                    .toggleStaffStatus(staffId, currentStatus);
                if (mounted && ok) {
                  ToastUtils.show(context, 'Đã $actionName nhân viên $name');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAlert(String title, String message) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettleDialog(int staffId, String name, double cashSpent) {
    final amountCtrl = TextEditingController(
      text: cashSpent.toStringAsFixed(0),
    );
    final fmt = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );

    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Thanh Toán Tiền Ứng'),
          content: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              children: [
                Text(
                  'Nhân viên "$name" đã ứng trước:\n${fmt.format(cashSpent)}',
                ),
                const SizedBox(height: 12),
                CupertinoTextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  placeholder: 'Số tiền thanh toán',
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Hủy'),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Thanh toán'),
              onPressed: () async {
                final amountStr = amountCtrl.text.replaceAll(
                  RegExp(r'[^0-9]'),
                  '',
                );
                if (amountStr.isEmpty) return;
                final amount = double.parse(amountStr);
                Navigator.pop(ctx);

                final ok = await ref
                    .read(staffListNotifierProvider.notifier)
                    .settleWallet(staffId, amount);
                if (mounted) {
                  if (ok) {
                    _showAlert(
                      'Thành công',
                      'Đã thanh toán ${fmt.format(amount)} cho nhân viên.',
                    );
                  } else {
                    _showAlert(
                      'Lỗi',
                      'Không thể thanh toán. Vui lòng thử lại.',
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffListNotifierProvider);

    return LiquidGlassScaffold(
      title: 'Quản Lý Nhân Viên',
      backgroundColors: AppTheme.kBackgroundLight,
      useScrollView: false,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => context.push('/owner-shifts'),
            child: const Icon(
              CupertinoIcons.calendar_badge_plus,
              color: LiquidGlassColors.ownerAccent,
              size: 26,
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _showCreateDialog,
            child: const Icon(
              CupertinoIcons.person_add_solid,
              color: LiquidGlassColors.ownerAccent,
              size: 26,
            ),
          ),
        ],
      ),
      child: staffAsync.when(
        data: (rawStaffList) {
          final filteredList = rawStaffList.where((s) {
            final matchesSearch =
                s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                s.phoneNumber.contains(_searchQuery);
            if (!matchesSearch) return false;
            if (_selectedFilterIndex == 1 && s.status != 'ACTIVE') return false;
            if (_selectedFilterIndex == 2 && s.status != 'LOCKED') return false;
            if (_selectedFilterIndex == 3 && s.status != 'RESIGNED') {
              return false;
            }
            return true;
          }).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(staffListNotifierProvider),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      children: [
                        CupertinoSearchTextField(
                          placeholder: 'Tìm tên hoặc SĐT...',
                          onChanged: (val) {
                            setState(() => _searchQuery = val);
                          },
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: CupertinoSlidingSegmentedControl<int>(
                            groupValue: _selectedFilterIndex,
                            children: const {
                              0: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  'Tất cả',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              1: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  'Hoạt động',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              2: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  'Đình chỉ',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              3: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  'Nghỉ việc',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            },
                            onValueChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedFilterIndex = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (filteredList.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.person_3,
                            size: 64,
                            color: CupertinoColors.systemGrey.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Không tìm thấy nhân viên',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Thử đổi từ khóa hoặc bộ lọc khác.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                          if (rawStaffList.isEmpty) ...[
                            const SizedBox(height: 24),
                            GlassButton(
                              text: 'Thêm Nhân Viên',
                              icon: CupertinoIcons.person_add,
                              color: LiquidGlassColors.ownerAccent,
                              onPressed: _showCreateDialog,
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((ctx, i) {
                        final s = filteredList[i];
                        final isResigned = s.status == 'RESIGNED';
                        final isLocked = s.status == 'LOCKED';
                        final isActive = s.status == 'ACTIVE';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Opacity(
                            opacity: isResigned ? 0.6 : 1.0,
                            child: GlassContainer(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? LiquidGlassColors.ownerAccent
                                                .withValues(alpha: 0.15)
                                          : CupertinoColors.systemGrey
                                                .withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        s.name.isNotEmpty
                                            ? s.name[0].toUpperCase()
                                            : 'N',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                          color: isActive
                                              ? LiquidGlassColors.ownerAccent
                                              : CupertinoColors.systemGrey,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: isActive
                                                ? CupertinoColors.black
                                                : CupertinoColors.systemGrey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              CupertinoIcons.phone,
                                              size: 13,
                                              color: isActive
                                                  ? const Color(0xFF4B5563)
                                                  : CupertinoColors.systemGrey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              s.phoneNumber,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: isActive
                                                    ? const Color(0xFF4B5563)
                                                    : CupertinoColors
                                                          .systemGrey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            _badge(
                                              'Nhân viên',
                                              CupertinoColors.systemGreen,
                                            ),
                                            if (isLocked)
                                              _badge(
                                                'Đang khóa',
                                                CupertinoColors.systemOrange,
                                              ),
                                            if (isResigned)
                                              _badge(
                                                'Đã nghỉ việc',
                                                CupertinoColors.systemRed,
                                              ),
                                            if (s.cashSpent > 0 && !isResigned)
                                              _badgeText(
                                                'Đang giữ: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(s.cashSpent)}',
                                                CupertinoColors.systemOrange,
                                              ),
                                            if (s.assignments.isNotEmpty)
                                              _badgeText(
                                                'Q.Lý ${s.assignments.length} cơ sở',
                                                CupertinoColors.systemPurple,
                                              ),
                                          ],
                                        ),
                                        if (isActive &&
                                            s.assignments.isEmpty) ...[
                                          const SizedBox(height: 4),
                                          const Text(
                                            '⚠️ Chưa được phân công cơ sở nào',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color:
                                                  CupertinoColors.systemOrange,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                        if (isResigned &&
                                            s.resignReason != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Lý do: ${s.resignReason}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: CupertinoColors.systemRed,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (!isResigned) ...[
                                    if (s.cashSpent > 0)
                                      CupertinoButton(
                                        padding: EdgeInsets.zero,
                                        child: const Icon(
                                          CupertinoIcons
                                              .money_dollar_circle_fill,
                                          color: CupertinoColors.systemOrange,
                                          size: 26,
                                        ),
                                        onPressed: () => _showSettleDialog(
                                          s.id,
                                          s.name,
                                          s.cashSpent,
                                        ),
                                      ),
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      child: Icon(
                                        isActive
                                            ? CupertinoIcons.lock_open_fill
                                            : CupertinoIcons.lock_fill,
                                        color: isActive
                                            ? CupertinoColors.systemGrey
                                            : CupertinoColors.systemOrange,
                                        size: 24,
                                      ),
                                      onPressed: () => _confirmToggleStatus(
                                        s.id,
                                        s.name,
                                        s.status,
                                      ),
                                    ),
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      child: const Icon(
                                        CupertinoIcons.shield_lefthalf_fill,
                                        color: CupertinoColors.systemPurple,
                                        size: 24,
                                      ),
                                      onPressed: () => context.push(
                                        '/staff-permissions',
                                        extra: {'staff': s},
                                      ),
                                    ),
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      child: const Icon(
                                        CupertinoIcons.person_badge_minus_fill,
                                        color: CupertinoColors.systemRed,
                                        size: 26,
                                      ),
                                      onPressed: () =>
                                          _confirmDelete(s.id, s.name),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }, childCount: filteredList.length),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const LiquidGlassLoader(text: 'Đang tải danh sách...'),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_circle_fill,
                  color: CupertinoColors.systemRed,
                  size: 48,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Không thể tải danh sách nhân viên.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '$err',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                CupertinoButton(
                  color: LiquidGlassColors.ownerAccent,
                  borderRadius: BorderRadius.circular(12),
                  onPressed: () => ref.invalidate(staffListNotifierProvider),
                  child: const Text(
                    'Thử lại',
                    style: TextStyle(color: CupertinoColors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
    ),
  );

  Widget _badgeText(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
    ),
  );
}
