import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/tenant_owner_feature_provider.dart';

class OwnerFeatureConfigScreen extends ConsumerWidget {
  const OwnerFeatureConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = ref.watch(dynamicFeaturesProvider);

    return LiquidGlassScaffold(
      title: 'Trạm Điều Khiển 50 Tính Năng',
      backgroundColors: AppTheme.kBackgroundLight,
      useScrollView: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'ĐÂY LÀ KHU VỰC DÀNH CHO CHỦ NHÀ.',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: CupertinoColors.activeBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bạn có toàn quyền Bật/Tắt các tiện ích cung cấp cho Khách Thuê của dãy trọ mình quản lý. Thay đổi sẽ áp dụng ngay lập tức (Real-time).',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CupertinoButton.filled(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: const Text('Bật Toàn Bộ (Enable All)'),
                    onPressed: () {
                      ref
                          .read(dynamicFeaturesProvider.notifier)
                          .toggleAll(true);
                    },
                  ),
                  const SizedBox(height: 8),
                  CupertinoButton(
                    child: const Text(
                      'Tắt Toàn Bộ',
                      style: TextStyle(color: CupertinoColors.destructiveRed),
                    ),
                    onPressed: () {
                      ref
                          .read(dynamicFeaturesProvider.notifier)
                          .toggleAll(false);
                    },
                  ),
                ],
              ),
            ),
          ),
          _buildCategory(
            title: '📱 TÍNH NĂNG NGƯỜI THUÊ (TENANT APP)',
            features: features,
            prefix: 'tenant_',
            ref: ref,
          ),
          _buildCategory(
            title: '🏢 TÍNH NĂNG CHỦ NHÀ (OWNER APP)',
            features: features,
            prefix: 'owner_',
            ref: ref,
          ),
          _buildCategory(
            title: '✨ TRẢI NGHIỆM CHUNG (CORE/SHARED)',
            features: features,
            prefix: 'core_',
            ref: ref,
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildCategory({
    required String title,
    required Map<String, bool> features,
    required String prefix,
    required WidgetRef ref,
  }) {
    final categoryFeatures = features.entries
        .where((e) => e.key.startsWith(prefix))
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8, top: 16),
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
          GlassContainer(
            padding: EdgeInsets.zero,
            child: Column(
              children: categoryFeatures.map((entry) {
                final isLast = entry.key == categoryFeatures.last.key;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _formatKeyName(entry.key),
                              style: const TextStyle(
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          CupertinoSwitch(
                            value: entry.value,
                            activeTrackColor: CupertinoColors.activeGreen,
                            onChanged: (_) {
                              ref
                                  .read(dynamicFeaturesProvider.notifier)
                                  .toggleFeature(entry.key);
                            },
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      Container(
                        height: 1,
                        color: CupertinoColors.systemGrey4,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatKeyName(String key) {
    // Convert 'tenant_ar_room_tour' to 'Ar Room Tour'
    final parts = key.split('_').skip(1).toList(); // Skip prefix
    if (parts.isEmpty) return key;

    return parts
        .map((w) {
          if (w.isEmpty) return '';
          return w[0].toUpperCase() + w.substring(1);
        })
        .join(' ');
  }
}
