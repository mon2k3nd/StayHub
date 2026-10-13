import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/core_providers.dart';
import '../../bill/data/models/bill_model.dart';
import '../data/models/checkout_request_model.dart';
import 'dispute_chat_screen.dart';
import '../../bill/presentation/split_bill_screen.dart';
import '../../bill/application/bill_notifier.dart';
import 'package:screen_protector/screen_protector.dart';
import 'dart:async' show unawaited;

class TenantCheckoutBillScreen extends ConsumerStatefulWidget {
  final BillModel bill;
  final CheckoutRequestModel request;

  const TenantCheckoutBillScreen({
    super.key,
    required this.bill,
    required this.request,
  });

  @override
  ConsumerState<TenantCheckoutBillScreen> createState() =>
      _TenantCheckoutBillScreenState();
}

class _TenantCheckoutBillScreenState
    extends ConsumerState<TenantCheckoutBillScreen> {
  final _disputeReasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isProcessingPayment = false;
  late BillModel _currentBill;

  @override
  void initState() {
    super.initState();
    _currentBill = widget.bill;
    unawaited(ScreenProtector.preventScreenshotOn());
    unawaited(ScreenProtector.protectDataLeakageOn());
  }

  @override
  void dispose() {
    unawaited(ScreenProtector.preventScreenshotOff());
    unawaited(ScreenProtector.protectDataLeakageWithColorOff());
    _disputeReasonController.dispose();
    super.dispose();
  }

  void _showVietQRBottomSheet() {
    // Generate VietQR string (Mock format)
    // Thực tế sẽ dùng thư viện vietqr_generator hoặc lấy từ API
    final amount = _currentBill.totalAmount?.toInt() ?? 0;
    final info = Uri.encodeComponent('Thanh toan quyet toan');
    final qrData =
        'https://img.vietqr.io/image/970415-113366668888-compact2.png?amount=$amount&addInfo=$info';

    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Thanh Toán Quyết Toán',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Quét mã VietQR dưới đây bằng ứng dụng ngân hàng của bạn.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Image.network(
                  _currentBill.paymentQrUrl ?? qrData,
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Số tiền: ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(_currentBill.totalAmount)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessingPayment
                      ? null
                      : () async {
                          setState(() => _isProcessingPayment = true);
                          // Gọi API xác nhận thanh toán (Mock)
                          // Trong thực tế, Backend sẽ nhận Webhook từ ngân hàng
                          await Future.delayed(const Duration(seconds: 2));

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            _showSuccessDialog();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.kAccentColor,
                  ),
                  child: _isProcessingPayment
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text(
                          'Tôi đã thanh toán',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 16),
              const Text(
                'Hoàn tất trả phòng thành công 🎉',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Cảm ơn bạn đã sử dụng dịch vụ của StayHub. Chúc bạn thành công trên chặng đường mới!',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Return to dashboard
                  Navigator.of(ctx).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kAccentColor,
                ),
                child: const Text(
                  'Về màn hình chính',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDisputeDialog() {
    unawaited(
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(
            'Phản hồi & Thắc mắc',
            style: TextStyle(color: Colors.orange),
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Vui lòng nhập lý do khiếu nại của bạn:'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _disputeReasonController,
                  decoration: const InputDecoration(
                    labelText: 'Lý do khiếu nại',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Bắt buộc nhập lý do khiếu nại!';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final reason = _disputeReasonController.text;
                  Navigator.pop(ctx);

                  try {
                    final dio = ref.read(dioProvider);
                    await dio.post(
                      '/v1/bills/${widget.bill.id}/dispute',
                      data: {'reason': reason},
                    );
                  } catch (e) {
                    debugPrint('Failed to dispute bill: $e');
                  }

                  if (!mounted) return;
                  unawaited(
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DisputeChatScreen(
                          initialBill: widget.bill,
                          isOwner: false,
                        ),
                      ),
                    ),
                  );
                }
              },
              child: const Text(
                'Gửi Khiếu Nại',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.kBackgroundLight,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        border: null,
        middle: const Text(
          'Chi Tiết Quyết Toán',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: CupertinoColors.black,
          ),
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
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Icon Header
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.kAccentColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.receipt_long_rounded,
                        color: AppTheme.kAccentColor,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Hóa Đơn Của Bạn',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Bill Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BẢNG KÊ CHI TIẾT',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Colors.black54,
                            letterSpacing: 1.2,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if ((_currentBill.rentAmount ?? 0) > 0)
                          _buildRow(
                            'Tiền thuê lẻ:',
                            _currentBill.rentAmount,
                            formatter,
                          ),
                        if ((_currentBill.electricAmount ?? 0) > 0)
                          _buildRow(
                            'Tiền điện:',
                            _currentBill.electricAmount,
                            formatter,
                          ),
                        if ((_currentBill.waterAmount ?? 0) > 0)
                          _buildRow(
                            'Tiền nước:',
                            _currentBill.waterAmount,
                            formatter,
                          ),
                        if ((_currentBill.serviceAmount ?? 0) > 0)
                          _buildRow(
                            'Dịch vụ:',
                            _currentBill.serviceAmount,
                            formatter,
                          ),
                        if ((_currentBill.damageFee ?? 0) > 0) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Divider(color: Colors.black12, height: 1),
                          ),
                          _buildRow(
                            'Tiền phạt hư hại:',
                            _currentBill.damageFee,
                            formatter,
                            isRed: true,
                          ),
                          if (_currentBill.damageReason != null &&
                              _currentBill.damageReason!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 8),
                              child: Text(
                                'Lý do: ${_currentBill.damageReason}',
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                        const SizedBox(height: 16),
                        const Divider(color: Colors.black12, height: 1),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TỔNG CỘNG',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              formatter.format(_currentBill.totalAmount ?? 0),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.kAccentColor,
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

            // Bottom Actions
            Container(
              padding: const EdgeInsets.all(
                20,
              ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: _currentBill.status == 'DISPUTED'
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                            'Hóa đơn này đang trong quá trình thương lượng. Vui lòng thống nhất với chủ nhà trước khi thanh toán.',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(
                              Icons.chat_bubble_outline,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Vào Phòng Thương Lượng',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DisputeChatScreen(
                                    initialBill: _currentBill,
                                    isOwner: false,
                                  ),
                                ),
                              );

                              // Refresh bills when returning
                              await ref
                                  .read(billProvider.notifier)
                                  .refreshBills();
                              final bills = ref.read(billProvider).value;
                              if (bills != null && mounted) {
                                final updated = bills.firstWhere(
                                  (b) => b.id == _currentBill.id,
                                  orElse: () => _currentBill,
                                );
                                setState(() {
                                  _currentBill = updated;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _showVietQRBottomSheet,
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.kAccentColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Vẫn muốn thanh toán ngay?',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _showVietQRBottomSheet,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  backgroundColor: AppTheme.kAccentColor,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Thanh Toán Ngay',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton(
                              onPressed: () {
                                unawaited(
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          SplitBillScreen(bill: widget.bill),
                                    ),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 16,
                                ),
                                foregroundColor: Colors.green.shade600,
                                side: BorderSide(
                                  color: Colors.green.shade200,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Icon(Icons.people_outline, size: 24),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _showDisputeDialog,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.orange.shade700,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Bạn có thắc mắc? Phản hồi ngay',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
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

  Widget _buildRow(
    String label,
    double? amount,
    NumberFormat formatter, {
    bool isRed = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isRed ? Colors.redAccent : Colors.black54,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            formatter.format(amount ?? 0),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: isRed ? Colors.redAccent : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
