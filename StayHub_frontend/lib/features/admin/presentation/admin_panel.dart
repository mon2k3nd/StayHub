import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/liquid_background.dart';
import '../../../core/components/liquid_glass_speed_dial.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/admin_kyc_notifier.dart';
import '../application/admin_owner_notifier.dart';
import 'admin_dashboard_screen.dart' hide adminDashboardProvider;
import 'admin_owner_management_screen.dart';
import 'financial_analytics_screen.dart';
import '../../../core/components/app_error_widget.dart';
import 'dart:async' show unawaited;

// ─────────────────────────────────────────────
// Admin Panel – Cupertino iOS 26 Liquid Glass
// Panel quản trị hệ thống StayHub dành cho Super Admin
// ─────────────────────────────────────────────
class AdminPanel extends ConsumerStatefulWidget {
  const AdminPanel({super.key});

  @override
  ConsumerState<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends ConsumerState<AdminPanel> {
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
                  const AdminDashboardScreen(),
                  const FinancialAnalyticsScreen(),
                  const AdminOwnerManagementScreen(),
                  _buildApprovalsTab(),
                  _buildSettingsTab(),
                ],
              ),
            ),

            // Thanh Bottom Bar nổi quản trị
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 24,
              right: 24,
              child: _buildFloatingNavBar(),
            ),

            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 90,
              right: 24,
              child: LiquidGlassSpeedDial(
                primaryColor: CupertinoColors.systemRed,
                openIcon: CupertinoIcons.sparkles,
                actions: [
                  SpeedDialAction(
                    label: 'Platform BI',
                    icon: CupertinoIcons.graph_square_fill,
                    color: CupertinoColors.activeOrange,
                    onTap: () => context.push('/admin-advanced-analytics'),
                  ),
                  SpeedDialAction(
                    label: 'Quản lý Chủ nhà',
                    icon: CupertinoIcons.building_2_fill,
                    color: CupertinoColors.systemOrange,
                    onTap: () => context.push('/admin-owners'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tab Phê duyệt tài khoản Chủ trọ
  Widget _buildApprovalsTab() {
    final kycAsync = ref.watch(adminKycProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const CupertinoSliverNavigationBar(
          largeTitle: Text(
            'Phê Duyệt',
            style: TextStyle(color: CupertinoColors.black),
          ),
          backgroundColor: Color(0x00000000),
          border: null,
          transitionBetweenRoutes: false,
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          sliver: kycAsync.when(
            data: (requests) {
              if (requests.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Không có yêu cầu chờ duyệt.',
                      style: TextStyle(color: Color(0xFF4B5563)),
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate((ctx, i) {
                  final req = requests[i];
                  // BUGFIX (data): coerce id an toàn — tránh `as int` ném
                  // TypeError khi id là String/null từ JSON.
                  final rawId = req['id'];
                  final reqId = rawId is num
                      ? rawId.toInt()
                      : int.tryParse(rawId?.toString() ?? '') ?? 0;
                  return _buildApprovalItem(
                    reqId,
                    req['fullName'] ?? 'Chưa cập nhật',
                    req['phone'] ?? 'Chưa cập nhật',
                    'CCCD: ${req['cccdNumber'] ?? 'Chưa cập nhật'}',
                    'Email: ${req['email'] ?? 'Chưa cập nhật'}',
                  );
                }, childCount: requests.length),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CupertinoActivityIndicator()),
            ),
            error: (err, _) =>
                SliverFillRemaining(child: AppErrorWidget(error: err)),
          ),
        ),
      ],
    );
  }

  // Tab Cấu hình hệ thống (Settings) - iOS Style
  Widget _buildSettingsTab() {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        const CupertinoSliverNavigationBar(
          largeTitle: Text(
            'Cấu Hình',
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
              _buildSectionTitle('Quản lý thông số'),
              const SizedBox(height: 12),
              GlassContainer(
                padding: EdgeInsets.zero,
                borderRadius: 20,
                child: Column(
                  children: [
                    _buildMenuRow(
                      CupertinoIcons.sparkles,
                      'Quản lý Feature Toggles',
                      CupertinoColors.activeGreen,
                      () => context.push('/admin-feature-toggles'),
                      'assets/images/features/rbac.png',
                    ),
                    _buildIndentedDivider(),
                    _buildMenuRow(
                      CupertinoIcons.chart_bar_alt_fill,
                      'Tổng quan hệ thống',
                      LiquidGlassColors.adminAccent,
                      () => context.push('/admin-dashboard'),
                      'assets/images/features/feat_analytics.png',
                    ),
                    _buildIndentedDivider(),
                    _buildMenuRow(
                      CupertinoIcons.graph_square_fill,
                      'Business Intelligence (Đẳng cấp)',
                      CupertinoColors.activeOrange,
                      () => context.push('/admin-advanced-analytics'),
                      'assets/images/features/ai_financial.png',
                    ),
                    _buildIndentedDivider(),
                    _buildMenuRow(
                      CupertinoIcons.building_2_fill,
                      'Quản lý Chủ nhà',
                      CupertinoColors.systemOrange,
                      () => context.push('/admin-owners'),
                      'assets/images/features/multi_property.png',
                    ),
                    _buildIndentedDivider(),
                    _buildMenuRow(
                      CupertinoIcons.map_fill,
                      'Bản đồ Tọa độ',
                      CupertinoColors.systemGreen,
                      () => context.push('/admin-geo-map'),
                      'assets/images/features/competitor_analysis.png',
                    ),
                    _buildIndentedDivider(),
                    _buildMenuRow(
                      CupertinoIcons.cart_fill,
                      'Quản trị SaaS',
                      CupertinoColors.systemPink,
                      () => context.push('/admin-saas'),
                      'assets/images/features/marketing_campaign.png',
                    ),
                    _buildIndentedDivider(),
                    _buildMenuRow(
                      CupertinoIcons.doc_text_fill,
                      'Hợp đồng Pháp lý',
                      CupertinoColors.systemBlue,
                      () => context.push('/admin-legal-blueprints'),
                      'assets/images/features/smart_contract.png',
                    ),
                    _buildIndentedDivider(),
                    _buildMenuRow(
                      CupertinoIcons.bell_fill,
                      'Tạo Thông báo Hệ thống',
                      CupertinoColors.systemPurple,
                      () => context.push('/admin-notifications'),
                      'assets/images/features/broadcast_msg.png',
                    ),
                    _buildIndentedDivider(),
                    _buildMenuRow(
                      CupertinoIcons.time_solid,
                      'Audit Logs',
                      AppTheme.kAccentColor,
                      () => context.push('/admin-audit-logs'),
                      'assets/images/features/auto_pnl_export.png',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () async {
                  unawaited(HapticFeedback.heavyImpact());
                  await ref.read(authProvider.notifier).logout();
                  if (mounted) {
                    context.go('/login');
                  }
                },
                child: GlassContainer(
                  color: CupertinoColors.systemRed.withValues(alpha: 0.1),
                  border: Border.all(
                    color: CupertinoColors.systemRed.withValues(alpha: 0.2),
                  ),
                  borderRadius: 20,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: const Center(
                    child: Text(
                      'Đăng Xuất Admin',
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

  Widget _buildMenuRow(
    IconData icon,
    String title,
    Color iconColor, [
    VoidCallback? onTap,
    String? imagePath,
  ]) {
    return GestureDetector(
      onTap: () {
        unawaited(HapticFeedback.selectionClick());
        if (onTap != null) onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            if (imagePath != null)
              Image.asset(
                imagePath,
                width: 24,
                height: 24,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                isAntiAlias: true,
                errorBuilder: (_, __, ___) =>
                    Icon(icon, color: iconColor, size: 22),
              )
            else
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
      ),
    );
  }

  Widget _buildIndentedDivider() {
    return Container(
      margin: const EdgeInsets.only(left: 56, right: 20),
      height: 0.5,
      color: const Color(0xFFE5E7EB),
    );
  }

  Widget _buildApprovalItem(
    int id,
    String name,
    String phone,
    String details,
    String region,
  ) {
    return _KycApprovalCard(
      id: id,
      name: name,
      phone: phone,
      details: details,
      region: region,
      onApprove: () async {
        unawaited(HapticFeedback.lightImpact());
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) =>
                const Center(child: CupertinoActivityIndicator(radius: 16)),
            barrierDismissible: false,
          ),
        );
        final success = await ref.read(adminKycProvider.notifier).approve(id);
        if (mounted) {
          Navigator.pop(context);
          _showResultDialog(
            success ? 'Đã duyệt yêu cầu thành công.' : 'Lỗi khi duyệt yêu cầu.',
          );
        }
      },
      onReject: (reason) async {
        unawaited(HapticFeedback.lightImpact());
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) =>
                const Center(child: CupertinoActivityIndicator(radius: 16)),
            barrierDismissible: false,
          ),
        );
        final success = await ref
            .read(adminKycProvider.notifier)
            .reject(id, reason);
        if (mounted) {
          Navigator.pop(context);
          _showResultDialog(
            success ? 'Đã từ chối yêu cầu.' : 'Lỗi khi từ chối yêu cầu.',
          );
        }
      },
    );
  }

  void _showResultDialog(String message) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Thông báo'),
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

  Widget _buildFloatingNavBar() {
    // Get pending KYC count for badge on tab 3
    final pendingCount =
        ref.watch(adminPendingOwnersCountProvider).whenData((c) => c).value ??
        0;

    final tabs = [
      (CupertinoIcons.chart_bar_alt_fill, 'Hệ thống', 0),
      (CupertinoIcons.money_dollar_circle_fill, 'Tài chính', 0),
      (CupertinoIcons.building_2_fill, 'Chủ nhà', 0),
      (
        CupertinoIcons.person_crop_circle_badge_checkmark,
        'Phê duyệt',
        pendingCount,
      ),
      (CupertinoIcons.settings_solid, 'Cấu hình', 0),
    ];

    return GlassContainer(
      borderRadius: 36,
      blur: 20,
      color: const Color(0xE5FFFFFF),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(tabs.length, (i) {
          final isActive = _selectedTab == i;
          return Expanded(
            flex: isActive ? 2 : 1,
            child: _AdminFloatingNavBarItem(
              icon: tabs[i].$1,
              label: tabs[i].$2,
              badgeCount: tabs[i].$3,
              isActive: isActive,
              onTap: () {
                unawaited(HapticFeedback.lightImpact());
                setState(() => _selectedTab = i);
              },
            ),
          );
        }),
      ),
    );
  }
}

class _AdminFloatingNavBarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final int badgeCount;
  final VoidCallback onTap;

  const _AdminFloatingNavBarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  State<_AdminFloatingNavBarItem> createState() =>
      _AdminFloatingNavBarItemState();
}

class _AdminFloatingNavBarItemState extends State<_AdminFloatingNavBarItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        unawaited(_controller.reverse());
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: widget.isActive
                ? LiquidGlassColors.adminAccent.withValues(alpha: 0.15)
                : const Color(0x00000000),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    widget.icon,
                    color: widget.isActive
                        ? LiquidGlassColors.adminAccent
                        : const Color(0xFF9CA3AF),
                    size: widget.isActive ? 26 : 24,
                  ),
                  if (widget.badgeCount > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: CupertinoColors.systemRed,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${widget.badgeCount > 9 ? '9+' : widget.badgeCount}',
                          style: const TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedOpacity(
                opacity: widget.isActive ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: widget.isActive
                    ? Text(
                        widget.label,
                        style: const TextStyle(
                          color: LiquidGlassColors.adminAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : const SizedBox(height: 0, width: 0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── KYC Approval Card (Expandable) ──────────────────────────────────────────
class _KycApprovalCard extends StatefulWidget {
  final int id;
  final String name;
  final String phone;
  final String details; // CCCD number
  final String region; // email
  final VoidCallback onApprove;
  final Future<void> Function(String reason) onReject;

  const _KycApprovalCard({
    required this.id,
    required this.name,
    required this.phone,
    required this.details,
    required this.region,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<_KycApprovalCard> createState() => _KycApprovalCardState();
}

class _KycApprovalCardState extends State<_KycApprovalCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: LiquidGlassColors.adminAccent.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // ─── Header ───────────────────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Pulsing avatar
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1.0, end: 1.1),
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeInOut,
                    builder: (ctx, value, child) {
                      return Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: LiquidGlassColors.adminAccent.withValues(
                            alpha: 0.1,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: LiquidGlassColors.adminAccent.withValues(
                                alpha: 0.2 * (value - 1.0) * 10,
                              ),
                              blurRadius: 15 * value,
                              spreadRadius: 5 * value,
                            ),
                          ],
                        ),
                        child: const Icon(
                          CupertinoIcons.person_fill,
                          color: LiquidGlassColors.adminAccent,
                          size: 24,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          style: const TextStyle(
                            color: CupertinoColors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${widget.phone}  •  ${widget.region}',
                          style: const TextStyle(
                            color: Color(0xFF4B5563),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.details,
                          style: const TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Pending badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemOrange.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Chờ duyệt',
                      style: TextStyle(
                        color: CupertinoColors.systemOrange,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    size: 14,
                    color: const Color(0xFF9CA3AF),
                  ),
                ],
              ),
            ),
          ),

          // ─── Expanded: Photo Preview + Actions ────────────────────────
          if (_expanded) ...[
            Container(
              height: 0.5,
              color: const Color(0xFFE5E7EB),
              margin: const EdgeInsets.symmetric(horizontal: 16),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ảnh CCCD & Selfie',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    children: [
                      _PhotoThumb(label: 'CCCD Mặt trước', url: null),
                      SizedBox(width: 8),
                      _PhotoThumb(label: 'CCCD Mặt sau', url: null),
                      SizedBox(width: 8),
                      _PhotoThumb(label: 'Selfie', url: null),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            unawaited(HapticFeedback.lightImpact());
                            widget.onApprove();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: LiquidGlassColors.adminAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                '✓ Duyệt KYC',
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _showRejectDialog(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemRed.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: CupertinoColors.systemRed.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                '✕ Từ chối',
                                style: TextStyle(
                                  color: CupertinoColors.systemRed,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final reasonCtrl = TextEditingController(
      text: 'Hình ảnh mờ hoặc không khớp thông tin',
    );
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Lý do từ chối KYC'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: CupertinoTextField(
              controller: reasonCtrl,
              placeholder: 'Nhập lý do từ chối...',
              maxLines: 3,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Hủy'),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Xác nhận từ chối'),
              onPressed: () {
                Navigator.pop(ctx);
                unawaited(widget.onReject(reasonCtrl.text));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  final String label;
  final String? url;
  const _PhotoThumb({required this.label, required this.url});

  // Dùng chung nguồn base URL với ApiClient (trước đây hardcode ngrok URL đã chết).
  static String get _baseUrl => ApiClient.baseUrl;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: url != null
                    ? LiquidGlassColors.adminAccent.withValues(alpha: 0.4)
                    : const Color(0xFFD1D5DB),
              ),
            ),
            child: url != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.network(
                      '$_baseUrl$url',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => const Icon(
                        CupertinoIcons.photo,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  )
                : const Center(
                    child: Icon(
                      CupertinoIcons.photo_fill_on_rectangle_fill,
                      color: Color(0xFF9CA3AF),
                      size: 24,
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
