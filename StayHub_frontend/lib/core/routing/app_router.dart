import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Scaffold, AppBar, IconButton, TextButton;
import 'package:go_router/go_router.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/setup_social_password_screen.dart';
import '../../features/auth/presentation/settings_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/auth/presentation/biometric_lock_screen.dart';
import '../../features/auth/presentation/avatar_update_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/dashboard/presentation/owner_dashboard.dart';
import '../../features/dashboard/presentation/owner_subscription_screen.dart';
import '../../features/tenant/presentation/tenant_dashboard_screen.dart';
import '../../features/staff/presentation/staff_dashboard.dart';
import '../../features/admin/presentation/admin_panel.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/admin/presentation/advanced_admin_analytics_screen.dart';
import '../../features/dashboard/presentation/advanced_owner_analytics_screen.dart';
import '../../features/admin/presentation/admin_owner_management_screen.dart';
import '../../features/admin/presentation/admin_geo_map_screen.dart';
import '../../features/admin/presentation/system_legal_blueprints_screen.dart';
import '../../features/admin/presentation/admin_audit_logs_screen.dart';
import '../../features/admin/presentation/admin_saas_management_screen.dart';
import '../../features/admin/presentation/admin_notification_screen.dart';
import '../../features/admin/presentation/admin_feature_toggles_screen.dart';
import '../../features/notification/presentation/notification_center_screen.dart';
import '../../features/tenant/presentation/room_search_screen.dart';
import '../../features/branch/presentation/branch_management_screen.dart';
import '../../features/branch/presentation/branch_wizard_screen.dart';
import '../../features/branch/data/models/branch_model.dart';
import '../../features/room/presentation/room_grid_screen.dart';
import '../../features/room/presentation/room_detail_screen.dart';
import '../../features/room/presentation/room_qr_screen.dart';
import '../../features/room/presentation/qr_scanner_screen.dart';
import '../../features/room/presentation/room_members_screen.dart';

import '../../features/room/presentation/create_room_screen.dart';
import '../../features/room/presentation/create_rooms_wizard_screen.dart';
import '../../features/bill/presentation/bill_screen.dart';
import '../../features/contract/presentation/contract_screen.dart';
import '../../features/contract/presentation/rental_request_screen.dart';
import '../../features/contract/presentation/rental_requests_list_screen.dart';

import '../../features/contract/presentation/digital_signature_screen.dart';
import '../../features/contract/presentation/deposit_payment_screen.dart';
import '../../features/ticket/presentation/ticket_screen.dart';
import '../../features/ticket/presentation/create_ticket_screen.dart';
import '../../features/contract/presentation/contract_preview_screen.dart';
import '../../features/contract/presentation/offline_contract_create_screen.dart';
import '../../features/contract/presentation/offline_contract_verify_screen.dart';
import '../../features/contract/presentation/contract_template_edit_screen.dart';
import '../../features/staff/presentation/meter_reading_screen.dart';
import '../../features/bill/presentation/batch_meter_reading_screen.dart';
import '../../features/checkout/presentation/tenant_checkout_request_screen.dart';
import '../../features/checkout/presentation/owner_checkout_list_screen.dart';
import '../../features/checkout/presentation/owner_checkout_detail_screen.dart';
import '../../features/checkout/presentation/dispute_chat_screen.dart';
import '../../features/checkout/presentation/tenant_checkout_bill_screen.dart';
import '../../features/checkout/presentation/create_checkout_bill_screen.dart';
import '../../features/checkout/presentation/tenant_checkout_tracking_screen.dart';
import '../../features/tenant/presentation/bank_config_screen.dart';
import '../../features/checkout/data/models/checkout_request_model.dart';
import '../../features/contract/data/models/contract_model.dart';
import '../../features/contract/presentation/contract_list_screen.dart';
import '../../features/contract/presentation/contract_viewer_screen.dart';
import '../../features/bill/data/models/bill_model.dart';
import '../../features/tenant/presentation/profile_update_screen.dart';
import '../../features/chat/presentation/chat_list_screen.dart';
import '../../features/chat/presentation/direct_message_screen.dart';
import '../../features/chat/presentation/thread_message_screen.dart';
import '../../features/staff/presentation/staff_management_screen.dart';
import '../../features/staff/presentation/staff_ticket_detail_screen.dart';
import '../../features/staff/presentation/staff_handover_screen.dart';
import '../../features/dashboard/presentation/owner_control_center_screen.dart';
import '../../features/staff/presentation/staff_branch_room_screen.dart';
import '../../features/dashboard/presentation/owner_ai_assistant_screen.dart';
import 'not_found_screen.dart';

