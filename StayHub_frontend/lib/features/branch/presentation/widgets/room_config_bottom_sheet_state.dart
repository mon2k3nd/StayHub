part of 'room_config_bottom_sheet.dart';

class _RoomConfigBottomSheetState extends State<RoomConfigBottomSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _depositCtrl;
  late TextEditingController _areaCtrl;
  late TextEditingController _electricIndexCtrl;
  late TextEditingController _waterIndexCtrl;
  late TextEditingController _descriptionCtrl; // Added description control

  // MÃ canonical (id mô hình), KHÔNG dùng nhãn/alias. Xem RoomTypeCodes.
  String _roomType = 'PHONG_TRO';
  String _orientation = ''; // Hướng nhìn: NAM, BAC, DONG, TAY, v.v.

  bool _hasMezzanine = false;
  bool _hasBalcony = false;
  bool _hasWindow = true;
  bool _hasKitchen = false;

  int _maxOccupants = 2;
  int _maxVehicles = 2;

  // ── Các thuộc tính đặc thù cho mô hình mới ──
  late TextEditingController _frontageCtrl; // Mặt tiền (Kiot, Kho bãi)
  bool _hasPavement = false;
  bool _truckAccess = false;

  String _bedType = 'TANG_1'; // Loại giường (KTX, Ở ghép)
  bool _hasLocker = true;

  int _capacity = 1; // Sức chứa (Văn phòng)
  bool _hasMeetingRoom = false;
  bool _hasPantry = false;

  int _numberOfBedrooms = 1; // Căn hộ, Nhà nguyên căn
  int _numberOfBathrooms = 1;

  String _terrainType = 'BE_TONG'; // Đất trống
  bool _isFenced = false;

  // ── Các tình huống "khó đỡ" thực tế ──
  String _genderRestriction = 'ALL';
  String _petPolicy = 'NO_PETS';
  bool _hasCurfew = false;
  late TextEditingController _curfewTimeCtrl;
  bool _hasVat = false;

  // ── Các tình huống "Tranh cãi" / Hợp đồng ──
  int _minimumStayMonths = 6; // Hợp đồng tối thiểu
  int _noticePeriodDays = 30; // Báo trước khi dọn đi
  bool _isLiveWithLandlord = false; // Chung chủ
  late TextEditingController _extraGuestFeeCtrl; // Phụ thu khách qua đêm

  // ── Tiền cọc ──
  String _depositType = '1_THANG'; // '1_THANG', '2_THANG', 'TUY_CHINH'
  late TextEditingController
  _holdingDepositCtrl; // Cọc giữ chỗ (Holding Deposit)
  bool _isHoldingDepositRefundable = false; // Có hoàn cọc giữ chỗ không?

  String _furnitureLevel = 'CO_BAN';
  final Set<String> _furnitureItems = {};

  // ── Photo groups ──
  // Static groups + dynamic furniture keys like 'FURNITURE_AC', 'FURNITURE_GIUONG', etc.
  final Map<String, List<String>> _photoUrls = {
    'ROOM': [],
    'MEZZANINE': [],
    'BALCONY': [],
    'WINDOW': [],
    'KITCHEN': [],
    'WC': [],
    'ELECTRIC_METER': [],
    'WATER_METER': [],
  };
  final Map<String, List<XFile>> _photoLocals = {
    'ROOM': [],
    'MEZZANINE': [],
    'BALCONY': [],
    'WINDOW': [],
    'KITCHEN': [],
    'WC': [],
    'ELECTRIC_METER': [],
    'WATER_METER': [],
  };

  void _ensureFurniturePhotoGroup(String key) {
    final fKey = 'FURNITURE_$key';
    _photoUrls.putIfAbsent(fKey, () => []);
    _photoLocals.putIfAbsent(fKey, () => []);
  }

  bool _isSavingSingle = false;
  bool _isSavingMultiple = false;
  double _uploadProgress = -1.0;
  String? _errorMessage; // Inline error banner inside the sheet
  bool get _isSelfContained {
    final room = widget.room;
    // Check root level first, then detailedInfo
    if (room['isSelfContained'] != null) return room['isSelfContained'] == true;
    final info = widget.room['detailedInfo'] as Map<String, dynamic>?;
    return info?['isSelfContained'] == true;
  }

  late bool _enableWaterMeter;

  @override
  void initState() {
    super.initState();
    final room = widget.room;

    final branchWaterType = widget.branch?.waterPricingType;
    if (branchWaterType != null) {
      _enableWaterMeter = branchWaterType == 'PER_INDEX';
    } else {
      final info = widget.room['detailedInfo'] as Map<String, dynamic>?;
      _enableWaterMeter = info?['waterPricingType'] == 'PER_INDEX';
    }

    final initialName = room['roomName'] ?? room['name'] ?? '';
    final initialPrice = widget.room['price'] != null
        ? NumberFormat('#,###').format(widget.room['price'])
        : '';
    final initialDeposit = widget.room['deposit'] != null
        ? NumberFormat('#,###').format(widget.room['deposit'])
        : '';
    final initialArea = widget.room['floorArea'] != null
        ? widget.room['floorArea'].toString()
        : '';

    _nameCtrl = TextEditingController(text: initialName);
    _priceCtrl = TextEditingController(text: initialPrice);
    _depositCtrl = TextEditingController(text: initialDeposit);
    _areaCtrl = TextEditingController(text: initialArea);
    _descriptionCtrl = TextEditingController(
      text: widget.room['description'] ?? '',
    );

    final info = widget.room['detailedInfo'] as Map<String, dynamic>?;

    _holdingDepositCtrl = TextEditingController(
      text: info?['holdingDeposit']?.toString() ?? '500000',
    );
    _isHoldingDepositRefundable = info?['isHoldingDepositRefundable'] == true;

    _frontageCtrl = TextEditingController(
      text: info?['frontage']?.toString() ?? '',
    );
    _hasPavement = info?['hasPavement'] == true;
    _truckAccess = info?['truckAccess'] == true;
    _bedType = info?['bedType'] ?? 'TANG_1';
    _hasLocker = info?['hasLocker'] ?? true;
    _capacity = info?['capacity'] ?? 1;
    _hasMeetingRoom = info?['hasMeetingRoom'] == true;
    _hasPantry = info?['hasPantry'] == true;
    _numberOfBedrooms = info?['numberOfBedrooms'] ?? 1;
    _numberOfBathrooms = info?['numberOfBathrooms'] ?? 1;
    _terrainType = info?['terrainType'] ?? 'BE_TONG';
    _isFenced = info?['isFenced'] == true;

    _genderRestriction = info?['genderRestriction'] ?? 'ALL';
    _petPolicy = info?['petPolicy'] ?? 'NO_PETS';
    _hasCurfew = info?['hasCurfew'] == true;
    _curfewTimeCtrl = TextEditingController(
      text: info?['curfewTime']?.toString() ?? '23:30',
    );
    _hasVat = info?['hasVat'] == true;

    _minimumStayMonths = info?['minimumStayMonths'] ?? 6;
    _noticePeriodDays = info?['noticePeriodDays'] ?? 30;
    _isLiveWithLandlord = info?['isLiveWithLandlord'] == true;
    _extraGuestFeeCtrl = TextEditingController(
      text: info?['extraGuestFee']?.toString() ?? '',
    );

    _electricIndexCtrl = TextEditingController(
      text: info?['electricIndexInit']?.toString() ?? '',
    );
    _waterIndexCtrl = TextEditingController(
      text: info?['waterIndexInit']?.toString() ?? '',
    );

    // Chuẩn hoá về MÃ canonical để không lưu alias (PHONG_THUONG, 1PN, 2PN...)
    _roomType =
        RoomTypeCodes.toCode(
          room['roomType']?.toString() ?? info?['roomType']?.toString(),
        ) ??
        'PHONG_TRO';
    // BUGFIX (data): coerce an toàn — tránh `as bool?`/`as int?`/`as String?`
    // ném TypeError khi backend trả kiểu khác (số cho bool, chuỗi cho int...).
    bool asBool(dynamic v, bool fallback) =>
        v is bool ? v : (v == null ? fallback : v.toString() == 'true');
    int asInt(dynamic v, int fallback) => v is num
        ? v.toInt()
        : (v == null ? fallback : int.tryParse(v.toString()) ?? fallback);

    _hasMezzanine = asBool(
      room['hasMezzanine'] ?? info?['hasMezzanine'],
      false,
    );
    _hasBalcony = asBool(room['hasBalcony'] ?? info?['hasBalcony'], false);
    _hasWindow = asBool(room['hasWindow'] ?? info?['hasWindow'], true);
    _maxOccupants = asInt(room['maxOccupants'] ?? info?['maxOccupants'], 2);
    _maxVehicles = asInt(room['maxVehicles'] ?? info?['maxVehicles'], 2);
    _furnitureLevel =
        (room['furnitureLevel'] ?? info?['furnitureLevel'])?.toString() ??
        'CO_BAN';
    _orientation = info?['orientation']?.toString() ?? '';

    if (info?['furnitureItems'] != null && info!['furnitureItems'] is List) {
      _furnitureItems.addAll(List<String>.from(info['furnitureItems']));
    } else {
      _furnitureItems.addAll(['AC', 'BINH_NONG_LANH']);
    }

    // Load existing photos
    if (info?['photos'] != null && info!['photos'] is List) {
      debugPrint('>>> Loaded ROOM photo URLs: ${info['photos']}');
      _photoUrls['ROOM']!.addAll(List<String>.from(info['photos']));
    }

    // Load feature photos
    if (info?['featurePhotos'] != null && info!['featurePhotos'] is Map) {
      final featurePhotos = info['featurePhotos'] as Map<String, dynamic>;
      featurePhotos.forEach((key, value) {
        if (value is List) {
          if (!_photoUrls.containsKey(key)) {
            _photoUrls[key] = [];
            _photoLocals[key] = [];
          }
          _photoUrls[key]!.addAll(value.map((e) => e.toString()));
        }
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _depositCtrl.dispose();
    _areaCtrl.dispose();
    _electricIndexCtrl.dispose();
    _waterIndexCtrl.dispose();
    _frontageCtrl.dispose();
    _curfewTimeCtrl.dispose();
    _extraGuestFeeCtrl.dispose();
    _holdingDepositCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  /// Robust money parser: strips ALL grouping separators (both `,` and `.`)
  /// so "3.500.000", "3,500,000" and "3500000" all resolve to 3500000.
  /// Returns 0 when the text is empty or not a valid number.
  static double _parseMoney(String raw) {
    final cleaned = raw.replaceAll(',', '').replaceAll('.', '').trim();
    if (cleaned.isEmpty) return 0;
    return double.tryParse(cleaned) ?? 0;
  }

  /// Robust area parser: area is a decimal value (e.g. 25.5 m²). We only treat
  /// `,` as a decimal separator when it is NOT acting as a thousands grouping
  /// separator. This prevents "1,000" (one thousand) from being read as 1.0.
  static double _parseArea(String raw) {
    var cleaned = raw.trim();
    if (cleaned.isEmpty) return 0;
    // If the string contains both separators, the LAST one is the decimal mark.
    final hasComma = cleaned.contains(',');
    final hasDot = cleaned.contains('.');
    if (hasComma && hasDot) {
      // e.g. "1.234,5" (vi) or "1,234.5" (en) -> keep only the last separator.
      final lastComma = cleaned.lastIndexOf(',');
      final lastDot = cleaned.lastIndexOf('.');
      if (lastComma > lastDot) {
        cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
      } else {
        cleaned = cleaned.replaceAll(',', '');
      }
    } else if (hasComma) {
      // Only commas: "1,5" -> decimal, "1,000" -> thousands grouping.
      final parts = cleaned.split(',');
      final isGrouping =
          parts.length > 1 && parts.skip(1).every((p) => p.length == 3);
      cleaned = isGrouping
          ? cleaned.replaceAll(',', '')
          : cleaned.replaceAll(',', '.');
    }
    return double.tryParse(cleaned) ?? 0;
  }

  void _onPriceChanged(String value) {
    if (_depositType != 'TUY_CHINH') {
      final price = _parseMoney(value);
      final multiplier = _depositType == '1_THANG' ? 1 : 2;
      // Keep the deposit field formatted with thousand separators so it stays
      // visually consistent with the price field.
      _depositCtrl.text = NumberFormat('#,###').format(price * multiplier);
    }
  }

  Future<Map<String, dynamic>> _buildPayload() async {
    // Helper để đọc ảnh thành base64 (Ảnh đã được nén sẵn bởi image_picker lúc chọn).
    // Resilient: a single unreadable/corrupt file must NOT abort the whole save.
    // Returns null on failure so the caller can skip it and keep the rest.
    Future<String?> processImage(XFile f) async {
      try {
        final bytes = await f.readAsBytes();
        if (bytes.isEmpty) return null;
        return base64Encode(bytes);
      } catch (e) {
        debugPrint('>>> Skipping unreadable image ${f.path}: $e');
        return null;
      }
    }

    // Main room photos
    final List<String> mainPhotos = List.from(_photoUrls['ROOM']!);
    for (var f in _photoLocals['ROOM']!) {
      final encoded = await processImage(f);
      if (encoded != null) mainPhotos.add(encoded);
    }

    // Feature photos (MEZZANINE, BALCONY, WINDOW, WC + all FURNITURE_* keys)
    final Map<String, List<String>> featurePhotos = {};
    final allGroups = _photoUrls.keys.where((k) => k != 'ROOM').toList();
    for (final key in allGroups) {
      final urls = List<String>.from(_photoUrls[key]!);
      for (var f in (_photoLocals[key] ?? [])) {
        final encoded = await processImage(f);
        if (encoded != null) urls.add(encoded);
      }
      if (urls.isNotEmpty) featurePhotos[key] = urls;
    }

    return {
      'roomName': _nameCtrl.text.trim(),
      'price': _parseMoney(_priceCtrl.text),
      'deposit': _parseMoney(_depositCtrl.text),
      'area': _parseArea(_areaCtrl.text),
      'description': _descriptionCtrl.text.trim(),
      'roomType': _roomType,
      'hasMezzanine': _hasMezzanine,
      'hasBalcony': _hasBalcony,
      'hasWindow': _hasWindow,
      'hasKitchen': _hasKitchen,
      'maxOccupants': _maxOccupants,
      'maxVehicles': _maxVehicles,
      'furnitureLevel': _furnitureLevel,
      'furnitureItems': _furnitureItems.toList(),
      'orientation': _orientation,
      'isSelfContained': _isSelfContained,
      'electricIndex': int.tryParse(_electricIndexCtrl.text) ?? 0,
      if (_enableWaterMeter)
        'waterIndex': int.tryParse(_waterIndexCtrl.text) ?? 0,

      // Đặc thù tuỳ mô hình
      if (_roomType == 'KIOT' || _roomType == 'KHO_BAI') ...{
        'frontage': double.tryParse(_frontageCtrl.text) ?? 0.0,
        'hasPavement': _hasPavement,
        'truckAccess': _truckAccess,
      } else if (_roomType == 'O_GHEP_KTX') ...{
        'bedType': _bedType,
        'hasLocker': _hasLocker,
      } else if (_roomType == 'OFFICE') ...{
        'capacity': _capacity,
        'hasMeetingRoom': _hasMeetingRoom,
        'hasPantry': _hasPantry,
      } else if (_roomType == 'CHUNG_CU' ||
          _roomType == 'CHUNG_CU_MINI' ||
          _roomType == 'NHA_NGUYEN_CAN') ...{
        'numberOfBedrooms': _numberOfBedrooms,
        'numberOfBathrooms': _numberOfBathrooms,
      } else if (_roomType == 'DAT_CHO_THUE' ||
          _roomType == 'SAN_THE_THAO') ...{
        'terrainType': _terrainType,
        'isFenced': _isFenced,
      },

      // Quy định thực tế
      'genderRestriction': _genderRestriction,
      'petPolicy': _petPolicy,
      'hasCurfew': _hasCurfew,
      if (_hasCurfew) 'curfewTime': _curfewTimeCtrl.text,
      'hasVat': _hasVat,

      // Các trường hợp đồng / pháp lý
      'minimumStayMonths': _minimumStayMonths,
      'noticePeriodDays': _noticePeriodDays,
      'isLiveWithLandlord': _isLiveWithLandlord,
      'extraGuestFee':
          double.tryParse(
            _extraGuestFeeCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0,

      // Tài chính sâu
      'holdingDeposit':
          double.tryParse(
            _holdingDepositCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
          ) ??
          0,
      'isHoldingDepositRefundable': _isHoldingDepositRefundable,

      'photos': mainPhotos,
      'featurePhotos': featurePhotos,
    };
  }

  bool _validate() {
    final price = _parseMoney(_priceCtrl.text);
    final deposit = _parseMoney(_depositCtrl.text);
    final area = _parseArea(_areaCtrl.text);

    // 0. Tên phòng bắt buộc
    if (_nameCtrl.text.trim().isEmpty) {
      _showError('⚠️ Vui lòng nhập Tên phòng');
      return false;
    }

    // 1. Giá thuê bắt buộc
    if (price <= 0) {
      _showError('⚠️ Vui lòng nhập Giá thuê hợp lệ');
      return false;
    }

    // 1b. Giá thuê quá lớn (gần như chắc chắn nhập sai định dạng)
    if (price > 1000000000) {
      _showError('⚠️ Giá thuê quá lớn (tối đa 1 tỷ). Vui lòng kiểm tra lại.');
      return false;
    }

    // 2. Tiền cọc bắt buộc
    if (deposit <= 0) {
      _showError('⚠️ Vui lòng nhập Tiền cọc hợp lệ');
      return false;
    }

    // 2b. Tiền cọc quá lớn
    if (deposit > 1000000000) {
      _showError('⚠️ Tiền cọc quá lớn (tối đa 1 tỷ). Vui lòng kiểm tra lại.');
      return false;
    }

    // 3. Diện tích bắt buộc
    if (area <= 0) {
      _showError('⚠️ Vui lòng nhập Diện tích hợp lệ');
      return false;
    }

    // 3b. Diện tích bất thường
    if (area > 1000) {
      _showError(
        '⚠️ Diện tích quá lớn (tối đa 1000 m²). Vui lòng kiểm tra lại.',
      );
      return false;
    }

    // 4. Ít nhất 1 ảnh phòng chính
    final roomPhotoTotal =
        _photoUrls['ROOM']!.length + _photoLocals['ROOM']!.length;
    if (roomPhotoTotal == 0) {
      _showError('📸 Cần ít nhất 1 ảnh phòng để đăng cho thuê');
      return false;
    }

    // 5. Nếu phòng khép kín -> phải có ảnh WC riêng
    if (_isSelfContained) {
      final wcTotal = _photoUrls['WC']!.length + _photoLocals['WC']!.length;
      if (wcTotal == 0) {
        _showError('🚽 Phòng khép kín cần có ít nhất 1 ảnh WC riêng');
        return false;
      }
    }

    // 6. Chỉ số đồng hồ điện ban đầu (không được để trống)
    if (_electricIndexCtrl.text.trim().isEmpty) {
      _showError('⚠️ Vui lòng nhập Chỉ số điện ban đầu');
      return false;
    }

    // 7. Chỉ số đồng hồ nước ban đầu (nếu có)
    if (_enableWaterMeter && _waterIndexCtrl.text.trim().isEmpty) {
      _showError('⚠️ Vui lòng nhập Chỉ số nước ban đầu');
      return false;
    }

    return true;
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.bolt_fill,
            color: Color(0xFFF59E0B),
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyFeeRow(
    String label,
    double? price, {
    String unit = 'đ',
  }) {
    final format = NumberFormat('#,###');
    final displayPrice = price != null ? format.format(price) : '0';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF4B5563), fontSize: 14),
        ),
        Text(
          '$displayPrice $unit',
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  void _showError(String msg) {
    unawaited(HapticFeedback.heavyImpact());
    setState(() => _errorMessage = msg);
    // Auto-clear after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _errorMessage = null);
    });
  }

  Future<void> _save() async {
    // Guard against double-tap while a save is already in-flight.
    if (_isSavingSingle || _isSavingMultiple) return;
    if (!_validate()) return;
    setState(() {
      _isSavingSingle = true;
      _errorMessage = null;
      _uploadProgress = 0.0;
    });
    try {
      final data = await _buildPayload();
      await widget.onSaved(data, (count, total) {
        if (mounted && total > 0) {
          setState(() => _uploadProgress = count / total);
        }
      });
      await Future.delayed(const Duration(milliseconds: 300));
      unawaited(HapticFeedback.heavyImpact());
      if (mounted) ToastUtils.show(context, 'Lưu phòng thành công!');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _showError('⚠️ Lỗi: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingSingle = false;
          _uploadProgress = -1.0;
        });
      }
    }
  }

  Future<void> _saveAndApplyMultiple() async {
    // Guard against double-tap while a save is already in-flight.
    if (_isSavingSingle || _isSavingMultiple) return;
    if (!_validate()) return;
    setState(() {
      _isSavingMultiple = true;
      _errorMessage = null;
      _uploadProgress = 0.0;
    });
    try {
      final data = await _buildPayload();
      await widget.onApplyMultiple(data, (count, total) {
        if (mounted && total > 0) {
          setState(() => _uploadProgress = count / total);
        }
      });
      await Future.delayed(const Duration(milliseconds: 300));
      unawaited(HapticFeedback.heavyImpact());
      if (mounted) ToastUtils.show(context, 'Đã áp dụng cấu hình!');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _showError('⚠️ Lỗi: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSavingMultiple = false;
          _uploadProgress = -1.0;
        });
      }
    }
  }

  Future<void> _pickPhotos(String group, {int max = 5}) async {
    final total = _photoUrls[group]!.length + _photoLocals[group]!.length;
    final remaining = max - total;
    if (remaining <= 0) {
      ToastUtils.show(context, 'Đã đạt giới hạn $max ảnh', isError: true);
      return;
    }
    try {
      unawaited(
        ImagePickerUtils.showPicker(
          context: context,
          limit: remaining,
          onPicked: (picked) {
            if (picked.isNotEmpty && mounted) {
              setState(() => _photoLocals[group]!.addAll(picked));
              unawaited(HapticFeedback.lightImpact());
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

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final roomName = room['roomName'] ?? '';

    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      // Chiều cao cố định 92% màn hình để sheet luôn mở đầy đủ và cuộn được —
      // tránh lỗi MainAxisSize.min + Expanded làm nội dung bị co lại che mất
      // phần "Ảnh phòng" ở đầu form.
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.92,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.bed_double_fill,
                          color: Color(0xFF0EA5E9),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cấu hình Phòng $roomName',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                            Text(
                              _isSelfContained
                                  ? '🔒 Phòng khép kín (WC riêng)'
                                  : '🚿 WC Chung',
                              style: TextStyle(
                                color: _isSelfContained
                                    ? const Color(0xFF0EA5E9)
                                    : const Color(0xFF10B981),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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

                // Scrollable body
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),

                        // ── ERROR BANNER (inline, always visible) ──
                        if (_errorMessage != null)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFF87171),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  CupertinoIcons.exclamationmark_circle_fill,
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

                        // ── SECTION 0: TÊN PHÒNG ──
                        _sectionTitle(
                          '🏷️ THÔNG TIN CƠ BẢN',
                          subtitle: 'Tên hoặc số phòng (VD: P.101)',
                        ),
                        _buildInput(
                          ctrl: _nameCtrl,
                          label: 'Tên phòng',
                          icon: CupertinoIcons.tag,
                        ),
                        const SizedBox(height: 28),

                        // ── SECTION 1: ẢNH PHÒNG ──
                        _sectionTitle(
                          '📸 ẢNH PHÒNG',
                          subtitle: 'Chụp từ góc phòng ra ngoài',
                        ),
                        _buildPhotoGrid('ROOM', max: 8),

                        const SizedBox(height: 28),
                        // ── SECTION 2: CẤU TRÚC & WC ──
                        _sectionTitle(
                          '🏠 CẤU TRÚC & WC',
                          subtitle: 'Chọn đặc điểm và tải ảnh tương ứng',
                        ),
                        _buildRoomTypeSelector(),
                        const SizedBox(height: 16),
                        // Feature toggles with photo upload on tap
                        _buildFeatureRow(),
                        // WC section (only for self-contained rooms)
                        if (_isSelfContained) ...[
                          const SizedBox(height: 20),
                          _buildWcSection(),
                        ] else ...[
                          const SizedBox(height: 12),
                          _buildSharedWcNote(),
                        ],

                        const SizedBox(height: 28),
                        // ── SECTION 3: NỘI THẤT ──
                        _sectionTitle(
                          '🛋️ NỘI THẤT',
                          subtitle: 'Chọn nội thất và tải ảnh thiết bị',
                        ),
                        _buildFurnitureLevelSelector(),
                        const SizedBox(height: 16),
                        if (_furnitureLevel != 'TRONG') _buildFurnitureChips(),

                        const SizedBox(height: 28),
                        // ── SECTION 4: GIÁ & DIỆN TÍCH ──
                        _sectionTitle('💰 GIÁ & DIỆN TÍCH'),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInput(
                                ctrl: _priceCtrl,
                                label: 'Giá thuê (đ/tháng)',
                                icon: CupertinoIcons.money_dollar,
                                onChanged: _onPriceChanged,
                                inputFormatters: [CurrencyInputFormatter()],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInput(
                                ctrl: _areaCtrl,
                                label: 'Diện tích (m²)',
                                icon: CupertinoIcons.square,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.,]'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDepositSection(),

                        const SizedBox(height: 28),
                        // ── SECTION 5: CHI PHÍ DỊCH VỤ CHI NHÁNH ──
                        _buildSectionTitle(
                          'GIÁ DỊCH VỤ VÀ TIỆN ÍCH CHI NHÁNH (Lưu ý: Không thể sửa ở đây)',
                        ),
                        if (widget.branch != null) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE5E7EB),
                              ),
                            ),
                            child: Column(
                              children: [
                                _buildReadOnlyFeeRow(
                                  '⚡ Giá điện',
                                  widget.branch!.electricityPrice,
                                  unit: 'đ/kWh',
                                ),
                                const Divider(height: 16),
                                _buildReadOnlyFeeRow(
                                  '💧 Giá nước',
                                  widget.branch!.waterPrice,
                                  unit:
                                      widget.branch!.waterPricingType ==
                                          'PER_PERSON'
                                      ? 'đ/Người'
                                      : (widget.branch!.waterPricingType ==
                                                'PER_ROOM'
                                            ? 'đ/Phòng'
                                            : 'đ/m³'),
                                ),
                                const Divider(height: 16),
                                _buildReadOnlyFeeRow(
                                  '🌐 Mạng Internet',
                                  widget.branch!.internetPrice,
                                  unit: 'đ/Phòng',
                                ),
                                const Divider(height: 16),
                                _buildReadOnlyFeeRow(
                                  '🏍️ Gửi xe',
                                  widget.branch!.parkingPrice,
                                  unit: 'đ/Xe',
                                ),
                                const Divider(height: 16),
                                _buildReadOnlyFeeRow(
                                  '🗑️ Rác thải',
                                  widget.branch!.trashPrice,
                                  unit: 'đ/Phòng',
                                ),
                              ],
                            ),
                          ),
                        ],

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionTitle('CHỈ SỐ ĐỒNG HỒ BAN ĐẦU'),
                          ],
                        ),
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
                            if (_enableWaterMeter) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMeterSection(
                                  'Số Nước (m³)',
                                  'WATER_METER',
                                  _waterIndexCtrl,
                                  '💧',
                                ),
                              ),
                            ] else ...[
                              const SizedBox(width: 12),
                              const Expanded(child: SizedBox()), // Placeholder
                            ],
                          ],
                        ),

                        const SizedBox(height: 28),
                        // ── SECTION 6: HƯỚNG & MÔ TẢ PHÒNG ──
                        _sectionTitle('🧭 HƯỚNG & MÔ TẢ PHÒNG'),
                        _buildOrientationSelector(),
                        const SizedBox(height: 16),
                        _buildDescriptionInput(),

                        const SizedBox(height: 28),
                        // ── SECTION 7: GIỚI HẠN SỬ DỤNG ──
                        _sectionTitle('👥 GIỚI HẠN SỬ DỤNG'),
                        Row(
                          children: [
                            Expanded(
                              child: _buildCounter(
                                '👤 Người ở tối đa',
                                _maxOccupants,
                                (v) => setState(() => _maxOccupants = v),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildCounter(
                                '🛵 Xe để tối đa',
                                _maxVehicles,
                                (v) => setState(() => _maxVehicles = v),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),
                        // ── SECTION 8: QUY ĐỊNH THỰC TẾ & HỢP ĐỒNG ──
                        // Trước đây section này bị "mồ côi" (khai báo nhưng không
                        // render) khiến chủ nhà không thể chỉnh giới tính/pet/giờ
                        // đóng cửa/tháng tối thiểu... dù payload vẫn gửi các giá
                        // trị mặc định. Đã nối vào cây build tại đây.
                        _buildSpecialRulesSection(),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                // Bottom buttons
                Container(
                  // Responsive gutter: tighter on very narrow phones so the two
                  // action buttons never overflow or get clipped.
                  padding: EdgeInsets.fromLTRB(
                    MediaQuery.of(context).size.width < 360 ? 12 : 20,
                    12,
                    MediaQuery.of(context).size.width < 360 ? 12 : 20,
                    12,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── ERROR BANNER always visible above buttons ──
                      if (_errorMessage != null)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFF87171)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.exclamationmark_circle_fill,
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
                                onTap: () =>
                                    setState(() => _errorMessage = null),
                                child: const Icon(
                                  CupertinoIcons.clear_circled_solid,
                                  color: Color(0xFFDC2626),
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: (_isSavingSingle || _isSavingMultiple)
                                  ? null
                                  : _saveAndApplyMultiple,
                              child: Container(
                                clipBehavior: Clip.hardEdge,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    if (_isSavingMultiple &&
                                        _uploadProgress >= 0)
                                      Positioned.fill(
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: _uploadProgress.clamp(
                                            0.0,
                                            1.0,
                                          ),
                                          child: Container(
                                            color: const Color(0xFFE5E7EB),
                                          ),
                                        ),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                      child: Center(
                                        child: _isSavingMultiple
                                            ? Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const CupertinoActivityIndicator(),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    _uploadProgress == 0.0
                                                        ? 'Đang nén ảnh...'
                                                        : 'Tải lên... ${(_uploadProgress * 100).toInt()}%',
                                                    style: const TextStyle(
                                                      color: Color(0xFF4B5563),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : const FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  'Áp dụng nhiều phòng',
                                                  maxLines: 1,
                                                  style: TextStyle(
                                                    color: Color(0xFF4B5563),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: (_isSavingSingle || _isSavingMultiple)
                                  ? null
                                  : _save,
                              child: Container(
                                clipBehavior: Clip.hardEdge,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF0EA5E9),
                                      Color(0xFF0284C7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Stack(
                                  children: [
                                    if (_isSavingSingle && _uploadProgress >= 0)
                                      Positioned.fill(
                                        child: FractionallySizedBox(
                                          alignment: Alignment.centerLeft,
                                          widthFactor: _uploadProgress.clamp(
                                            0.0,
                                            1.0,
                                          ),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            color: Colors.white.withValues(
                                              alpha: 0.25,
                                            ),
                                          ),
                                        ),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                      child: Center(
                                        child: _isSavingSingle
                                            ? Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const CupertinoActivityIndicator(
                                                    color: Colors.white,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    _uploadProgress == 0.0
                                                        ? 'Đang nén ảnh...'
                                                        : 'Tải lên... ${(_uploadProgress * 100).toInt()}%',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  widget.room['status'] !=
                                                          'KHOA_CHO_CAP_NHAT'
                                                      ? 'Cập nhật'
                                                      : 'Lưu phòng này',
                                                  maxLines: 1,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ), // end Row
                    ], // end Column children
                  ), // end Column
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Feature toggles (Gác lửng, Ban công, Cửa sổ) ───
  Widget _buildFeatureRow() {
    if (_roomType == 'KIOT' || _roomType == 'KHO_BAI') {
      return Column(
        children: [
          _buildInput(
            ctrl: _frontageCtrl,
            label: 'Mặt tiền (m)',
            icon: CupertinoIcons.arrow_left_right_square,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildToggleCard(
                  'Vỉa hè rộng',
                  CupertinoIcons.car_fill,
                  _hasPavement,
                  (v) => setState(() => _hasPavement = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildToggleCard(
                  'Xe tải vào',
                  CupertinoIcons.bus,
                  _truckAccess,
                  (v) => setState(() => _truckAccess = v),
                ),
              ),
            ],
          ),
        ],
      );
    } else if (_roomType == 'O_GHEP_KTX') {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Loại giường',
                  value: _bedType,
                  items: const [
                    DropdownMenuItem(
                      value: 'TANG_1',
                      child: Text('Giường tầng 1'),
                    ),
                    DropdownMenuItem(
                      value: 'TANG_2',
                      child: Text('Giường tầng 2'),
                    ),
                    DropdownMenuItem(value: 'DON', child: Text('Giường đơn')),
                  ],
                  onChanged: (v) => setState(() => _bedType = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildToggleCard(
                  'Tủ đồ riêng',
                  CupertinoIcons.lock_fill,
                  _hasLocker,
                  (v) => setState(() => _hasLocker = v),
                ),
              ),
            ],
          ),
        ],
      );
    } else if (_roomType == 'OFFICE') {
      return Column(
        children: [
          _buildCounter(
            '👥 Sức chứa (người)',
            _capacity,
            (v) => setState(() => _capacity = v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildToggleCard(
                  'Phòng họp',
                  CupertinoIcons.person_3_fill,
                  _hasMeetingRoom,
                  (v) => setState(() => _hasMeetingRoom = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildToggleCard(
                  'Pantry',
                  CupertinoIcons.flame,
                  _hasPantry,
                  (v) => setState(() => _hasPantry = v),
                ),
              ),
            ],
          ),
        ],
      );
    } else if (_roomType == 'CHUNG_CU' ||
        _roomType == 'NHA_NGUYEN_CAN' ||
        _roomType == 'CHUNG_CU_MINI') {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCounter(
                  '🛏️ Phòng ngủ',
                  _numberOfBedrooms,
                  (v) => setState(() => _numberOfBedrooms = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCounter(
                  '🚿 Phòng tắm',
                  _numberOfBathrooms,
                  (v) => setState(() => _numberOfBathrooms = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildFeatureCard(
                  label: 'Ban công',
                  icon: '🌿',
                  photoGroup: 'BALCONY',
                  value: _hasBalcony,
                  onChanged: (v) => setState(() => _hasBalcony = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFeatureCard(
                  label: 'Cửa sổ',
                  icon: '🪟',
                  photoGroup: 'WINDOW',
                  value: _hasWindow,
                  onChanged: (v) => setState(() => _hasWindow = v),
                ),
              ),
            ],
          ),
          if (_hasBalcony) _buildInlinePhotoUpload('BALCONY', 'Ảnh ban công'),
          if (_hasWindow) _buildInlinePhotoUpload('WINDOW', 'Ảnh cửa sổ'),
        ],
      );
    } else if (_roomType == 'DAT_CHO_THUE' || _roomType == 'SAN_THE_THAO') {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  label: 'Loại bề mặt',
                  value: _terrainType,
                  items: const [
                    DropdownMenuItem(
                      value: 'BE_TONG',
                      child: Text('Bê tông/Nhựa'),
                    ),
                    DropdownMenuItem(
                      value: 'DAT_TRONG',
                      child: Text('Đất trống'),
                    ),
                    DropdownMenuItem(
                      value: 'CO',
                      child: Text('Cỏ/Nông nghiệp'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _terrainType = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildToggleCard(
                  'Rào chắn',
                  CupertinoIcons.rectangle_split_3x1,
                  _isFenced,
                  (v) => setState(() => _isFenced = v),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Default cho PHONG_TRO, CHDV, STUDIO...
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFeatureCard(
                label: 'Gác lửng',
                icon: '🪜',
                value: _hasMezzanine,
                onChanged: (v) => setState(() => _hasMezzanine = v),
                photoGroup: 'MEZZANINE',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildFeatureCard(
                label: 'Ban công',
                icon: '🌿',
                value: _hasBalcony,
                onChanged: (v) => setState(() => _hasBalcony = v),
                photoGroup: 'BALCONY',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildFeatureCard(
                label: 'Cửa sổ',
                icon: '🪟',
                value: _hasWindow,
                onChanged: (v) => setState(() => _hasWindow = v),
                photoGroup: 'WINDOW',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildFeatureCard(
                label: 'Bếp',
                icon: '🍳',
                value: _hasKitchen,
                onChanged: (v) {
                  if (v && widget.branch?.cookingPolicy == 'KHONG_CHO') {
                    _showError(
                      'Không thể cấu hình bếp vì Nội quy Chi nhánh "KHÔNG CHO PHÉP" nấu ăn trong phòng!',
                    );
                    unawaited(HapticFeedback.heavyImpact());
                    return;
                  }
                  setState(() => _hasKitchen = v);
                },
                photoGroup: 'KITCHEN',
              ),
            ),
          ],
        ),
        // Show photo upload inline when feature is toggled on
        if (_hasMezzanine) _buildInlinePhotoUpload('MEZZANINE', 'Ảnh gác lửng'),
        if (_hasBalcony) _buildInlinePhotoUpload('BALCONY', 'Ảnh ban công'),
        if (_hasWindow) _buildInlinePhotoUpload('WINDOW', 'Ảnh cửa sổ'),
        if (_hasKitchen)
          _buildInlinePhotoUpload('KITCHEN', 'Ảnh bếp', colorScheme: 'ORANGE'),
      ],
    );
  }

  // ─── Hướng và Mô tả ───
  Widget _buildOrientationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hướng nhìn ban công/cửa sổ',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        CupertinoSlidingSegmentedControl<String>(
          groupValue: _orientation.isEmpty ? 'KHONG_RO' : _orientation,
          children: const {
            'KHONG_RO': Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('Không rõ', style: TextStyle(fontSize: 12)),
            ),
            'DONG': Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('Đông', style: TextStyle(fontSize: 12)),
            ),
            'TAY': Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('Tây', style: TextStyle(fontSize: 12)),
            ),
            'NAM': Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('Nam', style: TextStyle(fontSize: 12)),
            ),
            'BAC': Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('Bắc', style: TextStyle(fontSize: 12)),
            ),
          },
          onValueChanged: (v) {
            if (v != null) {
              setState(() => _orientation = v == 'KHONG_RO' ? '' : v);
            }
          },
        ),
      ],
    );
  }

  Widget _buildDescriptionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mô tả phòng',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionCtrl,
          maxLines: 5,
          minLines: 3,
          decoration: InputDecoration(
            hintText:
                'Nhập mô tả chi tiết phòng để tự động đăng bài khi trống...',
            hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF69B1FF)),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Đồng hồ điện / nước ───
  Widget _buildMeterSection(
    String label,
    String photoGroup,
    TextEditingController ctrl,
    String iconText,
  ) {
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
        _buildInlinePhotoUpload(photoGroup, 'Ảnh $label', colorScheme: 'BLUE'),
      ],
    );
  }

  // ─── Photo grid (tổng quan) ───
  Widget _buildPhotoGrid(
    String group, {
    int max = 8,
    double emptyHeight = 120,
  }) {
    final urls = _photoUrls[group]!;
    final locals = _photoLocals[group]!;
    final total = urls.length + locals.length;

    if (total == 0) {
      return GestureDetector(
        onTap: () => _pickPhotos(group, max: max),
        child: Container(
          width: double.infinity,
          height: emptyHeight + 30,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.camera_fill,
                  color: Color(0xFF2563EB),
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '📷 Tải ảnh phòng lên',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D4ED8),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text(
                  'BẮT BUỘC • Tối thiểu 1 ảnh',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ),
              const Text(
                'Chụp từ góc phòng, ảnh sáng rõ sẽ thu hút người thuê hơn',
                style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildThumbnailRow(group, max: max),
        const SizedBox(height: 8),
        if (total < max)
          GestureDetector(
            onTap: () => _pickPhotos(group, max: max),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: const Color(0xFFD1D5DB)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.plus, size: 13, color: Color(0xFF4B5563)),
                  SizedBox(width: 4),
                  Text(
                    'Thêm ảnh',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildThumbnailRow(String group, {int max = 5}) {
    final urls = _photoUrls[group]!;
    final locals = _photoLocals[group]!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...urls.asMap().entries.map(
            (e) => _photoThumb(
              onDelete: () =>
                  setState(() => _photoUrls[group]!.removeAt(e.key)),
              child: Image.network(e.value, fit: BoxFit.cover),
            ),
          ),
          ...locals.asMap().entries.map(
            (e) => _photoThumb(
              onDelete: () =>
                  setState(() => _photoLocals[group]!.removeAt(e.key)),
              child: kIsWeb
                  ? Image.network(e.value.path, fit: BoxFit.cover)
                  : Image.file(File(e.value.path), fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }

  Widget _photoThumb({required VoidCallback onDelete, required Widget child}) {
    return Stack(
      children: [
        Container(
          width: 90,
          height: 90,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: child,
          ),
        ),
        Positioned(
          top: 4,
          right: 14,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.clear,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Helpers ───
  Widget _sectionTitle(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFF374151),
              letterSpacing: 0.3,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    Function(String)? onChanged,
    List<TextInputFormatter>? inputFormatters,
    TextInputType keyboardType = TextInputType.number,
    String? suffix,
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
                  keyboardType: keyboardType,
                  onChanged: onChanged,
                  inputFormatters: inputFormatters,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
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
              if (suffix != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    suffix,
                    style: const TextStyle(
                      color: Color(0xFF9CA3AF),
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
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
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                CupertinoIcons.chevron_down,
                size: 16,
                color: Color(0xFF6B7280),
              ),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF111827),
              ),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleCard(
    String label,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return GestureDetector(
      onTap: () {
        unawaited(HapticFeedback.selectionClick());
        onChanged(!value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          gradient: value
              ? const LinearGradient(
                  colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                )
              : null,
          color: value ? null : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value ? Colors.transparent : const Color(0xFFE5E7EB),
          ),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: value ? Colors.white : const Color(0xFF4B5563),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: value ? Colors.white : const Color(0xFF4B5563),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Icon(
              value
                  ? CupertinoIcons.checkmark_alt_circle_fill
                  : CupertinoIcons.circle,
              color: value ? Colors.white : const Color(0xFFD1D5DB),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialRulesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
          'QUY ĐỊNH THỰC TẾ & LƯU Ý',
          subtitle: 'Các ràng buộc giúp chủ nhà lọc đúng tệp khách',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                label: 'Giới tính',
                value: _genderRestriction,
                items: const [
                  DropdownMenuItem(
                    value: 'ALL',
                    child: Text('Nam & Nữ (Tất cả)'),
                  ),
                  DropdownMenuItem(
                    value: 'NAM',
                    child: Text('Chỉ cho Nam thuê'),
                  ),
                  DropdownMenuItem(value: 'NU', child: Text('Chỉ cho Nữ thuê')),
                ],
                onChanged: (v) => setState(() => _genderRestriction = v!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown(
                label: 'Thú cưng (Pet)',
                value: _petPolicy,
                items: const [
                  DropdownMenuItem(
                    value: 'NO_PETS',
                    child: Text('Không nuôi Pet'),
                  ),
                  DropdownMenuItem(
                    value: 'SMALL_ONLY',
                    child: Text('Pet nhỏ (Mèo, chim)'),
                  ),
                  DropdownMenuItem(value: 'FREE', child: Text('Nuôi tự do')),
                ],
                onChanged: (v) => setState(() => _petPolicy = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildToggleCard(
                'Khóa cổng đêm',
                CupertinoIcons.moon_stars_fill,
                _hasCurfew,
                (v) => setState(() => _hasCurfew = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildToggleCard(
                'Xuất hóa đơn VAT',
                CupertinoIcons.doc_text_fill,
                _hasVat,
                (v) => setState(() => _hasVat = v),
              ),
            ),
          ],
        ),
        if (_hasCurfew) ...[
          const SizedBox(height: 12),
          _buildInput(
            ctrl: _curfewTimeCtrl,
            label: 'Giờ đóng cửa (Ví dụ: 23:30)',
            icon: CupertinoIcons.time,
            keyboardType: TextInputType.text,
          ),
        ],
        const SizedBox(height: 16),
        _sectionTitle(
          'HỢP ĐỒNG & BẢO ĐẢM TRÁNH TRANH CÃI',
          subtitle: 'Nguyên nhân hàng đầu gây mất cọc & phốt',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCounter(
                'Tháng tối thiểu',
                _minimumStayMonths,
                (v) => setState(() => _minimumStayMonths = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCounter('Báo chuyển đi\n(Ngày)', _noticePeriodDays, (
                v,
              ) {
                if (v >= 15 && v <= 60) setState(() => _noticePeriodDays = v);
              }),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildToggleCard(
                'Chung chủ',
                CupertinoIcons.house_alt_fill,
                _isLiveWithLandlord,
                (v) => setState(() => _isLiveWithLandlord = v),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInput(
                ctrl: _extraGuestFeeCtrl,
                label: 'Phụ thu người thứ 3 (đ/đêm)',
                icon: CupertinoIcons.money_dollar,
                inputFormatters: [CurrencyInputFormatter()],
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDepositSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tiền cọc Hợp đồng (Security Deposit)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _depositChip('1 Tháng', '1_THANG'),
            const SizedBox(width: 8),
            _depositChip('2 Tháng', '2_THANG'),
            const SizedBox(width: 8),
            _depositChip('Tuỳ chỉnh', 'TUY_CHINH'),
          ],
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
              const Padding(
                padding: EdgeInsets.only(left: 12),
                child: Icon(
                  CupertinoIcons.shield_fill,
                  size: 16,
                  color: Color(0xFF10B981),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _depositCtrl,
                  keyboardType: TextInputType.number,
                  enabled: _depositType == 'TUY_CHINH',
                  inputFormatters: [CurrencyInputFormatter()],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: _depositType == 'TUY_CHINH'
                        ? const Color(0xFF111827)
                        : const Color(0xFF6B7280),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    isDense: true,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Text(
                  'VNĐ',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        const Text(
          'Tiền cọc Giữ chỗ (Holding Deposit)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Thu trước khi ký HĐ để khóa phòng, tránh bom',
          style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: Icon(
                        CupertinoIcons.lock_fill,
                        size: 16,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _holdingDepositCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [CurrencyInputFormatter()],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
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
                    const Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Text(
                        'VNĐ',
                        style: TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildToggleCard(
                'Hoàn cọc nếu hủy',
                CupertinoIcons.arrow_uturn_left_circle_fill,
                _isHoldingDepositRefundable,
                (v) => setState(() => _isHoldingDepositRefundable = v),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _depositChip(String label, String type) {
    final sel = _depositType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _depositType = type;
          if (type != 'TUY_CHINH') {
            final price = _parseMoney(_priceCtrl.text);
            _depositCtrl.text = NumberFormat(
              '#,###',
            ).format(price * (type == '1_THANG' ? 1 : 2));
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: sel
              ? const LinearGradient(
                  colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                )
              : null,
          color: sel ? null : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: sel ? Colors.transparent : const Color(0xFFE5E7EB),
          ),
          boxShadow: sel
              ? [
                  BoxShadow(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
            color: sel ? Colors.white : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }

  Widget _buildRoomTypeSelector() {
    // Giá trị là MÃ canonical (id mô hình), KHÔNG phải nhãn hiển thị.
    return CupertinoSlidingSegmentedControl<String>(
      groupValue: _roomType,
      children: const {
        'PHONG_TRO': Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('Thường', style: TextStyle(fontSize: 13)),
        ),
        'STUDIO': Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('Studio', style: TextStyle(fontSize: 13)),
        ),
        'CHUNG_CU_MINI': Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('1 PN', style: TextStyle(fontSize: 13)),
        ),
        'CHUNG_CU': Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text('2 PN', style: TextStyle(fontSize: 13)),
        ),
      },
      onValueChanged: (v) {
        if (v != null) setState(() => _roomType = v);
      },
    );
  }

  Widget _buildCounter(String label, int value, ValueChanged<int> onChanged) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  if (value > 1) {
                    onChanged(value - 1);
                    unawaited(HapticFeedback.selectionClick());
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.minus, size: 16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$value',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (value < 10) {
                    onChanged(value + 1);
                    unawaited(HapticFeedback.selectionClick());
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.plus, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFurnitureLevelSelector() {
    return CupertinoSlidingSegmentedControl<String>(
      groupValue: _furnitureLevel,
      children: const {
        'TRONG': Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text('Phòng trống', style: TextStyle(fontSize: 13)),
        ),
        'CO_BAN': Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text('Cơ bản', style: TextStyle(fontSize: 13)),
        ),
        'FULL': Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text('Full đồ', style: TextStyle(fontSize: 13)),
        ),
      },
      onValueChanged: (v) {
        if (v != null) {
          setState(() {
            _furnitureLevel = v;
            if (v == 'TRONG') _furnitureItems.clear();
            if (v == 'CO_BAN') {
              _furnitureItems.clear();
              // Cơ bản: chỉ những món cốt lõi
              _furnitureItems.addAll(['AC', 'GIUONG']);
              if (_hasKitchen) _furnitureItems.addAll(['TU_BEP', 'BEP_TU']);
              if (_isSelfContained) {
                _furnitureItems.addAll(['BINH_NONG_LANH', 'VOI_SEN']);
              }
            }
            if (v == 'FULL') {
              _furnitureItems.clear();
              _furnitureItems.addAll([
                'AC',
                'TU_LANH',
                'MAY_GIAT',
                'GIUONG',
                'TU_QUAN_AO',
                'BAN_GHE',
                'SOFA',
              ]);
              if (_hasKitchen) {
                _furnitureItems.addAll([
                  'TU_BEP',
                  'BEP_TU',
                  'LO_VI_SONG',
                  'HUT_MUI',
                ]);
              }
              if (_isSelfContained) {
                _furnitureItems.addAll(['BINH_NONG_LANH', 'VOI_SEN', 'BET']);
              }
            }
          });
        }
      },
    );
  }

  Widget _buildFurnitureChips() {
    // ── Items by zone ──
    const roomItems = {
      'AC': ('Ðiều hòa', '❄️'),
      'TU_LANH': ('Tủ lạnh', '🧊'),
      'MAY_GIAT': ('Máy giặt', '🫧'),
      'GIUONG': ('Giường đệm', '🛏️'),
      'TU_QUAN_AO': ('Tủ quần áo', '👔'),
      'BAN_GHE': ('Bàn ghế', '🪑'),
      'SOFA': ('Sofa', '🛋️'),
    };
    const kitchenItems = {
      'TU_BEP': ('Tủ bếp', '🗄️'),
      'BEP_TU': ('Bếp từ/gas', '🔥'),
      'LO_VI_SONG': ('Lò vi sóng', '📡'),
      'HUT_MUI': ('Hút mùi', '💨'),
    };
    const wcItems = {
      'BINH_NONG_LANH': ('Bình nóng lạnh', '🚿'),
      'VOI_SEN': ('Vòi sen', '🪣'),
      'BET': ('Bệt xịt', '🚽'),
    };

    Widget subsection(
      String title,
      String icon,
      Map<String, (String, String)> items,
    ) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 8),
            child: Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.entries.map((e) {
              final sel = _furnitureItems.contains(e.key);
              final fKey = 'FURNITURE_${e.key}';
              final photoCount = sel
                  ? ((_photoUrls[fKey]?.length ?? 0) +
                        (_photoLocals[fKey]?.length ?? 0))
                  : 0;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (sel) {
                      _furnitureItems.remove(e.key);
                    } else {
                      _furnitureItems.add(e.key);
                      _ensureFurniturePhotoGroup(e.key);
                    }
                  });
                  unawaited(HapticFeedback.selectionClick());
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: sel
                        ? const LinearGradient(
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          )
                        : null,
                    color: sel ? null : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: sel ? Colors.transparent : const Color(0xFFE5E7EB),
                    ),
                    boxShadow: sel
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (sel)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(
                            CupertinoIcons.checkmark_alt_circle_fill,
                            size: 16,
                            color: Colors.white,
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            e.value.$2,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      Text(
                        e.value.$1,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                          color: sel ? Colors.white : const Color(0xFF4B5563),
                        ),
                      ),
                      if (sel && photoCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            '$photoCount ảnh',
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
          // Inline photo upload for selected items in this zone
          ...items.entries
              .where((e) => _furnitureItems.contains(e.key))
              .map(
                (e) =>
                    _buildFurniturePhotoUpload(e.key, e.value.$1, e.value.$2),
              ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Zone 1: Phòng (always)
        subsection('Nội thất Phòng', '🛋️', roomItems),
        // Zone 2: Bếp (only if _hasKitchen)
        if (_hasKitchen)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: subsection('Thiết bị Bếp', '🍳', kitchenItems),
          )
        else
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Row(
              children: [
                Icon(
                  CupertinoIcons.info_circle,
                  size: 14,
                  color: Color(0xFF9CA3AF),
                ),
                SizedBox(width: 6),
                Text(
                  'Bật "Bếp" ở phần Cấu Trúc để thêm thiết bị bếp',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        // Zone 3: WC riêng (only if _isSelfContained)
        if (_isSelfContained)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFC7E2FF)),
            ),
            child: subsection('Thiết bị WC Riêng', '🚿', wcItems),
          )
        else
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Row(
              children: [
                Icon(
                  CupertinoIcons.info_circle,
                  size: 14,
                  color: Color(0xFF9CA3AF),
                ),
                SizedBox(width: 6),
                Text(
                  'Chọn "Khép kín" ở Loại phòng để thêm thiết bị WC',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFurniturePhotoUpload(String key, String label, String emoji) {
    final fKey = 'FURNITURE_$key';
    _ensureFurniturePhotoGroup(key);
    final urls = _photoUrls[fKey]!;
    final locals = _photoLocals[fKey]!;
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
                    onTap: () => _pickPhotos(fKey, max: 2),
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
                onTap: () => _pickPhotos(fKey, max: 2),
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
              _buildThumbnailRow(fKey, max: 2),
          ],
        ),
      ),
    );
  }
}
