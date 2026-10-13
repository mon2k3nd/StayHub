import 'rental_scan_landing_screen.dart';
import 'package:flutter/cupertino.dart';

import '../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter/material.dart' show Badge;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/bounce_click.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/glass_button.dart';
import '../../../core/components/animated_list_wrapper.dart';
import '../../../core/components/premium_text_field.dart';
import '../../../core/constants/role_types.dart';
import '../../../core/providers/core_providers.dart';
import '../../room/application/room_notifier.dart';
import '../../room/data/models/room_model.dart';
import '../../../core/enums/room_status.dart';
import '../../contract/application/contract_notifier.dart';
import '../application/tenant_dashboard_notifier.dart';
import '../../auth/application/auth_notifier.dart';
import '../../notification/data/unread_notifications_count_provider.dart';
import '../../premium/presentation/tenant_premium_hub_screen.dart';
import '../../checkout/application/checkout_provider.dart';
import 'tenant_smart_lock_screen.dart';
import 'tenant_community_board.dart';
import 'tenant_bill_splitter.dart';
import '../../../core/components/app_error_widget.dart';
import 'package:stayhub_frontend/core/components/stayhub_logo_icon.dart';
import 'dart:async' show unawaited;

class TenantHomeScreen extends ConsumerStatefulWidget {
  final TenantState state;
  const TenantHomeScreen({super.key, required this.state});

  @override
  ConsumerState<TenantHomeScreen> createState() => _TenantHomeScreenState();
}

class _TenantHomeScreenState extends ConsumerState<TenantHomeScreen> {
  final TextEditingController _roomCodeController = TextEditingController();

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final contractsAsync = ref.watch(contractProvider);
    final allContracts = contractsAsync.value ?? [];
    final activeContracts = allContracts
        .where((c) => c.status == 'ACTIVE' || c.status == 'PENDING')
        .toList();

