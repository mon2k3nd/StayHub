import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/components/bounce_click.dart';
import '../../../search/domain/models/room_search_filter.dart';
import '../../../search/application/room_search_notifier.dart';
import 'glass_dropdown_overlay.dart';

// --- Price Dropdown Overlay ---
class PriceDropdownOverlay extends StatefulWidget {
  final Offset position;
  final Size size;
  final RoomSearchFilter currentFilter;
  final Function(RoomSearchFilter) onApply;
  final VoidCallback onDismiss;

  const PriceDropdownOverlay({
    super.key,
    required this.position,
    required this.size,
    required this.currentFilter,
    required this.onApply,
    required this.onDismiss,
  });

  @override
  State<PriceDropdownOverlay> createState() => _PriceDropdownOverlayState();
}

class _PriceDropdownOverlayState extends State<PriceDropdownOverlay> {
  late final TextEditingController _minPriceCtrl;
  late final TextEditingController _maxPriceCtrl;
  late RoomSearchFilter _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.currentFilter;
    _minPriceCtrl = TextEditingController(
      text: _draft.minPrice != null ? _draft.minPrice!.toInt().toString() : '',
    );
    _maxPriceCtrl = TextEditingController(
      text: _draft.maxPrice != null ? _draft.maxPrice!.toInt().toString() : '',
    );
  }

  @override
  void dispose() {
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    final minPrice = double.tryParse(_minPriceCtrl.text.replaceAll(',', ''));
    final maxPrice = double.tryParse(_maxPriceCtrl.text.replaceAll(',', ''));
    final result = _draft.copyWith(
      minPrice: minPrice,
      maxPrice: maxPrice,
      clearMinPrice: minPrice == null,
      clearMaxPrice: maxPrice == null,
    );
    widget.onApply(result);
  }

  void _setPreset(double? min, double? max) {
    _minPriceCtrl.text = min != null ? min.toInt().toString() : '';
    _maxPriceCtrl.text = max != null ? max.toInt().toString() : '';
    setState(() {
      _draft = _draft.copyWith(
        minPrice: min,
        maxPrice: max,
        clearMinPrice: min == null,
        clearMaxPrice: max == null,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlassDropdownOverlay(
      position: widget.position,
      size: widget.size,
      onDismiss: widget.onDismiss,
      width: 340,
      maxHeight: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Khoảng giá (VND/tháng)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1, color: Colors.white24),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Flexible(child: _buildNumField(_minPriceCtrl, 'Tối thiểu')),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        '-',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.kTextMuted,
                        ),
                      ),
                    ),
                    Flexible(child: _buildNumField(_maxPriceCtrl, 'Tối đa')),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildPresetPill('Dưới 3tr', null, 3000000),
                    _buildPresetPill('3 - 5tr', 3000000, 5000000),
                    _buildPresetPill('5 - 10tr', 5000000, 10000000),
                    _buildPresetPill('Trên 10tr', 10000000, null),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white24),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildPresetPill(String label, double? min, double? max) {
    final active = _draft.minPrice == min && _draft.maxPrice == max;
    return BounceClick(
      onPressed: () => _setPreset(min, max),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.kBrand : AppTheme.kSurface2Light,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active
                ? AppTheme.kBrand
                : AppTheme.kBorderColor.withValues(alpha: 0.6),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? Colors.white : AppTheme.kTextPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildNumField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppTheme.kTextMuted),
        filled: true,
        fillColor: AppTheme.kSurface2Light,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.kBorderColor.withValues(alpha: 0.6),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.kBorderColor.withValues(alpha: 0.6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.kBrand, width: 1.6),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => _setPreset(null, null),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: _apply,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }
}

// --- Area Dropdown Overlay ---
class AreaDropdownOverlay extends StatefulWidget {
  final Offset position;
  final Size size;
  final RoomSearchFilter currentFilter;
  final Function(RoomSearchFilter) onApply;
  final VoidCallback onDismiss;

  const AreaDropdownOverlay({
    super.key,
    required this.position,
    required this.size,
    required this.currentFilter,
    required this.onApply,
    required this.onDismiss,
  });

  @override
  State<AreaDropdownOverlay> createState() => _AreaDropdownOverlayState();
}

