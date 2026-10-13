import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/theme/app_theme.dart';
import '../data/models/branch_model.dart';
import '../domain/constants/rental_categories.dart';
import '../application/branch_notifier.dart';
import 'dart:async' show unawaited;

// ── SCREEN ───────────────────────────────────────────────────────────────────

class RentalModelConfigScreen extends ConsumerStatefulWidget {
  final BranchModel branch;
  const RentalModelConfigScreen({super.key, required this.branch});
  @override
  ConsumerState<RentalModelConfigScreen> createState() => _State();
}

class _State extends ConsumerState<RentalModelConfigScreen> {
  String _catId = 'PHONG_TRO';
  String _subId = 'PHONG_TRO_THUONG';
  bool _loading = false;

  late TextEditingController _depCtrl,
      _billCtrl,
      _elecCtrl,
      _waterCtrl,
      _wifiCtrl,
      _trashCtrl,
      _mgmtCtrl,
      _comElecCtrl;

  String _timeUnit = 'THANG';
  String _cleanFreq = 'HANG_TUAN';
  int _checkIn = 14;
  int _checkOut = 12;
  int _maxCap = 2;
  int _maxVeh = 1;
  String _gender = 'HET';
  String _pet = 'KHONG';
  String _cooking = 'TRONG_PHONG';

  RentalCategory get _cat =>
      kRentalCategories.firstWhere((c) => c.id == _catId);

  bool get _isPhong => _catId == 'PHONG_TRO';
  bool get _isCan => _catId == 'NHA_NGUYEN_CAN';
  bool get _isKtx => _catId == 'O_GHEP_KTX';
  bool get _isKiot => _catId == 'KIOT_BAN_LE';
  bool get _isVP => _catId == 'VAN_PHONG';
  bool get _isKho => _catId == 'KHO_XUONG';
  bool get _isKGCD => _catId == 'KHONG_GIAN_CD';
  bool get _isLT => _catId == 'LUU_TRU';

  bool get _hasUtil => _isPhong;
  bool get _hasMgmt => _isCan;
  bool get _hasComElec => _isKiot || _isVP || _isKho || _isKGCD;
  bool get _hasTime => _isVP || _isKGCD || _isKho || _isLT;
  bool get _hasClean => _isKtx || _isKGCD || _isLT;
  bool get _hasCheckIO => _isLT;
  bool get _hasPolicy => _isPhong || _isCan || _isKtx || _isLT;

  @override
  void initState() {
    super.initState();
    final b = widget.branch;
    _depCtrl = TextEditingController(text: '1');
    _billCtrl = TextEditingController(text: '5');
    _elecCtrl = TextEditingController(
      text: b.electricityPrice?.toInt().toString() ?? '3500',
    );
    _waterCtrl = TextEditingController(
      text: b.waterPrice?.toInt().toString() ?? '15000',
    );
    _wifiCtrl = TextEditingController(
      text: b.internetPrice?.toInt().toString() ?? '100000',
    );
    _trashCtrl = TextEditingController(
      text: b.trashPrice?.toInt().toString() ?? '30000',
    );
    _mgmtCtrl = TextEditingController(text: '0');
    _comElecCtrl = TextEditingController(text: '5000');
  }

