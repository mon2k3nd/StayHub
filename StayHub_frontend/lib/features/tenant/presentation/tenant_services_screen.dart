import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Material;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/bounce_click.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/theme/app_theme.dart';
import '../application/tenant_service_notifier.dart';
import 'dart:async' show unawaited;

class TenantServicesScreen extends ConsumerStatefulWidget {
  const TenantServicesScreen({super.key});

  @override
  ConsumerState<TenantServicesScreen> createState() =>
      _TenantServicesScreenState();
}

class _TenantServicesScreenState extends ConsumerState<TenantServicesScreen> {
  void _showBookingSheet(BuildContext context, ServiceItem service) {
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (context) => _BookingBottomSheet(service: service),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableServices = ref.watch(availableServicesProvider);
    final bookingHistoryAsync = ref.watch(serviceBookingProvider);

    return LiquidGlassScaffold(
      title: 'Chợ Dịch Vụ',
      useScrollView: true,
      backgroundColors: AppTheme.kBackgroundLight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Hero Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: PremiumGradients.oceanBlue,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.kBrandDeep.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '🌟 Ưu đãi cuối tuần',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Giảm 20% Dọn Phòng',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nhập mã WEEKEND20',
                    style: TextStyle(
                      color: CupertinoColors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Text(
              'DỊCH VỤ NỔI BẬT',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.kTextSecondary,
                fontSize: 13,
              ),
            ),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
              children: availableServices.asMap().entries.map((entry) {
                final idx = entry.key;
                final service = entry.value;
                final sColor = Color(service.colorValue);
                // Map icon name string to IconData (simplified)
                final iconData = _getIconData(service.iconName);

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
                      unawaited(HapticFeedback.lightImpact());
                      _showBookingSheet(context, service);
                    },
                    child: GlassContainer(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: sColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(
                              _getIconAsset(service.iconName),
                              width: 48,
                              height: 48,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              isAntiAlias: true,
                              errorBuilder: (_, __, ___) =>
                                  Icon(iconData, color: sColor, size: 36),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            service.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: CupertinoColors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            service.priceDesc,
                            style: const TextStyle(
                              color: AppTheme.kTextSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),
            const Text(
              'ĐƠN DỊCH VỤ CỦA BẠN',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.kTextSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),

            bookingHistoryAsync.when(
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (err, stack) => Text(
                'Lỗi: $err',
                style: const TextStyle(color: CupertinoColors.systemRed),
              ),
              data: (history) {
                if (history.isEmpty) {
                  return const GlassContainer(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Bạn chưa đặt dịch vụ nào',
                        style: TextStyle(color: AppTheme.kTextSecondary),
                      ),
                    ),
                  );
                }
                return Column(
                  children: history.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final booking = entry.value;
                    final statusColor = _getStatusColor(booking.status);
                    final statusText = _getStatusText(booking.status);
                    final serviceObj = availableServices.firstWhere(
                      (s) => s.id == booking.serviceId,
                      orElse: () => availableServices.first,
                    );
                    final sColor = Color(serviceObj.colorValue);

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: Duration(milliseconds: 400 + (idx * 50)),
                      curve: Curves.easeOutCubic,
                      builder: (context, val, child) => Transform.translate(
                        offset: Offset(15 * (1 - val), 0),
                        child: Opacity(opacity: val, child: child),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: GlassContainer(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: sColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Image.asset(
                                  _getIconAsset(serviceObj.iconName),
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.high,
                                  isAntiAlias: true,
                                  errorBuilder: (_, __, ___) => Icon(
                                    _getIconData(serviceObj.iconName),
                                    color: sColor,
                                    size: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      booking.serviceTitle,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: CupertinoColors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$statusText • Đặt lúc ${booking.createdAt.day}/${booking.createdAt.month}',
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                CupertinoIcons.chevron_right,
                                color: AppTheme.kTextSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'sparkles':
        return CupertinoIcons.sparkles;
      case 'snow':
        return CupertinoIcons.snow;
      case 'drop_fill':
        return CupertinoIcons.drop_fill;
      case 'wrench_fill':
        return CupertinoIcons.wrench_fill;
      case 'bag_fill':
        return CupertinoIcons.bag_fill;
      case 'car_detailed':
        return CupertinoIcons.car_detailed;
      default:
        return CupertinoIcons.star;
    }
  }

  String _getIconAsset(String name) {
    switch (name) {
      case 'sparkles':
        return 'assets/images/features/local_services.png';
      case 'snow':
        return 'assets/images/features/iot_management.png';
      case 'drop_fill':
        return 'assets/images/features/utilities_dashboard.png';
      case 'wrench_fill':
        return 'assets/images/features/video_maintenance.png';
      case 'bag_fill':
        return 'assets/images/features/local_services.png';
      case 'car_detailed':
        return 'assets/images/features/smart_locker.png';
      default:
        return 'assets/images/features/local_services.png';
    }
  }

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return CupertinoColors.systemOrange;
      case BookingStatus.inProgress:
        return CupertinoColors.systemBlue;
      case BookingStatus.completed:
        return CupertinoColors.systemGreen;
      case BookingStatus.cancelled:
        return CupertinoColors.systemRed;
    }
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
        return 'Đang xử lý';
      case BookingStatus.inProgress:
        return 'Đang thực hiện';
      case BookingStatus.completed:
        return 'Hoàn thành';
      case BookingStatus.cancelled:
        return 'Đã hủy';
    }
  }
}

class _BookingBottomSheet extends ConsumerStatefulWidget {
  final ServiceItem service;

  const _BookingBottomSheet({required this.service});

  @override
  ConsumerState<_BookingBottomSheet> createState() =>
      _BookingBottomSheetState();
}

class _BookingBottomSheetState extends ConsumerState<_BookingBottomSheet> {
  int _selectedOption = 0;
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sColor = Color(widget.service.colorValue);

    return Container(
      padding: const EdgeInsets.only(top: 8),
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.kTextMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: sColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIcon(widget.service.iconName),
                    color: sColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.service.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: CupertinoColors.black,
                        ),
                      ),
                      Text(
                        widget.service.priceDesc,
                        style: TextStyle(
                          color: sColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Icon(
                    CupertinoIcons.clear_circled_solid,
                    color: AppTheme.kTextSecondary,
                    size: 28,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Container(
              height: 1,
              color: AppTheme.kTextMuted,
              margin: const EdgeInsets.symmetric(vertical: 16),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const Text(
                    'Chọn gói dịch vụ',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildOption(
                    0,
                    'Gói Cơ Bản',
                    'Dịch vụ tiêu chuẩn theo yêu cầu',
                    widget.service.priceDesc,
                    sColor,
                  ),
                  const SizedBox(height: 12),
                  _buildOption(
                    1,
                    'Gói Nâng Cao',
                    'Ưu tiên xử lý nhanh + Hỗ trợ thêm',
                    'Thêm 50,000đ',
                    sColor,
                  ),

                  const SizedBox(height: 32),
                  const Text(
                    'Thời gian mong muốn',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.kSurfaceBlue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.calendar_today,
                              color: AppTheme.kTextSecondary,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Càng sớm càng tốt',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: CupertinoColors.black,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          CupertinoIcons.chevron_down,
                          color: AppTheme.kTextSecondary,
                          size: 16,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Text(
                    'Ghi chú (Tùy chọn)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    controller: _notesCtrl,
                    placeholder: 'Ví dụ: Phòng tôi có nuôi mèo...',
                    maxLines: 3,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.kSurfaceBlue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: Consumer(
                    builder: (context, ref, child) {
                      final isSubmitting = ref
                          .watch(serviceBookingProvider)
                          .isLoading;
                      return CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        borderRadius: BorderRadius.circular(16),
                        color: sColor,
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                final notes = _notesCtrl.text.trim();
                                await ref
                                    .read(serviceBookingProvider.notifier)
                                    .bookNewService(
                                      widget.service.id,
                                      widget.service.title,
                                      notes,
                                    );
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  unawaited(
                                    showCupertinoDialog(
                                      context: context,
                                      builder: (ctx) => CupertinoAlertDialog(
                                        title: const Text('✅ Đặt thành công!'),
                                        content: const Text(
                                          'Dịch vụ của bạn đã được ghi nhận. Nhà cung cấp sẽ liên hệ với bạn trong ít phút nữa.',
                                        ),
                                        actions: [
                                          CupertinoDialogAction(
                                            child: const Text('OK'),
                                            onPressed: () => Navigator.pop(ctx),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                              },
                        child: isSubmitting
                            ? const CupertinoActivityIndicator(
                                color: CupertinoColors.white,
                              )
                            : const Text(
                                'Đặt Dịch Vụ Ngay',
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    int index,
    String title,
    String desc,
    String price,
    Color sColor,
  ) {
    final isSelected = _selectedOption == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedOption = index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? sColor.withValues(alpha: 0.1)
              : AppTheme.kSurfaceBlue,
          border: Border.all(
            color: isSelected ? sColor : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? CupertinoIcons.check_mark_circled_solid
                  : CupertinoIcons.circle,
              color: isSelected ? sColor : AppTheme.kTextSecondary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.kTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: TextStyle(fontWeight: FontWeight.w700, color: sColor),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String name) {
    switch (name) {
      case 'sparkles':
        return CupertinoIcons.sparkles;
      case 'snow':
        return CupertinoIcons.snow;
      case 'drop_fill':
        return CupertinoIcons.drop_fill;
      case 'wrench_fill':
        return CupertinoIcons.wrench_fill;
      case 'bag_fill':
        return CupertinoIcons.bag_fill;
      case 'car_detailed':
        return CupertinoIcons.car_detailed;
      default:
        return CupertinoIcons.star;
    }
  }
}