class _AreaDropdownOverlayState extends State<AreaDropdownOverlay> {
  late final TextEditingController _minAreaCtrl;
  late final TextEditingController _maxAreaCtrl;
  late RoomSearchFilter _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.currentFilter;
    _minAreaCtrl = TextEditingController(
      text: _draft.minArea != null ? _draft.minArea!.toInt().toString() : '',
    );
    _maxAreaCtrl = TextEditingController(
      text: _draft.maxArea != null ? _draft.maxArea!.toInt().toString() : '',
    );
  }

  @override
  void dispose() {
    _minAreaCtrl.dispose();
    _maxAreaCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    final minArea = double.tryParse(_minAreaCtrl.text.replaceAll(',', ''));
    final maxArea = double.tryParse(_maxAreaCtrl.text.replaceAll(',', ''));
    final result = _draft.copyWith(
      minArea: minArea,
      maxArea: maxArea,
      clearMinArea: minArea == null,
      clearMaxArea: maxArea == null,
    );
    widget.onApply(result);
  }

  void _clear() {
    // BUGFIX (logic): trước đây chỉ xoá text của 2 ô nhập nhưng KHÔNG cập nhật
    // `_draft`. Bấm "Xóa" rồi "Áp dụng" sẽ gửi lại đúng min/maxArea CŨ → thao
    // tác xoá hoàn toàn vô tác dụng. Nay xoá cả state draft (đồng bộ với
    // PriceDropdownOverlay dùng _setPreset(null, null)).
    _minAreaCtrl.clear();
    _maxAreaCtrl.clear();
    setState(() {
      _draft = _draft.copyWith(
        minArea: null,
        maxArea: null,
        clearMinArea: true,
        clearMaxArea: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlassDropdownOverlay(
      position: widget.position,
      size: widget.size,
      onDismiss: widget.onDismiss,
      width: 340,
      maxHeight: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Diện tích (m²)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1, color: Colors.white24),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Flexible(child: _buildNumField(_minAreaCtrl, 'Tối thiểu')),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '-',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.kTextMuted,
                      ),
                    ),
                  ),
                  Flexible(child: _buildNumField(_maxAreaCtrl, 'Tối đa')),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.white24),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildNumField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppTheme.kTextMuted),
        filled: true,
        fillColor: AppTheme.kSurface2Light,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.kBorderColor.withValues(alpha: 0.6),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppTheme.kBorderColor.withValues(alpha: 0.6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.kBrand, width: 1.6),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: _clear,
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: _apply,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }
}

// --- Amenities Dropdown Overlay ---
class AmenitiesDropdownOverlay extends ConsumerStatefulWidget {
  final Offset position;
  final Size size;
  final RoomSearchFilter currentFilter;
  final Function(RoomSearchFilter) onApply;
  final VoidCallback onDismiss;

  const AmenitiesDropdownOverlay({
    super.key,
    required this.position,
    required this.size,
    required this.currentFilter,
    required this.onApply,
    required this.onDismiss,
  });

  @override
  ConsumerState<AmenitiesDropdownOverlay> createState() =>
      _AmenitiesDropdownOverlayState();
}

