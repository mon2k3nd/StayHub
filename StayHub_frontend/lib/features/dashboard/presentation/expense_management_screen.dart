import 'package:flutter/cupertino.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/core_providers.dart';
import '../../auth/application/auth_notifier.dart';
import '../../staff/application/staff_assignment_notifier.dart';
import 'dart:async' show unawaited;

// ──────────────────────────────────────────────
// Model
// ──────────────────────────────────────────────
class ExpenseModel {
  final int? id;
  final int ownerId;
  final int? branchId;
  final String category;
  final String description;
  final double amount;
  final String expenseDate; // yyyy-MM-dd
  final String? receiptImage;

  ExpenseModel({
    this.id,
    required this.ownerId,
    this.branchId,
    required this.category,
    required this.description,
    required this.amount,
    required this.expenseDate,
    this.receiptImage,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) => ExpenseModel(
    id: json['id'],
    ownerId: json['ownerId'],
    branchId: json['branchId'],
    category: json['category'] ?? 'OTHER',
    description: json['description'] ?? '',
    amount: (json['amount'] ?? 0).toDouble(),
    expenseDate: json['expenseDate'] ?? '',
    receiptImage: json['receiptImage'],
  );

  Map<String, dynamic> toJson() => {
    'ownerId': ownerId,
    if (branchId != null) 'branchId': branchId,
    'category': category,
    'description': description,
    'amount': amount,
    'expenseDate': expenseDate,
  };
}

// ──────────────────────────────────────────────
// Provider
// ──────────────────────────────────────────────
final expenseListProvider = FutureProvider.family<List<ExpenseModel>, int>((
  ref,
  ownerId,
) async {
  final api = ref.read(apiClientProvider);
  final res = await api.dio.get('/v1/expenses/owner/$ownerId');
  // BUGFIX (data): tránh `as List<dynamic>` ném TypeError khi `data`
  // null/không phải List.
  final raw = res.data is Map ? res.data['data'] : null;
  final data = raw is List ? raw : const <dynamic>[];
  return data
      .whereType<Map>()
      .map((e) => ExpenseModel.fromJson(Map<String, dynamic>.from(e)))
      .toList();
});

typedef ProfitParams = ({int ownerId, int month, int year});

final profitReportProvider =
    FutureProvider.family<Map<String, dynamic>, ProfitParams>((
      ref,
      params,
    ) async {
      final api = ref.read(apiClientProvider);
      final res = await api.dio.get(
        '/v1/expenses/owner/${params.ownerId}/profit-report',
        queryParameters: {'month': params.month, 'year': params.year},
      );
      return Map<String, dynamic>.from(res.data['data'] ?? {});
    });

// ──────────────────────────────────────────────
// Screen
// ──────────────────────────────────────────────
class ExpenseManagementScreen extends ConsumerStatefulWidget {
  const ExpenseManagementScreen({super.key});

  @override
  ConsumerState<ExpenseManagementScreen> createState() =>
      _ExpenseManagementScreenState();
}

class _ExpenseManagementScreenState
    extends ConsumerState<ExpenseManagementScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  int _selectedTabIndex = 0; // 0: Tổng quan, 1: Giao dịch
  bool _isLoading = false;

  final _currencyFmt = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  int get _ownerId {
    final user = ref.read(authProvider).value;
    if (user?.role == 'STAFF') {
      final assignments = ref.read(staffAssignmentProvider).assignments;
      return assignments.isNotEmpty ? assignments.first.ownerId : 0;
    }
    return user?.id ?? 0;
  }

