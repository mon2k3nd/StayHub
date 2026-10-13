import 'dart:ui' show ImageFilter;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    show Colors, LinearGradient, Icons, TabController, Material, BoxDecoration;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../application/auth_notifier.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/google_auth_service.dart';
import '../../../core/services/facebook_auth_service.dart';
import '../../../core/services/zalo_auth_service.dart';
import '../../../core/services/apple_auth_service.dart';
import '../../../core/services/firebase_phone_auth_service.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/services/deep_link_memory_service.dart';
import '../../../core/components/premium_text_field.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/services/wishlist_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stayhub_frontend/core/components/stayhub_logo_icon.dart';
import 'widgets/animated_sky_background.dart';
import 'dart:async' show unawaited;

part 'login_screen_state.dart';
part 'login_screen_ui_kit.dart';

// ─── Color tokens ────────────────────────────────────────────
const _kBrand = Color(0xFF298FFF); // StayHub Sky Blue brand
const _kBrand2 = Color(0xFF1A6FD4); // brand deep blue
// Frosted panel: high-opacity white so the form stays crisp and legible
// over the bright animated sky. A 25% white panel (the old value) washed
// out the fields and made the screen look flat/dated.
const _kGlass = Color(0xF2FFFFFF); // near-opaque frosted panel
const _kGlassB = Color(0x33FFFFFF); // subtle inner border
const _kGlassSoftB = Color(0x40FFFFFF); // border for soft glass
const _kText = Color(0xFF0F172A); // dark text for light background
const _kTextSub = Color(0xFF475569); // slate text

enum RegisterStep { emailInput, otpVerification, passwordSetup }

// =============================================================================
//  UNIFIED AUTH SCREEN  (Tab 0 = Đăng Nhập, Tab 1 = Đăng Ký)
// =============================================================================
class LoginScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const LoginScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<LoginScreen> createState() => _AuthScreenState();
}
