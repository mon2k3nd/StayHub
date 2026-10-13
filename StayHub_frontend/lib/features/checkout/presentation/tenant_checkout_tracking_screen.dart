import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../data/models/checkout_request_model.dart';
import '../../contract/data/models/contract_model.dart';

import '../application/checkout_provider.dart';
import '../../tenant/application/tenant_dashboard_notifier.dart';
import '../../bill/data/models/bill_model.dart';
import 'dart:async' show unawaited;

class TenantCheckoutTrackingScreen extends ConsumerWidget {
  final ContractModel contract;
  final CheckoutRequestModel request;

  const TenantCheckoutTrackingScreen({
    super.key,
    required this.contract,
    required this.request,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(checkoutTrackingProvider(request.id));

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.kBackgroundLight,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        border: null,
        middle: const Text(
          'Tiến độ trả phòng',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: CupertinoColors.black,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(
            CupertinoIcons.back,
            color: CupertinoColors.activeBlue,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: asyncData.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (err, stack) => Center(child: Text('Lỗi: $err')),
          data: (data) {
            final summary = data;
            final status = request.status;

            return CustomScrollView(
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh: () async {
                    ref.invalidate(checkoutTrackingProvider(request.id));
                    await ref.read(checkoutTrackingProvider(request.id).future);
                  },
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildTimelineCard(context, ref, status),
                      const SizedBox(height: 16),
                      _buildOverviewCard(summary),
                      const SizedBox(height: 16),
                      _buildStayStatisticsCard(summary),
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTimelineCard(
    BuildContext context,
    WidgetRef ref,
    String status,
  ) {
    int currentStep = 0;
    if (status == 'PENDING') currentStep = 1;
    if (status == 'APPROVED' || status == 'REJECTED') currentStep = 2;
    if (status == 'PAYMENT_PENDING') currentStep = 3;
    if (status == 'COMPLETED') currentStep = 4;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TRẠNG THÁI YÊU CẦU',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF8C8C8C),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildTimelineStep(
                1,
                'Gửi\nyêu cầu',
                isActive: currentStep >= 1,
                isCurrent: currentStep == 1,
              ),
              _buildTimelineDivider(isActive: currentStep >= 2),
              _buildTimelineStep(
                2,
                'Nghiệm\nthu',
                isActive: currentStep >= 2,
                isCurrent: currentStep == 2,
              ),
              _buildTimelineDivider(isActive: currentStep >= 3),
              _buildTimelineStep(
                3,
                'Thanh\ntoán',
                isActive: currentStep >= 3,
                isCurrent: currentStep == 3,
              ),
              _buildTimelineDivider(isActive: currentStep >= 4),
              _buildTimelineStep(
                4,
                'Hoàn\ntất',
                isActive: currentStep >= 4,
                isCurrent: currentStep == 4,
              ),
            ],
          ),
          if (status == 'REJECTED') ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    CupertinoIcons.clear_circled_solid,
                    color: Colors.red,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Yêu cầu bị từ chối. Vui lòng liên hệ chủ nhà.',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (status == 'PAYMENT_PENDING') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: CupertinoColors.activeBlue,
                borderRadius: BorderRadius.circular(12),
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: () async {
                  unawaited(
                    showCupertinoDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (ctx) => const Center(
                        child: CupertinoActivityIndicator(radius: 16),
                      ),
                    ),
                  );

                  try {
                    final bills = await ref.read(unpaidBillsProvider.future);
                    // BUGFIX (data): tránh `as Map<String, dynamic>` ném
                    // TypeError khi phần tử không phải Map.
                    final checkoutBillMap = bills.firstWhere(
                      (b) => b is Map && b['type'] == 'CHECKOUT',
                      orElse: () =>
                          throw Exception('Không tìm thấy hóa đơn quyết toán'),
                    );
                    final checkoutBill = BillModel.fromJson(
                      Map<String, dynamic>.from(checkoutBillMap as Map),
                    );
                    if (context.mounted) {
                      context.pop();
                      unawaited(
                        context.push(
                          '/tenant/checkout-bill',
                          extra: {'bill': checkoutBill, 'request': request},
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      context.pop();
                      unawaited(
                        showCupertinoDialog(
                          context: context,
                          builder: (ctx) => CupertinoAlertDialog(
                            title: const Text('Lỗi'),
                            content: Text(e.toString()),
                            actions: [
                              CupertinoDialogAction(
                                onPressed: () => ctx.pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  }
                },
                child: const Text(
                  'Thanh toán Quyết toán',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineStep(
    int step,
    String label, {
    required bool isActive,
    required bool isCurrent,
  }) {
    Color color = isActive
        ? CupertinoColors.activeBlue
        : const Color(0xFFE5E7EB);
    if (isCurrent) color = CupertinoColors.activeOrange;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: isActive && !isCurrent
                  ? Icon(Icons.check, size: 16, color: color)
                  : Text(
                      '$step',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
              color: isCurrent ? color : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineDivider({required bool isActive}) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? CupertinoColors.activeBlue : const Color(0xFFE5E7EB),
        margin: const EdgeInsets.only(bottom: 24),
      ),
    );
  }

  Widget _buildOverviewCard(Map<String, dynamic> summary) {
    final room = summary['room'];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THÔNG TIN CHUNG',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF8C8C8C),
            ),
          ),
          const SizedBox(height: 16),
          _buildRow(
            'Căn hộ / Phòng',
            room != null
                ? room['roomName']?.toString()
                : 'Phòng ${contract.roomId}',
            icon: CupertinoIcons.house_fill,
          ),
          _buildRow(
            'Ngày dự kiến trả',
            DateFormat('dd/MM/yyyy').format(request.targetCheckoutDate),
            isBold: true,
            color: CupertinoColors.systemRed,
          ),
          _buildRow('Mã hợp đồng', 'HD-${contract.id}'),
          _buildRow(
            'Tiền đặt cọc',
            '${NumberFormat('#,###').format(contract.depositAmount)} VNĐ',
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStayStatisticsCard(Map<String, dynamic> summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THỐNG KÊ QUÁ TRÌNH Ở',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF8C8C8C),
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            'Thời gian đã ở',
            '${summary['stayDurationDays'] ?? 0} ngày',
            CupertinoIcons.calendar_today,
            CupertinoColors.activeBlue,
          ),
          const Divider(color: Color(0xFFF3F4F6), height: 24),
          _buildStatRow(
            'Sự cố đã báo',
            '${summary['incidentCount'] ?? 0} lần',
            CupertinoIcons.wrench_fill,
            CupertinoColors.systemOrange,
          ),
          const Divider(color: Color(0xFFF3F4F6), height: 24),
          _buildStatRow(
            'Thanh toán trọ',
            '${summary['paidBills'] ?? 0}/${summary['totalBills'] ?? 0} hóa đơn',
            CupertinoIcons.money_dollar_circle_fill,
            CupertinoColors.systemGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String? value, {
    bool isBold = false,
    Color? color,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: CupertinoColors.activeBlue),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    value ?? '',
                    style: TextStyle(
                      fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 14,
                      color: color ?? const Color(0xFF1F2937),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String title, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
