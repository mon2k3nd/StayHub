import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircleAvatar;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/app_error_widget.dart';
import '../application/admin_owner_notifier.dart';
import 'dart:async' show unawaited;

// ─── Filter State ─────────────────────────────────────────────────────────────
enum _OwnerFilter { all, pending, approved, rejected }

class AdminOwnerManagementScreen extends ConsumerStatefulWidget {
  const AdminOwnerManagementScreen({super.key});

  @override
  ConsumerState<AdminOwnerManagementScreen> createState() =>
      _AdminOwnerManagementScreenState();
}

class _AdminOwnerManagementScreenState
    extends ConsumerState<AdminOwnerManagementScreen> {
  final _searchCtrl = TextEditingController();
  _OwnerFilter _filter = _OwnerFilter.all;
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<dynamic> _applyFilter(List<dynamic> owners) {
    return owners.where((o) {
      // Apply status filter
      if (_filter == _OwnerFilter.pending &&
          o['ownerStatus'] != 'PENDING_VERIFICATION') {
        return false;
      }
      if (_filter == _OwnerFilter.approved && o['ownerStatus'] != 'APPROVED') {
        return false;
      }
      if (_filter == _OwnerFilter.rejected && o['ownerStatus'] != 'REJECTED') {
        return false;
      }

      // Apply text search
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      final name = (o['name'] ?? '').toString().toLowerCase();
      final email = (o['email'] ?? '').toString().toLowerCase();
      final phone = (o['phone'] ?? '').toString().toLowerCase();
      return name.contains(q) || email.contains(q) || phone.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ownersAsync = ref.watch(adminOwnersProvider);

    return LiquidGlassScaffold(
      title: 'Quản lý Chủ nhà',
      backgroundColors: AppTheme.kBackgroundLight,
      useScrollView: false,
      child: Column(
        children: [
          // ─── Search Bar ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: CupertinoSearchTextField(
              controller: _searchCtrl,
              placeholder: 'Tìm theo tên, email, SĐT...',
              onChanged: (val) => setState(() => _query = val),
              onSuffixTap: () {
                _searchCtrl.clear();
                setState(() => _query = '');
              },
            ),
          ),

          // ─── Filter Chips ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                    label: 'Tất cả',
                    active: _filter == _OwnerFilter.all,
                    color: AppTheme.kAccentColor,
                    onTap: () => setState(() => _filter = _OwnerFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Chờ duyệt',
                    active: _filter == _OwnerFilter.pending,
                    color: CupertinoColors.systemOrange,
                    onTap: () => setState(() => _filter = _OwnerFilter.pending),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Đã duyệt',
                    active: _filter == _OwnerFilter.approved,
                    color: CupertinoColors.systemGreen,
                    onTap: () =>
                        setState(() => _filter = _OwnerFilter.approved),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Từ chối',
                    active: _filter == _OwnerFilter.rejected,
                    color: CupertinoColors.systemRed,
                    onTap: () =>
                        setState(() => _filter = _OwnerFilter.rejected),
                  ),
                ],
              ),
            ),
          ),

          // ─── Owner List ─────────────────────────────────────────────────
          Expanded(
            child: ownersAsync.when(
              data: (allOwners) {
                final owners = _applyFilter(allOwners);
                if (owners.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          CupertinoIcons.building_2_fill,
                          size: 56,
                          color: Color(0xFFD1D5DB),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _query.isNotEmpty
                              ? 'Không tìm thấy kết quả cho "$_query"'
                              : 'Không có chủ nhà nào.',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    CupertinoSliverRefreshControl(
                      onRefresh: () async {
                        ref.invalidate(adminOwnersProvider);
                        await ref
                            .read(adminOwnersProvider.future)
                            .catchError((_) => <dynamic>[]);
                      },
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _OwnerCard(
                            owner: owners[index],
                            onVerify: (approved, {reason}) async {
                              unawaited(HapticFeedback.lightImpact());
                              // BUGFIX (data): coerce id an toàn — tránh
                              // `as int` ném TypeError khi id là String/null.
                              final rawId = owners[index]['id'];
                              final ownerId = rawId is num
                                  ? rawId.toInt()
                                  : int.tryParse(rawId?.toString() ?? '') ?? 0;
                              final ok = await ref
                                  .read(adminOwnerActionProvider.notifier)
                                  .verifyOwner(
                                    ownerId,
                                    approved,
                                    reason: reason,
                                  );
                              if (ok && mounted) {
                                _showResult(
                                  approved
                                      ? 'Đã duyệt thành công!'
                                      : 'Đã từ chối.',
                                );
                              }
                            },
                            onBan: (isBanned) async {
                              unawaited(HapticFeedback.heavyImpact());
                              // BUGFIX (data): coerce id an toàn.
                              final rawId = owners[index]['id'];
                              final ownerId = rawId is num
                                  ? rawId.toInt()
                                  : int.tryParse(rawId?.toString() ?? '') ?? 0;
                              final ok = await ref
                                  .read(adminOwnerActionProvider.notifier)
                                  .banOwner(ownerId, isBanned: isBanned);
                              if (ok && mounted) {
                                _showResult(
                                  isBanned
                                      ? 'Đã đình chỉ tài khoản.'
                                      : 'Đã gỡ đình chỉ.',
                                );
                              }
                            },
                            onEdit: (name, phone) async {
                              // BUGFIX (data): coerce id an toàn.
                              final rawId = owners[index]['id'];
                              final ownerId = rawId is num
                                  ? rawId.toInt()
                                  : int.tryParse(rawId?.toString() ?? '') ?? 0;
                              final ok = await ref
                                  .read(adminOwnerActionProvider.notifier)
                                  .overrideOwner(
                                    ownerId,
                                    name: name,
                                    phone: phone,
                                  );
                              if (ok && mounted) {
                                _showResult('Đã cập nhật thông tin.');
                              }
                            },
                            onAnalytics: () => context.push(
                              '/admin-owner-analytics/${owners[index]['id']}',
                            ),
                          ),
                          childCount: owners.length,
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: AppErrorWidget(
                  error: err,
                  onRetry: () => ref.invalidate(adminOwnersProvider),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResult(String msg) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Thông báo'),
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
}

// ─── Filter Chip ──────────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        unawaited(HapticFeedback.selectionClick());
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? color : color.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? CupertinoColors.white : color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─── Owner Card ───────────────────────────────────────────────────────────────
class _OwnerCard extends StatefulWidget {
  final dynamic owner;
  final Future<void> Function(bool approved, {String? reason}) onVerify;
  final Future<void> Function(bool isBanned) onBan;
  final Future<void> Function(String name, String phone) onEdit;
  final VoidCallback onAnalytics;

  const _OwnerCard({
    required this.owner,
    required this.onVerify,
    required this.onBan,
    required this.onEdit,
    required this.onAnalytics,
  });

  @override
  State<_OwnerCard> createState() => _OwnerCardState();
}

class _OwnerCardState extends State<_OwnerCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final owner = widget.owner;
    final status = owner['ownerStatus'] ?? 'PENDING_VERIFICATION';

    Color statusColor = CupertinoColors.systemGrey;
    String statusText = 'Chờ duyệt';
    if (status == 'APPROVED') {
      statusColor = CupertinoColors.systemGreen;
      statusText = 'Đã duyệt';
    } else if (status == 'REJECTED') {
      statusColor = CupertinoColors.systemRed;
      statusText = 'Từ chối';
    } else if (status == 'BANNED') {
      statusColor = CupertinoColors.systemOrange;
      statusText = 'Đình chỉ';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header row ─────────────────────────────────────────────
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    backgroundColor: AppTheme.kAccentColor.withValues(
                      alpha: 0.1,
                    ),
                    radius: 22,
                    child: Text(
                      // BUGFIX (UI): tránh RangeError khi tên rỗng/whitespace —
                      // `''[0]` ném RangeError. Lấy ký tự đầu sau khi trim, fallback '?'.
                      () {
                        final n = (owner['name'] ?? '').toString().trim();
                        return n.isEmpty ? '?' : n[0].toUpperCase();
                      }(),
                      style: const TextStyle(
                        color: AppTheme.kAccentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          owner['name'] ?? 'Không tên',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.kTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          owner['email'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.kTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    size: 14,
                    color: AppTheme.kTextMuted,
                  ),
                ],
              ),
            ),

            // ─── Expanded Details ───────────────────────────────────────
            if (_expanded) ...[
              const SizedBox(height: 14),
              Container(height: 0.5, color: const Color(0xFFE5E7EB)),
              const SizedBox(height: 14),

              // Contact info
              _InfoRow(CupertinoIcons.phone, owner['phone'] ?? 'Không có SĐT'),
              const SizedBox(height: 6),
              _InfoRow(
                CupertinoIcons.location_solid,
                owner['address'] ?? 'Chưa cập nhật địa chỉ',
              ),

              const SizedBox(height: 16),

              // Action Buttons based on status
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (status == 'PENDING_VERIFICATION') ...[
                    _ActionBtn(
                      label: '✓ Duyệt',
                      color: CupertinoColors.systemGreen,
                      onTap: () => widget.onVerify(true),
                    ),
                    _ActionBtn(
                      label: '✕ Từ chối',
                      color: CupertinoColors.systemRed,
                      onTap: () => _showRejectDialog(context),
                    ),
                  ],
                  if (status == 'APPROVED') ...[
                    _ActionBtn(
                      label: '📊 Phân tích',
                      color: AppTheme.kAccentColor,
                      onTap: widget.onAnalytics,
                    ),
                    _ActionBtn(
                      label: '✏️ Sửa TT',
                      color: CupertinoColors.activeBlue,
                      onTap: () => _showEditDialog(context),
                    ),
                    _ActionBtn(
                      label: '⛔ Đình chỉ',
                      color: CupertinoColors.systemOrange,
                      onTap: () => widget.onBan(true),
                    ),
                  ],
                  if (status == 'BANNED') ...[
                    _ActionBtn(
                      label: '✓ Gỡ đình chỉ',
                      color: CupertinoColors.systemGreen,
                      onTap: () => widget.onBan(false),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final reasonCtrl = TextEditingController(text: 'Hồ sơ chưa đạt yêu cầu');
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Lý do từ chối'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: CupertinoTextField(
              controller: reasonCtrl,
              placeholder: 'Nhập lý do từ chối...',
              maxLines: 3,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Hủy'),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Từ chối'),
              onPressed: () {
                Navigator.pop(ctx);
                unawaited(widget.onVerify(false, reason: reasonCtrl.text));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final nameCtrl = TextEditingController(text: widget.owner['name']);
    final phoneCtrl = TextEditingController(text: widget.owner['phone']);
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Sửa thông tin Chủ nhà'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoTextField(controller: nameCtrl, placeholder: 'Họ tên'),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: phoneCtrl,
                  placeholder: 'Số điện thoại',
                  keyboardType: TextInputType.phone,
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
              child: const Text('Lưu'),
              onPressed: () {
                Navigator.pop(ctx);
                unawaited(widget.onEdit(nameCtrl.text, phoneCtrl.text));
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Small Helpers ────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.kTextMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.kTextSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        unawaited(HapticFeedback.selectionClick());
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
