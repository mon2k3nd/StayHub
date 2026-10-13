import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/components/glass_container.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/complaint_model.dart';
import 'owner_complaint_detail_screen.dart';
import 'dart:async' show unawaited;

class OwnerComplaintListScreen extends ConsumerStatefulWidget {
  final int branchId;
  const OwnerComplaintListScreen({super.key, required this.branchId});

  @override
  ConsumerState<OwnerComplaintListScreen> createState() =>
      _OwnerComplaintListScreenState();
}

class _OwnerComplaintListScreenState
    extends ConsumerState<OwnerComplaintListScreen> {
  bool _isLoading = true;
  List<ComplaintModel> _complaints = [];
  String _selectedStatus = 'ALL';
  late ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    unawaited(_fetchComplaints());
    _subscribeSSE();
  }

  @override
  void dispose() {
    SSEClient.unsubscribeFromSSE();
    super.dispose();
  }

  Future<void> _fetchComplaints() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.dio.get(
        '/v1/complaints/branch/${widget.branchId}',
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        setState(() {
          _complaints = data.map((e) => ComplaintModel.fromJson(e)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) ToastUtils.show(context, 'Lỗi tải danh sách: $e');
      setState(() => _isLoading = false);
    }
  }

  void _subscribeSSE() {
    const userId = 1; // MOCK USER ID

    SSEClient.subscribeToSSE(
      method: SSERequestType.GET,
      url:
          '${ApiClient.baseUrl}/v1/complaints/stream/branch/${widget.branchId}?userId=$userId',
      header: {
        "Accept": "text/event-stream",
        "Cache-Control": "no-cache",
        "Authorization": "Bearer MOCK_TOKEN",
      },
    ).listen((event) {
      if (event.event == 'NEW_COMPLAINT' ||
          event.event == 'COMPLAINT_UPDATED') {
        if (event.data != null && event.data!.isNotEmpty) {
          try {
            final data = json.decode(event.data!);
            final updated = ComplaintModel.fromJson(data);
            setState(() {
              final idx = _complaints.indexWhere((c) => c.id == updated.id);
              if (idx >= 0) {
                _complaints[idx] = updated;
              } else {
                _complaints.insert(0, updated);
              }
            });
            if (event.event == 'NEW_COMPLAINT') {
              if (!mounted) return;
              ToastUtils.show(
                context,
                'Có phản ánh mới từ phòng ${updated.roomName}',
                isError: false,
              );
            }
          } catch (_) {}
        }
      }
    });
  }

  Widget _buildFilterChips() {
    final statuses = [
      {'id': 'ALL', 'name': 'Tất cả'},
      {'id': 'PENDING', 'name': 'Chờ xử lý'},
      {'id': 'PROCESSING', 'name': 'Đang xử lý'},
      {'id': 'RESOLVED', 'name': 'Đã giải quyết'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: statuses.map((s) {
          final isSelected = _selectedStatus == s['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                s['name']!,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.kTextPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              selectedColor: AppTheme.kBrand,
              backgroundColor: AppTheme.kSurface1Light,
              onSelected: (val) {
                if (val) {
                  setState(() => _selectedStatus = s['id']!);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'URGENT':
        return AppTheme.kError;
      case 'HIGH':
        return AppTheme.kWarning;
      case 'LOW':
        return AppTheme.kSuccess;
      default:
        return AppTheme.kBrand;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return AppTheme.kWarning;
      case 'PROCESSING':
        return AppTheme.kBrand;
      case 'RESOLVED':
        return AppTheme.kSuccess;
      case 'REJECTED':
        return AppTheme.kTextMuted;
      default:
        return AppTheme.kTextPrimary;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'PENDING':
        return 'Chờ xử lý';
      case 'PROCESSING':
        return 'Đang xử lý';
      case 'RESOLVED':
        return 'Đã giải quyết';
      case 'REJECTED':
        return 'Từ chối';
      default:
        return status;
    }
  }

  Widget _buildComplaintCard(ComplaintModel complaint) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) =>
                    OwnerComplaintDetailScreen(complaint: complaint),
              ),
            );
            // unawaited(Refresh on pop)
            unawaited(_fetchComplaints());
          },
          child: Hero(
            tag: 'complaint_${complaint.id}',
            child: GlassContainer(
              padding: const EdgeInsets.all(12),
              border: Border.all(color: AppTheme.kBorderColor),
              color: AppTheme.kSurface1Light,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getPriorityColor(
                            complaint.priority,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          complaint.priority,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _getPriorityColor(complaint.priority),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            complaint.status,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          _getStatusText(complaint.status),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(complaint.status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    complaint.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.kTextPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.person_solid,
                        size: 14,
                        color: AppTheme.kTextSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${complaint.tenantName} - Phòng ${complaint.roomName ?? "N/A"}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.time,
                        size: 14,
                        color: AppTheme.kTextMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        complaint.createdAt
                            .substring(0, 16)
                            .replaceFirst('T', ' '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.kTextMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedStatus == 'ALL'
        ? _complaints
        : _complaints.where((c) => c.status == _selectedStatus).toList();

    return Scaffold(
      backgroundColor: AppTheme.kBackgroundLight,
      appBar: AppBar(
        title: const Text('Phản ánh & Khiếu nại'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _buildFilterChips(),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? const Center(child: Text('Không có phản ánh nào'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _buildComplaintCard(filtered[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
