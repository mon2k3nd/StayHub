import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/theme/app_theme.dart';
import '../application/room_member_provider.dart';
import 'dart:async' show unawaited;

// ─── Model ────────────────────────────────────────────────────────────────────
class RoomMemberModel {
  final int? id;
  final int roomId;
  final String name;
  final String? phone;
  final String? idNumber;
  final String role; // TENANT_MAIN, TENANT_SUB, GUEST
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final bool isActive;
  final bool isEkycVerified;

  const RoomMemberModel({
    this.id,
    required this.roomId,
    required this.name,
    this.phone,
    this.idNumber,
    this.role = 'TENANT_SUB',
    this.checkInDate,
    this.checkOutDate,
    this.isActive = true,
    this.isEkycVerified = false,
  });

  // BUGFIX (data): coerce an toàn — tránh TypeError khi backend trả String/null.
  static int? _toIntOrNull(dynamic v) =>
      v == null ? null : (v is num ? v.toInt() : int.tryParse(v.toString()));

  static DateTime? _toDate(dynamic v) =>
      v == null ? null : DateTime.tryParse(v.toString());

  factory RoomMemberModel.fromJson(Map<String, dynamic> j) => RoomMemberModel(
    id: _toIntOrNull(j['id']),
    roomId: _toIntOrNull(j['roomId']) ?? 0,
    name: (j['fullName'] ?? j['name'])?.toString() ?? '',
    phone: (j['phoneNumber'] ?? j['phone'])?.toString(),
    idNumber: (j['cccdNumber'] ?? j['idNumber'])?.toString(),
    role: j['role']?.toString() ?? 'TENANT_SUB',
    checkInDate: _toDate(j['checkInDate']),
    checkOutDate: _toDate(j['checkOutDate']),
    isActive: j['isActive'] is bool ? j['isActive'] as bool : true,
    isEkycVerified: j['isEkycVerified'] is bool
        ? j['isEkycVerified'] as bool
        : false,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'roomId': roomId,
    'fullName': name,
    'name': name,
    if (phone != null) 'phoneNumber': phone,
    'phone': phone,
    if (idNumber != null) 'cccdNumber': idNumber,
    'idNumber': idNumber,
    'role': role,
    if (checkInDate != null) 'checkInDate': checkInDate!.toIso8601String(),
    if (checkOutDate != null) 'checkOutDate': checkOutDate!.toIso8601String(),
    'isActive': isActive,
    'isEkycVerified': isEkycVerified,
  };
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class RoomMembersScreen extends ConsumerStatefulWidget {
  final int roomId;
  final String roomName;

  const RoomMembersScreen({
    super.key,
    required this.roomId,
    required this.roomName,
  });

  @override
  ConsumerState<RoomMembersScreen> createState() => _RoomMembersScreenState();
}

class _RoomMembersScreenState extends ConsumerState<RoomMembersScreen> {
  static const _roleMeta = {
    'TENANT_MAIN': ('👑', 'Khách chính', Color(0xFF298FFF)),
    'TENANT_SUB': ('👤', 'Khách phụ', Color(0xFF6366F1)),
    'GUEST': ('🛎️', 'Khách vãng lai', AppTheme.kSuccess),
  };

  @override
  void initState() {
    super.initState();
  }

  Future<void> _addMember(RoomMemberModel member) async {
    final success = await ref
        .read(roomMemberProvider(widget.roomId).notifier)
        .addMember(member.toJson());
    if (success) {
      if (mounted) ToastUtils.show(context, 'Đã thêm thành viên!');
    } else {
      if (mounted) ToastUtils.show(context, 'Có lỗi xảy ra', isError: true);
    }
  }

  Future<void> _checkOutMember(int memberId) async {
    final success = await ref
        .read(roomMemberProvider(widget.roomId).notifier)
        .checkoutMember(memberId);
    if (success) {
      if (mounted) ToastUtils.show(context, 'Đã ghi nhận ra khỏi phòng.');
    } else {
      if (mounted) ToastUtils.show(context, 'Có lỗi xảy ra', isError: true);
    }
  }

