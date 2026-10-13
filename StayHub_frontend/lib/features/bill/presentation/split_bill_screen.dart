import 'dart:async' show unawaited;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/components/bounce_click.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/toast_utils.dart';
import '../data/models/bill_model.dart';

class SplitBillScreen extends ConsumerStatefulWidget {
  final BillModel bill;

  const SplitBillScreen({super.key, required this.bill});

  @override
  ConsumerState<SplitBillScreen> createState() => _SplitBillScreenState();
}

class _SplitBillScreenState extends ConsumerState<SplitBillScreen> {
  int _numberOfPeople = 2;
  late List<String> _roommateNames;

  final _currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  static const String _defaultBankBin = '970415'; // VietinBank
  static const String _defaultBankAccount = '113366668888';
  static const String _defaultAccountName = 'STAYHUB PROPERTY';

  @override
  void initState() {
    super.initState();
    _roommateNames = List.generate(
      _numberOfPeople,
      (index) => 'Bạn cùng phòng ${index + 1}',
    );
  }

  void _updatePeopleCount(int count) {
    if (count < 1 || count > 10) return;
    HapticFeedback.lightImpact();
    setState(() {
      _numberOfPeople = count;
      if (_roommateNames.length < count) {
        for (int i = _roommateNames.length; i < count; i++) {
          _roommateNames.add('Bạn cùng phòng ${i + 1}');
        }
      } else if (_roommateNames.length > count) {
        _roommateNames = _roommateNames.sublist(0, count);
      }
    });
  }

