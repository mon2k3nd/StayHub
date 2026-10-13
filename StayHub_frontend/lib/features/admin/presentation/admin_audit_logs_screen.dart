import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/components/app_error_widget.dart';

// 1. Cập nhật Provider hỗ trợ Filter
final adminAuditLogsProvider = FutureProvider.autoDispose
    .family<List<dynamic>, String>((ref, filterType) async {
      final client = ref.watch(apiClientProvider);

      // Xây dựng query params
      String query = '/v1/admin/audit-logs';
      if (filterType != 'ALL') {
        query += '?entityType=$filterType';
      }

      final response = await client.get(query);
      if (response['success'] == true) {
        // BUGFIX (data): tránh `as List<dynamic>` ném TypeError khi `data`
        // null/không phải List — trả [] để màn hình không vỡ.
        final raw = response['data'];
        return raw is List ? raw : const <dynamic>[];
      }
      return [];
    });

class AdminAuditLogsScreen extends ConsumerStatefulWidget {
  const AdminAuditLogsScreen({super.key});

  @override
  ConsumerState<AdminAuditLogsScreen> createState() =>
      _AdminAuditLogsScreenState();
}

class _AdminAuditLogsScreenState extends ConsumerState<AdminAuditLogsScreen> {
  String _selectedFilter = 'ALL';
  String _searchQuery = '';

  final List<Map<String, String>> _filters = [
    {'id': 'ALL', 'label': 'Tất cả'},
    {'id': 'BRANCH', 'label': 'Chi nhánh'},
    {'id': 'ROOM', 'label': 'Phòng'},
    {'id': 'USER', 'label': 'Khách thuê'},
    {'id': 'CONTRACT', 'label': 'Hợp đồng'},
    {'id': 'EQUIPMENT', 'label': 'Thiết bị'},
  ];

  Color _getTypeColor(String type) {
    switch (type) {
      case 'DANGER':
        return CupertinoColors.destructiveRed;
      case 'WARNING':
        return CupertinoColors.activeOrange;
      case 'SUCCESS':
        return CupertinoColors.activeGreen;
      case 'INFO':
      default:
        return CupertinoColors.activeBlue;
    }
  }

  String _formatTime(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} ${dt.day}/${dt.month}';
    } catch (e) {
      return isoTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(adminAuditLogsProvider(_selectedFilter));

    return LiquidGlassScaffold(
      title: 'Trung tâm Truy vết',
      backgroundColors: AppTheme.kBackgroundLight,
      useScrollView: false,
      child: Column(
        children: [
          // Header Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: CupertinoColors.systemGrey6,
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.circle_fill,
                  size: 12,
                  color: CupertinoColors.activeGreen,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Master Audit Center (Real-time)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.black,
                  ),
                ),
                const Spacer(),
                Text(
                  'Filter: $_selectedFilter',
                  style: const TextStyle(
                    fontSize: 10,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: CupertinoSearchTextField(
              placeholder: 'Tìm kiếm ID, tên người dùng, hành động...',
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Horizontal Filter Bar
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter['id'];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter['id']!;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.kBrand : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.kBrand
                              : CupertinoColors.systemGrey4,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.kBrand.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          filter['label']!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : CupertinoColors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Log List
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh: () async {
                    ref.invalidate(adminAuditLogsProvider(_selectedFilter));
                  },
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: logsAsync.when(
                    data: (logs) {
                      // Apply search filter locally
                      var filteredLogs = logs;
                      if (_searchQuery.isNotEmpty) {
                        filteredLogs = logs.where((log) {
                          final action = (log['action'] ?? '')
                              .toString()
                              .toLowerCase();
                          final user = (log['admin']?['fullName'] ?? 'Admin')
                              .toString()
                              .toLowerCase();
                          final changes = (log['changes'] ?? '')
                              .toString()
                              .toLowerCase();
                          return action.contains(_searchQuery) ||
                              user.contains(_searchQuery) ||
                              changes.contains(_searchQuery);
                        }).toList();
                      }

                      if (filteredLogs.isEmpty) {
                        return const SliverFillRemaining(
                          child: Center(
                            child: Text('Chưa có lịch sử truy vết phù hợp.'),
                          ),
                        );
                      }

                      return SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final log = filteredLogs[index];
                          String action = log['action'] ?? '';
                          String type = 'INFO';
                          if (action.toUpperCase().contains('DELETE') ||
                              action.toUpperCase().contains('UNBAN')) {
                            type = 'DANGER';
                          }
                          if (action.toUpperCase().contains('CREATE')) {
                            type = 'SUCCESS';
                          }

                          final color = _getTypeColor(type);
                          final entityType =
                              log['entityType'] ?? _selectedFilter;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GlassContainer(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Time Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: color.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          CupertinoIcons.clock_fill,
                                          size: 14,
                                          color: color,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatTime(log['createdAt'] ?? ''),
                                          style: TextStyle(
                                            color: color,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              log['admin']?['fullName'] ??
                                                  'Hệ thống / Admin',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                                color: CupertinoColors.black,
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    CupertinoColors.systemGrey5,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                entityType,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: CupertinoColors
                                                      .systemGrey,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          action,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: CupertinoColors.black,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),

                                        if (log['changes'] != null) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(
                                                alpha: 0.5,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color:
                                                    CupertinoColors.systemGrey5,
                                              ),
                                            ),
                                            child: Text(
                                              log['changes'],
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color:
                                                    CupertinoColors.systemGrey,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],

                                        if (log['targetId'] != null)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 8,
                                            ),
                                            child: Text(
                                              'ID Đối tượng: ${log['targetId']}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color:
                                                    CupertinoColors.activeBlue,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }, childCount: filteredLogs.length),
                      );
                    },
                    loading: () => const SliverFillRemaining(
                      child: Center(child: CupertinoActivityIndicator()),
                    ),
                    error: (err, _) =>
                        SliverFillRemaining(child: AppErrorWidget(error: err)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
