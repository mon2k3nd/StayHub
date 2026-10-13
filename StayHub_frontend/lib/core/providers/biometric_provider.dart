import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async' show unawaited;

final biometricEnabledProvider = NotifierProvider<BiometricNotifier, bool>(() {
  return BiometricNotifier();
});

class BiometricNotifier extends Notifier<bool> {
  static const _key = 'biometric_enabled';

  @override
  bool build() {
    unawaited(_load());
    return false;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
  }

  Future<void> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    state = !state;
    await prefs.setBool(_key, state);
  }
}
