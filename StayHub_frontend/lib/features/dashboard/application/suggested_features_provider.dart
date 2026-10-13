import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async' show unawaited;

class SuggestedFeaturesNotifier extends Notifier<List<String>> {
  static const _prefsKey = 'owner_suggested_features_order';

  static const _defaultFeatures = [
    'Theo Dõi Công Nợ',
    'Thanh Lý Hợp Đồng',
    'Lịch Bảo Trì',
    'Sổ Quỹ Thu Chi',
    'Quản lý Phương Tiện',
    'Khai Báo Tạm Trú (CT01)',
    'Dịch Vụ & Tiện Ích',
    'Quản lý Sự Cố',
  ];

  @override
  List<String> build() {
    unawaited(_loadPrefs());
    return _defaultFeatures;
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey);
    if (saved != null && saved.isNotEmpty) {
      final validSaved = saved
          .where((item) => _defaultFeatures.contains(item))
          .toList();
      for (final feature in _defaultFeatures) {
        if (!validSaved.contains(feature)) {
          validSaved.add(feature);
        }
      }
      state = validSaved.isNotEmpty ? validSaved : _defaultFeatures;
    }
  }

  Future<void> prioritizeFeature(String featureId) async {
    final currentState = state.toList();
    currentState.remove(featureId);
    currentState.insert(0, featureId);
    state = currentState;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, currentState);
  }
}

final suggestedFeaturesProvider =
    NotifierProvider<SuggestedFeaturesNotifier, List<String>>(() {
      return SuggestedFeaturesNotifier();
    });
