import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/network/api_client.dart';
import '../../auth/application/auth_notifier.dart';
import 'dart:async' show unawaited;

class OwnerViewingSchedulesScreen extends ConsumerStatefulWidget {
  const OwnerViewingSchedulesScreen({super.key});

  @override
  ConsumerState<OwnerViewingSchedulesScreen> createState() =>
      _OwnerViewingSchedulesScreenState();
}

class _OwnerViewingSchedulesScreenState
    extends ConsumerState<OwnerViewingSchedulesScreen> {
  bool _isLoading = true;
  List<dynamic> _schedules = [];

  @override
  void initState() {
    super.initState();
    unawaited(_fetchSchedules());
  }

  Future<void> _fetchSchedules() async {
    // BUGFIX (UI): setState() gọi trong initState (trước build đầu tiên) là
    // thừa và có thể gây lỗi; đồng thời setState sau await không kiểm tra
    // mounted → crash "setState() called after dispose()" khi user rời màn
    // hình trong lúc request đang bay.
    if (mounted) setState(() => _isLoading = true);
    try {
      final user = ref.read(authProvider).value;
      if (user != null) {
        final res = await ApiClient().get(
          '/api/v1/viewing-schedules/owner/${user.id}',
        );
        if (!mounted) return;
        setState(() {
          // BUGFIX (data): trước đây ép `as List<dynamic>?` — nếu API trả
          // `data` là object/null thì ném TypeError. Guard `is List` an toàn.
          final raw = res['data'];
          _schedules = raw is List ? raw : const [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching schedules: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int id, String status) async {
    try {
      await ApiClient().put(
        '/api/v1/viewing-schedules/$id/status?status=$status',
      );
      unawaited(_fetchSchedules());
    } catch (e) {
      debugPrint('Error updating schedule status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      title: 'Lịch Xem Phòng',
      backgroundColors: AppTheme.kBackgroundLight,
      useScrollView: false,
      child: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : _schedules.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              itemCount: _schedules.length,
              itemBuilder: (context, index) {
                final schedule = _schedules[index];
                return _buildScheduleCard(schedule);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.kBrandDeep.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.calendar,
              size: 52,
              color: AppTheme.kBrandDeep,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Chưa có lịch hẹn nào',
            style: TextStyle(
              color: Color(0xFF374151),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Các yêu cầu xem phòng sẽ xuất hiện ở đây',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(dynamic schedule) {
    final status = schedule['status'];
    Color statusColor;
    String statusText;
    switch (status) {
      case 'PENDING':
        statusColor = CupertinoColors.systemOrange;
        statusText = 'Chờ duyệt';
        break;
      case 'APPROVED':
        statusColor = CupertinoColors.systemGreen;
        statusText = 'Đã duyệt';
        break;
      case 'REJECTED':
        statusColor = CupertinoColors.systemRed;
        statusText = 'Đã từ chối';
        break;
      default:
        statusColor = AppTheme.kTextSecondary;
        statusText = status ?? 'UNKNOWN';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: statusColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.kBrandDeep.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.person_fill,
                      size: 18,
                      color: AppTheme.kBrandDeep,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Khách #${schedule['tenantId']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppTheme.kTextPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 0.5, color: const Color(0xFFE5E7EB)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                CupertinoIcons.building_2_fill,
                size: 15,
                color: AppTheme.kTextMuted,
              ),
              const SizedBox(width: 8),
              Text(
                'Phòng ID: ${schedule['roomId']}',
                style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                CupertinoIcons.calendar,
                size: 15,
                color: AppTheme.kTextMuted,
              ),
              const SizedBox(width: 8),
              Text(
                'Ngày: ${schedule['viewDate']} • Giờ: ${schedule['viewHour']}:00',
                style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
              ),
            ],
          ),
          if (status == 'PENDING') ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _updateStatus(schedule['id'], 'REJECTED'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppTheme.kError.withValues(alpha: 0.3),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Từ Chối',
                        style: TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _updateStatus(schedule['id'], 'APPROVED'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: PremiumGradients.oceanBlue,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.kBrandDeep.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Duyệt Lịch',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
