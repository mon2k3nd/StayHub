part of '../../create_branch_screen.dart';

// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api

extension Step1InfoWidgetExt on _CreateBranchScreenState {
  Future<void> _onWardSelected(Map<String, dynamic> w) async {
    final hadPin = _latitude != null;
    setState(() {
      _selectedWard63 = w;
      // Xóa toạ độ cũ vì địa chỉ đã thay đổi
      _latitude = null;
      _longitude = null;
      _isPinned = false;
    });
    await _autoGeocodeToWard();

    if (hadPin && mounted) {
      ToastUtils.show(
        context,
        'Xã/Phường đã thay đổi. Vui lòng ghim lại bản đồ để xác nhận vị trí mới.',
      );
    }

    // Auto-open Map Picker for pinning
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) {
        unawaited(_openMapPicker());
      }
    }
  }

  Future<void> _onDistrictSelected(Map<String, dynamic> d) async {
    setState(() {
      _selectedDistrict63 = d;
      _wards63 = [];
      _selectedWard63 = null;
      // Xóa toạ độ cũ vì địa chỉ đã thay đổi
      _latitude = null;
      _longitude = null;
      _isPinned = false;
    });
    unawaited(_autoGeocodeToDistrict());

    // BUGFIX (data): `id` có thể là num/null → tránh TypeError.
    await _fetchWards63(d['id']?.toString() ?? '');

    // Auto-open Ward selection
    if (mounted && _wards63.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) {
        unawaited(
          _showSearchableBottomSheet(
            title: 'Chọn Phường / Xã',
            items: _wards63,
            onSelected: _onWardSelected,
          ),
        );
      }
    }
  }

  Future<void> _onProvinceSelected(Map<String, dynamic> p) async {
    setState(() {
      _selectedDistrict63Province = p;
      _districts63 = [];
      _wards63 = [];
      _selectedDistrict63 = null;
      _selectedWard63 = null;
      // Xóa toạ độ cũ vì Tỉnh/Thành phố đã thay đổi
      _latitude = null;
      _longitude = null;
      _isPinned = false;
    });
    unawaited(_autoGeocodeToProvince());

    // Fetch and auto-open District selection
    // BUGFIX (data): `id` có thể là num/null → tránh TypeError.
    await _fetchDistricts63(p['id']?.toString() ?? '');
    if (mounted && _districts63.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 350));
      if (mounted) {
        unawaited(
          _showSearchableBottomSheet(
            title: 'Chọn Quận / Huyện',
            items: _districts63,
            onSelected: _onDistrictSelected,
          ),
        );
      }
    }
  }

  Widget _buildStep1Info() {
    final groupedPois = <String, List<Map<String, dynamic>>>{};
    if (!_isLoadingPOIs && _pois.isNotEmpty) {
      for (final poi in _pois) {
        // BUGFIX (data): `category` có thể null/không phải String.
        final poiCat = poi['category']?.toString() ?? 'OTHER';
        groupedPois.putIfAbsent(poiCat, () => []).add(poi);
      }
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── ẢNH MẶT TIỀN (đứng đầu — khớp checklist bên ngoài) ────
          _buildSectionTitle('ẢNH MẶT TIỀN'),
          const SizedBox(height: 10),
          _buildCoverPhotoPicker(),
          const SizedBox(height: 16),

          // ── TÊN DÃY TRỌ ──────────────────────────────────────────
          IOSGroupedSection(
            title: 'THÔNG TIN CHUNG',
            children: [
              _buildInput(
                ctrl: _nameCtrl,
                placeholder: 'Tên dãy trọ (VD: Trọ Sinh Viên H5)',
                icon: CupertinoIcons.building_2_fill,
                onChanged: generateBranchCode,
                maxLength: _CreateBranchScreenState._maxNameLength,
              ),
              // Mã chi nhánh (ID) tự sinh từ tên — CHỈ ĐỌC, không cho sửa.
              _buildReadOnlyCodeField(),
            ],
          ),
          // Real-time duplicate indicator
          if (_isCheckingCode)
            const Padding(
              padding: EdgeInsets.only(top: 8, left: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 11,
                    height: 11,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                  SizedBox(width: 7),
                  Text(
                    'Đang kiểm tra mã…',
                    style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            )
          else if (_isBranchCodeTaken)
            const Padding(
              padding: EdgeInsets.only(top: 8, left: 4),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.xmark_circle_fill,
                    size: 13,
                    color: Color(0xFFEF4444),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Mã đã tồn tại',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else if (_branchCodeCtrl.text.isNotEmpty && !_isCheckingCode)
            const Padding(
              padding: EdgeInsets.only(top: 8, left: 4),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    size: 13,
                    color: Color(0xFF10B981),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Mã hợp lệ',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF10B981),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // ── PCCC ─────────────────────────────────────────────────
          const SizedBox(height: 12),
          IOSGroupedSection(
            title: 'PHÒNG CHÁY CHỮA CHÁY (PCCC)',
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        CupertinoIcons.flame_fill,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        'Trang bị hệ thống PCCC',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                    ),
                    CupertinoSwitch(
                      value: _hasPccc,
                      activeTrackColor: const Color(0xFF34C759),
                      onChanged: (val) => setState(() => _hasPccc = val),
                    ),
                  ],
                ),
              ),
              if (_hasPccc) ...[
                if (_pcccPhotos.length + _networkPcccPhotos.length < 3)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: GestureDetector(
                      onTap: () {
                        int remaining =
                            3 - _pcccPhotos.length - _networkPcccPhotos.length;
                        if (remaining <= 0) return;
                        unawaited(
                          ImagePickerUtils.showPicker(
                            context: context,
                            limit: remaining,
                            onPicked: (picked) {
                              setState(() {
                                for (var p in picked) {
                                  if (_pcccPhotos.length < 3) {
                                    // Giữ nguyên XFile: đọc bytes được trên web.
                                    _pcccPhotos.add(p);
                                  }
                                }
                              });
                            },
                          ),
                        );
                        unawaited(HapticFeedback.lightImpact());
                      },
                      child: Container(
                        width: double.infinity,
                        height: 110,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE5E5EA),
                            style: BorderStyle.solid,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.06),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                CupertinoIcons.camera_viewfinder,
                                color: Color(0xFF007AFF),
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Tải ảnh thiết bị PCCC',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1C1C1E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_pcccPhotos.isNotEmpty || _networkPcccPhotos.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount:
                            _networkPcccPhotos.length + _pcccPhotos.length,
                        itemBuilder: (context, index) {
                          final isNetwork = index < _networkPcccPhotos.length;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: isNetwork
                                      ? _buildPcccImage(
                                          _networkPcccPhotos[index],
                                          width: 80,
                                          height: 80,
                                        )
                                      : XFileImage(
                                          _pcccPhotos[index -
                                              _networkPcccPhotos.length],
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (isNetwork) {
                                          _networkPcccPhotos.removeAt(index);
                                        } else {
                                          _pcccPhotos.removeAt(
                                            index - _networkPcccPhotos.length,
                                          );
                                        }
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.5,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ],
          ),

          // ── ĐỊA CHỈ ──────────────────────────────────────────────
          const SizedBox(height: 12),
          IOSGroupedSection(
            title: 'ĐỊA CHỈ',
            children: [
              // Thông báo địa chỉ đã bị khóa khi chỉnh sửa chi nhánh đã có địa chỉ.
              if (_isAddressLocked)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.lock_fill,
                        size: 14,
                        color: Color(0xFF8E8E93),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Địa chỉ đã được khóa và không thể thay đổi.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF8E8E93),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Step 1: Tỉnh / Thành phố
              if (_provinces.isEmpty)
                _buildLoadingField('Đang tải danh sách tỉnh...')
              else
                _buildSelectField(
                  hint: 'Chọn Tỉnh / Thành phố',
                  value:
                      _selectedDistrict63Province?['full_name'] ??
                      _selectedDistrict63Province?['name'],
                  icon: CupertinoIcons.map,
                  items: _provinces,
                  onSelected: _onProvinceSelected,
                  locked: _isAddressLocked,
                ),

              // Step 2: Quận / Huyện (animated reveal)
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child:
                    (_selectedDistrict63Province == null && !_hasSavedAddress)
                    ? const SizedBox.shrink()
                    : Column(
                        children: [
                          if (_isLoadingDistricts63)
                            _buildLoadingField('Đang tải Quận / Huyện...')
                          else if (_districts63.isNotEmpty)
                            _buildSelectField(
                              hint: 'Chọn Quận / Huyện',
                              value:
                                  _selectedDistrict63?['full_name'] ??
                                  _selectedDistrict63?['name'],
                              icon: CupertinoIcons.location,
                              items: _districts63,
                              onSelected: _onDistrictSelected,
                              locked: _isAddressLocked,
                            ),
                        ],
                      ),
              ),

              // Step 3: Phường / Xã (animated reveal)
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: (_selectedDistrict63 == null && !_hasSavedAddress)
                    ? const SizedBox.shrink()
                    : Column(
                        children: [
                          if (_isLoadingWards63)
                            _buildLoadingField('Đang tải Phường / Xã...')
                          else if (_wards63.isNotEmpty)
                            _buildSelectField(
                              hint: 'Chọn Phường / Xã',
                              value:
                                  _selectedWard63?['full_name'] ??
                                  _selectedWard63?['name'],
                              icon: CupertinoIcons.house,
                              items: _wards63,
                              onSelected: _onWardSelected,
                              locked: _isAddressLocked,
                            ),
                        ],
                      ),
              ),

              // Step 4: Số nhà + Tên đường gộp (animated reveal)
              // Hiện khi đã chọn Phường/Xã HOẶC chi nhánh đang sửa đã có địa chỉ
              // lưu sẵn — tránh việc khôi phục dropdown thất bại (tên không khớp
              // danh mục) làm ẩn mất ô nhập Số nhà / Tên đường.
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                child: (_selectedWard63 == null && !_hasSavedAddress)
                    ? const SizedBox.shrink()
                    : Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildInput(
                                  ctrl: _houseNumberCtrl,
                                  placeholder: 'Số nhà, ngõ ngách',
                                  icon: CupertinoIcons.house_fill,
                                  onChanged: (_) => setState(() {}),
                                  readOnly: _isAddressLocked,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 3,
                                child: _buildInput(
                                  ctrl: _addressDetailCtrl,
                                  placeholder: 'Tên đường (VD: Trần Cung)',
                                  icon: CupertinoIcons.map_pin_ellipse,
                                  onChanged: (_) => setState(() {}),
                                  readOnly: _isAddressLocked,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ],
          ),

          // ── LOCATION CARD ─────────────────────────────────────────
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isPinned
                  ? const Color(0xFFF0FDF4)
                  : const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isPinned
                    ? const Color(0xFF6EE7B7)
                    : const Color(0xFFDDE3F0),
                width: _isPinned ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: _isPinned
                      ? const Color(0xFF10B981).withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _isPinned
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : const Color(0xFF0EA5E9).withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isPinned
                            ? CupertinoIcons.checkmark_seal_fill
                            : CupertinoIcons.location_fill,
                        size: 18,
                        color: _isPinned
                            ? const Color(0xFF10B981)
                            : const Color(0xFF0EA5E9),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isPinned ? 'Đã ghim vị trí' : 'Chưa ghim vị trí',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: _isPinned
                                  ? const Color(0xFF065F46)
                                  : const Color(0xFF374151),
                            ),
                          ),
                          if (_isPinned && _latitude != null)
                            Text(
                              '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: _isAddressLocked ? null : _openMapPicker,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isAddressLocked
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF0EA5E9),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _isAddressLocked
                                ? []
                                : const [
                                    BoxShadow(
                                      color: Color(0x33298FFF),
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isAddressLocked
                                    ? CupertinoIcons.lock_fill
                                    : CupertinoIcons.map_fill,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isAddressLocked
                                    ? 'Địa chỉ đã khóa'
                                    : 'Mở bản đồ chọn vị trí',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: _isAddressLocked
                            ? null
                            : () {
                                unawaited(HapticFeedback.selectionClick());
                                if (!_isFetchingLocation) {
                                  unawaited(_getCurrentLocation());
                                }
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isFetchingLocation
                                ? const Color(0xFFE5E7EB)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.transparent),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x08000000),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                              BoxShadow(
                                color: Color(0x0A000000),
                                blurRadius: 24,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isFetchingLocation)
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF6B7280),
                                  ),
                                )
                              else
                                const Icon(
                                  CupertinoIcons.location_fill,
                                  size: 16,
                                  color: Color(0xFF6E6E73),
                                ),
                              const SizedBox(width: 6),
                              Text(
                                _isFetchingLocation ? 'Đang lấy...' : 'GPS tôi',
                                style: TextStyle(
                                  color: _isFetchingLocation
                                      ? const Color(0xFF6B7280)
                                      : const Color(0xFF4B5563),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // ── MAP PREVIEW STATIC ─────────────────────────
                Builder(
                  builder: (context) {
                    final displayLat = (_isPinned && _latitude != null)
                        ? _latitude!
                        : (_previewLat ?? 21.028511);
                    final displayLon = (_isPinned && _longitude != null)
                        ? _longitude!
                        : (_previewLon ?? 105.804817);

                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: GestureDetector(
                        onTap: _isAddressLocked ? null : _openMapPicker,
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isPinned
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFE5E7EB),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _isPinned
                                    ? const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.12)
                                    : Colors.black.withValues(alpha: 0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              Hero(
                                tag: 'map_hero',
                                child: FlutterMap(
                                  key: ValueKey('$displayLat-$displayLon'),
                                  options: MapOptions(
                                    initialCenter: LatLng(
                                      displayLat,
                                      displayLon,
                                    ),
                                    initialZoom: 15.5,
                                    interactionOptions:
                                        const InteractionOptions(
                                          flags: InteractiveFlag.none,
                                        ), // static
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate:
                                          'https://mt1.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                                      userAgentPackageName: 'com.stayhub.app',
                                    ),
                                  ],
                                ),
                              ),
                              // Center pin (no ghost shadow)
                              Center(
                                child: Transform.translate(
                                  offset: const Offset(0, -18),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: _isPinned
                                              ? const Color(0xFFFF3B30)
                                              : const Color(0xFF9CA3AF),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 3,
                                          ),
                                        ),
                                        child: const Icon(
                                          CupertinoIcons.location_solid,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                      CustomPaint(
                                        size: const Size(12, 8),
                                        painter: _PinTailPainter(
                                          color: _isPinned
                                              ? const Color(0xFFFF3B30)
                                              : const Color(0xFF9CA3AF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Badge
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isPinned
                                        ? const Color(
                                            0xFF10B981,
                                          ).withValues(alpha: 0.9)
                                        : Colors.black.withValues(alpha: 0.65),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _isPinned
                                            ? CupertinoIcons.checkmark_seal_fill
                                            : CupertinoIcons.hand_draw_fill,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _isPinned ? 'Đã ghim' : 'Chạm để ghim',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Edit Button Overlay
                              if (_isPinned)
                                Positioned(
                                  bottom: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(100),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          CupertinoIcons.pencil,
                                          size: 14,
                                          color: Color(0xFF111827),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Thay đổi',
                                          style: TextStyle(
                                            color: Color(0xFF111827),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
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
                    );
                  },
                ),
              ],
            ),
          ),

          // ── HIỂN THỊ ĐỊA CHỈ SAU KHI GIM ─────────────────────────
          // Hiển thị khi đã ghim HOẶC khi đang chỉnh sửa chi nhánh đã có địa chỉ
          // (tránh việc mở "Chỉnh sửa" mà khối địa chỉ biến mất khi dropdown
          // Tỉnh/Huyện/Xã không khôi phục được do tên không khớp danh mục).
          if (_isPinned || _hasSavedAddress)
            Builder(
              builder: (context) {
                final streetPart = _addressDetailCtrl.text.trim();
                final housePart = _houseNumberCtrl.text.trim();
                final wardName =
                    _selectedWard63?['full_name'] ??
                    _selectedWard63?['name'] ??
                    '';
                final distName =
                    _selectedDistrict63?['full_name'] ??
                    _selectedDistrict63?['name'] ??
                    '';

                // provName: ưu tiên lấy từ map đã chọn, fallback về local AddressData bằng id
                String provName =
                    _selectedDistrict63Province?['full_name'] ??
                    _selectedDistrict63Province?['name'] ??
                    '';
                if (provName.isEmpty && _selectedDistrict63Province != null) {
                  final rawId =
                      _selectedDistrict63Province!['id']?.toString() ?? '';
                  // Thử zero-pad nếu cần (API có thể trả về "1" thay vì "01")
                  for (final tryId in [rawId, rawId.padLeft(2, '0')]) {
                    final localProv = AddressData.getProvinces63Sorted()
                        .firstWhere(
                          (p) => p['id']?.toString() == tryId,
                          orElse: () => <String, dynamic>{},
                        );
                    provName =
                        localProv['full_name'] ?? localProv['name'] ?? '';
                    if (provName.isNotEmpty) break;
                  }
                }

                // Địa chỉ chuẩn (có quận)
                var oldFullAddr = [
                  if (housePart.isNotEmpty) housePart,
                  if (streetPart.isNotEmpty) streetPart,
                  wardName,
                  if (distName.isNotEmpty) distName,
                  provName,
                ].where((e) => e.isNotEmpty).join(', ');

                // Fallback: nếu không dựng được từ dropdown (khôi phục thất bại),
                // dùng nguyên chuỗi địa chỉ đã lưu để không hiển thị trống.
                if (oldFullAddr.trim().isEmpty) {
                  oldFullAddr =
                      widget.branchToEdit?.addressOld?.trim().isNotEmpty == true
                      ? widget.branchToEdit!.addressOld!.trim()
                      : (widget.branchToEdit?.address.trim() ?? '');
                }
                if (oldFullAddr.trim().isEmpty) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 4, right: 8),
                          child: Icon(
                            CupertinoIcons.location_solid,
                            size: 16,
                            color: Color(0xFF0EA5E9),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            oldFullAddr,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Color(0xFF1E293B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 20),
        ],
      ),
    );
  } // end _buildStep1Info

  /// Khối chọn ảnh mặt tiền (tách riêng để đặt lên ĐẦU màn hình Bước 1,
  /// khớp đúng thứ tự checklist bên ngoài: Ảnh → Tên & mã → Địa chỉ → …).
  Widget _buildCoverPhotoPicker() {
    if (_coverPhotos.isEmpty && _networkCoverPhotos.isEmpty) {
      return GestureDetector(
        onTap: () {
          int remaining = 5 - _coverPhotos.length - _networkCoverPhotos.length;
          if (remaining <= 0) return;
          unawaited(
            ImagePickerUtils.showPicker(
              context: context,
              limit: remaining,
              onPicked: (picked) {
                setState(() {
                  for (var p in picked) {
                    if (_coverPhotos.length < 5) _coverPhotos.add(p);
                  }
                });
              },
            ),
          );
        },
        child: Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.transparent),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.camera_fill,
                color: Color(0xFF9CA3AF),
                size: 32,
              ),
              SizedBox(height: 8),
              Text(
                'Tải ảnh lên',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }
    // Đã có ảnh (mạng hoặc local) — hiển thị lưới ảnh + nút thêm.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 110,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (int i = 0; i < _networkCoverPhotos.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _buildCoverThumb(
                    child: _buildPcccImage(
                      _networkCoverPhotos[i],
                      width: 150,
                      height: 110,
                    ),
                    onRemove: () =>
                        setState(() => _networkCoverPhotos.removeAt(i)),
                  ),
                ),
              for (int i = 0; i < _coverPhotos.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _buildCoverThumb(
                    child: XFileImage(
                      _coverPhotos[i],
                      width: 150,
                      height: 110,
                      fit: BoxFit.cover,
                    ),
                    onRemove: () => setState(() => _coverPhotos.removeAt(i)),
                  ),
                ),
              if (_coverPhotos.length + _networkCoverPhotos.length < 5)
                GestureDetector(
                  onTap: () {
                    int remaining =
                        5 - _coverPhotos.length - _networkCoverPhotos.length;
                    if (remaining <= 0) return;
                    unawaited(
                      ImagePickerUtils.showPicker(
                        context: context,
                        limit: remaining,
                        onPicked: (picked) {
                          setState(() {
                            for (var p in picked) {
                              if (_coverPhotos.length < 5) _coverPhotos.add(p);
                            }
                          });
                        },
                      ),
                    );
                  },
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E5EA)),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.plus,
                          color: Color(0xFF9CA3AF),
                          size: 26,
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Thêm ảnh',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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
    );
  }

  /// Hiển thị ảnh PCCC đã lưu: hỗ trợ cả URL (http/https, đường dẫn tương đối)
  /// lẫn chuỗi base64 (do submit() gửi lên). Trước đây luôn dùng Image.network
  /// nên ảnh base64 không render được → người dùng thấy "mất ảnh PCCC".
  Widget _buildPcccImage(String raw, {double? width, double? height}) {
    final value = raw.trim();
    if (value.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: const Color(0xFFF2F2F7),
        child: const Icon(CupertinoIcons.photo, color: Color(0xFF8E8E93)),
      );
    }

    // Chuỗi base64 thuần (không phải URL) → decode và dùng Image.memory.
    final bool looksLikeUrl =
        value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('/') ||
        value.startsWith('data:');
    if (!looksLikeUrl) {
      try {
        final bytes = base64Decode(value);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: width,
            height: height,
            color: const Color(0xFFF2F2F7),
            child: const Icon(CupertinoIcons.photo, color: Color(0xFF8E8E93)),
          ),
        );
      } catch (_) {
        // Không phải base64 hợp lệ — thử render như URL bên dưới.
      }
    }

    final String url = value.startsWith('http') || value.startsWith('data:')
        ? value
        : '${ApiClient.baseUrl}$value';
    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: const Color(0xFFF2F2F7),
        child: const Icon(CupertinoIcons.photo, color: Color(0xFF8E8E93)),
      ),
    );
  }

  Widget _buildCoverThumb({
    required Widget child,
    required VoidCallback onRemove,
  }) {
    return Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(16), child: child),
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.xmark,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Ô hiển thị Mã chi nhánh (ID) — CHỈ ĐỌC.
  /// Mã được tự sinh từ tên chi nhánh, người dùng không sửa trực tiếp.
  Widget _buildReadOnlyCodeField() {
    final code = _branchCodeCtrl.text.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: const Icon(
              CupertinoIcons.tag_fill,
              color: Color(0xFF0EA5E9),
              size: 16,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              code.isEmpty ? 'Mã chi nhánh (ID)' : code,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: code.isEmpty
                    ? const Color(0xFF9CA3AF)
                    : const Color(0xFF1C1C1E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectField({
    required String hint,
    required String? value,
    required IconData icon,
    required List<dynamic> items,
    required void Function(Map<String, dynamic>) onSelected,
    bool locked = false,
  }) {
    return _AnimatedSelectField(
      hint: hint,
      value: value,
      icon: icon,
      items: items,
      onTap: locked
          ? null
          : () {
              unawaited(HapticFeedback.selectionClick());
              unawaited(
                _showSearchableBottomSheet(
                  title: hint,
                  items: items,
                  onSelected: onSelected,
                ),
              );
            },
    );
  }

  Future<void> _showSearchableBottomSheet({
    required String title,
    required List<dynamic> items,
    required void Function(Map<String, dynamic>) onSelected,
  }) async {
    List<dynamic> filtered = List.from(items);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return FractionallySizedBox(
              heightFactor: 0.88,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFAFAFC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    // ── DRAG HANDLE ───────────────────────────────
                    const SizedBox(height: 12),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1D5DB),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── TITLE ─────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF0EA5E9,
                              ).withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              CupertinoIcons.search,
                              size: 18,
                              color: Color(0xFF0EA5E9),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── SEARCH ───────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.transparent),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x08000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 24,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CupertinoSearchTextField(
                          placeholder: 'Tìm nhanh... (có thể gõ không dấu)',
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 13,
                          ),
                          style: const TextStyle(fontSize: 15),
                          onChanged: (val) {
                            setModalState(() {
                              final query = _removeDiacritics(
                                val.toLowerCase(),
                              );
                              filtered = items.where((item) {
                                final display = _removeDiacritics(
                                  (item['full_name'] ?? item['name'] ?? '')
                                      .toString()
                                      .toLowerCase(),
                                );
                                return display.startsWith(query) ||
                                    display.contains(query);
                              }).toList();
                              if (query.isNotEmpty) {
                                filtered.sort((a, b) {
                                  final an = _removeDiacritics(
                                    (a['full_name'] ?? a['name'] ?? '')
                                        .toString()
                                        .toLowerCase(),
                                  );
                                  final bn = _removeDiacritics(
                                    (b['full_name'] ?? b['name'] ?? '')
                                        .toString()
                                        .toLowerCase(),
                                  );
                                  final ap = an.startsWith(query) ? 0 : 1;
                                  final bp = bn.startsWith(query) ? 0 : 1;
                                  return ap.compareTo(bp);
                                });
                              }
                            });
                          },
                        ),
                      ),
                    ),

                    // ── COUNT BADGE ──────────────────────────────────
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: filtered.isEmpty
                          ? const SizedBox.shrink()
                          : Padding(
                              key: ValueKey(filtered.length),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF0EA5E9,
                                      ).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Text(
                                      '${filtered.length} kết quả',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0EA5E9),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),

                    // ── LIST ─────────────────────────────────────────
                    if (filtered.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  CupertinoIcons.search,
                                  size: 32,
                                  color: Color(0xFFD1D5DB),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Không tìm thấy kết quả',
                                style: TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Thử gõ không dấu, VD: "giao ha"',
                                style: TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: AnimationLimiter(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final item =
                                  filtered[index] as Map<String, dynamic>;
                              final display =
                                  (item['full_name'] ?? item['name'] ?? '')
                                      .toString();
                              return AnimationConfiguration.staggeredList(
                                position: index,
                                duration: const Duration(milliseconds: 280),
                                delay: const Duration(milliseconds: 25),
                                child: SlideAnimation(
                                  verticalOffset: 20,
                                  child: FadeInAnimation(
                                    child: _AddressListItem(
                                      display: display,
                                      onTap: () {
                                        unawaited(
                                          HapticFeedback.selectionClick(),
                                        );
                                        Navigator.pop(ctx);
                                        onSelected(item);
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Xoá dấu tiếng Việt để tìm kiếm không phân biệt dấu.
  /// VD: "giao hà" → "giao ha", "Phường Đông Hương" → "phuong dong huong"
  String _removeDiacritics(String s) {
    const from =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ'
        'ÀÁẠẢÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';
    const to =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd'
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    final buf = StringBuffer();
    for (final ch in s.runes) {
      final c = String.fromCharCode(ch);
      final idx = from.indexOf(c);
      buf.write(idx >= 0 ? to[idx] : c);
    }
    return buf.toString();
  }
}

/// Widget dropdown cho địa chỉ với hiệu ứng press animation.
