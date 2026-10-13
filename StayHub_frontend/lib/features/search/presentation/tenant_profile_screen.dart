import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';

import '../application/tenant_profile_provider.dart';

class TenantProfileScreen extends ConsumerWidget {
  final String tenantId;
  const TenantProfileScreen({super.key, required this.tenantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(tenantProfileProvider(tenantId));

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.kBackgroundLight,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: CupertinoColors.black),
          onPressed: () => context.pop(),
        ),
        middle: const Text(
          'Hồ sơ khách thuê',
          style: TextStyle(
            color: CupertinoColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      child: SafeArea(
        child: profileAsync.when(
          data: (data) {
            if (data == null) {
              return const Center(child: Text('Không tìm thấy thông tin'));
            }

            final user = data.userProfile;
            final contracts = data.contracts;
            final bills = data.bills;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Avatar & Basic Info
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.kAccentColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.person_solid,
                            size: 40,
                            color: AppTheme.kAccentColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user['fullName'] ?? 'Chưa cập nhật',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Khách thuê',
                            style: TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Section: Thông tin cá nhân
                  const Text(
                    'THÔNG TIN CÁ NHÂN',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.kTextMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: CupertinoIcons.phone_fill,
                          imagePath: 'assets/images/features/e2e_chat.png',
                          label: 'Số điện thoại',
                          value: user['phone'] ?? '...',
                        ),
                        const Divider(height: 1, indent: 48),
                        _InfoRow(
                          icon: CupertinoIcons.mail_solid,
                          imagePath: 'assets/images/features/broadcast_msg.png',
                          label: 'Email',
                          value: user['email'] ?? '...',
                        ),
                        const Divider(height: 1, indent: 48),
                        _InfoRow(
                          icon: CupertinoIcons.person_crop_circle,
                          imagePath: 'assets/images/features/ai_roommate.png',
                          label: 'Giới tính',
                          value: user['gender'] ?? '...',
                        ),
                        const Divider(height: 1, indent: 48),
                        _InfoRow(
                          icon: CupertinoIcons.calendar,
                          imagePath: 'assets/images/features/feat_booking.png',
                          label: 'Ngày sinh',
                          value: user['dateOfBirth'] ?? '...',
                        ),
                        const Divider(height: 1, indent: 48),
                        _InfoRow(
                          icon: CupertinoIcons.location_solid,
                          imagePath:
                              'assets/images/features/multi_property.png',
                          label: 'Quê quán',
                          value: user['hometown'] ?? '...',
                        ),
                        const Divider(height: 1, indent: 48),
                        _InfoRow(
                          icon: CupertinoIcons.briefcase_fill,
                          imagePath:
                              'assets/images/features/staff_dispatch.png',
                          label: 'Nghề nghiệp',
                          value: user['occupation'] ?? '...',
                        ),
                        const Divider(height: 1, indent: 48),
                        _InfoRow(
                          icon: CupertinoIcons.car_detailed,
                          imagePath:
                              'assets/images/features/iot_management.png',
                          label: 'Xe cộ',
                          value:
                              '${user['vehicleType'] ?? 'Chưa cập nhật'} - ${user['licensePlate'] ?? '...'}',
                        ),
                        const Divider(height: 1, indent: 48),
                        _InfoRow(
                          icon: CupertinoIcons.exclamationmark_triangle_fill,
                          imagePath: 'assets/images/features/sos_panic.png',
                          label: 'Liên hệ khẩn',
                          value:
                              '${user['emergencyContactName'] ?? 'Chưa cập nhật'} - ${user['emergencyContactPhone'] ?? '...'}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Section: Thông tin CCCD
                  const Text(
                    'THÔNG TIN CCCD',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.kTextMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: CupertinoIcons.creditcard_fill,
                          imagePath:
                              'assets/images/features/biometric_auth.png',
                          label: 'Số CCCD',
                          value: user['cccdNumber'] ?? '...',
                        ),
                        const Divider(height: 1, indent: 48),
                        _InfoRow(
                          icon: CupertinoIcons.calendar_badge_plus,
                          imagePath: 'assets/images/features/feat_booking.png',
                          label: 'Ngày cấp',
                          value: user['cccdIssueDate'] ?? '...',
                        ),
                        const Divider(height: 1, indent: 48),
                        _InfoRow(
                          icon: CupertinoIcons.building_2_fill,
                          imagePath:
                              'assets/images/features/multi_property.png',
                          label: 'Nơi cấp',
                          value: user['cccdIssuePlace'] ?? '...',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (user['cccdFrontUrl'] != null ||
                      user['cccdBackUrl'] != null)
                    Row(
                      children: [
                        if (user['cccdFrontUrl'] != null)
                          Expanded(
                            child: AspectRatio(
                              aspectRatio: 1.6,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  user['cccdFrontUrl'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey[200],
                                    child: const Icon(CupertinoIcons.photo),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (user['cccdFrontUrl'] != null &&
                            user['cccdBackUrl'] != null)
                          const SizedBox(width: 12),
                        if (user['cccdBackUrl'] != null)
                          Expanded(
                            child: AspectRatio(
                              aspectRatio: 1.6,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  user['cccdBackUrl'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey[200],
                                    child: const Icon(CupertinoIcons.photo),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 32),

                  // Section: Lịch sử thuê phòng (Hợp đồng)
                  const Text(
                    'LỊCH SỬ THUÊ PHÒNG',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.kTextMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (contracts.isEmpty)
                    const Text(
                      'Chưa có lịch sử thuê',
                      style: TextStyle(color: AppTheme.kTextMuted),
                    ),
                  ...contracts.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ContractCard(
                        roomName: c['room'] != null
                            ? c['room']['name']
                            : 'Phòng',
                        branchName:
                            c['room'] != null && c['room']['branch'] != null
                            ? c['room']['branch']['name']
                            : 'Chi nhánh',
                        startDate: c['startDate'] ?? '...',
                        endDate: c['endDate'] ?? '...',
                        status: c['status'] == 'ACTIVE'
                            ? 'Đang hiệu lực'
                            : 'Đã thanh lý',
                        statusColor: c['status'] == 'ACTIVE'
                            ? const Color(0xFF059669)
                            : AppTheme.kTextMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section: Lịch sử đóng tiền (Hóa đơn)
                  const Text(
                    'LỊCH SỬ GIAO DỊCH',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.kTextMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (bills.isEmpty)
                    const Text(
                      'Chưa có giao dịch',
                      style: TextStyle(color: AppTheme.kTextMuted),
                    ),
                  ...bills.map((b) {
                    bool isLate = b['status'] == 'OVERDUE';
                    bool isPaid = b['status'] == 'PAID';
                    String statusStr = isPaid
                        ? 'Đã thanh toán'
                        : (isLate ? 'Trễ hạn' : 'Chưa thanh toán');

                    // totalAmount có thể là num HOẶC String (JSON) → ép an toàn
                    // trước khi format, tránh TypeError làm vỡ toàn bộ danh sách.
                    final rawAmount = b['totalAmount'];
                    final amountNum = rawAmount is num
                        ? rawAmount
                        : (num.tryParse(rawAmount?.toString() ?? '') ?? 0);
                    final formattedAmount = NumberFormat.currency(
                      locale: 'vi_VN',
                      symbol: 'đ',
                    ).format(amountNum);

                    final m = b['month'];
                    final y = b['year'];
                    final title = m != null && y != null
                        ? 'Hóa đơn tháng $m/$y'
                        : (b['title'] ?? 'Hóa đơn');

                    return _TransactionRow(
                      month: title,
                      amount: formattedAmount,
                      status: statusStr,
                      isLate: isLate,
                    );
                  }),

                  const SizedBox(height: 40),
                ],
              ),
            );
          },
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (err, stack) => Center(child: Text('Lỗi: $err')),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? imagePath;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          if (imagePath != null)
            Image.asset(
              imagePath!,
              width: 22,
              height: 22,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              isAntiAlias: true,
              errorBuilder: (_, __, ___) =>
                  Icon(icon, size: 20, color: AppTheme.kTextMuted),
            )
          else
            Icon(icon, size: 20, color: AppTheme.kTextMuted),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppTheme.kTextPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContractCard extends StatelessWidget {
  final String roomName;
  final String branchName;
  final String startDate;
  final String endDate;
  final String status;
  final Color statusColor;

  const _ContractCard({
    required this.roomName,
    required this.branchName,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CupertinoColors.systemGrey5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                roomName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            branchName,
            style: const TextStyle(color: AppTheme.kTextMuted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                CupertinoIcons.calendar,
                size: 16,
                color: AppTheme.kTextMuted,
              ),
              const SizedBox(width: 8),
              Text(
                '$startDate - $endDate',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.kTextPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final String month;
  final String amount;
  final String status;
  final bool isLate;

  const _TransactionRow({
    required this.month,
    required this.amount,
    required this.status,
    required this.isLate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isLate ? const Color(0xFFFEE2E2) : const Color(0xFFE3F0FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isLate
                  ? CupertinoIcons.exclamationmark_triangle_fill
                  : CupertinoIcons.check_mark_circled_solid,
              color: isLate ? const Color(0xFFEF4444) : AppTheme.kBrand,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  month,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    color: isLate
                        ? const Color(0xFFEF4444)
                        : AppTheme.kTextMuted,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppTheme.kTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
