part of '../../create_branch_screen.dart';

// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api

extension Step3OperationScaleWidgetExt on _CreateBranchScreenState {
  Widget buildStep3OperationScale() {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('CẤU HÌNH PHÒNG & TẦNG'),
          const Text(
            'Thiết lập cấu trúc các tầng và số phòng.',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
          const SizedBox(height: 20),

          // ── SỐ TẦNG DỰ KIẾN + WC CHUNG (chuyển từ Bước 1 sang) ──────────────
          // Chỉ mô hình vận hành theo phòng mới cần khai báo tầng & WC chung.
          if (rentalCategoryById(_catId)?.isRoomBased ?? false) ...[
            _buildSectionTitle('SỐ TẦNG DỰ KIẾN'),
            _buildInput(
              ctrl: _floorsCtrl,
              placeholder: 'Nhập số tầng (VD: 3)',
              icon: CupertinoIcons.layers_alt_fill,
              type: TextInputType.number,
              onChanged: (v) => generateFloors(),
            ),
            const SizedBox(height: 16),
            _buildWizardSharedWcSection(),
            const SizedBox(height: 20),
          ],

          if (_hasSharedWc) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Danh sách WC Chung',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF111827),
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: addNewWc,
                  child: const Row(
                    children: [
                      Icon(
                        CupertinoIcons.add_circled_solid,
                        size: 18,
                        color: Color(0xFF10B981),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Thêm WC',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_sharedWcs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    style: BorderStyle.solid,
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(
                      CupertinoIcons.drop,
                      size: 32,
                      color: Color(0xFF9CA3AF),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Chưa có WC chung nào',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _sharedWcs
                    .map(
                      (wc) => GestureDetector(
                        onTap: () => showEditWcDialog(wc),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(
                                0xFF0EA5E9,
                              ).withValues(alpha: 0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF0EA5E9,
                                ).withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                CupertinoIcons.drop_fill,
                                color: Color(0xFF0EA5E9),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    wc.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  Text(
                                    wc.code,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _sharedWcs.remove(wc);
                                    _wcCtrl.text = _sharedWcs.length.toString();
                                    for (var f in _floors) {
                                      for (var r in f.rooms) {
                                        if (r.sharedWcId == wc.tempId) {
                                          r.sharedWcId = null;
                                        }
                                      }
                                    }
                                  });
                                },
                                child: const Icon(
                                  CupertinoIcons.clear_circled_solid,
                                  color: Color(0xFFEF4444),
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            const SizedBox(height: 16),
          ],

          // Danh sách các tầng
          ..._floors.map(
            (floor) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildFloorCard(floor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloorCard(FloorDraft floor) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          // Header Tầng
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tầng ${floor.floorNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                    fontSize: 15,
                  ),
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        if (floor.rooms.isNotEmpty) {
                          setState(() => floor.rooms.removeLast());
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.minus,
                          color: Colors.red,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${floor.rooms.length} phòng',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: () {
                        setState(() {
                          int nextIdx = floor.rooms.length + 1;
                          final branchCode = _branchCodeCtrl.text.isNotEmpty
                              ? _branchCodeCtrl.text
                              : 'CN';
                          final newRoomCode =
                              '${branchCode}_T${floor.floorNumber}_${nextIdx.toString().padLeft(2, '0')}';
                          final newRoom = RoomDraft(
                            tempId:
                                'P${floor.floorNumber}${nextIdx.toString().padLeft(2, '0')}',
                            subType: _subId,
                            code: newRoomCode,
                          );
                          if (floor.rooms.isNotEmpty) {
                            final lastRoom = floor.rooms.last;
                            newRoom.price = lastRoom.price;
                            newRoom.area = lastRoom.area;
                            newRoom.isSelfContained = lastRoom.isSelfContained;
                            newRoom.sharedWcId = lastRoom.sharedWcId;
                          }
                          floor.rooms.add(newRoom);
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          CupertinoIcons.add,
                          color: Color(0xFF0EA5E9),
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Nút Áp dụng cho cả tầng
          if (floor.rooms.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 12, right: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () {
                    final p1 = floor.rooms.first;
                    setState(() {
                      for (int i = 1; i < floor.rooms.length; i++) {
                        floor.rooms[i].price = p1.price;
                        floor.rooms[i].area = p1.area;
                        floor.rooms[i].isSelfContained = p1.isSelfContained;
                        floor.rooms[i].sharedWcId = p1.sharedWcId;
                      }
                    });
                    ToastUtils.show(
                      context,
                      'Đã sao chép cấu hình phòng 1 cho cả tầng!',
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.doc_on_clipboard_fill,
                          size: 12,
                          color: Color(0xFF0EA5E9),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Áp dụng P1 cho cả tầng',
                          style: TextStyle(
                            color: Color(0xFF0EA5E9),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // Danh sách phòng
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: floor.rooms
                  .map((room) => _buildRoomRow(floor, room))
                  .toList(),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRoomRow(FloorDraft floor, RoomDraft room) {
    final bool hasError = (room.price <= 0 || room.area <= 0);

    final priceCtrl = _roomPriceCtrls.putIfAbsent(room.tempId, () {
      final ctrl = TextEditingController(
        text: room.price > 0 ? NumberFormat('#,###').format(room.price) : '',
      );
      ctrl.addListener(() {
        // Handle both commas and dots for thousands separator
        final raw = ctrl.text.replaceAll(',', '').replaceAll('.', '');
        final newPrice = raw.isNotEmpty ? (double.tryParse(raw) ?? 0.0) : 0.0;
        room.price = newPrice;
      });
      return ctrl;
    });

    final areaCtrl = _roomAreaCtrls.putIfAbsent(room.tempId, () {
      final text = room.area > 0
          ? (room.area == room.area.toInt()
                ? room.area.toInt().toString()
                : room.area.toString())
          : '';
      final ctrl = TextEditingController(text: text);
      ctrl.addListener(() {
        room.area = _parseAreaInput(ctrl.text);
      });
      return ctrl;
    });

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasError ? Colors.red : const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.bed_double_fill,
                    color: Color(0xFF0EA5E9),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phòng ${room.tempId.replaceAll('P', '')}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (room.code.isNotEmpty)
                        Text(
                          room.code,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (_hasSharedWc && !room.isSelfContained)
                        room.sharedWcId == null
                            ? const Text(
                                'Chưa gán WC',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              )
                            : Text(
                                'Đã gán: ${_sharedWcs.firstWhere(
                                  (w) => w.tempId == room.sharedWcId,
                                  orElse: () => SharedWcDraft(tempId: '', name: 'Lỗi'),
                                ).name}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                    ],
                  ),
                ),
                if (_hasSharedWc)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => setState(() {
                            room.isSelfContained = true;
                            room.sharedWcId = null;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: room.isSelfContained
                                  ? const Color(0xFFF59E0B)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Khép kín',
                              style: TextStyle(
                                color: room.isSelfContained
                                    ? Colors.white
                                    : const Color(0xFF6B7280),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () =>
                              setState(() => room.isSelfContained = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: !room.isSelfContained
                                  ? const Color(0xFFF59E0B)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Không',
                              style: TextStyle(
                                color: !room.isSelfContained
                                    ? Colors.white
                                    : const Color(0xFF6B7280),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (_hasSharedWc && !room.isSelfContained) ...[
              const SizedBox(height: 8),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => showAssignWcBottomSheet(room),
                minimumSize: const Size(0, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: room.sharedWcId == null
                        ? Colors.red.withValues(alpha: 0.1)
                        : const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: room.sharedWcId == null
                          ? Colors.red.withValues(alpha: 0.3)
                          : const Color(0xFF10B981).withValues(alpha: 0.3),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    room.sharedWcId == null ? 'Bấm để Gán WC' : 'Đổi WC Chung',
                    style: TextStyle(
                      color: room.sharedWcId == null
                          ? Colors.red
                          : const Color(0xFF10B981),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Giá thuê (VNĐ)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 4),
                      CupertinoTextField(
                        keyboardType: TextInputType.number,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        placeholder: 'VD: 3,500,000',
                        placeholderStyle: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 12,
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        controller: priceCtrl,
                        inputFormatters: [CurrencyInputFormatter()],
                        onChanged: (val) {
                          room.price =
                              double.tryParse(
                                val.replaceAll(',', '').replaceAll('.', ''),
                              ) ??
                              0;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Diện tích (m²)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 4),
                      CupertinoTextField(
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        placeholder: 'VD: 20',
                        placeholderStyle: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 12,
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        controller: areaCtrl,
                        onChanged: (val) {
                          room.area = _parseAreaInput(val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
