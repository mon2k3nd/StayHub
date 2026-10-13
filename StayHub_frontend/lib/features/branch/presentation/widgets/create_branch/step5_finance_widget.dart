part of '../../create_branch_screen.dart';

// ignore_for_file: invalid_use_of_protected_member
// ignore_for_file: library_private_types_in_public_api

extension Step5FinanceWidgetExt on _CreateBranchScreenState {
  Widget _buildStep5Finance() {
    // Revenue preview
    final totalRooms = _floors.fold<int>(0, (s, f) => s + f.rooms.length);
    // BUGFIX (data): coerce an toàn — tránh `as num` ném TypeError khi
    // room.price là String/null.
    double roomPrice(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;
    final double avgPrice = totalRooms > 0
        ? _floors.fold<double>(
                0.0,
                (s, f) =>
                    s +
                    f.rooms.fold<double>(
                      0.0,
                      (r, room) => r + roomPrice(room.price),
                    ),
              ) /
              totalRooms
        : 0.0;
    final double estRevenue = avgPrice * totalRooms;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header hero gradient card ──────────────────────────────────
          if (estRevenue > 0)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
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
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          CupertinoIcons.chart_bar_alt_fill,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Dự kiến Doanh thu / tháng',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatCurrency(estRevenue),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalRooms phòng × ${_formatCurrency(avgPrice)}/tháng',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

          // ── Card 1: Giá điện & nước ───────────────────────────────────
          _buildFinanceSection(
            icon: CupertinoIcons.bolt_fill,
            iconColor: const Color(0xFFF59E0B),
            iconBg: const Color(0xFFFFFBEB),
            title: 'Điện & Nước sinh hoạt',
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Loại giá điện',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    CupertinoSlidingSegmentedControl<String>(
                      groupValue: _elecPricingType,
                      children: const {
                        'FIXED': Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            'Cố định',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        'TIERED': Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            'Nhà nước',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      },
                      onValueChanged: (v) =>
                          setState(() => _elecPricingType = v ?? 'FIXED'),
                    ),
                  ],
                ),
                if (_elecPricingType == 'FIXED') ...[
                  const SizedBox(height: 12),
                  _buildFinanceTile(
                    ctrl: _elecPriceCtrl,
                    label: 'Giá điện cố định',
                    unit: 'đ/kWh',
                    icon: '⚡',
                    accentColor: const Color(0xFFF59E0B),
                  ),
                ],
                const SizedBox(height: 12),
                _buildFinanceTile(
                  ctrl: _waterPriceCtrl,
                  label: 'Giá nước',
                  unit: 'đ/${_waterUnit.toLowerCase()}',
                  icon: '💧',
                  accentColor: const Color(0xFF0EA5E9),
                  unitOptions: const ['Người', 'Khối', 'Phòng'],
                  onUnitChanged: (v) => setState(() => _waterUnit = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Card 2: Tiện ích ─────────────────────────────────────────
          buildAmenityPricingCard(),

          // ── Card 3: Chu kỳ & HĐ ──────────────────────────────────────
          _buildFinanceSection(
            icon: CupertinoIcons.doc_text_fill,
            iconColor: const Color(0xFF10B981),
            iconBg: const Color(0xFFF0FDF4),
            title: 'Chu kỳ & Hợp đồng',
            child: Column(
              children: [
                _buildFinanceTile(
                  ctrl: _billingDayCtrl,
                  label: 'Ngày chốt tiền',
                  unit: 'hàng tháng',
                  icon: '📅',
                  accentColor: const Color(0xFF8B5CF6),
                  isCurrency: false,
                ),
                const SizedBox(height: 12),
                _buildFinanceTile(
                  ctrl: _minLeaseDaysCtrl,
                  label: 'Hợp đồng tối thiểu',
                  unit: 'tháng',
                  icon: '📋',
                  accentColor: const Color(0xFFEF4444),
                  isCurrency: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Card 4: Nội quy ──────────────────────────────────────────
          _buildFinanceSection(
            icon: CupertinoIcons.shield_lefthalf_fill,
            iconColor: const Color(0xFF8B5CF6),
            iconBg: const Color(0xFFF5F3FF),
            title: 'Nội quy chi nhánh',
            child: Column(
              children: [
                _buildPolicyTile(
                  icon: '🐾',
                  label: 'Nuôi thú cưng',
                  value: _petPolicy == 'CHO_PHEP',
                  onChanged: (v) =>
                      setState(() => _petPolicy = v ? 'CHO_PHEP' : 'CAM'),
                ),
                _buildDivider(),
                _buildPolicyTile(
                  icon: '🤝',
                  label: 'Ở ghép',
                  value: _roommatePolicy == 'CHO_PHEP',
                  onChanged: (v) =>
                      setState(() => _roommatePolicy = v ? 'CHO_PHEP' : 'CAM'),
                ),
                _buildDivider(),
                _buildPolicyTile(
                  icon: '🍳',
                  label: 'Nấu ăn trong phòng',
                  value: _cookingPolicy == 'TRONG_PHONG',
                  onChanged: (v) => setState(
                    () => _cookingPolicy = v ? 'TRONG_PHONG' : 'KHONG_CHO',
                  ),
                ),
                _buildDivider(),
                // Giờ đóng cửa
                Row(
                  children: [
                    const Text('🕐', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Giờ đóng cửa',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    CupertinoSlidingSegmentedControl<String>(
                      groupValue: _closingTime,
                      children: const {
                        'Tự do': Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text('Tự do', style: TextStyle(fontSize: 12)),
                        ),
                        '22:00': Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text('22:00', style: TextStyle(fontSize: 12)),
                        ),
                        '23:00': Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text('23:00', style: TextStyle(fontSize: 12)),
                        ),
                      },
                      onValueChanged: (v) =>
                          setState(() => _closingTime = v ?? 'Tự do'),
                    ),
                  ],
                ),
                _buildDivider(),
                // Sạc xe điện
                _buildPolicyTile(
                  icon: '🔋',
                  label: 'Cho phép sạc xe điện',
                  value: _evChargingAllowed,
                  onChanged: (v) => setState(() => _evChargingAllowed = v),
                ),
                if (_evChargingAllowed) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _buildEVTypeChip('Cố định/tháng', 'fixed'),
                            const SizedBox(width: 8),
                            _buildEVTypeChip('Theo số điện', 'metered'),
                          ],
                        ),
                        if (_evChargeType == 'fixed') ...[
                          const SizedBox(height: 12),
                          _buildFinanceTile(
                            ctrl: _evFixedPriceCtrl,
                            label: 'Mức phí sạc xe',
                            unit: 'đ/xe/tháng',
                            icon: '💰',
                            accentColor: const Color(0xFF10B981),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF0FDF4), Color(0xFFECFDF5)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  CupertinoIcons.checkmark_shield_fill,
                  color: Color(0xFF10B981),
                  size: 18,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tất cả nội quy và chi phí sẽ áp dụng đồng nhất cho toàn bộ phòng trong chi nhánh.',
                    style: TextStyle(
                      color: Color(0xFF065F46),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceSection({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildFinanceTile({
    required TextEditingController ctrl,
    required String label,
    required String unit,
    required String icon,
    required Color accentColor,
    List<String>? unitOptions,
    ValueChanged<String>? onUnitChanged,
    // Whether this field holds a currency amount. Non-currency numeric fields
    // (e.g. billing day, minimum contract months) must NOT use the currency
    // formatter, otherwise "5" would be displayed as "5" but typed values get
    // thousands separators which is confusing and can corrupt parsing.
    bool isCurrency = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            alignment: Alignment.center,
            child: Text(icon, style: const TextStyle(fontSize: 20)),
          ),
          Container(width: 1, height: 44, color: const Color(0xFFE5E7EB)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 8),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    if (isCurrency)
                      CurrencyInputFormatter()
                    else
                      FilteringTextInputFormatter.digitsOnly,
                  ],
                  onChanged: (v) => _updateProgress(),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: accentColor,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.fromLTRB(12, 2, 12, 10),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          if (unitOptions != null && onUnitChanged != null)
            GestureDetector(
              onTap: () {
                unawaited(
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 40,
                              height: 4,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5E7EB),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const Text(
                              'Chọn đơn vị tính',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...unitOptions.map((u) {
                              final isSelected = 'đ/${u.toLowerCase()}' == unit;
                              return GestureDetector(
                                onTap: () {
                                  onUnitChanged(u);
                                  Navigator.pop(ctx);
                                },
                                child: Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFEFF6FF)
                                        : const Color(0xFFF9FAFB),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF3B82F6)
                                          : const Color(0xFFE5E7EB),
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'đ/${u.toLowerCase()}',
                                    style: TextStyle(
                                      color: isSelected
                                          ? const Color(0xFF1D4ED8)
                                          : const Color(0xFF4B5563),
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 12,
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      CupertinoIcons.chevron_down,
                      size: 11,
                      color: accentColor,
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPolicyTile({
    required String icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF111827),
            ),
          ),
        ),
        CupertinoSwitch(
          value: value,
          activeTrackColor: const Color(0xFF10B981),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildEVTypeChip(String label, String type) {
    final isSelected = _evChargeType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _evChargeType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0EA5E9) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF0EA5E9)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected
                    ? CupertinoIcons.checkmark_circle_fill
                    : CupertinoIcons.circle,
                size: 14,
                color: isSelected ? Colors.white : const Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF4B5563),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() => const Padding(
    padding: EdgeInsets.symmetric(vertical: 10),
    child: Divider(color: Color(0xFFF3F4F6), height: 1),
  );

  Widget buildAmenityPricingCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.sparkles,
                    color: Color(0xFFF59E0B),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Chi phí tiện ích',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: Wrap(
              spacing: 10,
              runSpacing: 12,
              children:
                  {
                    ..._getDefaultAmenities(_catId),
                    ..._customAmenities,
                    '+ Thêm tiện ích khác',
                  }.toList().map((a) {
                    if (a == '+ Thêm tiện ích khác') {
                      return GestureDetector(
                        onTap: showAddCustomAmenityDialog,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                CupertinoIcons.add,
                                size: 14,
                                color: Color(0xFF6B7280),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Thêm tiện ích khác',
                                style: TextStyle(
                                  color: Color(0xFF4B5563),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final isSelected = _selectedAmenities.containsKey(a);
                    return GestureDetector(
                      onTap: () {
                        if (isSelected) {
                          setState(() => _selectedAmenities.remove(a));
                        } else {
                          // Chọn tiện ích ⇒ mở ngay sheet cấu hình để chủ nhà buộc phải chọn
                          // Miễn phí / Thu theo phòng / Thu theo người và nhập giá. Trước đây chip
                          // chỉ gán mặc định `free` nên Wifi… bị lưu "Miễn phí" dù thực tế thu phí.
                          setState(() {
                            _selectedAmenities[a] = {
                              'price': 0.0,
                              'chargeType': 'free',
                              'isMandatory': true,
                            };
                          });
                          _showAmenityConfigBottomSheet(a);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.only(
                          left: 16,
                          right: isSelected ? 16 : 16,
                          top: isSelected ? 10 : 10,
                          bottom: isSelected ? 10 : 10,
                        ),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF38BDF8),
                                    Color(0xFF0284C7),
                                  ],
                                )
                              : null,
                          color: isSelected ? null : Colors.white,
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : const Color(0xFFE5E7EB),
                          ),
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF0284C7,
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
                            if (isSelected) ...[
                              const Icon(
                                CupertinoIcons.checkmark_alt_circle_fill,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                a,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ] else ...[
                              Text(
                                a,
                                style: const TextStyle(
                                  color: Color(0xFF4B5563),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
          if (_selectedAmenities.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: _selectedAmenities.keys.map((a) {
                  final cfg = _selectedAmenities[a];
                  // BUGFIX (data): `price` có thể là int/String → tránh TypeError.
                  final rawPrice = cfg?['price'];
                  final price = rawPrice is num
                      ? rawPrice.toDouble()
                      : double.tryParse(rawPrice?.toString() ?? '') ?? 0.0;
                  final chargeType = cfg?['chargeType']?.toString() ?? 'free';
                  String priceLabel = '';
                  String chargeLabel = '';
                  if (chargeType == 'free') {
                    priceLabel = 'Miễn phí';
                    chargeLabel = '';
                  } else if (chargeType == 'per_room') {
                    priceLabel = _formatCurrency(price);
                    chargeLabel = '/Phòng';
                  } else if (chargeType == 'per_person') {
                    priceLabel = _formatCurrency(price);
                    chargeLabel = '/Người';
                  } else if (chargeType == 'monthly') {
                    priceLabel = _formatCurrency(price);
                    chargeLabel = '/Tháng';
                  }

                  return GestureDetector(
                    onTap: () => _showAmenityConfigBottomSheet(a),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: chargeType == 'free'
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF0EA5E9),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              a,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: priceLabel,
                                  style: TextStyle(
                                    color: chargeType == 'free'
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFF0EA5E9),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                if (chargeLabel.isNotEmpty)
                                  TextSpan(
                                    text: chargeLabel,
                                    style: const TextStyle(
                                      color: Color(0xFF9CA3AF),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF0EA5E9,
                              ).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Sửa',
                              style: TextStyle(
                                color: Color(0xFF0EA5E9),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
