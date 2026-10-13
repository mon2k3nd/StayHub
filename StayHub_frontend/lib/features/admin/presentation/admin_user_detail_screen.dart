import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/components/premium_shimmer_loading.dart';
import 'package:intl/intl.dart';
import '../../../core/components/app_error_widget.dart';
import 'dart:async' show unawaited;

final adminUserDetailProvider =
    FutureProvider.family<Map<String, dynamic>, int>((ref, userId) async {
      final res = await ApiClient().dio.get('/v1/admin/users/$userId/details');
      if (res.data['success']) {
        return res.data['data'];
      }
      throw Exception(res.data['message']);
    });

class AdminUserDetailScreen extends ConsumerWidget {
  final int userId;
  const AdminUserDetailScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(adminUserDetailProvider(userId));

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.kBackgroundLightGray,
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Hồ sơ Chi Tiết'),
        previousPageTitle: 'Tìm kiếm',
      ),
      child: SafeArea(
        child: asyncData.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: PremiumShimmerLoading(itemCount: 4, itemHeight: 120),
          ),
          error: (err, _) => AppErrorWidget(error: err),
          data: (user) {
            // BUGFIX (data): tránh `as String` ném TypeError khi role null.
            final role = (user['role'] ?? '').toString();
            final isTenant = role == 'TENANT';
            final isOwner = role == 'OWNER';

            return CustomScrollView(
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh: () async {
                    await Future.delayed(const Duration(milliseconds: 1000));
                  },
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(user),
                        const SizedBox(height: 24),
                        if (isTenant && user['tenantDetails'] != null)
                          _buildTenantDetails(user['tenantDetails']),
                        if (isOwner && user['ownerDetails'] != null)
                          _buildOwnerDetails(user['ownerDetails']),
                        const SizedBox(height: 24),
                        _GodModePanel(user: user),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> user) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LiquidGlassColors.adminAccent.withValues(alpha: 0.2),
            ),
            child: const Icon(
              CupertinoIcons.person_solid,
              size: 40,
              color: LiquidGlassColors.adminAccent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user['name'] ?? 'Không rõ',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${user['phone']} • ${user['role']}',
            style: const TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: user['status'] == 'ACTIVE'
                  ? CupertinoColors.activeGreen.withValues(alpha: 0.1)
                  : CupertinoColors.systemRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              user['status'] ?? 'UNKNOWN',
              style: TextStyle(
                color: user['status'] == 'ACTIVE'
                    ? CupertinoColors.activeGreen
                    : CupertinoColors.systemRed,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantDetails(Map<String, dynamic> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'THÔNG TIN ĐỊNH DANH (TENANT)',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 12),
        GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildRow('CCCD', details['cccdNumber'] ?? 'Chưa cập nhật'),
              const Divider(color: CupertinoColors.systemGrey5),
              _buildRow(
                'Điểm Uy Tín',
                '${details['trustScore'] ?? 100} điểm',
                isBold: true,
                valueColor: CupertinoColors.activeBlue,
              ),
              const Divider(color: CupertinoColors.systemGrey5),
              _buildRow('Trạng thái KYC', details['kycStatus'] ?? 'UNVERIFIED'),
              const Divider(color: CupertinoColors.systemGrey5),
              _buildRow('Quê quán', details['hometown'] ?? 'Chưa cập nhật'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'ĐANG THUÊ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 12),
        _buildContractList(details['activeContracts'] as List?),
        const SizedBox(height: 24),
        const Text(
          'LỊCH SỬ THUÊ TRƯỚC ĐÂY',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 12),
        _buildContractList(details['pastContracts'] as List?),
      ],
    );
  }

  Widget _buildOwnerDetails(Map<String, dynamic> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'THÔNG TIN CHỦ NHÀ (OWNER)',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 12),
        GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildRow(
                'Gói SaaS',
                details['packageId'] ?? 'FREE',
                isBold: true,
                valueColor: CupertinoColors.activeOrange,
              ),
              const Divider(color: CupertinoColors.systemGrey5),
              _buildRow(
                'Tổng Phòng Sở Hữu',
                '${details['totalRoomsOwned'] ?? 0} phòng',
              ),
              const Divider(color: CupertinoColors.systemGrey5),
              _buildRow('Trạng thái', details['ownerStatus'] ?? 'UNKNOWN'),
              const Divider(color: CupertinoColors.systemGrey5),
              _buildRow('Ngân hàng', details['bankName'] ?? 'Chưa cập nhật'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: CupertinoColors.systemGrey),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? CupertinoColors.black,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractList(List? contracts) {
    if (contracts == null || contracts.isEmpty) {
      return const Text(
        'Không có dữ liệu',
        style: TextStyle(
          color: CupertinoColors.systemGrey,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return Column(
      children: contracts.map((c) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mã hợp đồng: #${c['id']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.black,
                      ),
                    ),
                    Text(
                      c['status'] ?? '',
                      style: const TextStyle(
                        color: CupertinoColors.activeBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Mã phòng: #${c['roomId']}'),
                const SizedBox(height: 4),
                Text(
                  'Thời gian: ${c['startDate'] ?? '?'} -> ${c['endDate'] ?? '?'}',
                ),
                const SizedBox(height: 4),
                Text(
                  'Tiền cọc: ${formatter.format(c['depositAmount'] ?? 0)}',
                  style: const TextStyle(color: CupertinoColors.activeGreen),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _GodModePanel extends StatefulWidget {
  final Map<String, dynamic> user;
  const _GodModePanel({required this.user});

  @override
  State<_GodModePanel> createState() => _GodModePanelState();
}

class _GodModePanelState extends State<_GodModePanel> {
  bool _isLoading = false;

  Future<void> _executeDeepAction(
    String title,
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Xác nhận $title'),
        content: const Text(
          'Bạn đang thực hiện thao tác nhạy cảm. Thao tác này sẽ ghi đè lên dữ liệu hiện tại.',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Hủy'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Thực thi'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final res = await ApiClient().dio.put(endpoint, data: body);
      if (!mounted) return;
      if (res.data['success']) {
        // unawaited(Show success snackbar equivalent or dialog)
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (context) => CupertinoAlertDialog(
              title: const Text('Thành công'),
              content: Text(
                res.data['message'] ?? 'Thao tác đã được thực thi.',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      unawaited(
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Lỗi'),
            content: Text('Không thể thực thi thao tác: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = widget.user['role'];
    final id = widget.user['id'];

    if (role != 'TENANT' && role != 'OWNER') return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Icon(
              CupertinoIcons.exclamationmark_shield_fill,
              color: CupertinoColors.destructiveRed,
            ),
            SizedBox(width: 8),
            Text(
              'HÀNH ĐỘNG QUẢN TRỊ (GOD MODE)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: CupertinoColors.destructiveRed,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: CupertinoColors.destructiveRed.withValues(alpha: 0.05),
            border: Border.all(
              color: CupertinoColors.destructiveRed.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: _isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (role == 'TENANT') ...[
                      CupertinoButton(
                        color: CupertinoColors.activeGreen,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: const Text('Xác thực eKYC Thủ Công'),
                        onPressed: () => _executeDeepAction(
                          'Xác thực eKYC',
                          '/v1/admin/tenants/$id/approve-ekyc',
                          {
                            'cccdNumber': 'MANUAL_APPROVAL',
                            'reason': 'Super Admin approved',
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      CupertinoButton(
                        color: CupertinoColors.activeOrange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: const Text('Khôi phục 100 Trust Score'),
                        onPressed: () => _executeDeepAction(
                          'Sửa Trust Score',
                          '/v1/admin/tenants/$id/trust-score',
                          {'newScore': 100, 'reason': 'Super Admin reset'},
                        ),
                      ),
                      const SizedBox(height: 12),
                      CupertinoButton(
                        color: CupertinoColors.destructiveRed,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: const Text('Gỡ Vi Phạm (Unban)'),
                        onPressed: () => _executeDeepAction(
                          'Gỡ Vi Phạm',
                          '/v1/admin/tenants/$id/unban',
                          {'reason': 'Super Admin unban'},
                        ),
                      ),
                      const SizedBox(height: 12),
                      CupertinoButton(
                        color: CupertinoColors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: const Text('Hủy Liên Kết CCCD'),
                        onPressed: () => _executeDeepAction(
                          'Hủy CCCD',
                          '/v1/admin/tenants/$id/unlink-cccd',
                          {'reason': 'Super Admin unlink'},
                        ),
                      ),
                    ],
                    if (role == 'OWNER') ...[
                      // We haven't implemented full Owner deep actions in backend API yet, but we have verifyOwner.
                      CupertinoButton(
                        color: CupertinoColors.destructiveRed,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: const Text('Khóa Tài Khoản Chủ Trọ'),
                        onPressed: () {},
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}
