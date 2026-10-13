import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/components/glass_container.dart';
import '../../../../../core/utils/toast_utils.dart';
import '../../../application/branch_notifier.dart';
import '../../../data/models/branch_model.dart';
import '../../create_branch_screen.dart';
import 'branch_wizard_theme.dart';
import 'dart:async' show unawaited;

/// BƯỚC 1 — Khởi tạo & Thiết lập Khung vận hành Chi nhánh.
///
/// Bao gồm: ảnh chi nhánh, tên, mã (ID), địa chỉ ghim bản đồ, mô hình chi nhánh,
/// cấu hình quy chế chung & tiện ích, cấu hình tài sản chung, bộ đơn giá.
///
/// Bước này tái sử dụng toàn bộ luồng "Tạo khu trọ" cũ ([CreateBranchScreen])
/// ở chế độ [CreateBranchScreen.wizardMode] để không mất bất kỳ trường dữ liệu
/// nào đã có, nhưng lưu ở trạng thái NHÁP (DRAFT).
class Step1FrameworkWidget extends ConsumerStatefulWidget {
  final BranchModel? branch;
  final ValueChanged<BranchModel> onCompleted;

  const Step1FrameworkWidget({
    super.key,
    required this.branch,
    required this.onCompleted,
  });

  @override
  ConsumerState<Step1FrameworkWidget> createState() =>
      _Step1FrameworkWidgetState();
}

class _Step1FrameworkWidgetState extends ConsumerState<Step1FrameworkWidget> {
  bool _busy = false;

