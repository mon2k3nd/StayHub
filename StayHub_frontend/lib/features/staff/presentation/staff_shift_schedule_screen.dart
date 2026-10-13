import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:stayhub_frontend/core/theme/app_theme.dart';
import 'package:stayhub_frontend/core/components/glass_container.dart';
import 'package:stayhub_frontend/core/network/api_client.dart';
import 'package:stayhub_frontend/core/utils/toast_utils.dart';
import 'package:stayhub_frontend/features/staff/data/models/shift_model.dart';
import 'dart:async';

class StaffShiftScheduleScreen extends StatefulWidget {
  const StaffShiftScheduleScreen({super.key});

  @override
  State<StaffShiftScheduleScreen> createState() =>
      _StaffShiftScheduleScreenState();
}

class _StaffShiftScheduleScreenState extends State<StaffShiftScheduleScreen> {
  final ApiClient _apiClient = ApiClient();
  List<ShiftModel> _shifts = [];
  bool _isLoading = true;
  final int _staffId = 1; // Mock staff ID

  @override
  void initState() {
    super.initState();
    unawaited(_fetchShifts());
  }

  Future<void> _fetchShifts() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.dio.get(
        '/v1/staff-shifts/staff/$_staffId',
      );
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['data'];
        setState(() {
          _shifts = data.map((j) => ShiftModel.fromJson(j)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) ToastUtils.show(context, 'Lỗi tải lịch làm việc: $e');
      setState(() => _isLoading = false);
    }
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
        color: statusColor.withValues(alpha: 0.05),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
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
                  style: const TextStyle(
                    color: AppTheme.kTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  shift.startTime.substring(0, 10),
                  style: const TextStyle(
                    color: AppTheme.kTextMuted,
                    fontSize: 12,
                  ),
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
        title: const Text('Lịch Làm Việc Của Tôi'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _shifts.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.calendar_today,
                    size: 64,
                    color: AppTheme.kTextMuted,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Bạn chưa có ca làm việc nào được phân công',
                    style: TextStyle(color: AppTheme.kTextSecondary),
                  ),
                ],
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
