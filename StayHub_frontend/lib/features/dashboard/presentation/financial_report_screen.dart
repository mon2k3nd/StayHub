import 'package:flutter/cupertino.dart';

import '../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../../bill/application/bill_notifier.dart';
import '../../branch/application/branch_notifier.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:async' show unawaited;

class FinancialReportScreen extends ConsumerStatefulWidget {
  const FinancialReportScreen({super.key});

  @override
  ConsumerState<FinancialReportScreen> createState() =>
      _FinancialReportScreenState();
}

class Transaction {
  final String id;
  final String type; // 'INCOME' or 'EXPENSE'
  final String title;
  final double amount;
  final DateTime date;
  final String person; // Who paid/collected
  final String location; // Branch/Room
  final String method; // CASH, TRANSFER

  Transaction({
    required this.id,
    required this.type,
    required this.title,
    required this.amount,
    required this.date,
    required this.person,
    required this.location,
    required this.method,
  });
}

class _FinancialReportScreenState extends ConsumerState<FinancialReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String _selectedPeriod = 'Tháng này'; // Tháng này, Tháng trước, Quý này
  final dateFormat = DateFormat('dd/MM/yyyy');
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  bool _isExporting = false;

  Future<void> _exportReport() async {
    setState(() => _isExporting = true);

    try {
      final doc = pw.Document();
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'StayHub',
                    style: const pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    'BÁO CÁO TÀI CHÍNH',
                    style: const pw.TextStyle(fontSize: 20),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Giai đoạn: ${dateFormat.format(_startDate)} - ${dateFormat.format(_endDate)}',
                  ),
                  pw.SizedBox(height: 40),
                  pw.Text('Được tạo tự động từ Hệ thống Quản lý StayHub.'),
                ],
              ),
            );
          },
        ),
      );

      final pdfBytes = await doc.save();
      await Printing.sharePdf(bytes: pdfBytes, filename: 'stayhub_report.pdf');
    } catch (e) {
      if (mounted) {
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Lỗi'),
              content: Text(e.toString()),
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
      if (mounted) setState(() => _isExporting = false);
    }
  }

  final List<Transaction> _mockExpenses = [
    Transaction(
      id: 'E1',
      type: 'EXPENSE',
      title: 'Sửa điện',
      amount: 500000,
      date: DateTime.now().subtract(const Duration(days: 2)),
      person: 'Thợ điện Quân',
      location: 'Dãy A',
      method: 'TRANSFER',
    ),
    Transaction(
      id: 'E2',
      type: 'EXPENSE',
      title: 'Bảo trì nước',
      amount: 1200000,
      date: DateTime.now().subtract(const Duration(days: 5)),
      person: 'Công ty Môi trường',
      location: 'Tất cả',
      method: 'TRANSFER',
    ),
    Transaction(
      id: 'E3',
      type: 'EXPENSE',
      title: 'Mua vật tư',
      amount: 350000,
      date: DateTime.now().subtract(const Duration(days: 10)),
      person: 'Nhân viên Hùng',
      location: 'Kho',
      method: 'CASH',
    ),
  ];

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: LiquidGlassColors.tenantAccent,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate.add(const Duration(days: 30));
          }
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate.subtract(const Duration(days: 30));
          }
        }
        _selectedPeriod = 'Tùy chỉnh';
      });
    }
  }

  void _setPeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      final now = DateTime.now();
      if (period == 'Tháng này') {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = DateTime(now.year, now.month + 1, 0);
      } else if (period == 'Tháng trước') {
        _startDate = DateTime(now.year, now.month - 1, 1);
        _endDate = DateTime(now.year, now.month, 0);
      } else if (period == 'Quý này') {
        final quarterMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        _startDate = DateTime(now.year, quarterMonth, 1);
        _endDate = DateTime(now.year, quarterMonth + 3, 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final branchesState = ref.watch(branchProvider);
    final billsState = ref.watch(billProvider);

    List<Transaction> allTransactions = [];

    // Parse bills to INCOME transactions
    if (billsState.value != null) {
      for (var bill in billsState.value!) {
        allTransactions.add(
          Transaction(
            id: 'B${bill.id}',
            type: 'INCOME',
            title: 'Thu tiền phòng ${bill.month}/${bill.year}',
            amount: bill.totalAmount ?? 0.0,
            date: bill.createdAt,
            person: 'Khách thuê', // Ideally we get from contract
            location: 'Phòng ${bill.roomId}', // Ideally branch + room
            method: bill.isPaid ? 'TRANSFER' : 'UNPAID',
          ),
        );
      }
    }

    allTransactions.addAll(_mockExpenses);

    // Filter by Date
    allTransactions = allTransactions
        .where(
          (t) =>
              t.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
              t.date.isBefore(_endDate.add(const Duration(days: 1))),
        )
        .toList();

    allTransactions.sort((a, b) => b.date.compareTo(a.date));

    double totalIncome = allTransactions
        .where((t) => t.type == 'INCOME' && t.method != 'UNPAID')
        .fold(0, (sum, item) => sum + item.amount);
    double totalExpense = allTransactions
        .where((t) => t.type == 'EXPENSE')
        .fold(0, (sum, item) => sum + item.amount);
    double netIncome = totalIncome - totalExpense;

    return LiquidGlassScaffold(
      title: 'TT Kiểm soát Tài chính',
      useScrollView: false,
      trailing: _isExporting
          ? const CupertinoActivityIndicator()
          : CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _exportReport(),
              child: const Icon(CupertinoIcons.square_arrow_down, size: 24),
            ),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 500));
            },
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildFilters(branchesState),
                  const SizedBox(height: 16),
                  _buildSummaryCards(totalIncome, totalExpense, netIncome),
                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Text(
                        'Lịch sử giao dịch',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final t = allTransactions[index];
                return _buildTransactionCard(t);
              }, childCount: allTransactions.length),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  Widget _buildFilters(AsyncValue branchesState) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Tháng này', 'Tháng trước', 'Quý này'].map((p) {
                final isSelected = _selectedPeriod == p;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: isSelected
                        ? LiquidGlassColors.tenantAccent
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    onPressed: () => _setPeriod(p),
                    child: Text(
                      p,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateSelector(
                  label: 'Từ ngày',
                  date: _startDate,
                  onTap: () => _selectDate(context, true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateSelector(
                  label: 'Đến ngày',
                  date: _endDate,
                  onTap: () => _selectDate(context, false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(double income, double expense, double net) {
    return Row(
      children: [
        Expanded(
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            color: CupertinoColors.systemGreen.withValues(alpha: 0.15),
            child: Column(
              children: [
                const Icon(
                  CupertinoIcons.arrow_down_right_circle_fill,
                  color: CupertinoColors.systemGreen,
                  size: 28,
                ),
                const SizedBox(height: 8),
                const Text(
                  'TỔNG THU',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormat.format(income),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassContainer(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            color: CupertinoColors.systemRed.withValues(alpha: 0.15),
            child: Column(
              children: [
                const Icon(
                  CupertinoIcons.arrow_up_right_circle_fill,
                  color: CupertinoColors.systemRed,
                  size: 28,
                ),
                const SizedBox(height: 8),
                const Text(
                  'TỔNG CHI',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormat.format(expense),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(Transaction t) {
    final isIncome = t.type == 'INCOME';
    final isUnpaid = t.method == 'UNPAID';
    final color = isUnpaid
        ? CupertinoColors.systemOrange
        : (isIncome ? CupertinoColors.systemGreen : CupertinoColors.systemRed);
    final icon = isIncome
        ? CupertinoIcons.add_circled_solid
        : CupertinoIcons.minus_circle_fill;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          t.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${isIncome ? '+' : '-'}${currencyFormat.format(t.amount)}',
                        style: TextStyle(
                          color: color,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.person_fill,
                        color: Colors.white54,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        t.person,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        CupertinoIcons.location_solid,
                        color: Colors.white54,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        t.location,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        dateFormat.format(t.date),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isUnpaid
                              ? CupertinoColors.systemOrange.withValues(
                                  alpha: 0.2,
                                )
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isUnpaid
                              ? 'CHƯA THANH TOÁN'
                              : (t.method == 'TRANSFER'
                                    ? 'CHUYỂN KHOẢN'
                                    : 'TIỀN MẶT'),
                          style: TextStyle(
                            color: isUnpaid
                                ? CupertinoColors.systemOrange
                                : Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
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
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 6),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormat.format(date),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.calendar,
                    color: Colors.white70,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
