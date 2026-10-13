import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/premium_shimmer_loading.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../dashboard/application/advanced_analytics_provider.dart';
import '../../../core/components/app_error_widget.dart';

class AdvancedAdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdvancedAdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdvancedAdminAnalyticsScreen> createState() =>
      _AdvancedAdminAnalyticsScreenState();
}

class _AdvancedAdminAnalyticsScreenState
    extends ConsumerState<AdvancedAdminAnalyticsScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      title: 'Platform BI (Macro)',
      useScrollView: false,
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
                    child: Text('SaaS Growth'),
                  ),
                  1: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Thị trường'),
                  ),
                  2: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Hệ thống'),
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
        return _buildSaasTab();
      case 1:
        return _buildMarketTab();
      case 2:
        return _buildSystemTab();
      default:
        return const Center(child: Text('Đang cập nhật...'));
    }
  }

  Widget _buildSaasTab() {
    final asyncData = ref.watch(adminSaasProvider);
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
              'ARR (Năm)',
              data['arr'] ?? '12.5B',
              'MRR (Tháng)',
              data['mrr'] ?? '1.04B',
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'LTV (Vòng đời)',
              data['ltv'] ?? '4.5M',
              'CAC (Chi phí mua)',
              data['cac'] ?? '250K',
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Tỉ lệ Churn',
              '${data['churnRate'] ?? 1.2}%',
              'Tăng trưởng',
              '+12.5%',
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              'Tài khoản Premium',
              '4,200',
              'Tài khoản Cơ bản',
              '12,500',
            ),
            const SizedBox(height: 16),
            _buildMetricRow('DAU (Active)', '8,540', 'MAU (Tháng)', '45,200'),
            const SizedBox(height: 24),
            _buildChartCard(
              'Biến động MRR (6 Tháng)',
              _buildLineChart(data['mrrGrowthTrend']),
            ),
            const SizedBox(height: 24),
            _buildChartCard(
              'Tỉ trọng Gói Cước',
              _buildPieChart(data['planDistribution']),
            ),
            const SizedBox(height: 24),
            _buildChartCard(
              'User Retention (D1-D30)',
              _buildLineChart(null),
            ), // Placeholder cho retention
            const SizedBox(height: 60),
          ],
        );
      },
    );
  }

  Widget _buildMarketTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildMetricRow(
          'Giá thuê TB',
          '4.5M/tháng',
          'Tỉ lệ lấp đầy Khu vực',
          '85.4%',
        ),
        const SizedBox(height: 16),
        _buildMetricRow(
          'Top Quận (Tìm kiếm)',
          'Cầu Giấy (35%)',
          'Nhu cầu tăng',
          '+15% (Q3)',
        ),
        const SizedBox(height: 16),
        _buildMetricRow(
          'Số phòng đang trống',
          '1,245',
          'Thời gian tìm khách TB',
          '5.2 Ngày',
        ),
        const SizedBox(height: 16),
        _buildMetricRow('Diện tích phòng TB', '22 m2', 'Giá/m2', '205K/m2'),
        const SizedBox(height: 24),
        _buildChartCard('Xu hướng giá thuê theo Tháng', _buildLineChart(null)),
        const SizedBox(height: 24),
        _buildChartCard('Phân bổ loại phòng', _buildPieChart(null)),
        const SizedBox(height: 60),
      ],
    );
  }

  Widget _buildSystemTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildMetricRow('API Latency', '45ms', 'DB Queries/s', '1,240'),
        const SizedBox(height: 16),
        _buildMetricRow('Storage Used', '1.2 TB', 'Bandwidth', '450 GB/Ngày'),
        const SizedBox(height: 16),
        _buildMetricRow(
          'Error Rate (5xx)',
          '0.01%',
          'Active Connections',
          '5,420',
        ),
        const SizedBox(height: 16),
        _buildMetricRow('CPU Usage', '34%', 'RAM Usage', '62%'),
        const SizedBox(height: 24),
        _buildChartCard('Tải Server (24h)', _buildLineChart(null)),
        const SizedBox(height: 60),
      ],
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
              color: CupertinoColors.systemGrey,
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

  Widget _buildLineChart(List<dynamic>? points) {
    if (points == null || points.isEmpty) return const SizedBox();
    List<FlSpot> spots = [];
    for (int i = 0; i < points.length; i++) {
      spots.add(
        FlSpot(i.toDouble(), (points[i]['value'] as num).toDouble() / 1000000),
      );
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
            color: CupertinoColors.systemIndigo,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  CupertinoColors.systemIndigo.withValues(alpha: 0.4),
                  CupertinoColors.systemIndigo.withValues(alpha: 0.0),
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
          value: (slice['value'] as num).toDouble(),
          title: '${slice['label']}\n${slice['value']}%',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.white,
          ),
        ),
      );
    }
    return PieChart(
      PieChartData(sectionsSpace: 4, centerSpaceRadius: 30, sections: sections),
    );
  }
}
