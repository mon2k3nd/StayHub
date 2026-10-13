import 'package:flutter/cupertino.dart';

import '../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/liquid_background.dart';
import '../../../core/constants/role_types.dart';
import 'tenant_home_screen.dart';
import '../../bill/presentation/bill_screen.dart';
import '../../auth/application/auth_notifier.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/custom_sse_client.dart';
import 'dart:convert';
import 'package:stayhub_frontend/core/components/stayhub_logo_icon.dart';

import '../application/tenant_dashboard_notifier.dart';
import 'initial_bill_warning_card.dart';
import 'business_landing_screen.dart';
import 'checkin_verification_screen.dart';
import '../../chat/presentation/chat_list_screen.dart';
import '../../guest/presentation/guest_main_scaffold.dart';
import 'rental_scan_landing_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import 'dart:async' show unawaited;

class TenantDashboard extends ConsumerStatefulWidget {
  const TenantDashboard({super.key});

  @override
  ConsumerState<TenantDashboard> createState() => _TenantDashboardState();
}

class _TenantDashboardState extends ConsumerState<TenantDashboard> {
  CustomSseClient? _sseClient;

  @override
  void initState() {
    super.initState();
    unawaited(_listenToApproval());
  }

  Future<void> _listenToApproval() async {
    final user = ref.read(authProvider).value;
    if (user == null) return;

    // Dùng chung nguồn base URL với ApiClient để tránh lệch cấu hình
    // (trước đây hardcode ngrok URL đã chết → SSE không bao giờ kết nối được).
    final url = '${ApiClient.baseUrl}/v1/rental-requests/stream/${user.id}';

    _sseClient = CustomSseClient();
    _sseClient!
        .subscribeToSSE(
          method: SSERequestType.get,
          url: url,
          header: {
            "Accept": "text/event-stream",
            "Cache-Control": "no-cache",
            "ngrok-skip-browser-warning": "true",
          },
        )
        .listen((event) {
          if (event.data != null && event.data!.isNotEmpty) {
            try {
              final data = jsonDecode(event.data!);
              if (data['status'] == 'APPROVED_WAITING_HANDOVER') {
                if (mounted) {
                  // Gọi Notifier cập nhật state để tự động chuyển sang Tab Nghiệm thu
                  unawaited(
                    ref.read(tenantDashboardProvider.notifier).checkStatus(),
                  );
                }
              }
            } catch (e, st) {
              debugPrint('Error: $e\n$st');
            }
          }
        });
  }

  @override
  void dispose() {
    _sseClient?.unsubscribeFromSSE();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authProvider);
    final authUser = authAsync.value;

