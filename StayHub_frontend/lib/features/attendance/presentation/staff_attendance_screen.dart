import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/glass_button.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../application/attendance_notifier.dart';
import '../../staff/application/staff_assignment_notifier.dart';
import '../../../core/components/app_error_widget.dart';
import 'dart:async' show unawaited;

class StaffAttendanceScreen extends ConsumerStatefulWidget {
  const StaffAttendanceScreen({super.key});

  @override
  ConsumerState<StaffAttendanceScreen> createState() =>
      _StaffAttendanceScreenState();
}

class _StaffAttendanceScreenState extends ConsumerState<StaffAttendanceScreen> {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      title: 'Chấm Công (GPS)',
      backgroundColors: AppTheme.kBackgroundLight,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              ref.invalidate(currentAttendanceStatusProvider);
              ref.invalidate(myAttendanceLogsProvider);
              ref.invalidate(staffAssignmentProvider);
              await ref.read(currentAttendanceStatusProvider.future);
            },
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHeader(),
                const SizedBox(height: 32),
                _buildActionPanel(),
                const SizedBox(height: 32),
                _buildHistoryLogs(),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chấm công định vị',
          style: TextStyle(
            color: CupertinoColors.black,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Hệ thống sẽ lấy tọa độ hiện tại của bạn để so khớp với vị trí chi nhánh. Yêu cầu bật GPS.',
          style: TextStyle(
            color: CupertinoColors.black.withValues(alpha: 0.6),
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildActionPanel() {
    final statusAsync = ref.watch(currentAttendanceStatusProvider);

    return statusAsync.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, _) => AppErrorWidget(error: e),
      data: (status) {
        if (status == null) {
          // Chưa check-in -> Hiển thị nút Check-in và chọn chi nhánh
          return _buildCheckInView();
        } else {
          // Đã check-in -> Hiển thị nút Check-out
          return _buildCheckOutView(status);
        }
      },
    );
  }

  Widget _buildCheckInView() {
    final assignmentState = ref.watch(staffAssignmentProvider);

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                CupertinoIcons.location_solid,
                color: CupertinoColors.systemBlue,
              ),
              SizedBox(width: 8),
              Text(
                'Bạn chưa bắt đầu ca làm việc',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (assignmentState.isLoading)
            const CupertinoActivityIndicator()
          else if (assignmentState.error != null)
            Text('Lỗi tải chi nhánh: ${assignmentState.error}')
          else if (assignmentState.assignments.isEmpty)
            const Text('Chưa được phân công chi nhánh nào.')
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Chọn chi nhánh đang làm việc:',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                ...assignmentState.assignments.map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassButton(
                      text: 'Check-in tại ${b.branchName}',
                      icon: CupertinoIcons.check_mark_circled_solid,
                      onPressed: () {
                        unawaited(
                          ref
                              .read(attendanceProvider.notifier)
                              .checkIn(context, b.branchId),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildCheckOutView(dynamic status) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.clock_fill,
                color: CupertinoColors.systemGreen,
              ),
              const SizedBox(width: 8),
              const Text(
                'Đang trong ca làm việc',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const Spacer(),
              _buildStatusBadge(status.status ?? 'VALID'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Chi nhánh: ${status.branchName}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Giờ vào: ${_dateFormat.format(status.checkInTime!)}',
            style: const TextStyle(
              fontSize: 15,
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sai số khoảng cách: ${status.distanceMeters?.toStringAsFixed(1) ?? 'N/A'} mét',
            style: const TextStyle(
              fontSize: 14,
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 24),
          GlassButton(
            text: 'Check-out (Kết thúc ca)',
            icon: CupertinoIcons.clear_circled_solid,
            color: CupertinoColors.systemRed,
            onPressed: () {
              unawaited(
                ref.read(attendanceProvider.notifier).checkOut(context),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryLogs() {
    final logsAsync = ref.watch(myAttendanceLogsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LỊCH SỬ CHẤM CÔNG',
          style: TextStyle(
            color: Color(0xFF4B5563),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        logsAsync.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e, _) => AppErrorWidget(error: e),
          data: (logs) {
            if (logs.isEmpty) {
              return const Center(
                child: Text(
                  'Chưa có lịch sử chấm công.',
                  style: TextStyle(color: CupertinoColors.systemGrey),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final log = logs[i];
                return GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey5,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          CupertinoIcons.calendar_today,
                          color: CupertinoColors.systemGrey,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.branchName ?? 'Không rõ CN',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Vào: ${_dateFormat.format(log.checkInTime!)}',
                              style: const TextStyle(
                                color: Color(0xFF1A6FD4),
                                fontSize: 13,
                              ),
                            ),
                            if (log.checkOutTime != null)
                              Text(
                                'Ra: ${_dateFormat.format(log.checkOutTime!)}',
                                style: const TextStyle(
                                  color: CupertinoColors.systemGrey,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(log.status ?? 'VALID'),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'VALID':
      case 'ON_TIME':
        color = CupertinoColors.systemGreen;
        label = 'Hợp lệ';
        break;
      case 'INVALID_LOCATION':
        color = CupertinoColors.systemRed;
        label = 'Sai vị trí';
        break;
      case 'NO_BRANCH_LOCATION':
      case 'NO_GPS_PROVIDED':
        color = CupertinoColors.systemOrange;
        label = 'Thiếu GPS';
        break;
      default:
        color = CupertinoColors.systemGrey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