    return LiquidGlassScaffold(
      title: 'StayHub',
      backgroundColors: AppTheme.kBackgroundLight,
      useScrollView: false,
      trailing: Consumer(
        builder: (context, ref, child) {
          final unreadCount =
              ref.watch(unreadNotificationsCountProvider).value ?? 0;
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  unawaited(
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => const RentalScanLandingScreen(),
                      ),
                    ),
                  );
                },
                child: const Icon(
                  CupertinoIcons.qrcode_viewfinder,
                  size: 24,
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(width: 8),
              Badge(
                label: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 10,
                  ),
                ),
                isLabelVisible: unreadCount > 0,
                backgroundColor: CupertinoColors.systemRed,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    unawaited(context.push('/notifications'));
                    ref.invalidate(unreadNotificationsCountProvider);
                  },
                  child: const Icon(
                    CupertinoIcons.bell_fill,
                    size: 24,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              ref.invalidate(contractProvider);
              ref.invalidate(unpaidBillsProvider);
              try {
                await ref.read(contractProvider.future);
                await ref.read(unpaidBillsProvider.future);
              } catch (e) {
                debugPrint('Error: $e');
              }
            },
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (widget.state == TenantState.pendingApproval)
                  _buildPendingApprovalUI()
                else if (widget.state == TenantState.unlinked)
                  _buildUnlinkedUI()
                else if (widget.state == TenantState.linked &&
                    activeContracts.isNotEmpty)
                  _buildLinkedUI(activeContracts.first)
                else if (widget.state == TenantState.linked)
                  _buildWaitingForContractUI()
                else if (widget.state == TenantState.requestingOwner)
                  _buildRequestingUI()
                else if (widget.state == TenantState.verifying)
                  _buildVerifyingUI()
                else
                  const SizedBox.shrink(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlinkedUI() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () {
                unawaited(
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => const RentalScanLandingScreen(),
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: LiquidGlassColors.tenantAccent.withValues(
                        alpha: 0.3,
                      ),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const GlassContainer(
                  borderRadius: 100,
                  padding: EdgeInsets.all(
                    40,
                  ), // Increased padding to make it larger
                  child: Icon(
                    CupertinoIcons.qrcode_viewfinder,
                    color: LiquidGlassColors.tenantAccent,
                    size: 80,
                  ), // Larger icon
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        const Text(
          'Chào mừng bạn!',
          style: TextStyle(
            color: CupertinoColors.black,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Quét mã QR trong phòng hoặc nhập mã do chủ nhà cung cấp để bắt đầu hành trình của bạn.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 48),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: LiquidGlassColors.tenantAccent.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 18),
            color: LiquidGlassColors.tenantAccent,
            borderRadius: BorderRadius.circular(20),
            onPressed: () => context.push('/qr-scanner'),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.camera_fill,
                  color: CupertinoColors.white,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Quét mã QR',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        PremiumTextField(
          controller: _roomCodeController,
          placeholder: 'Hoặc nhập mã phòng (6 số)',
          textAlign: TextAlign.center,
          suffix: CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(
              CupertinoIcons.arrow_right_circle_fill,
              color: CupertinoColors.black,
              size: 32,
            ),
            onPressed: () => _handleJoinRoom(_roomCodeController.text.trim()),
          ),
        ),
        const SizedBox(height: 48),
        _buildUpgradeBanner(),
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildPendingApprovalUI() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          const CupertinoActivityIndicator(
            radius: 24,
            color: AppTheme.kAccentColor,
          ),
          const SizedBox(height: 32),
          const Text(
            'Đang chờ phê duyệt',
            style: TextStyle(
              color: CupertinoColors.black,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Yêu cầu thuê phòng của bạn đã được gửi đến chủ nhà. Vui lòng chờ xác nhận để tiếp tục bước nghiệm thu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 48),
          GlassButton(
            text: 'Làm mới trạng thái',
            icon: CupertinoIcons.refresh,
            color: AppTheme.kAccentColor,
            onPressed: () {
              unawaited(
                ref.read(tenantDashboardProvider.notifier).checkStatus(),
              );
            },
          ),
          const SizedBox(height: 16),
          GlassButton(
            text: 'Hủy yêu cầu',
            icon: CupertinoIcons.xmark_circle_fill,
            color: CupertinoColors.systemRed,
            onPressed: () {
              unawaited(
                ref
                    .read(tenantDashboardProvider.notifier)
                    .cancelRentalRequest(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyingUI() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 80),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.kBrand.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.checkmark_seal_fill,
              color: AppTheme.kBrand,
              size: 64,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Yêu cầu đã được duyệt!',
            style: TextStyle(
              color: CupertinoColors.black,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Chủ nhà đã đồng ý yêu cầu thuê phòng của bạn. Vui lòng xem và ký hợp đồng, sau đó tiến hành nghiệm thu phòng.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 48),
          GlassButton(
            text: 'Đi tới Nghiệm thu',
            icon: CupertinoIcons.arrow_right_circle_fill,
            color: AppTheme.kBrand,
            onPressed: () {
              ref.read(tenantDashboardProvider.notifier).setTab(2);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleJoinRoom(String roomCode) async {
    if (roomCode.isEmpty) return;
    final code = roomCode.trim().toUpperCase();
    try {
      unawaited(
        showCupertinoDialog(
          context: context,
          builder: (ctx) =>
              const Center(child: CupertinoActivityIndicator(radius: 16)),
          barrierDismissible: false,
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pop(context);
      final roomRepo = ref.read(roomRepositoryProvider);
      RoomModel? room;
      final isOtp = code.length == 6 && int.tryParse(code) != null;
      if (isOtp) {
        try {
          final dio = ref.read(dioProvider);
          final res = await dio.post('/v1/rooms/by-otp/$code/lock');
          if (res.data != null && res.data['success'] == true) {
            room = RoomModel.fromJson(res.data['data']);
          } else {
            _showErrorDialog("Mã phòng đã hết hạn hoặc không tồn tại!");
            return;
          }
        } catch (e) {
          _showErrorDialog(
            "Mã phòng đã hết hạn hoặc không tồn tại! Vui lòng xin chủ nhà mã mới.",
          );
          return;
        }
      } else {
        int? roomId = int.tryParse(code);
        if (roomId != null) {
          room = await roomRepo.loadRoomById(roomId);
        }
      }
      if (room != null) {
        if (room.status == RoomStatus.cleaningTurnover.value) {
          if (!mounted) return;
          _showErrorDialog(
            "Phòng đang trong quá trình hoàn tất thủ tục bàn giao và vệ sinh. Vui lòng liên hệ chủ nhà hoặc quay lại sau!",
          );
          return;
        }
        if (room.status != RoomStatus.trong.value &&
            room.status != RoomStatus.choDuyet.value) {
          if (!mounted) return;
          _showErrorDialog("Phòng này hiện không trống. Vui lòng thử mã khác.");
          return;
        }
        if (!mounted) return;
        final user = ref.read(authProvider).value;
        final extraData = {
          'roomId': room.id,
          'roomName': room.roomName,
          'branchId': room.branchId,
          'branchName': room.detailedInfo?['branchName'] ?? 'Cơ sở StayHub',
          'price': room.price ?? 0.0,
        };
        if (user == null ||
            user.cccdNumber == null ||
            user.cccdNumber!.isEmpty ||
            user.hometown == null ||
            user.hometown!.isEmpty ||
            user.cccdIssueDate == null ||
            user.cccdIssuePlace == null ||
            user.cccdIssuePlace!.isEmpty ||
            user.emergencyContactName == null ||
            user.emergencyContactName!.isEmpty ||
            user.emergencyContactPhone == null ||
            user.emergencyContactPhone!.isEmpty ||
            user.gender == null ||
            user.gender!.isEmpty ||
            user.dateOfBirth == null) {
          unawaited(
            context.push(
              '/profile-update',
              extra: {'nextRoute': '/rental-request', 'extraData': extraData},
            ),
          );
          return;
        }
        unawaited(context.push('/rental-request', extra: extraData));
      } else {
        if (!mounted) return;
        _showErrorDialog("Mã phòng không hợp lệ. Vui lòng kiểm tra lại!");
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(
        "Không tìm thấy phòng hoặc đã xảy ra lỗi. Vui lòng kiểm tra lại mã!",
      );
    }
  }

  void _showErrorDialog(String message) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Lỗi'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('Đóng'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkedUI(dynamic contract) {
    if (contract.status == 'PENDING') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          GlassContainer(
            padding: const EdgeInsets.all(24),
            color: CupertinoColors.systemYellow.withValues(alpha: 0.1),
            child: Column(
              children: [
                const Icon(
                  CupertinoIcons.doc_text_fill,
                  color: CupertinoColors.systemYellow,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Chờ Ký Hợp Đồng',
                  style: TextStyle(
                    color: CupertinoColors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Yêu cầu thuê phòng của bạn đã được chủ nhà duyệt. Vui lòng ký hợp đồng điện tử để hoàn tất.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF4B5563), fontSize: 14),
                ),
                const SizedBox(height: 24),
                GlassButton(
                  text: 'Xem & Ký Hợp Đồng',
                  icon: CupertinoIcons.doc_text_search,
                  color: CupertinoColors.systemYellow,
                  onPressed: () {
                    unawaited(
                      context.push(
                        '/contract-preview',
                        extra: {'contractId': contract.id},
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [
                AppTheme.kBrandLight, // Light Sky Blue
                AppTheme.kBrandDeep, // Deep Sky Blue
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.kBrand.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CupertinoColors.white.withValues(alpha: 0.12),
                  ),
                ),
              ),
              Positioned(
                left: -20,
                bottom: -20,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: CupertinoColors.white.withValues(alpha: 0.07),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const StayHubLogoIcon(
                          color: CupertinoColors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'PHÒNG CỦA BẠN',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'ĐANG THUÊ',
                            style: TextStyle(
                              color: CupertinoColors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Phòng ${contract.roomName ?? contract.roomId}',
                                style: const TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              if (contract.branchName != null &&
                                  contract.branchName!.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(
                                      CupertinoIcons.location_fill,
                                      color: CupertinoColors.white,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        contract.branchName ?? '',
                                        style: const TextStyle(
                                          color: CupertinoColors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      color: CupertinoColors.white.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildRoomInfoItem(
                          icon: CupertinoIcons.money_dollar_circle_fill,
                          imagePath: 'assets/images/features/feat_payments.png',
                          label: 'Tiền phòng',
                          value:
                              '${_formatAmount(contract.monthlyRent ?? 0)}/tháng',
                        ),
                        const SizedBox(width: 16),
                        _buildRoomInfoItem(
                          icon: CupertinoIcons.calendar,
                          imagePath: 'assets/images/features/feat_booking.png',
                          label: 'Ngày bắt đầu',
                          value: _formatDate(contract.startDate),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildRoomInfoItem(
                          icon: CupertinoIcons.time_solid,
                          imagePath:
                              'assets/images/features/auto_pnl_export.png',
                          label: 'Đã ở',
                          value: _calcDuration(contract.startDate),
                        ),
                        const SizedBox(width: 16),
                        _buildRoomInfoItem(
                          icon: CupertinoIcons.person_2_fill,
                          imagePath:
                              'assets/images/features/multi_property.png',
                          label: 'Chủ nhà',
                          value: contract.ownerName ?? 'Chủ nhà',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader(
          'HÓA ĐƠN CHỜ',
          CupertinoIcons.doc_text_fill,
          imagePath: 'assets/images/features/feat_payments.png',
        ),
        const SizedBox(height: 12),
        _buildBillAlert(),
        const SizedBox(height: 28),
        _buildSectionHeader(
          'TIỆN ÍCH NHANH',
          CupertinoIcons.bolt_fill,
          imagePath: 'assets/images/features/utilities_dashboard.png',
        ),
        const SizedBox(height: 14),
        _buildQuickActions(contract),
        const SizedBox(height: 28),
        _buildSectionHeader(
          'QUẢN LÝ PHÒNG',
          CupertinoIcons.square_grid_2x2_fill,
          imagePath: 'assets/images/features/feat_room.png',
        ),
        const SizedBox(height: 14),
        _buildGridMenu(contract),
        const SizedBox(height: 28),
        _buildUpgradeBanner(),
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {String? imagePath}) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(imagePath == null ? 6 : 2),
          decoration: BoxDecoration(
            gradient: imagePath == null
                ? const LinearGradient(
                    colors: [AppTheme.kBrandDeep, AppTheme.kBrandLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: imagePath == null ? null : const Color(0xFFEAF3FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: imagePath == null
              ? Icon(icon, color: CupertinoColors.white, size: 12)
              : Image.asset(
                  imagePath,
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  isAntiAlias: true,
                  errorBuilder: (_, __, ___) =>
                      Icon(icon, color: AppTheme.kBrandDeep, size: 12),
                ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.kBrandDeep,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildRoomInfoItem({
    required IconData icon,
    required String label,
    required String value,
    String? imagePath,
  }) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imagePath != null)
            Image.asset(
              imagePath,
              width: 18,
              height: 18,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              isAntiAlias: true,
              errorBuilder: (_, __, ___) => Icon(
                icon,
                color: CupertinoColors.white.withValues(alpha: 0.8),
                size: 14,
              ),
            )
          else
            Icon(
              icon,
              color: CupertinoColors.white.withValues(alpha: 0.8),
              size: 14,
            ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: CupertinoColors.white.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
    return amount.toStringAsFixed(0);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _calcDuration(DateTime? startDate) {
    if (startDate == null) return 'N/A';
    final diff = DateTime.now().difference(startDate);
    final months = (diff.inDays / 30).floor();
    final days = diff.inDays % 30;
    if (months > 0) return '$months tháng $days ngày';
    return '${diff.inDays} ngày';
  }

  Widget _buildBillAlert() {
    final billsAsync = ref.watch(unpaidBillsProvider);
    return billsAsync.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, _) => AppErrorWidget(error: e, compact: true),
      data: (bills) {
        if (bills.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGreen.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: CupertinoColors.systemGreen.withValues(alpha: 0.2),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  CupertinoIcons.checkmark_seal_fill,
                  color: CupertinoColors.systemGreen,
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bạn đã thanh toán đầy đủ hóa đơn. Tuyệt vời!',
                    style: TextStyle(
                      color: Color(0xFF374151),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        final bill = bills.first;
        final month = bill['month'] ?? 0;
        final year = bill['year'] ?? 0;
        return BounceClick(
          onPressed: () {
            unawaited(HapticFeedback.lightImpact());
            unawaited(context.push('/bill'));
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  CupertinoColors.systemOrange.withValues(alpha: 0.15),
                  CupertinoColors.systemOrange.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: CupertinoColors.systemOrange.withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: -5,
                  offset: const Offset(0, 8),
                ),
              ],
              border: Border.all(
                color: CupertinoColors.systemOrange.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemOrange.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.exclamationmark_triangle_fill,
                    color: CupertinoColors.systemOrange,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hóa đơn tháng $month/$year',
                        style: const TextStyle(
                          color: CupertinoColors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Hạn cuối: Theo hợp đồng',
                        style: TextStyle(
                          color: Color(0xFFD97706),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_right,
                  color: CupertinoColors.systemOrange,
                  size: 20,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(dynamic contract) {
    final actions = [
      (
        'Hóa đơn',
        CupertinoIcons.money_dollar_circle_fill,
        AppTheme.kBrandDeep,
        AppTheme.kBrandLight,
        'assets/images/features/feat_payments.png',
        () => context.push('/bill'),
      ),
      (
        'Sự cố',
        CupertinoIcons.wrench_fill,
        AppTheme.kError,
        const Color(0xFFFF8C00),
        'assets/images/features/video_maintenance.png',
        () => context.push('/ticket'),
      ),
      (
        'Dịch vụ',
        CupertinoIcons.cart_fill,
        const Color(0xFF8B5CF6),
        const Color(0xFFA78BFA),
        'assets/images/features/local_services.png',
        () =>
            context.push('/tenant-addons', extra: {'roomId': contract.roomId}),
      ),
      (
        'Smart Lock',
        CupertinoIcons.lock_fill,
        const Color(0xFF374151),
        const Color(0xFF6B7280),
        'assets/images/features/iot_smart_key.png',
        () => Navigator.push(
          context,
          CupertinoPageRoute(builder: (c) => const TenantSmartLockScreen()),
        ),
      ),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: actions.asMap().entries.map((entry) {
        final idx = entry.key;
        final item = entry.value;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: TweenAnimationBuilder<double>(
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
                  unawaited(item.$6());
                },
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 4,
                  ),
                  borderRadius: 20,
                  border: Border.all(color: item.$3.withValues(alpha: 0.2)),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              item.$3.withValues(alpha: 0.8),
                              item.$4.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: item.$3.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          item.$5,
                          width: 34,
                          height: 34,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.$1,
                        style: const TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGridMenu(dynamic contract) {
    final items = [
      (
        'Hợp đồng',
        CupertinoIcons.doc_text_fill,
        AppTheme.kBrandDeep,
        AppTheme.kBrandLight,
        'assets/images/features/feat_contracts.png',
      ),
      (
        'Bảng Tin',
        CupertinoIcons.news_solid,
        AppTheme.kWarning,
        const Color(0xFFFBBF24),
        'assets/images/features/community_board.png',
      ),
      (
        'Chia Tiền',
        CupertinoIcons.person_3_fill,
        AppTheme.kSuccess,
        const Color(0xFF34D399),
        'assets/images/features/bill_splitting.png',
      ),
      (
        'Người ở cùng',
        CupertinoIcons.person_2_fill,
        const Color(0xFF8B5CF6),
        const Color(0xFFA78BFA),
        'assets/images/features/ai_roommate.png',
      ),
      (
        'Smart Home',
        CupertinoIcons.lightbulb_fill,
        const Color(0xFFEA580C),
        const Color(0xFFFB923C),
        'assets/images/features/iot_management.png',
      ),
      (
        'Trả phòng',
        CupertinoIcons.arrow_right_square_fill,
        AppTheme.kError,
        const Color(0xFFF87171),
        'assets/images/features/move_checklist.png',
      ),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.95,
      ),
      itemCount: 6,
      itemBuilder: (ctx, i) => AnimatedEntrance(
        delay: Duration(milliseconds: 100 + i * 50),
        child: GestureDetector(
          onTap: () async {
            if (items[i].$1 == 'Hợp đồng') {
              unawaited(context.push('/contract'));
            } else if (items[i].$1 == 'Bảng Tin') {
              unawaited(
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (c) => const TenantCommunityBoard(),
                  ),
                ),
              );
            } else if (items[i].$1 == 'Chia Tiền') {
              unawaited(
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (c) => const TenantBillSplitter(),
                  ),
                ),
              );
            } else if (items[i].$1 == 'Người ở cùng') {
              unawaited(
                context.push(
                  '/roommates',
                  extra: {
                    'contractId': contract.id,
                    'roomId': contract.roomId,
                    'roomName': 'Phòng của bạn',
                  },
                ),
              );
            } else if (items[i].$1 == 'Smart Home') {
              unawaited(context.push('/smart-home-controller'));
            } else if (items[i].$1 == 'Trả phòng') {
              final nav = Navigator.of(context);
              final router = GoRouter.of(context);
              // Show loading indicator inunawaited( dialog to prevent multiple clicks)
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
                // Wait for the provider to resolve, then check active requests
                final requests = await ref.read(
                  tenantCheckoutRequestsProvider.future,
                );
                final activeRequest = requests
                    .where((r) => r.contractId == contract.id)
                    .firstOrNull;

                if (!context.mounted) return;
                nav.pop(); // Close loading dialog

                if (activeRequest != null &&
                    activeRequest.status != 'COMPLETED') {
                  if (activeRequest.status == 'PENDING' ||
                      activeRequest.status == 'APPROVED' ||
                      activeRequest.status == 'REJECTED') {
                    unawaited(
                      router.push(
                        '/checkout-request',
                        extra: {
                          'contract': contract,
                          'previousRequest': activeRequest,
                        },
                      ),
                    );
                  } else {
                    unawaited(
                      router.push(
                        '/tenant/checkout-tracking',
                        extra: {'request': activeRequest, 'contract': contract},
                      ),
                    );
                  }
                } else {
                  unawaited(
                    router.push(
                      '/checkout-request',
                      extra: {
                        'contract': contract,
                        'previousRequest': activeRequest,
                      },
                    ),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                nav.pop(); // unawaited(Close loading dialog)
                unawaited(
                  showCupertinoDialog(
                    context: context,
                    builder: (ctx) => CupertinoAlertDialog(
                      title: const Text('Lỗi'),
                      content: Text('Lỗi tải dữ liệu: $e'),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: items[i].$3.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [items[i].$3, items[i].$4],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: items[i].$3.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    items[i].$5,
                    width: 38,
                    height: 38,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  items[i].$1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpgradeBanner() {
    return GestureDetector(
      onTap: () {
        unawaited(
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (c) => const TenantPremiumHubScreen()),
          ),
        );
      },
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        borderRadius: 24,
        color: AppTheme.kAccentColor.withValues(alpha: 0.1),
        blur: 20,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.kAccentColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                CupertinoIcons.star_fill,
                color: CupertinoColors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Siêu Tiện Ích Người Thuê',
                    style: TextStyle(
                      color: AppTheme.kTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Khám phá 20 tính năng StayHub cao cấp',
                    style: TextStyle(
                      color: AppTheme.kTextSecondary,
                      fontSize: 14,
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
    );
  }

  Widget _buildRequestingUI() {
    return const Center(
      child: Column(
        children: [
          SizedBox(height: 100),
          CupertinoActivityIndicator(radius: 20, color: AppTheme.kAccentColor),
          SizedBox(height: 24),
          Text(
            'Hồ sơ đang thẩm định',
            style: TextStyle(
              color: CupertinoColors.black,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Admin đang kiểm tra thông tin chủ trọ của bạn.\nVui lòng quay lại sau.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF4B5563), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingForContractUI() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 100),
          const CupertinoActivityIndicator(
            radius: 20,
            color: AppTheme.kAccentColor,
          ),
          const SizedBox(height: 24),
          const Text(
            'Đang chờ ký hợp đồng',
            style: TextStyle(
              color: CupertinoColors.black,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Nghiệm thu thành công.\nChủ trọ đang tiến hành soạn thảo hợp đồng cho bạn.\nVui lòng chờ trong giây lát.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF4B5563), fontSize: 14),
          ),
          const SizedBox(height: 48),
          GlassButton(
            text: 'Làm mới',
            icon: CupertinoIcons.refresh,
            color: AppTheme.kAccentColor,
            onPressed: () {
              unawaited(ref.read(contractProvider.notifier).refreshContracts());
            },
          ),
        ],
      ),
    );
  }
}
