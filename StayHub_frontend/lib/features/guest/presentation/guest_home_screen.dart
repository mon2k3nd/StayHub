import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'widgets/guest_address_dropdown_overlay.dart';
import 'widgets/guest_quick_filter_dropdowns.dart';
import 'package:go_router/go_router.dart';

import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../application/explore_feed_notifier.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/room_type_codes.dart';
import '../../../core/components/bounce_click.dart';
import '../../../core/glass/glass_interactive.dart';
import '../../../core/glass/glass_surface.dart';
import '../../../core/components/stayhub_main_header.dart';
import 'widgets/guest_property_card.dart';
import 'guest_main_scaffold.dart';
import '../../search/application/room_search_notifier.dart';
import '../../search/application/room_filter_sync.dart';
import '../../search/domain/models/room_search_filter.dart';
import '../../search/presentation/widgets/room_search_filter_sheet.dart';
import '../../room/application/public_rooms_filter_provider.dart';
import '../../marketplace/presentation/guest_marketplace_screen.dart';
import '../../../core/services/osm_map_service.dart';
import '../../auth/application/auth_notifier.dart';
import '../../auth/presentation/widgets/guest_auth_bottom_sheet.dart';
import '../../marketplace/application/wishlist_provider.dart';
import '../../../core/utils/toast_utils.dart';

part 'guest_home_widgets.dart';

enum ViewMode { list, map }

/// Danh mục bất động sản trên thanh Category Bar.
///
/// Mỗi danh mục gắn với một ảnh 3D isometric trong `assets/images/categories/`
/// để đảm bảo tính đồng bộ thị giác (5/5 ảnh 3D, không còn icon 2D).
class _Category {
  final String label;
  final String imagePath;
  final String? roomType; // giá trị gửi lên API khi lọc theo danh mục

  const _Category({
    required this.label,
    required this.imagePath,
    this.roomType,
  });
}

/// BUGFIX: các `roomType` dưới đây PHẢI là MÃ CANONICAL (khớp
/// `RoomTypeCodes.canonicalCodes`), KHÔNG dùng alias. Trước đây 'Mặt bằng'
/// dùng `KIOT_BAN_LE`, 'Văn phòng' dùng `VAN_PHONG`, 'Kho xưởng' dùng
/// `KHO_XUONG` — đều là ALIAS. Chúng bị gửi thẳng lên API (xem
/// [RoomSearchFilter.toQueryParams]) và chỉ "tình cờ" đúng nhờ backend tự
/// canonical hoá; đồng thời phép so `isSelected`/`forRoomType` ở client dùng
/// alias nên dễ lệch. Nay quy về canonical: KIOT / OFFICE / KHO_BAI.
const List<_Category> _kCategories = [
  _Category(
    label: 'Phòng trọ',
    imagePath: 'assets/images/categories/phong_tro_v11.png',
    roomType: 'PHONG_TRO',
  ),
  _Category(
    label: 'Chung cư',
    imagePath: 'assets/images/categories/can_ho_v11.png',
    roomType: 'CHUNG_CU',
  ),
  _Category(
    label: 'Nhà ở',
    imagePath: 'assets/images/categories/nha_o_v11.png',
    roomType: 'NHA_NGUYEN_CAN',
  ),
  _Category(
    label: 'Ở ghép / KTX',
    imagePath: 'assets/images/categories/o_ghep_v11.png',
    roomType: 'O_GHEP_KTX',
  ),
  _Category(
    label: 'Mặt bằng',
    imagePath: 'assets/images/categories/mat_bang_v11.png',
    roomType: 'KIOT',
  ),
  _Category(
    label: 'Văn phòng',
    imagePath: 'assets/images/categories/van_phong_v11.png',
    roomType: 'OFFICE',
  ),
  _Category(
    label: 'Kho xưởng',
    imagePath: 'assets/images/categories/kho_van_v11.png',
    roomType: 'KHO_BAI',
  ),
  _Category(
    label: 'Không gian',
    imagePath: 'assets/images/categories/khong_gian_v11.png',
    roomType: 'KHONG_GIAN_CD',
  ),
  _Category(
    label: 'Lưu trú',
    imagePath: 'assets/images/categories/luu_tru_v11.png',
    roomType: 'LUU_TRU',
  ),
  _Category(
    label: 'Đất trống',
    imagePath: 'assets/images/categories/dat_cho_thue_v11.png',
    roomType: 'DAT_CHO_THUE',
  ),
];

class GuestHomeScreen extends ConsumerStatefulWidget {
  const GuestHomeScreen({super.key});

