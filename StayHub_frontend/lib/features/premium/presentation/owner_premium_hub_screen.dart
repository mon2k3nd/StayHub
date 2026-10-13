import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/liquid_background.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/tenant_owner_feature_provider.dart';
import 'features/owner/owner_multi_property_screen.dart';
import 'features/owner/owner_auto_rent_collection_screen.dart';
import 'features/owner/owner_ai_financial_screen.dart';
import '../../owner/presentation/owner_ocr_scanner_screen.dart';
import 'features/owner/owner_broadcast_msg_screen.dart';
import 'features/owner/owner_dynamic_pricing_screen.dart';
import 'features/owner/owner_expense_scanner_screen.dart';
import 'features/owner/owner_lease_renewal_screen.dart';
import 'features/owner/owner_tenant_bg_check_screen.dart';
import 'features/owner/owner_staff_dispatch_screen.dart';
import 'features/owner/owner_iot_management_screen.dart';
import 'features/owner/owner_auto_pnl_export_screen.dart';
import 'features/owner/owner_marketing_campaign_screen.dart';
import 'features/owner/owner_moveout_settlement_screen.dart';
import 'features/owner/owner_multilevel_debt_screen.dart';
import 'features/owner/owner_auto_pdf_gen_screen.dart';
import 'features/owner/owner_rbac_screen.dart';
import 'features/owner/owner_tax_helper_screen.dart';
import 'features/owner/owner_competitor_analysis_screen.dart';
import 'features/owner/owner_inventory_management_screen.dart';
import 'dart:async' show unawaited;

class OwnerPremiumHubScreen extends ConsumerWidget {
  const OwnerPremiumHubScreen({super.key});

  final List<Map<String, dynamic>> _features = const [
    {
      'key': 'owner_multi_property',
      'title': 'Đa Dãy Trọ',
      'icon': CupertinoIcons.building_2_fill,
      'image': 'assets/images/features/multi_property.png',
      'screen': OwnerMultiPropertyScreen(),
    },
    {
      'key': 'owner_auto_rent_collection',
      'title': 'Thu Tiền Tự Động',
      'icon': CupertinoIcons.money_dollar_circle_fill,
      'image': 'assets/images/features/auto_rent_collection.png',
      'screen': OwnerAutoRentCollectionScreen(),
    },
    {
      'key': 'owner_ai_financial',
      'title': 'AI Tài Chính',
      'icon': CupertinoIcons.graph_square_fill,
      'image': 'assets/images/features/ai_financial.png',
      'screen': OwnerAiFinancialScreen(),
    },
    {
      'key': 'owner_ocr_meter',
      'title': 'Quét OCR',
      'icon': CupertinoIcons.camera_viewfinder,
      'image': 'assets/images/features/ocr_meter.png',
      'screen': OwnerOcrScannerScreen(),
    },
    {
      'key': 'owner_broadcast_msg',
      'title': 'Tin Nhắn Loạt',
      'icon': CupertinoIcons.speaker_2_fill,
      'image': 'assets/images/features/broadcast_msg.png',
      'screen': OwnerBroadcastMsgScreen(),
    },
    {
      'key': 'owner_dynamic_pricing',
      'title': 'Giá Linh Hoạt',
      'icon': CupertinoIcons.tag_fill,
      'image': 'assets/images/features/dynamic_pricing.png',
      'screen': OwnerDynamicPricingScreen(),
    },
    {
      'key': 'owner_expense_scanner',
      'title': 'Quét Hóa Đơn',
      'icon': CupertinoIcons.doc_text_search,
      'image': 'assets/images/features/expense_scanner.png',
      'screen': OwnerExpenseScannerScreen(),
    },
    {
      'key': 'owner_lease_renewal',
      'title': 'Tự Gia Hạn',
      'icon': CupertinoIcons.arrow_2_squarepath,
      'image': 'assets/images/features/lease_renewal.png',
      'screen': OwnerLeaseRenewalScreen(),
    },
    {
      'key': 'owner_tenant_bg_check',
      'title': 'Kiểm Tra Lý Lịch',
      'icon': CupertinoIcons.person_badge_minus,
      'image': 'assets/images/features/tenant_bg_check.png',
      'screen': OwnerTenantBgCheckScreen(),
    },
    {
      'key': 'owner_staff_dispatch',
      'title': 'Nhân Sự',
      'icon': CupertinoIcons.person_3_fill,
      'image': 'assets/images/features/staff_dispatch.png',
      'screen': OwnerStaffDispatchScreen(),
    },
    {
      'key': 'owner_iot_management',
      'title': 'Trung Tâm IoT',
      'icon': CupertinoIcons.radiowaves_right,
      'image': 'assets/images/features/iot_management.png',
      'screen': OwnerIotManagementScreen(),
    },
    {
      'key': 'owner_auto_pnl_export',
      'title': 'Xuất PnL',
      'icon': CupertinoIcons.doc_chart_fill,
      'image': 'assets/images/features/auto_pnl_export.png',
      'screen': OwnerAutoPnlExportScreen(),
    },
    {
      'key': 'owner_marketing_campaign',
      'title': 'Marketing',
      'icon': CupertinoIcons.speaker_2_fill,
      'image': 'assets/images/features/marketing_campaign.png',
      'screen': OwnerMarketingCampaignScreen(),
    },
    {
      'key': 'owner_moveout_settlement',
      'title': 'Quyết Toán',
      'icon': CupertinoIcons.bag_badge_minus,
      'image': 'assets/images/features/moveout_settlement.png',
      'screen': OwnerMoveoutSettlementScreen(),
    },
    {
      'key': 'owner_multilevel_debt',
      'title': 'Quản Lý Nợ',
      'icon': CupertinoIcons.creditcard_fill,
      'image': 'assets/images/features/multilevel_debt.png',
      'screen': OwnerMultilevelDebtScreen(),
    },
    {
      'key': 'owner_auto_pdf_gen',
      'title': 'Tạo PDF',
      'icon': CupertinoIcons.doc_text_fill,
      'image': 'assets/images/features/auto_pdf_gen.png',
      'screen': OwnerAutoPdfGenScreen(),
    },
    {
      'key': 'owner_rbac',
      'title': 'Phân Quyền',
      'icon': CupertinoIcons.shield_fill,
      'image': 'assets/images/features/rbac.png',
      'screen': OwnerRbacScreen(),
    },
    {
      'key': 'owner_tax_helper',
      'title': 'Khai Thuế',
      'icon': CupertinoIcons.doc_text_search,
      'image': 'assets/images/features/tax_helper.png',
      'screen': OwnerTaxHelperScreen(),
    },
    {
      'key': 'owner_competitor_analysis',
      'title': 'PT Đối Thủ',
      'icon': CupertinoIcons.eye_fill,
      'image': 'assets/images/features/competitor_analysis.png',
      'screen': OwnerCompetitorAnalysisScreen(),
    },
    {
      'key': 'owner_inventory_management',
      'title': 'Kho Tài Sản',
      'icon': CupertinoIcons.cube_box_fill,
      'image': 'assets/images/features/inventory_management.png',
      'screen': OwnerInventoryManagementScreen(),
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuresState = ref.watch(dynamicFeaturesProvider);

    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Siêu Tiện Ích Chủ Nhà (20)'),
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
                          : null,
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
                                    // TypeError khi image null/khác.
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
