import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/premium_empty_state_widget.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/liquid_background.dart';
import '../../../core/components/bounce_click.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/staff_assignment_notifier.dart';
import '../../ticket/presentation/ticket_screen.dart';
import '../../ticket/application/ticket_provider.dart';
import '../../../core/enums/ticket_status.dart';
import 'staff_permission_screen.dart';
import '../../attendance/application/attendance_notifier.dart';

import '../../room/presentation/rent_out_room_screen.dart';
import '../../dashboard/presentation/vehicle_management_screen.dart';
import '../../dashboard/presentation/ct01_export_screen.dart';
import '../../room/presentation/record_utilities_screen.dart';
import '../../bill/presentation/generate_bill_screen.dart';
import '../application/housekeeping_notifier.dart';
import 'housekeeping_screen.dart';
import 'dart:async' show unawaited;

// ─────────────────────────────────────────────
// Staff Dashboard – Cupertino iOS 26 Liquid Glass
// Giao diện vận hành dành cho nhân viên bảo trì/thu phí
// ─────────────────────────────────────────────
class StaffDashboard extends ConsumerStatefulWidget {
  const StaffDashboard({super.key});

  @override
  ConsumerState<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends ConsumerState<StaffDashboard> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: LiquidBackground(
        colors: AppTheme.kBackgroundLight,
        child: Stack(
          children: [
            Positioned.fill(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  _buildTasksTab(),
                  const TicketScreen(),
                  _buildHistoryTab(),
                  _buildProfileTab(),
                ],
              ),
            ),

            // Thanh Bottom Bar nổi
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 24,
              right: 24,
              child: _buildFloatingNavBar(ref.watch(staffAssignmentProvider)),
            ),
          ],
        ),
      ),
    );
  }

  // Tab Danh sách nhiệm vụ thực địa
  Widget _buildTasksTab() {
    final assignmentState = ref.watch(staffAssignmentProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        CupertinoSliverNavigationBar(
          largeTitle: const Text(
            'Vận Hành',
            style: TextStyle(color: CupertinoColors.black),
          ),
          backgroundColor: const Color(0x00000000),
          border: null,
          transitionBetweenRoutes: false,
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(
              CupertinoIcons.qrcode_viewfinder,
              color: LiquidGlassColors.staffAccent,
            ),
            onPressed: () =>
                context.push('/qr_cash_scanner'), // Quét QR thanh toán/nộp tiền
          ),
        ),
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            ref.invalidate(staffAssignmentProvider);
            unawaited(ref.read(ticketProvider.notifier).refresh());
          },
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (assignmentState.isLoading)
                const Center(child: CupertinoActivityIndicator())
              else if (assignmentState.error != null)
                Center(
                  child: Text(
                    'Lỗi tải phân công: ${assignmentState.error}',
                    style: const TextStyle(color: CupertinoColors.systemRed),
                  ),
                )
              else if (assignmentState.assignments.isEmpty)
                _buildEmptyState()
              else ...[
                _buildQuickStats(assignmentState),
                const SizedBox(height: 24),
                _buildAttendanceSection(),
                const SizedBox(height: 28),
                _buildHousekeepingSection(),
                const SizedBox(height: 28),
                _buildSectionTitle('Các dãy trọ đang quản lý'),
                const SizedBox(height: 16),
                _buildBranchCards(assignmentState),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats(StaffAssignmentState state) {
    final ticketsAsync = ref.watch(ticketProvider);
    final tickets = ticketsAsync.value ?? [];
    final pendingCount = tickets
        .where(
          (t) =>
              t.status == TicketStatus.assigned.value ||
              t.status == TicketStatus.processing.value ||
              t.status == TicketStatus.newTicket.value,
        )
        .length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: LiquidGlassColors.staffAccent.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        CupertinoIcons.building_2_fill,
                        color: LiquidGlassColors.staffAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${state.assignments.length}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Khu trọ quản lý',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemOrange.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        CupertinoIcons.wrench_fill,
                        color: CupertinoColors.systemOrange,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$pendingCount',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sự cố chờ xử lý',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // QR Actions
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/qr_cash_scanner'),
                icon: const Icon(CupertinoIcons.qrcode_viewfinder),
                label: const Text('Thu/Nộp tiền'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kBrand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push(
                  '/qr_cash_receiver',
                  extra: {'sessionType': 'TENANT_PAY_BILL'},
                ),
                icon: const Icon(CupertinoIcons.qrcode),
                label: const Text('Tạo QR thu tiền'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/my-tasks'),
                icon: const Icon(CupertinoIcons.doc_text_fill),
                label: const Text('Công việc'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kWarning,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.push('/my-attendance'),
                icon: const Icon(CupertinoIcons.camera_viewfinder),
                label: const Text('Chấm công'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.kSuccess,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => context.push('/staff-shifts'),
          icon: const Icon(CupertinoIcons.calendar_badge_plus),
          label: const Text('Lịch làm việc'),
          style: ElevatedButton.styleFrom(
            backgroundColor: LiquidGlassColors.staffAccent,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return PremiumEmptyStateWidget(
      title: 'Chưa có phân công',
      message:
          'Bạn chưa được chủ nhà phân công quản lý khu trọ nào. Hãy liên hệ với chủ nhà để được nhận việc nhé!',
      icon: CupertinoIcons.briefcase_fill,
      buttonText: 'Tải lại dữ liệu',
      onButtonPressed: () =>
          ref.read(staffAssignmentProvider.notifier).loadAssignments(),
    );
  }

  Widget _buildHousekeepingSection() {
    final tasksAsync = ref.watch(housekeepingProvider);

    return tasksAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (tasks) {
        final done = tasks.where((t) => t.status == TaskStatus.done).length;
        final total = tasks.length;
        final pct = total == 0 ? 0.0 : done / total;
        final nextPending = tasks
            .where((t) => t.status != TaskStatus.done)
            .take(2)
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle('Công việc hôm nay (Housekeeping)'),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  onPressed: () => Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => const HousekeepingScreen(),
                    ),
                  ),
                  child: const Text(
                    'Xem tất cả',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GlassContainer(
              padding: const EdgeInsets.all(16),
              color: LiquidGlassColors.staffAccent.withValues(alpha: 0.06),
              border: Border.all(
                color: LiquidGlassColors.staffAccent.withValues(alpha: 0.15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$done/$total nhiệm vụ hoàn thành',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: (done == total && total > 0)
                              ? CupertinoColors.systemGreen
                              : CupertinoColors.black,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${(pct * 100).toInt()}%',
                        style: const TextStyle(
                          color: LiquidGlassColors.staffAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Container(
                      height: 8,
                      color: CupertinoColors.systemGrey5,
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: pct,
                        child: Container(
                          decoration: BoxDecoration(
                            color: (done == total && total > 0)
                                ? CupertinoColors.systemGreen
                                : LiquidGlassColors.staffAccent,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (nextPending.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Tiếp theo cần làm:',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...nextPending.map((task) {
                      const typeLabel = {
                        TaskType.cleaning: 'Dọn phòng',
                        TaskType.checkOut: 'Bàn giao trả phòng',
                        TaskType.checkIn: 'Bàn giao nhận phòng',
                        TaskType.maintenance: 'Bảo trì sửa chữa',
                      };
                      final isInProgress = task.status == TaskStatus.inProgress;
                      return BounceClick(
                        onPressed: () {
                          unawaited(HapticFeedback.lightImpact());
                          unawaited(
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (_) => const HousekeepingScreen(),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: CupertinoColors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isInProgress
                                      ? CupertinoColors.systemOrange.withValues(
                                          alpha: 0.1,
                                        )
                                      : LiquidGlassColors.staffAccent
                                            .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  isInProgress
                                      ? CupertinoIcons.play_circle_fill
                                      : CupertinoIcons.circle,
                                  color: isInProgress
                                      ? CupertinoColors.systemOrange
                                      : LiquidGlassColors.staffAccent,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      typeLabel[task.type] ?? 'Nhiệm vụ',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: CupertinoColors.black,
                                      ),
                                    ),
                                    Text(
                                      '${task.roomName}  •  Trước ${task.dueTime}',
                                      style: const TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                CupertinoIcons.chevron_right,
                                color: CupertinoColors.systemGrey4,
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                  if (done == total && total > 0) ...[
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.checkmark_seal_fill,
                          color: CupertinoColors.systemGreen,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '🎉 Tất cả việc đã hoàn thành!',
                          style: TextStyle(
                            color: CupertinoColors.systemGreen,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleQuickAction(
    StaffAssignmentState state,
    Function(int branchId) onBranchSelected,
  ) {
    if (state.assignments.length == 1) {
      onBranchSelected(state.assignments.first.branchId);
      return;
    }

    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => Container(
          height: 300,
          color: CupertinoColors.systemBackground,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Text('Hủy'),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Chọn Dãy Trọ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const CupertinoButton(
                    onPressed: null,
                    child: SizedBox(width: 40),
                  ),
                ],
              ),
              Expanded(
                child: ListView.separated(
                  itemCount: state.assignments.length,
                  separatorBuilder: (_, __) => const SizedBox(
                    height: 1,
                    child: ColoredBox(color: Color(0xFFE5E7EB)),
                  ),
                  itemBuilder: (context, index) {
                    final branch = state.assignments[index];
                    return CupertinoButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onBranchSelected(branch.branchId);
                      },
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          branch.branchName,
                          style: const TextStyle(color: CupertinoColors.black),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBranchCards(StaffAssignmentState state) {
    if (state.assignments.isEmpty) return const SizedBox();

    return Column(
      children: state.assignments.asMap().entries.map((entry) {
        final idx = entry.key;
        final branch = entry.value;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (idx * 50)),
          curve: Curves.easeOutCubic,
          builder: (context, val, child) => Transform.translate(
            offset: Offset(0, 15 * (1 - val)),
            child: Opacity(opacity: val, child: child),
          ),
          child: BounceClick(
            onPressed: () {
              unawaited(HapticFeedback.selectionClick());
              unawaited(
                context.push(
                  '/staff-branch-room/${branch.branchId}',
                  extra: branch.branchName,
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: LiquidGlassColors.staffAccent.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        CupertinoIcons.building_2_fill,
                        color: LiquidGlassColors.staffAccent,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            branch.branchName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Nhấn để xem danh sách phòng',
                            style: TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      CupertinoIcons.chevron_right,
                      color: CupertinoColors.systemGrey,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHistoryTab() {
    final logsAsync = ref.watch(myAttendanceLogsProvider);
    final attendanceLogs = logsAsync.value ?? [];

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const CupertinoSliverNavigationBar(
          largeTitle: Text(
            'Lịch Sử',
            style: TextStyle(color: CupertinoColors.black),
          ),
          backgroundColor: Color(0x00000000),
          border: null,
          transitionBetweenRoutes: false,
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // ── Chấm công section ──
              _buildSectionTitle('Chấm công gần đây'),
              const SizedBox(height: 12),
              if (logsAsync.isLoading)
                const Center(child: CupertinoActivityIndicator())
              else if (attendanceLogs.isEmpty)
                const GlassContainer(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'Chưa có dữ liệu chấm công.',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ),
                )
              else
                ...attendanceLogs.take(7).toList().asMap().entries.map((entry) {
                  final idx = entry.key;
                  final log = entry.value;
                  DateTime? checkInTime = log.checkInTime;
                  DateTime? checkOutTime = log.checkOutTime;

                  final checkInStr = checkInTime != null
                      ? '${checkInTime.hour.toString().padLeft(2, '0')}:${checkInTime.minute.toString().padLeft(2, '0')}'
                      : '--:--';
                  final checkOutStr = checkOutTime != null
                      ? '${checkOutTime.hour.toString().padLeft(2, '0')}:${checkOutTime.minute.toString().padLeft(2, '0')}'
                      : '--:--';
                  final dateRef = checkInTime ?? checkOutTime;
                  final dateStr = dateRef != null
                      ? '${dateRef.day.toString().padLeft(2, '0')}/${dateRef.month.toString().padLeft(2, '0')}'
                      : 'N/A';
                  final isDone = checkOutTime != null;

                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 400 + (idx * 50)),
                    curve: Curves.easeOutCubic,
                    builder: (context, val, child) => Transform.translate(
                      offset: Offset(15 * (1 - val), 0),
                      child: Opacity(opacity: val, child: child),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: LiquidGlassColors.staffAccent.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                CupertinoIcons.person_badge_plus_fill,
                                color: LiquidGlassColors.staffAccent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ngày $dateStr',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Vào: $checkInStr  •  Ra: $checkOutStr',
                                    style: const TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isDone
                                    ? CupertinoColors.systemGreen.withValues(
                                        alpha: 0.12,
                                      )
                                    : CupertinoColors.systemOrange.withValues(
                                        alpha: 0.12,
                                      ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isDone ? 'Đủ ca' : 'Đang làm',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDone
                                      ? CupertinoColors.systemGreen
                                      : CupertinoColors.systemOrange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 24),

              // ── Sự cố đã xử lý section ──
              _buildSectionTitle('Sự cố đã xử lý'),
              const SizedBox(height: 12),
              _buildCompletedTickets(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedTickets() {
    final ticketAsync = ref.watch(ticketProvider);
    return ticketAsync.when(
      data: (tickets) {
        final done = tickets
            .where(
              (t) =>
                  t.status == TicketStatus.closed.value ||
                  t.status == TicketStatus.completed.value,
            )
            .toList();
        if (done.isEmpty) {
          return const GlassContainer(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text(
                'Chưa có sự cố nào đã xử lý.',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
          );
        }
        return Column(
          children: done.asMap().entries.map((entry) {
            final idx = entry.key;
            final t = entry.value;
            final color = t.status == TicketStatus.closed.value
                ? CupertinoColors.systemGreen
                : CupertinoColors.systemBlue;
            final statusLabel = t.status == TicketStatus.closed.value
                ? 'Đã duyệt'
                : 'Chờ nghiệm thu';
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 400 + (idx * 50)),
              curve: Curves.easeOutCubic,
              builder: (context, val, child) => Transform.translate(
                offset: Offset(15 * (1 - val), 0),
                child: Opacity(opacity: val, child: child),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: GlassContainer(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          CupertinoIcons.wrench_fill,
                          color: color,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.category,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Phòng #${t.roomId}  •  ${t.description ?? ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  // Tab Cá nhân
  Widget _buildProfileTab() {
    final authState = ref.watch(authProvider);
    final user = authState.value;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const CupertinoSliverNavigationBar(
          largeTitle: Text(
            'Nhân Viên',
            style: TextStyle(color: CupertinoColors.black),
          ),
          backgroundColor: Color(0x00000000),
          border: null,
          transitionBetweenRoutes: false,
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: LiquidGlassColors.staffAccent,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.person_fill,
                        color: CupertinoColors.black,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Nhân Viên Vận Hành',
                            style: const TextStyle(
                              color: CupertinoColors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ??
                                user?.phoneNumber ??
                                'staff@stayhub.vn',
                            style: const TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Cài đặt tài khoản'),
              const SizedBox(height: 12),
              GlassContainer(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildMenuRow(
                      CupertinoIcons.square_list_fill,
                      'Báo cáo công việc',
                      CupertinoColors.systemBlue,
                    ),
                    _buildDivider(),
                    _buildMenuRow(
                      CupertinoIcons.creditcard_fill,
                      'Tài khoản nhận lương',
                      CupertinoColors.systemGreen,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (!mounted) return;
                  context.go('/login');
                },
                child: GlassContainer(
                  color: CupertinoColors.systemRed.withValues(alpha: 0.1),
                  border: Border.all(
                    color: CupertinoColors.systemRed.withValues(alpha: 0.3),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: const Center(
                    child: Text(
                      'Đăng Xuất',
                      style: TextStyle(
                        color: CupertinoColors.systemRed,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuRow(IconData icon, String title, Color iconColor) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      onPressed: () {},
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: CupertinoColors.black,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Icon(
            CupertinoIcons.chevron_right,
            color: const Color(0xFF4B5563).withValues(alpha: 0.3),
            size: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 0.5,
      color: CupertinoColors.white,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: Color(0xFF4B5563),
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    );
  }

  void _showQuickActionMenu(StaffAssignmentState state) {
    final perms = state.assignments.isNotEmpty
        ? state.assignments.first.permissions
        : const StaffPermissions.fullAccess();
    final canHandleTickets = perms.canHandleTickets;
    final canManageBills = perms.canManageBills;
    final canManageContracts = perms.canManageContracts;
    final canRecordMeters = perms.canRecordMeters;
    final canViewFinancial = perms.canViewFinancial;
    final canSendNotifications = perms.canSendNotifications;

    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: const BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Thao tác nghiệp vụ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildActionCategory('Nghiệp vụ hằng ngày', [
                        _ActionItem(
                          'Bàn Giao',
                          CupertinoIcons.house_alt_fill,
                          const Color(0xFFF59E0B),
                          const Color(0xFFFEF3C7),
                          () {
                            Navigator.pop(ctx);
                            unawaited(context.push('/staff-handover'));
                          },
                          imagePath:
                              'assets/images/features/move_checklist.png',
                        ),
                        if (canHandleTickets)
                          _ActionItem(
                            'Sự Cố',
                            CupertinoIcons.bolt_fill,
                            const Color(0xFFEF4444),
                            const Color(0xFFFEE2E2),
                            () {
                              Navigator.pop(ctx);
                              setState(() => _selectedTab = 1);
                            },
                            imagePath:
                                'assets/images/features/video_maintenance.png',
                          ),
                        if (canManageBills)
                          _ActionItem(
                            'Hóa Đơn',
                            CupertinoIcons.money_dollar_circle_fill,
                            const Color(0xFF10B981),
                            const Color(0xFFD1FAE5),
                            () {
                              Navigator.pop(ctx);
                              unawaited(context.push('/bill'));
                            },
                            imagePath:
                                'assets/images/features/feat_payments.png',
                          ),
                        if (canRecordMeters)
                          _ActionItem(
                            'Điện Nước',
                            CupertinoIcons.gauge,
                            const Color(0xFF298FFF),
                            const Color(0xFFE3F0FF),
                            () {
                              Navigator.pop(ctx);
                              _handleQuickAction(
                                state,
                                (branchId) => context.push(
                                  '/batch-meter-reading/$branchId',
                                ),
                              );
                            },
                            imagePath:
                                'assets/images/features/utilities_dashboard.png',
                          ),
                        if (canHandleTickets || canRecordMeters)
                          _ActionItem(
                            'Quản lý xe',
                            CupertinoIcons.car_fill,
                            const Color(0xFF298FFF),
                            const Color(0xFFE3F0FF),
                            () {
                              Navigator.pop(ctx);
                              unawaited(
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (c) =>
                                        const VehicleManagementScreen(),
                                  ),
                                ),
                              );
                            },
                            imagePath:
                                'assets/images/features/smart_locker.png',
                          ),
                        _ActionItem(
                          'Quét QR',
                          CupertinoIcons.qrcode_viewfinder,
                          const Color(0xFFEF4444),
                          const Color(0xFFFEE2E2),
                          () {
                            Navigator.pop(ctx);
                            unawaited(context.push('/qr-scanner'));
                          },
                          imagePath: 'assets/images/features/ocr_meter.png',
                        ),
                        _ActionItem(
                          'Chấm công',
                          CupertinoIcons.location_solid,
                          const Color(0xFF298FFF),
                          const Color(0xFFE3F0FF),
                          () {
                            Navigator.pop(ctx);
                            unawaited(context.push('/staff-attendance'));
                          },
                          imagePath: 'assets/images/features/feat_booking.png',
                        ),
                      ]),
                      const SizedBox(height: 32),
                      if (canManageContracts ||
                          canViewFinancial ||
                          canSendNotifications)
                        _buildActionCategory('Quản lý nâng cao', [
                          if (canManageContracts)
                            _ActionItem(
                              'Yêu Cầu',
                              CupertinoIcons.doc_person_fill,
                              const Color(0xFF298FFF),
                              const Color(0xFFE3F0FF),
                              () {
                                Navigator.pop(ctx);
                                unawaited(context.push('/rental-requests'));
                              },
                              imagePath:
                                  'assets/images/features/tenant_bg_check.png',
                            ),
                          if (canManageContracts)
                            _ActionItem(
                              'Hợp Đồng',
                              CupertinoIcons.doc_text_fill,
                              const Color(0xFF298FFF),
                              const Color(0xFFE3F0FF),
                              () {
                                Navigator.pop(ctx);
                                unawaited(context.push('/contract'));
                              },
                              imagePath:
                                  'assets/images/features/feat_contracts.png',
                            ),
                          if (canViewFinancial)
                            _ActionItem(
                              'Thu Chi',
                              CupertinoIcons.chart_pie_fill,
                              const Color(0xFFF59E0B),
                              const Color(0xFFFEF3C7),
                              () {
                                Navigator.pop(ctx);
                                unawaited(context.push('/expense-management'));
                              },
                              imagePath:
                                  'assets/images/features/expense_scanner.png',
                            ),
                          if (canSendNotifications)
                            _ActionItem(
                              'Thông Báo',
                              CupertinoIcons.bell_fill,
                              const Color(0xFFFF6B35),
                              const Color(0xFFFFF0EB),
                              () {
                                Navigator.pop(ctx);
                                unawaited(context.push('/broadcast'));
                              },
                              imagePath:
                                  'assets/images/features/broadcast_msg.png',
                            ),
                          if (canManageContracts)
                            _ActionItem(
                              'Cho Thuê',
                              CupertinoIcons.person_crop_circle_badge_plus,
                              const Color(0xFF111827),
                              CupertinoColors.white,
                              () {
                                Navigator.pop(ctx);
                                unawaited(
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (c) => const RentOutRoomScreen(),
                                    ),
                                  ),
                                );
                              },
                              imagePath:
                                  'assets/images/features/smart_contract.png',
                            ),
                          if (canManageContracts)
                            _ActionItem(
                              'Xuất CT01',
                              CupertinoIcons.doc_text,
                              const Color(0xFFF59E0B),
                              const Color(0xFFFEF3C7),
                              () {
                                Navigator.pop(ctx);
                                unawaited(
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (c) => const CT01ExportScreen(),
                                    ),
                                  ),
                                );
                              },
                              imagePath:
                                  'assets/images/features/auto_pdf_gen.png',
                            ),
                          if (canRecordMeters)
                            _ActionItem(
                              'Chốt số',
                              CupertinoIcons.gauge_badge_plus,
                              const Color(0xFF298FFF),
                              const Color(0xFFE3F0FF),
                              () {
                                Navigator.pop(ctx);
                                unawaited(
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (c) =>
                                          const RecordUtilitiesScreen(),
                                    ),
                                  ),
                                );
                              },
                              imagePath: 'assets/images/features/ocr_meter.png',
                            ),
                          if (canManageBills)
                            _ActionItem(
                              'Lập HĐơn',
                              CupertinoIcons.money_dollar_circle,
                              const Color(0xFF10B981),
                              const Color(0xFFD1FAE5),
                              () {
                                Navigator.pop(ctx);
                                unawaited(
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (c) =>
                                          const GenerateBillScreen(),
                                    ),
                                  ),
                                );
                              },
                              imagePath:
                                  'assets/images/features/one_tap_payment.png',
                            ),
                          if (canManageContracts)
                            _ActionItem(
                              'Mẫu HĐ',
                              CupertinoIcons.doc_text_fill,
                              const Color(0xFF298FFF),
                              const Color(0xFFE3F0FF),
                              () {
                                Navigator.pop(ctx);
                                unawaited(
                                  context.push('/contract-template-edit'),
                                );
                              },
                              imagePath:
                                  'assets/images/features/document_vault.png',
                            ),
                        ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCategory(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 20,
            crossAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: items.length,
          itemBuilder: (ctx, i) => items[i],
        ),
      ],
    );
  }

  Widget _buildFloatingNavBar(StaffAssignmentState state) {
    return GlassContainer(
      borderRadius: 40,
      blur: 20,
      color: const Color(0xE5FFFFFF),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavItem(
            0,
            CupertinoIcons.house_fill,
            'Trang chủ',
            imagePath: 'assets/images/features/feat_home.png',
          ),
          _buildNavItem(
            1,
            CupertinoIcons.wrench_fill,
            'Sự cố',
            imagePath: 'assets/images/features/video_maintenance.png',
          ),

          // Nút FAB Ở Giữa
          GestureDetector(
            onTapDown: (_) {},
            onTap: () => _showQuickActionMenu(state),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: LiquidGlassColors.staffAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: LiquidGlassColors.staffAccent.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.add,
                color: CupertinoColors.white,
                size: 32,
              ),
            ),
          ),

          _buildNavItem(
            2,
            CupertinoIcons.clock_fill,
            'Lịch sử',
            imagePath: 'assets/images/features/auto_pnl_export.png',
          ),
          _buildNavItem(
            3,
            CupertinoIcons.person_fill,
            'Cá nhân',
            imagePath: 'assets/images/features/feat_profile.png',
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label, {
    String? imagePath,
  }) {
    final isActive = _selectedTab == index;
    return Expanded(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => setState(() => _selectedTab = index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (imagePath != null)
              Opacity(
                opacity: isActive ? 1.0 : 0.55,
                child: Image.asset(
                  imagePath,
                  width: 26,
                  height: 26,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  isAntiAlias: true,
                  errorBuilder: (_, __, ___) => Icon(
                    icon,
                    color: isActive
                        ? LiquidGlassColors.staffAccent
                        : const Color(0xFF9CA3AF),
                    size: 24,
                  ),
                ),
              )
            else
              Icon(
                icon,
                color: isActive
                    ? LiquidGlassColors.staffAccent
                    : const Color(0xFF9CA3AF),
                size: 24,
              ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? LiquidGlassColors.staffAccent
                    : const Color(0xFF9CA3AF),
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceSection() {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      color: CupertinoColors.systemBlue.withValues(alpha: 0.1),
      border: Border.all(
        color: CupertinoColors.systemBlue.withValues(alpha: 0.3),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: CupertinoColors.systemBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.location_solid,
              color: CupertinoColors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chấm công định vị',
                  style: TextStyle(
                    color: CupertinoColors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Bấm để check-in/out ca làm việc',
                  style: TextStyle(color: Color(0xFF4B5563), fontSize: 13),
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: CupertinoColors.systemBlue,
            borderRadius: BorderRadius.circular(20),
            onPressed: () {
              unawaited(context.push('/staff-attendance'));
            },
            child: const Text(
              'Mở',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: CupertinoColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Quick Action Menu Item
// ──────────────────────────────────────────────
class _ActionItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;
  final String? imagePath;

  const _ActionItem(
    this.label,
    this.icon,
    this.iconColor,
    this.bgColor,
    this.onTap, {
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: imagePath == null
                ? Icon(icon, color: iconColor, size: 26)
                : Padding(
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      imagePath!,
                      width: 44,
                      height: 44,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }
}
