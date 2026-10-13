import 'dart:io';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/room_type_codes.dart';
import '../../../core/components/responsive_file_image.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/utils/image_picker_utils.dart';
import 'dart:async' show unawaited;

class EditPostScreen extends ConsumerStatefulWidget {
  final dynamic room;
  final dynamic post; // null if creating a new post
  final dynamic branch; // branch object — source of service prices
  final String? branchAddress;
  final dynamic branchLat;
  final dynamic branchLng;

  const EditPostScreen({
    super.key,
    required this.room,
    this.post,
    this.branch,
    this.branchAddress,
    this.branchLat,
    this.branchLng,
  });

  @override
  ConsumerState<EditPostScreen> createState() => _EditPostScreenState();
}

class _ImageData {
  final bool isNetwork;
  final String path;
  _ImageData(this.isNetwork, this.path);
}

class _EditPostScreenState extends ConsumerState<EditPostScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _basePriceController = TextEditingController();
  final _basePriceFocusNode = FocusNode();
  int _initialBasePrice = 0;
  double? _currentDeposit;
  final List<_ImageData> _images = [];
  final bool _isLoading = false;

  // ── Room data accessors (works for both Map and RoomModel) ──────
  Map<String, dynamic> get _roomMap => widget.room is Map
      ? Map<String, dynamic>.from(widget.room)
      : widget.room.toJson();

  dynamic _roomField(String key) {
    if (widget.room is Map) return (widget.room as Map)[key];
    try {
      return _roomMap[key];
    } catch (_) {
      return null;
    }
  }

  /// BUGFIX (data): coerce an toàn sang num — tránh `as num?` ném TypeError
  /// khi backend trả String ("3000000") hoặc giá trị không phải số.
  num _asNum(dynamic raw) {
    if (raw == null) return 0;
    if (raw is num) return raw;
    return num.tryParse(raw.toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
  }

  // ── AI description assistant ────────────────────────────────────
  /// Sinh mô tả dài, đầy đủ từ dữ liệu phòng + chi nhánh.
  ///
  /// BẢO MẬT: KHÔNG đưa thông tin nhạy cảm vào mô tả — số điện thoại,
  /// số CCCD, email, địa chỉ nhà chính xác (số nhà/ngõ) đều bị loại bỏ.
  /// Chỉ mô tả khu vực ở cấp phường/quận/tỉnh.
  void _generateAiDescription() {
    final fmt = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '',
      decimalDigits: 0,
    );
    final room = _roomMap;

    String s(dynamic v) => v?.toString().trim() ?? '';
    double n(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0;

    final price = n(room['price'] ?? _roomFieldDeep('price'));
    final area = n(room['area'] ?? room['floorArea'] ?? _roomFieldDeep('area'));
    final deposit = n(room['deposit'] ?? _roomFieldDeep('deposit'));
    final mezzanine = n(
      room['mezzanineArea'] ?? _roomFieldDeep('mezzanineArea'),
    );
    final floor = s(room['floor'] ?? _roomFieldDeep('floor'));
    final maxOcc = _maxOccupants;
    final maxVehicles = _maxVehicles;
    final roomType = _roomTypeLabel;
    final orientation = _orientationLabel;
    final furnitureLevel = _furnitureLevelLabel;

    // ── Nội thất: dịch mã (AC, BINH_NONG_LANH, TU_QUAN_AO…) sang nhãn
    //    tiếng Việt. Trước đây AI in thẳng mã thô nên bài viết rất "ẩu".
    final List<String> furnitureLabels = [];
    for (final code in _amenities) {
      final entry = _furnitureMap[code];
      final label = entry?['label'] ?? (code.contains('_') ? '' : code);
      if (label.isNotEmpty && !furnitureLabels.contains(label)) {
        furnitureLabels.add(label);
      }
    }

    // ── Tiện ích chung của toà nhà (thang máy, bãi xe, camera…).
    final List<String> branchAmenityLabels = [];
    final branchAmenitiesRaw = _branchMap['branchAmenities'];
    if (branchAmenitiesRaw is List) {
      for (final a in branchAmenitiesRaw) {
        if (a is Map) {
          final name = s(a['name']);
          if (name.isNotEmpty && !branchAmenityLabels.contains(name)) {
            branchAmenityLabels.add(name);
          }
        }
      }
    }

    // ── Giá dịch vụ (thuộc CHI NHÁNH, không phải phòng).
    final elecPrice = n(_priceField('electricityPrice'));
    final waterPrice = n(_priceField('waterPrice'));
    final serviceFee = n(_priceField('serviceFee'));
    final internetPrice = n(_priceField('internetPrice'));
    final parkingPrice = n(_priceField('parkingPrice'));
    final trashPrice = n(_priceField('trashPrice'));

    // ── Địa chỉ đã được làm mờ: chỉ giữ phường/quận/tỉnh (bảo mật).
    final branch = _branchMap;
    final ward = s(branch['legalWard']);
    final district = s(branch['legalDistrict']);
    final province = s(branch['legalProvince']);
    final areaText = [
      ward,
      district,
      province,
    ].where((e) => e.isNotEmpty).join(', ');

    final buf = StringBuffer();

    // ── Mở bài (gộp tiêu đề + giới thiệu, tránh lặp lại thông số)
    final intro = StringBuffer('Cho thuê ');
    intro.write(roomType.isNotEmpty ? roomType.toLowerCase() : 'phòng');
    if (area > 0) intro.write(' ${area.toStringAsFixed(0)}m²');
    if (floor.isNotEmpty) intro.write(' tại tầng $floor');
    if (areaText.isNotEmpty) intro.write(', khu vực $areaText');
    intro.write('. ');
    if (furnitureLevel.isNotEmpty) {
      intro.write('Phòng $furnitureLevel, vào ở ngay. ');
    }
    intro.write(
      'Không gian thoáng, nhiều ánh sáng tự nhiên, phù hợp sinh viên và người đi làm.',
    );
    buf.writeln(intro.toString());
    buf.writeln();

    // ── Điểm nổi bật (chỉ liệt kê, không diễn giải dài dòng)
    final highlights = <String>[];
    if (mezzanine > 0) {
      highlights.add('Gác xép ${mezzanine.toStringAsFixed(0)}m²');
    }
    if (orientation.isNotEmpty) highlights.add(orientation);
    if (maxOcc != null && maxOcc > 0) highlights.add('Tối đa $maxOcc người');
    if (maxVehicles != null && maxVehicles > 0) {
      highlights.add('Để được $maxVehicles xe');
    }
    if (_isSelfContained) highlights.add('Vệ sinh khép kín');
    if (_hasBalcony) highlights.add('Ban công');
    if (_hasWindow) highlights.add('Cửa sổ');
    if (_hasKitchen) highlights.add('Có bếp');
    if (furnitureLabels.isNotEmpty) {
      highlights.add('Nội thất: ${furnitureLabels.join(', ')}');
    }
    if (highlights.isNotEmpty) {
      buf.writeln('✨ Điểm nổi bật: ${highlights.join(' • ')}');
      buf.writeln();
    }

    // ── Vị trí & tiện ích toà nhà
    if (areaText.isNotEmpty || branchAmenityLabels.isNotEmpty) {
      buf.writeln('📍 Vị trí & tiện ích:');
      if (areaText.isNotEmpty) {
        buf.writeln('• Khu vực $areaText — gần chợ, trường học, siêu thị.');
      }
      if (branchAmenityLabels.isNotEmpty) {
        buf.writeln(
          '• Toà nhà có: ${branchAmenityLabels.take(10).join(', ')}.',
        );
      }
      buf.writeln();
    }

    // ── Chi phí (chỉ in khoản có phát sinh)
    final costs = <String>[];
    if (price > 0) costs.add('Giá thuê ${fmt.format(price)}đ/tháng');
    if (deposit > 0) costs.add('Cọc ${fmt.format(deposit)}đ');
    if (elecPrice > 0) costs.add('Điện ${fmt.format(elecPrice)}đ/kWh');
    if (waterPrice > 0) costs.add('Nước ${fmt.format(waterPrice)}đ');
    if (internetPrice > 0) {
      costs.add('Internet ${fmt.format(internetPrice)}đ/tháng');
    }
    if (parkingPrice > 0) {
      costs.add('Gửi xe ${fmt.format(parkingPrice)}đ/tháng');
    }
    if (trashPrice > 0) costs.add('Vệ sinh ${fmt.format(trashPrice)}đ/tháng');
    if (serviceFee > 0) {
      costs.add('Phí dịch vụ ${fmt.format(serviceFee)}đ/tháng');
    }
    if (costs.isNotEmpty) {
      buf.writeln('💰 Chi phí: ${costs.join(' • ')}.');
      buf.writeln();
    }

    // ── Liên hệ
    buf.writeln(
      '📞 Liên hệ qua ứng dụng StayHub để được tư vấn và xem phòng trực tiếp.',
    );

    final text = buf.toString().trim();
    _descriptionController.text = text;
    _descriptionController.selection = TextSelection.collapsed(
      offset: text.length,
    );
    setState(() {});
    ToastUtils.show(context, 'Đã tạo mô tả bằng AI');
  }

  // ── Branch data accessors ───────────────────────────────────────
  // Service prices (điện/nước/mạng/gửi xe/rác/phí dịch vụ) belong to the
  // BRANCH, not the room. The room-config sheet only displays them read-only
  // from `widget.branch`. So the post screen must read them from the branch.
  Map<String, dynamic> get _branchMap {
    final b = widget.branch;
    if (b == null) return const {};
    if (b is Map) return Map<String, dynamic>.from(b);
    try {
      return Map<String, dynamic>.from(b.toJson() as Map);
    } catch (_) {
      return const {};
    }
  }

  /// Tên chi nhánh (hiển thị ở hero + review).
  String get _branchName {
    final b = widget.branch;
    if (b != null && b is! Map) {
      try {
        final v = b.branchName;
        if (v != null && v.toString().trim().isNotEmpty) {
          return v.toString().trim();
        }
      } catch (_) {}
    }
    return (_branchMap['branchName'] ?? _branchMap['name'] ?? '')
        .toString()
        .trim();
  }

  /// Danh sách tiện ích chung của toà nhà (bước 2 khi tạo chi nhánh).
  /// Nguồn: `branchAmenities` (root) hoặc JSON trong `description`.
  List<Map<String, dynamic>> get _branchAmenities {
    List<dynamic>? raw;
    final direct = _branchMap['branchAmenities'];
    if (direct is List) {
      raw = direct;
    } else {
      final desc = _branchMap['description'];
      dynamic decoded = desc;
      if (desc is String && desc.trim().startsWith('{')) {
        try {
          decoded = jsonDecode(desc);
        } catch (_) {
          decoded = null;
        }
      }
      if (decoded is Map && decoded['branchAmenities'] is List) {
        raw = decoded['branchAmenities'] as List;
      }
    }
    if (raw == null) return const [];
    final out = <Map<String, dynamic>>[];
    for (final a in raw) {
      if (a is Map) {
        final name = (a['name'] ?? '').toString().trim();
        if (name.isEmpty) continue;
        final chargeType = (a['chargeType'] ?? 'free').toString();
        final price = double.tryParse((a['price'] ?? 0).toString()) ?? 0;
        out.add({
          'name': name,
          // Tiện ích "free" luôn coi như 0đ để không hiển thị giá sai.
          'price': chargeType == 'free' ? 0.0 : price,
          'chargeType': chargeType,
          'icon': (a['icon'] ?? a['emoji'] ?? '✅').toString(),
        });
      }
    }
    return out;
  }

  /// Water pricing type of the branch (PER_PERSON / PER_ROOM / PER_M3).
  String get _branchWaterPricingType {
    final b = widget.branch;
    if (b != null && b is! Map) {
      try {
        return b.waterPricingType?.toString() ?? '';
      } catch (_) {}
    }
    return _branchMap['waterPricingType']?.toString() ?? '';
  }

  /// Maps a canonical price key to the JSON key used by BranchModel.toJson().
  static const Map<String, String> _branchJsonAliases = {
    'internetPrice': 'internetFee',
    'parkingPrice': 'parkingFee',
    'trashPrice': 'garbageFee',
  };

  /// Amenity-name prefixes used to derive a service fee from the branch's
  /// `branchAmenities` metadata (stored inside the branch description JSON).
  /// This is the reliable fallback when the dedicated fee column is 0/null
  /// (e.g. branches created before the fee mapping was added).
  static const Map<String, List<String>> _feeAmenityPrefixes = {
    'internetPrice': ['wifi', 'internet', 'mạng'],
    'parkingPrice': ['bãi để xe', 'giữ xe', 'gửi xe', 'đỗ xe', 'bãi giữ xe'],
    'trashPrice': ['vệ sinh', 'rác', 'thu gom'],
    // Các tiện ích thu phí khác được gộp vào phí dịch vụ chung.
    'serviceFee': ['dịch vụ', 'bảo vệ', 'thang máy', 'quản lý', 'điện', 'nước'],
  };

  /// Returns the max price among branch amenities whose name matches one of
  /// [prefixes]. Reads from the unified [_branchAmenities] getter (root
  /// `branchAmenities` OR the `description` JSON) and ignores amenities marked
  /// `chargeType: 'free'` so a stale price never leaks into the fee table.
  double _feeFromBranchAmenities(List<String> prefixes) {
    double best = 0;
    for (final a in _branchAmenities) {
      final name = (a['name'] ?? '').toString().toLowerCase();
      if (name.isEmpty) continue;
      if (!prefixes.any((p) => name.contains(p))) continue;
      final chargeType = (a['chargeType'] ?? 'free').toString();
      if (chargeType == 'free') continue;
      final price = double.tryParse((a['price'] ?? 0).toString()) ?? 0;
      if (price > best) best = price;
    }
    return best;
  }

  /// Reads a service-price field from the branch, falling back to the branch
  /// amenity metadata and finally to the room (legacy data).
  dynamic _priceField(String key) {
    final b = widget.branch;
    // 1) Direct property access on a typed BranchModel.
    if (b != null && b is! Map) {
      try {
        switch (key) {
          case 'electricityPrice':
            return b.electricityPrice;
          case 'waterPrice':
            return b.waterPrice;
          case 'serviceFee':
            return b.serviceFee;
          case 'internetPrice':
            return b.internetPrice;
          case 'parkingPrice':
            return b.parkingPrice;
          case 'trashPrice':
            return b.trashPrice;
        }
      } catch (_) {}
    }
    // 2) Map lookup (canonical key, then JSON alias).
    final map = _branchMap;
    final direct = map[key];
    if (direct != null && direct is num && direct > 0) return direct;
    final alias = _branchJsonAliases[key];
    if (alias != null && map[alias] is num && (map[alias] as num) > 0) {
      return map[alias];
    }
    // 3) Derive from the branch's `branchAmenities` metadata (reliable source
    //    of the prices the owner actually entered during branch creation).
    final prefixes = _feeAmenityPrefixes[key];
    if (prefixes != null) {
      final derived = _feeFromBranchAmenities(prefixes);
      if (derived > 0) return derived;
    }
    // 4) Keep a zero value if the branch explicitly provided one.
    if (direct != null) return direct;
    if (alias != null && map[alias] != null) return map[alias];
    // 5) Legacy fallback: price stored on the room itself.
    return _roomField(key);
  }

  // Furniture/amenity code → label + emoji (covers every code emitted by
  // the room-config sheet, including legacy aliases).
  static const Map<String, Map<String, String>> _furnitureMap = {
    'AC': {'label': 'Điều hoà', 'emoji': '❄️'},
    'MAY_LANH': {'label': 'Điều hoà', 'emoji': '❄️'},
    'NUOC_NONG': {'label': 'Nóng lạnh', 'emoji': '🚿'},
    'BINH_NONG_LANH': {'label': 'Nóng lạnh', 'emoji': '🚿'},
    'GIUONG': {'label': 'Giường', 'emoji': '🛏️'},
    'TU_QUAN_AO': {'label': 'Tủ áo', 'emoji': '🗄️'},
    'TU_QUAN_AO_QUAN_JEAN': {'label': 'Tủ áo', 'emoji': '🗄️'},
    'BAN_HOC': {'label': 'Bàn học', 'emoji': '📚'},
    'BAN_LAM_VIEC': {'label': 'Bàn làm việc', 'emoji': '💻'},
    'TU_LANH': {'label': 'Tủ lạnh', 'emoji': '🧊'},
    'MAY_GIAT': {'label': 'Máy giặt', 'emoji': '🫧'},
    'BEP': {'label': 'Bếp', 'emoji': '🍳'},
    'BEP_DIEN': {'label': 'Bếp điện', 'emoji': '🍳'},
    'WIFI': {'label': 'WiFi', 'emoji': '📡'},
    'THANG_MAY': {'label': 'Thang máy', 'emoji': '🛗'},
    'BAI_XE': {'label': 'Bãi xe', 'emoji': '🅿️'},
    'CAMERA': {'label': 'Camera', 'emoji': '📹'},
    'BAO_VE': {'label': 'Bảo vệ 24/7', 'emoji': '🛡️'},
    'BAN_CONG': {'label': 'Ban công', 'emoji': '🌤️'},
    'CUA_SO': {'label': 'Cửa sổ', 'emoji': '🪟'},
    'GAC_LUNG': {'label': 'Gác lửng', 'emoji': '🪜'},
    'NHA_BEP': {'label': 'Nhà bếp', 'emoji': '🍽️'},
    'NHA_VE_SINH': {'label': 'WC riêng', 'emoji': '🚽'},
    'CHO_DE_XE': {'label': 'Chỗ để xe', 'emoji': '🛵'},
    'THU_CUNG': {'label': 'Cho nuôi thú cưng', 'emoji': '🐾'},
    'MAY_NUOC_NONG': {'label': 'Máy nước nóng', 'emoji': '♨️'},
    'TU_BEP': {'label': 'Tủ bếp', 'emoji': '🗄️'},
    'QUAT_TRAN': {'label': 'Quạt trần', 'emoji': '🌀'},
  };

  static const Map<String, String> _furnitureLevelMap = {
    'TRONG': 'Không nội thất',
    'CO_BAN': 'Nội thất cơ bản',
    'DAY_DU': 'Nội thất đầy đủ',
    'CAO_CAP': 'Nội thất cao cấp',
  };

  static const Map<String, String> _directionMap = {
    'DONG': 'Hướng Đông',
    'TAY': 'Hướng Tây',
    'NAM': 'Hướng Nam',
    'BAC': 'Hướng Bắc',
    'DONG_NAM': 'Hướng Đông Nam',
    'DONG_BAC': 'Hướng Đông Bắc',
    'TAY_NAM': 'Hướng Tây Nam',
    'TAY_BAC': 'Hướng Tây Bắc',
  };

  /// The nested `detailedInfo` map written by the room-config sheet.
  Map<String, dynamic> get _detailedInfo {
    final raw = _roomField('detailedInfo');
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.trim().startsWith('{')) {
      try {
        return Map<String, dynamic>.from(jsonDecode(raw) as Map);
      } catch (_) {}
    }
    return const {};
  }

  /// Reads a key from `detailedInfo` first, then falls back to the top level.
  dynamic _roomFieldDeep(String key) {
    final d = _detailedInfo[key];
    if (d != null) return d;
    return _roomField(key);
  }

  static bool _truthy(dynamic v) =>
      v == true || v == 'true' || v == 1 || v == '1';

  /// Parse furniture/amenities from room data (List, Map, or JSON/CSV string).
  /// Reads `detailedInfo.furnitureItems` (written by the room-config sheet)
  /// as well as top-level `furniture`/`amenities`/`facilities`.
  List<String> get _amenities {
    final raw =
        _roomFieldDeep('furnitureItems') ??
        _roomField('furniture') ??
        _roomField('amenities') ??
        _roomField('facilities');
    List<String> list = [];
    if (raw is List) {
      list = raw.map((e) => e.toString()).toList();
    } else if (raw is Map) {
      list = raw.keys.map((e) => e.toString()).toList();
    } else if (raw is String && raw.trim().isNotEmpty) {
      final s = raw.trim();
      if (s.startsWith('[')) {
        try {
          final decoded = jsonDecode(s) as List;
          list = decoded.map((e) => e.toString()).toList();
        } catch (_) {
          list = s
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } else {
        list = s
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    // Add boolean-derived amenities
    if (_hasBalcony) list.add('BAN_CONG');
    if (_hasWindow) list.add('CUA_SO');
    if (_hasKitchen) list.add('NHA_BEP');
    if (_hasMezzanine) list.add('GAC_LUNG');
    // De-duplicate while preserving order
    final seen = <String>{};
    return list.where((e) => seen.add(e)).toList();
  }

  bool get _hasBalcony => _truthy(_roomFieldDeep('hasBalcony'));
  bool get _hasWindow => _truthy(_roomFieldDeep('hasWindow'));
  bool get _hasKitchen => _truthy(_roomFieldDeep('hasKitchen'));
  bool get _hasMezzanine => _truthy(_roomFieldDeep('hasMezzanine'));
  bool get _isSelfContained => _truthy(_roomFieldDeep('isSelfContained'));

  String get _furnitureLevelLabel =>
      _furnitureLevelMap[_roomFieldDeep('furnitureLevel')?.toString() ?? ''] ??
      '';

  String get _roomTypeLabel {
    final raw = _roomFieldDeep('roomType')?.toString() ?? '';
    if (raw.isEmpty) return '';
    // Dùng nguồn chân lý duy nhất: MÃ canonical → NHÃN hiển thị.
    return RoomTypeCodes.labelOf(raw);
  }

  String get _orientationLabel {
    final raw =
        (_roomFieldDeep('orientation') ?? _roomFieldDeep('direction'))
            ?.toString() ??
        '';
    return _directionMap[raw] ?? '';
  }

  /// Tên phòng — ưu tiên `detailedInfo.roomName` (chủ nhà nhập ở bước cấu hình
  /// phòng), rồi tới `roomName`/`name`/`code` ở root.
  String get _roomName {
    final v =
        _roomFieldDeep('roomName') ?? _roomField('name') ?? _roomField('code');
    final s = v?.toString().trim() ?? '';
    return s.isEmpty ? 'Phòng' : s;
  }

  String get _floor {
    final v = _roomFieldDeep('floor');
    return v?.toString().trim() ?? '';
  }

  double get _area {
    final v = _roomFieldDeep('area') ?? _roomField('floorArea');
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  double get _mezzanineArea {
    final v = _roomFieldDeep('mezzanineArea');
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  double get _deposit {
    final v = _roomFieldDeep('deposit') ?? _roomField('baseDeposit');
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }

  /// Nội thất đã dịch sang nhãn tiếng Việt (kèm emoji), đã loại trùng.
  List<Map<String, String>> get _furnitureChips {
    final out = <Map<String, String>>[];
    final seen = <String>{};
    for (final code in _amenities) {
      final key = code.toUpperCase().replaceAll(' ', '_');
      final entry = _furnitureMap[key];
      final label = entry?['label'] ?? code;
      final emoji = entry?['emoji'] ?? '📦';
      if (label.trim().isEmpty) continue;
      if (!seen.add(label)) continue;
      out.add({'emoji': emoji, 'label': label});
    }
    return out;
  }

  int? get _maxOccupants {
    final v = _roomFieldDeep('maxOccupants') ?? _roomField('maxGuests');
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '');
  }

  int? get _maxVehicles {
    final v = _roomFieldDeep('maxVehicles');
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '');
  }

  int? get _electricIndex {
    final v =
        _roomFieldDeep('electricIndexInit') ?? _roomFieldDeep('electricIndex');
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '');
  }

  int? get _waterIndex {
    final v = _roomFieldDeep('waterIndexInit') ?? _roomFieldDeep('waterIndex');
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '');
  }

  /// Feature photos (WC / balcony / window / kitchen / meters) stored by the
  /// room-config sheet under `detailedInfo.featurePhotos`.
  List<String> get _featurePhotos {
    final raw = _roomFieldDeep('featurePhotos');
    List<String> out = [];
    if (raw is List) {
      out = raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    } else if (raw is Map) {
      raw.forEach((_, v) {
        if (v is List) {
          out.addAll(v.map((e) => e.toString()).where((e) => e.isNotEmpty));
        } else if (v != null && v.toString().isNotEmpty) {
          out.add(v.toString());
        }
      });
    } else if (raw is String && raw.trim().isNotEmpty) {
      final s = raw.trim();
      if (s.startsWith('[')) {
        try {
          out = (jsonDecode(s) as List)
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList();
        } catch (_) {
          out = s
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } else {
        out = s
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    return out
        .map((e) => ImageUrlHelper.buildUrl(e) ?? e)
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _promptUpdateDeposit(int currentPrice) async {
    final fmt = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '',
      decimalDigits: 0,
    );
    final suggested = (currentPrice * 1.0).round();
    final controller = TextEditingController(
      text: _currentDeposit != null
          ? fmt.format(_currentDeposit).trim()
          : fmt.format(suggested).trim(),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cập nhật tiền cọc',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Giá thuê đã thay đổi. Bạn có muốn cập nhật lại tiền cọc cho phòng này không?',
              style: TextStyle(color: AppTheme.kTextSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Tiền cọc (đ)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
              onChanged: (val) {
                final number =
                    int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                final newText = fmt.format(number).trim();
                if (newText != val) {
                  controller.value = TextEditingValue(
                    text: newText,
                    selection: TextSelection.collapsed(offset: newText.length),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Bỏ qua',
              style: TextStyle(color: AppTheme.kTextSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.kBrand,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final parsed =
                  double.tryParse(
                    controller.text.replaceAll(RegExp(r'[^0-9]'), ''),
                  ) ??
                  0;
              Navigator.pop(ctx, parsed);
            },
            child: const Text(
              'Cập nhật',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      setState(() => _currentDeposit = result);
    }
  }

  Future<void> _pickImages() async {
    final remaining = 10 - _images.length;
    if (remaining <= 0) {
      ToastUtils.show(context, 'Chỉ được chọn tối đa 10 ảnh', isError: true);
      return;
    }
    await ImagePickerUtils.showPicker(
      context: context,
      limit: remaining,
      onPicked: (files) {
        if (!mounted) return;
        setState(() {
          for (final f in files) {
            _images.add(_ImageData(false, f.path));
          }
        });
      },
    );
  }

  void _showImageActions(int index) {
    if (index < 0 || index >= _images.length) return;
    unawaited(
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Material(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SafeArea(
            bottom: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                if (index != 0)
                  ListTile(
                    leading: const Icon(
                      CupertinoIcons.star_fill,
                      color: AppTheme.kBrand,
                    ),
                    title: const Text(
                      'Đặt làm ảnh bìa',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        final item = _images.removeAt(index);
                        _images.insert(0, item);
                      });
                    },
                  ),
                ListTile(
                  leading: const Icon(
                    CupertinoIcons.trash,
                    color: AppTheme.kError,
                  ),
                  title: const Text(
                    'Xóa ảnh',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.kError,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _images.removeAt(index));
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _savePost({required bool isActive}) async {
    if (_titleController.text.trim().isEmpty) {
      ToastUtils.show(context, 'Vui lòng nhập tiêu đề bài đăng', isError: true);
      return;
    }

    final price =
        double.tryParse(
          _basePriceController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        0;
    if (price <= 0) {
      ToastUtils.show(context, 'Vui lòng nhập giá thuê hợp lệ', isError: true);
      return;
    }

    final List<String> orderedImages = _images
        .where((e) => e.isNetwork)
        .map((e) => e.path)
        .toList();
    final Map<String, dynamic> currentPost = {
      ...(widget.post != null
          ? Map<String, dynamic>.from(widget.post)
          : <String, dynamic>{}),
      'postTitle': _titleController.text.trim(),
      'postDescription': _descriptionController.text.trim(),
      'rentingPrice': price,
      'deposit': _currentDeposit,
      'price': price,
      'originalPrice': price,
      'status': isActive ? 'ACTIVE' : 'DRAFT',
      'coverImageUrl': orderedImages.isNotEmpty ? orderedImages.first : null,
      'postImages': orderedImages.length > 1
          ? orderedImages.skip(1).join(',')
          : null,
    };

    final updatedRoom = widget.room is Map
        ? Map<String, dynamic>.from(widget.room)
        : widget.room.toJson();
    updatedRoom['price'] = price;
    if (_currentDeposit != null) {
      updatedRoom['deposit'] = _currentDeposit;
      updatedRoom['baseDeposit'] = _currentDeposit;
    }
    if (widget.branchLat != null) updatedRoom['latitude'] = widget.branchLat;
    if (widget.branchLng != null) updatedRoom['longitude'] = widget.branchLng;

    unawaited(
      context.push(
        '/owner/post-preview',
        extra: {
          'room': updatedRoom,
          'post': currentPost,
          'previewImages': _images
              .map((e) => e.isNetwork ? e.path : File(e.path))
              .toList(),
          'branch': widget.branch,
          'branchAddress': widget.branchAddress,
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    final fmt = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '',
      decimalDigits: 0,
    );
    final initRoomData = widget.room is Map
        ? widget.room
        : widget.room.toJson();
    // BUGFIX (data): trước đây ép `as num?` — nếu backend trả String
    // ("3000000") thì ném TypeError ngay trong initState và màn hình
    // chỉnh sửa không mở được. Coerce an toàn.
    _initialBasePrice = _asNum(initRoomData['price']).toInt();
    _basePriceController.text = fmt.format(_initialBasePrice).trim();

    final depositRaw = initRoomData['deposit'] ?? initRoomData['baseDeposit'];
    if (depositRaw != null) {
      _currentDeposit = double.tryParse(depositRaw.toString());
    }

    _basePriceFocusNode.addListener(() {
      if (!_basePriceFocusNode.hasFocus) {
        final currentPrice =
            int.tryParse(
              _basePriceController.text.replaceAll(RegExp(r'[^0-9]'), ''),
            ) ??
            0;
        if (currentPrice != _initialBasePrice && currentPrice > 0) {
          unawaited(_promptUpdateDeposit(currentPrice));
        }
      }
    });

    if (widget.post != null) {
      _titleController.text = widget.post['postTitle'] ?? '';
      _descriptionController.text = widget.post['postDescription'] ?? '';

      final cover = widget.post['coverImageUrl'];
      if (cover != null && cover.toString().isNotEmpty) {
        final url = ImageUrlHelper.buildUrl(cover.toString()) ?? '';
        if (url.isNotEmpty) _images.add(_ImageData(true, url));
      }

      final dynamic imagesField = widget.post['postImages'];
      if (imagesField != null) {
        List<String> order = [];
        if (imagesField is List) {
          order = imagesField.map((e) => e.toString()).toList();
        } else if (imagesField is String && imagesField.isNotEmpty) {
          order = List<String>.from(
            imagesField.split(',').where((s) => s.isNotEmpty),
          );
        }
        for (var img in order) {
          final resolved = ImageUrlHelper.buildUrl(img) ?? '';
          if (resolved.isNotEmpty && !_images.any((e) => e.path == resolved)) {
            _images.add(_ImageData(true, resolved));
          }
        }
      }

      // Fallback: nếu bài đăng chưa có ảnh nào, tự động lấy ảnh của phòng
      if (_images.isEmpty) {
        final String? roomImages = widget.room is Map
            ? widget.room['roomImages']
            : widget.room.roomImages;
        if (roomImages != null && roomImages.isNotEmpty) {
          try {
            if (roomImages.trim().startsWith('[')) {
              final decoded = jsonDecode(roomImages) as List;
              for (var img in decoded) {
                final url = ImageUrlHelper.buildUrl(img.toString()) ?? '';
                if (url.isNotEmpty) _images.add(_ImageData(true, url));
              }
            } else {
              _images.addAll(
                roomImages
                    .split(',')
                    .map((e) => ImageUrlHelper.buildUrl(e.trim()) ?? '')
                    .where((e) => e.isNotEmpty)
                    .map((e) => _ImageData(true, e)),
              );
            }
          } catch (e) {
            debugPrint(
              'Image parse error: $e',
            ); // ignore parse error, skip images
          }
        }
      }
    } else {
      // Default title
      _titleController.text = 'Cho thuê phòng trọ đẹp, tiện nghi, ở ngay!';

      // Mô tả được nhập tại bước đăng bài (không lấy từ phòng nữa).
      _descriptionController.text = '';

      final String? roomImages = widget.room.roomImages;
      if (roomImages != null && roomImages.isNotEmpty) {
        try {
          if (roomImages.trim().startsWith('[')) {
            final decoded = jsonDecode(roomImages) as List;
            for (var img in decoded) {
              final url = ImageUrlHelper.buildUrl(img.toString()) ?? '';
              if (url.isNotEmpty) _images.add(_ImageData(true, url));
            }
          } else {
            _images.addAll(
              roomImages
                  .split(',')
                  .map((e) => ImageUrlHelper.buildUrl(e.trim()) ?? '')
                  .where((e) => e.isNotEmpty)
                  .map((e) => _ImageData(true, e)),
            );
          }
        } catch (e) {
          debugPrint('Image parse error (init): '); // ignore, fall through
        }
      }
    }
  }

  Widget _buildAnimatedSection(int index, Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutQuart,
      builder: (context, value, _) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
    );
  }

  /// Tiêu đề section thống nhất (icon + label + phụ đề tuỳ chọn).
  Widget _buildSectionHeader(
    IconData icon,
    String title, {
    String? subtitle,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.kBrand, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.kTextSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    final roomData = widget.room is Map ? widget.room : widget.room.toJson();

    return Scaffold(
      backgroundColor: AppTheme.kBackgroundLight, // Nền xám nhạt cực êm
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              // Sliver App Bar với Gradient Sky Blue
              SliverAppBar(
                floating: false,
                pinned: true,
                elevation: 10,
                shadowColor: AppTheme.kBrand.withValues(alpha: 0.3),
                backgroundColor: AppTheme.kBrand,
                centerTitle: true,
                title: Text(
                  widget.post == null ? 'Tạo tin đăng' : 'Chỉnh sửa tin đăng',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
                flexibleSpace: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.kBrandLight, AppTheme.kBrandDeep],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(CupertinoIcons.back, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),

              // Main Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    24,
                    20,
                    120,
                  ), // padding dưới lớn để không bị che bởi BottomBar
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 0. Hero — ảnh bìa phòng + giá
                      _buildAnimatedSection(0, _buildHeroHeader(fmt)),
                      const SizedBox(height: 28),

                      // 1. Tiêu đề
                      _buildAnimatedSection(
                        1,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              CupertinoIcons.textbox,
                              'Tiêu đề bài đăng *',
                              subtitle:
                                  'Ngắn gọn, nêu bật loại phòng và điểm hấp dẫn nhất.',
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _titleController,
                                maxLength: 50,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                                decoration: InputDecoration(
                                  hintText:
                                      'Ví dụ: Cho thuê phòng trọ cao cấp, giá sinh viên',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.normal,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.all(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 2. Hình ảnh
                      _buildAnimatedSection(
                        1,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              CupertinoIcons.photo_on_rectangle,
                              'Hình ảnh bài đăng',
                              subtitle:
                                  'Ảnh đầu tiên là ảnh bìa. Kéo thả để sắp xếp, chạm để đổi ảnh bìa hoặc xoá.',
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.kBrand.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  '${_images.length}/10',
                                  style: const TextStyle(
                                    color: AppTheme.kBrand,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 140,
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      unawaited(HapticFeedback.lightImpact());
                                      if (_images.length < 10) {
                                        unawaited(_pickImages());
                                      }
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      width: 110,
                                      margin: const EdgeInsets.only(right: 16),
                                      decoration: BoxDecoration(
                                        color: _images.length >= 10
                                            ? const Color(0xFFF1F5F9)
                                            : const Color(0xFFF2F8FF),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _images.length >= 10
                                              ? const Color(0xFFE2E8F0)
                                              : const Color(0xFF9CCBFF),
                                          width: 1.5,
                                          style: BorderStyle.solid,
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            CupertinoIcons.add_circled_solid,
                                            color: _images.length >= 10
                                                ? const Color(0xFF94A3B8)
                                                : AppTheme.kBrand,
                                            size: 32,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Thêm ảnh',
                                            style: TextStyle(
                                              color: _images.length >= 10
                                                  ? const Color(0xFF94A3B8)
                                                  : AppTheme.kBrand,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: _images.isEmpty
                                        ? Center(
                                            child: Text(
                                              'Chưa có ảnh nào',
                                              style: TextStyle(
                                                color: Colors.grey.shade400,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          )
                                        : ReorderableListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: _images.length,
                                            onReorderItem: (oldIndex, newIndex) {
                                              unawaited(
                                                HapticFeedback.lightImpact(),
                                              );
                                              setState(() {
                                                final item = _images.removeAt(
                                                  oldIndex,
                                                );
                                                _images.insert(newIndex, item);
                                              });
                                            },
                                            buildDefaultDragHandles: false,
                                            proxyDecorator:
                                                (child, index, animation) =>
                                                    Material(
                                                      elevation: 12,
                                                      color: Colors.transparent,
                                                      child: child,
                                                    ),
                                            itemBuilder: (context, index) {
                                              final e = _images[index];
                                              return Padding(
                                                key: ValueKey(
                                                  e.hashCode.toString() +
                                                      index.toString(),
                                                ),
                                                padding: const EdgeInsets.only(
                                                  right: 16,
                                                ),
                                                child: GestureDetector(
                                                  onTap: () {
                                                    unawaited(
                                                      HapticFeedback.selectionClick(),
                                                    );
                                                    _showImageActions(index);
                                                  },
                                                  child: Container(
                                                    width: 140,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            20,
                                                          ),
                                                      border: index == 0
                                                          ? Border.all(
                                                              color: AppTheme
                                                                  .kBrand,
                                                              width: 2,
                                                            )
                                                          : null,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withValues(
                                                                alpha: 0.06,
                                                              ),
                                                          blurRadius: 10,
                                                          offset: const Offset(
                                                            0,
                                                            4,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Stack(
                                                      fit: StackFit.expand,
                                                      children: [
                                                        ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                index == 0
                                                                    ? 18
                                                                    : 20,
                                                              ),
                                                          child: e.isNetwork
                                                              ? (e.path.startsWith(
                                                                      'base64:',
                                                                    )
                                                                    ? Image.memory(
                                                                        base64Decode(
                                                                          e.path.substring(
                                                                            7,
                                                                          ),
                                                                        ),
                                                                        fit: BoxFit
                                                                            .cover,
                                                                        errorBuilder:
                                                                            (
                                                                              _,
                                                                              error,
                                                                              ___,
                                                                            ) => Container(
                                                                              color: AppTheme.kBorderColor,
                                                                              child: const Center(
                                                                                child: Text(
                                                                                  'Error',
                                                                                ),
                                                                              ),
                                                                            ),
                                                                      )
                                                                    : Image.network(
                                                                        e.path,
                                                                        fit: BoxFit
                                                                            .cover,
                                                                        errorBuilder:
                                                                            (
                                                                              _,
                                                                              error,
                                                                              ___,
                                                                            ) => Container(
                                                                              color: AppTheme.kBorderColor,
                                                                              padding: const EdgeInsets.all(
                                                                                4,
                                                                              ),
                                                                              child: Center(
                                                                                child: Text(
                                                                                  'Error:\n${e.path}',
                                                                                  style: const TextStyle(
                                                                                    fontSize: 8,
                                                                                    color: CupertinoColors.systemRed,
                                                                                  ),
                                                                                  textAlign: TextAlign.center,
                                                                                ),
                                                                              ),
                                                                            ),
                                                                      ))
                                                              : ResponsiveFileImage(
                                                                  File(e.path),
                                                                  fit: BoxFit
                                                                      .cover,
                                                                ),
                                                        ),
                                                        if (index == 0)
                                                          Positioned(
                                                            bottom: 0,
                                                            left: 0,
                                                            right: 0,
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets.symmetric(
                                                                    vertical: 6,
                                                                  ),
                                                              decoration: const BoxDecoration(
                                                                color: AppTheme
                                                                    .kBrand,
                                                                borderRadius:
                                                                    BorderRadius.vertical(
                                                                      bottom:
                                                                          Radius.circular(
                                                                            18,
                                                                          ),
                                                                    ),
                                                              ),
                                                              child: const Text(
                                                                'Ảnh bìa',
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style: TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 11,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 3. Giá thuê (chỉ nhập giá — thông số phòng đã có ở hero & phần review)
                      _buildAnimatedSection(
                        2,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              CupertinoIcons.money_dollar_circle_fill,
                              'Giá thuê',
                              subtitle:
                                  'Giá niêm yết cho phòng này. Đổi giá sẽ hỏi cập nhật lại tiền cọc.',
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.money_dollar_circle_fill,
                                    color: AppTheme.kSuccess,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Giá gốc',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextField(
                                      controller: _basePriceController,
                                      focusNode: _basePriceFocusNode,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.kSuccess,
                                        fontSize: 16,
                                      ),
                                      decoration: const InputDecoration(
                                        suffixText: ' đ/tháng',
                                        suffixStyle: TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onChanged: (val) {
                                        if (val.isEmpty) return;
                                        final number =
                                            int.tryParse(
                                              val.replaceAll(
                                                RegExp(r'[^0-9]'),
                                                '',
                                              ),
                                            ) ??
                                            0;
                                        final fmt = NumberFormat.currency(
                                          locale: 'vi_VN',
                                          symbol: '',
                                          decimalDigits: 0,
                                        );
                                        final newText = fmt
                                            .format(number)
                                            .trim();
                                        if (newText != val) {
                                          _basePriceController
                                              .value = TextEditingValue(
                                            text: newText,
                                            selection: TextSelection.collapsed(
                                              offset: newText.length,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // 4. Thông tin phòng đầy đủ (chỉ xem) — toàn bộ dữ liệu 5 bước tạo chi nhánh
                      //    (bao gồm cả bảng giá dịch vụ theo chi nhánh, không lặp lại ở trên)
                      _buildAnimatedSection(
                        3,
                        _buildRoomInfoReview(roomData, fmt),
                      ),
                      const SizedBox(height: 32),

                      // 5. Mô tả chi tiết (nhập tại đây khi đăng bài)
                      _buildAnimatedSection(
                        4,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                              CupertinoIcons.doc_text_fill,
                              'Mô tả chi tiết',
                              subtitle:
                                  'Chỉ dùng cho bài đăng. AI tự loại bỏ thông tin nhạy cảm (SĐT, địa chỉ chi tiết).',
                              trailing: GestureDetector(
                                onTap: _generateAiDescription,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF6366F1),
                                        Color(0xFF8B5CF6),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        CupertinoIcons.sparkles,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        'AI viết giúp',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _descriptionController,
                                maxLines: 8,
                                minLines: 5,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: Color(0xFF334155),
                                ),
                                decoration: const InputDecoration(
                                  hintText:
                                      'Giới thiệu về phòng: vị trí, tiện ích nổi bật, đối tượng phù hợp, nội quy...',
                                  hintStyle: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 14,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
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
            ],
          ),

          // 7. Sticky Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).padding.bottom + 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                border: Border(
                  top: BorderSide(
                    color: const Color(0xFFE2E8F0).withValues(alpha: 0.5),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Nút Xem Trước
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () {
                              unawaited(HapticFeedback.lightImpact());
                              final List<String> orderedImages = _images
                                  .where((e) => e.isNetwork)
                                  .map((e) => e.path)
                                  .toList();
                              final Map<String, dynamic> currentPost = {
                                ...(widget.post != null
                                    ? Map<String, dynamic>.from(widget.post)
                                    : <String, dynamic>{}),
                                'postTitle': _titleController.text,
                                'coverImageUrl': orderedImages.isNotEmpty
                                    ? orderedImages.first
                                    : null,
                                'postImages': orderedImages.length > 1
                                    ? orderedImages.skip(1).join(',')
                                    : null,
                                'postDescription': _descriptionController.text,
                                'price':
                                    double.tryParse(
                                      _basePriceController.text.replaceAll(
                                        RegExp(r'[^0-9]'),
                                        '',
                                      ),
                                    ) ??
                                    0.0,
                                'originalPrice':
                                    double.tryParse(
                                      _basePriceController.text.replaceAll(
                                        RegExp(r'[^0-9]'),
                                        '',
                                      ),
                                    ) ??
                                    0.0,
                              };
                              final updatedRoom = widget.room is Map
                                  ? Map<String, dynamic>.from(widget.room)
                                  : widget.room.toJson();
                              updatedRoom['price'] =
                                  double.tryParse(
                                    _basePriceController.text.replaceAll(
                                      RegExp(r'[^0-9]'),
                                      '',
                                    ),
                                  ) ??
                                  0.0;
                              if (_currentDeposit != null) {
                                updatedRoom['deposit'] = _currentDeposit;
                                updatedRoom['baseDeposit'] = _currentDeposit;
                              }
                              if (widget.branchLat != null) {
                                updatedRoom['latitude'] = widget.branchLat;
                              }

                              if (widget.branchLng != null) {
                                updatedRoom['longitude'] = widget.branchLng;
                              }

                              unawaited(
                                context.push(
                                  '/owner/post-preview',
                                  extra: {
                                    'room': updatedRoom,
                                    'post': currentPost,
                                    'previewImages': _images
                                        .map(
                                          (e) => e.isNetwork
                                              ? e.path
                                              : File(e.path),
                                        )
                                        .toList(),
                                    'branch': widget.branch,
                                    'branchAddress': widget.branchAddress,
                                  },
                                ),
                              );
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F8FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.kBrandLight.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.eye_solid,
                              color: AppTheme.kBrandDeep,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'XEM TRƯỚC',
                              style: TextStyle(
                                color: AppTheme.kBrandDeep,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Nút Đăng Tin Ngay
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () {
                              unawaited(HapticFeedback.mediumImpact());
                              unawaited(_savePost(isActive: true));
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.kBrandLight, AppTheme.kBrandDeep],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.kBrand.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.post != null
                                  ? CupertinoIcons.check_mark_circled_solid
                                  : CupertinoIcons.rocket_fill,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.post != null ? 'CẬP NHẬT' : 'ĐĂNG TIN',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
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
        ],
      ),
    );
  }

  // ── Hero header: ảnh bìa + giá (thông số chi tiết đã có ở phần review) ──
  Widget _buildHeroHeader(NumberFormat fmt) {
    final cover = _images.isNotEmpty ? _images.first : null;
    final price = _initialBasePrice;

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppTheme.kBrandLight, AppTheme.kBrandDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kBrand.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Cover image (nếu có) làm nền mờ
          if (cover != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.28,
                child: cover.isNetwork
                    ? Image.network(
                        cover.path,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      )
                    : ResponsiveFileImage(File(cover.path), fit: BoxFit.cover),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.kBrandDeep.withValues(alpha: 0.55),
                    AppTheme.kBrandDeep.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        CupertinoIcons.bed_double_fill,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _roomName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_branchName.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              _branchName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  price > 0 ? '${fmt.format(price)}/tháng' : 'Chưa có giá',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared card shell ───────────────────────────────────────────
  Widget _reviewCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.kBrand.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.kBrand, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.kTextSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
              fontSize: 13,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _divider() => const Divider(height: 1, color: Color(0xFFF1F5F9));

  Widget _chip(String emoji, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFE5E7EB)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF374151),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  // ── Full room info review (read-only) ───────────────────────────
  Widget _buildRoomInfoReview(Map<String, dynamic> roomData, NumberFormat fmt) {
    final amenities = _amenities;
    final featurePhotos = _featurePhotos;
    final branchAmenities = _branchAmenities;
    final area = _area;
    final mezzanine = _mezzanineArea;
    // Service prices come from the BRANCH (see _priceField).
    final serviceFee = _priceField('serviceFee');
    final internetPrice = _priceField('internetPrice');
    final parkingPrice = _priceField('parkingPrice');
    final trashPrice = _priceField('trashPrice');
    final electricityPrice = _priceField('electricityPrice');
    final waterPrice = _priceField('waterPrice');
    final waterPricingType = _branchWaterPricingType;

    String money(dynamic v, String unit) =>
        v is num && v > 0 ? '${fmt.format(v)}$unit' : 'Miễn phí';

    final waterUnit = waterPricingType == 'PER_PERSON'
        ? '/người'
        : (waterPricingType == 'PER_ROOM' ? '/phòng' : '/m³');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          CupertinoIcons.house_fill,
          'Thông tin phòng đầy đủ',
          subtitle:
              'Toàn bộ dữ liệu bạn đã cấu hình trong 5 bước tạo chi nhánh — người xem sẽ thấy khi duyệt tin.',
        ),
        const SizedBox(height: 14),

        // ── Đặc điểm & cấu trúc ──
        _reviewCard(
          title: 'ĐẶC ĐIỂM & CẤU TRÚC',
          icon: CupertinoIcons.building_2_fill,
          children: [
            _infoRow('Tên phòng', _roomName),
            _divider(),
            _infoRow(
              'Loại phòng',
              _roomTypeLabel.isNotEmpty ? _roomTypeLabel : 'Phòng thường',
            ),
            _divider(),
            _infoRow(
              'Diện tích',
              area > 0 ? '${area.toStringAsFixed(0)} m²' : 'Chưa nhập',
            ),
            _divider(),
            _infoRow(
              'Gác lửng',
              _hasMezzanine
                  ? (mezzanine > 0
                        ? 'Có • ${mezzanine.toStringAsFixed(0)} m²'
                        : 'Có')
                  : 'Không có',
            ),
            _divider(),
            _infoRow(
              'Vệ sinh',
              _isSelfContained ? 'Khép kín (WC riêng)' : 'WC chung',
            ),
            _divider(),
            _infoRow('Nhà bếp', _hasKitchen ? 'Có bếp riêng' : 'Không có'),
            _divider(),
            _infoRow(
              'Hướng phòng',
              _orientationLabel.isNotEmpty
                  ? _orientationLabel
                  : 'Không xác định',
            ),
            _divider(),
            _infoRow('Ban công', _hasBalcony ? 'Có ban công' : 'Không có'),
            _divider(),
            _infoRow('Cửa sổ', _hasWindow ? 'Có cửa sổ' : 'Không có'),
            if (_floor.isNotEmpty) ...[
              _divider(),
              _infoRow('Tầng', 'Tầng $_floor'),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // ── Sức chứa & nội thất ──
        _reviewCard(
          title: 'SỨC CHỨA & NỘI THẤT',
          icon: CupertinoIcons.person_2_fill,
          children: [
            _infoRow(
              'Người ở tối đa',
              _maxOccupants != null && _maxOccupants! > 0
                  ? '$_maxOccupants người'
                  : 'Không giới hạn',
            ),
            _divider(),
            _infoRow(
              'Xe để tối đa',
              _maxVehicles != null && _maxVehicles! > 0
                  ? '$_maxVehicles xe'
                  : 'Không giới hạn',
            ),
            _divider(),
            _infoRow(
              'Mức nội thất',
              _furnitureLevelLabel.isNotEmpty
                  ? _furnitureLevelLabel
                  : 'Chưa cập nhật',
            ),
            _divider(),
            _infoRow(
              'Tiền cọc',
              _deposit > 0 ? fmt.format(_deposit) : 'Thỏa thuận',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Giá dịch vụ ──
        _reviewCard(
          title: 'GIÁ DỊCH VỤ (THEO CHI NHÁNH)',
          icon: CupertinoIcons.money_dollar_circle_fill,
          children: [
            _infoRow(
              'Tiền điện',
              electricityPrice is num && electricityPrice > 0
                  ? '${fmt.format(electricityPrice)}/kWh'
                  : 'Theo giá nhà nước',
            ),
            _divider(),
            _infoRow(
              'Tiền nước',
              waterPrice is num && waterPrice > 0
                  ? '${fmt.format(waterPrice)}$waterUnit'
                  : 'Theo giá nhà nước',
            ),
            _divider(),
            _infoRow('Phí dịch vụ', money(serviceFee, '/tháng')),
            _divider(),
            _infoRow('Internet', money(internetPrice, '/phòng')),
            _divider(),
            _infoRow('Gửi xe', money(parkingPrice, '/xe')),
            _divider(),
            _infoRow('Rác', money(trashPrice, '/phòng')),
          ],
        ),
        const SizedBox(height: 16),

        // ── Chỉ số đồng hồ ban đầu ──
        if (_electricIndex != null || _waterIndex != null) ...[
          _reviewCard(
            title: 'CHỈ SỐ ĐỒNG HỒ BAN ĐẦU',
            icon: CupertinoIcons.gauge,
            children: [
              _infoRow(
                'Số điện',
                _electricIndex != null ? '$_electricIndex kWh' : 'Chưa nhập',
              ),
              _divider(),
              _infoRow(
                'Số nước',
                _waterIndex != null ? '$_waterIndex m³' : 'Chưa nhập',
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],

        // ── Nội thất trong phòng ──
        _reviewCard(
          title: 'NỘI THẤT TRONG PHÒNG',
          icon: CupertinoIcons.sparkles,
          children: [
            if (amenities.isEmpty)
              const Text(
                'Chưa cập nhật nội thất cho phòng này.',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _furnitureChips
                    .map((e) => _chip(e['emoji']!, e['label']!))
                    .toList(),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Tiện ích chung của toà nhà (bước 2 khi tạo chi nhánh) ──
        _reviewCard(
          title: 'TIỆN ÍCH CHUNG TOÀ NHÀ',
          icon: CupertinoIcons.building_2_fill,
          children: [
            if (branchAmenities.isEmpty)
              const Text(
                'Chưa cập nhật tiện ích chung cho chi nhánh.',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: branchAmenities.map((a) {
                  // BUGFIX (data): trước đây ép `as num?` — nếu `price`
                  // là String thì ném TypeError và cả khối tiện ích chi
                  // nhánh không render. Coerce an toàn.
                  final price = _asNum(a['price']);
                  final chargeType = (a['chargeType'] ?? 'free').toString();
                  final unit = chargeType == 'per_person'
                      ? '/người'
                      : chargeType == 'per_room'
                      ? '/phòng'
                      : chargeType == 'monthly'
                      ? '/tháng'
                      : '';
                  final isFree = chargeType == 'free' || price <= 0;
                  final label = isFree
                      ? '${a['name']} • Miễn phí'
                      : '${a['name']} • ${fmt.format(price)}$unit';
                  return _chip(a['icon'].toString(), label);
                }).toList(),
              ),
          ],
        ),

        // ── Ảnh chi tiết (WC / ban công / cửa sổ / bếp / đồng hồ) ──
        if (featurePhotos.isNotEmpty) ...[
          const SizedBox(height: 16),
          _reviewCard(
            title: 'ẢNH CHI TIẾT PHÒNG',
            icon: CupertinoIcons.photo_on_rectangle,
            children: [
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: featurePhotos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.network(
                      featurePhotos[i],
                      width: 120,
                      height: 96,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 120,
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(
                          CupertinoIcons.photo,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
