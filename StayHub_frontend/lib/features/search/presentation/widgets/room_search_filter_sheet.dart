import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/components/bounce_click.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/room_type_codes.dart';
import '../../application/room_search_notifier.dart';
import '../../domain/models/room_search_filter.dart';

/// Bottom sheet lọc phòng — server-driven, đồng bộ 1-1 với backend
/// (`GET /v1/rooms/public/search`).
///
/// Trả về [RoomSearchFilter] mới qua `Navigator.pop`. Toàn bộ tiêu chí đều
/// được backend xử lý nên kết quả luôn chính xác trên toàn bộ dữ liệu.
class RoomSearchFilterSheet extends ConsumerStatefulWidget {
  final RoomSearchFilter initial;

  /// Hồ sơ trường lọc phù hợp với danh mục đang chọn. Quyết định section nào
  /// được hiển thị (vd: "Phòng trọ" không hỏi số phòng ngủ / số giường).
  final RoomFilterProfile profile;
  final String? focusedSection;

  const RoomSearchFilterSheet({
    super.key,
    required this.initial,
    this.profile = RoomFilterProfile.all,
    this.focusedSection,
  });

  /// Mở sheet và trả về bộ lọc mới (hoặc null nếu đóng không áp dụng).
  static Future<RoomSearchFilter?> show(
    BuildContext context,
    RoomSearchFilter initial, {
    RoomFilterProfile profile = RoomFilterProfile.all,
    String? focusedSection,
  }) {
    return showModalBottomSheet<RoomSearchFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => RoomSearchFilterSheet(
        initial: initial,
        profile: profile,
        focusedSection: focusedSection,
      ),
    );
  }

  @override
  ConsumerState<RoomSearchFilterSheet> createState() =>
      _RoomSearchFilterSheetState();
}

class _RoomSearchFilterSheetState extends ConsumerState<RoomSearchFilterSheet> {
  late RoomSearchFilter _draft;

