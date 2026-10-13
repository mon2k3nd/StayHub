part of '../../create_branch_screen.dart';

// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api

extension CreateBranchDialogsExt on _CreateBranchScreenState {
  void _showDialog(
    String title,
    String content, {
    bool isError = true,
    VoidCallback? onSuccess,
  }) {
    if (isError) {
      InAppNotificationBanner.show(
        context,
        title: title,
        body: content,
        icon: CupertinoIcons.exclamationmark_circle_fill,
        iconColor: const Color(0xFFEF4444),
      );
    } else {
      unawaited(
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.pop(ctx);
                  if (onSuccess != null) onSuccess();
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  void showAddCustomAmenityDialog() {
    final TextEditingController ctrl = TextEditingController();
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Thêm tiện ích mới'),
          content: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: CupertinoTextField(
              controller: ctrl,
              placeholder: 'Tên tiện ích (VD: Lọc nước RO)',
              autofocus: true,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Hủy'),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Thêm'),
              onPressed: () {
                final name = ctrl.text.trim();
                if (name.isNotEmpty) {
                  setState(() {
                    if (!_customAmenities.contains(name) &&
                        !_getDefaultAmenities(_catId).contains(name)) {
                      _customAmenities.add(name);
                    }
                    _selectedAmenities[name] = {
                      'price': 0.0,
                      'chargeType': 'free',
                    };
                  });
                }
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAmenityConfigBottomSheet(String amenityName) {
    final existing = _selectedAmenities[amenityName];
    // BUGFIX (data): coerce an toàn — tránh `as double` ném TypeError khi
    // price là int/String/null.
    final existingPrice = existing?['price'];
    final existingPriceNum = existingPrice is num
        ? existingPrice.toDouble()
        : double.tryParse(existingPrice?.toString() ?? '') ?? 0.0;
    final priceCtrl = TextEditingController(
      text: existingPriceNum > 0 ? existingPriceNum.toStringAsFixed(0) : '',
    );
    String selectedChargeType = existing?['chargeType']?.toString() ?? 'free';
    bool isMandatory = existing?['isMandatory'] == true;

    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(
                        Icons.settings_outlined,
                        color: Color(0xFF0EA5E9),
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          amenityName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      if (existing != null)
                        TextButton.icon(
                          onPressed: () {
                            setState(
                              () => _selectedAmenities.remove(amenityName),
                            );
                            Navigator.pop(ctx);
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Color(0xFFEF4444),
                          ),
                          label: const Text(
                            'Xóa',
                            style: TextStyle(color: Color(0xFFEF4444)),
                          ),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Phương thức thu phí',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...{
                    'free': (
                      'Miễn phí',
                      'Không thu thêm phí cho tiện ích này',
                      Icons.card_giftcard_outlined,
                    ),
                    'per_room': (
                      'Thu theo phòng',
                      'Tính phí cố định trên mỗi phòng/tháng',
                      Icons.door_front_door_outlined,
                    ),
                    'per_person': (
                      'Thu theo người',
                      'Tính phí trên mỗi cư dân/tháng',
                      Icons.person_outline,
                    ),
                  }.entries.map((entry) {
                    final isActive = selectedChargeType == entry.key;
                    return GestureDetector(
                      onTap: () =>
                          setSheetState(() => selectedChargeType = entry.key),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFFE0F2FE)
                              : const Color(0xFFF9FAFB),
                          border: Border.all(
                            color: isActive
                                ? const Color(0xFF0EA5E9)
                                : const Color(0xFFE5E7EB),
                            width: isActive ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              entry.value.$3,
                              color: isActive
                                  ? const Color(0xFF0EA5E9)
                                  : const Color(0xFF9CA3AF),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.value.$1,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isActive
                                          ? const Color(0xFF0EA5E9)
                                          : const Color(0xFF374151),
                                    ),
                                  ),
                                  Text(
                                    entry.value.$2,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isActive)
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF0EA5E9),
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: selectedChargeType != 'free'
                        ? Column(
                            key: const ValueKey('price_input'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              const Text(
                                'Mức giá (VNĐ/tháng)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: priceCtrl,
                                keyboardType: TextInputType.number,
                                inputFormatters: [CurrencyInputFormatter()],
                                decoration: InputDecoration(
                                  hintText: 'VD: 50.000',
                                  suffixText: 'đ',
                                  filled: true,
                                  fillColor: const Color(0xFFF9FAFB),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: const BorderSide(
                                      color: Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF0EA5E9),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(key: ValueKey('no_price')),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.checkmark_seal_fill,
                          color: Color(0xFF10B981),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bắt buộc áp dụng',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Color(0xFF374151),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isMandatory
                                    ? 'Thu phí tất cả khách thuê'
                                    : 'Khách có thể chọn khi làm hợp đồng',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        CupertinoSwitch(
                          value: isMandatory,
                          activeTrackColor: const Color(0xFF10B981),
                          onChanged: (v) =>
                              setSheetState(() => isMandatory = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final price =
                            double.tryParse(
                              priceCtrl.text
                                  .replaceAll(',', '')
                                  .replaceAll('.', ''),
                            ) ??
                            0.0;
                        setState(() {
                          _selectedAmenities[amenityName] = {
                            'price': selectedChargeType == 'free' ? 0.0 : price,
                            'chargeType': selectedChargeType,
                            'isMandatory': isMandatory,
                          };
                        });
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0EA5E9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Xác nhận',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
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
    );
  }

  void showAssignWcBottomSheet(RoomDraft room) {
    if (_sharedWcs.isEmpty) {
      ToastUtils.show(context, 'Vui lòng thêm WC Chung trước!', isError: true);
      return;
    }

    unawaited(
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: 0.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) => Transform.translate(
              offset: Offset(
                0,
                MediaQuery.of(context).size.height * 0.5 * value,
              ),
              child: child,
            ),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(20),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Chọn WC Chung',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._sharedWcs.map(
                      (wc) => InkWell(
                        onTap: () {
                          setState(() => room.sharedWcId = wc.tempId);
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: room.sharedWcId == wc.tempId
                                ? const Color(0xFF0EA5E9).withValues(alpha: 0.1)
                                : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: room.sharedWcId == wc.tempId
                                  ? const Color(0xFF0EA5E9)
                                  : const Color(0xFFE5E7EB),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.drop_fill,
                                color: room.sharedWcId == wc.tempId
                                    ? const Color(0xFF0EA5E9)
                                    : const Color(0xFF9CA3AF),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                wc.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: room.sharedWcId == wc.tempId
                                      ? const Color(0xFF0EA5E9)
                                      : const Color(0xFF111827),
                                ),
                              ),
                              const Spacer(),
                              if (room.sharedWcId == wc.tempId)
                                const Icon(
                                  CupertinoIcons.checkmark_alt_circle_fill,
                                  color: Color(0xFF0EA5E9),
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
          );
        },
      ),
    );
  }

  void showAddPOIDialog() {
    final nameCtrl = TextEditingController();
    final distCtrl = TextEditingController();
    String selectedCat = 'Khác';
    final categories = [
      'Giáo dục',
      'Y tế',
      'Giao thông',
      'Mua sắm',
      'Giải trí',
      'Khác',
    ];

    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Material(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom,
                    left: 20,
                    right: 20,
                    top: 20,
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Thêm tiện ích thủ công',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Nếu hệ thống quét thiếu, bạn có thể tự thêm vào đây.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        _buildInput(
                          ctrl: nameCtrl,
                          placeholder: 'Tên địa điểm (VD: Chợ Lớn)',
                          icon: Icons.place,
                        ),
                        const SizedBox(height: 16),
                        _buildInput(
                          ctrl: distCtrl,
                          placeholder: 'Khoảng cách (km) - VD: 0.5',
                          icon: Icons.route,
                          type: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Loại tiện ích:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: categories.map((c) {
                            final isSel = c == selectedCat;
                            return GestureDetector(
                              onTap: () => setModalState(() => selectedCat = c),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? const Color(
                                          0xFF0EA5E9,
                                        ).withValues(alpha: 0.1)
                                      : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSel
                                        ? const Color(0xFF0EA5E9)
                                        : Colors.transparent,
                                  ),
                                ),
                                child: Text(
                                  c,
                                  style: TextStyle(
                                    color: isSel
                                        ? const Color(0xFF0EA5E9)
                                        : const Color(0xFF4B5563),
                                    fontWeight: isSel
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: CupertinoButton(
                            color: const Color(0xFF0EA5E9),
                            borderRadius: BorderRadius.circular(24),
                            child: const Text(
                              'Thêm địa điểm',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              final name = nameCtrl.text.trim();
                              final dist = double.tryParse(
                                distCtrl.text.replaceAll(',', '.'),
                              );

                              if (name.isEmpty || dist == null) {
                                _showDialog(
                                  'Lỗi',
                                  'Vui lòng nhập tên và khoảng cách hợp lệ (VD: 1.5)',
                                );
                                return;
                              }

                              setState(() {
                                _pois.add({
                                  'name': name,
                                  'category': selectedCat,
                                  'distanceKm': dist,
                                  'lat': _latitude,
                                  'lon': _longitude,
                                });
                                // BUGFIX (data): coerce an toàn — tránh
                                // `as double` ném TypeError khi distanceKm
                                // là int/String.
                                double dist0(dynamic v) => v is num
                                    ? v.toDouble()
                                    : double.tryParse(v?.toString() ?? '') ??
                                          0.0;
                                _pois.sort(
                                  (a, b) => dist0(
                                    a['distanceKm'],
                                  ).compareTo(dist0(b['distanceKm'])),
                                );
                              });
                              Navigator.pop(ctx);
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ); // End Material
            }, // End StatefulBuilder builder
          ); // End StatefulBuilder
        }, // End showModalBottomSheet builder
      ),
    ); // End showModalBottomSheet
  } // End showAddPOIDialog

  void showEditWcDialog(SharedWcDraft wc) {
    final wcNameCtrl = TextEditingController(text: wc.name);

    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return Material(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sửa tên WC',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildInput(
                      ctrl: wcNameCtrl,
                      placeholder: 'Tên WC (VD: Nhà vệ sinh 1)',
                      icon: CupertinoIcons.drop_fill,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        color: const Color(0xFF0EA5E9),
                        borderRadius: BorderRadius.circular(24),
                        child: const Text(
                          'Lưu thay đổi',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          if (wcNameCtrl.text.trim().isNotEmpty) {
                            setState(() {
                              wc.name = wcNameCtrl.text.trim();
                            });
                            Navigator.pop(ctx);
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ), // SafeArea
            ), // Padding
          ); // Material
        },
      ),
    );
  }

  void showBranchCodeConflictSheet(BranchModel conflicting) {
    final isDraft = conflicting.creationStatus == 'DRAFT';
    final isSuspended = conflicting.creationStatus == 'SUSPENDED';
    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 8,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.exclamationmark_circle_fill,
                  color: Color(0xFFF59E0B),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Mã chi nhánh trùng',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mã "${_autoGeneratedCode.isNotEmpty ? _autoGeneratedCode : _branchCodeCtrl.text}" đã được dùng bởi chi nhánh bên dưới. '
                '${isDraft
                    ? "Bạn có thể hủy bản nháp đó để giải phóng mã."
                    : isSuspended
                    ? "Chi nhánh này đang tạm ngừng. Hãy kích hoạt lại chi nhánh đó nếu muốn dùng lại mã, hoặc đổi tên để tạo mã mới."
                    : "Chi nhánh đang hoạt động — hãy đổi tên để tạo mã mới."}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // Conflicting branch card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDraft
                        ? const Color(0xFFFCD34D)
                        : const Color(0xFF10B981),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            (isDraft
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFF10B981))
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(
                        isDraft
                            ? CupertinoIcons.doc_text
                            : CupertinoIcons.building_2_fill,
                        color: isDraft
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF10B981),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conflicting.branchName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isDraft
                                      ? const Color(0xFFFEF3C7)
                                      : isSuspended
                                      ? const Color(0xFFF3F4F6)
                                      : const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  isDraft
                                      ? '📝 Bản nháp'
                                      : isSuspended
                                      ? '⏸️ Ngừng hoạt động'
                                      : '✅ Đang hoạt động',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDraft
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFF059669),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                conflicting.displayCode,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Actions
              if (isDraft) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(CupertinoIcons.trash_fill, size: 18),
                    label: const Text(
                      'Hủy bản nháp này',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        // DRAFT = "Hủy": xóa hẳn, mã coi như chưa từng xuất hiện.
                        await ref
                            .read(branchProvider.notifier)
                            .cancelDraftBranch(conflicting.id);
                        if (mounted) {
                          ToastUtils.show(
                            context,
                            'Đã hủy bản nháp. Mã chi nhánh đã được giải phóng!',
                          );
                          // Reset saved id so next submit does fresh create
                          setState(() => _savedBranchId = null);
                        }
                      } catch (e) {
                        if (mounted) {
                          _showDialog('Lỗi', 'Không thể hủy: ${e.toString()}');
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(CupertinoIcons.pencil, size: 18),
                  label: Text(
                    isDraft
                        ? 'Giữ lại & Đổi tên chi nhánh mới'
                        : 'Đổi tên để tạo mã mới',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0EA5E9),
                    side: const BorderSide(color: Color(0xFF0EA5E9)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    // Scroll back to step 0 and focus name field
                    unawaited(
                      _pageController.animateToPage(
                        0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      ),
                    );
                    setState(() => _currentStep = 0);
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (!mounted) return;
                      _nameCtrl.selection = TextSelection(
                        baseOffset: 0,
                        extentOffset: _nameCtrl.text.length,
                      );
                      unawaited(
                        showCupertinoDialog(
                          context: context,
                          builder: (c) => CupertinoAlertDialog(
                            title: const Text('Đổi tên chi nhánh'),
                            content: const Text(
                              'Hãy sửa lại tên chi nhánh để tạo mã mới khác.',
                            ),
                            actions: [
                              CupertinoDialogAction(
                                onPressed: () => Navigator.pop(c),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        ),
                      );
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Đóng',
                  style: TextStyle(color: Color(0xFF9CA3AF)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void showSummaryConfirmDialog() {
    // Helpers
    final fmt = NumberFormat('#,###', 'vi_VN');
    String fmtPrice(String raw) {
      final v =
          double.tryParse(raw.replaceAll(',', '').replaceAll('.', '')) ?? 0;
      return v == 0 ? '—' : '${fmt.format(v)}đ';
    }

    final address = [
      _houseNumberCtrl.text.trim(),
      _addressDetailCtrl.text.trim(),
      _selectedWard63?['name'],
      _selectedDistrict63?['name'],
      _selectedDistrict63Province?['name'],
    ].where((e) => e != null && e.toString().isNotEmpty).join(', ');

    // Category label
    String catLabel = '—';
    for (final cat in kRentalCategories) {
      for (final sub in cat.subModels) {
        if (sub.id == _subId) {
          catLabel = sub.title;
          break;
        }
      }
    }

    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return DraggableScrollableSheet(
            initialChildSize: 0.92,
            minChildSize: 0.6,
            maxChildSize: 0.95,
            builder: (_, scrollCtrl) => Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // ── Handle ──
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                  // ── Header ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Xem lại thông tin',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Kiểm tra kỹ trước khi tạo chi nhánh',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(ctx),
                          child: const Icon(
                            CupertinoIcons.xmark_circle_fill,
                            color: Color(0xFFD1D5DB),
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  // ── Scrollable content ──
                  Expanded(
                    child: ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                      children: [
                        // Cover photos
                        if (_coverPhotos.isNotEmpty ||
                            _networkCoverPhotos.isNotEmpty) ...[
                          _reviewSectionTitle('🖼 Ảnh bìa'),
                          SizedBox(
                            height: 120,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _networkCoverPhotos.isNotEmpty
                                  ? _networkCoverPhotos.length
                                  : _coverPhotos.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (_, i) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: _networkCoverPhotos.isNotEmpty
                                      ? Image.network(
                                          '${ApiClient.baseUrl}${_networkCoverPhotos[i]}',
                                          width: 160,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.file(
                                          File(_coverPhotos[i].path),
                                          width: 160,
                                          height: 120,
                                          fit: BoxFit.cover,
                                        ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Bước 1 — Thông tin cơ bản
                        _reviewSectionTitle('📍 Thông tin cơ bản'),
                        _reviewCard([
                          _reviewRow('Tên chi nhánh', _nameCtrl.text.trim()),
                          _reviewRow(
                            'Địa chỉ',
                            address.isEmpty ? '—' : address,
                          ),
                          if (_latitude != null)
                            _reviewRow(
                              'Tọa độ',
                              '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                            ),
                        ]),

                        // Bước 2 — Mô hình kinh doanh
                        _reviewSectionTitle('🏢 Mô hình kinh doanh'),
                        _reviewCard([_reviewRow('Loại hình', catLabel)]),

                        // Bước 4 — Tài chính
                        _reviewSectionTitle('💰 Tài chính'),
                        _reviewCard([
                          _reviewRow(
                            'Điện',
                            '${fmtPrice(_elecPriceCtrl.text)}/kWh',
                          ),
                          _reviewRow(
                            'Nước',
                            '${fmtPrice(_waterPriceCtrl.text)}/${_waterUnit.toLowerCase()}',
                          ),
                          // Giá dịch vụ lấy từ cấu hình tiện ích (nguồn thực sự
                          // được lưu), có fallback sang ô nhập giá chuyên biệt.
                          if (getAmenityFee(
                                'Wifi|Internet',
                                fallbackCtrl: _internetPriceCtrl,
                              ) >
                              0)
                            _reviewRow(
                              'Internet',
                              '${fmt.format(getAmenityFee('Wifi|Internet', fallbackCtrl: _internetPriceCtrl))}đ/phòng',
                            ),
                          if (getAmenityFee(
                                'Bãi để xe|Giữ xe|Gửi xe',
                                fallbackCtrl: _parkingPriceCtrl,
                              ) >
                              0)
                            _reviewRow(
                              'Gửi xe',
                              '${fmt.format(getAmenityFee('Bãi để xe|Giữ xe|Gửi xe', fallbackCtrl: _parkingPriceCtrl))}đ/xe',
                            ),
                          if (getAmenityFee(
                                'Vệ sinh|Rác',
                                fallbackCtrl: _trashPriceCtrl,
                              ) >
                              0)
                            _reviewRow(
                              'Rác',
                              '${fmt.format(getAmenityFee('Vệ sinh|Rác', fallbackCtrl: _trashPriceCtrl))}đ/người',
                            ),
                        ]),

                        // Chính sách
                        _reviewSectionTitle('📋 Chính sách'),
                        _reviewCard([
                          _reviewRow(
                            'Thú cưng',
                            _petPolicy == 'CHO_PHEP' ? '✅ Cho phép' : '❌ Không',
                          ),
                          _reviewRow(
                            'Ở ghép',
                            _roommatePolicy == 'CHO_PHEP'
                                ? '✅ Cho phép'
                                : '❌ Không',
                          ),
                          _reviewRow('Giờ đóng cửa', _closingTime),
                          _reviewRow(
                            'Nấu ăn',
                            _cookingPolicy == 'TRONG_PHONG'
                                ? 'Trong phòng'
                                : 'Trong bếp chung',
                          ),
                        ]),

                        // Tiện ích
                        if (_selectedAmenities.isNotEmpty) ...[
                          _reviewSectionTitle('✨ Tiện ích'),
                          _reviewCard(
                            _selectedAmenities.entries.map((e) {
                              // BUGFIX (data): `price` có thể là String → tránh TypeError.
                              final rawPrice = e.value['price'];
                              final price = rawPrice is num
                                  ? rawPrice.toDouble()
                                  : double.tryParse(
                                          rawPrice?.toString() ?? '',
                                        ) ??
                                        0;
                              final charge =
                                  e.value['chargeType']?.toString() ?? 'free';
                              // Dựa vào `chargeType` (không chỉ price == 0) để tránh
                              // hiển thị "Miễn phí" cho tiện ích thực tế thu phí.
                              final isFree = charge == 'free' || price == 0;
                              final priceStr = isFree
                                  ? 'Miễn phí'
                                  : '${fmt.format(price)}đ';
                              final unit = isFree
                                  ? ''
                                  : charge == 'per_person'
                                  ? '/người'
                                  : charge == 'per_room'
                                  ? '/phòng'
                                  : charge == 'monthly'
                                  ? '/tháng'
                                  : '';
                              return _reviewRow(e.key, '$priceStr$unit');
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── Bottom action ──
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF9FAFB),
                      border: Border(
                        top: BorderSide(color: Color(0x14000000), width: 0.5),
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Row(
                          children: [
                            // Quay lại chỉnh sửa
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF0F2),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 13,
                                ),
                                borderRadius: BorderRadius.circular(100),
                                minimumSize: const Size(0, 0),
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text(
                                  'Chỉnh sửa',
                                  style: TextStyle(
                                    color: Color(0xFF374151),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Xác nhận tạo
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.pop(ctx);
                                  unawaited(submit());
                                },
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF10B981),
                                        Color(0xFF059669),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(100),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF10B981,
                                        ).withValues(alpha: 0.35),
                                        blurRadius: 14,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '🎉',
                                        style: TextStyle(fontSize: 18),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Xác nhận & Tạo chi nhánh',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Helpers for review sheet ──────────────────────────────────────────────────

  Widget _reviewSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF374151),
      ),
    ),
  );

  Widget _reviewCard(List<Widget> rows) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A000000),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: rows.asMap().entries.map((e) {
        final isLast = e.key == rows.length - 1;
        return Column(
          children: [
            e.value,
            if (!isLast)
              const Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: Color(0xFFF3F4F6),
              ),
          ],
        );
      }).toList(),
    ),
  );

  Widget _reviewRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF111827),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    ),
  );
}
