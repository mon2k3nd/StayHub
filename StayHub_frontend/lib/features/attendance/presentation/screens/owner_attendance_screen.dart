import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/components/glass_container.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../../core/network/api_client.dart';
import 'dart:async' show unawaited;

class OwnerAttendanceScreen extends ConsumerStatefulWidget {
  const OwnerAttendanceScreen({super.key});

  @override
  ConsumerState<OwnerAttendanceScreen> createState() =>
      _OwnerAttendanceScreenState();
}

class _OwnerAttendanceScreenState extends ConsumerState<OwnerAttendanceScreen> {
  bool _isLoading = true;
  List<dynamic> _logs = [];
  late ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    unawaited(_fetchLogs());
  }

  Future<void> _fetchLogs() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.dio.get('/v1/attendance/logs');
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          _logs = response.data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) ToastUtils.show(context, 'Lỗi tải lịch sử chấm công: $e');
      setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ON_TIME':
        return AppTheme.kSuccess;
      case 'LATE':
        return AppTheme.kWarning;
      case 'INVALID_LOCATION':
        return AppTheme.kError;
      default:
        return AppTheme.kTextMuted;
    }
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final status = log['status'] ?? 'UNKNOWN';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        border: Border.all(color: AppTheme.kBorderColor),
        color: AppTheme.kSurface1Light,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  log['checkInTime']?.substring(0, 10) ?? 'N/A',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Check-in',
                        style: TextStyle(
                          color: AppTheme.kTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        log['checkInTime']?.substring(11, 16) ?? '--:--',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        log['checkInLocation'] ?? 'Không rõ',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 40, color: AppTheme.kBorderColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Check-out',
                        style: TextStyle(
                          color: AppTheme.kTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        log['checkOutTime']?.substring(11, 16) ?? '--:--',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        log['checkOutLocation'] ?? 'Chưa check-out',
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
        title: const Text('Lịch sử chấm công'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
          ? const Center(child: Text('Chưa có dữ liệu chấm công'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              itemBuilder: (context, index) => _buildLogCard(_logs[index]),
            ),
    );
  }
}