    // Guard: while auth is loading (e.g. after web page refresh), show spinner
    if (authAsync.isLoading) {
      return const CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemBackground,
        child: Center(child: CupertinoActivityIndicator(radius: 16)),
      );
    }

    // ── GUEST MODE: show Guest Marketplace ──────────
    if (authUser == null) {
      return const GuestMainScaffold();
    }

    // ── LOGGED IN: show full dashboard ──────────────────────────────────────
    final dashboardState = ref.watch(tenantDashboardProvider);

    if (dashboardState.tenantState == TenantState.unlinked ||
        dashboardState.tenantState == TenantState.pendingApproval) {
      return const GuestMainScaffold();
    }

    return _DashboardContent(
      dashboardState: dashboardState,
      buildTabViews: () => _buildTabViews(dashboardState),
      buildNavBar: () => _buildFloatingNavBar(dashboardState),
      onQRScannerTap: () {
        final user = ref.read(authProvider).value;
        if (user == null) {
          _showLoginPrompt();
        } else {
          // Show new rental scan landing screen instead of directly opening scanner
          unawaited(
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) => const RentalScanLandingScreen(),
              ),
            ),
          );
        }
      },
    );
  }

  void _showLoginPrompt() {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Yêu cầu Đăng nhập'),
          content: const Text('Bạn cần đăng nhập để sử dụng tính năng này.'),
          actions: [
            CupertinoDialogAction(
              child: const Text(
                'Để sau',
                style: TextStyle(color: AppTheme.kTextSecondary),
              ),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text(
                'Đăng nhập ngay',
                style: TextStyle(color: AppTheme.kAccentColor),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                unawaited(context.push('/login'));
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTabViews(TenantDashboardState state) {
    switch (state.tenantState) {
      case TenantState.unlinked:
      case TenantState.pendingApproval:
        return [
          const GuestMainScaffold(),
          const ChatListScreen(),
          const BusinessLandingScreen(),
          const ProfileScreen(),
        ];
      case TenantState.verifying:
        return [
          TenantHomeScreen(state: state.tenantState),
          const ChatListScreen(),
          CheckinVerificationScreen(room: state.verificationRoom),
          const ProfileScreen(),
        ];
      case TenantState.linked:
      default:
        return [
          TenantHomeScreen(state: state.tenantState),
          const ChatListScreen(),
          const BillScreen(),
          const ProfileScreen(),
        ];
    }
  }

  // Removed _buildProfileTab() and its sub-methods since they are moved to profile_screen.dart

  // Thanh Bottom Navigation Bar nổi phong cách Liquid Glass
  Widget _buildFloatingNavBar(TenantDashboardState state) {
    List<(IconData?, String)> tabs;

    switch (state.tenantState) {
      case TenantState.unlinked:
      case TenantState.pendingApproval:
        tabs = [
          (null, 'Tìm trọ'),
          (CupertinoIcons.chat_bubble_fill, 'Tin nhắn'),
          (CupertinoIcons.briefcase_fill, 'Kinh doanh'),
          (CupertinoIcons.person_fill, 'Cá nhân'),
        ];
        break;
      case TenantState.verifying:
        tabs = [
          (null, 'Phòng'),
          (CupertinoIcons.chat_bubble_fill, 'Tin nhắn'),
          (CupertinoIcons.doc_checkmark_fill, 'Nghiệm thu'),
          (CupertinoIcons.person_fill, 'Cá nhân'),
        ];
        break;
      case TenantState.linked:
      default:
        tabs = [
          (null, 'Phòng'),
          (CupertinoIcons.chat_bubble_fill, 'Tin nhắn'),
          (CupertinoIcons.doc_text_fill, 'Hóa đơn'),
          (CupertinoIcons.person_fill, 'Cá nhân'),
        ];
        break;
    }

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        GlassContainer(
          borderRadius: 36,
          blur: 24,
          color: CupertinoColors.white.withValues(alpha: 0.85),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(tabs.length, (index) {
              final tabIndex = index;
              final isActive = state.selectedTab == tabIndex;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  ref.read(tenantDashboardProvider.notifier).setTab(tabIndex);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  padding: EdgeInsets.symmetric(
                    horizontal: isActive ? 12 : 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? LiquidGlassColors.tenantAccent.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedScale(
                        scale: isActive ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        child: tabs[tabIndex].$1 == null
                            ? StayHubLogoIcon(
                                size: 24,
                                color: isActive
                                    ? LiquidGlassColors.tenantAccent
                                    : const Color(0xFF9CA3AF),
                              )
                            : Icon(
                                tabs[tabIndex].$1,
                                color: isActive
                                    ? LiquidGlassColors.tenantAccent
                                    : const Color(0xFF9CA3AF),
                                size: 24,
                              ),
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        child: SizedBox(
                          height: isActive ? 16 : 0,
                          width: isActive ? null : 0,
                          child: AnimatedOpacity(
                            opacity: isActive ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                tabs[tabIndex].$2,
                                style: const TextStyle(
                                  color: LiquidGlassColors.tenantAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final TenantDashboardState dashboardState;
  final List<Widget> Function() buildTabViews;
  final Widget Function() buildNavBar;
  final VoidCallback onQRScannerTap;

  const _DashboardContent({
    required this.dashboardState,
    required this.buildTabViews,
    required this.buildNavBar,
    required this.onQRScannerTap,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: LiquidBackground(
        colors: AppTheme.kBackgroundLight,
        child: dashboardState.isLoading
            ? const Center(child: CupertinoActivityIndicator(radius: 20))
            : Stack(
                children: [
                  Positioned.fill(
                    child: IndexedStack(
                      index: dashboardState.selectedTab,
                      children: buildTabViews(),
                    ),
                  ),
                  Positioned(
                    bottom: MediaQuery.of(context).padding.bottom + 16,
                    left: 24,
                    right: 24,
                    child: buildNavBar(),
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 16,
                    right: 16,
                    child: const InitialBillWarningCard(),
                  ),
                ],
              ),
      ),
    );
  }
}