// ── Sprint 7: Tính năng mới ────────────────────────────────────────────────
import '../../features/staff/presentation/staff_permission_screen.dart';
import '../../features/dashboard/presentation/expense_management_screen.dart';
import '../../features/dashboard/presentation/vehicle_management_screen.dart';
import '../../features/dashboard/presentation/ct01_export_screen.dart';
import '../../features/search/presentation/tenant_profile_screen.dart';
import '../../features/notification/presentation/broadcast_screen.dart';
import '../../features/staff/presentation/owner_shift_management_screen.dart';
import '../../features/staff/presentation/staff_shift_schedule_screen.dart';
import '../../features/room/presentation/room_inventory_screen.dart';
import '../../features/addon/presentation/tenant_addon_screen.dart';
import '../../features/addon/presentation/owner_addon_screen.dart';
import '../../features/attendance/presentation/screens/owner_attendance_screen.dart';

import '../../features/guest/presentation/guest_main_scaffold.dart';
// guest_home_screen.dart removed – GuestHomeScreen đã được thay thế bởi
// GuestMainScaffold (Tab 0 = GuestLandingScreen).
// Route /guest-search hiện trỏ tới GuestMainScaffold(initialTab: 1).
import '../../features/marketplace/presentation/post_management_screen.dart';
import '../../features/marketplace/presentation/edit_post_screen.dart';
import '../../features/marketplace/presentation/post_preview_screen.dart';
import '../../features/bill/presentation/debt_management_screen.dart';
import '../../features/marketplace/presentation/guest_marketplace_screen.dart';
import '../../features/marketplace/presentation/promotion_management_screen.dart';
import '../../features/marketplace/presentation/guest_room_detail_screen.dart';
import '../../features/guest/presentation/compare_rooms_screen.dart';
import '../../features/guest/presentation/guest_saved_rooms_screen.dart';
import '../../features/marketplace/presentation/wishlist_screen.dart';
import '../../features/tenant/presentation/owner_tenant_list_screen.dart';
import '../../features/room/presentation/owner_smart_lock_screen.dart';
import '../../features/room/presentation/owner_electric_meter_screen.dart';
import '../../features/shared/presentation/screens/privacy_policy_screen.dart';
import '../../features/branch/presentation/rules_management_screen.dart';
import '../../features/branch/presentation/violation_management_screen.dart';
import '../../features/tenant/presentation/ekyc_verification_screen.dart';

import '../../features/cash/presentation/qr_cash_receiver_screen.dart';
import '../../features/cash/presentation/qr_cash_scanner_screen.dart';
import '../../features/complaint/presentation/screens/owner_complaint_list_screen.dart';
import '../../features/staff_task/presentation/screens/owner_task_kanban_screen.dart';
import '../../features/staff_task/presentation/screens/staff_task_receive_screen.dart';
import '../../features/attendance/presentation/screens/staff_attendance_screen.dart';
import '../../features/affiliate/presentation/owner_affiliate_screen.dart';
import '../../features/affiliate/presentation/admin_affiliate_dashboard.dart';
import '../../features/dashboard/presentation/owner_ai_call_campaign_screen.dart';
import '../../features/dashboard/presentation/ai_call_simulation_screen.dart';
import '../../features/bill/presentation/ai_receipt_scanner_screen.dart';
import '../../features/tenant/presentation/smart_home_controller_screen.dart';
import '../../features/branch/presentation/manage_service_pools_screen.dart';
import '../../features/analytics/presentation/utility_leakage_screen.dart';
import '../../features/analytics/presentation/meter_history_screen.dart';
import '../../features/voucher/presentation/screens/landlord_voucher_screen.dart';
import '../../features/tenant/presentation/business_landing_screen.dart';