class _AmenitiesDropdownOverlayState
    extends ConsumerState<AmenitiesDropdownOverlay> {
  late RoomSearchFilter _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.currentFilter;
  }

  void _apply() {
    widget.onApply(_draft);
  }

  void _clear() {
    setState(() {
      _draft = _draft.copyWith(amenities: const []);
    });
  }

  @override
  Widget build(BuildContext context) {
    final meta = ref.watch(roomFilterMetadataProvider);
    final rawAmenities = meta.value?['amenities'];

    // BUGFIX: danh sách mã tiện ích trước đây dùng các mã "chuẩn hoá" KHÔNG
    // tồn tại trong cột `furniture` thật (AIR_CONDITIONER/WASHING_MACHINE/
    // FRIDGE/KITCHEN/FURNISHED/GYM/POOL/PETS_ALLOWED). Backend lọc `furniture`
    // bằng LIKE trên mã hoa → chọn các chip này KHÔNG BAO GIỜ khớp phòng nào
    // (kết quả rỗng). Nay dùng đúng MÃ mà luồng tạo phòng ghi vào DB
    // (AC/TU_LANH/MAY_GIAT/GIUONG/TU_QUAN_AO/BAN_GHE/SOFA/TU_BEP/BEP_TU/
    // LO_VI_SONG/HUT_MUI/BINH_NONG_LANH/VOI_SEN/BET) + vài mã tiện ích chung
    // có thật (WIFI/PARKING/ELEVATOR/SECURITY/CAMERA/BALCONY/WINDOW/TV).
    Set<String> amenitiesSet = {
      'AC',
      'TU_LANH',
      'MAY_GIAT',
      'GIUONG',
      'TU_QUAN_AO',
      'BAN_GHE',
      'SOFA',
      'TU_BEP',
      'BEP_TU',
      'LO_VI_SONG',
      'HUT_MUI',
      'BINH_NONG_LANH',
      'VOI_SEN',
      'BET',
      'WIFI',
      'PARKING',
      'ELEVATOR',
      'SECURITY',
      'CAMERA',
      'BALCONY',
      'WINDOW',
      'TV',
    };

    if (rawAmenities is List) {
      amenitiesSet.addAll(rawAmenities.map((e) => e.toString()));
    }

    List<String> amenities = amenitiesSet.toList();

    return GlassDropdownOverlay(
      position: widget.position,
      size: widget.size,
      onDismiss: widget.onDismiss,
      width: 360,
      maxHeight: 380,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Tiện ích',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1, color: Colors.white24),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: amenities.map((a) {
                    final active = _draft.amenities.contains(a);
                    return BounceClick(
                      onPressed: () {
                        setState(() {
                          final next = [..._draft.amenities];
                          if (active) {
                            next.remove(a);
                          } else {
                            next.add(a);
                          }
                          _draft = _draft.copyWith(amenities: next);
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? AppTheme.kBrand
                              : AppTheme.kSurface2Light,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: active
                                ? AppTheme.kBrand
                                : AppTheme.kBorderColor.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Text(
                          _getAmenityLabel(a),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: active
                                ? Colors.white
                                : AppTheme.kTextPrimary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white24),
          _buildFooter(),
        ],
      ),
    );
  }

  String _getAmenityLabel(String code) {
    // BUGFIX: nhãn phải khớp MÃ THẬT trong cột `furniture` (xem amenitiesSet).
    // Giữ thêm vài alias legacy để dữ liệu cũ vẫn có nhãn.
    switch (code.toUpperCase()) {
      // ── Mã thật do luồng tạo phòng ghi ──
      case 'AC':
        return 'Điều hoà';
      case 'TU_LANH':
        return 'Tủ lạnh';
      case 'MAY_GIAT':
        return 'Máy giặt';
      case 'GIUONG':
        return 'Giường đệm';
      case 'TU_QUAN_AO':
        return 'Tủ quần áo';
      case 'BAN_GHE':
        return 'Bàn ghế';
      case 'SOFA':
        return 'Sofa';
      case 'TU_BEP':
        return 'Tủ bếp';
      case 'BEP_TU':
        return 'Bếp từ/gas';
      case 'LO_VI_SONG':
        return 'Lò vi sóng';
      case 'HUT_MUI':
        return 'Hút mùi';
      case 'BINH_NONG_LANH':
        return 'Bình nóng lạnh';
      case 'VOI_SEN':
        return 'Vòi sen';
      case 'BET':
        return 'Bệt xịt';
      // ── Tiện ích chung ──
      case 'WIFI':
        return 'Wi-Fi miễn phí';
      case 'PARKING':
        return 'Chỗ để xe';
      case 'SECURITY':
        return 'Bảo vệ 24/7';
      case 'ELEVATOR':
        return 'Thang máy';
      case 'CAMERA':
        return 'Camera';
      case 'BALCONY':
        return 'Ban công';
      case 'WINDOW':
        return 'Cửa sổ';
      case 'TV':
        return 'TV';
      // ── Alias/legacy ──
      case 'AIR_CONDITIONER':
        return 'Điều hoà';
      case 'WASHING_MACHINE':
        return 'Máy giặt';
      case 'FRIDGE':
        return 'Tủ lạnh';
      case 'KITCHEN':
        return 'Khu vực bếp';
      default:
        return code;
    }
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: _clear,
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: _apply,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }
}
