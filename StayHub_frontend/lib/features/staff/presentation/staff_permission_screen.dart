import 'dart:convert';
import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../auth/application/auth_notifier.dart';
import 'staff_management_screen.dart';
import 'dart:async' show unawaited;

// ─── Permission Model ─────────────────────────────
class StaffPermissions {
  final bool canRecordMeters; // Ghi điện nước
  final bool canViewFinancial; // Xem báo cáo tài chính
  final bool canManageBills; // Quản lý hóa đơn
  final bool canHandleTickets; // Xử lý phiếu sự cố
  final bool canManageContracts; // Quản lý hợp đồng
  final bool canSendNotifications; // Gửi thông báo

  // Mặc định = true vì khi chủ nhà chưa phân quyền gì
  // thì nhân viên được quyền làm tất cả
  const StaffPermissions({
    this.canRecordMeters = true,
    this.canViewFinancial = true,
    this.canManageBills = true,
    this.canHandleTickets = true,
    this.canManageContracts = true,
    this.canSendNotifications = true,
  });

  /// Toàn quyền (default)
  const StaffPermissions.fullAccess()
    : canRecordMeters = true,
      canViewFinancial = true,
      canManageBills = true,
      canHandleTickets = true,
      canManageContracts = true,
      canSendNotifications = true;

  factory StaffPermissions.fromJson(Map<String, dynamic> json) {
    // Nếu tất cả giá trị đều null/false = chưa được thiết lập => toàn quyền
    final hasAnyExplicit = json.values.any((v) => v == true);
    if (!hasAnyExplicit) return const StaffPermissions.fullAccess();
    return StaffPermissions(
      canRecordMeters: json['canRecordMeters'] == true,
      canViewFinancial: json['canViewFinancial'] == true,
      canManageBills: json['canManageBills'] == true,
      canHandleTickets: json['canHandleTickets'] == true,
      canManageContracts: json['canManageContracts'] == true,
      canSendNotifications: json['canSendNotifications'] == true,
    );
  }

  /// Parse từ chuỗi – hỗ trợ cả JSON lẫn CSV cũ
  /// CSV ví dụ: "CAN_WRITE_METER,CAN_MANAGE_BILLS"
  /// JSON ví dụ: "{\"canRecordMeters\":true}"
  static StaffPermissions parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const StaffPermissions.fullAccess();
    }
    final s = raw.trim();
    // JSON format
    if (s.startsWith('{')) {
      try {
        final map = Map<String, dynamic>.from(jsonDecode(s) as Map);
        // {} rỗng → full access
        if (map.isEmpty) return const StaffPermissions.fullAccess();
        return StaffPermissions.fromJson(map);
      } catch (e, st) {
        debugPrint('Error: $e\n$st');
      }
    }
    // CSV format (legacy): CAN_WRITE_METER,CAN_VIEW_FINANCE,…
    final parts = s.split(',').map((p) => p.trim().toUpperCase()).toSet();
    if (parts.isEmpty) return const StaffPermissions.fullAccess();
    return StaffPermissions(
      canRecordMeters:
          parts.contains('CAN_WRITE_METER') ||
          parts.contains('CAN_RECORD_METERS'),
      canViewFinancial:
          parts.contains('CAN_VIEW_FINANCE') ||
          parts.contains('CAN_VIEW_FINANCIAL'),
      canManageBills: parts.contains('CAN_MANAGE_BILLS'),
      canHandleTickets: parts.contains('CAN_HANDLE_TICKETS'),
      canManageContracts:
          parts.contains('CAN_MANAGE_CONTRACTS') ||
          parts.contains('CAN_VIEW_CONTRACTS'),
      canSendNotifications:
          parts.contains('CAN_SEND_NOTIFICATION') ||
          parts.contains('CAN_SEND_NOTIFICATIONS'),
    );
  }

  Map<String, dynamic> toJson() => {
    'canRecordMeters': canRecordMeters,
    'canViewFinancial': canViewFinancial,
    'canManageBills': canManageBills,
    'canHandleTickets': canHandleTickets,
    'canManageContracts': canManageContracts,
    'canSendNotifications': canSendNotifications,
  };

  StaffPermissions copyWith({
    bool? canRecordMeters,
    bool? canViewFinancial,
    bool? canManageBills,
    bool? canHandleTickets,
    bool? canManageContracts,
    bool? canSendNotifications,
  }) => StaffPermissions(
    canRecordMeters: canRecordMeters ?? this.canRecordMeters,
    canViewFinancial: canViewFinancial ?? this.canViewFinancial,
    canManageBills: canManageBills ?? this.canManageBills,
    canHandleTickets: canHandleTickets ?? this.canHandleTickets,
    canManageContracts: canManageContracts ?? this.canManageContracts,
    canSendNotifications: canSendNotifications ?? this.canSendNotifications,
  );
}