  Future<void> _verifyEkyc(RoomMemberModel member) async {
    // Show confirmation dialog first
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Xác nhận eKYC'),
        content: Text(
          'Bạn có chắc chắn muốn xác thực danh tính cho:\n\n👤 ${member.name}\nCMND/CCCD: ${member.idNumber}\n\nThao tác này không thể hoàn tác.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Hủy'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text(
              'Xác nhận',
              style: TextStyle(color: Color(0xFF10B981)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final success = await ref
        .read(roomMemberProvider(widget.roomId).notifier)
        .updateMember(member.id!, {'isEkycVerified': true});
    if (success) {
      if (mounted) ToastUtils.show(context, 'Xác thực eKYC thành công!');
    } else {
      if (mounted) ToastUtils.show(context, 'Lỗi cập nhật eKYC', isError: true);
    }
  }

  void _showAddMemberSheet() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final idCtrl = TextEditingController();
    String selRole = 'TENANT_SUB';

    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, ss) => Container(
            height: MediaQuery.of(ctx).size.height * 0.75,
            decoration: const BoxDecoration(
              color: CupertinoColors.systemGroupedBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.kTextMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Thêm Thành Viên',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Icon(
                          CupertinoIcons.xmark_circle_fill,
                          color: AppTheme.kTextMuted,
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(color: CupertinoColors.separator, height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Role selector
                        const Text(
                          'Vai trò',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.kTextSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: _roleMeta.entries.map((e) {
                            final sel = selRole == e.key;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => ss(() => selRole = e.key),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: sel
                                        ? e.value.$3.withValues(alpha: 0.12)
                                        : CupertinoColors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: sel
                                          ? e.value.$3
                                          : AppTheme.kTextMuted,
                                      width: sel ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Text(
                                        e.value.$1,
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        e.value.$2,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: sel
                                              ? e.value.$3
                                              : AppTheme.kTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),
                        const Text(
                          'Họ tên *',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.kTextSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        CupertinoTextField(
                          controller: nameCtrl,
                          placeholder: 'Nguyễn Văn A',
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: CupertinoColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.kTextMuted),
                          ),
                        ),

                        const SizedBox(height: 12),
                        const Text(
                          'Số điện thoại',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.kTextSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        CupertinoTextField(
                          controller: phoneCtrl,
                          placeholder: '09xx xxx xxx',
                          keyboardType: TextInputType.phone,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: CupertinoColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.kTextMuted),
                          ),
                        ),

                        const SizedBox(height: 12),
                        const Text(
                          'CMND / CCCD',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.kTextSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        CupertinoTextField(
                          controller: idCtrl,
                          placeholder: '001234567890',
                          keyboardType: TextInputType.number,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: CupertinoColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.kTextMuted),
                          ),
                        ),

                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF6366F1,
                            ).withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(
                                0xFF6366F1,
                              ).withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                CupertinoIcons.info_circle,
                                color: Color(0xFF6366F1),
                                size: 14,
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Số người thực tế dùng để phân bổ phí Pool "Chia theo Đầu người". Luôn cập nhật chính xác!',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6366F1),
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
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    MediaQuery.of(ctx).viewInsets.bottom + 24,
                  ),
                  child: CupertinoButton.filled(
                    borderRadius: BorderRadius.circular(14),
                    child: const Text('Thêm Thành Viên'),
                    onPressed: () {
                      if (nameCtrl.text.trim().isEmpty) {
                        ToastUtils.show(
                          context,
                          'Vui lòng nhập họ tên!',
                          isError: true,
                        );
                        return;
                      }
                      final phone = phoneCtrl.text.trim();
                      if (phone.isNotEmpty) {
                        final phoneRegex = RegExp(r'^0[0-9]{9,10}$');
                        if (!phoneRegex.hasMatch(phone)) {
                          ToastUtils.show(
                            context,
                            'Số điện thoại không hợp lệ (VD: 0912345678)',
                            isError: true,
                          );
                          return;
                        }
                      }
                      Navigator.pop(ctx);
                      unawaited(
                        _addMember(
                          RoomMemberModel(
                            roomId: widget.roomId,
                            name: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim().isEmpty
                                ? null
                                : phoneCtrl.text.trim(),
                            idNumber: idCtrl.text.trim().isEmpty
                                ? null
                                : idCtrl.text.trim(),
                            role: selRole,
                            checkInDate: DateTime.now(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmCheckOut(RoomMemberModel member) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Xác nhận Ra khỏi Phòng'),
          content: Text(
            '${member.name} sẽ được ghi nhận rời phòng hôm nay.\nSố người pool sẽ giảm từ chu kỳ sau.',
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Ra khỏi phòng'),
              onPressed: () {
                Navigator.pop(ctx);
                unawaited(_checkOutMember(member.id!));
              },
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Hủy'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final membersAsync = ref.watch(roomMemberProvider(widget.roomId));

    return LiquidGlassScaffold(
      title: 'Thành Viên — ${widget.roomName}',
      backgroundColors: AppTheme.kBackgroundLight,
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _showAddMemberSheet,
        child: const Icon(
          CupertinoIcons.person_add_solid,
          color: Color(0xFF298FFF),
          size: 26,
        ),
      ),
      useScrollView: false,
      child: membersAsync.when(
        data: (data) {
          final members = data.map((e) => RoomMemberModel.fromJson(e)).toList();
          final activeMembers = members.where((m) => m.isActive).toList();
          final inactiveMembers = members.where((m) => !m.isActive).toList();
          return _buildContent(activeMembers, inactiveMembers);
        },
        loading: () =>
            const Center(child: CupertinoActivityIndicator(radius: 16)),
        error: (err, _) => _buildError(err.toString()),
      ),
    );
  }

  Widget _buildError(String error) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          CupertinoIcons.exclamationmark_triangle,
          color: CupertinoColors.systemRed,
          size: 48,
        ),
        const SizedBox(height: 12),
        Text(
          error,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.kTextSecondary),
        ),
        const SizedBox(height: 16),
        CupertinoButton.filled(
          child: const Text('Thử lại'),
          onPressed: () => ref.invalidate(roomMemberProvider(widget.roomId)),
        ),
      ],
    ),
  );

  Widget _buildContent(
    List<RoomMemberModel> active,
    List<RoomMemberModel> inactive,
  ) {
    final fmt = DateFormat('dd/MM/yyyy');
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Headcount banner ───────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Count badge
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '${active.length}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: CupertinoColors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Số người hiện tại',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${active.length} người đang ở',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: active.isNotEmpty
                                ? AppTheme.kSuccess.withValues(alpha: 0.1)
                                : const Color(
                                    0xFFFF9500,
                                  ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            active.isNotEmpty
                                ? '✅ Dùng để phân bổ Pool đầu người'
                                : '⚠️ Phòng chưa có người ở',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: active.isNotEmpty
                                  ? AppTheme.kSuccess
                                  : const Color(0xFFFF9500),
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

        // ── Active members ─────────────────────────────────────────────
        if (active.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 16, 6),
              child: Text(
                'ĐANG Ở',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4B5563),
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _MemberCard(
                  member: active[i],
                  fmt: fmt,
                  onCheckOut: active[i].role != 'TENANT_MAIN'
                      ? () => _confirmCheckOut(active[i])
                      : null,
                  onVerifyEkyc:
                      (!active[i].isEkycVerified && active[i].idNumber != null)
                      ? () => _verifyEkyc(active[i])
                      : null,
                ),
                childCount: active.length,
              ),
            ),
          ),
        ] else
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Text('🏠', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 8),
                  Text(
                    'Phòng chưa có thành viên nào.',
                    style: TextStyle(color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ),

        // ── History ────────────────────────────────────────────────────
        if (inactive.isNotEmpty) ...[
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 16, 6),
              child: Text(
                'LỊCH SỬ ĐÃ RỜI PHÒNG',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF9CA3AF),
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) =>
                    _MemberCard(member: inactive[i], fmt: fmt, isHistory: true),
                childCount: inactive.length,
              ),
            ),
          ),
        ],

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