  @override
  void dispose() {
    for (final c in [
      _depCtrl,
      _billCtrl,
      _elecCtrl,
      _waterCtrl,
      _wifiCtrl,
      _trashCtrl,
      _mgmtCtrl,
      _comElecCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ref.read(branchProvider.notifier).updateBranch(widget.branch.id, {
        'rentalCategory': _catId,
        'rentalSubModel': _subId,
        if (_hasUtil) ...{
          'electricityPrice': double.tryParse(_elecCtrl.text),
          'waterPrice': double.tryParse(_waterCtrl.text),
          'internetPrice': double.tryParse(_wifiCtrl.text),
          'trashPrice': double.tryParse(_trashCtrl.text),
        },
        if (_hasMgmt) 'buildingMgmtFee': double.tryParse(_mgmtCtrl.text),
        if (_hasComElec) 'commercialElec': double.tryParse(_comElecCtrl.text),
        if (_hasTime) 'timeUnit': _timeUnit,
        if (_hasClean) 'cleanFreq': _cleanFreq,
        if (_hasCheckIO) ...{
          'checkInHour': _checkIn,
          'checkOutHour': _checkOut,
        },
        'depositMonths': int.tryParse(_depCtrl.text) ?? 1,
        'billingDay': int.tryParse(_billCtrl.text) ?? 5,
        if (_hasPolicy) ...{
          'maxCapacity': _maxCap,
          'maxVehicles': _maxVeh,
          'genderPolicy': _gender,
          'petPolicy': _pet,
        },
        if (_isPhong) 'cookingPolicy': _cooking,
        if (_isLT) 'maxGuests': _maxCap,
      });
      if (mounted) {
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Thành công'),
              content: const Text('Đã cập nhật Mô hình Cho thuê!'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Lỗi'),
              content: Text('$e'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Đóng'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      title: 'Mô hình Cho thuê',
      backgroundColors: AppTheme.kBackgroundLight,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Thiết lập Mô hình Kinh doanh',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Chọn đúng phân loại để hệ thống tự động điều chỉnh hợp đồng, hóa đơn và chính sách vận hành.',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),

            // Category selector
            _sec('PHÂN LOẠI BẤT ĐỘNG SẢN'),
            ...kRentalCategories.map(_catCard),
            const SizedBox(height: 20),

            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              child: Column(
                key: ValueKey(_catId),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sec('LOẠI HÌNH CHI TIẾT'),
                  _subSelector(),
                  const SizedBox(height: 20),
                  _sec('CẤU HÌNH TÀI CHÍNH & VẬN HÀNH'),
                  _financeBox(),
                  const SizedBox(height: 20),
                  if (_hasPolicy) ...[
                    _sec('GIỚI HẠN & NỘI QUY'),
                    _policyBox(),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),

            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: const Color(0xFF0EA5E9),
                borderRadius: BorderRadius.circular(16),
                padding: const EdgeInsets.symmetric(vertical: 16),
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const CupertinoActivityIndicator(
                        color: CupertinoColors.white,
                      )
                    : const Text(
                        'Áp Dụng Mô Hình Kinh Doanh',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sec(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10, left: 2),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Color(0xFF4B5563),
        letterSpacing: 1.0,
      ),
    ),
  );

  Widget _catCard(RentalCategory cat) {
    final sel = cat.id == _catId;
    return GestureDetector(
      onTap: () => setState(() {
        _catId = cat.id;
        _subId = cat.subModels.first.id;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFFF0F7FF) : CupertinoColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: sel ? const Color(0xFF0EA5E9) : const Color(0xFFE5E7EB),
            width: sel ? 1.5 : 1,
          ),
          boxShadow: sel
              ? [
                  BoxShadow(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: sel ? const Color(0xFFDBEAFE) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(
                child: Text(cat.emoji, style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cat.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: sel
                          ? const Color(0xFF0EA5E9)
                          : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    cat.subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (sel)
              const Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: Color(0xFF0EA5E9),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _subSelector() => Container(
    padding: const EdgeInsets.all(8),
    decoration: _cd(),
    child: Column(
      children: _cat.subModels.map((sub) {
        final sel = _subId == sub.id;
        return GestureDetector(
          onTap: () => setState(() => _subId = sub.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: sel ? const Color(0xFFF0F7FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: sel ? const Color(0xFF0EA5E9) : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  sel
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.circle,
                  size: 18,
                  color: sel
                      ? const Color(0xFF0EA5E9)
                      : const Color(0xFFD1D5DB),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: sel
                              ? const Color(0xFF0EA5E9)
                              : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sub.desc,
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
          ),
        );
      }).toList(),
    ),
  );

  Widget _financeBox() => AnimatedSize(
    duration: const Duration(milliseconds: 250),
    curve: Curves.easeOut,
    child: Container(
      key: ValueKey('finance_$_catId'),
      padding: const EdgeInsets.all(16),
      decoration: _cd(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PHONG_TRO: điện nước wifi rác
          if (_hasUtil) ...[
            _note(
              CupertinoIcons.bolt_fill,
              'Chủ nhà thu điện/nước theo đơn giá riêng, ghi trên hóa đơn hàng tháng.',
              const Color(0xFFD97706),
              const Color(0xFFFFFBEB),
            ),
            const SizedBox(height: 12),
            _row(
              CupertinoIcons.bolt_fill,
              const Color(0xFFD97706),
              'Đơn giá điện (đ/kWh):',
              _pf(_elecCtrl),
            ),
            const SizedBox(height: 10),
            _row(
              CupertinoIcons.drop_fill,
              const Color(0xFF0EA5E9),
              'Đơn giá nước (đ/m³):',
              _pf(_waterCtrl),
            ),
            const SizedBox(height: 10),
            _row(
              CupertinoIcons.wifi,
              const Color(0xFF8B5CF6),
              'Internet (đ/tháng):',
              _pf(_wifiCtrl),
            ),
            const SizedBox(height: 10),
            _row(
              CupertinoIcons.trash_fill,
              const Color(0xFF6B7280),
              'Phí rác (đ/tháng):',
              _pf(_trashCtrl),
            ),
            const _Dv(),
          ],

          // NHA_NGUYEN_CAN: phí BQL
          if (_hasMgmt) ...[
            _note(
              CupertinoIcons.info_circle_fill,
              'Khách tự thanh toán điện/nước theo giá Nhà nước. Chủ nhà ghi nhận phí quản lý BQL (nếu có).',
              const Color(0xFF6366F1),
              const Color(0xFFF5F3FF),
            ),
            const SizedBox(height: 12),
            _row(
              CupertinoIcons.building_2_fill,
              const Color(0xFF6366F1),
              'Phí BQL / KĐT (đ/tháng):',
              _pf(_mgmtCtrl),
            ),
            const _Dv(),
          ],

          // Thương mại / VP / Kho / CD: điện TM
          if (_hasComElec) ...[
            _note(
              CupertinoIcons.bolt_fill,
              'Mặt bằng thương mại dùng giá điện kinh doanh (4.000–6.000đ/kWh). Thỏa thuận theo hợp đồng.',
              const Color(0xFFD97706),
              const Color(0xFFFFFBEB),
            ),
            const SizedBox(height: 12),
            _row(
              CupertinoIcons.bolt_fill,
              const Color(0xFFD97706),
              'Đơn giá điện TM (đ/kWh):',
              _pf(_comElecCtrl),
            ),
            const _Dv(),
          ],

          // Đơn vị tính
          if (_hasTime) ...[
            _row(
              CupertinoIcons.clock_fill,
              const Color(0xFF6366F1),
              'Đơn vị tính giá:',
              CupertinoSlidingSegmentedControl<String>(
                groupValue: _timeUnit,
                children: _isLT
                    ? const {
                        'GIO': Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('Giờ', style: TextStyle(fontSize: 12)),
                        ),
                        'DEM': Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('Đêm', style: TextStyle(fontSize: 12)),
                        ),
                        'THANG': Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('Tháng', style: TextStyle(fontSize: 12)),
                        ),
                      }
                    : const {
                        'GIO': Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('Giờ', style: TextStyle(fontSize: 12)),
                        ),
                        'NGAY': Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('Ngày', style: TextStyle(fontSize: 12)),
                        ),
                        'THANG': Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text('Tháng', style: TextStyle(fontSize: 12)),
                        ),
                      },
                onValueChanged: (v) {
                  if (v != null) setState(() => _timeUnit = v);
                },
              ),
            ),
            const _Dv(),
          ],

          // Dọn dẹp
          if (_hasClean) ...[
            _row(
              CupertinoIcons.sparkles,
              const Color(0xFF10B981),
              'Tần suất dọn dẹp:',
              CupertinoSlidingSegmentedControl<String>(
                groupValue: _cleanFreq,
                children: const {
                  'HANG_NGAY': Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3),
                    child: Text('Hàng ngày', style: TextStyle(fontSize: 11)),
                  ),
                  'HANG_TUAN': Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3),
                    child: Text('Hàng tuần', style: TextStyle(fontSize: 11)),
                  ),
                  'HANG_THANG': Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3),
                    child: Text('Hàng tháng', style: TextStyle(fontSize: 11)),
                  ),
                  'KHONG': Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3),
                    child: Text('Không dọn', style: TextStyle(fontSize: 11)),
                  ),
                },
                onValueChanged: (v) {
                  if (v != null) setState(() => _cleanFreq = v);
                },
              ),
            ),
            const _Dv(),
          ],

