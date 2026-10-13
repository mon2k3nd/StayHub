part of '../../create_branch_screen.dart';

// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api

extension Step2BusinessModelWidgetExt on _CreateBranchScreenState {
  /// BƯỚC 1 (wizard) — CHỈ phần "Mô hình chi nhánh".
  ///
  /// Tách riêng khỏi [_buildStep2BusinessModel] để Bước 1 "Khung vận hành"
  /// KHÔNG còn kéo theo "Số tầng dự kiến" (thuộc Bước 2 — Cấu trúc không gian)
  /// lẫn "WC chung" (thuộc Bước 3 — Khu vực vệ sinh chung).
  Widget _buildWizardModelSelector() {
    final cat = _catId.isNotEmpty
        ? kRentalCategories.firstWhere(
            (c) => c.id == _catId,
            orElse: () => kRentalCategories.first,
          )
        : null;

    // KHÔNG bọc SingleChildScrollView: khối này được nhúng trong ListView của
    // _buildWizardFrameworkScreen → scroll lồng nhau gây xung đột cử chỉ và
    // làm mất khả năng cuộn của trang. Chỉ trả về Column để ListView cha lo cuộn.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('MÔ HÌNH CHI NHÁNH'),
          const SizedBox(height: 4),
          const Text(
            'Chọn nhóm hình thức cho thuê phù hợp nhất với chi nhánh.',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          _buildMainCategorySelector(),
          const SizedBox(height: 16),
          if (cat == null)
            _buildEmptySubModelHint()
          else
            _buildSubModelSection(cat),
        ],
      ),
    );
  }

  /// Gợi ý khi chưa chọn mô hình cấp 1.
  Widget _buildEmptySubModelHint() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Row(
        children: [
          Icon(CupertinoIcons.cursor_rays, color: Color(0xFF9CA3AF), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Chọn một mô hình ở trên để xem loại hình chi tiết.',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  /// Khối "Loại hình chi tiết" — thẻ lớn có tiêu đề + mô tả, không còn chip
  /// trùng lặp. Kèm banner giải thích "khép kín" là thuộc tính cấp phòng.
  Widget _buildSubModelSection(RentalCategory cat) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Column(
        key: ValueKey(_catId),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tóm tắt mô hình đã chọn.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cat.accent.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cat.accent.withValues(alpha: 0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cat.accent,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(cat.icon, size: 21, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.title,
                        style: TextStyle(
                          color: cat.accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        cat.subtitle,
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Loại hình chi tiết',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Chọn đúng bản chất tài sản — có thể chỉnh lại sau.',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 10),
          ...cat.subModels.map(
            (sub) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildSubModelCard(cat, sub),
            ),
          ),
          const SizedBox(height: 6),
          _buildSelfContainedHint(),
        ],
      ),
    );
  }

  /// Thẻ chọn loại hình chi tiết: radio + tiêu đề + mô tả.
  Widget _buildSubModelCard(RentalCategory cat, RentalSubModel sub) {
    final isSelected = sub.id == _subId;
    return GestureDetector(
      onTap: () => setState(() => _subId = sub.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? cat.accent.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? cat.accent : const Color(0xFFE5E7EB),
            width: isSelected ? 1.6 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                isSelected
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.circle,
                size: 20,
                color: isSelected ? cat.accent : const Color(0xFFD1D5DB),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sub.title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isSelected ? cat.accent : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    sub.desc,
                    style: const TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Banner giải thích: khép kín / không khép kín là thuộc tính CẤP PHÒNG,
  /// không phải loại hình chi nhánh — tránh hiểu nhầm và trùng lặp.
  Widget _buildSelfContainedHint() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            CupertinoIcons.info_circle_fill,
            size: 16,
            color: Color(0xFF0EA5E9),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Phòng khép kín hay dùng WC chung là thuộc tính của TỪNG PHÒNG, '
              'không phải loại hình chi nhánh. Một chi nhánh có thể vừa có phòng '
              'khép kín vừa có phòng dùng WC chung — bạn sẽ thiết lập ở Bước 3.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.45,
                color: Color(0xFF1E40AF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Khối "WC chung" gọn cho Bước 1 (wizard): bật/tắt + tăng giảm số WC.
  Widget _buildWizardSharedWcSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _hasSharedWc ? const Color(0xFFEFF6FF) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _hasSharedWc
              ? const Color(0xFF93C5FD)
              : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _hasSharedWc
                      ? const Color(0xFFDBEAFE)
                      : const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  CupertinoIcons.drop_fill,
                  color: _hasSharedWc
                      ? const Color(0xFF0EA5E9)
                      : const Color(0xFF9CA3AF),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dãy có WC / NVS chung?',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      'Bật nếu một số phòng dùng chung nhà vệ sinh',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: _hasSharedWc,
                activeTrackColor: const Color(0xFF0EA5E9),
                onChanged: (val) {
                  setState(() {
                    _hasSharedWc = val;
                    if (!val) {
                      _sharedWcs.clear();
                      for (var f in _floors) {
                        for (var r in f.rooms) {
                          r.sharedWcId = null;
                          r.isSelfContained = true;
                        }
                      }
                    }
                  });
                  // syncSharedWcs() tự gọi setState → gọi ngoài setState trên
                  // để tránh lồng setState (nested setState).
                  if (val) {
                    final count = int.tryParse(_wcCtrl.text) ?? 1;
                    syncSharedWcs(count);
                  }
                },
              ),
            ],
          ),
          if (_hasSharedWc) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFBFDBFE)),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  CupertinoIcons.number,
                  size: 16,
                  color: Color(0xFF0EA5E9),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Số WC chung:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF374151),
                  ),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        onPressed: () {
                          final cur = int.tryParse(_wcCtrl.text) ?? 1;
                          if (cur > 1) {
                            setState(() => _wcCtrl.text = '${cur - 1}');
                            // syncSharedWcs() tự gọi setState → gọi ngoài
                            // setState trên để tránh lồng setState.
                            syncSharedWcs(cur - 1);
                          }
                        },
                        minimumSize: const Size(0, 0),
                        child: const Icon(
                          CupertinoIcons.minus,
                          size: 16,
                          color: Color(0xFF0EA5E9),
                        ),
                      ),
                      SizedBox(
                        width: 36,
                        child: Text(
                          _wcCtrl.text.isEmpty ? '1' : _wcCtrl.text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        onPressed: () {
                          final cur = int.tryParse(_wcCtrl.text) ?? 1;
                          if (cur < 20) {
                            setState(() => _wcCtrl.text = '${cur + 1}');
                            // syncSharedWcs() tự gọi setState → gọi ngoài
                            // setState trên để tránh lồng setState.
                            syncSharedWcs(cur + 1);
                          }
                        },
                        minimumSize: const Size(0, 0),
                        child: const Icon(
                          CupertinoIcons.plus,
                          size: 16,
                          color: Color(0xFF0EA5E9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Row(
                children: [
                  Icon(
                    CupertinoIcons.info_circle,
                    size: 14,
                    color: Color(0xFF0EA5E9),
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Ở Bước 3, bạn sẽ gán từng phòng vào WC tương ứng.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep2BusinessModel() {
    final cat = _catId.isNotEmpty
        ? kRentalCategories.firstWhere(
            (c) => c.id == _catId,
            orElse: () => kRentalCategories.first,
          )
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('PHÂN LOẠI BẤT ĐỘNG SẢN'),
          const Text(
            'Chọn mô hình phù hợp với loại hình cho thuê của bạn.',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          _buildMainCategorySelector(),
          const SizedBox(height: 8),
          if (cat == null)
            _buildEmptySubModelHint()
          else
            _buildSubModelSection(cat),

          // Chỉ mô hình vận hành theo phòng mới cần khai báo số tầng.
          if (rentalCategoryById(_catId)?.isRoomBased ?? false) ...[
            const SizedBox(height: 20),
            _buildSectionTitle('SỐ TẦNG DỰ KIẾN'),
            _buildInput(
              ctrl: _floorsCtrl,
              placeholder: 'Nhập số tầng (VD: 3)',
              icon: CupertinoIcons.layers_alt_fill,
              type: TextInputType.number,
              onChanged: (v) {
                generateFloors();
              },
            ),
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💡', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sau khi nhập số tầng, bạn có thể thiết lập chi tiết từng phòng (khép kín, số phòng mỗi tầng...) ở Bước 3.',
                      style: TextStyle(
                        color: Color(0xFF92400E),
                        fontSize: 12.5,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── WC CHUNG ────────────────────────────────────────────
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _hasSharedWc
                    ? const Color(0xFFEFF6FF)
                    : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _hasSharedWc
                      ? const Color(0xFF93C5FD)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _hasSharedWc
                              ? const Color(0xFFDBEAFE)
                              : const Color(0xFFF3F4F6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.drop_fill,
                          color: _hasSharedWc
                              ? const Color(0xFF0EA5E9)
                              : const Color(0xFF9CA3AF),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dãy có WC / NVS chung?',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Color(0xFF111827),
                              ),
                            ),
                            Text(
                              'Bật nếu một số phòng dùng chung nhà vệ sinh',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      CupertinoSwitch(
                        value: _hasSharedWc,
                        activeTrackColor: const Color(0xFF0EA5E9),
                        onChanged: (val) {
                          setState(() {
                            _hasSharedWc = val;
                            if (!val) {
                              _sharedWcs.clear();
                              for (var f in _floors) {
                                for (var r in f.rooms) {
                                  r.sharedWcId = null;
                                  r.isSelfContained = true;
                                }
                              }
                            } else {
                              final count = int.tryParse(_wcCtrl.text) ?? 1;
                              syncSharedWcs(count);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  if (_hasSharedWc) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFBFDBFE)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(
                          CupertinoIcons.number,
                          size: 16,
                          color: Color(0xFF0EA5E9),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Số WC chung:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                onPressed: () {
                                  final cur = int.tryParse(_wcCtrl.text) ?? 1;
                                  if (cur > 1) {
                                    setState(() {
                                      _wcCtrl.text = '${cur - 1}';
                                    });
                                    syncSharedWcs(cur - 1);
                                  }
                                },
                                minimumSize: const Size(0, 0),
                                child: const Icon(
                                  CupertinoIcons.minus,
                                  size: 16,
                                  color: Color(0xFF0EA5E9),
                                ),
                              ),
                              SizedBox(
                                width: 36,
                                child: Text(
                                  _wcCtrl.text.isEmpty ? '1' : _wcCtrl.text,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ),
                              CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                onPressed: () {
                                  final cur = int.tryParse(_wcCtrl.text) ?? 1;
                                  if (cur < 20) {
                                    setState(() {
                                      _wcCtrl.text = '${cur + 1}';
                                    });
                                    syncSharedWcs(cur + 1);
                                  }
                                },
                                minimumSize: const Size(0, 0),
                                child: const Icon(
                                  CupertinoIcons.plus,
                                  size: 16,
                                  color: Color(0xFF0EA5E9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F7FF),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            CupertinoIcons.info_circle,
                            size: 14,
                            color: Color(0xFF0EA5E9),
                          ),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Ở Bước 3, bạn sẽ gán từng phòng vào WC tương ứng.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1E40AF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
