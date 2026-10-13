import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../contract/data/models/contract_model.dart';
import '../data/models/checkout_request_model.dart';
import '../application/owner_checkout_notifier.dart';

class CreateCheckoutBillScreen extends ConsumerStatefulWidget {
  final CheckoutRequestModel request;
  final ContractModel contract;
  final double initialDamageFee;
  final String initialDamageReason;

  const CreateCheckoutBillScreen({
    super.key,
    required this.request,
    required this.contract,
    this.initialDamageFee = 0,
    this.initialDamageReason = '',
  });

  @override
  ConsumerState<CreateCheckoutBillScreen> createState() =>
      _CreateCheckoutBillScreenState();
}

class _CreateCheckoutBillScreenState
    extends ConsumerState<CreateCheckoutBillScreen> {
  final _formKey = GlobalKey<FormState>();

  final _elecCurrentController = TextEditingController();
  final _waterCurrentController = TextEditingController();
  late final TextEditingController _damageFeeController;
  late final TextEditingController _damageReasonController;

  double _calculatedRent = 0;
  double _calculatedElec = 0;
  double _calculatedWater = 0;
  double _calculatedService = 0;
  int _unusedDays = 0;
  int _daysInMonth = 30;

  // Toggle từng khoản
  bool _includeRentRefund = true;
  bool _includeServiceRefund = true;
  bool _includeElec = true;
  bool _includeWater = true;

  // true = trả đúng hạn → hoàn cọc
  // false = trả sai hạn (sớm/muộn) → mất cọc
  bool _checkoutOnTime = true;

  @override
  void initState() {
    super.initState();
    _damageFeeController = TextEditingController(
      text: widget.initialDamageFee > 0
          ? widget.initialDamageFee.toStringAsFixed(0)
          : '0',
    );
    _damageReasonController = TextEditingController(
      text: widget.initialDamageReason,
    );
    _elecCurrentController.addListener(_updateUtilityFees);
    _waterCurrentController.addListener(_updateUtilityFees);
    _damageFeeController.addListener(
      () => setState(() {}),
    ); // To update total dynamically
    _calculateProratedFees();
  }

  @override
  void dispose() {
    _elecCurrentController.dispose();
    _waterCurrentController.dispose();
    _damageFeeController.dispose();
    _damageReasonController.dispose();
    super.dispose();
  }

  void _calculateProratedFees() {
    // Pro-rata Refund Calculator
    // Khách đã trả trước cả tháng. Khi trả phòng sớm, tính hoàn tiền cho số ngày chưa ở.
    final checkOutDate = widget.request.targetCheckoutDate;
    final dim = DateTime(
      checkOutDate.year,
      checkOutDate.month + 1,
      0,
    ).day; // số ngày thực trong tháng
    final endOfMonth = DateTime(checkOutDate.year, checkOutDate.month, dim);
    final unused = endOfMonth.difference(checkOutDate).inDays;

    setState(() {
      _daysInMonth = dim;
      _unusedDays = unused;
      _calculatedRent = (widget.contract.monthlyRent / dim) * unused;
      _calculatedService = ((widget.contract.serviceFee ?? 0) / dim) * unused;
    });
  }

  void _updateUtilityFees() {
    setState(() {
      final elecCurrent = double.tryParse(_elecCurrentController.text) ?? 0;
      final waterCurrent = double.tryParse(_waterCurrentController.text) ?? 0;
      // Mock previous values = 0 cho đơn giản (thực tế lấy từ Bill tháng trước)
      const elecPrevious = 0.0;
      const waterPrevious = 0.0;

      if (elecCurrent >= elecPrevious) {
        _calculatedElec =
            (elecCurrent - elecPrevious) *
            (widget.contract.electricityPrice ?? 0);
      }
      if (waterCurrent >= waterPrevious) {
        _calculatedWater =
            (waterCurrent - waterPrevious) * (widget.contract.waterPrice ?? 0);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final damageFee = double.tryParse(_damageFeeController.text) ?? 0;
    final effectiveRentRefund = _includeRentRefund ? _calculatedRent : 0;
    final effectiveServiceRefund = _includeServiceRefund
        ? _calculatedService
        : 0;
    final effectiveElec = _includeElec ? _calculatedElec : 0;
    final effectiveWater = _includeWater ? _calculatedWater : 0;
    final totalFees =
        effectiveElec +
        effectiveWater +
        damageFee -
        effectiveRentRefund -
        effectiveServiceRefund;
    final deposit = _checkoutOnTime
        ? (widget.contract.depositAmount ?? 0)
        : 0.0;
    final finalAmount = totalFees - deposit;

    final success = await ref
        .read(ownerCheckoutProvider.notifier)
        .approveAndCreateBill(widget.request.id, {
          'rentAmount': effectiveRentRefund,
          'electricAmount': effectiveElec,
          'waterAmount': effectiveWater,
          'serviceAmount': effectiveServiceRefund,
          'damageFee': damageFee,
          'damageReason': _damageReasonController.text,
          'electricCurrent': double.tryParse(_elecCurrentController.text) ?? 0,
          'waterCurrent': double.tryParse(_waterCurrentController.text) ?? 0,
          'totalFees': totalFees,
          'deposit': deposit,
          'finalAmount': finalAmount,
          'depositRefunded': _checkoutOnTime,
          'checkoutOnTime': _checkoutOnTime,
        });

    if (success && mounted) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(
            'Thành công',
            style: TextStyle(color: Colors.green),
          ),
          content: const Text('Đã gửi hóa đơn quyết toán thành công!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      if (mounted) {
        // Pop cả màn hình này và màn hình Detail để quay về List
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ownerCheckoutProvider);
    final damageFee = double.tryParse(_damageFeeController.text) ?? 0;
    // Hiệu lực từng khoản theo toggle
    final effectiveRentRefund = _includeRentRefund ? _calculatedRent : 0;
    final effectiveServiceRefund = _includeServiceRefund
        ? _calculatedService
        : 0;
    final effectiveElec = _includeElec ? _calculatedElec : 0;
    final effectiveWater = _includeWater ? _calculatedWater : 0;
    final totalFees =
        effectiveElec +
        effectiveWater +
        damageFee -
        effectiveRentRefund -
        effectiveServiceRefund;
    final deposit = _checkoutOnTime
        ? (widget.contract.depositAmount ?? 0)
        : 0.0;
    final finalAmount = totalFees - deposit;

    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.kBackgroundLight,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        border: null,
        middle: const Text(
          'Hóa Đơn Quyết Toán',
          style: TextStyle(color: CupertinoColors.black),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(
            CupertinoIcons.back,
            color: CupertinoColors.activeBlue,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // CÁC KHOẢN TÍNH TOÁN (có thể tích chọn)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'CÁC KHOẢN TÍNH TOÁN',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.blue,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'Ngày trả: ${widget.request.targetCheckoutDate.day}/${widget.request.targetCheckoutDate.month}/${widget.request.targetCheckoutDate.year}  •  Chưa ở: $_unusedDays/$_daysInMonth ngày trong tháng',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 20),
                          // Hoàn tiền nhà
                          if (_unusedDays > 0)
                            _buildToggleRow(
                              label: 'Hoàn tiền nhà ($_unusedDays ngày chưa ở)',
                              amount: -_calculatedRent,
                              formatter: formatter,
                              isActive: _includeRentRefund,
                              activeColor: Colors.green,
                              onToggle: (v) =>
                                  setState(() => _includeRentRefund = v),
                            ),
                          // Hoàn dịch vụ
                          if (_unusedDays > 0 &&
                              (widget.contract.serviceFee ?? 0) > 0)
                            _buildToggleRow(
                              label: 'Hoàn phí dịch vụ ($_unusedDays ngày)',
                              amount: -_calculatedService,
                              formatter: formatter,
                              isActive: _includeServiceRefund,
                              activeColor: Colors.green,
                              onToggle: (v) =>
                                  setState(() => _includeServiceRefund = v),
                            ),
                          // Tiền điện
                          _buildToggleRow(
                            label:
                                'Tiền điện (${_elecCurrentController.text.isEmpty ? "chưa nhập" : "${_elecCurrentController.text} kWh"})',
                            amount: _calculatedElec,
                            formatter: formatter,
                            isActive: _includeElec,
                            activeColor: Colors.orange,
                            onToggle: (v) => setState(() => _includeElec = v),
                          ),
                          // Tiền nước
                          _buildToggleRow(
                            label:
                                'Tiền nước (${_waterCurrentController.text.isEmpty ? "chưa nhập" : "${_waterCurrentController.text} m³"})',
                            amount: _calculatedWater,
                            formatter: formatter,
                            isActive: _includeWater,
                            activeColor: Colors.blue,
                            onToggle: (v) => setState(() => _includeWater = v),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'CHỈ SỐ ĐIỆN NƯỚC CUỐI CÙNG',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _elecCurrentController,
                            decoration: const InputDecoration(
                              labelText: 'Số điện mới',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => _updateUtilityFees(),
                            validator: (v) =>
                                v!.isEmpty ? 'Nhập số điện' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _waterCurrentController,
                            decoration: const InputDecoration(
                              labelText: 'Số nước mới',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => _updateUtilityFees(),
                            validator: (v) =>
                                v!.isEmpty ? 'Nhập số nước' : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'CHI PHÍ ĐỀN BÙ / PHẠT HƯ HẠI',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _damageFeeController,
                      decoration: const InputDecoration(
                        labelText: 'Số tiền phạt (đ)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập số tiền (0 nếu không phạt)';
                        }
                        final val = double.tryParse(value);
                        if (val == null || val < 0) {
                          return 'Số tiền không hợp lệ hoặc âm';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // MANDATE VALIDATION LOGIC FOR DAMAGE REASON
                    TextFormField(
                      controller: _damageReasonController,
                      decoration: const InputDecoration(
                        labelText: 'Lý do phạt (Bắt buộc nếu tiền phạt > 0)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      validator: (value) {
                        final fee =
                            double.tryParse(_damageFeeController.text) ?? 0;
                        if (fee > 0) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Bắt buộc phải nhập lý do phạt cụ thể khi có chi phí hư hại tài sản!';
                          }
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // DEPOSIT / ON-TIME CHECKOUT TOGGLE
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _checkoutOnTime
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _checkoutOnTime ? Colors.green : Colors.red,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'XÁC NHẬN TIỀN CỌC',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: _checkoutOnTime
                                  ? Colors.green.shade800
                                  : Colors.red.shade800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Option 1: On Time
                          InkWell(
                            onTap: () => setState(() => _checkoutOnTime = true),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: _checkoutOnTime
                                    ? Colors.green.shade100
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _checkoutOnTime
                                      ? Colors.green
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _checkoutOnTime
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    color: _checkoutOnTime
                                        ? Colors.green
                                        : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Trả đúng hạn / Thoả thuận hợp lệ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          '→ Hoàn tiền cọc (trừ vào tổng phải thu)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Option 2: Late/Early
                          InkWell(
                            onTap: () =>
                                setState(() => _checkoutOnTime = false),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: !_checkoutOnTime
                                    ? Colors.red.shade100
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: !_checkoutOnTime
                                      ? Colors.red
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    !_checkoutOnTime
                                        ? Icons.cancel
                                        : Icons.circle_outlined,
                                    color: !_checkoutOnTime
                                        ? Colors.red
                                        : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Trả sai hạn / Vi phạm hợp đồng',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          '→ Mất cọc (chủ nhà giữ toàn bộ tiền cọc)',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (!_checkoutOnTime) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Tiền cọc ${NumberFormat.currency(locale: "vi_VN", symbol: "đ").format(widget.contract.depositAmount ?? 0)} sẽ KHÔNG được hoàn lại.',
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
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

                    const SizedBox(height: 24),

                    // TOTAL BREAKDOWN
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'BẢNG TỔNG KẾT',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Color(0xFF8C8C8C),
                            ),
                          ),
                          const Divider(height: 24),
                          if (_includeElec && _calculatedElec > 0)
                            _buildFeeRow(
                              'Tiền điện:',
                              _calculatedElec,
                              formatter,
                            ),
                          if (_includeWater && _calculatedWater > 0)
                            _buildFeeRow(
                              'Tiền nước:',
                              _calculatedWater,
                              formatter,
                            ),
                          if (damageFee > 0)
                            _buildFeeRow(
                              'Phí phạt hư hại:',
                              damageFee,
                              formatter,
                              color: Colors.red,
                            ),
                          if (_includeRentRefund && _calculatedRent > 0)
                            _buildFeeRow(
                              'Hoàn tiền nhà (ngày chưa ở):',
                              -_calculatedRent,
                              formatter,
                              color: Colors.green,
                            ),
                          if (_includeServiceRefund && _calculatedService > 0)
                            _buildFeeRow(
                              'Hoàn phí dịch vụ (ngày chưa dùng):',
                              -_calculatedService,
                              formatter,
                              color: Colors.green,
                            ),
                          const Divider(height: 24),
                          _buildFeeRow(
                            'Tổng phát sinh:',
                            totalFees,
                            formatter,
                            isBold: true,
                          ),
                          const SizedBox(height: 4),
                          if (_checkoutOnTime && deposit > 0)
                            _buildFeeRow(
                              'Tiền cọc đã thu (hoàn):',
                              -deposit,
                              formatter,
                              color: Colors.green,
                              isBold: true,
                            )
                          else if (!_checkoutOnTime &&
                              (widget.contract.depositAmount ?? 0) > 0)
                            _buildFeeRow(
                              'Tiền cọc (chủ nhà giữ):',
                              widget.contract.depositAmount!,
                              formatter,
                              color: Colors.red.shade700,
                              isBold: true,
                            ),
                          const Divider(height: 24),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                finalAmount >= 0
                                    ? 'KHÁCH CÒN PHẢI TRẢ:'
                                    : 'HOÀN LẠI CHO KHÁCH:',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: finalAmount >= 0
                                      ? Colors.red.shade700
                                      : Colors.green.shade700,
                                ),
                              ),
                              Text(
                                formatter.format(finalAmount.abs()),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: finalAmount >= 0
                                      ? Colors.red.shade700
                                      : Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => _submit(),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.kAccentColor,
                      ),
                      child: const Text(
                        'Gửi Hóa Đơn Hoàn Phòng',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildFeeRow(
    String label,
    double amount,
    NumberFormat formatter, {
    Color? color,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color ?? Colors.black87,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          Text(
            formatter.format(amount),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required String label,
    required double amount,
    required NumberFormat formatter,
    required bool isActive,
    required Color activeColor,
    required ValueChanged<bool> onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          Switch(
            value: isActive,
            activeThumbColor: activeColor,
            onChanged: onToggle,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isActive ? Colors.black87 : Colors.grey,
                decoration: isActive ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
          Text(
            formatter.format(amount),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isActive ? activeColor : Colors.grey,
              decoration: isActive ? null : TextDecoration.lineThrough,
            ),
          ),
        ],
      ),
    );
  }
}
