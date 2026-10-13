import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../application/staff_assignment_notifier.dart';
import '../../../core/components/app_error_widget.dart';
import 'dart:async' show unawaited;

// ─── Model ──────────────────────────────────────────
class _HandoverRequest {
  final int id;
  final int roomId;
  final String roomName;
  final String branchName;
  final String tenantName;
  final String tenantPhone;
  final String type; // 'CHECK_IN' | 'CHECK_OUT'
  final String status;
  final String date;

  const _HandoverRequest({
    required this.id,
    required this.roomId,
    required this.roomName,
    required this.branchName,
    required this.tenantName,
    required this.tenantPhone,
    required this.type,
    required this.status,
    required this.date,
  });

  factory _HandoverRequest.fromRental(Map<String, dynamic> j) =>
      _HandoverRequest(
        id: j['id'] ?? 0,
        roomId: j['roomId'] ?? 0,
        roomName: j['roomName'] ?? 'Phòng #${j['roomId']}',
        branchName: j['branchName'] ?? '',
        tenantName: j['tenantName'] ?? j['fullName'] ?? 'Khách thuê',
        tenantPhone: j['tenantPhone'] ?? j['phone'] ?? '',
        type: 'CHECK_IN',
        status: j['status'] ?? '',
        date: j['startDate'] ?? j['createdAt'] ?? '',
      );

  factory _HandoverRequest.fromCheckout(Map<String, dynamic> j) =>
      _HandoverRequest(
        id: j['id'] ?? 0,
        roomId: j['roomId'] ?? 0,
        roomName: j['roomName'] ?? 'Phòng #${j['roomId']}',
        branchName: j['branchName'] ?? '',
        tenantName: j['tenantName'] ?? j['fullName'] ?? 'Khách thuê',
        tenantPhone: j['tenantPhone'] ?? j['phone'] ?? '',
        type: 'CHECK_OUT',
        status: j['status'] ?? '',
        date: j['checkoutDate'] ?? j['createdAt'] ?? '',
      );
}

// ─── Provider ────────────────────────────────────────
final staffHandoverProvider = FutureProvider<List<_HandoverRequest>>((
  ref,
) async {
  final assignments = ref.watch(staffAssignmentProvider).assignments;
  if (assignments.isEmpty) return [];

  final api = ref.read(apiClientProvider);
  final List<_HandoverRequest> result = [];

  for (final a in assignments) {
    // Lấy rental requests đã duyệt, chưa check-in
    try {
      final res = await api.dio.get('/v1/rental-requests/owner/${a.ownerId}');
      // BUGFIX (data): tránh `as List` ném TypeError + `j['branchId']` ném
      // NoSuchMethodError khi phần tử không phải Map — lọc an toàn.
      final raw = res.data['data'];
      // BUGFIX (data): whereType<Map>() trả Map<dynamic,dynamic> — ép về
      // Map<String,dynamic> để khớp fromRental.
      final list = raw is List
          ? raw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
          : const <Map<String, dynamic>>[];
      // Lọc theo branchId nếu có
      result.addAll(
        list
            .where((j) => j['branchId'] == a.branchId || j['branchId'] == null)
            .map((j) => _HandoverRequest.fromRental(j)),
      );
    } catch (e, st) {
      debugPrint('Error: $e\n$st');
    }

    // Lấy checkout requests đã được duyệt (dùng ownerId)
    try {
      // Dùng /v1/checkouts/owner/{ownerId} vì backend không có branch-level endpoint
      final res = await api.dio.get('/v1/checkouts/owner/${a.ownerId}');
      // BUGFIX (data): tránh `as List` ném TypeError + `j['status']` ném
      // NoSuchMethodError khi phần tử không phải Map — lọc an toàn.
      final raw = res.data['data'];
      // BUGFIX (data): whereType<Map>() trả Map<dynamic,dynamic> — ép về
      // Map<String,dynamic> để khớp fromCheckout.
      final list = raw is List
          ? raw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
          : const <Map<String, dynamic>>[];
      result.addAll(
        list
            .where((j) => j['status'] == 'APPROVED' || j['status'] == 'PENDING')
            .map((j) => _HandoverRequest.fromCheckout(j)),
      );
    } catch (e, st) {
      debugPrint('Error: $e\n$st');
    }
  }

  return result;
});

