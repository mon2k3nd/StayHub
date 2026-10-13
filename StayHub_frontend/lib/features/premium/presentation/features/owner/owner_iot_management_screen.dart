import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/components/glass_container.dart';
import '../../../../../core/components/liquid_background.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../application/owner_iot_notifier.dart';

class OwnerIotManagementScreen extends ConsumerWidget {
  const OwnerIotManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(iotProvider);
    final notifier = ref.read(iotProvider.notifier);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Trung Tâm IoT'),
        backgroundColor: const Color(0x00000000),
        border: null,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.add_circled),
          onPressed: () {},
        ),
      ),
      child: LiquidBackground(
        colors: AppTheme.kBackgroundLight,
        child: SafeArea(
          child: state.isLoading
              ? const Center(child: CupertinoActivityIndicator(radius: 20))
              : CustomScrollView(
                  slivers: [
                    CupertinoSliverRefreshControl(
                      onRefresh: () async {
                        await Future.delayed(
                          const Duration(milliseconds: 1000),
                        );
                      },
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(24.0),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.85,
                            ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final device = state.devices[index];
                          return _buildDeviceCard(
                            device,
                            () => notifier.toggleDevice(device.id),
                          );
                        }, childCount: state.devices.length),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildDeviceCard(IotDevice device, VoidCallback onToggle) {
    IconData icon;
    Color activeColor;
    switch (device.type) {
      case 'lock':
        icon = device.isOn
            ? CupertinoIcons.lock_fill
            : CupertinoIcons.lock_open_fill;
        activeColor = CupertinoColors.destructiveRed;
        break;
      case 'camera':
        icon = CupertinoIcons.video_camera_solid;
        activeColor = CupertinoColors.activeBlue;
        break;
      case 'meter':
        icon = CupertinoIcons.bolt_fill;
        activeColor = CupertinoColors.systemYellow;
        break;
      default:
        icon = CupertinoIcons.radiowaves_right;
        activeColor = AppTheme.kAccentColor;
    }

    final isCardActive = device.isOnline && device.isOn;

    return GestureDetector(
      onTap: onToggle,
      child: GlassContainer(
        borderRadius: 24,
        blur: 15,
        color: isCardActive
            ? activeColor.withValues(alpha: 0.15)
            : CupertinoColors.white.withValues(alpha: 0.6),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 36,
                  color: isCardActive
                      ? activeColor
                      : CupertinoColors.systemGrey2,
                ),
                if (!device.isOnline)
                  const Icon(
                    CupertinoIcons.wifi_exclamationmark,
                    size: 20,
                    color: CupertinoColors.destructiveRed,
                  )
                else if (device.batteryLevel != null)
                  Row(
                    children: [
                      Text(
                        '${(device.batteryLevel! * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        device.batteryLevel! < 0.2
                            ? CupertinoIcons.battery_25
                            : CupertinoIcons.battery_100,
                        size: 16,
                        color: device.batteryLevel! < 0.2
                            ? CupertinoColors.destructiveRed
                            : CupertinoColors.activeGreen,
                      ),
                    ],
                  ),
              ],
            ),
            const Spacer(),
            Text(
              device.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              device.location,
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: !device.isOnline
                        ? CupertinoColors.destructiveRed
                        : (device.isOn
                              ? CupertinoColors.activeGreen
                              : CupertinoColors.systemGrey3),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  !device.isOnline
                      ? 'Mất kết nối'
                      : (device.isOn
                            ? 'Đang Bật / Đã Khóa'
                            : 'Đang Tắt / Mở Khóa'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