          // Check-in / out (Lưu trú ngắn hạn)
          if (_hasCheckIO) ...[
            _row(
              CupertinoIcons.arrow_right_circle_fill,
              const Color(0xFF0EA5E9),
              'Giờ Check-in:',
              _hourPick(_checkIn, (h) => setState(() => _checkIn = h)),
            ),
            const SizedBox(height: 10),
            _row(
              CupertinoIcons.arrow_left_circle_fill,
              const Color(0xFFEF4444),
              'Giờ Check-out:',
              _hourPick(_checkOut, (h) => setState(() => _checkOut = h)),
            ),
            const _Dv(),
          ],

          // Chung: cọc & hóa đơn
          _row(
            CupertinoIcons.shield_fill,
            const Color(0xFF10B981),
            'Số tháng đặt cọc:',
            SizedBox(
              width: 80,
              child: CupertinoTextField(
                controller: _depCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _row(
            CupertinoIcons.calendar,
            const Color(0xFF0EA5E9),
            'Ngày lập hóa đơn:',
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Ngày ',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
                SizedBox(
                  width: 50,
                  child: CupertinoTextField(
                    controller: _billCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const Text(
                  ' /tháng',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _policyBox() => Container(
    padding: const EdgeInsets.all(16),
    decoration: _cd(),
    child: Column(
      children: [
        _row(
          CupertinoIcons.person_2_fill,
          const Color(0xFF0EA5E9),
          _isLT ? 'Số khách tối đa:' : 'Số người tối đa / phòng:',
          _step(
            _maxCap,
            _maxCap > 1 ? () => setState(() => _maxCap--) : null,
            () => setState(() => _maxCap++),
          ),
        ),
        const SizedBox(height: 14),

        if (_isPhong || _isCan) ...[
          _row(
            CupertinoIcons.car_detailed,
            const Color(0xFF6B7280),
            'Xe máy tối đa / phòng:',
            _step(
              _maxVeh,
              _maxVeh > 0 ? () => setState(() => _maxVeh--) : null,
              () => setState(() => _maxVeh++),
            ),
          ),
          const _Dv(),
        ] else
          const _Dv(),

        if (_isPhong || _isKtx) ...[
          _row(
            CupertinoIcons.person_crop_circle_badge_exclam,
            const Color(0xFFEC4899),
            'Yêu cầu giới tính:',
            CupertinoSlidingSegmentedControl<String>(
              groupValue: _gender,
              children: const {
                'HET': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Tất cả', style: TextStyle(fontSize: 12)),
                ),
                'NAM': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Nam', style: TextStyle(fontSize: 12)),
                ),
                'NU': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Nữ', style: TextStyle(fontSize: 12)),
                ),
              },
              onValueChanged: (v) {
                if (v != null) setState(() => _gender = v);
              },
            ),
          ),
          const SizedBox(height: 14),
        ],

        if (_isPhong || _isCan || _isKtx) ...[
          _row(
            CupertinoIcons.paw,
            const Color(0xFF92400E),
            'Quy định thú cưng:',
            CupertinoSlidingSegmentedControl<String>(
              groupValue: _pet,
              children: const {
                'CHO_PHEP': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text('Cho phép', style: TextStyle(fontSize: 11)),
                ),
                'KHONG': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text('Cấm', style: TextStyle(fontSize: 11)),
                ),
                'DAT_COC': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text('Đặt cọc', style: TextStyle(fontSize: 11)),
                ),
              },
              onValueChanged: (v) {
                if (v != null) setState(() => _pet = v);
              },
            ),
          ),
          const SizedBox(height: 14),
        ],

        if (_isPhong)
          _row(
            CupertinoIcons.flame_fill,
            const Color(0xFFEF4444),
            'Nấu ăn:',
            CupertinoSlidingSegmentedControl<String>(
              groupValue: _cooking,
              children: const {
                'TRONG_PHONG': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text('Trong phòng', style: TextStyle(fontSize: 11)),
                ),
                'KHU_CHUNG': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text('Khu chung', style: TextStyle(fontSize: 11)),
                ),
                'KHONG': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text('Cấm nấu', style: TextStyle(fontSize: 11)),
                ),
              },
              onValueChanged: (v) {
                if (v != null) setState(() => _cooking = v);
              },
            ),
          ),
      ],
    ),
  );

  // ── micro helpers ──────────────────────────────────────────────────────────
  BoxDecoration _cd() => BoxDecoration(
    color: CupertinoColors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: const Color(0xFFE5E7EB)),
  );

  Widget _row(IconData icon, Color color, String label, Widget child) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
              ),
            ),
            child,
          ],
        ),
      );

  Widget _pf(TextEditingController ctrl) => SizedBox(
    width: 110,
    child: CupertinoTextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.right,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );

  Widget _step(int v, VoidCallback? dec, VoidCallback inc) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: dec,
        child: Icon(
          CupertinoIcons.minus_circle,
          size: 24,
          color: dec == null
              ? const Color(0xFFD1D5DB)
              : const Color(0xFF0EA5E9),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          '$v',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: inc,
        child: const Icon(
          CupertinoIcons.plus_circle,
          size: 24,
          color: Color(0xFF0EA5E9),
        ),
      ),
    ],
  );

  Widget _hourPick(int hour, void Function(int) cb) => GestureDetector(
    onTap: () async => showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => SizedBox(
        height: 220,
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.time,
          use24hFormat: true,
          initialDateTime: DateTime(2024, 1, 1, hour),
          onDateTimeChanged: (dt) => cb(dt.hour),
        ),
      ),
    ),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${hour.toString().padLeft(2, "0")}:00',
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: Color(0xFF111827),
        ),
      ),
    ),
  );

  Widget _note(IconData icon, String t, Color color, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            t,
            style: TextStyle(fontSize: 11, color: color, height: 1.4),
          ),
        ),
      ],
    ),
  );
}

class _Dv extends StatelessWidget {
  const _Dv();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 12),
    child: SizedBox(height: 1, child: ColoredBox(color: Color(0xFFE5E7EB))),
  );
}
