import 'package:flutter/cupertino.dart';

import '../../../core/theme/app_theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_button.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../contract/application/contract_notifier.dart';
import '../application/ticket_provider.dart';
import '../../../core/providers/core_providers.dart';
import 'dart:async' show unawaited;

class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  final _descController = TextEditingController();
  final _desireController = TextEditingController();
  int _selectedCategory = 0;
  int _selectedSeverity = 1;
  bool _isLoading = false;

  final _categories = [
    '⚡ Điện',
    '💧 Nước',
    '🪑 Nội thất',
    '📶 Mạng',
    '🔧 Khác',
  ];
  final _severities = ['Thấp', 'Bình thường', 'Cao', 'Khẩn cấp'];
  final _severityValues = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];

  // Scope
  int _incidentScope = 0; // 0: Room, 1: Pool, 2: Shared Facility

  int? _selectedPoolId;
  List<Map<String, dynamic>> _availablePools = [];

  int? _selectedFacilityId;
  List<Map<String, dynamic>> _availableFacilities = [];

  @override
  void initState() {
    super.initState();
    unawaited(_loadLocations());
  }

  Future<void> _loadLocations() async {
    try {
      final contracts = await ref.read(contractProvider.future);
      if (contracts.isNotEmpty) {
        final branchId = contracts.first.branchId;
        if (branchId == null) return;
        final dio = ref.read(dioProvider);

        final respPools = await dio.get('/v1/service-pools/branch/$branchId');
        // BUGFIX (data): tránh `as Map<String, dynamic>` ném TypeError khi
        // phần tử không phải Map — lọc an toàn bằng whereType.
        final pools =
            (respPools.data is List ? respPools.data as List : const [])
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();

        final respFacilities = await dio.get(
          '/v1/branches/$branchId/facilities',
        );
        final facilities =
            (respFacilities.data is Map && respFacilities.data['data'] is List
                    ? respFacilities.data['data'] as List
                    : const [])
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();

        if (mounted) {
          setState(() {
            _availablePools = pools;
            _availableFacilities = facilities;
          });
        }
      }
    } catch (e) {
      debugPrint('[CreateTicket] Failed to load pools/facilities: $e');
      // Non-critical: form still works, just no location options
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _desireController.dispose();
    super.dispose();
  }

  Future<void> _submitTicket() async {
    if (_descController.text.trim().isEmpty) {
      _showDialog('Lỗi', 'Vui lòng nhập mô tả sự cố.');
      return;
    }

    final activeContracts = ref.read(contractProvider).value;
    if (activeContracts == null || activeContracts.isEmpty) {
      _showDialog('Lỗi', 'Bạn chưa thuê phòng nào.');
      return;
    }

    final roomId = activeContracts.first.roomId;
    setState(() => _isLoading = true);

    final success = await ref.read(ticketProvider.notifier).createTicket({
      'roomId': roomId,
      'category': _categories[_selectedCategory],
      'description': _descController.text.trim(),
      'severity': _severityValues[_selectedSeverity],
      'tenantDesire': _desireController.text.trim(),
      if (_incidentScope == 1 && _selectedPoolId != null)
        'poolId': _selectedPoolId!,
      if (_incidentScope == 2 && _selectedFacilityId != null)
        'sharedFacilityId': _selectedFacilityId!,
    }, null);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        _showDialog(
          'Thành công',
          'Đã gửi yêu cầu sửa chữa. Chủ nhà sẽ sớm điều phối nhân viên đến khắc phục.',
          popOnOk: true,
        );
      } else {
        _showDialog('Lỗi', 'Không thể gửi yêu cầu.');
      }
    }
  }

  void _showDialog(String title, String content, {bool popOnOk = false}) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            CupertinoDialogAction(
              child: const Text('Đóng'),
              onPressed: () {
                Navigator.pop(ctx);
                if (popOnOk) context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationScopeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'VỊ TRÍ SỰ CỐ',
          style: TextStyle(
            color: Color(0xFF374151),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: CupertinoSlidingSegmentedControl<int>(
            groupValue: _incidentScope,
            backgroundColor: const Color(0xFFF3F4F6),
            thumbColor: CupertinoColors.white,
            children: const {
              0: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  'Trong phòng',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              1: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  'Toàn nhà',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              2: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  'Khu vực chung',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            },
            onValueChanged: (v) {
              if (v != null) setState(() => _incidentScope = v);
            },
          ),
        ),

        if (_incidentScope == 1 && _availablePools.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showPicker(true),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedPoolId != null
                          ? (_availablePools
                                    .where((p) => p['id'] == _selectedPoolId)
                                    .map((p) => p['name']?.toString() ?? 'Pool')
                                    .firstOrNull ??
                                'Chọn Pool...')
                          : 'Chọn hệ thống bị sự cố...',
                      style: TextStyle(
                        fontSize: 14,
                        color: _selectedPoolId != null
                            ? const Color(0xFF111827)
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.chevron_down,
                    size: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                ],
              ),
            ),
          ),
        ],

        if (_incidentScope == 2 && _availableFacilities.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showPicker(false),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedFacilityId != null
                          ? (_availableFacilities
                                    .where(
                                      (p) => p['id'] == _selectedFacilityId,
                                    )
                                    .map(
                                      (p) => p['name']?.toString() ?? 'Khu vực',
                                    )
                                    .firstOrNull ??
                                'Chọn khu vực...')
                          : 'Chọn khu vực dùng chung (WC, Bếp)...',
                      style: TextStyle(
                        fontSize: 14,
                        color: _selectedFacilityId != null
                            ? const Color(0xFF111827)
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.chevron_down,
                    size: 14,
                    color: Color(0xFF9CA3AF),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showPicker(bool isPool) {
    final list = isPool ? _availablePools : _availableFacilities;
    if (list.isEmpty) return;

    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => Container(
          height: 300,
          color: AppTheme.kBackgroundLight,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isPool ? 'Chọn hệ thống' : 'Chọn khu vực chung',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Xong'),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 44,
                  onSelectedItemChanged: (i) => setState(() {
                    // BUGFIX (data): tránh `as int?` ném TypeError khi id là
                    // String/null.
                    final rawId = list[i]['id'];
                    final id = rawId is num
                        ? rawId.toInt()
                        : int.tryParse(rawId?.toString() ?? '');
                    if (isPool) {
                      _selectedPoolId = id;
                    } else {
                      _selectedFacilityId = id;
                    }
                  }),
                  children: list
                      .map(
                        (p) => Center(
                          child: Text(
                            p['name']?.toString() ??
                                (isPool
                                    ? 'Pool #${p['id']}'
                                    : 'Facility #${p['id']}'),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      title: 'Báo Sự Cố Mới',
      backgroundColors: AppTheme.kBackgroundLight,
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        child: const Icon(
          CupertinoIcons.clear_circled_solid,
          color: CupertinoColors.black,
          size: 28,
        ),
        onPressed: () => context.pop(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category section
            const Text(
              'LOẠI SỰ CỐ',
              style: TextStyle(
                color: Color(0xFF374151),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedCategory == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFDC2626)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFDC2626)
                              : const Color(0xFFE5E7EB),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFFDC2626,
                                  ).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        _categories[index],
                        style: TextStyle(
                          color: isSelected
                              ? CupertinoColors.white
                              : const Color(0xFF374151),
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Severity section
            const Text(
              'MỨC ĐỘ NGHIÊM TRỌNG',
              style: TextStyle(
                color: Color(0xFF374151),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 42,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _severities.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedSeverity == index;
                  final colors = [
                    AppTheme.kSuccess, // LOW - green
                    const Color(0xFF2563EB), // MEDIUM - blue
                    const Color(0xFFF97316), // HIGH - orange
                    const Color(0xFFDC2626), // CRITICAL - red
                  ];
                  final color = colors[index];
                  final bgColors = [
                    const Color(0xFFECFDF5),
                    const Color(0xFFEFF6FF),
                    const Color(0xFFFFF7ED),
                    const Color(0xFFFEF2F2),
                  ];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedSeverity = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? color : bgColors[index],
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected
                              ? color
                              : color.withValues(alpha: 0.3),
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        _severities[index],
                        style: TextStyle(
                          color: isSelected ? CupertinoColors.white : color,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Location Scope Section
            _buildLocationScopeSection(),
            const SizedBox(height: 24),

            // Description
            const Text(
              'MÔ TẢ CHI TIẾT',
              style: TextStyle(
                color: Color(0xFF374151),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _descController,
              placeholder: 'Ví dụ: Đèn phòng tắm bị cháy, điện bị chập...',
              placeholderStyle: const TextStyle(
                color: Color(0xFFADB5BD),
                fontSize: 14,
              ),
              style: const TextStyle(color: Color(0xFF111827), fontSize: 14),
              padding: const EdgeInsets.all(16),
              minLines: 4,
              maxLines: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
            ),
            const SizedBox(height: 20),

            // Desire
            const Text(
              'MONG MUỐN CỦA BẠN (Tùy chọn)',
              style: TextStyle(
                color: Color(0xFF374151),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            CupertinoTextField(
              controller: _desireController,
              placeholder: 'Ví dụ: Cần thợ đến sau 5h chiều...',
              placeholderStyle: const TextStyle(
                color: Color(0xFFADB5BD),
                fontSize: 14,
              ),
              style: const TextStyle(color: Color(0xFF111827), fontSize: 14),
              padding: const EdgeInsets.all(16),
              minLines: 2,
              maxLines: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
            ),
            const SizedBox(height: 32),

            _isLoading
                ? const Center(child: CupertinoActivityIndicator(radius: 16))
                : GlassButton(
                    text: 'Gửi yêu cầu sửa chữa',
                    icon: CupertinoIcons.paperplane_fill,
                    color: const Color(0xFFDC2626),
                    onPressed: _submitTicket,
                  ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