  @override
  ConsumerState<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends ConsumerState<GuestHomeScreen>
    with SingleTickerProviderStateMixin {
  ViewMode _viewMode = ViewMode.list;
  int? _activeCategory;

  final _searchCtrl = TextEditingController();
  final _searchFocusNode = FocusNode();
  Timer? _debounce;
  late final AnimationController _pulseCtrl;

  List<OsmSuggestion> _mapSuggestions = [];
  bool _isSearchingAddress = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _searchFocusNode.addListener(() {
      if (!mounted) return;
      setState(() {});
      if (_viewMode == ViewMode.map &&
          _searchFocusNode.hasFocus &&
          _searchCtrl.text.trim().isEmpty) {
        setState(() {
          _mapSuggestions = OsmMapService.getQuickLocations();
          _isSearchingAddress = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    _pulseCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String q) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (q.trim().isEmpty) {
      ref.read(roomSearchProvider.notifier).setKeyword('');
      // Ở màn Bản đồ, xoá từ khoá cũng phải xoá bộ lọc keyword của bản đồ.
      if (_viewMode == ViewMode.map) {
        ref
            .read(publicRoomsFilterProvider.notifier)
            .setFrom(ref.read(publicRoomsFilterProvider).copyWith(keyword: ''));
      }
      setState(() {
        _isSearchingAddress = false;
        _mapSuggestions = [];
      });
      return;
    }

    if (_viewMode == ViewMode.map) {
      setState(() => _isSearchingAddress = true);
      _debounce = Timer(const Duration(milliseconds: 600), () async {
        final results = await OsmMapService().searchSuggestions(q);
        if (mounted) {
          setState(() {
            _mapSuggestions = results;
            _isSearchingAddress = false;
          });
        }
      });
    } else {
      _debounce = Timer(const Duration(milliseconds: 500), () {
        ref.read(roomSearchProvider.notifier).setKeyword(q.trim());
      });
    }
  }

  Future<void> _handleMapAddressSearch(String q) async {
    _searchFocusNode.unfocus();
    setState(() {
      _isSearchingAddress = false;
      _mapSuggestions = [];
    });
    ref.read(roomSearchProvider.notifier).setKeyword(q.trim());
    // Đồng bộ từ khoá sang bộ lọc Bản đồ để bản đồ lọc đúng theo địa chỉ vừa tìm.
    if (_viewMode == ViewMode.map) {
      ref
          .read(publicRoomsFilterProvider.notifier)
          .setFrom(
            ref.read(publicRoomsFilterProvider).copyWith(keyword: q.trim()),
          );
    }
  }

  Widget _buildAddressSuggestionsOverlay() {
    if (_isSearchingAddress) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppTheme.kBackgroundLight,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.kTextPrimary.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.kBrand),
        ),
      );
    }
    if (_mapSuggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 320),
      decoration: BoxDecoration(
        color: AppTheme.kBackgroundLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kTextPrimary.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: _mapSuggestions.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: AppTheme.kBorderColor.withValues(alpha: 0.5),
            indent: 16,
            endIndent: 16,
          ),
          itemBuilder: (context, index) {
            final sugg = _mapSuggestions[index];
            return BounceClick(
              onPressed: () async {
                setState(() {
                  _searchCtrl.text = sugg.displayName;
                  _mapSuggestions = [];
                });
                _searchFocusNode.unfocus();
                ref
                    .read(roomSearchProvider.notifier)
                    .setKeyword(sugg.displayName);
                // BUGFIX: khi chọn gợi ý địa chỉ ở chế độ BẢN ĐỒ, phải đồng bộ
                // từ khoá sang bộ lọc Bản đồ (giống [_handleMapAddressSearch]).
                // Trước đây chỉ setKeyword cho danh sách → bản đồ KHÔNG lọc theo
                // địa chỉ vừa chọn, gây lệch kết quả giữa 2 màn.
                if (_viewMode == ViewMode.map) {
                  ref
                      .read(publicRoomsFilterProvider.notifier)
                      .setFrom(
                        ref
                            .read(publicRoomsFilterProvider)
                            .copyWith(keyword: sugg.displayName),
                      );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                color: Colors.transparent,
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.location_solid,
                      color: AppTheme.kBrand,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        sugg.displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.kTextPrimary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  OverlayEntry? _overlayEntry;

  void _closeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// BUGFIX (trạng thái danh mục bị "cũ"): `_activeCategory` là biến cục bộ chỉ
  /// được gán trong [_selectCategory]/[_resetCategory]. Khi bộ lọc đổi từ BÊN
  /// NGOÀI (đồng bộ Danh sách ⇄ Bản đồ ở [_toggleView], chọn địa chỉ/giá ở
  /// dropdown, áp bộ lọc ở sheet, hay deep-link), biến này KHÔNG được cập nhật →
  /// chip danh mục sáng sai và hồ sơ bộ lọc ở [_openFilter] bị lệch. Hàm này
  /// suy lại chỉ số danh mục từ `roomTypes` THẬT trong bộ lọc (so theo mã
  /// canonical để khớp cả alias lẫn canonical).
  void _syncActiveCategoryFromFilter(RoomSearchFilter filter) {
    int? next;
    if (filter.roomTypes.length == 1) {
      final wanted =
          RoomTypeCodes.toCode(filter.roomTypes.first) ??
          filter.roomTypes.first;
      for (var i = 0; i < _kCategories.length; i++) {
        final rt = _kCategories[i].roomType;
        if (rt == null) continue;
        if ((RoomTypeCodes.toCode(rt) ?? rt) == wanted) {
          next = i;
          break;
        }
      }
    }
    if (next != _activeCategory) {
      setState(() => _activeCategory = next);
    }
  }

  /// Áp bộ lọc cho màn Danh sách VÀ (nếu đang ở màn Bản đồ) đồng bộ luôn sang
  /// bộ lọc của Bản đồ. Nhờ vậy mọi thao tác lọc trên thanh header — dù đang ở
  /// chế độ Danh sách hay Bản đồ — đều được áp đúng cho CẢ HAI màn.
  void _applyListFilter(RoomSearchFilter filter) {
    ref.read(roomSearchProvider.notifier).applyFilter(filter);
    // Giữ chip danh mục khớp với bộ lọc thật (kể cả khi bộ lọc đổi từ nơi khác).
    _syncActiveCategoryFromFilter(filter);
    if (_viewMode == ViewMode.map) {
      ref
          .read(publicRoomsFilterProvider.notifier)
          .setFrom(RoomFilterSync.toMapFilter(filter));
    }
  }

  void _openFilter(String? focusedSection, Offset? pos, Size? size) async {
    if (pos != null &&
        size != null &&
        [
          'Khu vực',
          'Khoảng giá',
          'Diện tích',
          'Tiện ích',
        ].contains(focusedSection)) {
      if (_overlayEntry != null) {
        _closeOverlay();
        return;
      }

      final cur =
          ref.read(roomSearchProvider).value?.filter ?? RoomSearchFilter.empty;

      _overlayEntry = OverlayEntry(
        builder: (ctx) {
          if (focusedSection == 'Khu vực') {
            return AddressDropdownOverlay(
              position: pos,
              size: size,
              initialProvince: cur.province,
              initialDistrict: cur.district,
              initialWard: cur.ward,
              onApply: (p, d, w) {
                _closeOverlay();
                final curFilter =
                    ref.read(roomSearchProvider).value?.filter ??
                    RoomSearchFilter.empty;
                // replaceAll trả về String KHÔNG null → chỉ dùng ?. ở lần gọi
                // đầu tiên (trên p/d/w có thể null), các lần sau dùng . thường.
                // Trước đây viết ?. liên tiếp nên analyzer báo
                // invalid_null_aware_operator và có thể gây hành vi sai.
                final newFilter = curFilter.copyWith(
                  province: p
                      ?.replaceAll('Thành phố ', '')
                      .replaceAll('Tỉnh ', ''),
                  district: d
                      ?.replaceAll('Quận ', '')
                      .replaceAll('Huyện ', '')
                      .replaceAll('Thị xã ', ''),
                  ward: w
                      ?.replaceAll('Phường ', '')
                      .replaceAll('Xã ', '')
                      .replaceAll('Thị trấn ', ''),
                  clearProvince: p == null,
                  clearDistrict: d == null,
                  clearWard: w == null,
                );
                _applyListFilter(newFilter);
              },
              onDismiss: _closeOverlay,
            );
          } else if (focusedSection == 'Khoảng giá') {
            return PriceDropdownOverlay(
              position: pos,
              size: size,
              currentFilter: cur,
              onApply: (f) {
                _closeOverlay();
                _applyListFilter(f);
              },
              onDismiss: _closeOverlay,
            );
          } else if (focusedSection == 'Diện tích') {
            return AreaDropdownOverlay(
              position: pos,
              size: size,
              currentFilter: cur,
              onApply: (f) {
                _closeOverlay();
                _applyListFilter(f);
              },
              onDismiss: _closeOverlay,
            );
          } else {
            return AmenitiesDropdownOverlay(
              position: pos,
              size: size,
              currentFilter: cur,
              onApply: (f) {
                _closeOverlay();
                _applyListFilter(f);
              },
              onDismiss: _closeOverlay,
            );
          }
        },
      );

      Overlay.of(context).insert(_overlayEntry!);
      return;
    }

    final cur =
        ref.read(roomSearchProvider).value?.filter ?? RoomSearchFilter.empty;
    final profile = _activeCategory != null
        ? RoomFilterProfile.forRoomType(_kCategories[_activeCategory!].roomType)
        : RoomFilterProfile.all;
    final result = await RoomSearchFilterSheet.show(
      context,
      cur,
      profile: profile,
      focusedSection: focusedSection,
    );
    if (result != null) {
      _applyListFilter(result);
    }
  }

  void _openSearch() {
    HapticFeedback.lightImpact();
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Đóng tìm kiếm',
      barrierColor: Colors.black.withValues(alpha: 0.28),
      transitionDuration: const Duration(milliseconds: 420),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, _, __) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.08),
              end: Offset.zero,
            ).animate(curved),
            child: Align(
              alignment: Alignment.topCenter,
              child: _SearchSheet(
                initial: _searchCtrl.text,
                onSearch: (q) async {
                  setState(() => _searchCtrl.text = q);
                  if (_viewMode == ViewMode.map) {
                    await _handleMapAddressSearch(q);
                  } else {
                    _onSearchChanged(q);
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _applyChip(double max) {
    final cur =
        ref.read(roomSearchProvider).value?.filter ?? RoomSearchFilter.empty;
    final active = cur.maxPrice == max;
    // Chip giá là lọc "tối đa": luôn xoá minPrice để tránh khoảng giá vô lý
    // (min > max) khi người dùng vừa kéo slider vừa bấm chip.
    _applyListFilter(
      cur.copyWith(
        maxPrice: active ? null : max,
        clearMinPrice: true,
        clearMaxPrice: active,
      ),
    );
  }

  void _selectCategory(int index) {
    if (_activeCategory == index) {
      _resetCategory();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _activeCategory = index);

    final cat = _kCategories[index];
    final cur =
        ref.read(roomSearchProvider).value?.filter ?? RoomSearchFilter.empty;

    final profile = RoomFilterProfile.forRoomType(cat.roomType);

    _applyListFilter(
      cur.copyWith(
        roomTypes: cat.roomType == null ? const [] : [cat.roomType!],
        keyword: _searchCtrl.text.trim(),
        // Xoá MỌI tiêu chí mà hồ sơ danh mục mới KHÔNG hỏi — nếu chỉ xoá một
        // phần, các giá trị cũ (vd. số phòng ngủ của danh mục trước) sẽ tồn tại
        // âm thầm và lọc sai kết quả dù UI không còn hiển thị chúng.
        clearUsageType: !profile.usageType,
        clearBedrooms: !profile.bedrooms,
        clearBeds: !profile.beds,
        clearBathrooms: !profile.bathrooms,
        clearMaxGuests: !profile.maxGuests,
        clearDirection: !profile.direction,
      ),
    );
  }

  void _resetCategory() {
    HapticFeedback.mediumImpact();
    setState(() {
      _activeCategory = null;
      _searchCtrl.clear();
    });
    final cur =
        ref.read(roomSearchProvider).value?.filter ?? RoomSearchFilter.empty;
    // Bỏ chọn danh mục phải trả bộ lọc về trạng thái "chưa lọc theo danh mục":
    // xoá loại phòng + từ khoá VÀ mọi tiêu chí riêng của danh mục (số phòng
    // ngủ/giường/WC/người, hình thức sử dụng, hướng) để không còn điều kiện ẩn.
    _applyListFilter(
      cur.copyWith(
        roomTypes: const [],
        keyword: '',
        clearUsageType: true,
        clearBedrooms: true,
        clearBeds: true,
        clearBathrooms: true,
        clearMaxGuests: true,
        clearDirection: true,
      ),
    );
  }

  void _toggleView() {
    HapticFeedback.mediumImpact();
    final newMode = _viewMode == ViewMode.list ? ViewMode.map : ViewMode.list;

    // ── Đồng bộ bộ lọc giữa 2 màn (Danh sách ⇄ Bản đồ) ──────────────────────
    // Hai màn dùng 2 hệ bộ lọc khác nhau (RoomSearchFilter vs
    // PublicRoomsFilterState). Nếu không đồng bộ, bộ lọc áp ở màn Danh sách sẽ
    // KHÔNG mang sang màn Bản đồ (và ngược lại). Ta chuyển đổi qua lại để cả
    // hai màn luôn chia sẻ CÙNG một bộ lọc.
    if (newMode == ViewMode.map) {
      // Danh sách → Bản đồ: đẩy bộ lọc hiện tại của danh sách sang bản đồ.
      final listFilter =
          ref.read(roomSearchProvider).value?.filter ?? RoomSearchFilter.empty;
      ref
          .read(publicRoomsFilterProvider.notifier)
          .setFrom(RoomFilterSync.toMapFilter(listFilter));
    } else {
      // Bản đồ → Danh sách: mang bộ lọc đang áp trên bản đồ về danh sách.
      final mapFilter = ref.read(publicRoomsFilterProvider);
      final listFilter = RoomFilterSync.toListFilter(mapFilter);
      ref.read(roomSearchProvider.notifier).applyFilter(listFilter);
      // BUGFIX: đồng bộ lại chip danh mục theo bộ lọc vừa mang từ Bản đồ sang,
      // nếu không chip sẽ giữ trạng thái cũ (sáng sai / không sáng).
      _syncActiveCategoryFromFilter(listFilter);
    }

    setState(() {
      _viewMode = newMode;
    });
    ref
        .read(navCollapseProvider.notifier)
        .set(newMode == ViewMode.map ? 1.0 : 0.0);
  }

  // LƯU Ý: _getUserCurrentLocationAndSelect() và _selectAddressSuggestion()
  // đã được chuyển sang [global_guest_header.dart] (nơi thực sự dùng chúng).
  // Bản sao cũ ở đây là dead code → đã xoá để tránh nhầm lẫn và cảnh báo
  // unused_element.

  /// Mở bộ lọc server-driven (Liquid Glass) — đồng bộ 1-1 với backend.
  ///
  /// Toàn bộ tiêu chí (giá, diện tích, loại phòng, số phòng ngủ/giường/WC,
  /// khu vực, hướng, tiện ích, đặc điểm, sắp xếp) đều được đẩy xuống DB nên
  /// kết quả luôn chính xác trên toàn bộ dữ liệu — không lọc client-side.

  /// Mở thanh tìm kiếm chi tiết bằng hiệu ứng trượt xuống mượt mà.
  ///
  /// Dùng `showGeneralDialog` với transition tự viết để có thể kiểm soát
  /// hoàn toàn curve/opacity/scale — mang lại cảm giác "Liquid Glass" cao cấp
  /// thay vì bottom sheet mặc định của hệ điều hành.

  /// Chọn danh mục — khi ấn vào: ẩn tất cả danh mục khác,
  /// hoán đổi icon lên trên và bung ô input tìm kiếm bên cạnh.

  /// Hủy chọn danh mục — khôi phục lại thanh danh mục đầy đủ ban đầu.

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(roomSearchProvider);
    final notifier = ref.read(roomSearchProvider.notifier);

    // Chiều cao header co dãn MƯỢT MÀ (không nhảy cứng 160↔224).
    // - Chế độ thường: 3 tầng (nav + search bar + dải danh mục 3D) ≈ 224.
    // - Chế độ đã lọc: thu gọn còn 2 tầng (nav + search bar) ≈ 160.
    // AnimatedContainer bên dưới sẽ nội suy giá trị này theo thời gian nên
    // nội dung không bao giờ bị "giật" hay bị header che khuất.
    final topPadding = MediaQuery.of(context).padding.top + 224;

    return Scaffold(
      backgroundColor: AppTheme.kBackgroundLight,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/hero_city_white.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: AppTheme.kBackgroundLight.withValues(alpha: 0.85),
              ),
            ),
          ),
          //  L?p n?n: chuy?n gi?a Danh sch   B?n d? b?ng hi?u ?ng mu?t
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 380),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) {
              final fade = CurvedAnimation(parent: anim, curve: Curves.easeOut);
              return FadeTransition(
                opacity: fade,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.97, end: 1.0).animate(fade),
                  child: child,
                ),
              );
            },
            layoutBuilder: (current, previous) => Stack(
              fit: StackFit.expand,
              children: [...previous, if (current != null) current],
            ),
            child: _viewMode == ViewMode.list
                ? KeyedSubtree(
                    key: const ValueKey('list'),
                    // Nội suy mượt mà chiều cao header (160↔224) để nội dung
                    // trượt lên/xuống êm ái thay vì nhảy cứng.
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: topPadding),
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      builder: (context, animatedTop, _) =>
                          _buildBodyList(asyncState, notifier, animatedTop),
                    ),
                  )
                : GuestMarketplaceScreen(
                    key: const ValueKey('map'),
                    showTopHeader: false,
                    initialMapView: true,
                    bottomInset: 16,
                    onExitMap: _toggleView,
                  ),
          ),

          //  L?p n?i (Header chu?n UI/UX Liquid Glass + Animation Hon D?i Icon/Search)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _SearchHeader(
              ctrl: _searchCtrl,
              searchFocusNode: _searchFocusNode,
              asyncState: asyncState,
              mapFilter: ref.watch(publicRoomsFilterProvider),
              pulseCtrl: _pulseCtrl,
              onSearchTap: _openSearch,
              onFilterTap: _openFilter,
              onChipTap: _applyChip,
              viewMode: _viewMode,
              onToggleView: _toggleView,
              activeCategory: _activeCategory,
              onCategoryTap: _selectCategory,
              onResetCategory: _resetCategory,
              onSearchChanged: _onSearchChanged,
              onSubmitted: (v) => _handleMapAddressSearch(v),
            ),
          ),

          //  Overlay gợi ý địa chỉ cho người dùng chọn khi tìm kiếm bản đồ
          if (_viewMode == ViewMode.map) ...[
            Builder(
              builder: (context) {
                final isOverlayVisible =
                    _mapSuggestions.isNotEmpty ||
                    _isSearchingAddress ||
                    (_searchFocusNode.hasFocus &&
                        _searchCtrl.text.trim().isEmpty);
                return Positioned.fill(
                  child: IgnorePointer(
                    ignoring: !isOverlayVisible,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      opacity: isOverlayVisible ? 1.0 : 0.0,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _mapSuggestions = [];
                            _isSearchingAddress = false;
                          });
                          _searchFocusNode.unfocus();
                        },
                        behavior: HitTestBehavior.translucent,
                      ),
                    ),
                  ),
                );
              },
            ),
            Builder(
              builder: (context) {
                final isOverlayVisible =
                    _mapSuggestions.isNotEmpty ||
                    _isSearchingAddress ||
                    (_searchFocusNode.hasFocus &&
                        _searchCtrl.text.trim().isEmpty);
                return Positioned(
                  top: MediaQuery.of(context).padding.top + 70,
                  left: 16,
                  right: 16,
                  child: IgnorePointer(
                    ignoring: !isOverlayVisible,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      opacity: isOverlayVisible ? 1.0 : 0.0,
                      child: _buildAddressSuggestionsOverlay(),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  //  Overlay UI danh sch d?a ch? g?i y chu?n Liquid Glass (Vi?t Nam Only)

  // ── Thân trang List ─────────────────────────────────────────────────────────
  Widget _buildBodyList(
    AsyncValue<RoomSearchState> asyncState,
    RoomSearchNotifier notifier,
    double topPadding,
  ) {
    final state = asyncState.value;
    final items = state?.items ?? const <Map<String, dynamic>>[];
    final isLoading = asyncState.isLoading;

    if (isLoading && items.isEmpty) {
      return _SkeletonList(topPadding: topPadding);
    }
    if (asyncState.hasError && items.isEmpty) {
      return _ErrorView(onRetry: notifier.refresh);
    }
    if (items.isEmpty) {
      return const _EmptyView();
    }
    return _RoomList(
      asyncState: asyncState,
      notifier: notifier,
      topPadding: topPadding,
    );
  }
}

// ── Search Header (Liquid Glass chuẩn iOS 26) ─────────────────────────────────
class _SearchHeader extends StatelessWidget {
  final TextEditingController ctrl;
  final FocusNode? searchFocusNode;
  final AsyncValue<RoomSearchState> asyncState;

  /// Bộ lọc đang áp trên màn Bản đồ (chỉ dùng khi [viewMode] == map) để badge/
  /// nhãn của nút lọc phản ánh ĐÚNG bộ lọc đang hoạt động ở chế độ bản đồ.
  final PublicRoomsFilterState? mapFilter;
  final AnimationController pulseCtrl;
  final VoidCallback onSearchTap;
  final void Function(String?, Offset?, Size?) onFilterTap;
  final ValueChanged<double> onChipTap;

  final ViewMode viewMode;
  final VoidCallback onToggleView;

  final int? activeCategory;
  final ValueChanged<int> onCategoryTap;
  final VoidCallback onResetCategory;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String>? onSubmitted;

  const _SearchHeader({
    required this.ctrl,
    this.searchFocusNode,
    required this.asyncState,
    this.mapFilter,
    required this.pulseCtrl,
    required this.onSearchTap,
    required this.onFilterTap,
    required this.onChipTap,
    required this.viewMode,
    required this.onToggleView,
    required this.activeCategory,
    required this.onCategoryTap,
    required this.onResetCategory,
    required this.onSearchChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final topSafe = MediaQuery.of(context).padding.top;
    // Ở chế độ Bản đồ, bộ lọc đang hoạt động nằm ở [mapFilter]; ở chế độ Danh
    // sách thì lấy từ [asyncState]. Nhờ vậy badge/nhãn luôn phản ánh đúng.
    final listFilter = asyncState.value?.filter ?? RoomSearchFilter.empty;
    final filter = (viewMode == ViewMode.map && mapFilter != null)
        ? RoomFilterSync.toListFilter(mapFilter!)
        : listFilter;
    final hasActiveFilter = filter.activeCount > 0;

    // -- Dynamic labels --
    String areaLabel = 'Khu vực';
    if (filter.ward != null && filter.ward!.isNotEmpty) {
      areaLabel = filter.ward!;
    } else if (filter.district != null && filter.district!.isNotEmpty) {
      areaLabel = filter.district!;
    } else if (filter.province != null && filter.province!.isNotEmpty) {
      areaLabel = filter.province!;
    }

    String priceLabel = 'Khoảng giá';
    // Hàm cục bộ không nên bắt đầu bằng '_' (lint
    // no_leading_underscores_for_local_identifiers).
    String formatP(double v) {
      if (v >= 1000000) {
        return '${(v / 1000000).toStringAsFixed(1).replaceAll('.0', '')}tr';
      }
      if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
      return v.toStringAsFixed(0);
    }

    if (filter.minPrice != null && filter.maxPrice != null) {
      priceLabel =
          '${formatP(filter.minPrice!)} - ${formatP(filter.maxPrice!)}';
    } else if (filter.minPrice != null) {
      priceLabel = 'Từ ${formatP(filter.minPrice!)}';
    } else if (filter.maxPrice != null) {
      priceLabel = 'Đến ${formatP(filter.maxPrice!)}';
    }

    String amenitiesLabel = 'Tiện ích';
    if (filter.amenities.isNotEmpty) {
      amenitiesLabel = 'Tiện ích (${filter.amenities.length})';
    }

    String areaSizeLabel = 'Diện tích';
    if (filter.minArea != null && filter.maxArea != null) {
      areaSizeLabel =
          '${filter.minArea!.toStringAsFixed(0)} - ${filter.maxArea!.toStringAsFixed(0)} m²';
    } else if (filter.minArea != null) {
      areaSizeLabel = 'Từ ${filter.minArea!.toStringAsFixed(0)} m²';
    } else if (filter.maxArea != null) {
      areaSizeLabel = 'Đến ${filter.maxArea!.toStringAsFixed(0)} m²';
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: AppTheme.kGlassColorLight,
            border: Border(
              bottom: BorderSide(
                color: AppTheme.kBorderColor.withValues(alpha: 0.5),
                width: 0.8,
              ),
            ),
            // Bóng mềm xuất hiện khi header thu gọn (đang lọc) → tách biệt
            // rõ ràng với nội dung bên dưới, không bị "chìm".
            boxShadow: activeCategory != null
                ? [
                    BoxShadow(
                      color: AppTheme.kBrand.withValues(alpha: 0.10),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(14, topSafe + 8, 14, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── LIST MODE: Full Explore Header (3 tầng sang trọng) ──
                StayHubMainHeader(
                  leading: activeCategory != null
                      ? GlassIconButton(
                          icon: const Icon(
                            CupertinoIcons.chevron_back,
                            size: 18,
                            color: AppTheme.kTextPrimary,
                          ),
                          onPressed: onResetCategory,
                          size: 38,
                          shape: GlassIconButtonShape.circle,
                          useOwnLayer: true,
                        )
                      : null,
                  rightActions: [
                    IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Danh sách phòng đã lưu yêu thích'),
                            duration: Duration(milliseconds: 1500),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(
                        CupertinoIcons.heart,
                        size: 24,
                        color: AppTheme.kTextPrimary,
                      ),
                      splashRadius: 24,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onToggleView,
                      icon: Icon(
                        viewMode == ViewMode.map
                            ? CupertinoIcons.list_bullet
                            : CupertinoIcons.map,
                        size: 24,
                        color: AppTheme.kTextPrimary,
                      ),
                      splashRadius: 24,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── TẦNG 2: iOS 26 Liquid Glass Unified Search & Filter Bar ──
                AnimatedSize(
                  alignment: Alignment.topCenter,
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  clipBehavior: Clip.none,
                  child: SizedBox(
                    width: double.infinity,
                    // Luôn hiển thị thanh tìm kiếm (nhánh ẩn cũ đã bỏ để tránh
                    // dead_code; trước đây dùng `false ? ... : ...`).
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: AppTheme.kBorderColor.withValues(alpha: 0.8),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.kBrand.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 14),
                          const Icon(
                            CupertinoIcons.search,
                            size: 20,
                            color: AppTheme.kTextSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: ctrl,
                              onChanged: onSearchChanged,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.kTextPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: activeCategory != null
                                    ? 'Tìm trong ${_kCategories[activeCategory!].label}...'
                                    : 'Tìm kiếm phòng, vị trí, tiện ích...',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: AppTheme.kTextMuted.withValues(
                                    alpha: 0.75,
                                  ),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (ctrl.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                ctrl.clear();
                                onSearchChanged('');
                              },
                              behavior: HitTestBehavior.opaque,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(
                                  CupertinoIcons.clear_circled_solid,
                                  size: 16,
                                  color: AppTheme.kTextMuted,
                                ),
                              ),
                            ),
                          Container(
                            height: 22,
                            width: 1,
                            color: AppTheme.kBorderColor.withValues(alpha: 0.7),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                          GestureDetector(
                            onTap: () => onFilterTap(null, null, null),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    CupertinoIcons.slider_horizontal_3,
                                    size: 20,
                                    color: hasActiveFilter
                                        ? AppTheme.kBrand
                                        : AppTheme.kTextSecondary,
                                  ),
                                  // Badge số lượng tiêu chí đang lọc —
                                  // thông minh hơn chấm tròn: người dùng
                                  // biết ngay đang áp bao nhiêu điều kiện.
                                  if (hasActiveFilter) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      constraints: const BoxConstraints(
                                        minWidth: 18,
                                      ),
                                      height: 18,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.kBrand,
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${filter.activeCount}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── TẦNG 3: Danh sách 10 mô hình 3D Isometric ──
                AnimatedSize(
                  alignment: Alignment.topCenter,
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutCubic,
                  clipBehavior: Clip.none,
                  child: SizedBox(
                    width: double.infinity,
                    child: activeCategory == null
                        ? Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: SizedBox(
                              height: 82,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                itemCount: _kCategories.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (_, i) => _CategoryItem(
                                  category: _kCategories[i],
                                  isActive: false,
                                  onTap: () => onCategoryTap(i),
                                ),
                              ),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(top: 12, bottom: 4),
                            child: Row(
                              children: [
                                // Nút thả xuống mô hình + Nút X tích hợp
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.kBrand.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppTheme.kBrand.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          // Bật BottomSheet chọn mô hình
                                          showModalBottomSheet(
                                            context: context,
                                            backgroundColor: Colors.transparent,
                                            isScrollControlled: true,
                                            builder: (_) =>
                                                _CategorySelectorSheet(
                                                  activeCategory:
                                                      activeCategory,
                                                  onSelect: (idx) {
                                                    Navigator.pop(context);
                                                    onCategoryTap(idx);
                                                  },
                                                ),
                                          );
                                        },
                                        behavior: HitTestBehavior.opaque,
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            12,
                                            8,
                                            8,
                                            8,
                                          ),
                                          child: Row(
                                            children: [
                                              Image.asset(
                                                _kCategories[activeCategory!]
                                                    .imagePath,
                                                width: 18,
                                                height: 18,
                                                fit: BoxFit.contain,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                _kCategories[activeCategory!]
                                                    .label,
                                                style: const TextStyle(
                                                  color: AppTheme.kBrandDeep,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(
                                                CupertinoIcons.chevron_down,
                                                size: 14,
                                                color: AppTheme.kBrandDeep,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 16,
                                        color: AppTheme.kBrand.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: onResetCategory,
                                        behavior: HitTestBehavior.opaque,
                                        child: Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            8,
                                            8,
                                            12,
                                            8,
                                          ),
                                          child: Icon(
                                            CupertinoIcons.clear_circled_solid,
                                            size: 16,
                                            color: AppTheme.kBrand.withValues(
                                              alpha: 0.6,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                // Các bộ lọc phụ
                                Expanded(
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    child: Row(
                                      children: [
                                        _QuickFilterChip(
                                          label: areaLabel,
                                          isActive: areaLabel != 'Khu vực',
                                          onTap: (pos, size) =>
                                              onFilterTap('Khu vực', pos, size),
                                        ),
                                        const SizedBox(width: 8),
                                        _QuickFilterChip(
                                          label: priceLabel,
                                          isActive: priceLabel != 'Khoảng giá',
                                          onTap: (pos, size) => onFilterTap(
                                            'Khoảng giá',
                                            pos,
                                            size,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _QuickFilterChip(
                                          label: amenitiesLabel,
                                          isActive:
                                              amenitiesLabel != 'Tiện ích',
                                          onTap: (pos, size) => onFilterTap(
                                            'Tiện ích',
                                            pos,
                                            size,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _QuickFilterChip(
                                          label: areaSizeLabel,
                                          isActive:
                                              areaSizeLabel != 'Diện tích',
                                          onTap: (pos, size) => onFilterTap(
                                            'Diện tích',
                                            pos,
                                            size,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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
}

// ── Quick Filter Chip ──
class _QuickFilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Function(Offset position, Size size)? onTap;

  const _QuickFilterChip({
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BounceClick(
      onPressed: () {
        if (onTap != null) {
          final renderBox = context.findRenderObject() as RenderBox;
          final offset = renderBox.localToGlobal(Offset.zero);
          onTap!(offset, renderBox.size);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCirc,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.kBrand.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(50), // Pill shape for modern UI
          border: Border.all(
            color: isActive
                ? AppTheme.kBrand.withValues(alpha: 0.8)
                : AppTheme.kBorderColor.withValues(alpha: 0.8),
            width: isActive ? 1.2 : 0.8,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.kBrand.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                color: isActive ? AppTheme.kBrandDeep : AppTheme.kTextPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              CupertinoIcons.chevron_down,
              size: 12,
              color: isActive ? AppTheme.kBrandDeep : AppTheme.kTextMuted,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Dropdown Category Selector BottomSheet ──
class _CategorySelectorSheet extends StatelessWidget {
  final int? activeCategory;
  final ValueChanged<int> onSelect;

  const _CategorySelectorSheet({
    required this.activeCategory,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.kBackgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
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
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Chọn loại hình lưu trú',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.kTextPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: _kCategories.length,
                itemBuilder: (context, index) {
                  final cat = _kCategories[index];
                  final isSelected = activeCategory == index;
                  return GestureDetector(
                    onTap: () => onSelect(index),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.kBrand.withValues(alpha: 0.08)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.kBrand
                              : AppTheme.kBorderColor,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.kBrand.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            cat.imagePath,
                            width: 38,
                            height: 38,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              cat.label,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? AppTheme.kBrandDeep
                                    : AppTheme.kTextPrimary,
                              ),
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.kBrand,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.checkmark_alt,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
