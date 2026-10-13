import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/liquid_background.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/tenant_owner_feature_provider.dart';
import 'features/tenant/tenant_ar_room_tour_screen.dart';
import 'features/tenant/tenant_smart_contract_screen.dart';
import 'features/tenant/tenant_one_tap_payment_screen.dart';
import 'features/tenant/tenant_bill_splitting_screen.dart';
import 'features/tenant/tenant_video_maintenance_screen.dart';
import 'features/tenant/tenant_iot_smart_key_screen.dart';
import 'features/tenant/tenant_utilities_dashboard_screen.dart';
import 'features/tenant/tenant_ai_roommate_screen.dart';
import 'features/tenant/tenant_loyalty_rewards_screen.dart';
import 'features/tenant/tenant_community_board_screen.dart';
import 'features/tenant/tenant_smart_locker_screen.dart';
import 'features/tenant/tenant_move_checklist_screen.dart';
import 'features/tenant/tenant_sos_panic_screen.dart';
import 'features/tenant/tenant_chatbot_screen.dart';
import 'features/tenant/tenant_local_services_screen.dart';
import 'features/tenant/tenant_flexible_payment_screen.dart';
import 'features/tenant/tenant_document_vault_screen.dart';
import 'features/tenant/tenant_property_rating_screen.dart';
import 'features/tenant/tenant_guest_access_code_screen.dart';
import 'dart:async' show unawaited;

class TenantPremiumHubScreen extends ConsumerWidget {
  const TenantPremiumHubScreen({super.key});