// ─────────────────────────────────────────────
// AppRouter – GoRouter Configuration
// ─────────────────────────────────────────────
class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static Page _buildPage(Widget child) {
    return CupertinoPage(child: child);
  }

  /// Smooth, depth-aware transition used for auth screens (login / register /
  /// forgot-password / setup-social-password). Combines a gentle upward slide,
  /// a fade and a subtle scale so navigation feels graceful and layered while
  /// remaining fully iOS-native in spirit.
  static Page _buildAuthPage(Widget child) {
    return CustomTransitionPage(
      child: child,
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.985, end: 1.0).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
  }

  static final router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    errorBuilder: (context, state) =>
        NotFoundScreen(error: state.error?.toString()),
    routes: [
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => _buildPage(const OnboardingScreen()),
      ),
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _buildPage(const SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) {
          final extra = state.extra;
          final initialTab = (extra is Map<String, dynamic>)
              ? (extra['initialTab'] as int? ?? 0)
              : 0;
          return _buildAuthPage(LoginScreen(initialTab: initialTab));
        },
      ),
      GoRoute(
        path: '/setup-social-password',
        pageBuilder: (context, state) =>
            _buildAuthPage(const SetupSocialPasswordScreen()),
      ),
      GoRoute(
        path: '/avatar-update',
        pageBuilder: (context, state) =>
            _buildAuthPage(const AvatarUpdateScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) =>
            _buildAuthPage(const LoginScreen(initialTab: 1)),
      ),
      GoRoute(
        path: '/biometric',
        pageBuilder: (context, state) {
          final dest = state.extra as String? ?? '/owner-dashboard';
          return _buildPage(BiometricLockScreen(destinationRoute: dest));
        },
      ),
      GoRoute(
        path: '/guest',
        pageBuilder: (context, state) => _buildPage(const GuestMainScaffold()),
      ),
      // Alias công khai cho khách chưa đăng nhập (Splash, GuestAuthBottomSheet,
      // guest_room_detail, register_screen đều trỏ tới '/marketplace').
      // Trước đây route này bị thiếu → GoException "no routes for location".
      GoRoute(
        path: '/marketplace',
        pageBuilder: (context, state) => _buildPage(const GuestMainScaffold()),
      ),
      // Route tìm kiếm phòng từ GuestLandingScreen (_openMarketplace).
      // Mở GuestMainScaffold và tự động chuyển sang tab Tìm phòng (index 1).
      GoRoute(
        path: '/guest-search',
        pageBuilder: (context, state) =>
            _buildPage(const GuestMainScaffold(initialTab: 1)),
      ),
      GoRoute(
        path: '/privacy',
        pageBuilder: (context, state) =>
            _buildPage(const PrivacyPolicyScreen(showTerms: false)),
      ),
      GoRoute(
        path: '/terms',
        pageBuilder: (context, state) =>
            _buildPage(const PrivacyPolicyScreen(showTerms: true)),
      ),

      GoRoute(
        path: '/contract-list',
        pageBuilder: (context, state) => _buildPage(const ContractListScreen()),
      ),
      GoRoute(
        path: '/contract/detail/:id',
        pageBuilder: (context, state) => _buildPage(
          ContractViewerScreen(contractId: state.pathParameters['id'] ?? ''),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) =>
            _buildPage(const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: '/owner-dashboard',
        pageBuilder: (context, state) => _buildPage(const OwnerDashboard()),
      ),
      GoRoute(
        path: '/business-landing',
        pageBuilder: (context, state) =>
            _buildPage(const BusinessLandingScreen()),
      ),
      GoRoute(
        path: '/become-host',
        pageBuilder: (context, state) =>
            _buildPage(const BusinessLandingScreen()),
      ),
      GoRoute(
        path: '/owner/promotion-management',
        pageBuilder: (context, state) =>
            _buildPage(const PromotionManagementScreen()),
      ),
      GoRoute(
        path: '/owner-ai-assistant',
        pageBuilder: (context, state) =>
            _buildPage(const OwnerAiAssistantScreen()),
      ),
      GoRoute(
        path: '/owner-ai-call',
        pageBuilder: (context, state) =>
            _buildPage(const OwnerAiCallCampaignScreen()),
      ),
      GoRoute(
        path: '/ai-call-simulation',
        pageBuilder: (context, state) =>
            _buildPage(const AiCallSimulationScreen()),
      ),
      GoRoute(
        path: '/ai-receipt-scanner/:id',
        pageBuilder: (context, state) {
          final billIdStr = state.pathParameters['id'] ?? '0';
          return _buildPage(
            AiReceiptScannerScreen(billId: int.tryParse(billIdStr) ?? 0),
          );
        },
      ),
      GoRoute(
        path: '/smart-home-controller',
        pageBuilder: (context, state) =>
            _buildPage(const SmartHomeControllerScreen()),
      ),
      GoRoute(
        path: '/subscription-management',
        pageBuilder: (context, state) =>
            _buildPage(const OwnerSubscriptionScreen()),
      ),
      GoRoute(
        path: '/branch-rules',
        pageBuilder: (context, state) =>
            _buildPage(const RulesManagementScreen()),
      ),
      GoRoute(
        path: '/violations',
        pageBuilder: (context, state) =>
            _buildPage(const ViolationManagementScreen()),
      ),
      GoRoute(
        path: '/landlord-vouchers',
        pageBuilder: (context, state) =>
            _buildPage(const LandlordVoucherScreen()),
      ),
      GoRoute(
        path: '/tenant-dashboard',
        pageBuilder: (context, state) =>
            _buildPage(const TenantDashboardScreen()),
      ),
      GoRoute(
        path: '/tenant-profile/:id',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return _buildPage(TenantProfileScreen(tenantId: id));
        },
      ),
      GoRoute(
        path: '/staff-dashboard',
        pageBuilder: (context, state) => _buildPage(const StaffDashboard()),
      ),
      GoRoute(
        path: '/admin-panel',
        pageBuilder: (context, state) => _buildPage(const AdminPanel()),
      ),
      GoRoute(
        path: '/admin-dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin-owners',
        builder: (context, state) => const AdminOwnerManagementScreen(),
      ),

      GoRoute(
        path: '/owner/rooms/wizard',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return _buildPage(
            CreateRoomsWizardScreen(
              branchId: extra['branchId'] ?? 0,
              branchCode: extra['branchCode'] ?? '',
              totalRooms: extra['totalRooms'] ?? 1,
            ),
          );
        },
      ),
      GoRoute(
        path: '/owner/branch/:branchId/pools',
        pageBuilder: (context, state) {
          final branchId =
              int.tryParse(state.pathParameters['branchId'] ?? '0') ?? 0;
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return _buildPage(
            ManageServicePoolsScreen(
              branchId: branchId,
              branchName: extra['branchName'] as String? ?? 'Dãy trọ',
            ),
          );
        },
      ),
      GoRoute(
        path: '/room/:roomId/members',
        pageBuilder: (context, state) {
          final roomId =
              int.tryParse(state.pathParameters['roomId'] ?? '0') ?? 0;
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return _buildPage(
            RoomMembersScreen(
              roomId: roomId,
              roomName: extra['roomName'] as String? ?? 'Phòng',
            ),
          );
        },
      ),
      GoRoute(
        path: '/qr_cash_receiver',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return QrCashReceiverScreen(
            sessionType: extra['sessionType'] ?? 'STAFF_HANDOVER_CASH',
            branchId: extra['branchId'],
          );
        },
      ),
      GoRoute(
        path: '/qr_cash_scanner',
        builder: (context, state) => const QrCashScannerScreen(),
      ),
      GoRoute(
        path: '/complaints',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return OwnerComplaintListScreen(branchId: extra['branchId'] ?? 1);
        },
      ),
      GoRoute(
        path: '/staff-tasks',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return OwnerTaskKanbanScreen(branchId: extra['branchId'] ?? 1);
        },
      ),
      GoRoute(
        path: '/my-tasks',
        builder: (context, state) => const StaffTaskReceiveScreen(),
      ),
      GoRoute(
        path: '/my-attendance',
        builder: (context, state) => const StaffAttendanceScreen(),
      ),
      GoRoute(
        path: '/attendance',
        builder: (context, state) => const OwnerAttendanceScreen(),
      ),
      GoRoute(
        path: 'admin-geo-map',
        builder: (context, state) => const AdminGeoMapScreen(),
      ),
      GoRoute(
        path: 'admin-feature-toggles',
        builder: (context, state) => const AdminFeatureTogglesScreen(),
      ),
      GoRoute(
        path: 'admin-legal-blueprints',
        builder: (context, state) => const SystemLegalBlueprintsScreen(),
      ),
      GoRoute(
        path: '/admin-audit-logs',
        builder: (context, state) => const AdminAuditLogsScreen(),
      ),
      GoRoute(
        path: '/admin-saas',
        builder: (context, state) => const AdminSaasManagementScreen(),
      ),
      GoRoute(
        path: '/admin-notifications',
        builder: (context, state) => const AdminNotificationScreen(),
      ),
      GoRoute(
        path: '/owner-affiliate',
        builder: (context, state) => const OwnerAffiliateScreen(),
      ),
      GoRoute(
        path: '/admin-affiliate',
        builder: (context, state) => const AdminAffiliateDashboard(),
      ),
      GoRoute(
        path: '/owner-advanced-analytics',
        builder: (context, state) => const AdvancedOwnerAnalyticsScreen(),
      ),
      GoRoute(
        path: '/admin-advanced-analytics',
        builder: (context, state) => const AdvancedAdminAnalyticsScreen(),
      ),
      GoRoute(
        path: '/owner/branch/:branchId/utility-leakage',
        builder: (context, state) {
          final branchId =
              int.tryParse(state.pathParameters['branchId'] ?? '0') ?? 0;
          return UtilityLeakageScreen(branchId: branchId);
        },
      ),
      GoRoute(
        path: '/owner/branch/:branchId/meter-history',
        builder: (context, state) {
          final branchId =
              int.tryParse(state.pathParameters['branchId'] ?? '0') ?? 0;
          return MeterHistoryScreen(branchId: branchId);
        },
      ),
      GoRoute(
        path: '/room-search',
        builder: (context, state) => const RoomSearchScreen(),
      ),
      GoRoute(
        path: '/control-center',
        builder: (context, state) => const OwnerControlCenterScreen(),
      ),
      GoRoute(
        path: '/branch',
        builder: (context, state) => const BranchManagementScreen(),
      ),
      GoRoute(
        path: '/branch/wizard',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return BranchWizardScreen(branch: extra?['branch'] as BranchModel?);
        },
      ),

      GoRoute(
        path: '/room',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return RoomGridScreen(
            ownerId: extra['ownerId'] as int,
            branchId: extra['branchId'] as int?,
            branchName: extra['branchName'] as String,
          );
        },
      ),
      GoRoute(
        path: '/room-detail',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          // BUGFIX: ép cứng `as int` sẽ NÉM TypeError nếu call-site truyền
          // String/null. Parse khoan dung để không vỡ màn chi tiết phòng.
          final rawId = extra['roomId'];
          final int? roomId = rawId is int
              ? rawId
              : int.tryParse(rawId?.toString() ?? '');
          if (roomId == null) return const _InvalidRoomDetailView();
          return RoomDetailScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/guest-room-detail',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          // BUGFIX (không xem chi tiết phòng được): trước đây ép cứng
          // `extra['roomId'] as int?` → NÉM TypeError khi call-site truyền
          // String (vd `pending['roomId']` dynamic từ deep-link/login) và trả
          // về màn TRẮNG im lặng khi null. Nay parse khoan dung: nhận cả int
          // lẫn String số; nếu không hợp lệ thì hiện màn lỗi có nút quay lại
          // thay vì trắng màn.
          final rawId = extra['roomId'];
          final int? roomId = rawId is int
              ? rawId
              : int.tryParse(rawId?.toString() ?? '');
          if (roomId == null) {
            return const _InvalidRoomDetailView();
          }
          return GuestRoomDetailScreen(roomId: roomId);
        },
      ),
      // Route /guest-search cũ trỏ vào GuestHomeScreen đã bị xóa.
      // Route mới tại file này (line ~225) xử lý đường dẫn này đúng cách.
      GoRoute(
        path: '/compare-rooms',
        builder: (context, state) => const CompareRoomsScreen(),
      ),
      GoRoute(
        path: '/viewed-history',
        builder: (context, state) => const ViewedHistoryScreen(),
      ),
      GoRoute(
        path: '/saved-rooms',
        builder: (context, state) => const WishlistScreen(),
      ),
      GoRoute(
        path: '/room-qr',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return RoomQrScreen(
            roomId: extra['roomId'] as int,
            roomName: extra['roomName'] as String,
            branchId: extra['branchId'] as int,
            branchName: extra['branchName'] as String,
            price: extra['price'] as double,
          );
        },
      ),
      GoRoute(
        path: '/roommates',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return RoomMembersScreen(
            roomId: extra['roomId'] as int,
            roomName: extra['roomName'] as String,
          );
        },
      ),
      GoRoute(
        path: '/qr-scanner',
        builder: (context, state) => const QrScannerScreen(),
      ),
      GoRoute(path: '/bill', builder: (context, state) => const BillScreen()),
      // Ví điện tử — mở màn cấu hình ngân hàng/thanh toán VietQR.
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const BankConfigScreen(),
      ),
      GoRoute(
        path: '/owner-tenant-list',
        builder: (context, state) => const OwnerTenantListScreen(),
      ),
      GoRoute(
        path: '/owner-smart-lock',
        builder: (context, state) => const OwnerSmartLockScreen(),
      ),
      GoRoute(
        path: '/owner-electric-meter',
        builder: (context, state) => const OwnerElectricMeterScreen(),
      ),
      GoRoute(
        path: '/contract',
        builder: (context, state) => const ContractScreen(),
      ),
      GoRoute(
        path: '/rental-request',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return RentalRequestScreen(
            roomId: extra['roomId'] as int? ?? 0,
            roomName: extra['roomName'] as String? ?? '',
            branchId: extra['branchId'] as int?,
            branchName: extra['branchName'] as String?,
            price: extra['price'] as double? ?? 0.0,
            sessionToken: extra['sessionToken'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/profile-update',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ProfileUpdateScreen(
            nextRoute: extra['nextRoute'] as String? ?? '/tenant-dashboard',
            extraData: extra['extraData'] as Map<String, dynamic>?,
          );
        },
      ),
      GoRoute(
        path: '/digital-signature',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return DigitalSignatureScreen(
            contractId: extra['contractId'] as int? ?? 0,
          );
        },
      ),
      GoRoute(
        path: '/deposit-payment',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return DepositPaymentScreen(
            contractId: extra['contractId'] as int? ?? 0,
          );
        },
      ),
      GoRoute(
        path: '/contract-preview',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ContractPreviewScreen(
            contractId: extra['contractId'] as int? ?? 0,
          );
        },
      ),
      GoRoute(
        path: '/contract-sign',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return DigitalSignatureScreen(
            contractId: extra['contractId'] as int? ?? 0,
          );
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/offline-contract-create',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return OfflineContractCreateScreen(
            roomId: extra['roomId'] as int? ?? 0,
            roomName: extra['roomName'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/offline-contract-verify',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return OfflineContractVerifyScreen(
            roomId: extra['roomId'] as int? ?? 0,
            contractId: extra['contractId'] as int?,
          );
        },
      ),
      GoRoute(
        path: '/contract-template-edit',
        builder: (context, state) => const ContractTemplateEditScreen(),
      ),
      GoRoute(
        path: '/create-room',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return CreateRoomScreen(
            ownerId: extra['ownerId'] as int?,
            branchId: extra['branchId'] as int?,
            branchName: extra['branchName'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/rental-requests',
        builder: (context, state) => const RentalRequestsListScreen(),
      ),
      GoRoute(
        path: '/owner/post-management',
        builder: (context, state) => const PostManagementScreen(),
      ),
      GoRoute(
        path: '/owner/edit-post',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final room = extra['room'];
          final post = extra['post'];
          final branch = extra['branch'];
          final branchAddress = extra['branchAddress'] as String?;
          final branchLat = extra['branchLat'];
          final branchLng = extra['branchLng'];
          return EditPostScreen(
            room: room,
            post: post,
            branch: branch,
            branchAddress: branchAddress,
            branchLat: branchLat,
            branchLng: branchLng,
          );
        },
      ),
      GoRoute(
        path: '/owner/post-preview',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return PostPreviewScreen(
            room: extra['room'],
            post: extra['post'],
            previewImages: extra['previewImages'] as List<dynamic>?,
            branch: extra['branch'],
            branchAddress: extra['branchAddress'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationCenterScreen(),
      ),
      GoRoute(
        path: '/chat-list',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/ticket',
        builder: (context, state) => const TicketScreen(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const CreateTicketScreen(),
          ),
          GoRoute(
            path: 'ticket-detail/:id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return StaffTicketDetailScreen(ticketId: id);
            },
          ),
          GoRoute(
            path: 'staff-handover',
            builder: (context, state) => const StaffHandoverScreen(),
          ),
          GoRoute(
            path: '/owner-shifts',
            builder: (context, state) => const OwnerShiftManagementScreen(),
          ),
          GoRoute(
            path: '/staff-shifts',
            builder: (context, state) => const StaffShiftScheduleScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/meter-reading/:roomId',
        builder: (context, state) {
          final roomId = int.parse(state.pathParameters['roomId'] ?? '0');
          return MeterReadingScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/staff-branch-room/:branchId',
        builder: (context, state) {
          final branchId = int.parse(state.pathParameters['branchId'] ?? '0');
          final branchName = state.extra as String? ?? 'Danh sách phòng';
          return StaffBranchRoomScreen(
            branchId: branchId,
            branchName: branchName,
          );
        },
      ),
      GoRoute(
        path: '/batch-meter-reading/:branchId',
        builder: (context, state) {
          final branchId = int.parse(state.pathParameters['branchId'] ?? '0');
          return BatchMeterReadingScreen(branchId: branchId);
        },
      ),
      GoRoute(
        path: '/checkout-request',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return TenantCheckoutRequestScreen(
            contract: extra['contract'] as ContractModel,
            previousRequest: extra['previousRequest'] as CheckoutRequestModel?,
          );
        },
      ),
      GoRoute(
        path: '/owner/checkout-list',
        builder: (context, state) => const OwnerCheckoutListScreen(),
      ),
      GoRoute(
        path: '/owner/checkout-detail/:id',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return OwnerCheckoutDetailScreen(
            request: extra['request'] as CheckoutRequestModel,
            contract: extra['contract'] as ContractModel,
          );
        },
      ),
      GoRoute(
        path: '/dispute-chat',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return DisputeChatScreen(
            initialBill: extra['bill'] as BillModel,
            isOwner: extra['isOwner'] as bool? ?? false,
          );
        },
      ),
      GoRoute(
        path: '/tenant/checkout-bill',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return TenantCheckoutBillScreen(
            request: extra['request'] as CheckoutRequestModel,
            bill: extra['bill'] as BillModel,
          );
        },
      ),
      GoRoute(
        path: '/tenant/checkout-tracking',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return TenantCheckoutTrackingScreen(
            request: extra['request'] as CheckoutRequestModel,
            contract: extra['contract'] as ContractModel,
          );
        },
      ),
      GoRoute(
        path: '/tenant/checkout-bill',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return TenantCheckoutBillScreen(
            request: extra['request'] as CheckoutRequestModel,
            bill: extra['bill'] as BillModel,
          );
        },
      ),
      GoRoute(
        path: '/owner/create-checkout-bill',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return CreateCheckoutBillScreen(
            request: extra['request'] as CheckoutRequestModel,
            contract: extra['contract'] as ContractModel,
          );
        },
      ),
      GoRoute(
        path: '/direct-message/:roomId',
        builder: (context, state) {
          final roomIdStr = state.pathParameters['roomId'] ?? '0';
          // Extract numeric part if it's a mock string like "mock1"
          final numericMatch = RegExp(r'\d+').firstMatch(roomIdStr);
          final roomId = int.tryParse(numericMatch?.group(0) ?? '0') ?? 0;

          final extra = state.extra as Map<String, dynamic>? ?? {};
          return DirectMessageScreen(
            roomId: roomId,
            roomName: extra['roomName'] as String? ?? 'Phòng $roomId',
            otherPersonName:
                extra['otherPersonName'] as String? ?? 'Người dùng',
            showNegotiation: extra['showNegotiation'] as bool? ?? false,
          );
        },
      ),
      GoRoute(
        path: '/thread-message/:threadId',
        builder: (context, state) {
          final threadIdStr = state.pathParameters['threadId'] ?? '0';
          final numericMatch = RegExp(r'\d+').firstMatch(threadIdStr);
          final threadId = int.tryParse(numericMatch?.group(0) ?? '0') ?? 0;

          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ThreadMessageScreen(
            threadId: threadId,
            title: extra['title'] as String? ?? 'Người dùng',
            initialRoomAttachment:
                extra['initialRoomAttachment'] as Map<String, dynamic>?,
          );
        },
      ),
      GoRoute(
        path: '/staff-management',
        builder: (context, state) => const StaffManagementScreen(),
      ),

      // ── Sprint 7: Routes mới ──────────────────────────────────────────────
      GoRoute(
        path: '/staff-permissions',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return StaffPermissionScreen(staff: extra['staff'] as StaffModel);
        },
      ),
      GoRoute(
        path: '/expense-management',
        builder: (context, state) => const ExpenseManagementScreen(),
      ),
      GoRoute(
        path: '/vehicle-management',
        builder: (context, state) => const VehicleManagementScreen(),
      ),
      GoRoute(
        path: '/ct01-export',
        builder: (context, state) => const CT01ExportScreen(),
      ),
      GoRoute(
        path: '/broadcast',
        builder: (context, state) => const BroadcastScreen(),
      ),
      GoRoute(
        path: '/room-inventory',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return RoomInventoryScreen(
            roomId: extra['roomId'] as int? ?? 0,
            roomName: extra['roomName'] as String? ?? 'Phòng',
          );
        },
      ),
      GoRoute(
        path: '/tenant-addons',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return TenantAddonScreen(roomId: extra['roomId'] as int? ?? 0);
        },
      ),
      GoRoute(
        path: '/owner-addons',
        builder: (context, state) => const OwnerAddonScreen(),
      ),
      GoRoute(
        path: '/staff-attendance',
        builder: (context, state) => const StaffAttendanceScreen(),
      ),
      GoRoute(
        path: '/debt-management',
        builder: (context, state) => const DebtManagementScreen(),
      ),
      // Màn tìm trọ trên Bản đồ — tách riêng khỏi màn "lướt phòng".
      GoRoute(
        path: '/marketplace-map',
        builder: (context, state) =>
            const GuestMarketplaceScreen(initialMapView: true),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/ekyc-verification',
        builder: (context, state) {
          return EkycVerificationScreen(
            onVerificationComplete: () {
              if (context.canPop()) {
                context.pop();
              }
            },
          );
        },
      ),
      GoRoute(
        path: '/branch-rules',
        builder: (context, state) => const RulesManagementScreen(),
      ),
      GoRoute(
        path: '/violations',
        builder: (context, state) => const ViolationManagementScreen(),
      ),
    ],
  );
}

/// Màn lỗi hiển thị khi route chi tiết phòng nhận được ID KHÔNG hợp lệ
/// (thiếu, null, hoặc không parse được thành số).
///
/// <p>BUGFIX (không xem chi tiết phòng được): trước đây route trả về
/// `SizedBox.shrink()` → người dùng chỉ thấy màn TRẮNG, không biết vì sao và
/// không có cách quay lại. Nay hiện thông báo rõ ràng + nút quay lại.</p>
class _InvalidRoomDetailView extends StatelessWidget {
  const _InvalidRoomDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Color(0xFF1E293B)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/guest-search');
            }
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFE6F2FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.exclamationmark_circle,
                  color: Color(0xFF69B1FF),
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Không mở được chi tiết phòng',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Phòng này không tồn tại hoặc đã bị gỡ. Vui lòng chọn phòng khác.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/guest-search');
                    }
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF69B1FF),
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  child: const Text(
                    'Quay lại',
                    style: TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
