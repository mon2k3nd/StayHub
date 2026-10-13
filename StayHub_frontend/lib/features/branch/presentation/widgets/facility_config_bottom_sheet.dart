import 'dart:io';
import 'dart:convert';
import '../../../../core/utils/image_picker_utils.dart';
import '../../../../core/utils/toast_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async' show unawaited;

class FacilityConfigBottomSheet extends StatefulWidget {
  final Map<String, dynamic> facility;
  final List<Map<String, dynamic>> allRooms;
  final Future<void> Function(Map<String, dynamic>) onSaved;

  const FacilityConfigBottomSheet({
    super.key,
    required this.facility,
    required this.allRooms,
    required this.onSaved,
  });

  @override
  State<FacilityConfigBottomSheet> createState() =>
      _FacilityConfigBottomSheetState();
}

class _FacilityConfigBottomSheetState extends State<FacilityConfigBottomSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _electricIndexCtrl;
  late TextEditingController _waterIndexCtrl;

  final Set<String> _equipmentItems = {};

  /// Kiểu tính nước: 'PER_INDEX' (có công tơ) hoặc 'PER_PERSON' (theo đầu người).
  /// Khi thu theo đầu người thì KHÔNG cần nhập chỉ số nước ban đầu.
  String _waterPricingType = 'PER_INDEX';

  // ── Photo groups ──
  // 'MAIN' for general facility photos, 'EQUIPMENT_*' for specific items
  final Map<String, List<String>> _photoUrls = {'MAIN': []};
  final Map<String, List<XFile>> _photoLocals = {'MAIN': []};

  void _ensureEquipmentPhotoGroup(String key) {
    final eqKey = 'EQUIPMENT_$key';
    _photoUrls.putIfAbsent(eqKey, () => []);
    _photoLocals.putIfAbsent(eqKey, () => []);
  }

  bool _isSaving = false;
  double _uploadProgress = -1.0;
  String? _errorMessage; // Inline error banner inside the sheet

  final Map<String, (String, String)> _availableEquipment = {
    'BINH_NONG_LANH': ('Bình nóng lạnh', '🚿'),
    'BON_CAU_BET': ('Bồn cầu bệt', '🚽'),
    'BON_CAU_XOM': ('Bồn cầu xổm', '🚽'),
    'VOI_SEN': ('Vòi sen', '🚿'),
    'MAY_GIAT': ('Máy giặt chung', '🫧'),
    'GUONG': ('Gương soi', '🪞'),
    'CHAU_RUA': ('Chậu rửa mặt', '🚰'),
    'QUAT_THONG_GIO': ('Quạt thông gió', '💨'),
  };

  @override
  void initState() {
    super.initState();
    // Tên WC = mã ngắn (notes, VD: WC1A) theo logic Bước 3.
    final wcShortCode = widget.facility['notes']?.toString();
    _nameCtrl = TextEditingController(
      text: (wcShortCode != null && wcShortCode.isNotEmpty)
          ? wcShortCode
          : (widget.facility['name'] ?? ''),
    );
    _notesCtrl = TextEditingController(text: widget.facility['notes'] ?? '');
    _electricIndexCtrl = TextEditingController(
      text: widget.facility['electricIndexInit']?.toString() ?? '',
    );
    _waterIndexCtrl = TextEditingController(
      text: widget.facility['waterIndexInit']?.toString() ?? '',
    );

    // Khôi phục kiểu tính nước đã lưu (nếu có), mặc định theo công tơ.
    final savedWaterType = widget.facility['waterPricingType']?.toString();
    if (savedWaterType == 'PER_PERSON' || savedWaterType == 'PER_INDEX') {
      _waterPricingType = savedWaterType!;
    }

    // Parse existing equipment if any (comes back as JSON String)
    final eq = widget.facility['equipment'];
    List<dynamic>? eqList;
    if (eq != null) {
      if (eq is List) {
        eqList = eq;
      } else if (eq is String && eq.isNotEmpty) {
        try {
          eqList = jsonDecode(eq) as List<dynamic>?;
        } catch (_) {}
      }
    }
    if (eqList != null) {
      for (final e in eqList) {
        _equipmentItems.add(e.toString());
        _ensureEquipmentPhotoGroup(e.toString());
      }
    }

    // Sort allRooms by floor then room name
    // BUGFIX (data): coerce an toàn — tránh `as int?` ném TypeError khi
    // `floor` là String/null.
    int floorOf(Map<String, dynamic> m) {
      final f = m['floor'];
      return f is num ? f.toInt() : int.tryParse(f?.toString() ?? '') ?? 0;
    }

    widget.allRooms.sort((a, b) {
      final fA = floorOf(a);
      final fB = floorOf(b);
      if (fA != fB) return fA.compareTo(fB);
      final nA = a['roomName']?.toString() ?? '';
      final nB = b['roomName']?.toString() ?? '';
      return nA.compareTo(nB);
    });

    // Parse existing images (comes back as JSON String)
    final existingImages = widget.facility['images'];
    List<dynamic>? imagesList;
    if (existingImages != null) {
      if (existingImages is List) {
        imagesList = existingImages;
      } else if (existingImages is String && existingImages.isNotEmpty) {
        try {
          imagesList = jsonDecode(existingImages) as List<dynamic>?;
        } catch (_) {}
      }
    }
    if (imagesList != null) {
      _photoUrls['MAIN'] = imagesList.map((e) => e.toString()).toList();
    }

    // Parse existing featurePhotos (comes back as JSON String)
    final featurePhotos = widget.facility['featurePhotos'];
    Map<String, dynamic>? fpMap;
    if (featurePhotos != null) {
      if (featurePhotos is Map<String, dynamic>) {
        fpMap = featurePhotos;
      } else if (featurePhotos is String && featurePhotos.isNotEmpty) {
        try {
          fpMap = jsonDecode(featurePhotos) as Map<String, dynamic>?;
        } catch (_) {}
      }
    }
    if (fpMap != null) {
      fpMap.forEach((key, val) {
        if (val is List) {
          _photoUrls[key] = val.map((e) => e.toString()).toList();
        }
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    _electricIndexCtrl.dispose();
    _waterIndexCtrl.dispose();
    super.dispose();
  }

  /// Shows an inline error banner inside the sheet (auto-clears after 4s).
  /// Consistent with RoomConfigBottomSheet so the message is never hidden
  /// behind the keyboard or the fixed bottom action button.
  void _showError(String msg) {
    unawaited(HapticFeedback.heavyImpact());
    setState(() => _errorMessage = msg);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _errorMessage = null);
    });
  }

  Future<void> _save() async {
    // Guard against double-tap while a save is already in-flight.
    if (_isSaving) return;

    if (_nameCtrl.text.trim().isEmpty) {
      _showError('⚠️ Vui lòng nhập tên khu vực chung');
      return;
    }

    if (_notesCtrl.text.trim().isEmpty) {
      _showError('⚠️ Vui lòng nhập Ghi chú / Mã định danh');
      return;
    }

    if (_electricIndexCtrl.text.trim().isEmpty) {
      _showError('⚡ Vui lòng nhập Chỉ số điện ban đầu');
      return;
    }

    // Chỉ bắt buộc chỉ số nước khi thu theo công tơ.
    if (_waterPricingType == 'PER_INDEX' &&
        _waterIndexCtrl.text.trim().isEmpty) {
      _showError('💧 Vui lòng nhập Chỉ số nước ban đầu');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _uploadProgress = 0.0;
    });
    try {
      // Collect MAIN photos
      final List<String> mainPhotos = List.from(_photoUrls['MAIN']!);
      for (var f in _photoLocals['MAIN']!) {
        final bytes = await f.readAsBytes();
        mainPhotos.add(base64Encode(bytes));
      }

      // Collect EQUIPMENT photos
      final Map<String, List<String>> featurePhotos = {};
      final allGroups = _photoUrls.keys.where((k) => k != 'MAIN').toList();
      for (final key in allGroups) {
        final urls = List<String>.from(_photoUrls[key]!);
        for (var f in (_photoLocals[key] ?? [])) {
          final bytes = await f.readAsBytes();
          urls.add(base64Encode(bytes));
        }
        if (urls.isNotEmpty) featurePhotos[key] = urls;
      }

      // Report progress while the payload is being uploaded.
      if (mounted) setState(() => _uploadProgress = 0.6);

      await widget.onSaved({
        'name': _nameCtrl.text,
        'notes': _notesCtrl.text,
        'equipment': _equipmentItems.toList(),
        // KHÔNG gửi roomIds: phân công phòng ↔ WC đã được chốt ở Bước 3
        // (Room.sharedFacilities). Gửi lại sẽ ghi đè sai phân công đó.
        'images': mainPhotos,
        'featurePhotos': featurePhotos,
        'electricIndex': int.tryParse(_electricIndexCtrl.text) ?? 0,
        'waterPricingType': _waterPricingType,
        if (_waterPricingType == 'PER_INDEX')
          'waterIndex': int.tryParse(_waterIndexCtrl.text) ?? 0,
      });

      if (mounted) setState(() => _uploadProgress = 1.0);
      unawaited(HapticFeedback.lightImpact());
      if (mounted) ToastUtils.show(context, 'Lưu khu vực chung thành công!');
    } catch (e) {
      if (mounted) _showError('⚠️ Lỗi: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _uploadProgress = -1.0;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header fixed
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.drop_fill,
                        color: Color(0xFF10B981),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tiêu đề = tên WC (mã ngắn, VD: WC1A) theo logic Bước 3.
                          Text(
                            (widget.facility['notes']?.toString().isNotEmpty ??
                                    false)
                                ? widget.facility['notes'].toString()
                                : 'Cấu hình WC Chung',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.facility['type'] == 'WC'
                                ? 'Khu vực vệ sinh chung'
                                : 'Khu vực chung',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        CupertinoIcons.clear_circled_solid,
                        color: Color(0xFF9CA3AF),
                        size: 26,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── ERROR BANNER (inline, always visible) ──
                      if (_errorMessage != null)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.exclamationmark_triangle_fill,
                                color: Color(0xFFDC2626),
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFB91C1C),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _errorMessage = null),
                                child: const Icon(
                                  CupertinoIcons.clear_circled,
                                  color: Color(0xFFDC2626),
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // ── SECTION 1: ẢNH KHU VỰC CHUNG ──
                      _buildSectionTitle('📸 ẢNH KHU VỰC CHUNG (Tối đa 5 ảnh)'),
                      _buildMainPhotoUpload(),

                      const SizedBox(height: 32),
                      // ── SECTION 2: THIẾT BỊ BÊN TRONG ──
                      _buildSectionTitle(
                        '🚿 THIẾT BỊ BÊN TRONG (Dùng để chia tiền sửa chữa)',
                      ),
                      _buildEquipmentChips(),

                      const SizedBox(height: 32),
                      // ── SECTION 3: THÔNG TIN CƠ BẢN ──
                      _buildSectionTitle('📝 THÔNG TIN CƠ BẢN'),
                      _buildInput(
                        ctrl: _nameCtrl,
                        label: 'Tên định danh (VD: WC Tầng 1)',
                        icon: CupertinoIcons.tag,
                      ),
                      const SizedBox(height: 12),
                      _buildInput(
                        ctrl: _notesCtrl,
                        label: 'Ghi chú (Lịch dọn vệ sinh...)',
                        icon: CupertinoIcons.doc_text,
                      ),

                      const SizedBox(height: 32),
                      // ── SECTION 4: CÁCH TÍNH NƯỚC ──
                      _buildSectionTitle('💧 CÁCH TÍNH TIỀN NƯỚC'),
                      _buildWaterPricingSelector(),
                      const SizedBox(height: 10),
                      _buildWaterPricingHint(),

                      const SizedBox(height: 32),
                      // ── SECTION 5: CHỈ SỐ ĐỒNG HỒ BAN ĐẦU ──
                      _buildSectionTitle('⚡ CHỈ SỐ ĐỒNG HỒ BAN ĐẦU'),
                      if (_waterPricingType == 'PER_INDEX')
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildMeterSection(
                                'Số Điện (kWh)',
                                'ELECTRIC_METER',
                                _electricIndexCtrl,
                                '⚡',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMeterSection(
                                'Số Nước (m³)',
                                'WATER_METER',
                                _waterIndexCtrl,
                                '💧',
                              ),
                            ),
                          ],
                        )
                      else
                        _buildMeterSection(
                          'Số Điện (kWh)',
                          'ELECTRIC_METER',
                          _electricIndexCtrl,
                          '⚡',
                        ),

                      const SizedBox(height: 32),
                      // ── SECTION 6: PHÒNG ĐANG SỬ DỤNG (chỉ đọc) ──
                      _buildSectionTitle('🚪 PHÒNG ĐANG SỬ DỤNG'),
                      _buildAssignedRoomsReadOnly(),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),

              // Bottom fixed button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── ERROR BANNER always visible above the button ──
                    if (_errorMessage != null)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              CupertinoIcons.exclamationmark_triangle_fill,
                              color: Color(0xFFDC2626),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFB91C1C),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _errorMessage = null),
                              child: const Icon(
                                CupertinoIcons.clear_circled_solid,
                                color: Color(0xFFDC2626),
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _isSaving ? null : _save,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Stack(
                          children: [
                            // Upload progress fill
                            if (_isSaving && _uploadProgress >= 0)
                              Positioned.fill(
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: _uploadProgress.clamp(0.0, 1.0),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.25,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            Center(
                              child: _isSaving
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const CupertinoActivityIndicator(
                                          color: Colors.white,
                                          radius: 8,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _uploadProgress <= 0.0
                                              ? 'Đang nén ảnh...'
                                              : 'Đang lưu... ${(_uploadProgress * 100).toInt()}%',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    )
                                  : const Text(
                                      'Lưu & Áp dụng',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ],
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
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: Color(0xFF9CA3AF),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Chọn cách tính nước: theo công tơ (có chỉ số) hay theo đầu người (không cần).
  Widget _buildWaterPricingSelector() {
    Widget option(String value, String label, String desc, IconData icon) {
      final selected = _waterPricingType == value;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _waterPricingType = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF10B981).withValues(alpha: 0.08)
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? const Color(0xFF10B981)
                    : const Color(0xFFE5E7EB),
                width: selected ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: selected
                          ? const Color(0xFF059669)
                          : const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? const Color(0xFF047857)
                              : const Color(0xFF374151),
                        ),
                      ),
                    ),
                    if (selected)
                      const Icon(
                        CupertinoIcons.checkmark_alt_circle_fill,
                        size: 16,
                        color: Color(0xFF10B981),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        option(
          'PER_INDEX',
          'Theo công tơ',
          'Nhập chỉ số nước (m³)',
          CupertinoIcons.gauge,
        ),
        const SizedBox(width: 10),
        option(
          'PER_PERSON',
          'Theo đầu người',
          'Không cần công tơ',
          CupertinoIcons.person_2_fill,
        ),
      ],
    );
  }

  /// Giải thích hệ quả của cách tính nước đang chọn để người dùng hiểu rõ.
  Widget _buildWaterPricingHint() {
    final bool perIndex = _waterPricingType == 'PER_INDEX';
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: perIndex ? const Color(0xFFF0F9FF) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: perIndex ? const Color(0xFFBAE6FD) : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            perIndex
                ? CupertinoIcons.info_circle_fill
                : CupertinoIcons.person_2_fill,
            size: 15,
            color: perIndex ? const Color(0xFF0284C7) : const Color(0xFFB45309),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              perIndex
                  ? 'Khu vực này có đồng hồ riêng. Cần nhập chỉ số nước ban đầu để chốt số khi trả phòng.'
                  : 'Khu vực này không có đồng hồ. Tiền nước sẽ được chia theo số người ở, không cần nhập chỉ số.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: perIndex
                    ? const Color(0xFF075985)
                    : const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Icon(icon, size: 16, color: const Color(0xFF6B7280)),
              ),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: Color(0xFF111827),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableEquipment.entries.map((e) {
            final isSelected = _equipmentItems.contains(e.key);
            final eqKey = 'EQUIPMENT_${e.key}';
            final photoCount = isSelected
                ? ((_photoUrls[eqKey]?.length ?? 0) +
                      (_photoLocals[eqKey]?.length ?? 0))
                : 0;
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _equipmentItems.remove(e.key);
                  } else {
                    _equipmentItems.add(e.key);
                    _ensureEquipmentPhotoGroup(e.key);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF10B981)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(
                          CupertinoIcons.checkmark_alt,
                          size: 14,
                          color: Color(0xFF059669),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          e.value.$2,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    Text(
                      e.value.$1,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF047857)
                            : const Color(0xFF4B5563),
                      ),
                    ),
                    if (isSelected && photoCount > 0) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          '$photoCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        // Inline photo upload for selected equipment
        ..._availableEquipment.entries
            .where((e) => _equipmentItems.contains(e.key))
            .map(
              (e) => _buildEquipmentPhotoUpload(e.key, e.value.$1, e.value.$2),
            ),
      ],
    );
  }

  Widget _buildEquipmentPhotoUpload(String key, String label, String emoji) {
    final eqKey = 'EQUIPMENT_$key';
    _ensureEquipmentPhotoGroup(key);
    final urls = _photoUrls[eqKey]!;
    final locals = _photoLocals[eqKey]!;
    final total = urls.length + locals.length;

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBBF7D0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  'Ảnh $label',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF065F46),
                  ),
                ),
                const Spacer(),
                if (total < 2)
                  GestureDetector(
                    onTap: () => _pickPhotos(eqKey, max: 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Text(
                        '+ Ảnh',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (total == 0)
              GestureDetector(
                onTap: () => _pickPhotos(eqKey, max: 2),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFBBF7D0),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.camera_fill,
                        size: 16,
                        color: Color(0xFF10B981),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Chạm để thêm ảnh',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF065F46),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildThumbnailRow(eqKey, max: 2),
          ],
        ),
      ),
    );
  }

  /// Hiển thị (chỉ đọc) danh sách phòng đã được phân công dùng WC này ở Bước 3.
  /// Không cho sửa tại đây để tránh ghi đè phân công đã chốt.
  Widget _buildAssignedRoomsReadOnly() {
    final rooms = _assignedRooms();
    if (rooms.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Row(
          children: [
            Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              size: 15,
              color: Color(0xFFB45309),
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Chưa có phòng nào được gán. Quay lại Bước 3 để chọn phòng dùng WC này.',
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.35,
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              CupertinoIcons.info_circle_fill,
              size: 14,
              color: Color(0xFF0284C7),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${rooms.length} phòng được phân công ở Bước 3 (không sửa tại đây).',
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF075985),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: rooms.map((r) {
            final code = '${r['roomCode'] ?? r['roomName'] ?? r['id']}';
            final floor = (r['floor'] as num?)?.toInt();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.bed_double_fill,
                    size: 12,
                    color: Color(0xFF059669),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    code,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF047857),
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (floor != null) ...[
                    const SizedBox(width: 5),
                    Text(
                      '· T$floor',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Danh sách phòng đang gán vào WC này — dựa trên `sharedFacilities` của
  /// từng phòng (nguồn dữ liệu chuẩn từ Bước 3), fallback sang `rooms`.
  List<Map<String, dynamic>> _assignedRooms() {
    // BUGFIX (data): `id` có thể là String/null → tránh TypeError.
    final rawFacilityId = widget.facility['id'];
    final int facilityId = rawFacilityId is num
        ? rawFacilityId.toInt()
        : int.tryParse(rawFacilityId?.toString() ?? '') ?? 0;
    final result = <Map<String, dynamic>>[];
    for (final r in widget.allRooms) {
      final shared = r['sharedFacilities'];
      if (shared is List &&
          shared.any((f) => f is Map && f['id'] == facilityId)) {
        result.add(r);
      }
    }
    if (result.isNotEmpty) return result;

    // Fallback: dùng danh sách rooms trả kèm facility.
    final rooms = widget.facility['rooms'];
    if (rooms is List) {
      return rooms
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return result;
  }

  // ─── Đồng hồ điện / nước ───
  Widget _buildMeterSection(
    String label,
    String photoGroup,
    TextEditingController ctrl,
    String iconText,
  ) {
    _ensureEquipmentPhotoGroup(photoGroup);
    final eqKey = 'EQUIPMENT_$photoGroup';
    final urls = _photoUrls[eqKey]!;
    final locals = _photoLocals[eqKey]!;
    final total = urls.length + locals.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(iconText, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF111827),
            ),
            decoration: const InputDecoration(
              hintText: 'VD: 1500',
              hintStyle: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F8FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFC7E2FF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Ảnh đồng hồ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0284C7),
                      ),
                    ),
                    const Spacer(),
                    if (total < 2)
                      GestureDetector(
                        onTap: () => _pickPhotos(eqKey, max: 2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0EA5E9),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Text(
                            '+ Ảnh',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (total == 0)
                  GestureDetector(
                    onTap: () => _pickPhotos(eqKey, max: 2),
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFC7E2FF),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            CupertinoIcons.camera_fill,
                            size: 16,
                            color: Color(0xFF0EA5E9),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Chạm để tải ảnh',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF0284C7),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  _buildThumbnailRow(eqKey, max: 2),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainPhotoUpload() {
    final urls = _photoUrls['MAIN']!;
    final locals = _photoLocals['MAIN']!;
    final total = urls.length + locals.length;
    final bool canAdd = total < 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (total > 0)
          _buildThumbnailRow('MAIN', max: 5)
        else
          GestureDetector(
            onTap: () => _pickPhotos('MAIN', max: 5),
            child: Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFD1D5DB),
                  style: BorderStyle.solid,
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.camera_fill,
                    color: Color(0xFF9CA3AF),
                    size: 28,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Chạm để tải ảnh lên',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (total > 0 && canAdd) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _pickPhotos('MAIN', max: 5),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.add, size: 16, color: Color(0xFF4B5563)),
                  SizedBox(width: 6),
                  Text(
                    'Thêm ảnh khác',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildThumbnailRow(String group, {required int max}) {
    final urls = _photoUrls[group]!;
    final locals = _photoLocals[group]!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...urls.asMap().entries.map(
            (e) => _buildThumb(e.value, false, group, e.key),
          ),
          ...locals.asMap().entries.map(
            (e) => _buildThumb(e.value.path, true, group, e.key),
          ),
        ],
      ),
    );
  }

  Widget _buildThumb(String path, bool isLocal, String group, int index) {
    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isLocal
                  ? (kIsWeb
                        ? Image.network(
                            path,
                            fit: BoxFit.cover,
                            width: 60,
                            height: 60,
                          )
                        : Image.file(
                            File(path),
                            fit: BoxFit.cover,
                            width: 60,
                            height: 60,
                          ))
                  : (path.startsWith('http') || path.startsWith('data:image')
                        ? Image.network(
                            path,
                            fit: BoxFit.cover,
                            width: 60,
                            height: 60,
                            errorBuilder: (c, e, s) => const Icon(
                              CupertinoIcons.exclamationmark_triangle,
                              size: 24,
                              color: Colors.red,
                            ),
                          )
                        : Image.memory(
                            base64Decode(path),
                            fit: BoxFit.cover,
                            width: 60,
                            height: 60,
                            errorBuilder: (c, e, s) => const Icon(
                              CupertinoIcons.exclamationmark_triangle,
                              size: 24,
                              color: Colors.red,
                            ),
                          )),
            ),
          ),
          Positioned(
            top: -4,
            right: -4,
            child: IconButton(
              icon: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.clear_circled_solid,
                  color: Colors.red,
                  size: 20,
                ),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                setState(() {
                  if (isLocal) {
                    _photoLocals[group]!.removeAt(index);
                  } else {
                    _photoUrls[group]!.removeAt(index);
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickPhotos(String group, {required int max}) async {
    final current = _photoUrls[group]!.length + _photoLocals[group]!.length;
    if (current >= max) {
      ToastUtils.show(context, 'Đã đạt giới hạn $max ảnh', isError: true);
      return;
    }
    try {
      unawaited(
        ImagePickerUtils.showPicker(
          context: context,
          limit: max - current,
          onPicked: (picked) {
            if (picked.isNotEmpty && mounted) {
              setState(() {
                _photoLocals[group]!.addAll(picked);
              });
            }
          },
        ),
      );
    } catch (e) {
      debugPrint('Error picking images: $e');
      if (mounted) {
        ToastUtils.show(
          context,
          'Không thể chọn ảnh. Vui lòng thử lại.',
          isError: true,
        );
      }
    }
  }
}