// ─── Screen ───────────────────────────────────────
class StaffPermissionScreen extends ConsumerStatefulWidget {
  final StaffModel staff;

  const StaffPermissionScreen({super.key, required this.staff});

  @override
  ConsumerState<StaffPermissionScreen> createState() =>
      _StaffPermissionScreenState();
}

class _StaffPermissionScreenState extends ConsumerState<StaffPermissionScreen> {
  final TextEditingController _maxCashController = TextEditingController();

  StaffPermissions _perms = const StaffPermissions();
  bool _isSaving = false;
  bool _isLoaded = false;
  String? _selectedRole;

  final _roles = [
    ('MANAGER', 'Quản lý', 'Toàn quyền vận hành', CupertinoColors.systemBlue),
    (
      'ACCOUNTANT',
      'Kế toán',
      'Tập trung tài chính & hóa đơn',
      CupertinoColors.systemGreen,
    ),
    (
      'SECURITY',
      'Bảo vệ',
      'Kiểm soát ra vào & ghi điện nước',
      CupertinoColors.systemOrange,
    ),
    (
      'CUSTOM',
      'Tùy chỉnh',
      'Tự thiết lập từng quyền riêng lẻ',
      CupertinoColors.systemPurple,
    ),
  ];

  int? get _firstAssignmentId {
    final assignments = widget.staff.assignments;
    if (assignments.isEmpty) return null;
    final a = assignments.first;
    if (a is Map<String, dynamic>) {
      // BUGFIX (data): coerce an toàn — tránh `as int?` ném TypeError khi
      // id là String/null từ JSON.
      final rawId = a['id'];
      if (rawId is num) return rawId.toInt();
      return int.tryParse(rawId?.toString() ?? '');
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadCurrentPermissions());
  }

  Future<void> _loadCurrentPermissions() async {
    final assignments = widget.staff.assignments;
    if (assignments.isNotEmpty) {
      final a = assignments.first;
      if (a is Map<String, dynamic>) {
        final permsStr = a['permissions'] as String?;
        final role = a['staffRole'] as String?;
        if (permsStr != null && permsStr.isNotEmpty) {
          try {
            final data = jsonDecode(permsStr);
            _perms = StaffPermissions.fromJson(data);
          } catch (e, st) {
            debugPrint('Error: $e\n$st');
          }
        }
        _selectedRole = role;
      }
    }

    // Setup initial maxCashLimit from staff wallet if available (Mocked for now)
    final maxCashLimit = widget.staff.maxCashLimit;
    if (maxCashLimit != null) {
      _maxCashController.text = maxCashLimit.toString();
    }

    setState(() => _isLoaded = true);
  }