  final List<Map<String, dynamic>> _features = const [
    {
      'key': 'tenant_ar_room_tour',
      'title': 'AR Room Tour',
      'icon': CupertinoIcons.viewfinder,
      'image': 'assets/images/features/ar_room_tour.png',
      'screen': TenantArRoomTourScreen(),
    },
    {
      'key': 'tenant_smart_contract',
      'title': 'Hợp đồng thông minh',
      'icon': CupertinoIcons.doc_text_viewfinder,
      'image': 'assets/images/features/smart_contract.png',
      'screen': TenantSmartContractScreen(),
    },
    {
      'key': 'tenant_one_tap_payment',
      'title': 'Thanh toán 1 chạm',
      'icon': CupertinoIcons.money_dollar_circle,
      'image': 'assets/images/features/one_tap_payment.png',
      'screen': TenantOneTapPaymentScreen(),
    },
    {
      'key': 'tenant_bill_splitting',
      'title': 'Chia sẻ hóa đơn',
      'icon': CupertinoIcons.person_2_alt,
      'image': 'assets/images/features/bill_splitting.png',
      'screen': TenantBillSplittingScreen(),
    },
    {
      'key': 'tenant_video_maintenance',
      'title': 'Báo sự cố Video',
      'icon': CupertinoIcons.video_camera,
      'image': 'assets/images/features/video_maintenance.png',
      'screen': TenantVideoMaintenanceScreen(),
    },
    {
      'key': 'tenant_iot_smart_key',
      'title': 'Khóa thông minh',
      'icon': CupertinoIcons.lock,
      'image': 'assets/images/features/iot_smart_key.png',
      'screen': TenantIotSmartKeyScreen(),
    },
    {
      'key': 'tenant_utilities_dashboard',
      'title': 'Bảng Điện Nước',
      'icon': CupertinoIcons.drop,
      'image': 'assets/images/features/utilities_dashboard.png',
      'screen': TenantUtilitiesDashboardScreen(),
    },
    {
      'key': 'tenant_ai_roommate',
      'title': 'AI Tìm Bạn Cùng Phòng',
      'icon': CupertinoIcons.person_add,
      'image': 'assets/images/features/ai_roommate.png',
      'screen': TenantAiRoommateScreen(),
    },
    {
      'key': 'tenant_loyalty_rewards',
      'title': 'Điểm thưởng VIP',
      'icon': CupertinoIcons.star_circle,
      'image': 'assets/images/features/loyalty_rewards.png',
      'screen': TenantLoyaltyRewardsScreen(),
    },
    {
      'key': 'tenant_community_board',
      'title': 'Bảng tin cộng đồng',
      'icon': CupertinoIcons.group,
      'image': 'assets/images/features/community_board.png',
      'screen': TenantCommunityBoardScreen(),
    },
    {
      'key': 'tenant_smart_locker',
      'title': 'Tủ đồ thông minh',
      'icon': CupertinoIcons.cube_box,
      'image': 'assets/images/features/smart_locker.png',
      'screen': TenantSmartLockerScreen(),
    },
    {
      'key': 'tenant_move_checklist',
      'title': 'Checklist chuyển nhà',
      'icon': CupertinoIcons.check_mark_circled,
      'image': 'assets/images/features/move_checklist.png',
      'screen': TenantMoveChecklistScreen(),
    },
    {
      'key': 'tenant_sos_panic',
      'title': 'Nút SOS',
      'icon': CupertinoIcons.exclamationmark_triangle,
      'image': 'assets/images/features/sos_panic.png',
      'screen': TenantSosPanicScreen(),
    },
    {
      'key': 'tenant_chatbot',
      'title': 'Trợ lý ảo 24/7',
      'icon': CupertinoIcons.chat_bubble_2,
      'image': 'assets/images/features/chatbot.png',
      'screen': TenantChatbotScreen(),
    },
    {
      'key': 'tenant_local_services',
      'title': 'Dịch vụ lân cận',
      'icon': CupertinoIcons.map,
      'image': 'assets/images/features/local_services.png',
      'screen': TenantLocalServicesScreen(),
    },
    {
      'key': 'tenant_flexible_payment',
      'title': 'Trả góp linh hoạt',
      'icon': CupertinoIcons.calendar,
      'image': 'assets/images/features/flexible_payment.png',
      'screen': TenantFlexiblePaymentScreen(),
    },
    {
      'key': 'tenant_document_vault',
      'title': 'Két sắt điện tử',
      'icon': CupertinoIcons.lock_shield,
      'image': 'assets/images/features/document_vault.png',
      'screen': TenantDocumentVaultScreen(),
    },
    {
      'key': 'tenant_push_alerts',
      'title': 'Cảnh báo thông minh',
      'icon': CupertinoIcons.bell,
      'image': 'assets/images/features/push_alerts.png',
      'screen': SizedBox(),
    },
    {
      'key': 'tenant_property_rating',
      'title': 'Đánh giá nhà trọ',
      'icon': CupertinoIcons.star,
      'image': 'assets/images/features/property_rating.png',
      'screen': TenantPropertyRatingScreen(),
    },
    {
      'key': 'tenant_guest_access_code',
      'title': 'Mã khách vãng lai',
      'icon': CupertinoIcons.qrcode,
      'image': 'assets/images/features/guest_access_code.png',
      'screen': TenantGuestAccessCodeScreen(),
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuresState = ref.watch(dynamicFeaturesProvider);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Siêu Tiện Ích Người Thuê (20)'),
        backgroundColor: Color(0x00000000),
        border: null,
      ),
      child: LiquidBackground(
        colors: AppTheme.kBackgroundLight,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              CupertinoSliverRefreshControl(
                onRefresh: () async {
                  await Future.delayed(const Duration(milliseconds: 1000));
                },
              ),
              SliverPadding(
                padding: const EdgeInsets.all(24.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = _features[index];
                    final isEnabled = featuresState[item['key']] ?? true;

                    return GestureDetector(
                      onTap: isEnabled
                          ? () {
                              unawaited(
                                Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (c) => item['screen'],
                                  ),
                                ),
                              );
                            }
                          : () {
                              // Show toast or alert that owner has disabled it
                              unawaited(
                                showCupertinoDialog(
                                  context: context,
                                  builder: (ctx) => CupertinoAlertDialog(
                                    title: const Text('Tính năng bị khóa'),
                                    content: const Text(
                                      'Chủ nhà hiện đang vô hiệu hóa tính năng này.',
                                    ),
                                    actions: [
                                      CupertinoDialogAction(
                                        child: const Text('Đóng'),
                                        onPressed: () => Navigator.pop(ctx),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                      child: GlassContainer(
                        borderRadius: 24,
                        blur: 15,
                        color: isEnabled
                            ? AppTheme.kGlassColorLight
                            : CupertinoColors.systemGrey5.withValues(
                                alpha: 0.8,
                              ),
                        padding: const EdgeInsets.all(16),
                        child: Stack(
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Opacity(
                                  opacity: isEnabled ? 1.0 : 0.4,
                                  child: Image.asset(
                                    // BUGFIX (data): tránh `as String` ném
                                    // TypeError khi image null.
                                    (item['image'] ?? '').toString(),
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  item['title'],
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isEnabled
                                        ? AppTheme.kTextPrimary
                                        : CupertinoColors.inactiveGray,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            if (!isEnabled)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Icon(
                                  CupertinoIcons.lock_fill,
                                  color: CupertinoColors.systemRed.withValues(
                                    alpha: 0.7,
                                  ),
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }, childCount: _features.length),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }
}
