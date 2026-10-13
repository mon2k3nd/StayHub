import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/premium_shimmer_loading.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../application/advanced_analytics_provider.dart';
import '../../../core/components/app_error_widget.dart';
import 'dart:async' show unawaited;

class AdvancedOwnerAnalyticsScreen extends ConsumerStatefulWidget {
  const AdvancedOwnerAnalyticsScreen({super.key});

  @override
  ConsumerState<AdvancedOwnerAnalyticsScreen> createState() =>
      _AdvancedOwnerAnalyticsScreenState();
}

class _AdvancedOwnerAnalyticsScreenState
    extends ConsumerState<AdvancedOwnerAnalyticsScreen> {
  int _selectedTab = 0;

  bool _isExporting = false;

  Future<void> _exportReport() async {
    setState(() => _isExporting = true);
    await Future.delayed(const Duration(milliseconds: 1500)); // Giả lập tạo PDF
    setState(() => _isExporting = false);
    if (!mounted) return;
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Thành công'),
          content: const Text('Báo cáo PDF đã được lưu vào thư mục tải xuống.'),
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

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      title: 'Business Intelligence',
      useScrollView: false,
      trailing: _isExporting
          ? const CupertinoActivityIndicator()
          : CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _exportReport(),
              child: const Icon(CupertinoIcons.doc_text, size: 24),
            ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: _selectedTab,
                children: const {
                  0: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Tài chính', style: TextStyle(fontSize: 12)),
                  ),
                  1: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Phòng ốc', style: TextStyle(fontSize: 12)),
                  ),
                  2: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Vận hành', style: TextStyle(fontSize: 12)),
                  ),
                  3: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Dự báo', style: TextStyle(fontSize: 12)),
                  ),
                },
                onValueChanged: (val) {
                  if (val != null) setState(() => _selectedTab = val);
                },
              ),
            ),
          ),
          Expanded(child: _buildSelectedTab()),
        ],
      ),
    );
  }

  Widget _buildSelectedTab() {
    switch (_selectedTab) {
      case 0:
        return _buildFinancialTab();
      case 1:
        return _buildOccupancyTab();
      case 2:
        return _buildOpsTab();
      case 3:
        return _buildForecastTab();
      default:
        return const SizedBox();
    }
  }

  Widget _buildFinancialTab() {
    final asyncData = ref.watch(ownerFinancialProvider);
    return asyncData.when(
      loading: () => ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          PremiumShimmerLoading(itemHeight: 120),
          SizedBox(height: 20),
          PremiumShimmerLoading(itemHeight: 250),
          SizedBox(height: 20),
          PremiumShimmerLoading(itemHeight: 250),
        ],
      ),
      error: (e, _) => AppErrorWidget(error: e),
      data: (data) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildMetricRow(
              'Tổng doanh thu (GMV)',
              data['gmv'] ?? '125M',
              'Lợi nhuận ròng',
              data['netIncome'] ?? '85M',
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Tỉ lệ nợ đọng',
              data['badDebt'] ?? '2.5M',
              'Thanh toán đúng hạn',
              '${data['onTimePaymentRate'] ?? 92}%',
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Chi phí bảo trì TB',
              '540K/phòng',
              'Doanh thu dịch vụ (Điện nước)',
              '14.5M',
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Dự phóng tháng sau',
              '132M',
              'Thất thoát dòng tiền',
              '1.2M',
            ),
            const SizedBox(height: 24),
            _buildChartCard(
              'Biến động Dòng tiền (Cashflow)',
              _buildLineChart(data['cashflowTrend']),
            ),
            const SizedBox(height: 24),
            _buildChartCard(
              'Cơ cấu Doanh thu',
              _buildPieChart(data['revenueBreakdown']),
            ),
            const SizedBox(height: 24),
            _buildChartCard('So sánh Thu / Chi (Tháng)', _buildBarChart(null)),
            const SizedBox(height: 60),
          ],
        );
      },
    );
  }

  Widget _buildOccupancyTab() {
    final asyncData = ref.watch(ownerOccupancyProvider);
    return asyncData.when(
      loading: () => ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          PremiumShimmerLoading(itemHeight: 120),
          SizedBox(height: 20),
          PremiumShimmerLoading(itemHeight: 250),
        ],
      ),
      error: (e, _) => AppErrorWidget(error: e),
      data: (data) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildMetricRow(
              'Tổng cơ sở',
              '${data['totalBranches'] ?? 2}',
              'Tổng số phòng',
              '${data['totalRooms'] ?? 24}',
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Cư dân đang ở',
              '${data['activeTenants'] ?? 45}',
              'Lấp đầy',
              '${data['realTimeOccupancyRate'] ?? 95}%',
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Thời gian tìm khách TB',
              '4 Ngày',
              'Tỉ lệ khách thuê > 1 năm',
              '64%',
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Tuổi trung bình KH',
              '22-26 tuổi',
              'Sắp hết hạn hợp đồng',
              '3 Phòng',
            ),
            const SizedBox(height: 24),
            _buildChartCard(
              'Tỉ lệ lấp đầy theo Cơ sở',
              _buildBarChart(data['occupancyByBranch']),
            ),
            const SizedBox(height: 24),
            _buildChartCard(
              'Phân bổ Tình trạng Phòng',
              _buildPieChart(data['roomStatusDistribution']),
            ),
            const SizedBox(height: 24),
            _buildChartCard('Xu hướng Trả/Nhận Phòng', _buildLineChart(null)),
            const SizedBox(height: 60),
          ],
        );
      },
    );
  }

  Widget _buildOpsTab() {
    final asyncData = ref.watch(ownerOpsProvider);
    return asyncData.when(
      loading: () => ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          PremiumShimmerLoading(itemHeight: 120),
          SizedBox(height: 20),
          PremiumShimmerLoading(itemHeight: 250),
        ],
      ),
      error: (e, _) => AppErrorWidget(error: e),
      data: (data) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildMetricRow(
              'Sự cố đang mở',
              '${data['openTickets'] ?? 2}/${data['totalTickets'] ?? 15}',
              'Thời gian xử lý TB',
              '${data['avgResolutionTimeHours'] ?? 24}h',
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Điểm hài lòng (CSAT)',
              '${data['maintenanceCsat'] ?? 4.8}/5.0',
              'Tỉ lệ tái ký',
              '${data['tenantRetentionRate'] ?? 85}%',
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Đánh giá Quản lý',
              '4.9/5.0',
              'Khiếu nại chưa giải quyết',
              '0',
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Tổng số hợp đồng mới (Tháng)',
              '4',
              'Tỉ lệ chấm dứt HD sớm',
              '2.5%',
            ),
            const SizedBox(height: 24),
            _buildChartCard(
              'Tình trạng xử lý Sự cố',
              _buildPieChart(data['ticketStatusDistribution']),
            ),
            const SizedBox(height: 24),
            _buildChartCard('Mức độ tiêu thụ Điện Nước', _buildLineChart(null)),
            const SizedBox(height: 60),
          ],
        );
      },
    );
  }

  Widget _buildMetricRow(
    String title1,
    dynamic val1,
    String title2,
    dynamic val2,
  ) {
    return Row(
      children: [
        Expanded(child: _buildMetricCard(title1, _formatValue(val1))),
        const SizedBox(width: 16),
        Expanded(child: _buildMetricCard(title2, _formatValue(val2))),
      ],
    );
  }

  String _formatValue(dynamic val) {
    if (val is double && val > 1000) {
      return '${(val / 1000000).toStringAsFixed(1)}M';
    }
    return val.toString();
  }

  Widget _buildMetricCard(String title, String value) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.kTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppTheme.kAccentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }

  /// BUGFIX (data): coerce an toàn sang double — tránh `as num` ném TypeError
  /// khi backend trả String/null (dùng chung cho cả 3 loại biểu đồ).
  double _num(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0.0;

  Widget _buildLineChart(List<dynamic>? points) {
    if (points == null || points.isEmpty) return const SizedBox();
    List<FlSpot> spots = [];
    for (int i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), _num(points[i]['value']) / 1000000));
    }
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) {
                if (v.toInt() >= 0 && v.toInt() < points.length) {
                  return Text(
                    points[v.toInt()]['label'],
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppTheme.kAccentColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppTheme.kAccentColor.withValues(alpha: 0.3),
                  AppTheme.kAccentColor.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(List<dynamic>? slices) {
    if (slices == null || slices.isEmpty) return const SizedBox();
    List<PieChartSectionData> sections = [];
    for (var slice in slices) {
      Color c = AppTheme.kAccentColor;
      if (slice['color'] != null &&
          slice['color'].toString().startsWith('0x')) {
        c = Color(int.parse(slice['color']));
      }
      sections.add(
        PieChartSectionData(
          color: c,
          value: _num(slice['value']),
          title: '${slice['label']}',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.white,
          ),
        ),
      );
    }
    return PieChart(
      PieChartData(sectionsSpace: 2, centerSpaceRadius: 40, sections: sections),
    );
  }

  Widget _buildBarChart(List<dynamic>? bars) {
    if (bars == null || bars.isEmpty) return const SizedBox();
    List<BarChartGroupData> groups = [];
    for (int i = 0; i < bars.length; i++) {
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: _num(bars[i]['value']),
              color: AppTheme.kAccentColor,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }
    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, meta) {
                if (v.toInt() >= 0 && v.toInt() < bars.length) {
                  return Text(
                    bars[v.toInt()]['label'],
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: groups,
      ),
    );
  }

  Widget _buildForecastTab() {
    final asyncData = ref.watch(ownerForecastProvider);
    return asyncData.when(
      loading: () => ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          PremiumShimmerLoading(itemHeight: 120),
          SizedBox(height: 20),
          PremiumShimmerLoading(itemHeight: 250),
        ],
      ),
      error: (e, _) => AppErrorWidget(error: e),
      data: (data) {
        // BUGFIX (data): tránh `as List` ném TypeError + `alert['type']` ném
        // NoSuchMethodError khi phần tử không phải Map — lọc an toàn.
        final alerts = (data['alerts'] is List
            ? (data['alerts'] as List).whereType<Map>().toList()
            : <Map>[]);
        final recs = (data['recommendations'] is List
            ? (data['recommendations'] as List).whereType<Map>().toList()
            : <Map>[]);

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // KPI Alerts
            if (alerts.isNotEmpty) ...[
              const Text(
                'Cảnh Báo KPI',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppTheme.kTextSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ...alerts.map((alert) {
                final isWarning = alert['type'] == 'WARNING';
                final color = isWarning
                    ? CupertinoColors.systemOrange
                    : CupertinoColors.systemGreen;
                final icon = isWarning
                    ? CupertinoIcons.exclamationmark_triangle_fill
                    : CupertinoIcons.check_mark_circled_solid;
                final alertAsset = isWarning
                    ? 'assets/images/features/sos_panic.png'
                    : 'assets/images/features/move_checklist.png';
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        alertAsset,
                        width: 26,
                        height: 26,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        isAntiAlias: true,
                        errorBuilder: (_, __, ___) =>
                            Icon(icon, color: color, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          alert['message'],
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),
            ],

            _buildMetricRow(
              'Tăng trưởng (MoM)',
              '${data['revenueMoM']}%',
              'Tăng trưởng (YoY)',
              '${data['revenueYoY']}%',
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Dự báo Lấp đầy',
              '${data['occupancyForecast']}%',
              'Phòng Rủi ro (Churn)',
              '${data['churnRisk']}',
            ),
            const SizedBox(height: 24),

            // AI Recommendations
            if (recs.isNotEmpty) ...[
              const Text(
                'AI Khuyến Nghị',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppTheme.kTextSecondary,
                ),
              ),
              const SizedBox(height: 12),
              GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: recs
                      .map(
                        (rec) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                CupertinoIcons.sparkles,
                                color: AppTheme.kAccentColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  rec.toString(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Mock Chart cho Forecast
            _buildChartCard(
              'Biểu đồ Dự báo Doanh Thu (3 tháng tới)',
              _buildMockForecastChart(),
            ),
            const SizedBox(height: 60),
          ],
        );
      },
    );
  }

  Widget _buildMockForecastChart() {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: const [
              FlSpot(0, 100),
              FlSpot(1, 110),
              FlSpot(2, 115),
              FlSpot(3, 125),
            ],
            isCurved: true,
            color: CupertinoColors.systemPurple,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  CupertinoColors.systemPurple.withValues(alpha: 0.3),
                  CupertinoColors.systemPurple.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
