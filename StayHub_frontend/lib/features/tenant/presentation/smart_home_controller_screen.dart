import 'dart:ui';
import 'dart:convert';
import 'package:flutter/cupertino.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/bounce_click.dart';

import '../application/smart_device_provider.dart';
import '../data/models/smart_device_model.dart';
import 'dart:async' show unawaited;

class SmartHomeControllerScreen extends ConsumerStatefulWidget {
  final int roomId;

  // Default to 1 if not passed in route (since it's hardcoded in app_router right now)
  const SmartHomeControllerScreen({super.key, this.roomId = 1});

  @override
  ConsumerState<SmartHomeControllerScreen> createState() =>
      _SmartHomeControllerScreenState();
}

class _SmartHomeControllerScreenState
    extends ConsumerState<SmartHomeControllerScreen> {
  @override
  Widget build(BuildContext context) {
    final devicesState = ref.watch(smartDeviceProvider(widget.roomId));

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.kTextPrimary,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppTheme.kTextPrimary.withValues(alpha: 0.8),
        middle: const Text(
          'Smart Home',
          style: TextStyle(color: CupertinoColors.white),
        ),
        previousPageTitle: 'Back',
      ),
      child: devicesState.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Lỗi: $err',
            style: const TextStyle(color: CupertinoColors.destructiveRed),
          ),
        ),
        data: (devices) {
          final acDevice = devices.cast<SmartDeviceModel?>().firstWhere(
            (d) => d?.deviceType == 'AC',
            orElse: () => null,
          );
          final otherDevices = devices
              .where((d) => d.deviceType != 'AC')
              .toList();

          final isMainLightOn = otherDevices.any(
            (d) => d.deviceType == 'LIGHT' && d.status == 'ON',
          );
          final isAcOn = acDevice != null && acDevice.status == 'ON';

          return Stack(
            children: [
              // Ambient Glow Background
              Positioned(
                top: 50,
                left: -50,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isMainLightOn
                        ? const Color(0xFFFBBF24).withValues(alpha: 0.2)
                        : Colors.transparent,
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                    child: const SizedBox(),
                  ),
                ),
              ),
              Positioned(
                bottom: 100,
                right: -50,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isAcOn
                        ? AppTheme.kBrandLight.withValues(alpha: 0.15)
                        : Colors.transparent,
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                    child: const SizedBox(),
                  ),
                ),
              ),

              SafeArea(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 32),
                    if (acDevice != null) ...[
                      _buildAcController(acDevice),
                      const SizedBox(height: 24),
                    ],
                    _buildDeviceGrid(otherDevices),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phòng ${widget.roomId == 1 ? '101' : widget.roomId}',
          style: const TextStyle(
            color: CupertinoColors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGreen.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(
                    CupertinoIcons.wifi,
                    color: CupertinoColors.systemGreen,
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Đã kết nối Hub',
                    style: TextStyle(
                      color: CupertinoColors.systemGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Nhiệt độ phòng: 26°C',
              style: TextStyle(color: AppTheme.kTextSecondary, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAcController(SmartDeviceModel ac) {
    final isOn = ac.status == 'ON';
    double temp = 24.0;
    try {
      if (ac.settings != null) {
        final map = jsonDecode(ac.settings!);
        if (map['temp'] != null) {
          temp = double.parse(map['temp'].toString());
        }
      }
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isOn
            ? AppTheme.kBrand.withValues(alpha: 0.15)
            : CupertinoColors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isOn
              ? AppTheme.kBrand.withValues(alpha: 0.5)
              : CupertinoColors.white.withValues(alpha: 0.1),
        ),
        boxShadow: isOn
            ? [
                BoxShadow(
                  color: AppTheme.kBrand.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: -5,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    CupertinoIcons.snow,
                    color: isOn
                        ? AppTheme.kBrandLight
                        : AppTheme.kTextSecondary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    ac.name,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              CupertinoSwitch(
                value: isOn,
                activeTrackColor: AppTheme.kBrand,
                onChanged: (val) {
                  unawaited(HapticFeedback.lightImpact());
                  unawaited(
                    ref
                        .read(smartDeviceProvider(widget.roomId).notifier)
                        .toggleDevice(ac.id!, val ? 'ON' : 'OFF'),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isOn ? 1.0 : 0.4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: isOn && temp > 16
                      ? () {
                          unawaited(HapticFeedback.selectionClick());
                          unawaited(
                            ref
                                .read(
                                  smartDeviceProvider(widget.roomId).notifier,
                                )
                                .updateSettings(ac.id!, {'temp': temp - 1}),
                          );
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.minus,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                Text(
                  '${temp.toInt()}°C',
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(width: 32),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: isOn && temp < 30
                      ? () {
                          unawaited(HapticFeedback.selectionClick());
                          unawaited(
                            ref
                                .read(
                                  smartDeviceProvider(widget.roomId).notifier,
                                )
                                .updateSettings(ac.id!, {'temp': temp + 1}),
                          );
                        }
                      : null,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.add,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isOn ? 1.0 : 0.4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAcMode('Cool', CupertinoIcons.snow, true),
                _buildAcMode('Dry', CupertinoIcons.drop, false),
                _buildAcMode('Fan', CupertinoIcons.wind, false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcMode(String label, IconData icon, bool isSelected) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.kBrand : Colors.transparent,
            shape: BoxShape.circle,
            border: isSelected
                ? null
                : Border.all(color: AppTheme.kTextSecondary),
          ),
          child: Icon(
            icon,
            color: isSelected ? CupertinoColors.white : AppTheme.kTextSecondary,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? CupertinoColors.white : AppTheme.kTextSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceGrid(List<SmartDeviceModel> devices) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: devices.asMap().entries.map((entry) {
        final idx = entry.key;
        final device = entry.value;
        IconData icon;
        Color color;
        bool isOn;
        String title = device.name;
        String statusLabel = '';
        String imagePath = 'assets/images/features/iot_management.png';

        switch (device.deviceType) {
          case 'LIGHT':
            isOn = device.status == 'ON';
            icon = isOn
                ? CupertinoIcons.lightbulb_fill
                : CupertinoIcons.lightbulb;
            color = const Color(0xFFFBBF24);
            statusLabel = isOn ? 'Đang bật' : 'Đã tắt';
            imagePath = 'assets/images/features/iot_management.png';
            break;
          case 'LOCK':
            isOn = device.status == 'LOCKED';
            icon = isOn
                ? CupertinoIcons.lock_fill
                : CupertinoIcons.lock_open_fill;
            color = AppTheme.kSuccess;
            statusLabel = isOn ? 'Đã khóa' : 'Mở khóa';
            imagePath = 'assets/images/features/iot_smart_key.png';
            break;
          case 'CURTAIN':
            isOn = device.status == 'OPEN';
            icon = isOn
                ? CupertinoIcons.macwindow
                : CupertinoIcons.rectangle_split_3x1;
            color = const Color(0xFFF472B6);
            statusLabel = isOn ? 'Đang mở' : 'Đã đóng';
            imagePath = 'assets/images/features/smart_locker.png';
            break;
          default:
            isOn = device.status == 'ON';
            icon = CupertinoIcons.bolt_fill;
            color = AppTheme.kTextSecondary;
            statusLabel = isOn ? 'ON' : 'OFF';
            imagePath = 'assets/images/features/utilities_dashboard.png';
        }

        final card = _buildDeviceCard(
          title: title,
          icon: icon,
          isOn: isOn,
          statusLabel: statusLabel,
          activeColor: color,
          imagePath: imagePath,
          onToggle: (val) {
            if (device.deviceType == 'LOCK') {
              unawaited(HapticFeedback.heavyImpact());
              unawaited(
                ref
                    .read(smartDeviceProvider(widget.roomId).notifier)
                    .toggleDevice(device.id!, val ? 'LOCKED' : 'UNLOCKED'),
              );
            } else if (device.deviceType == 'CURTAIN') {
              unawaited(HapticFeedback.lightImpact());
              unawaited(
                ref
                    .read(smartDeviceProvider(widget.roomId).notifier)
                    .toggleDevice(device.id!, val ? 'OPEN' : 'CLOSED'),
              );
            } else {
              unawaited(HapticFeedback.lightImpact());
              unawaited(
                ref
                    .read(smartDeviceProvider(widget.roomId).notifier)
                    .toggleDevice(device.id!, val ? 'ON' : 'OFF'),
              );
            }
          },
        );

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (idx * 50)),
          curve: Curves.easeOutCubic,
          builder: (context, val, child) => Transform.translate(
            offset: Offset(0, 20 * (1 - val)),
            child: Opacity(opacity: val, child: child),
          ),
          child: card,
        );
      }).toList(),
    );
  }

  Widget _buildDeviceCard({
    required String title,
    required IconData icon,
    required bool isOn,
    required String statusLabel,
    required Color activeColor,
    required ValueChanged<bool> onToggle,
    String? imagePath,
  }) {
    return BounceClick(
      onPressed: () {
        unawaited(HapticFeedback.lightImpact());
        onToggle(!isOn);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isOn
              ? activeColor.withValues(alpha: 0.15)
              : CupertinoColors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isOn
                ? activeColor.withValues(alpha: 0.5)
                : CupertinoColors.white.withValues(alpha: 0.1),
          ),
          boxShadow: isOn
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: -5,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                imagePath != null
                    ? Opacity(
                        opacity: isOn ? 1.0 : 0.5,
                        child: Image.asset(
                          imagePath,
                          width: 34,
                          height: 34,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          isAntiAlias: true,
                          errorBuilder: (_, __, ___) => Icon(
                            icon,
                            color: isOn ? activeColor : AppTheme.kTextSecondary,
                            size: 28,
                          ),
                        ),
                      )
                    : Icon(
                        icon,
                        color: isOn ? activeColor : AppTheme.kTextSecondary,
                        size: 28,
                      ),
                CupertinoSwitch(
                  value: isOn,
                  activeTrackColor: activeColor,
                  onChanged: (val) {
                    unawaited(HapticFeedback.lightImpact());
                    onToggle(val);
                  },
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusLabel,
                  style: TextStyle(
                    color: isOn ? activeColor : AppTheme.kTextSecondary,
                    fontSize: 12,
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
