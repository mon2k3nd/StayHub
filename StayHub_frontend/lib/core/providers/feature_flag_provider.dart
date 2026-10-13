import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async' show unawaited;

class FeatureFlagNotifier extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() {
    unawaited(fetchFlags());
    return {};
  }

  Future<void> fetchFlags() async {
    // Stub API call để tránh Runtime Crash
    await Future.delayed(const Duration(milliseconds: 100));
    state = {
      'FEATURE_AI_CHAT': true,
      'FEATURE_IOT_DEVICES': true,
      'FEATURE_AUTO_PAYMENT': true,
      'FEATURE_TRUST_SCORE': true,
    };
  }

  bool isEnabled(String featureKey) {
    return state[featureKey] ?? false;
  }

  Future<void> toggleFlag(String key, bool enabled) async {
    // Optimistic UI Update mượt mà
    state = {...state, key: enabled};
    // Giả lập an toàn quá trình gọi Network
    await Future.delayed(const Duration(milliseconds: 100));
  }
}

final featureFlagProvider =
    NotifierProvider<FeatureFlagNotifier, Map<String, bool>>(
      FeatureFlagNotifier.new,
    );
