import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/utils/toast_utils.dart';
import '../../bill/application/bill_notifier.dart';
import '../application/dashboard_notifier.dart';
import '../../branch/application/branch_notifier.dart';
import '../../room/application/room_notifier.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/components/liquid_glass_loader.dart';
import 'widgets/financial_chart_widget.dart';
import 'dart:async' show unawaited;

// Mock Transaction for Finance
class Transaction {
  final String id;
  final String title;
  final double amount;
  final String type; // INCOME / EXPENSE
  final DateTime date;
  final String person;
  final String location;
  final String method; // TRANSFER, CASH, UNPAID

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    required this.person,
    required this.location,
    required this.method,
  });
}

class OwnerControlCenterScreen extends ConsumerStatefulWidget {
  const OwnerControlCenterScreen({super.key});

  @override
  ConsumerState<OwnerControlCenterScreen> createState() =>
      _OwnerControlCenterScreenState();
}

class _OwnerControlCenterScreenState
    extends ConsumerState<OwnerControlCenterScreen> {
  int _selectedTab = 0; // 0: Finance, 1: Subscription, 2: Add-ons

  // Finance variables
  String _selectedPeriod = 'Tháng này';
  late DateTime _startDate;
  late DateTime _endDate;
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final dateFormat = DateFormat('dd/MM/yyyy');

  final List<Transaction> _expenses = [];

  @override
  void initState() {
    super.initState();
    _setPeriod('Tháng này');
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
        final currentQuarter = ((now.month - 1) / 3).floor() + 1;
        _startDate = DateTime(now.year, (currentQuarter - 1) * 3 + 1, 1);
        _endDate = DateTime(now.year, currentQuarter * 3 + 1, 0);
      } else if (period == 'Năm nay') {
        _startDate = DateTime(now.year, 1, 1);
        _endDate = DateTime(now.year, 12, 31);
      }
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: CupertinoColors.systemBlue,
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
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
        } else {
          _endDate = picked;
        }
        _selectedPeriod = 'Tùy chỉnh';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      title: 'Trung tâm Quản trị',
      useScrollView: false,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<int>(
                  groupValue: _selectedTab,
                  backgroundColor: AppTheme.kAccentColor.withValues(alpha: 0.1),
                  thumbColor: AppTheme.kAccentColor,
                  children: {
                    0: _buildSegment('Cần xử lý', 0),
                    1: _buildSegment('Tài chính', 1),
                    2: _buildSegment('Gói Dịch Vụ', 2),
                    3: _buildSegment('Tiện Ích', 3),
                  },
                  onValueChanged: (val) {
                    if (val != null) setState(() => _selectedTab = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  _buildTodoTab(ref),
                  _buildFinanceTab(),
                  _buildSubscriptionTab(),
                  _buildAddonsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegment(String title, int index) {
    final isSelected = _selectedTab == index;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF4B5563),
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  // ==========================================
  // TAB 0: CẦN XỬ LÝ (TO-DO LIST)
  // ==========================================
  Widget _buildTodoTab(WidgetRef ref) {
    final branchesAsync = ref.watch(branchProvider);
    final roomsAsync = ref.watch(roomProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            unawaited(ref.read(branchProvider.notifier).refreshBranches());
            // TODO: RoomNotifier doesn't have refresh method, it should re-fetch by owner but keep it simple for now
            await Future.delayed(const Duration(milliseconds: 500));
          },
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const Text(
                'CÔNG VIỆC CẦN PHÊ DUYỆT',
                style: TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              // Nút Mở QR Thu tiền mặt
              ElevatedButton.icon(
                onPressed: () => context.push(
                  '/qr_cash_receiver',
                  extra: {'sessionType': 'TENANT_PAY_BILL'},
                ),
                icon: const Icon(CupertinoIcons.qrcode),
                label: const Text('Thu Tiền Mặt (Mã QR)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF298FFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 24),

              // Pending Branches
              ...branchesAsync.when(
                data: (branches) {
                  final pending = branches
                      .where((b) => b.approvalStatus == 'PENDING_APPROVAL')
                      .toList();
                  if (pending.isEmpty) return [];
                  return AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 375),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(child: widget),
                    ),
                    children: pending
                        .map(
                          (b) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildTodoItem(
                              title: 'Duyệt Chi nhánh mới',
                              subtitle:
                                  'Chi nhánh: ${b.branchName} - ${b.branchCode ?? ""}',
                              icon: Icons.store_outlined,
                              onApprove: () async {
                                await ref
                                    .read(branchProvider.notifier)
                                    .approveBranch(b.id, true);
                                if (!mounted) return;
                                ToastUtils.show(context, 'Đã duyệt chi nhánh!');
                              },
                              onReject: () async {
                                await ref
                                    .read(branchProvider.notifier)
                                    .approveBranch(b.id, false);
                                if (!mounted) return;
                                ToastUtils.show(
                                  context,
                                  'Đã từ chối chi nhánh!',
                                  isError: true,
                                );
                              },
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
                loading: () => [
                  const Center(child: CircularProgressIndicator()),
                ],
                error: (e, st) => [Text('Lỗi tải chi nhánh: $e')],
              ),

              // Pending Rooms
              ...roomsAsync.when(
                data: (rooms) {
                  final pending = rooms
                      .where((r) => r.approvalStatus == 'PENDING_APPROVAL')
                      .toList();
                  if (pending.isEmpty) return [];
                  return AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 375),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(child: widget),
                    ),
                    children: pending
                        .map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildTodoItem(
                              title: 'Duyệt Phòng mới',
                              subtitle:
                                  'Phòng: ${r.roomName}\nChi nhánh ID: ${r.branchId}',
                              icon: Icons.meeting_room_outlined,
                              onApprove: null,
                              onReject: null,
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
                loading: () => [],
                error: (e, st) => [],
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildTodoItem({
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onApprove,
    VoidCallback? onReject,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.kAccentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppTheme.kAccentColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: const Text(
                  'CHỜ DUYỆT',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          if (onApprove != null && onReject != null)
            Row(
              children: [
                Expanded(
                  child: _TapticScaleButton(
                    onPressed: onReject,
                    child: OutlinedButton(
                      onPressed: null, // Handled by wrapper
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(
                          color: Colors.red.withValues(alpha: 0.5),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Từ chối',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TapticScaleButton(
                    onPressed: onApprove,
                    child: ElevatedButton(
                      onPressed: null, // Handled by wrapper
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.kAccentColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppTheme
                            .kAccentColor, // Keep color when disabled but handled by wrapper
                        disabledForegroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Phê duyệt',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Center(
                child: Text(
                  'Đang chờ Admin phê duyệt',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: TÀI CHÍNH (FINANCE)
  // ==========================================
  Widget _buildFinanceTab() {
    final billsState = ref.watch(billProvider);
    final statsState = ref.watch(dashboardStatsProvider());

    List<Transaction> allTransactions = [];
    double totalIncome = 0;
    double totalExpense = 0;

    if (billsState.value != null) {
      for (var bill in billsState.value!) {
        allTransactions.add(
          Transaction(
            id: 'B${bill.id}',
            title: 'Thu tiền phòng ${bill.roomId}',
            amount: bill.totalAmount ?? 0.0,
            type: 'INCOME',
            date: bill.createdAt,
            person: 'Khách hàng',
            location: 'Phòng ${bill.roomId}',
            method: bill.status == 'PAID' ? 'TRANSFER' : 'UNPAID',
          ),
        );
      }
    }

    allTransactions.addAll(_expenses);

    final startOfDay = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
    );
    final endOfDay = DateTime(
      _endDate.year,
      _endDate.month,
      _endDate.day,
      23,
      59,
      59,
      999,
    );

    // Lọc theo ngày
    allTransactions = allTransactions
        .where(
          (t) =>
              t.date.compareTo(startOfDay) >= 0 &&
              t.date.compareTo(endOfDay) <= 0,
        )
        .toList();

    allTransactions.sort((a, b) => b.date.compareTo(a.date));

    for (var t in allTransactions) {
      if (t.method == 'UNPAID') continue;
      if (t.type == 'INCOME') totalIncome += t.amount;
      if (t.type == 'EXPENSE') totalExpense += t.amount;
    }
    double netProfit = totalIncome - totalExpense;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 500));
          },
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildDateFilters(),
              const SizedBox(height: 24),
              _buildSummaryCards(totalIncome, totalExpense, netProfit),
              const SizedBox(height: 32),
              statsState.when(
                data: (data) {
                  // BUGFIX (data): tránh `as List<dynamic>?` ném TypeError khi
                  // `revenueChart` không phải List — chỉ nhận khi là List.
                  final chart = data['revenueChart'] is List
                      ? (data['revenueChart'] as List).whereType<Map>().toList()
                      : <Map>[];
                  return FinancialChartWidget(chartData: chart);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, st) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 32),
              const Text(
                'CHI TIẾT GIAO DỊCH',
                style: TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: allTransactions.isEmpty
              ? const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'Không có giao dịch nào trong thời gian này',
                        style: TextStyle(color: Color(0xFF4B5563)),
                      ),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildTransactionCard(allTransactions[index]),
                    childCount: allTransactions.length,
                  ),
                ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
      ],
    );
  }

  Widget _buildDateFilters() {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Tháng này', 'Tháng trước', 'Quý này', 'Năm nay'].map((
                p,
              ) {
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
                        : AppTheme.kBackgroundLight,
                    borderRadius: BorderRadius.circular(20),
                    onPressed: () => _setPeriod(p),
                    child: Text(
                      p,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF4B5563),
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
          style: const TextStyle(color: Color(0xFF4B5563), fontSize: 12),
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
                color: AppTheme.kBackgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dateFormat.format(date),
                    style: const TextStyle(
                      color: CupertinoColors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.calendar,
                    color: Color(0xFF4B5563),
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

  Widget _buildSummaryCards(double income, double expense, double net) {
    return Column(
      children: [
        // Donut Chart for Income/Expense Ratio
        if (income > 0 || expense > 0)
          Container(
            height: 180,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 40,
                          sections: (income == 0 && expense == 0)
                              ? [
                                  PieChartSectionData(
                                    color: const Color(0xFFE5E7EB),
                                    value: 1,
                                    title: '',
                                    radius: 18,
                                  ),
                                ]
                              : [
                                  if (income > 0)
                                    PieChartSectionData(
                                      color: CupertinoColors.systemGreen,
                                      value: income,
                                      title: '',
                                      radius: 18,
                                    ),
                                  if (expense > 0)
                                    PieChartSectionData(
                                      color: CupertinoColors.systemRed,
                                      value: expense,
                                      title: '',
                                      radius: 18,
                                    ),
                                ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Lợi Nhuận',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          _AnimatedCurrencyText(
                            value: net,
                            format: currencyFormat,
                            style: TextStyle(
                              color: net >= 0
                                  ? CupertinoColors.systemGreen
                                  : CupertinoColors.systemRed,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildChartLegend(
                        'Thu nhập',
                        income,
                        CupertinoColors.systemGreen,
                      ),
                      const SizedBox(height: 12),
                      _buildChartLegend(
                        'Chi phí',
                        expense,
                        CupertinoColors.systemRed,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildFinanceCard(
                title: 'TỔNG THU',
                amount: income,
                icon: CupertinoIcons.arrow_down_right_circle_fill,
                imagePath: 'assets/images/features/auto_rent_collection.png',
                color: CupertinoColors.systemGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFinanceCard(
                title: 'TỔNG CHI',
                amount: expense,
                icon: CupertinoIcons.arrow_up_right_circle_fill,
                imagePath: 'assets/images/features/expense_scanner.png',
                color: CupertinoColors.systemRed,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartLegend(String title, double value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Color(0xFF4B5563), fontSize: 12),
              ),
              _AnimatedCurrencyText(
                value: value,
                format: currencyFormat,
                style: const TextStyle(
                  color: CupertinoColors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinanceCard({
    required String title,
    String? imagePath,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: imagePath != null
                    ? Image.asset(
                        imagePath,
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        isAntiAlias: true,
                        errorBuilder: (_, __, ___) =>
                            Icon(icon, color: color, size: 24),
                      )
                    : Icon(icon, color: color, size: 24),
              ),
              Icon(
                CupertinoIcons.graph_square_fill,
                color: color.withValues(alpha: 0.2),
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          _AnimatedCurrencyText(
            value: amount,
            format: currencyFormat,
            style: const TextStyle(
              color: CupertinoColors.black,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
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
    final imagePath = isIncome
        ? 'assets/images/features/auto_rent_collection.png'
        : 'assets/images/features/expense_scanner.png';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                imagePath,
                width: 26,
                height: 26,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                isAntiAlias: true,
                errorBuilder: (_, __, ___) =>
                    Icon(icon, color: color, size: 22),
              ),
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
                            color: CupertinoColors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _AnimatedCurrencyText(
                        value: t.amount,
                        format: currencyFormat,
                        prefix: isIncome ? '+' : '-',
                        style: TextStyle(
                          color: color,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.person_fill,
                        color: Color(0xFF4B5563),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        t.person,
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        CupertinoIcons.location_solid,
                        color: Color(0xFF4B5563),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        t.location,
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
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
                          color: Color(0xFF4B5563),
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
                                  alpha: 0.1,
                                )
                              : AppTheme.kBackgroundLight,
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
                                : const Color(0xFF4B5563),
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

  // ==========================================
  // TAB 2: SAAS SUBSCRIPTION
  // ==========================================
  final List<Map<String, dynamic>> _mockPlans = [
    {
      'id': 1,
      'name': 'GÓI CƠ BẢN (FREE)',
      'price': 'Miễn phí',
      'features': ['Quản lý 10 phòng', 'Thống kê cơ bản', 'Hỗ trợ cộng đồng'],
      'isPopular': false,
    },
    {
      'id': 2,
      'name': 'GÓI PRO',
      'price': '499.000 đ/tháng',
      'features': [
        'Quản lý 50 phòng',
        'Chữ ký điện tử',
        'Xuất báo cáo CT01',
        'Quản lý nhân viên',
      ],
      'isPopular': true,
    },
    {
      'id': 3,
      'name': 'GÓI VIP',
      'price': '1.499.000 đ/tháng',
      'features': [
        'Không giới hạn phòng',
        'Hỗ trợ 1-1 24/7',
        'Báo cáo chuyên sâu',
        'Tích hợp API',
      ],
      'isPopular': false,
    },
  ];

  Widget _buildSubscriptionTab() {
    final statsAsync = ref.watch(
      dashboardStatsProvider(month: null, year: null),
    );

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 500));
          },
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: statsAsync.when(
            data: (stats) {
              final planName =
                  stats['currentPlanName'] as String? ?? 'CHƯA ĐĂNG KÝ';
              return SliverList(
                delegate: SliverChildListDelegate([
                  GlassContainer(
                    padding: const EdgeInsets.all(24),
                    color: AppTheme.kAccentColor.withValues(alpha: 0.1),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.sparkles,
                          color: AppTheme.kAccentColor,
                          size: 36,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Gói hiện tại của bạn',
                                style: TextStyle(
                                  color: Color(0xFF4B5563),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                planName.toUpperCase(),
                                style: const TextStyle(
                                  color: AppTheme.kAccentColor,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'NÂNG CẤP GÓI PHẦN MỀM',
                    style: TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._mockPlans.map(
                    (plan) => _buildPlanCard(plan, currentPlan: planName),
                  ),
                  const SizedBox(height: 40),
                ]),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: LiquidGlassLoader(text: 'Đang tải gói dịch vụ...'),
              ),
            ),
            error: (e, _) =>
                SliverToBoxAdapter(child: Center(child: Text('Lỗi: $e'))),
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard(
    Map<String, dynamic> plan, {
    required String currentPlan,
  }) {
    // BUGFIX (data): tránh `as bool` ném TypeError khi `isPopular` null/khác.
    final isPopular = plan['isPopular'] is bool
        ? plan['isPopular'] as bool
        : false;
    final isCurrent = currentPlan.toUpperCase().contains(
      plan['name'].toString().toUpperCase(),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        color: isPopular
            ? AppTheme.kAccentColor.withValues(alpha: 0.05)
            : Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPopular)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.kAccentColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ĐƯỢC YÊU THÍCH',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    plan['name'],
                    style: const TextStyle(
                      color: CupertinoColors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  plan['price'],
                  style: const TextStyle(
                    color: AppTheme.kAccentColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // BUGFIX (data): tránh `as List` ném TypeError khi `features`
            // là null/không phải List.
            ...List.generate(
              (plan['features'] is List ? plan['features'] as List : const [])
                  .length,
              (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.check_mark_circled_solid,
                        color: CupertinoColors.systemGreen,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          (plan['features'] is List
                                  ? plan['features'] as List
                                  : const [])[index]
                              .toString(),
                          style: const TextStyle(
                            color: Color(0xFF4B5563),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: isCurrent
                    ? const Color(0xFFD1D5DB)
                    : (isPopular
                          ? AppTheme.kAccentColor
                          : CupertinoColors.black),
                borderRadius: BorderRadius.circular(24),
                onPressed: isCurrent
                    ? null
                    : () => ToastUtils.show(
                        context,
                        'Đã chuyển hướng thanh toán mua gói ${plan['name']}',
                      ),
                child: Text(
                  isCurrent ? 'Đang sử dụng' : 'Nâng cấp ngay',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 3: TIỆN ÍCH (ADD-ONS)
  // ==========================================
  Widget _buildAddonsTab() {
    final addons = [
      {
        'icon': CupertinoIcons.doc_text_fill,
        'image': 'assets/images/features/auto_pdf_gen.png',
        'color': CupertinoColors.systemBlue,
        'title': 'Xuất CT01',
        'route': '/ct01-export',
      },
      {
        'icon': CupertinoIcons.car_detailed,
        'image': 'assets/images/features/smart_locker.png',
        'color': CupertinoColors.systemIndigo,
        'title': 'Quản lý xe',
        'route': '/vehicle-management',
      },
      {
        'icon': CupertinoIcons.person_3_fill,
        'image': 'assets/images/features/staff_dispatch.png',
        'color': CupertinoColors.systemTeal,
        'title': 'Nhân viên',
        'route': '/staff-management',
      },
      {
        'icon': CupertinoIcons.money_dollar_circle_fill,
        'image': 'assets/images/features/multilevel_debt.png',
        'color': CupertinoColors.systemGreen,
        'title': 'Nợ đọng',
        'route': '/debt-management',
      },
      {
        'icon': CupertinoIcons.doc_on_clipboard_fill,
        'image': 'assets/images/features/move_checklist.png',
        'color': CupertinoColors.systemOrange,
        'title': 'Điểm danh',
        'route': '/staff-attendance',
      },
      {
        'icon': CupertinoIcons.cart_fill,
        'image': 'assets/images/features/local_services.png',
        'color': CupertinoColors.systemPink,
        'title': 'Chợ cư dân',
        'route': '/marketplace',
      },
      {
        'icon': CupertinoIcons.ticket_fill,
        'image': 'assets/images/features/loyalty_rewards.png',
        'color': const Color(0xFF298FFF),
        'title': 'Mã Giảm Giá',
        'route': '/landlord-vouchers',
      },
    ];

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 500));
          },
        ),
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = addons[index];
              return GestureDetector(
                onTap: () => context.push(item['route'] as String),
                child: GlassContainer(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: (item['color'] as Color).withValues(
                            alpha: 0.1,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          item['image'] as String,
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          isAntiAlias: true,
                          errorBuilder: (_, __, ___) => Icon(
                            item['icon'] as IconData,
                            color: item['color'] as Color,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        item['title'] as String,
                        style: const TextStyle(
                          color: CupertinoColors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }, childCount: addons.length),
          ),
        ),
      ],
    );
  }
}

class _TapticScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  const _TapticScaleButton({required this.child, required this.onPressed});

  @override
  State<_TapticScaleButton> createState() => _TapticScaleButtonState();
}

class _TapticScaleButtonState extends State<_TapticScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    unawaited(_controller.forward());
  }

  void _onTapUp(TapUpDetails details) {
    unawaited(HapticFeedback.lightImpact());
    unawaited(_controller.reverse());
    widget.onPressed();
  }

  void _onTapCancel() {
    unawaited(_controller.reverse());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

class _AnimatedCurrencyText extends StatelessWidget {
  final double value;
  final TextStyle style;
  final NumberFormat format;
  final String prefix;

  const _AnimatedCurrencyText({
    required this.value,
    required this.style,
    required this.format,
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOutQuart,
      builder: (context, val, child) {
        String formatted = format.format(val).replaceAll('đ', '').trim();
        return Text('$prefix$formatted', style: style);
      },
    );
  }
}
