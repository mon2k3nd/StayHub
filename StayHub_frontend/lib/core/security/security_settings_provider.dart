import 'dart:async' show unawaited;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Trạng thái cài đặt bảo mật chuẩn ngân hàng (Bank-grade Security Settings).
class SecuritySettingsState {
  final bool biometricEnabled;
  final bool instantLockOnExit;
  final bool protectDataLeakage;

  const SecuritySettingsState({
    this.biometricEnabled = false,
    this.instantLockOnExit = false,
    this.protectDataLeakage = true,
  });

  SecuritySettingsState copyWith({
    bool? biometricEnabled,
    bool? instantLockOnExit,
    bool? protectDataLeakage,
  }) {
    return SecuritySettingsState(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      instantLockOnExit: instantLockOnExit ?? this.instantLockOnExit,
      protectDataLeakage: protectDataLeakage ?? this.protectDataLeakage,
    );
  }
}

final securitySettingsProvider =
    NotifierProvider<SecuritySettingsNotifier, SecuritySettingsState>(() {
  return SecuritySettingsNotifier();
});

class SecuritySettingsNotifier extends Notifier<SecuritySettingsState> {
  static const _keyBiometric = 'biometric_enabled';
  static const _keyInstantLock = 'instant_lock_on_exit';
  static const _keyProtectDataLeakage = 'protect_data_leakage';

  @override
  SecuritySettingsState build() {
    unawaited(_load());
    return const SecuritySettingsState();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    // Mặc định an toàn: biometric và instantLock tắt theo mặc định (opt-in)
    final bio = prefs.getBool(_keyBiometric) ?? false;
    final instant = prefs.getBool(_keyInstantLock) ?? false;
    final protect = prefs.getBool(_keyProtectDataLeakage) ?? true;

    state = SecuritySettingsState(
      biometricEnabled: bio,
      instantLockOnExit: instant,
      protectDataLeakage: protect,
    );
  }

  Future<void> setBiometricEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometric, value);
    state = state.copyWith(biometricEnabled: value);
  }

  Future<void> setInstantLockOnExit(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyInstantLock, value);
    state = state.copyWith(instantLockOnExit: value);
  }

  Future<void> setProtectDataLeakage(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyProtectDataLeakage, value);
    state = state.copyWith(protectDataLeakage: value);
  }

  Future<void> toggleBiometric() async {
    await setBiometricEnabled(!state.biometricEnabled);
  }

  Future<void> toggleInstantLock() async {
    await setInstantLockOnExit(!state.instantLockOnExit);
  }

  Future<void> toggleProtectDataLeakage() async {
    await setProtectDataLeakage(!state.protectDataLeakage);
  }
}