  void _editRoommateName(int index) {
    HapticFeedback.selectionClick();
    final ctrl = TextEditingController(text: _roommateNames[index]);
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text('Đổi tên Bạn ${index + 1}'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: CupertinoTextField(
              controller: ctrl,
              placeholder: 'Ví dụ: Tuấn, Linh, Nam...',
              autofocus: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Hủy'),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Lưu'),
              onPressed: () {
                final text = ctrl.text.trim();
                if (text.isNotEmpty) {
                  setState(() {
                    _roommateNames[index] = text;
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

  void _copyReminderMessage(double totalAmount, int splitAmount) {
    HapticFeedback.mediumImpact();
    final buffer = StringBuffer();
    buffer.writeln('🏠 [StayHub] NHẮC TIỀN PHÒNG ${widget.bill.periodLabel.toUpperCase()}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('• Tổng tiền cả phòng: ${_currencyFmt.format(totalAmount)}');
    buffer.writeln('• Số người ở ghép: $_numberOfPeople bạn');
    buffer.writeln('• Mỗi bạn cần đóng: ${_currencyFmt.format(splitAmount)}');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📋 Danh sách chia tiền:');
    for (int i = 0; i < _roommateNames.length; i++) {
      buffer.writeln('${i + 1}. ${_roommateNames[i]}: ${_currencyFmt.format(splitAmount)}');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('💳 THÔNG TIN CHUYỂN KHOẢN:');
    buffer.writeln('• Ngân hàng: VietinBank');
    buffer.writeln('• Số tài khoản: $_defaultBankAccount');
    buffer.writeln('• Chủ tài khoản: $_defaultAccountName');
    buffer.writeln('• Nội dung: Thue phong ${widget.bill.month}_${widget.bill.year} [Ten cua ban]');
    buffer.writeln('');
    buffer.writeln('Cả nhà chuyển khoản theo thông tin trên sớm giúp phòng mình nhé! Cảm ơn mọi người ❤️');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ToastUtils.show(
      context,
      'Đã sao chép tin nhắn nhắc tiền trọ! Bạn có thể dán vào Zalo/Messenger.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = widget.bill.totalAmount ?? 0;
    final int splitAmount = _numberOfPeople > 0
        ? (totalAmount / _numberOfPeople).round()
        : totalAmount.toInt();
    final isDark = CupertinoTheme.brightnessOf(context) == Brightness.dark;

    return LiquidGlassScaffold(
      title: 'Chia Tiền Ở Ghép',
      backgroundColors: isDark ? const Color(0xFF0F172A) : AppTheme.kBackgroundLight,
      useScrollView: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHeaderCard(totalAmount, isDark),
                const SizedBox(height: 18),
                _buildPeopleCounterCard(isDark),
                const SizedBox(height: 18),
                _buildSplitAmountHero(splitAmount, isDark),
                const SizedBox(height: 18),
                _buildQuickCopyReminderButton(totalAmount, splitAmount),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'MÃ VIETQR TỪNG BẠN',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      'Chạm để đổi tên',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF69B1FF).withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildRoommateList(splitAmount, isDark),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(double totalAmount, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF69B1FF).withValues(alpha: 0.20),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF69B1FF).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HÓA ĐƠN ${widget.bill.periodLabel.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tổng tiền phòng cần chia',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _currencyFmt.format(totalAmount),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF69B1FF).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.person_3_fill,
              color: Color(0xFF2563EB),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleCounterCard(bool isDark) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Số người ở ghép',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Chia đều số tiền cho từng thành viên',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          Row(
            children: [
              BounceClick(
                scaleFactor: 0.90,
                onPressed: _numberOfPeople > 1
                    ? () => _updatePeopleCount(_numberOfPeople - 1)
                    : null,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _numberOfPeople > 1
                        ? const Color(0xFF69B1FF).withValues(alpha: 0.15)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    CupertinoIcons.minus,
                    size: 18,
                    color: _numberOfPeople > 1
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),
              Container(
                width: 44,
                alignment: Alignment.center,
                child: Text(
                  '$_numberOfPeople',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              BounceClick(
                scaleFactor: 0.90,
                onPressed: _numberOfPeople < 10
                    ? () => _updatePeopleCount(_numberOfPeople + 1)
                    : null,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _numberOfPeople < 10
                        ? const Color(0xFF69B1FF).withValues(alpha: 0.15)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    CupertinoIcons.plus,
                    size: 18,
                    color: _numberOfPeople < 10
                        ? const Color(0xFF2563EB)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSplitAmountHero(int splitAmount, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF38BDF8),
            Color(0xFF2563EB),
            Color(0xFF1D4ED8),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'CHIA CHO $_numberOfPeople THÀNH VIÊN',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Mỗi Bạn Cần Đóng',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _currencyFmt.format(splitAmount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCopyReminderButton(double totalAmount, int splitAmount) {
    return BounceClick(
      scaleFactor: 0.96,
      onPressed: () => _copyReminderMessage(totalAmount, splitAmount),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: const Color(0xFF69B1FF).withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF69B1FF).withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.doc_on_clipboard_fill,
              size: 18,
              color: Color(0xFF2563EB),
            ),
            SizedBox(width: 8),
            Text(
              'Sao chép tin nhắn nhắc tiền (Gửi Zalo/Nhóm)',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoommateList(int splitAmount, bool isDark) {
    return Column(
      children: List.generate(_numberOfPeople, (index) {
        final name = _roommateNames[index];
        final addInfo = Uri.encodeComponent(
          'Thue phong T${widget.bill.month}_${widget.bill.year} $name',
        );
        final qrUrl =
            'https://img.vietqr.io/image/$_defaultBankBin-$_defaultBankAccount-compact2.png?amount=$splitAmount&addInfo=$addInfo&accountName=${Uri.encodeComponent(_defaultAccountName)}';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar số thứ tự
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF69B1FF), Color(0xFF2563EB)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Tên và số tiền
                Expanded(
                  child: BounceClick(
                    scaleFactor: 0.98,
                    onPressed: () => _editRoommateName(index),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(
                              CupertinoIcons.pencil,
                              size: 13,
                              color: Color(0xFF64748B),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _currencyFmt.format(splitAmount),
                          style: const TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Nút mở VietQR
                BounceClick(
                  scaleFactor: 0.92,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _showQrPopup(name, splitAmount, qrUrl);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF69B1FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(
                        color: const Color(0xFF69B1FF).withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.qrcode,
                          size: 15,
                          color: Color(0xFF2563EB),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Mã QR',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  void _showQrPopup(String personName, int amount, String qrUrl) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text('Mã VietQR - $personName'),
          content: Padding(
            padding: const EdgeInsets.only(top: 14.0),
            child: Column(
              children: [
                Text(
                  _currencyFmt.format(amount),
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      qrUrl,
                      width: 210,
                      height: 210,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const SizedBox(
                          width: 210,
                          height: 210,
                          child: Center(
                            child: CupertinoActivityIndicator(radius: 12),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          CupertinoIcons.qrcode,
                          size: 80,
                          color: Color(0xFF0B192C),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Mở ứng dụng Ngân hàng bất kỳ để quét mã chuyển tiền',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Sao chép STK'),
              onPressed: () {
                Clipboard.setData(
                  const ClipboardData(text: _defaultBankAccount),
                );
                Navigator.pop(ctx);
                ToastUtils.show(context, 'Đã sao chép STK: $_defaultBankAccount');
              },
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Đóng'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}