  void _applyPreset(String role) {
    setState(() {
      _selectedRole = role;
      switch (role) {
        case 'MANAGER':
          _perms = const StaffPermissions(
            canRecordMeters: true,
            canViewFinancial: true,
            canManageBills: true,
            canHandleTickets: true,
            canManageContracts: true,
            canSendNotifications: true,
          );
          break;
        case 'ACCOUNTANT':
          _perms = const StaffPermissions(
            canViewFinancial: true,
            canManageBills: true,
          );
          break;
        case 'SECURITY':
          _perms = const StaffPermissions(
            canRecordMeters: true,
            canHandleTickets: true,
          );
          break;
        case 'CUSTOM':
          break;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiClientProvider);

      int? aId = _firstAssignmentId;
      if (aId == null) {
        // Auto assign to all branches
        final auth = ref.read(authProvider);
        final ownerId = auth.value?.id;
        if (ownerId != null) {
          await api.post(
            '/v1/staff/${widget.staff.id}/assign-branches',
            data: {'ownerId': ownerId, 'branchIds': []},
          );

          // Fetch assignments again to get the new aId
          final res = await api.get(
            '/v1/staff/assignments/staff/${widget.staff.id}',
          );
          if (res['data'] != null) {
            final List list = res['data'];
            if (list.isNotEmpty) {
              aId = list.first['id'];
            }
          }
        }
      }

      if (aId == null) {
        _showAlert('Lỗi', 'Không thể khởi tạo phân công!');
        return;
      }

      // Backend expects Map<String, String> where permissions is a JSON string
      final payload = {
        'permissions': jsonEncode(_perms.toJson()),
        'staffRole': _selectedRole ?? 'STAFF',
      };

      await api.put('/v1/staff/assignments/$aId/permissions', data: payload);

      // Update maxCashLimit
      final maxCashStr = _maxCashController.text.trim();
      final maxCash = maxCashStr.isEmpty ? null : double.tryParse(maxCashStr);
      await api.put(
        '/v1/staff/${widget.staff.id}/wallet/max-cash-limit',
        data: {'maxCashLimit': maxCash},
      );

      // Also refresh the staff list
      ref.invalidate(staffListNotifierProvider);

      if (mounted) {
        _showAlert('Thành công', 'Đã cập nhật quyền cho ${widget.staff.name}!');
      }
    } catch (e) {
      if (mounted) _showAlert('Lỗi', 'Không thể lưu: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAlert(String title, String msg) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (_) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(msg),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      title: 'Phân Quyền Nhân Viên',
      child: !_isLoaded
          ? const Center(child: CupertinoActivityIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Staff info card
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: LiquidGlassColors.ownerAccent.withValues(
                              alpha: 0.15,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              widget.staff.name.isNotEmpty
                                  ? widget.staff.name[0].toUpperCase()
                                  : 'N',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: LiquidGlassColors.ownerAccent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.staff.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: CupertinoColors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.staff.phoneNumber,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF4B5563),
                                ),
                              ),
                              if (widget.staff.assignments.isNotEmpty)
                                Text(
                                  '${widget.staff.assignments.length} khu trọ được phân công',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: CupertinoColors.systemGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Role preset selector
                  const Text(
                    'CHỌN VAI TRÒ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 2.2,
                        ),
                    itemCount: _roles.length,
                    itemBuilder: (_, i) {
                      final r = _roles[i];
                      final isSelected = _selectedRole == r.$1;
                      return GestureDetector(
                        onTap: () => _applyPreset(r.$1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? r.$4.withValues(alpha: 0.15)
                                : CupertinoColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? r.$4
                                  : const Color(0xFFE5E7EB),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isSelected
                                        ? CupertinoIcons.checkmark_circle_fill
                                        : CupertinoIcons.circle,
                                    color: isSelected
                                        ? r.$4
                                        : const Color(0xFFD1D5DB),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    r.$2,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? r.$4
                                          : const Color(0xFF111827),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                r.$3,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF6B7280),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Detailed permissions
                  const Text(
                    'QUYỀN CỤ THỂ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),

                  GlassContainer(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _PermissionTile(
                          icon: CupertinoIcons.gauge,
                          imagePath: 'assets/images/features/ocr_meter.png',
                          title: 'Ghi điện nước',
                          subtitle: 'Chốt số điện, nước hàng tháng',
                          color: const Color(0xFF298FFF),
                          value: _perms.canRecordMeters,
                          onChanged: (v) => setState(() {
                            _perms = _perms.copyWith(canRecordMeters: v);
                            _selectedRole = 'CUSTOM';
                          }),
                        ),
                        _divider(),
                        _PermissionTile(
                          icon: CupertinoIcons.chart_bar_fill,
                          imagePath: 'assets/images/features/ai_financial.png',
                          title: 'Xem báo cáo tài chính',
                          subtitle: 'Doanh thu, chi phí, lợi nhuận',
                          color: const Color(0xFF10B981),
                          value: _perms.canViewFinancial,
                          onChanged: (v) => setState(() {
                            _perms = _perms.copyWith(canViewFinancial: v);
                            _selectedRole = 'CUSTOM';
                          }),
                        ),
                        _divider(),
                        _PermissionTile(
                          icon: CupertinoIcons.money_dollar_circle_fill,
                          imagePath: 'assets/images/features/feat_payments.png',
                          title: 'Quản lý hóa đơn',
                          subtitle: 'Xuất và xác nhận đóng hóa đơn',
                          color: const Color(0xFFF59E0B),
                          value: _perms.canManageBills,
                          onChanged: (v) => setState(() {
                            _perms = _perms.copyWith(canManageBills: v);
                            _selectedRole = 'CUSTOM';
                          }),
                        ),
                        _divider(),
                        _PermissionTile(
                          icon: CupertinoIcons.wrench_fill,
                          imagePath:
                              'assets/images/features/video_maintenance.png',
                          title: 'Xử lý phiếu sự cố',
                          subtitle: 'Nhận và hoàn thành ticket sửa chữa',
                          color: const Color(0xFFEF4444),
                          value: _perms.canHandleTickets,
                          onChanged: (v) => setState(() {
                            _perms = _perms.copyWith(canHandleTickets: v);
                            _selectedRole = 'CUSTOM';
                          }),
                        ),
                        _divider(),
                        _PermissionTile(
                          icon: CupertinoIcons.doc_text_fill,
                          imagePath:
                              'assets/images/features/smart_contract.png',
                          title: 'Quản lý hợp đồng',
                          subtitle: 'Xem và xử lý hợp đồng thuê phòng',
                          color: const Color(0xFF298FFF),
                          value: _perms.canManageContracts,
                          onChanged: (v) => setState(() {
                            _perms = _perms.copyWith(canManageContracts: v);
                            _selectedRole = 'CUSTOM';
                          }),
                        ),
                        _divider(),
                        _PermissionTile(
                          icon: CupertinoIcons.bell_fill,
                          imagePath: 'assets/images/features/broadcast_msg.png',
                          title: 'Gửi thông báo',
                          subtitle: 'Phát thông báo tới cư dân trong khu',
                          color: const Color(0xFFEC4899),
                          value: _perms.canSendNotifications,
                          isLast: true,
                          onChanged: (v) => setState(() {
                            _perms = _perms.copyWith(canSendNotifications: v);
                            _selectedRole = 'CUSTOM';
                          }),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Cài đặt Max Cash Limit
                  const Text(
                    'ĐỊNH MỨC TIỀN MẶT (QR HANDSHAKE)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Số tiền mặt tối đa nhân viên được phép giữ trước khi phải nộp lại cho chủ nhà. Bỏ trống để không giới hạn.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 12),
                        CupertinoTextField(
                          controller: _maxCashController,
                          keyboardType: TextInputType.number,
                          placeholder: 'Ví dụ: 10000000',
                          prefix: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(
                              CupertinoIcons.money_dollar,
                              color: AppTheme.kBrand,
                            ),
                          ),
                          suffix: const Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: Text(
                              'VNĐ',
                              style: TextStyle(color: Color(0xFF6B7280)),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: CupertinoColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: LiquidGlassColors.ownerAccent,
                      borderRadius: BorderRadius.circular(16),
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const CupertinoActivityIndicator(
                              color: CupertinoColors.white,
                            )
                          : const Text(
                              'Lưu Phân Quyền',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Info note
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: CupertinoColors.systemBlue.withValues(
                          alpha: 0.2,
                        ),
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          CupertinoIcons.info_circle_fill,
                          color: CupertinoColors.systemBlue,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Quyền sẽ có hiệu lực ngay lập tức. Nhân viên cần đăng xuất và đăng nhập lại để cập nhật.',
                            style: TextStyle(
                              fontSize: 12,
                              color: CupertinoColors.systemBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _divider() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    height: 0.5,
    color: const Color(0xFFE5E7EB),
  );
}

// ─── Permission Tile Widget ────────────────────────
class _PermissionTile extends StatelessWidget {
  final IconData icon;
  final String? imagePath;
  final String title;
  final String subtitle;
  final Color color;
  final bool value;
  final bool isLast;
  final ValueChanged<bool> onChanged;

  const _PermissionTile({
    required this.icon,
    this.imagePath,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, isLast ? 12 : 14, 16, isLast ? 12 : 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: imagePath != null
                ? Image.asset(
                    imagePath!,
                    width: 26,
                    height: 26,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    isAntiAlias: true,
                    errorBuilder: (_, __, ___) =>
                        Icon(icon, color: color, size: 20),
                  )
                : Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: color,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
