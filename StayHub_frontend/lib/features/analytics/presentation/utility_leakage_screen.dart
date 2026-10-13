import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/utils/toast_utils.dart';
import 'dart:async' show unawaited;

class UtilityLeakageScreen extends ConsumerStatefulWidget {
  final int branchId;
  const UtilityLeakageScreen({super.key, required this.branchId});

  @override
  ConsumerState<UtilityLeakageScreen> createState() =>
      _UtilityLeakageScreenState();
}

class _UtilityLeakageScreenState extends ConsumerState<UtilityLeakageScreen> {
  bool _loading = true;
  Map<String, dynamic>? _reportData;
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;

  final _elecMasterCtrl = TextEditingController();
  final _waterMasterCtrl = TextEditingController();
  bool _isSaving = false;

  /// BUGFIX (data): coerce an toàn sang double — tránh `as num` ném TypeError
  /// khi backend trả String/null.
  double _num(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;

  @override
  void initState() {
    super.initState();
    unawaited(_fetchLeakageData());
  }

  Future<void> _fetchLeakageData() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.get(
        '/v1/branch-meters/${widget.branchId}/leakage',
        queryParameters: {'month': _month, 'year': _year},
      );
      if (mounted) {
        setState(() {
          _reportData = resp.data as Map<String, dynamic>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ToastUtils.show(context, 'Lỗi tải báo cáo: $e', isError: true);
      }
    }
  }

  Future<void> _saveMasterMeter() async {
    if (_elecMasterCtrl.text.isEmpty && _waterMasterCtrl.text.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        '/v1/branch-meters/${widget.branchId}',
        queryParameters: {
          'month': _month,
          'year': _year,
          if (_elecMasterCtrl.text.isNotEmpty)
            'electricCurrent': _elecMasterCtrl.text,
          if (_waterMasterCtrl.text.isNotEmpty)
            'waterCurrent': _waterMasterCtrl.text,
        },
      );
      if (mounted) {
        ToastUtils.show(context, 'Đã lưu chỉ số đồng hồ tổng');
      }
      _elecMasterCtrl.clear();
      _waterMasterCtrl.clear();
      await _fetchLeakageData();
    } catch (e) {
      if (mounted) {
        ToastUtils.show(context, 'Lỗi lưu đồng hồ: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      title: 'Báo cáo Thất Thoát',
      useScrollView: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      if (_month == 1) {
                        _month = 12;
                        _year--;
                      } else {
                        _month--;
                      }
                      unawaited(_fetchLeakageData());
                    },
                    child: const Icon(CupertinoIcons.left_chevron),
                  ),
                  Text(
                    'Tháng $_month/$_year',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      if (_month == 12) {
                        _month = 1;
                        _year++;
                      } else {
                        _month++;
                      }
                      unawaited(_fetchLeakageData());
                    },
                    child: const Icon(CupertinoIcons.right_chevron),
                  ),
                ],
              ),
            ),
          ),

          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CupertinoActivityIndicator()),
            )
          else if (_reportData != null)
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // BUGFIX (data): trước đây ép `as num` — nếu backend trả
                  // String/null thì ném TypeError và cả màn hình rò rỉ điện
                  // nước không render. Coerce an toàn.
                  _buildChartCard(
                    title: 'Điện (kWh)',
                    masterUsage: _num(_reportData!['masterElectricUsage']),
                    roomsUsage: _num(_reportData!['roomsElectricUsage']),
                    leakage: _num(_reportData!['electricLeakage']),
                    color: CupertinoColors.activeOrange,
                  ),
                  const SizedBox(height: 20),
                  _buildChartCard(
                    title: 'Nước (Khối)',
                    masterUsage: _num(_reportData!['masterWaterUsage']),
                    roomsUsage: _num(_reportData!['roomsWaterUsage']),
                    leakage: _num(_reportData!['waterLeakage']),
                    color: CupertinoColors.activeBlue,
                  ),
                  const SizedBox(height: 24),
                  _buildUpdateMeterCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required double masterUsage,
    required double roomsUsage,
    required double leakage,
    required Color color,
  }) {
    final maxVal = (masterUsage > roomsUsage ? masterUsage : roomsUsage) * 1.2;
    final maxValAdj = maxVal == 0 ? 100.0 : maxVal;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9CA3AF).withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValAdj,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF111827),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label = groupIndex == 0 ? 'Tổng Tòa' : 'Các Phòng';
                      return BarTooltipItem(
                        '$label\n${rod.toY.toStringAsFixed(1)}',
                        const TextStyle(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            value.toInt() == 0
                                ? 'Đồng hồ Tổng'
                                : 'Tổng các Phòng',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: masterUsage,
                        color: const Color(0xFF111827),
                        width: 40,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: roomsUsage,
                        color: color,
                        width: 40,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: leakage > 0
                  ? const Color(0xFFFEF2F2)
                  : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  leakage > 0
                      ? CupertinoIcons.arrow_down_right_square_fill
                      : CupertinoIcons.checkmark_seal_fill,
                  color: leakage > 0
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF10B981),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    leakage > 0
                        ? 'Thất thoát: ${leakage.toStringAsFixed(1)}'
                        : 'Không có thất thoát / Âm',
                    style: TextStyle(
                      color: leakage > 0
                          ? const Color(0xFF991B1B)
                          : const Color(0xFF065F46),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateMeterCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cập nhật chỉ số Đồng hồ Tổng',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CupertinoTextField(
                  controller: _elecMasterCtrl,
                  placeholder: 'Điện (mới)',
                  keyboardType: TextInputType.number,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGroupedBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoTextField(
                  controller: _waterMasterCtrl,
                  placeholder: 'Nước (mới)',
                  keyboardType: TextInputType.number,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGroupedBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              borderRadius: BorderRadius.circular(12),
              onPressed: _isSaving ? null : _saveMasterMeter,
              child: _isSaving
                  ? const CupertinoActivityIndicator()
                  : const Text('Lưu chỉ số'),
            ),
          ),
        ],
      ),
    );
  }
}