// ─── Screen ──────────────────────────────────────────
class StaffHandoverScreen extends ConsumerStatefulWidget {
  const StaffHandoverScreen({super.key});

  @override
  ConsumerState<StaffHandoverScreen> createState() =>
      _StaffHandoverScreenState();
}

class _StaffHandoverScreenState extends ConsumerState<StaffHandoverScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final handoverAsync = ref.watch(staffHandoverProvider);

    return LiquidGlassScaffold(
      title: 'Bàn Giao Phòng',
      backgroundColors: AppTheme.kBackgroundLight,
      useScrollView: false,
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        child: const Icon(CupertinoIcons.refresh, color: AppTheme.kBrand),
        onPressed: () => ref.invalidate(staffHandoverProvider),
      ),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            sliver: handoverAsync.when(
              data: (requests) {
                if (requests.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: LiquidGlassColors.staffAccent.withValues(
                                alpha: 0.08,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.checkmark_circle_fill,
                              size: 56,
                              color: LiquidGlassColors.staffAccent,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Không có yêu cầu bàn giao',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Hiện tại chưa có khách nào chờ nhận/trả phòng.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final checkIns = requests
                    .where((r) => r.type == 'CHECK_IN')
                    .toList();
                final checkOuts = requests
                    .where((r) => r.type == 'CHECK_OUT')
                    .toList();

                return SliverList(
                  delegate: SliverChildListDelegate([
                    if (checkIns.isNotEmpty) ...[
                      _buildSectionHeader(
                        'Nhận phòng (${checkIns.length})',
                        CupertinoIcons.person_crop_circle_badge_plus,
                        CupertinoColors.systemGreen,
                        imagePath: 'assets/images/features/move_checklist.png',
                      ),
                      const SizedBox(height: 12),
                      ...checkIns.map((r) => _buildCard(r)),
                      const SizedBox(height: 24),
                    ],
                    if (checkOuts.isNotEmpty) ...[
                      _buildSectionHeader(
                        'Trả phòng (${checkOuts.length})',
                        CupertinoIcons.person_crop_circle_badge_minus,
                        CupertinoColors.systemOrange,
                        imagePath:
                            'assets/images/features/moveout_settlement.png',
                      ),
                      const SizedBox(height: 12),
                      ...checkOuts.map((r) => _buildCard(r)),
                    ],
                  ]),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CupertinoActivityIndicator()),
              ),
              error: (e, _) =>
                  SliverFillRemaining(child: AppErrorWidget(error: e)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    Color color, {
    String? imagePath,
  }) {
    return Row(
      children: [
        if (imagePath != null)
          Image.asset(
            imagePath,
            width: 24,
            height: 24,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            isAntiAlias: true,
            errorBuilder: (_, __, ___) => Icon(icon, color: color, size: 18),
          )
        else
          Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(_HandoverRequest r) {
    final isCheckIn = r.type == 'CHECK_IN';
    final accent = isCheckIn
        ? CupertinoColors.systemGreen
        : CupertinoColors.systemOrange;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isCheckIn
                        ? CupertinoIcons.arrow_down_to_line
                        : CupertinoIcons.arrow_up_to_line,
                    color: accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.roomName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                        ),
                      ),
                      if (r.branchName.isNotEmpty)
                        Text(
                          r.branchName,
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isCheckIn ? 'Nhận phòng' : 'Trả phòng',
                    style: TextStyle(
                      color: accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: const Color(0xFFE5E7EB)),
            const SizedBox(height: 12),
            // Tenant info
            Row(
              children: [
                const Icon(
                  CupertinoIcons.person_fill,
                  size: 14,
                  color: Color(0xFF9CA3AF),
                ),
                const SizedBox(width: 6),
                Text(
                  r.tenantName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (r.tenantPhone.isNotEmpty)
                  Text(
                    r.tenantPhone,
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
            if (r.date.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.calendar,
                    size: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Ngày ${isCheckIn ? 'dự kiến vào' : 'trả phòng'}: ${_formatDate(r.date)}',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            // Action button
            SizedBox(
              width: double.infinity,
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      color: accent,
                      borderRadius: BorderRadius.circular(12),
                      child: Text(
                        isCheckIn
                            ? 'Thực hiện bàn giao phòng'
                            : 'Xác nhận trả phòng',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.white,
                        ),
                      ),
                      onPressed: () => isCheckIn
                          ? _showCheckInModal(r)
                          : _showCheckOutModal(r),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final d = DateTime.parse(raw);
      return DateFormat('dd/MM/yyyy').format(d);
    } catch (e, st) {
      debugPrint('Error: $e\n$st');
      return raw;
    }
  }

  void _showCheckInModal(_HandoverRequest r) {
    final elecCtrl = TextEditingController(text: '0');
    final waterCtrl = TextEditingController(text: '0');
    bool keyHanded = false;

    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx2, setModal) => Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(ctx2).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Bàn giao: ${r.roomName}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Chỉ số Điện ban đầu (kWh)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: elecCtrl,
                  keyboardType: TextInputType.number,
                  padding: const EdgeInsets.all(14),
                  placeholder: '0',
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(
                      CupertinoIcons.bolt_fill,
                      color: CupertinoColors.systemYellow,
                      size: 16,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chỉ số Nước ban đầu (m³)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: waterCtrl,
                  keyboardType: TextInputType.number,
                  padding: const EdgeInsets.all(14),
                  placeholder: '0',
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(
                      CupertinoIcons.drop_fill,
                      color: CupertinoColors.systemBlue,
                      size: 16,
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Đã giao chìa khóa cho khách?',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    CupertinoSwitch(
                      value: keyHanded,
                      activeTrackColor: CupertinoColors.systemGreen,
                      onChanged: (v) => setModal(() => keyHanded = v),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        child: const Text(
                          'Hủy',
                          style: TextStyle(color: Color(0xFF374151)),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        color: keyHanded
                            ? CupertinoColors.systemGreen
                            : CupertinoColors.inactiveGray,
                        borderRadius: BorderRadius.circular(12),
                        onPressed: keyHanded
                            ? () async {
                                Navigator.pop(ctx);
                                await _confirmCheckIn(
                                  r,
                                  elecCtrl.text,
                                  waterCtrl.text,
                                );
                              }
                            : null,
                        child: const Text(
                          'Hoàn tất Bàn Giao',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCheckOutModal(_HandoverRequest r) {
    bool receivedKey = false;
    final noteCtrl = TextEditingController();

    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx2, setModal) => Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(ctx2).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Trả phòng: ${r.roomName}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Đã nhận lại chìa khóa?',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    CupertinoSwitch(
                      value: receivedKey,
                      activeTrackColor: CupertinoColors.systemOrange,
                      onChanged: (v) => setModal(() => receivedKey = v),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Ghi chú tình trạng phòng',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 8),
                CupertinoTextField(
                  controller: noteCtrl,
                  placeholder: 'VD: Phòng sạch sẽ, thiết bị nguyên vẹn...',
                  maxLines: 3,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    color: receivedKey
                        ? CupertinoColors.systemOrange
                        : CupertinoColors.inactiveGray,
                    borderRadius: BorderRadius.circular(12),
                    onPressed: receivedKey
                        ? () async {
                            Navigator.pop(ctx);
                            await _confirmCheckOut(r, noteCtrl.text);
                          }
                        : null,
                    child: const Text(
                      'Xác nhận trả phòng',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmCheckIn(
    _HandoverRequest r,
    String elec,
    String water,
  ) async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.patch(
        '/v1/rental-requests/${r.id}/checkin',
        data: {
          'electricIndicator': double.tryParse(elec) ?? 0,
          'waterIndicator': double.tryParse(water) ?? 0,
        },
      );
      ref.invalidate(staffHandoverProvider);
      if (mounted) _showSuccess('Bàn giao phòng thành công!');
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmCheckOut(_HandoverRequest r, String note) async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.patch(
        '/v1/checkout-requests/${r.id}/checkedout',
        data: {'note': note},
      );
      ref.invalidate(staffHandoverProvider);
      if (mounted) _showSuccess('Xác nhận trả phòng thành công!');
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String msg) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (c) => CupertinoAlertDialog(
          title: const Text('Thành công ✓'),
          content: Text(msg),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(c),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String msg) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (c) => CupertinoAlertDialog(
          title: const Text('Lỗi'),
          content: Text(msg),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(c),
            ),
          ],
        ),
      ),
    );
  }
}
