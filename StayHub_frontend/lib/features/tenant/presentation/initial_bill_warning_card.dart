import 'dart:async';
import 'package:flutter/cupertino.dart';

import '../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter/material.dart' show ScaffoldMessenger, SnackBar;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../bill/application/bill_notifier.dart';
import '../../bill/data/models/bill_model.dart';

class InitialBillWarningCard extends ConsumerStatefulWidget {
  const InitialBillWarningCard({super.key});

  @override
  ConsumerState<InitialBillWarningCard> createState() =>
      _InitialBillWarningCardState();
}

class _InitialBillWarningCardState extends ConsumerState<InitialBillWarningCard>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  DateTime? _dueDate;
  Duration _timeLeft = Duration.zero;
  bool _isExpired = false;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    unawaited(_pulseCtrl.repeat(reverse: true));
    _pulseAnim = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_dueDate == null) return;
      final now = DateTime.now();
      final due = _dueDate!;
      if (now.isAfter(due)) {
        if (!_isExpired) {
          setState(() {
            _isExpired = true;
            _timeLeft = Duration.zero;
          });
        }
      } else {
        setState(() {
          _isExpired = false;
          _timeLeft = due.difference(now);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final fmt = NumberFormat('#,###', 'vi_VN');
    return '${fmt.format(amount)}đ';
  }

  String get _formattedTime {
    if (_isExpired) return 'ĐÃ QUÁ HẠN';
    final h = _timeLeft.inHours.toString().padLeft(2, '0');
    final m = (_timeLeft.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final billsAsync = ref.watch(billProvider);

    return billsAsync.when(
      data: (bills) {
        BillModel? initialBill;
        try {
          final matches = bills.where(
            (b) => b.type == 'INITIAL_PAYMENT' && b.status == 'PENDING',
          );
          initialBill = matches.isNotEmpty ? matches.first : null;
        } catch (e, st) {
          debugPrint('Error: $e\n$st');
          initialBill = null;
        }

        if (initialBill == null) return const SizedBox.shrink();

        if (_dueDate != initialBill.dueDate) {
          _dueDate = initialBill.dueDate;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFFFF4B4B), Color(0xFFFF8C00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4B4B).withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Decorative circle
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: CupertinoColors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: CupertinoColors.white.withValues(
                                alpha: 0.2,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              CupertinoIcons.exclamationmark_triangle_fill,
                              color: CupertinoColors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'THANH TOÁN ĐỂ NHẬN PHÒNG',
                                  style: TextStyle(
                                    color: CupertinoColors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                Text(
                                  'Tiền nhà tháng đầu + Tiền cọc',
                                  style: TextStyle(
                                    color: CupertinoColors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Amount
                      Text(
                        _formatCurrency(initialBill.totalAmount ?? 0),
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -1.0,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Timer
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.timer,
                              color: CupertinoColors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isExpired
                                  ? 'ĐÃ QUÁ HẠN'
                                  : 'Còn lại: $_formattedTime',
                              style: const TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Pay Button
                      if (!_isExpired)
                        ScaleTransition(
                          scale: _pulseAnim,
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () =>
                                _showVietQrBottomSheet(context, initialBill!),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: CupertinoColors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      CupertinoIcons.creditcard_fill,
                                      color: Color(0xFFFF4B4B),
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Thanh toán ngay',
                                      style: TextStyle(
                                        color: Color(0xFFFF4B4B),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: CupertinoColors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Text(
                              '⚠️ Phòng đã bị giải phóng do quá hạn',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 13,
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
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showVietQrBottomSheet(BuildContext context, BillModel bill) {
    if (bill.paymentQrUrl == null || bill.paymentQrUrl!.isEmpty) {
      unawaited(
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Chưa có mã QR'),
            content: const Text(
              'Hệ thống chưa tạo mã QR thanh toán cho hóa đơn này. Vui lòng liên hệ chủ nhà.',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Đóng'),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      );
      return;
    }

    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => Container(
          height: MediaQuery.of(ctx).size.height * 0.75,
          decoration: const BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              // Header
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF4B4B), Color(0xFFFF8C00)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      CupertinoIcons.creditcard_fill,
                      color: CupertinoColors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thanh toán khoản khởi tạo',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            _formatCurrency(bill.totalAmount ?? 0),
                            style: const TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Quét mã QR bằng app ngân hàng để thanh toán.\nHóa đơn sẽ được xác nhận tự động.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        bill.paymentQrUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.qrcode,
                              size: 80,
                              color: Color(0xFF9CA3AF),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Không thể tải mã QR',
                              style: TextStyle(color: Color(0xFF9CA3AF)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        color: LiquidGlassColors.tenantAccent,
                        borderRadius: BorderRadius.circular(16),
                        onPressed: () {
                          Navigator.pop(ctx);
                          unawaited(
                            ref.read(billProvider.notifier).refreshBills(),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '✅ Đang kiểm tra giao dịch... Vui lòng chờ!',
                              ),
                              backgroundColor: Color(0xFF059669),
                            ),
                          );
                        },
                        child: const Text(
                          'Đã thanh toán xong',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CupertinoButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Đóng',
                        style: TextStyle(color: Color(0xFF6B7280)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
