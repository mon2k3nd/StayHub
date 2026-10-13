import 'package:flutter/cupertino.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/glass_button.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/theme/app_theme.dart';
import 'dart:async' show unawaited;

class AdminPaymentConfigScreen extends StatefulWidget {
  const AdminPaymentConfigScreen({super.key});

  @override
  State<AdminPaymentConfigScreen> createState() =>
      _AdminPaymentConfigScreenState();
}

class _AdminPaymentConfigScreenState extends State<AdminPaymentConfigScreen> {
  int _selectedTab = 0;
  double _commission = 1.5;
  bool _momoEnabled = true;
  bool _vnpayEnabled = false;

  final List<Map<String, dynamic>> _transactions = [
    {
      'id': '#TXN-98231',
      'owner': 'Nguyễn Văn A',
      'amount': '+1,500,000 đ',
      'type': 'Gia hạn Gói PRO',
      'time': '10:30 Hôm nay',
      'status': 'SUCCESS',
    },
    {
      'id': '#TXN-98230',
      'owner': 'Trần Thị B',
      'amount': '+500,000 đ',
      'type': 'Mua Gói BASIC',
      'time': '09:15 Hôm nay',
      'status': 'SUCCESS',
    },
    {
      'id': '#TXN-98229',
      'owner': 'Lê Văn C',
      'amount': '3,000,000 đ',
      'type': 'Thanh toán phí HH',
      'time': 'Hôm qua',
      'status': 'FAILED',
    },
    {
      'id': '#TXN-98228',
      'owner': 'Phạm Thị D',
      'amount': '+12,000,000 đ',
      'type': 'Gói ENTERPRISE (1 năm)',
      'time': 'Hôm qua',
      'status': 'SUCCESS',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      title: 'Trung tâm Tài chính',
      backgroundColors: AppTheme.kBackgroundLight,
      useScrollView: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: _selectedTab,
              children: const {
                0: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Cấu hình Gateways'),
                ),
                1: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Lịch sử Dòng tiền'),
                ),
              },
              onValueChanged: (v) {
                if (v != null) setState(() => _selectedTab = v);
              },
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _selectedTab == 0
                  ? _buildConfigTab()
                  : _buildTransactionsTab(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'CẤU HÌNH API NỀN TẢNG',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 12),
        GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA50064).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.money_dollar,
                      color: Color(0xFFA50064),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'MoMo API',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: CupertinoColors.black,
                    ),
                  ),
                  const Spacer(),
                  CupertinoSwitch(
                    value: _momoEnabled,
                    activeTrackColor: const Color(0xFFA50064),
                    onChanged: (v) => setState(() => _momoEnabled = v),
                  ),
                ],
              ),
              if (_momoEnabled) ...[
                const SizedBox(height: 16),
                const Text(
                  'Partner Code',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.black,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                const CupertinoTextField(
                  placeholder: 'MOMOVN2026',
                  padding: EdgeInsets.all(10),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Secret Key',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.black,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                const CupertinoTextField(
                  placeholder: '********************',
                  obscureText: true,
                  padding: EdgeInsets.all(10),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CupertinoColors.activeBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      CupertinoIcons.creditcard,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'VNPay API',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: CupertinoColors.black,
                    ),
                  ),
                  const Spacer(),
                  CupertinoSwitch(
                    value: _vnpayEnabled,
                    activeTrackColor: CupertinoColors.activeBlue,
                    onChanged: (v) => setState(() => _vnpayEnabled = v),
                  ),
                ],
              ),
              if (_vnpayEnabled) ...[
                const SizedBox(height: 16),
                const Text(
                  'Terminal ID',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.black,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                const CupertinoTextField(
                  placeholder: 'VNPAY123',
                  padding: EdgeInsets.all(10),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'CẤU HÌNH PHÍ NỀN TẢNG (COMMISSION)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 12),
        GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Phí xử lý giao dịch (%)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.black,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.activeGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_commission.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.activeGreen,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CupertinoSlider(
                value: _commission,
                min: 0.0,
                max: 10.0,
                divisions: 100,
                activeColor: CupertinoColors.activeGreen,
                onChanged: (v) {
                  setState(() => _commission = v);
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Mức phí này sẽ tự động thu khi Khách hàng thanh toán tiền nhà cho Chủ trọ qua nền tảng StayHub.',
                style: TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        GlassButton(
          text: 'Lưu Cấu Hình',
          color: CupertinoColors.activeBlue,
          onPressed: () {
            unawaited(
              showCupertinoDialog(
                context: context,
                builder: (c) => CupertinoAlertDialog(
                  title: const Text('Thành công'),
                  content: const Text(
                    'Đã cập nhật cấu hình cổng thanh toán và phí.',
                  ),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('OK'),
                      onPressed: () => Navigator.pop(c),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildTransactionsTab() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final tx = _transactions[index];
        final isSuccess = tx['status'] == 'SUCCESS';
        final statusColor = isSuccess
            ? CupertinoColors.activeGreen
            : CupertinoColors.destructiveRed;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSuccess
                        ? CupertinoIcons.arrow_down_right
                        : CupertinoIcons.xmark_circle,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx['type'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: CupertinoColors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${tx['owner']} • ${tx['id']}',
                        style: const TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      tx['amount'],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tx['time'],
                      style: const TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