  /// Số ảnh cover/PCCC — nạp riêng qua endpoint `/images` vì backend đã
  /// `@JsonIgnore` hai cột ảnh nặng để tránh OOM khi trả danh sách.
  int _coverCount = 0;
  int _pcccCount = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadImageCounts());
  }

  @override
  void didUpdateWidget(covariant Step1FrameworkWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.branch?.id != widget.branch?.id) {
      unawaited(_loadImageCounts());
    }
  }

  Future<void> _loadImageCounts() async {
    final id = widget.branch?.id;
    if (id == null) return;
    try {
      final imgs = await ref.read(branchRepositoryProvider).getBranchImages(id);
      if (!mounted) return;
      setState(() {
        _coverCount = _countJsonList(imgs['coverImages'] ?? imgs['coverImage']);
        _pcccCount = _countJsonList(imgs['pcccImages']);
      });
    } catch (_) {
      // Bỏ qua — checklist chỉ hiển thị "Chưa cập nhật".
    }
  }

  /// Chi nhánh MỚI NHẤT để hiển thị checklist.
  ///
  /// Ưu tiên bản ghi trong `branchProvider` (đã được `markStep`/`updateBranch`
  /// đồng bộ tại chỗ) theo `id`, vì `widget.branch` là ảnh chụp tại thời điểm
  /// mở màn hình và có thể THIẾU `description` (tiện ích) vừa lưu. Nếu không
  /// tìm thấy trong provider thì mới rơi về `widget.branch`.
  ///
  /// Trước đây checklist chỉ đọc `widget.branch` nên sau khi lưu tiện ích ở
  /// Bước 1, người dùng phải mở lại Bước 1 LẦN THỨ HAI mới thấy tiện ích
  /// ("cứ phải làm 2 lần mới thấy").
  BranchModel? _resolveBranch() {
    final fallback = widget.branch;
    final id = fallback?.id;
    if (id == null) return fallback;
    final list = ref.watch(branchProvider).value;
    if (list == null) return fallback;
    for (final b in list) {
      if (b.id == id) return b;
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final b = _resolveBranch();
    final done = b?.step1Done ?? false;

    return WzStepScaffold(
      title: 'Bước 1 · Khung vận hành',
      subtitle: 'Thiết lập nền tảng cho chi nhánh',
      bottomBar: _buildActionButton(b, done),
      children: [
        const WzInfoCard(
          icon: CupertinoIcons.briefcase_fill,
          title: 'Khung vận hành chi nhánh',
          description:
              'Thiết lập nền tảng pháp lý & vận hành cho chi nhánh. '
              'Đây là bước bắt buộc đầu tiên — mọi bước sau đều dựa trên dữ liệu này.',
        ),
        const SizedBox(height: WzSpacing.md),
        _buildChecklist(b),
      ],
    );
  }

  Widget _buildChecklist(BranchModel? b) {
    final meta = _decodeMeta(b?.description);
    final amenities = (meta['branchAmenities'] as List?) ?? const [];
    final customAmenities = (meta['customAmenities'] as List?) ?? const [];

    final coverCount = _coverCount;
    final pcccCount = _pcccCount;
    final amenityNames = _amenityNames(amenities, customAmenities);
    final addr = _parseAddress(b);

    // Mỗi mục = (icon, tiêu đề, mô tả, danh sách dòng nhãn/giá trị).
    // Giá trị rỗng → WzInfoRow tự hiện "Chưa cập nhật" màu đỏ.
    final items = <(IconData, String, String, List<(String, String?)>)>[
      (
        CupertinoIcons.photo_fill,
        'Ảnh chi nhánh',
        'Ảnh bìa & thư viện ảnh thực tế của dãy trọ',
        [
          ('Ảnh bìa', coverCount > 0 ? '$coverCount ảnh' : null),
          (
            'PCCC',
            pcccCount > 0
                ? '$pcccCount ảnh'
                : (b?.hasPccc == true ? 'Đã bật · chưa có ảnh' : 'Không bật'),
          ),
        ],
      ),
      (
        CupertinoIcons.tag_fill,
        'Tên & mã chi nhánh (ID)',
        'Tên hiển thị và mã định danh duy nhất',
        [('Tên chi nhánh', b?.branchName), ('Mã chi nhánh', b?.branchCode)],
      ),
      (
        CupertinoIcons.location_fill,
        'Địa chỉ ghim bản đồ',
        'Địa chỉ 4 cấp + toạ độ lat/lng chính xác',
        [
          ('Số nhà', addr.houseNumber),
          ('Tên đường', addr.street),
          ('Phường/Xã', addr.ward ?? b?.legalWard),
          ('Quận/Huyện', addr.district ?? b?.legalDistrict),
          ('Tỉnh/Thành', addr.province ?? b?.legalProvince),
          (
            'Toạ độ',
            (b?.latitude != null && b?.longitude != null)
                ? '${b!.latitude!.toStringAsFixed(5)}, ${b.longitude!.toStringAsFixed(5)}'
                : null,
          ),
        ],
      ),
      (
        CupertinoIcons.building_2_fill,
        'Mô hình chi nhánh',
        'Nhà trọ / Chung cư mini / Studio…',
        [
          (
            'Loại hình',
            b?.propertyType != null
                ? _propertyTypeLabel(b!.propertyType)
                : null,
          ),
        ],
      ),
      (
        CupertinoIcons.doc_text_fill,
        'Quy chế chung & tiện ích',
        'Giờ giới nghiêm, nấu ăn, thú nuôi, PCCC…',
        [
          ('Giờ giới nghiêm', _closingLabel(b?.closingTime)),
          ('Nấu ăn', _cookingLabel(b?.cookingPolicy)),
          (
            'Thú nuôi',
            b?.petPolicy == null
                ? null
                : (b!.petPolicy! ? 'Cho phép' : 'Không cho phép'),
          ),
          (
            'Ở ghép',
            b?.roommatePolicy == null
                ? null
                : (b!.roommatePolicy! ? 'Cho phép' : 'Không cho phép'),
          ),
          (
            'Sạc xe điện',
            b?.evChargingAllowed == null
                ? null
                : (b!.evChargingAllowed!
                      ? _evLabel(b.evChargeType)
                      : 'Không cho phép'),
          ),
          ('Tiện ích', amenityNames.isEmpty ? null : amenityNames.join(', ')),
        ],
      ),
      (
        CupertinoIcons.money_dollar_circle_fill,
        'Bộ đơn giá',
        'Giá điện, nước, internet, rác, gửi xe',
        [
          ('Điện', _moneyOrNull(b?.electricityPrice)),
          ('Nước', _moneyOrNull(b?.waterPrice)),
          ('Internet', _moneyOrNull(b?.internetPrice)),
          ('Gửi xe', _moneyOrNull(b?.parkingPrice)),
          ('Vệ sinh', _moneyOrNull(b?.trashPrice)),
          ('Phí dịch vụ', _moneyOrNull(b?.serviceFee)),
          ('Ngày chốt', b?.billingDay != null ? 'Ngày ${b!.billingDay}' : null),
          (
            'HĐ tối thiểu',
            (b?.minLeaseDays ?? 0) > 0 ? '${b!.minLeaseDays} ngày' : null,
          ),
        ],
      ),
    ];

    return GlassContainer(
      padding: const EdgeInsets.symmetric(
        horizontal: WzSpacing.lg,
        vertical: WzSpacing.xs,
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            WzChecklistRow(
              icon: items[i].$1,
              title: items[i].$2,
              subtitle: items[i].$3,
              rows: items[i].$4,
            ),
            if (i != items.length - 1)
              const Divider(height: 1, color: WzColors.divider),
          ],
        ],
      ),
    );
  }

  /// Tách địa chỉ thành các thành phần theo ĐÚNG thứ tự đã lưu:
  /// `[Số nhà, Tên đường, Phường/Xã, Quận/Huyện, Tỉnh/Thành phố]`.
  ///
  /// Chiến lược: duyệt từ CUỐI lên và nhận diện 3 cấp hành chính bằng tiền tố
  /// (Tỉnh/Thành phố → Quận/Huyện/Thị xã → Phường/Xã/Thị trấn). Nhờ duyệt
  /// ngược, "Thành phố" ở vị trí quận (vd "Thành phố Thủ Đức") không bị nhầm
  /// thành tỉnh. Phần còn lại (đầu danh sách) là Số nhà + Tên đường.
  ({
    String? houseNumber,
    String? street,
    String? ward,
    String? district,
    String? province,
  })
  _parseAddress(BranchModel? b) {
    final raw = (b?.addressOld?.trim().isNotEmpty ?? false)
        ? b!.addressOld!.trim()
        : (b?.address ?? '').trim();
    if (raw.isEmpty) {
      return (
        houseNumber: null,
        street: null,
        ward: null,
        district: null,
        province: null,
      );
    }

    final parts = raw
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    bool isProvince(String s) =>
        s.startsWith('tỉnh ') || s.startsWith('thành phố ');
    bool isDistrict(String s) =>
        s.startsWith('quận ') ||
        s.startsWith('huyện ') ||
        s.startsWith('thị xã ') ||
        s.startsWith('thành phố ');
    bool isWard(String s) =>
        s.startsWith('phường ') ||
        s.startsWith('xã ') ||
        s.startsWith('thị trấn ');

    String? ward;
    String? district;
    String? province;
    var cut = parts.length;

    // Duyệt ngược: Tỉnh → Quận → Phường.
    for (var i = parts.length - 1; i >= 0; i--) {
      final lower = parts[i].toLowerCase();
      if (province == null && isProvince(lower)) {
        province = parts[i];
        cut = i;
      } else if (district == null && isDistrict(lower)) {
        district = parts[i];
        cut = i;
      } else if (ward == null && isWard(lower)) {
        ward = parts[i];
        cut = i;
      } else {
        break;
      }
    }

    // Fallback vị trí: phần cuối luôn là Tỉnh, trước đó là Quận, trước nữa là Phường.
    if (province == null && parts.length >= 3) {
      province = parts[parts.length - 1];
      cut = parts.length - 1;
    }
    if (district == null && cut - 1 >= 0 && cut - 1 < parts.length) {
      district = parts[cut - 1];
      cut = cut - 1;
    }
    if (ward == null && cut - 1 >= 0 && cut - 1 < parts.length) {
      ward = parts[cut - 1];
      cut = cut - 1;
    }

    final streetParts = parts.sublist(0, cut < 0 ? 0 : cut);
    final houseNumber = streetParts.isNotEmpty ? streetParts.first : null;
    final street = streetParts.length > 1
        ? streetParts.sublist(1).join(', ')
        : null;

    return (
      houseNumber: houseNumber,
      street: street,
      ward: ward,
      district: district,
      province: province,
    );
  }

  // ─────────────────────────── Summary helpers ───────────────────────────

  Map<String, dynamic> _decodeMeta(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }

  /// Đếm số phần tử trong trường ảnh. Hỗ trợ cả 2 định dạng backend trả về:
  /// - JSON array: `["url1","url2"]`
  /// - Chuỗi đơn: `url` hoặc `data:image/...;base64,...`
  int _countJsonList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 0;
    final value = raw.trim();
    if (value.startsWith('[')) {
      try {
        final decoded = jsonDecode(value);
        return decoded is List ? decoded.length : 0;
      } catch (_) {
        return 0;
      }
    }
    // Không phải JSON array → coi là 1 ảnh đơn (URL hoặc base64).
    return 1;
  }

  /// Định dạng tiền. Trả `null` khi chưa cấu hình (để hiện "Chưa cập nhật"),
  /// trả "Miễn phí" khi giá = 0.
  String? _moneyOrNull(double? v) {
    if (v == null) return null;
    if (v <= 0) return 'Miễn phí';
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf.toString()} đ';
  }

  String _propertyTypeLabel(int? type) {
    return switch (type) {
      1 => 'Nhà trọ',
      2 => 'Chung cư mini',
      3 => 'Studio',
      4 => 'Nhà nguyên căn',
      5 => 'Căn hộ dịch vụ',
      _ => 'Chưa chọn',
    };
  }

  /// Nhãn giờ giới nghiêm. "Tự do" → "Giờ giấc tự do".
  String? _closingLabel(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return null;
    final lower = s.toLowerCase();
    if (lower == 'tự do' || lower == 'tu do' || lower == 'free') {
      return 'Giờ giấc tự do';
    }
    return s;
  }

  String? _cookingLabel(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return null;
    return switch (s) {
      'CHO_PHEP' => 'Cho phép',
      'KHONG_CHO_PHEP' => 'Không cho phép',
      'KHU_VUC_CHUNG' => 'Khu vực chung',
      'TRONG_PHONG' => 'Nấu trong phòng',
      _ => s,
    };
  }

  String _evLabel(String? v) {
    return switch (v) {
      'FIXED' => 'Thu phí cố định',
      'PERCENT' => 'Thu theo %',
      'FREE' => 'Miễn phí',
      _ => 'Cho phép',
    };
  }

  /// Tên các tiện ích đã chọn (gộp tiện ích hệ thống + tuỳ chỉnh).
  /// Trả rỗng khi chưa chọn → UI hiện "Chưa cập nhật" màu đỏ.
  ///
  /// LƯU Ý định dạng lưu trữ:
  /// - `branchAmenities` = `List<Map>` với khoá `name` (xem `submit()`).
  /// - `customAmenities` = `List<String>` (xem `submit()`), KHÔNG phải Map.
  ///   Trước đây chỉ đọc `a['name']` nên tiện ích tuỳ chỉnh KHÔNG bao giờ
  ///   hiển thị trong checklist Bước 1. Hỗ trợ cả 2 định dạng để tương thích
  ///   với dữ liệu cũ (nếu từng lưu dạng Map).
  List<String> _amenityNames(List amenities, List custom) {
    final names = <String>[];
    for (final a in amenities) {
      final n = a is Map ? a['name']?.toString() : a?.toString();
      if (n != null && n.isNotEmpty) names.add(n);
    }
    for (final a in custom) {
      final n = a is Map ? a['name']?.toString() : a?.toString();
      if (n != null && n.isNotEmpty) names.add(n);
    }
    return names;
  }

  Widget _buildActionButton(BranchModel? b, bool done) {
    return WzPrimaryButton(
      label: done ? 'Chỉnh sửa khung vận hành' : 'Thiết lập khung vận hành',
      icon: done
          ? CupertinoIcons.checkmark_alt_circle_fill
          : CupertinoIcons.pencil,
      color: done ? WzColors.success : WzColors.brand,
      loading: _busy,
      onPressed: () => _openFramework(b),
    );
  }

  Future<void> _openFramework(BranchModel? b) async {
    setState(() => _busy = true);
    try {
      // Mở màn hình thiết lập khung vận hành ở CHẾ ĐỘ WIZARD:
      // - Lưu chi nhánh dạng NHÁP (DRAFT) qua API createWizardDraft.
      // - Lưu xong chỉ pop(BranchModel) về đây, không nhảy sang màn hình khác.
      final result = await Navigator.of(context).push<BranchModel>(
        CupertinoPageRoute(
          builder: (_) => CreateBranchScreen(branchToEdit: b, wizardMode: true),
        ),
      );
      if (!mounted) return;
      if (result == null) return;

      // Đánh dấu bước 1 hoàn tất trên server. Dữ liệu này là NỀN TẢNG cho
      // các bước sau (cấu trúc phòng, vệ sinh chung, đăng bài).
      final updated = await ref
          .read(branchProvider.notifier)
          .markStep(result.id, 1, true);
      if (!mounted) return;
      // Không hiện toast ở đây nữa: submit() bên trong màn hình wizard đã
      // hiện "Đã lưu khung vận hành". Toast trùng lặp + chèn OverlayEntry
      // ngay sau khi route vừa pop gây nhiễu animation/navigator.
      widget.onCompleted(updated ?? result);
    } catch (e) {
      if (mounted) {
        ToastUtils.show(
          context,
          'Không thể lưu khung vận hành: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
