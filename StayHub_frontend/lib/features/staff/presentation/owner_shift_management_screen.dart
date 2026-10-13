import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:stayhub_frontend/core/theme/app_theme.dart';
import 'package:stayhub_frontend/core/components/glass_container.dart';
import 'package:stayhub_frontend/core/network/api_client.dart';
import 'package:stayhub_frontend/core/utils/toast_utils.dart';
import 'package:stayhub_frontend/features/staff/data/models/shift_model.dart';
import 'dart:async';

class OwnerShiftManagementScreen extends StatefulWidget {
  const OwnerShiftManagementScreen({super.key});

  @override
  State<OwnerShiftManagementScreen> createState() =>
      _OwnerShiftManagementScreenState();
}

class _OwnerShiftManagementScreenState
    extends State<OwnerShiftManagementScreen> {
  final ApiClient _apiClient = ApiClient();
  List<ShiftModel> _shifts = [];
  bool _isLoading = true;
  final int _branchId = 1; // Mock branch ID

  @override
  void initState() {
    super.initState();
    unawaited(_fetchShifts());
  }

  Future<void> _fetchShifts() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.dio.get(
        '/v1/staff-shifts/branch/$_branchId',
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        setState(() {
          _shifts = data.map((j) => ShiftModel.fromJson(j)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) ToastUtils.show(context, 'Lỗi tải danh sách ca: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteShift(int id) async {
    try {
      final response = await _apiClient.dio.delete('/v1/staff-shifts/$id');
      if (response.statusCode == 200) {
        if (mounted) {
          ToastUtils.show(context, 'Đã xoá ca làm việc', isError: false);
        }
        unawaited(_fetchShifts());
      }
    } catch (e) {
      if (mounted) ToastUtils.show(context, 'Lỗi xoá ca: $e');
    }
  }

  void _showAddShiftModal() {
    // Mock UI for adding a shift
    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Phân công ca làm việc',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextFormField(
                initialValue: 'Ca Sáng',
                decoration: const InputDecoration(
                  labelText: 'Tên Ca (VD: Ca Sáng)',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  // Mock API Call
                  try {
                    await _apiClient.dio.post(
                      '/v1/staff-shifts',
                      data: {
                        "branchId": _branchId,
                        "staffId": 1, // Mock staff
                        "title": "Ca Sáng",
                        "startTime": DateTime.now().toIso8601String(),
                        "endTime": DateTime.now()
                            .add(const Duration(hours: 8))
                            .toIso8601String(),
                        "status": "SCHEDULED",
                      },
                    );
                    if (mounted) {
                      ToastUtils.show(
                        context,
                        'Thêm ca thành công',
                        isError: false,
                      );
                    }
                    unawaited(_fetchShifts());
                  } catch (e) {
                    if (mounted) ToastUtils.show(context, 'Lỗi: $e');
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: AppTheme.kBrand,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Lưu Ca Làm Việc'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShiftCard(ShiftModel shift) {
    Color statusColor;
    switch (shift.status) {
      case 'IN_PROGRESS':
        statusColor = AppTheme.kBrand;
        break;
      case 'COMPLETED':
        statusColor = AppTheme.kSuccess;
        break;
      case 'ABSENT':
        statusColor = AppTheme.kError;
        break;
      default:
        statusColor = AppTheme.kWarning;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        border: Border.all(color: AppTheme.kBorderColor),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  shift.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.kTextPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    shift.status,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  CupertinoIcons.clock,
                  size: 16,
                  color: AppTheme.kTextSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${shift.startTime.substring(11, 16)} - ${shift.endTime.substring(11, 16)}',
                  style: const TextStyle(color: AppTheme.kTextSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(
                    CupertinoIcons.trash,
                    color: AppTheme.kError,
                  ),
                  onPressed: () => _deleteShift(shift.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.kBackgroundLight,
      appBar: AppBar(
        title: const Text('Quản lý Lịch trực'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              CupertinoIcons.add_circled_solid,
              color: AppTheme.kBrand,
            ),
            onPressed: _showAddShiftModal,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _shifts.isEmpty
          ? const Center(
              child: Text(
                'Chưa có ca làm việc nào',
                style: TextStyle(color: AppTheme.kTextSecondary),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchShifts,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _shifts.length,
                itemBuilder: (context, index) =>
                    _buildShiftCard(_shifts[index]),
              ),
            ),
    );
  }
}