  Future<void> _showAddExpenseDialog({ExpenseModel? existing}) async {
    final categories = [
      'SALARY',
      'REPAIR',
      'ELECTRICITY',
      'WATER',
      'WIFI',
      'TRASH',
      'TAX',
      'OTHER',
    ];
    final catLabels = {
      'SALARY': 'Lương nhân viên',
      'REPAIR': 'Sửa chữa',
      'ELECTRICITY': 'Tiền điện',
      'WATER': 'Tiền nước',
      'WIFI': 'Internet/Wifi',
      'TRASH': 'Thu gom rác',
      'TAX': 'Thuế & Phí',
      'OTHER': 'Khác',
    };
    String selectedCat = existing?.category ?? 'OTHER';
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final amountCtrl = TextEditingController(
      text: existing != null ? existing.amount.toStringAsFixed(0) : '',
    );
    DateTime selectedDate = existing != null
        ? DateTime.parse(existing.expenseDate)
        : DateTime.now();

    await showCupertinoDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => CupertinoAlertDialog(
          title: Text(
            existing == null ? 'Thêm Chi Phí' : 'Cập Nhật Chi Phí',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          content: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              children: [
                // Category Selector
                GestureDetector(
                  onTap: () async {
                    await showCupertinoModalPopup(
                      context: ctx,
                      builder: (_) => Container(
                        height: 250,
                        color: AppTheme.kBackgroundLight,
                        child: CupertinoPicker(
                          itemExtent: 40,
                          scrollController: FixedExtentScrollController(
                            initialItem: categories.indexOf(selectedCat),
                          ),
                          onSelectedItemChanged: (i) =>
                              setDlgState(() => selectedCat = categories[i]),
                          children: categories
                              .map(
                                (c) => Center(child: Text(catLabels[c] ?? c)),
                              )
                              .toList(),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          catLabels[selectedCat] ?? selectedCat,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppTheme.kTextPrimary,
                          ),
                        ),
                        const Icon(
                          CupertinoIcons.chevron_down,
                          size: 16,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                CupertinoTextField(
                  controller: descCtrl,
                  placeholder: 'Mô tả chi tiết',
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                ),
                const SizedBox(height: 12),
                CupertinoTextField(
                  controller: amountCtrl,
                  placeholder: 'Số tiền (VNĐ)',
                  keyboardType: TextInputType.number,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    await showCupertinoModalPopup(
                      context: ctx,
                      builder: (_) => Container(
                        height: 250,
                        color: AppTheme.kBackgroundLight,
                        child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.date,
                          initialDateTime: selectedDate,
                          maximumDate: DateTime.now(),
                          onDateTimeChanged: (d) =>
                              setDlgState(() => selectedDate = d),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.calendar,
                          size: 18,
                          color: AppTheme.kBrand,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd/MM/yyyy').format(selectedDate),
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppTheme.kTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Hủy'),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              child: const Text(
                'Lưu',
                style: TextStyle(
                  color: AppTheme.kBrand,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                try {
                  final api = ref.read(apiClientProvider);
                  final payload = {
                    'ownerId': _ownerId,
                    'category': selectedCat,
                    'description': descCtrl.text,
                    'amount': double.tryParse(amountCtrl.text) ?? 0,
                    'expenseDate': DateFormat(
                      'yyyy-MM-dd',
                    ).format(selectedDate),
                  };
                  if (existing == null) {
                    await api.dio.post('/v1/expenses', data: payload);
                  } else {
                    await api.dio.put(
                      '/v1/expenses/${existing.id}',
                      data: payload,
                    );
                  }
                  ref.invalidate(expenseListProvider(_ownerId));
                  ref.invalidate(profitReportProvider);
                } catch (e) {
                  debugPrint('Error saving expense: $e');
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteExpense(ExpenseModel e) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Xóa chi phí?'),
        content: Text('Bạn có chắc muốn xóa khoản chi "${e.description}"?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Hủy'),
            onPressed: () => Navigator.pop(ctx, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Xóa'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.delete('/v1/expenses/${e.id}');
      ref.invalidate(expenseListProvider(_ownerId));
      ref.invalidate(profitReportProvider);
    } catch (e) {
      debugPrint('Error deleting expense: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF2F8FF), // Soft blue pale
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Colors.transparent,
        border: null,
        middle: Text(
          'Thu Chi & Lợi Nhuận',
          style: TextStyle(
            color: AppTheme.kTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      child: Stack(
        children: [
          // Background Gradient
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.kBrand.withValues(alpha: 0.15),
                    const Color(0xFFF2F8FF).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Tab Selection & Month Picker
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: CupertinoSlidingSegmentedControl<int>(
                            groupValue: _selectedTabIndex,
                            backgroundColor: Colors.transparent,
                            thumbColor: Colors.white,
                            children: {
                              0: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Text(
                                  'Tổng quan',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: _selectedTabIndex == 0
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: _selectedTabIndex == 0
                                        ? AppTheme.kBrandDeep
                                        : AppTheme.kTextSecondary,
                                  ),
                                ),
                              ),
                              1: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Text(
                                  'Giao dịch',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: _selectedTabIndex == 1
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: _selectedTabIndex == 1
                                        ? AppTheme.kBrandDeep
                                        : AppTheme.kTextSecondary,
                                  ),
                                ),
                              ),
                            },
                            onValueChanged: (v) {
                              if (v != null) {
                                setState(() => _selectedTabIndex = v);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _showMonthPicker(),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.kBrand.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                CupertinoIcons.calendar,
                                size: 18,
                                color: AppTheme.kBrand,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'T$_selectedMonth/$_selectedYear',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.kTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Content Area
                Expanded(
                  child: _selectedTabIndex == 0
                      ? _buildOverviewTab()
                      : _buildTransactionsTab(),
                ),
              ],
            ),
          ),

          // Floating Action Button for adding expense
          Positioned(
            bottom: 24,
            right: 20,
            child: GestureDetector(
              onTap: () => _showAddExpenseDialog(),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.kBrandLight, AppTheme.kBrandDeep],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.kBrand.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.add,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),

          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.white.withValues(alpha: 0.5),
                child: const Center(
                  child: CupertinoActivityIndicator(radius: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showMonthPicker() {
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (_) => Container(
          height: 250,
          color: AppTheme.kBackgroundLight,
          child: Row(
            children: [
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 40,
                  scrollController: FixedExtentScrollController(
                    initialItem: _selectedMonth - 1,
                  ),
                  onSelectedItemChanged: (i) =>
                      setState(() => _selectedMonth = i + 1),
                  children: List.generate(
                    12,
                    (i) => Center(
                      child: Text(
                        'Tháng ${i + 1}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 40,
                  scrollController: FixedExtentScrollController(
                    initialItem: _selectedYear - 2020,
                  ),
                  onSelectedItemChanged: (i) =>
                      setState(() => _selectedYear = 2020 + i),
                  children: List.generate(
                    10,
                    (i) => Center(
                      child: Text(
                        '${2020 + i}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final profitAsync = ref.watch(
      profitReportProvider((
        ownerId: _ownerId,
        month: _selectedMonth,
        year: _selectedYear,
      )),
    );

    return profitAsync.when(
      data: (data) {
        final revenue = (data['totalRevenue'] ?? 0).toDouble();
        final expense = (data['totalExpense'] ?? 0).toDouble();
        final profit = (data['netProfit'] ?? 0).toDouble();

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profit Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.kBrandDeep, AppTheme.kBrand],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.kBrand.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'LỢI NHUẬN THUẦN',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currencyFmt.format(profit),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _buildSubStatCard(
                          'Tổng Thu',
                          revenue,
                          AppTheme.kSuccess,
                          CupertinoIcons.arrow_down_left_circle_fill,
                          'assets/images/features/auto_rent_collection.png',
                        ),
                        const SizedBox(width: 12),
                        _buildSubStatCard(
                          'Tổng Chi',
                          expense,
                          AppTheme.kError,
                          CupertinoIcons.arrow_up_right_circle_fill,
                          'assets/images/features/expense_scanner.png',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'PHÂN TÍCH CHI PHÍ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.kTextSecondary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),

              // Mock Pie Chart Area
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.kBrand.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (expense == 0)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          'Chưa có dữ liệu chi phí tháng này',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                        ),
                      )
                    else
                      Column(
                        children: [
                          Container(
                            height: 200,
                            alignment: Alignment.center,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Simple visual representation of a chart since fl_chart isn't imported yet
                                Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.kBrand.withValues(
                                        alpha: 0.2,
                                      ),
                                      width: 30,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 160,
                                  height: 160,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border(
                                      left: BorderSide(
                                        color: AppTheme.kWarning,
                                        width: 30,
                                      ),
                                      top: BorderSide(
                                        color: AppTheme.kError,
                                        width: 30,
                                      ),
                                    ),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Tổng',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.kTextSecondary,
                                      ),
                                    ),
                                    Text(
                                      _currencyFmt.format(expense),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.kTextPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Legend
                          _buildLegendRow('Sửa chữa', AppTheme.kError, '45%'),
                          _buildLegendRow(
                            'Điện nước',
                            AppTheme.kWarning,
                            '30%',
                          ),
                          _buildLegendRow('Khác', AppTheme.kBrand, '25%'),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, _) => Center(
        child: Text(
          'Lỗi tải dữ liệu: $e',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildSubStatCard(
    String label,
    double value,
    Color iconColor,
    IconData icon, [
    String? imagePath,
  ]) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (imagePath != null)
                  Image.asset(
                    imagePath,
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    isAntiAlias: true,
                    errorBuilder: (_, __, ___) =>
                        Icon(icon, color: iconColor, size: 16),
                  )
                else
                  Icon(icon, color: iconColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _currencyFmt.format(value),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendRow(String title, Color color, String percent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            percent,
            style: const TextStyle(
              color: AppTheme.kTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    final expensesAsync = ref.watch(expenseListProvider(_ownerId));

    return expensesAsync.when(
      data: (expenses) {
        // Filter by selected month/year locally if API returns all
        final filtered = expenses.where((e) {
          final d = DateTime.parse(e.expenseDate);
          return d.month == _selectedMonth && d.year == _selectedYear;
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.kBrand.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.doc_text_search,
                    color: AppTheme.kBrand,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chưa có khoản chi nào',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.kTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ghi chép chi phí để theo dõi\nlợi nhuận chính xác hơn',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.kTextSecondary,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final e = filtered[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.kBrand.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CupertinoListTile(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                leadingSize: 44,
                leading: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Image.asset(
                      _categoryAsset(e.category),
                      width: 30,
                      height: 30,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (_, __, ___) => Icon(
                        _categoryIcon(e.category),
                        color: _categoryColor(e.category),
                        size: 22,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  e.description.isNotEmpty
                      ? e.description
                      : _categoryLabel(e.category),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppTheme.kTextPrimary,
                  ),
                ),
                subtitle: Text(
                  '${_categoryLabel(e.category)} • ${DateFormat('dd/MM').format(DateTime.parse(e.expenseDate))}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.kTextSecondary,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '-${_currencyFmt.format(e.amount)}',
                      style: const TextStyle(
                        color: AppTheme.kError,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _showExpenseOptions(e),
                      child: const Icon(
                        CupertinoIcons.ellipsis_vertical,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
    );
  }

  void _showExpenseOptions(ExpenseModel e) {
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: Text(
            e.description,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          actions: [
            CupertinoActionSheetAction(
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.pencil, size: 20, color: AppTheme.kBrand),
                  SizedBox(width: 8),
                  Text('Sửa', style: TextStyle(color: AppTheme.kBrand)),
                ],
              ),
              onPressed: () {
                Navigator.pop(ctx);
                unawaited(_showAddExpenseDialog(existing: e));
              },
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.trash, size: 20),
                  SizedBox(width: 8),
                  Text('Xóa'),
                ],
              ),
              onPressed: () {
                Navigator.pop(ctx);
                unawaited(_deleteExpense(e));
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            child: const Text('Đóng'),
            onPressed: () => Navigator.pop(ctx),
          ),
        ),
      ),
    );
  }

  String _categoryAsset(String cat) {
    switch (cat) {
      case 'SALARY':
        return 'assets/images/features/ai_roommate.png';
      case 'REPAIR':
        return 'assets/images/features/video_maintenance.png';
      case 'ELECTRICITY':
        return 'assets/images/features/ocr_meter.png';
      case 'WATER':
        return 'assets/images/features/utilities_dashboard.png';
      case 'WIFI':
        return 'assets/images/features/iot_management.png';
      case 'TRASH':
        return 'assets/images/features/local_services.png';
      case 'TAX':
        return 'assets/images/features/tax_helper.png';
      default:
        return 'assets/images/features/one_tap_payment.png';
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'SALARY':
        return CupertinoIcons.person_2_fill;
      case 'REPAIR':
        return CupertinoIcons.wrench_fill;
      case 'ELECTRICITY':
        return CupertinoIcons.bolt_fill;
      case 'WATER':
        return CupertinoIcons.drop_fill;
      case 'WIFI':
        return CupertinoIcons.wifi;
      case 'TRASH':
        return CupertinoIcons.trash_fill;
      case 'TAX':
        return CupertinoIcons.doc_fill;
      default:
        return CupertinoIcons.money_dollar_circle_fill;
    }
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'SALARY':
        return const Color(0xFF8B5CF6);
      case 'REPAIR':
        return AppTheme.kError;
      case 'ELECTRICITY':
        return AppTheme.kWarning;
      case 'WATER':
        return const Color(0xFF3B82F6);
      case 'WIFI':
        return AppTheme.kSuccess;
      default:
        return AppTheme.kTextSecondary;
    }
  }

  String _categoryLabel(String cat) {
    const labels = {
      'SALARY': 'Lương NV',
      'REPAIR': 'Sửa chữa',
      'ELECTRICITY': 'Điện tổng',
      'WATER': 'Nước tổng',
      'WIFI': 'Wifi',
      'TRASH': 'Rác',
      'TAX': 'Thuế',
      'OTHER': 'Khác',
    };
    return labels[cat] ?? cat;
  }
}
