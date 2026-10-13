import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ScaffoldMessenger, SnackBar;

import '../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';

class FinancialControlScreen extends ConsumerStatefulWidget {
  const FinancialControlScreen({super.key});

  @override
  ConsumerState<FinancialControlScreen> createState() =>
      _FinancialControlScreenState();
}

class _FinancialControlScreenState
    extends ConsumerState<FinancialControlScreen> {
  int _selectedFilter = 0; // 0: Tất cả, 1: Khoản Thu, 2: Khoản Chi
  final DateTime _selectedDate = DateTime.now();

  final _currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final _dateFmt = DateFormat('dd/MM/yyyy HH:mm');
  final _monthFmt = DateFormat('MM/yyyy');

  final List<Color> _chartColors = [
    CupertinoColors.systemBlue,
    CupertinoColors.systemOrange,
    CupertinoColors.systemPurple,
    CupertinoColors.systemTeal,
    CupertinoColors.systemPink,
  ];

  // Dummy data for financial records
  final List<Map<String, dynamic>> _transactions = [
    {
      'id': 'TX1001',
      'type': 'INCOME',
      'category': 'Thu tiền phòng',
      'title': 'Thu tiền phòng 101 - Tòa A',
      'amount': 4500000,
      'actor': 'Nguyễn Văn A (Khách thuê)',
      'method': 'Chuyển khoản (Techcombank)',
      'date': DateTime.now().subtract(const Duration(hours: 2)),
      'location': 'Phòng 101, Tòa A',
    },
    {
      'id': 'TX1002',
      'type': 'EXPENSE',
      'category': 'Sửa chữa',
      'title': 'Sửa chữa ống nước phòng 205',
      'amount': -350000,
      'actor': 'Trần Văn B (Thợ bảo trì)',
      'method': 'Tiền mặt',
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'location': 'Phòng 205, Tòa A',
    },
    {
      'id': 'TX1003',
      'type': 'INCOME',
      'category': 'Thu tiền cọc',
      'title': 'Thu tiền cọc phòng 302 - Tòa B',
      'amount': 3000000,
      'actor': 'Lê Thị C (Khách thuê)',
      'method': 'Chuyển khoản (Vietcombank)',
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'location': 'Phòng 302, Tòa B',
    },
    {
      'id': 'TX1004',
      'type': 'EXPENSE',
      'category': 'Điện nước',
      'title': 'Thanh toán tiền điện tổng tòa A',
      'amount': -2150000,
      'actor': 'Công ty Điện Lực',
      'method': 'Chuyển khoản (BIDV)',
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'location': 'Tòa A',
    },
    {
      'id': 'TX1005',
      'type': 'INCOME',
      'category': 'Thu tiền phòng',
      'title': 'Thu tiền phòng 102 - Tòa A',
      'amount': 4200000,
      'actor': 'Phạm Văn D (Khách thuê)',
      'method': 'Chuyển khoản (MB Bank)',
      'date': DateTime.now().subtract(const Duration(days: 4)),
      'location': 'Phòng 102, Tòa A',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Tạm tính tổng thu / chi từ dummy data
    // BUGFIX (data): trước đây ép `t['amount'] as int` — nếu amount là
    // double/String (JSON) thì ném TypeError và cả màn hình tài chính
    // không render. Coerce an toàn qua num.
    double amt(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;
    double totalIncome = _transactions
        .where((t) => t['type'] == 'INCOME')
        .fold(0.0, (sum, t) => sum + amt(t['amount']));
    double totalExpense = _transactions
        .where((t) => t['type'] == 'EXPENSE')
        .fold(0.0, (sum, t) => sum + amt(t['amount']).abs());
    double netProfit = totalIncome - totalExpense;

    final filteredTransactions = _transactions.where((t) {
      if (_selectedFilter == 1) return t['type'] == 'INCOME';
      if (_selectedFilter == 2) return t['type'] == 'EXPENSE';
      return true;
    }).toList();

    // Chart Data
    final dataMap = <String, double>{};
    if (_selectedFilter == 1) {
      for (var t in _transactions.where((t) => t['type'] == 'INCOME')) {
        dataMap[t['category']] =
            (dataMap[t['category']] ?? 0) + amt(t['amount']);
      }
    } else if (_selectedFilter == 2) {
      for (var t in _transactions.where((t) => t['type'] == 'EXPENSE')) {
        dataMap[t['category']] =
            (dataMap[t['category']] ?? 0) + amt(t['amount']).abs();
      }
    } else {
      dataMap['Tổng Thu'] = totalIncome;
      dataMap['Tổng Chi'] = totalExpense;
    }

    return LiquidGlassScaffold(
      title: 'Kiểm soát Tài chính',
      child: CustomScrollView(
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 1000));
            },
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kỳ báo cáo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.black,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Month Picker đang phát triển')));
                        },
                        child: GlassContainer(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          borderRadius: 20,
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.calendar,
                                size: 16,
                                color: LiquidGlassColors.ownerAccent,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Tháng ${_monthFmt.format(_selectedDate)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: LiquidGlassColors.ownerAccent,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                CupertinoIcons.chevron_down,
                                size: 12,
                                color: LiquidGlassColors.ownerAccent,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Lợi Nhuận Ròng Thẻ Cấp Độ Premium (Banking Style)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), AppTheme.kTextPrimary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.kTextPrimary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TỔNG LỢI NHUẬN RÒNG',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                            color: AppTheme.kTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currencyFmt.format(netProfit),
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -1,
                            color: CupertinoColors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildKPIStat(
                                'TỔNG THU',
                                totalIncome,
                                CupertinoColors.systemGreen,
                                CupertinoIcons.arrow_down_left,
                                'assets/images/features/auto_rent_collection.png',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: AppTheme.kTextSecondary.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: _buildKPIStat(
                                  'TỔNG CHI',
                                  totalExpense,
                                  CupertinoColors.systemRed,
                                  CupertinoIcons.arrow_up_right,
                                  'assets/images/features/expense_scanner.png',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filter Segmented Control
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoSlidingSegmentedControl<int>(
                      groupValue: _selectedFilter,
                      children: const {
                        0: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'Tổng Quan',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        1: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'Khoản Thu',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        2: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'Khoản Chi',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      },
                      onValueChanged: (val) {
                        if (val != null) setState(() => _selectedFilter = val);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Pie Chart Section
                  if (dataMap.isNotEmpty) ...[
                    GlassContainer(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Phân bổ tỷ trọng',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 200,
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: PieChart(
                                    PieChartData(
                                      sectionsSpace: 4,
                                      centerSpaceRadius: 40,
                                      sections: _buildPieChartSections(dataMap),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: _buildChartLegend(dataMap),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 16),

                  // Title list
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Chi tiết giao dịch',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.black,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {},
                        child: const Row(
                          children: [
                            Icon(
                              CupertinoIcons.doc_text,
                              size: 16,
                              color: LiquidGlassColors.ownerAccent,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Xuất Excel',
                              style: TextStyle(
                                fontSize: 14,
                                color: LiquidGlassColors.ownerAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Transactions List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final t = filteredTransactions[index];
                final isIncome = t['type'] == 'INCOME';
                final amountStr = _currencyFmt.format(t['amount'].abs());

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isIncome
                                ? CupertinoColors.systemGreen.withValues(
                                    alpha: 0.1,
                                  )
                                : CupertinoColors.systemRed.withValues(
                                    alpha: 0.1,
                                  ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isIncome
                                ? CupertinoIcons.arrow_down_left
                                : CupertinoIcons.arrow_up_right,
                            color: isIncome
                                ? CupertinoColors.systemGreen
                                : CupertinoColors.systemRed,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t['title'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                            color: CupertinoColors.black,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.kTextSecondary
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            t['category'] ?? 'Khác',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.kTextSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${isIncome ? '+' : '-'}$amountStr',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: isIncome
                                          ? CupertinoColors.systemGreen
                                          : CupertinoColors.systemRed,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildDetailRow(
                                CupertinoIcons.person_fill,
                                t['actor'],
                                'assets/images/features/ai_roommate.png',
                              ),
                              const SizedBox(height: 4),
                              _buildDetailRow(
                                CupertinoIcons.location_solid,
                                t['location'],
                                'assets/images/features/multi_property.png',
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _dateFmt.format(t['date']),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.kTextSecondary,
                                    ),
                                  ),
                                  Text(
                                    t['method'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4B5563),
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
                );
              }, childCount: filteredTransactions.length),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildKPIStat(
    String label,
    double amount,
    Color color,
    IconData icon, [
    String? imagePath,
  ]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.kTextSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            if (imagePath != null)
              Image.asset(
                imagePath,
                width: 16,
                height: 16,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                isAntiAlias: true,
                errorBuilder: (_, __, ___) =>
                    Icon(icon, size: 14, color: color),
              )
            else
              Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _currencyFmt.format(amount),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String text, [String? imagePath]) {
    return Row(
      children: [
        if (imagePath != null)
          Image.asset(
            imagePath,
            width: 14,
            height: 14,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            isAntiAlias: true,
            errorBuilder: (_, __, ___) =>
                Icon(icon, size: 12, color: AppTheme.kTextMuted),
          )
        else
          Icon(icon, size: 12, color: AppTheme.kTextMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieChartSections(
    Map<String, double> dataMap,
  ) {
    if (dataMap.isEmpty) return [];

    // Default colors for "Tổng Quan"
    if (_selectedFilter == 0) {
      return [
        PieChartSectionData(
          color: CupertinoColors.systemGreen,
          value: dataMap['Tổng Thu'] ?? 0,
          title: '',
          radius: 20,
        ),
        PieChartSectionData(
          color: CupertinoColors.systemRed,
          value: dataMap['Tổng Chi'] ?? 0,
          title: '',
          radius: 20,
        ),
      ];
    }

    final double total = dataMap.values.fold(0, (a, b) => a + b);
    int idx = 0;
    return dataMap.entries.map((e) {
      final isLarge = (e.value / total) > 0.1;
      final color = _chartColors[idx % _chartColors.length];
      idx++;
      return PieChartSectionData(
        color: color,
        value: e.value,
        title: isLarge
            ? '${((e.value / total) * 100).toStringAsFixed(0)}%'
            : '',
        radius: 20,
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.white,
        ),
      );
    }).toList();
  }

  List<Widget> _buildChartLegend(Map<String, double> dataMap) {
    if (dataMap.isEmpty) return [];

    if (_selectedFilter == 0) {
      return [
        _buildLegendItem(
          'Tổng Thu',
          CupertinoColors.systemGreen,
          dataMap['Tổng Thu'] ?? 0,
        ),
        const SizedBox(height: 8),
        _buildLegendItem(
          'Tổng Chi',
          CupertinoColors.systemRed,
          dataMap['Tổng Chi'] ?? 0,
        ),
      ];
    }

    int idx = 0;
    return dataMap.entries.map((e) {
      final color = _chartColors[idx % _chartColors.length];
      idx++;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _buildLegendItem(e.key, color, e.value),
      );
    }).toList();
  }

  Widget _buildLegendItem(String title, Color color, double value) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _currencyFmt.format(value),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
