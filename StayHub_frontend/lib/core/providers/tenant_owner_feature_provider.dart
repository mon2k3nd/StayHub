import 'package:flutter_riverpod/flutter_riverpod.dart';

class FeatureTogglesNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() {
    return {
      // --- ?? Tenant App Features (20) ---
      'tenant_ar_room_tour': true,
      'tenant_smart_contract': true,
      'tenant_one_tap_payment': true,
      'tenant_bill_splitting': true,
      'tenant_video_maintenance': true,
      'tenant_iot_smart_key': true,
      'tenant_utilities_dashboard': true,
      'tenant_ai_roommate': true,
      'tenant_loyalty_rewards': true,
      'tenant_community_board': true,
      'tenant_smart_locker': true,
      'tenant_move_checklist': true,
      'tenant_sos_panic': true,
      'tenant_chatbot': true,
      'tenant_local_services': true,
      'tenant_flexible_payment': true,
      'tenant_document_vault': true,
      'tenant_push_alerts': true,
      'tenant_property_rating': true,
      'tenant_guest_access_code': true,

      // --- ?? Owner App Features (20) ---
      'owner_multi_property': true,
      'owner_auto_rent_collection': true,
      'owner_ai_financial': true,
      'owner_ocr_meter': true,
      'owner_broadcast_msg': true,
      'owner_dynamic_pricing': true,
      'owner_expense_scanner': true,
      'owner_lease_renewal': true,
      'owner_tenant_bg_check': true,
      'owner_staff_dispatch': true,
      'owner_iot_management': true,
      'owner_auto_pnl_export': true,
      'owner_marketing_campaign': true,
      'owner_moveout_settlement': true,
      'owner_multilevel_debt': true,
      'owner_auto_pdf_gen': true,
      'owner_rbac': true,
      'owner_tax_helper': true,
      'owner_competitor_analysis': true,
      'owner_inventory_management': true,

      // --- ? Core & Shared Features (10) ---
      'core_liquid_glass': true,
      'core_dark_light_mode': true,
      'core_biometric_auth': true,
      'core_e2e_chat': true,
      'core_multi_language': true,
      'core_offline_sync': true,
      'core_accessibility': true,
      'core_ gamification': true,
      'core_universal_deeplinks': true,
      'core_haptic_feedback': true,
    };
  }

  void toggleFeature(String key) {
    if (state.containsKey(key)) {
      state = {...state, key: !state[key]!};
    }
  }

  void toggleAll(bool value) {
    final newState = <String, bool>{};
    state.forEach((key, _) => newState[key] = value);
    state = newState;
  }
}

final dynamicFeaturesProvider =
    NotifierProvider<FeatureTogglesNotifier, Map<String, bool>>(
      FeatureTogglesNotifier.new,
    );
