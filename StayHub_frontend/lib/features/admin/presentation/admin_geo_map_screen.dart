import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/components/glass_container.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/osm_map_service.dart';
import '../application/admin_geo_analytics_provider.dart';
import 'dart:async' show unawaited;

class AdminGeoMapScreen extends ConsumerWidget {
  const AdminGeoMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final geoAsync = ref.watch(adminGeoAnalyticsProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.kBackgroundLightGray,
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Bản Đồ Phân Bổ BĐS',
          style: TextStyle(color: CupertinoColors.black),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: CupertinoColors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: geoAsync.when(
          data: (data) => _buildContent(context, data),
          loading: () => _buildSkeletonLoading(),
          error: (err, stack) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  CupertinoIcons.exclamationmark_triangle,
                  color: CupertinoColors.systemRed,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Lỗi: $err',
                  style: const TextStyle(color: CupertinoColors.systemRed),
                ),
                const SizedBox(height: 16),
                CupertinoButton.filled(
                  child: const Text('Thử lại'),
                  onPressed: () => ref.invalidate(adminGeoAnalyticsProvider),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Map<String, dynamic> data) {
    // BUGFIX (data): tránh `as Map`/`as List` ném TypeError khi dữ liệu không
    // đúng kiểu — chỉ nhận khi thực sự đúng kiểu.
    final summary = data['summary'] is Map
        ? Map<String, dynamic>.from(data['summary'] as Map)
        : <String, dynamic>{};
    final regions = data['regions'] is List
        ? (data['regions'] as List).whereType<Map>().toList()
        : <Map>[];
    final insights = data['actionableInsights'] is List
        ? (data['actionableInsights'] as List).whereType<Map>().toList()
        : <Map>[];

    return Column(
      children: [
        SizedBox(
          height: 350,
          child: Stack(
            children: [
              Positioned.fill(
                child: FlutterMap(
                  options: const MapOptions(
                    initialCenter: LatLng(
                      10.7769,
                      106.7009,
                    ), // Center on HCM City
                    initialZoom: 12.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: OsmMapService.tileUrl,
                      subdomains: OsmMapService.tileSubdomains,
                      userAgentPackageName: 'com.stayhub.admin',
                    ),
                    MarkerLayer(
                      markers: regions.map((region) {
                        // BUGFIX (data): coerce lat/lng an toàn — tránh
                        // TypeError khi JSON lỗi kiểu. `regions` đã được lọc
                        // qua whereType<Map>() nên phần tử luôn là Map.
                        final regMap = Map<String, dynamic>.from(region);
                        final coords = regMap['coordinates'] is Map
                            ? Map<String, dynamic>.from(
                                regMap['coordinates'] as Map,
                              )
                            : <String, dynamic>{};
                        final lat = coords['lat'] is num
                            ? (coords['lat'] as num).toDouble()
                            : 0.0;
                        final lng = coords['lng'] is num
                            ? (coords['lng'] as num).toDouble()
                            : 0.0;
                        final rawStatus = regMap['status'];
                        final color = _getStatusColor(
                          rawStatus is String ? rawStatus : 'NORMAL',
                        );

                        return Marker(
                          point: LatLng(lat, lng),
                          width: 40,
                          height: 40,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Icon(
                                CupertinoIcons.location_solid,
                                color: color,
                                size: 28,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        CupertinoIcons.flame_fill,
                        color: CupertinoColors.destructiveRed,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Khu vực nóng nhất',
                              style: TextStyle(
                                fontSize: 12,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                            Text(
                              summary['hottestRegion'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: CupertinoColors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (insights.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 8.0,
            ),
            child: _buildActionableInsights(context, insights),
          ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'THỐNG KÊ THEO KHU VỰC',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: regions.length,
            itemBuilder: (context, index) {
              // BUGFIX (data): coerce an toàn — `regions` đã được lọc qua
              // whereType<Map>() nên phần tử luôn là Map.
              final region = Map<String, dynamic>.from(regions[index]);
              final rawStatus = region['status'];
              final color = _getStatusColor(
                rawStatus is String ? rawStatus : 'NORMAL',
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.placemark_fill,
                        color: color,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              region['name'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: CupertinoColors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${region['roomCount']} phòng',
                              style: const TextStyle(
                                color: CupertinoColors.systemGrey,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Giá TB: ${_formatMoney((region['averagePrice'] as num?)?.toDouble() ?? 0)}',
                              style: const TextStyle(
                                color: CupertinoColors.systemGrey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              region['status'] ?? '',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${(region['occupancyRate'] as num?)?.toDouble() ?? 0}% Kín',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: CupertinoColors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionableInsights(
    BuildContext context,
    List<dynamic> insights,
  ) {
    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      children: insights.map((insight) {
        final message = insight['message'] as String?;
        final actionText = insight['actionText'] as String?;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
            border: Border.all(
              color: CupertinoColors.systemBlue.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                CupertinoIcons.sparkles,
                color: CupertinoColors.systemBlue,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message ?? '',
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
              if (actionText != null)
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  color: CupertinoColors.systemBlue,
                  borderRadius: BorderRadius.circular(8),
                  minimumSize: Size.zero,
                  onPressed: () => _showSuccessOverlay(context),
                  child: Text(
                    actionText,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showSuccessOverlay(BuildContext context) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Marketing'),
          content: const Text(
            'Đã kích hoạt chiến dịch Marketing ưu đãi tại khu vực này.',
          ),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'VERY HOT':
        return CupertinoColors.destructiveRed;
      case 'HOT':
        return CupertinoColors.activeOrange;
      case 'WARM':
        return CupertinoColors.systemYellow;
      case 'COLD':
        return CupertinoColors.systemTeal;
      case 'NORMAL':
      default:
        return CupertinoColors.systemGrey;
    }
  }

  Widget _buildSkeletonLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          Container(
            height: 150,
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: 4,
              itemBuilder: (context, index) {
                return Container(
                  height: 80,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatMoney(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}B đ';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M đ';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k đ';
    }
    return '${amount.toStringAsFixed(0)} đ';
  }
}