  late final TextEditingController _minPriceCtrl;
  late final TextEditingController _maxPriceCtrl;
  late final TextEditingController _minAreaCtrl;
  late final TextEditingController _maxAreaCtrl;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
    _minPriceCtrl = TextEditingController(
      text: _draft.minPrice != null ? _draft.minPrice!.toInt().toString() : '',
    );
    _maxPriceCtrl = TextEditingController(
      text: _draft.maxPrice != null ? _draft.maxPrice!.toInt().toString() : '',
    );
    _minAreaCtrl = TextEditingController(
      text: _draft.minArea != null ? _draft.minArea!.toInt().toString() : '',
    );
    _maxAreaCtrl = TextEditingController(
      text: _draft.maxArea != null ? _draft.maxArea!.toInt().toString() : '',
    );
  }

  @override
  void dispose() {
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    _minAreaCtrl.dispose();
    _maxAreaCtrl.dispose();
    super.dispose();
  }

  void _set(RoomSearchFilter next) => setState(() => _draft = next);

  void _apply() {
    var minPrice = double.tryParse(_minPriceCtrl.text.replaceAll(',', ''));
    var maxPrice = double.tryParse(_maxPriceCtrl.text.replaceAll(',', ''));
    var minArea = double.tryParse(_minAreaCtrl.text.replaceAll(',', ''));
    var maxArea = double.tryParse(_maxAreaCtrl.text.replaceAll(',', ''));

    // ── Chuẩn hoá khoảng min/max (999 tình huống thực tế) ────────────────────
    // Người dùng rất hay nhập ngược (min > max) hoặc chỉ nhập 1 đầu. Nếu đẩy
    // thẳng lên backend, điều kiện `price >= min AND price <= max` với min > max
    // sẽ LUÔN rỗng → app hiện "không tìm thấy phòng" mà không giải thích gì.
    // Ta tự hoán đổi 2 đầu để ý định người dùng luôn được tôn trọng.
    if (minPrice != null && maxPrice != null && minPrice > maxPrice) {
      final t = minPrice;
      minPrice = maxPrice;
      maxPrice = t;
    }
    if (minArea != null && maxArea != null && minArea > maxArea) {
      final t = minArea;
      minArea = maxArea;
      maxArea = t;
    }

    final result = _draft.copyWith(
      minPrice: minPrice,
      maxPrice: maxPrice,
      minArea: minArea,
      maxArea: maxArea,
      clearMinPrice: minPrice == null,
      clearMaxPrice: maxPrice == null,
      clearMinArea: minArea == null,
      clearMaxArea: maxArea == null,
    );
    Navigator.pop(context, result);
  }

  void _reset() {
    _minPriceCtrl.clear();
    _maxPriceCtrl.clear();
    _minAreaCtrl.clear();
    _maxAreaCtrl.clear();
    _set(RoomSearchFilter.empty.copyWith(keyword: _draft.keyword));
  }

  @override
  Widget build(BuildContext context) {
    final meta = ref.watch(roomFilterMetadataProvider);
    final roomTypes = _stringList(meta.value?['roomTypes']);
    final amenities = _stringList(meta.value?['amenities']);
    // BUGFIX: các mã "chuẩn" trước đây (AIR_CONDITIONER, WASHING_MACHINE,
    // FURNISHED, PETS_ALLOWED…) KHÔNG tồn tại trong cột `furniture` thật.
    // BUGFIX 2: ngay cả bộ mã "đã sửa" trước đó (WASHER/FRIDGE/WARDROBE/BED/
    // KITCHEN/ELEVATOR/BALCONY) cũng SAI — luồng tạo phòng
    // (`room_config_bottom_sheet_state._buildFurnitureChips`) chỉ ghi các mã:
    // AC, TU_LANH, MAY_GIAT, GIUONG, TU_QUAN_AO, BAN_GHE, SOFA, TU_BEP, BEP_TU,
    // LO_VI_SONG, HUT_MUI, BINH_NONG_LANH, VOI_SEN, BET. Vì backend lọc bằng
    // LIKE trên mã thô, chọn các chip không tồn tại sẽ KHÔNG BAO GIỜ khớp phòng
    // nào. Nay dùng ĐÚNG tập mã mà luồng tạo phòng thực sự ghi.
    final standardAmenities = {
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
    };
    amenities.addAll(standardAmenities.where((a) => !amenities.contains(a)));
    final provinces = _stringList(meta.value?['provinces']);
    final directions = _stringList(meta.value?['directions']);
    // Gợi ý khoảng giá/diện tích thật từ DB (thay vì hard-code).
    final metaMinPrice = _asNum(meta.value?['minPrice']);
    final metaMaxPrice = _asNum(meta.value?['maxPrice']);
    final metaMinArea = _asNum(meta.value?['minArea']);
    final metaMaxArea = _asNum(meta.value?['maxArea']);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: widget.focusedSection == null
              ? MediaQuery.of(context).size.height * 0.92
              : null,
          decoration: BoxDecoration(
            color: AppTheme.kSurface1Light.withValues(alpha: 0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.kBorderColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 16),
              _buildHeader(),
              const SizedBox(height: 8),
              Divider(
                color: AppTheme.kBorderColor.withValues(alpha: 0.4),
                height: 1,
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  children: [
                    if ((widget.focusedSection == null ||
                            widget.focusedSection == 'Loại phòng') &&
                        widget.profile.usageType) ...[
                      _section('Hình thức sử dụng'),
                      _chipRow(
                        options: const [
                          _Opt('WHOLE', '🏠 Toàn bộ nhà'),
                          _Opt('SHARED', '🛋️ Ở ghép'),
                          _Opt('PRIVATE', '🛏️ Phòng riêng'),
                        ],
                        selected: _draft.usageType,
                        onSelect: (v) => _set(
                          _draft.copyWith(
                            usageType: v,
                            clearUsageType: v == null,
                          ),
                        ),
                      ),
                    ],
                    if ((widget.focusedSection == null ||
                            widget.focusedSection == 'Khu vực') &&
                        provinces.isNotEmpty) ...[
                      _section('Khu vực'),
                      _multiChips(
                        options: provinces,
                        selected:
                            _draft.province != null &&
                                _draft.province!.isNotEmpty
                            ? [_draft.province!]
                            : const [],
                        labelOf: (v) => v,
                        onToggle: (v) {
                          final active = _draft.province == v;
                          _set(
                            _draft.copyWith(
                              province: active ? null : v,
                              clearProvince: active,
                            ),
                          );
                        },
                      ),
                    ],
                    if (widget.focusedSection == null ||
                        widget.focusedSection == 'Khoảng giá') ...[
                      _section('Khoảng giá (VND/tháng)'),
                      _rangeInputs(
                        minCtrl: _minPriceCtrl,
                        maxCtrl: _maxPriceCtrl,
                        hintMin: metaMinPrice != null
                            ? _shortMoney(metaMinPrice)
                            : 'Tối thiểu',
                        hintMax: metaMaxPrice != null
                            ? _shortMoney(metaMaxPrice)
                            : 'Tối đa',
                      ),
                      const SizedBox(height: 12),
                      _quickPriceChips(),
                    ],
                    if (widget.focusedSection == null ||
                        widget.focusedSection == 'Diện tích') ...[
                      _section('Diện tích (m²)'),
                      _rangeInputs(
                        minCtrl: _minAreaCtrl,
                        maxCtrl: _maxAreaCtrl,
                        hintMin: metaMinArea != null
                            ? '${metaMinArea.toInt()}'
                            : 'Tối thiểu',
                        hintMax: metaMaxArea != null
                            ? '${metaMaxArea.toInt()}'
                            : 'Tối đa',
                      ),
                    ],
                    if ((widget.focusedSection == null) &&
                        widget.profile.bedrooms) ...[
                      _section('Số phòng ngủ'),
                      _countChips(
                        value: _draft.bedrooms,
                        onSelect: (v) => _set(
                          _draft.copyWith(
                            bedrooms: v,
                            clearBedrooms: v == null,
                          ),
                        ),
                      ),
                    ],
                    if ((widget.focusedSection == null) &&
                        widget.profile.beds) ...[
                      _section('Số giường'),
                      _countChips(
                        value: _draft.beds,
                        onSelect: (v) => _set(
                          _draft.copyWith(beds: v, clearBeds: v == null),
                        ),
                      ),
                    ],
                    if ((widget.focusedSection == null) &&
                        widget.profile.bathrooms) ...[
                      _section('Số phòng tắm / WC'),
                      _countChips(
                        value: _draft.bathrooms,
                        onSelect: (v) => _set(
                          _draft.copyWith(
                            bathrooms: v,
                            clearBathrooms: v == null,
                          ),
                        ),
                      ),
                    ],
                    if (widget.profile.maxGuests) ...[
                      _section('Số người tối đa'),
                      _countChips(
                        value: _draft.maxGuests,
                        onSelect: (v) => _set(
                          _draft.copyWith(
                            maxGuests: v,
                            clearMaxGuests: v == null,
                          ),
                        ),
                      ),
                    ],
                    if ((widget.focusedSection == null ||
                            widget.focusedSection == 'Loại phòng') &&
                        roomTypes.isNotEmpty) ...[
                      _section('Loại phòng'),
                      _multiChips(
                        options: roomTypes,
                        selected: _draft.roomTypes,
                        labelOf: _roomTypeLabel,
                        onToggle: (v) {
                          final next = [..._draft.roomTypes];
                          next.contains(v) ? next.remove(v) : next.add(v);
                          _set(_draft.copyWith(roomTypes: next));
                        },
                      ),
                    ],
                    if (widget.profile.direction) ...[
                      _section('Hướng phòng'),
                      _chipRow(
                        options:
                            (directions.isNotEmpty
                                    ? directions
                                    : const ['DONG', 'TAY', 'NAM', 'BAC'])
                                .map((d) => _Opt(d, _directionLabel(d)))
                                .toList(),
                        selected: _draft.direction,
                        onSelect: (v) => _set(
                          _draft.copyWith(
                            direction: v,
                            clearDirection: v == null,
                          ),
                        ),
                      ),
                    ],
                    if ((widget.focusedSection == null ||
                            widget.focusedSection == 'Tiện ích') &&
                        amenities.isNotEmpty) ...[
                      _section('Tiện ích'),
                      _multiChips(
                        options: amenities,
                        selected: _draft.amenities,
                        labelOf: (v) {
                          // BUGFIX: nhãn phải khớp MÃ THẬT mà luồng tạo phòng
                          // ghi vào cột `furniture` (AC/TU_LANH/MAY_GIAT/GIUONG/
                          // TU_QUAN_AO/BAN_GHE/SOFA/TU_BEP/BEP_TU/LO_VI_SONG/
                          // HUT_MUI/BINH_NONG_LANH/VOI_SEN/BET), không phải các
                          // mã "chuẩn hoá" cũ (AIR_CONDITIONER/WASHER/FRIDGE…).
                          switch (v) {
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
                            default:
                              return _amenityLabel(v);
                          }
                        },
                        onToggle: (v) {
                          final next = [..._draft.amenities];
                          next.contains(v) ? next.remove(v) : next.add(v);
                          _set(_draft.copyWith(amenities: next));
                        },
                      ),
                    ],
                    if (widget.profile.features) ...[
                      _section('Đặc điểm'),
                      _featureToggles(),
                    ],
                    _section('Sắp xếp theo'),
                    _sortChips(),
                  ],
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header / Footer ────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final title = widget.focusedSection ?? 'Bộ lọc';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: BounceClick(
              onPressed: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.kSurface2Light,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.kBorderColor.withValues(alpha: 0.5),
                  ),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: AppTheme.kTextPrimary,
                ),
              ),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.kTextPrimary,
              letterSpacing: -0.3,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: BounceClick(
              onPressed: _reset,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Text(
                  'Đặt lại',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.kBrand,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppTheme.kSurface1Light,
        border: Border(
          top: BorderSide(color: AppTheme.kBorderColor.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        children: [
          Flexible(
            child: BounceClick(
              onPressed: _reset,
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.kSurface2Light,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.kBorderColor.withValues(alpha: 0.6),
                  ),
                ),
                child: const Text(
                  'Xoá bộ lọc',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.kTextPrimary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            flex: 2,
            child: BounceClick(
              onPressed: _apply,
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.kBrandLight, AppTheme.kBrand],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.kPremiumShadowLight,
                ),
                child: Text(
                  _draft.activeCount > 0
                      ? 'Áp dụng (${_draft.activeCount})'
                      : 'Áp dụng',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sections ───────────────────────────────────────────────────────────────
  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppTheme.kTextPrimary,
        letterSpacing: -0.2,
      ),
    ),
  );

  Widget _chipRow({
    required List<_Opt> options,
    required String? selected,
    required ValueChanged<String?> onSelect,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((o) {
        final active = selected == o.value;
        return _pill(
          label: o.label,
          active: active,
          onTap: () => onSelect(active ? null : o.value),
        );
      }).toList(),
    );
  }

  Widget _multiChips({
    required List<String> options,
    required List<String> selected,
    required String Function(String) labelOf,
    required ValueChanged<String> onToggle,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((o) {
        final active = selected.contains(o);
        return _pill(
          label: labelOf(o),
          active: active,
          onTap: () => onToggle(o),
        );
      }).toList(),
    );
  }

  /// Hàng chip số lượng dùng chung cho phòng ngủ / giường / WC / số người.
  /// `null` = "Bất kỳ", `5` = "5+" (backend hiểu là >= 5).
  Widget _countChips({
    required int? value,
    required ValueChanged<int?> onSelect,
  }) {
    final values = <int?>[null, 1, 2, 3, 4, 5];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: values.map((v) {
        final active = value == v;
        final label = v == null ? 'Bất kỳ' : (v == 5 ? '5+' : '$v');
        return _pill(
          label: label,
          active: active,
          onTap: () => onSelect(active ? null : v),
        );
      }).toList(),
    );
  }

  Widget _quickPriceChips() {
    const presets = <String, (double?, double?)>{
      'Dưới 3tr': (null, 3000000),
      '3 - 5tr': (3000000, 5000000),
      '5 - 10tr': (5000000, 10000000),
      'Trên 10tr': (10000000, null),
    };
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: presets.entries.map((e) {
        final active =
            _draft.minPrice == e.value.$1 && _draft.maxPrice == e.value.$2;
        return _pill(
          label: e.key,
          active: active,
          onTap: () {
            _minPriceCtrl.text = e.value.$1 != null
                ? e.value.$1!.toInt().toString()
                : '';
            _maxPriceCtrl.text = e.value.$2 != null
                ? e.value.$2!.toInt().toString()
                : '';
            _set(
              _draft.copyWith(
                minPrice: e.value.$1,
                maxPrice: e.value.$2,
                clearMinPrice: e.value.$1 == null,
                clearMaxPrice: e.value.$2 == null,
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _featureToggles() {
    return Column(
      children: [
        _toggleTile(
          icon: Icons.window_rounded,
          label: 'Có cửa sổ',
          value: _draft.hasWindow,
          onChanged: (v) => _set(_draft.copyWith(hasWindow: v)),
        ),
        _toggleTile(
          icon: Icons.balcony_rounded,
          label: 'Có ban công',
          value: _draft.hasBalcony,
          onChanged: (v) => _set(_draft.copyWith(hasBalcony: v)),
        ),
        _toggleTile(
          icon: Icons.bathtub_rounded,
          label: 'WC riêng',
          value: _draft.privateBathroom,
          onChanged: (v) => _set(_draft.copyWith(privateBathroom: v)),
        ),
        _toggleTile(
          icon: Icons.local_offer_rounded,
          label: 'Đang có khuyến mãi',
          value: _draft.onlyPromotion,
          onChanged: (v) => _set(_draft.copyWith(onlyPromotion: v)),
        ),
      ],
    );
  }

  Widget _sortChips() {
    const sorts = <String, String>{
      'newest': 'Mới nhất',
      'price_asc': 'Giá thấp → cao',
      'price_desc': 'Giá cao → thấp',
      'area_asc': 'Diện tích nhỏ → lớn',
      'area_desc': 'Diện tích lớn → nhỏ',
    };
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: sorts.entries.map((e) {
        return _pill(
          label: e.value,
          active: _draft.sortBy == e.key,
          onTap: () => _set(_draft.copyWith(sortBy: e.key)),
        );
      }).toList(),
    );
  }

  // ── Primitives ─────────────────────────────────────────────────────────────
  Widget _pill({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return BounceClick(
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: active ? AppTheme.kBrand : AppTheme.kSurface2Light,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active
                ? AppTheme.kBrand
                : AppTheme.kBorderColor.withValues(alpha: 0.6),
          ),
          boxShadow: active ? AppTheme.kPremiumShadowLight : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active ? Colors.white : AppTheme.kTextPrimary,
          ),
        ),
      ),
    );
  }

  Widget _rangeInputs({
    required TextEditingController minCtrl,
    required TextEditingController maxCtrl,
    required String hintMin,
    required String hintMax,
  }) {
    return Row(
      children: [
        Flexible(child: _numField(minCtrl, hintMin)),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '-',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.kTextMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Flexible(child: _numField(maxCtrl, hintMax)),
      ],
    );
  }

  Widget _numField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppTheme.kTextPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppTheme.kTextMuted,
        ),
        filled: true,
        fillColor: AppTheme.kSurface2Light,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppTheme.kBorderColor.withValues(alpha: 0.6),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppTheme.kBorderColor.withValues(alpha: 0.6),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.kBrand, width: 1.6),
        ),
      ),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: BounceClick(
        onPressed: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: value
                ? AppTheme.kBrand.withValues(alpha: 0.10)
                : AppTheme.kSurface2Light,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: value
                  ? AppTheme.kBrand.withValues(alpha: 0.6)
                  : AppTheme.kBorderColor.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: value ? AppTheme.kBrand : AppTheme.kTextMuted,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: value ? FontWeight.w700 : FontWeight.w600,
                    color: AppTheme.kTextPrimary,
                  ),
                ),
              ),
              Switch.adaptive(
                value: value,
                activeTrackColor: AppTheme.kBrand,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  static List<String> _stringList(Object? raw) {
    if (raw is List) {
      return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }

  /// Ép giá trị metadata (num/string) về double an toàn.
  static double? _asNum(Object? raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString());
  }

  /// Rút gọn tiền tệ cho hint: 3.000.000 → "3tr", 12.500.000 → "12,5tr".
  static String _shortMoney(double v) {
    if (v >= 1000000) {
      final m = v / 1000000;
      final s = m == m.roundToDouble()
          ? m.toInt().toString()
          : m.toStringAsFixed(1).replaceAll('.', ',');
      return '${s}tr';
    }
    if (v >= 1000) return '${(v / 1000).toInt()}k';
    return v.toInt().toString();
  }

  static String _directionLabel(String code) {
    const map = {
      'DONG': 'Đông',
      'TAY': 'Tây',
      'NAM': 'Nam',
      'BAC': 'Bắc',
      'DONG_BAC': 'Đông Bắc',
      'DONG_NAM': 'Đông Nam',
      'TAY_BAC': 'Tây Bắc',
      'TAY_NAM': 'Tây Nam',
    };
    return map[code.toUpperCase()] ?? code;
  }

  static String _roomTypeLabel(String code) {
    // Nguồn chân lý duy nhất: MÃ canonical → NHÃN hiển thị.
    return RoomTypeCodes.labelOf(code);
  }

  static String _amenityLabel(String code) {
    // BUGFIX: dùng đúng MÃ mà luồng tạo phòng ghi vào cột `furniture`
    // (AC/TU_LANH/MAY_GIAT/GIUONG/TU_QUAN_AO/BAN_GHE/SOFA/TU_BEP/BEP_TU/
    // LO_VI_SONG/HUT_MUI/BINH_NONG_LANH/VOI_SEN/BET). Giữ thêm vài mã cũ
    // (WIFI/HEATER/FRIDGE/WASHER…) làm alias để dữ liệu seed/legacy vẫn có nhãn.
    const map = {
      // ── Mã thật do luồng tạo phòng ghi ──
      'AC': 'Điều hoà',
      'TU_LANH': 'Tủ lạnh',
      'MAY_GIAT': 'Máy giặt',
      'GIUONG': 'Giường đệm',
      'TU_QUAN_AO': 'Tủ quần áo',
      'BAN_GHE': 'Bàn ghế',
      'SOFA': 'Sofa',
      'TU_BEP': 'Tủ bếp',
      'BEP_TU': 'Bếp từ/gas',
      'LO_VI_SONG': 'Lò vi sóng',
      'HUT_MUI': 'Hút mùi',
      'BINH_NONG_LANH': 'Bình nóng lạnh',
      'VOI_SEN': 'Vòi sen',
      'BET': 'Bệt xịt',
      // ── Alias/legacy (seed cũ, dữ liệu nhập tay) ──
      'WIFI': 'Wifi',
      'HEATER': 'Bình nóng lạnh',
      'FRIDGE': 'Tủ lạnh',
      'WASHER': 'Máy giặt',
      'TV': 'Tivi',
      'BED': 'Giường',
      'WARDROBE': 'Tủ quần áo',
      'KITCHEN': 'Bếp',
      'PARKING': 'Chỗ để xe',
      'ELEVATOR': 'Thang máy',
      'SECURITY': 'Bảo vệ 24/7',
      'CAMERA': 'Camera',
      'BALCONY': 'Ban công',
      'WINDOW': 'Cửa sổ',
    };
    return map[code] ?? code;
  }
}

class _Opt {
  final String value;
  final String label;
  const _Opt(this.value, this.label);
}