// ─── Member Card ──────────────────────────────────────────────────────────────
class _MemberCard extends StatelessWidget {
  final RoomMemberModel member;
  final DateFormat fmt;
  final VoidCallback? onCheckOut;
  final VoidCallback? onVerifyEkyc;
  final bool isHistory;

  const _MemberCard({
    required this.member,
    required this.fmt,
    this.onCheckOut,
    this.onVerifyEkyc,
    this.isHistory = false,
  });

  @override
  Widget build(BuildContext context) {
    final meta = {
      'TENANT_MAIN': ('👑', 'Khách chính', const Color(0xFF298FFF)),
      'TENANT_SUB': ('👤', 'Khách phụ', const Color(0xFF6366F1)),
      'GUEST': ('🛎️', 'Vãng lai', AppTheme.kSuccess),
    };
    final (icon, label, color) =
        meta[member.role] ?? ('👤', member.role, const Color(0xFF6366F1));

    return Opacity(
      opacity: isHistory ? 0.6 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 12,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (member.idNumber != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: member.isEkycVerified
                                ? AppTheme.kSuccess.withValues(alpha: 0.1)
                                : AppTheme.kError.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                member.isEkycVerified
                                    ? CupertinoIcons.checkmark_seal_fill
                                    : CupertinoIcons.xmark_seal_fill,
                                size: 10,
                                color: member.isEkycVerified
                                    ? AppTheme.kSuccess
                                    : AppTheme.kError,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                member.isEkycVerified ? 'eKYC' : 'Chưa eKYC',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: member.isEkycVerified
                                      ? AppTheme.kSuccess
                                      : AppTheme.kError,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  if (member.phone != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '📞 ${member.phone}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                  if (member.idNumber != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      '🪪 ${member.idNumber}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                  if (member.checkInDate != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      isHistory
                          ? 'Vào: ${fmt.format(member.checkInDate!)}  →  Ra: ${member.checkOutDate != null ? fmt.format(member.checkOutDate!) : "?"}'
                          : 'Vào phòng: ${fmt.format(member.checkInDate!)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (onVerifyEkyc != null)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onVerifyEkyc,
                child: const Icon(
                  CupertinoIcons.checkmark_shield_fill,
                  color: CupertinoColors.activeBlue,
                  size: 28,
                ),
              ),
            if (onCheckOut != null)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onCheckOut,
                child: const Icon(
                  CupertinoIcons.arrow_right_circle_fill,
                  color: CupertinoColors.systemOrange,
                  size: 28,
                ),
              ),
            if (isHistory)
              const Icon(
                CupertinoIcons.checkmark_seal_fill,
                color: Color(0xFF9CA3AF),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
