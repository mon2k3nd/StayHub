import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/providers/core_providers.dart';
import 'dart:async' show unawaited;

class MeterHistoryScreen extends ConsumerStatefulWidget {
  final int branchId;
  const MeterHistoryScreen({super.key, required this.branchId});

  @override
  ConsumerState<MeterHistoryScreen> createState() => _MeterHistoryScreenState();
}

class _MeterHistoryScreenState extends ConsumerState<MeterHistoryScreen>
    with SingleTickerProviderStateMixin {
  int _selectedTab = 0;
  bool _loading = true;
  List<Map<String, dynamic>> _roomBills = [];
  List<Map<String, dynamic>> _masterMeters = [];

  @override
  void initState() {
    super.initState();
    unawaited(_loadData());
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final results = await Future.wait([
        // Bills tổng hợp cho branch (lấy từ API tổng hợp tháng hiện tại ± 5 tháng)
        dio.get('/v1/branch-meters/${widget.branchId}/history'),
        // Master meters
        dio.get('/v1/branch-meters/${widget.branchId}/history'),
      ]);
      // NOTE: Cả 2 tab dùng cùng endpoint `/history` trả về list BranchMeter
      // Room bills tab: Đọc bills từ branchId bills-by-month endpoint
      final billsResp = await dio.get(
        '/v1/bills',
        queryParameters: {'branchId': widget.branchId},
      );
      // BUGFIX (data): tránh `as Map<String, dynamic>` ném TypeError khi phần
      // tử không phải Map (ví dụ String/số) — lọc an toàn bằng whereType.
      final bills = (billsResp.data is List ? billsResp.data as List : const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final masterData = (results[0].data is List)
          ? (results[0].data as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
          : <Map<String, dynamic>>[];

      if (mounted) {
        setState(() {
          _roomBills = bills;
          _masterMeters = masterData;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      title: 'Lịch sử Đồng hồ',
      useScrollView: false,
      child: Column(
        children: [
          // Tab selector
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildTab('🏠 Theo Phòng', 0),
                  _buildTab('🏢 Đồng hồ Tổng', 1),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CupertinoActivityIndicator())
                : _selectedTab == 0
                ? _buildRoomBillsTab()
                : _buildMasterMeterTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final sel = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: sel ? CupertinoColors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: sel
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
              color: sel ? const Color(0xFF111827) : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoomBillsTab() {
    if (_roomBills.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📋', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text(
              'Chưa có dữ liệu hóa đơn',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ],
        ),
      );
    }

    // Group by month/year
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final bill in _roomBills) {
      final key = '${bill['month'] ?? '?'}/${bill['year'] ?? '?'}';
      grouped.putIfAbsent(key, () => []).add(bill);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: grouped.length,
      itemBuilder: (context, i) {
        final monthKey = grouped.keys.elementAt(i);
        final monthBills = grouped[monthKey]!;
        return _buildMonthSection(monthKey, monthBills);
      },
    );
  }

  Widget _buildMonthSection(String monthKey, List<Map<String, dynamic>> bills) {
    double totalElec = 0;
    double totalWater = 0;
    for (final b in bills) {
      final eCurrent = (b['electricCurrent'] as num?)?.toDouble() ?? 0;
      final ePrev = (b['electricPrevious'] as num?)?.toDouble() ?? 0;
      final wCurrent = (b['waterCurrent'] as num?)?.toDouble() ?? 0;
      final wPrev = (b['waterPrevious'] as num?)?.toDouble() ?? 0;
      totalElec += (eCurrent - ePrev).clamp(0, double.infinity);
      totalWater += (wCurrent - wPrev).clamp(0, double.infinity);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9CA3AF).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF298FFF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tháng $monthKey',
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${bills.length} phòng',
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildMiniStat(
                  '⚡',
                  'Tổng điện',
                  '${totalElec.toStringAsFixed(1)} kWh',
                ),
                const SizedBox(width: 12),
                _buildMiniStat(
                  '💧',
                  'Tổng nước',
                  '${totalWater.toStringAsFixed(1)} m³',
                ),
              ],
            ),
          ),
          ...bills.take(5).map((bill) => _buildRoomBillRow(bill)),
          if (bills.length > 5)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '... và ${bills.length - 5} phòng khác',
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRoomBillRow(Map<String, dynamic> bill) {
    final eCurrent = (bill['electricCurrent'] as num?)?.toDouble() ?? 0;
    final ePrev = (bill['electricPrevious'] as num?)?.toDouble() ?? 0;
    final wCurrent = (bill['waterCurrent'] as num?)?.toDouble() ?? 0;
    final wPrev = (bill['waterPrevious'] as num?)?.toDouble() ?? 0;
    final elecUsed = (eCurrent - ePrev).clamp(0, double.infinity).toDouble();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              CupertinoIcons.house,
              size: 18,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill['roomName'] ?? 'Phòng #${bill['roomId']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '⚡ ${ePrev.toInt()} → ${eCurrent.toInt()} (${elecUsed.toStringAsFixed(0)} kWh)  💧 ${wPrev.toInt()} → ${wCurrent.toInt()}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterMeterTab() {
    if (_masterMeters.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📊', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text(
              'Chưa có dữ liệu đồng hồ tổng',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
            SizedBox(height: 4),
            Text(
              'Hãy nhập chỉ số qua màn hình\nBáo cáo Thất Thoát.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _masterMeters.length,
      itemBuilder: (context, i) {
        final m = _masterMeters[i];
        final month = m['month'] ?? '?';
        final year = m['year'] ?? '?';
        final elecCurrent =
            (m['electricMasterCurrent'] as num?)?.toDouble() ?? 0;
        final elecPrev = (m['electricMasterPrevious'] as num?)?.toDouble() ?? 0;
        final waterCurrent = (m['waterMasterCurrent'] as num?)?.toDouble() ?? 0;
        final waterPrev = (m['waterMasterPrevious'] as num?)?.toDouble() ?? 0;
        final elecUsed = (elecCurrent - elecPrev)
            .clamp(0, double.infinity)
            .toDouble();
        final waterUsed = (waterCurrent - waterPrev)
            .clamp(0, double.infinity)
            .toDouble();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9CA3AF).withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tháng $month/$year',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMeterReadingCard(
                      '⚡ Điện',
                      elecPrev,
                      elecCurrent,
                      elecUsed,
                      'kWh',
                      const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMeterReadingCard(
                      '💧 Nước',
                      waterPrev,
                      waterCurrent,
                      waterUsed,
                      'm³',
                      const Color(0xFF298FFF),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMeterReadingCard(
    String label,
    double prev,
    double current,
    double used,
    String unit,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${prev.toStringAsFixed(1)} → ${current.toStringAsFixed(1)}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF374151)),
          ),
          Text(
            'Dùng: ${used.toStringAsFixed(1)} $unit',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
