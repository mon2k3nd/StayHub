import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Divider;
import 'dart:async';
import 'dart:math';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/theme/app_theme.dart';

class IotManagementScreen extends StatefulWidget {
  const IotManagementScreen({super.key});

  @override
  State<IotManagementScreen> createState() => _IotManagementScreenState();
}

class _IotManagementScreenState extends State<IotManagementScreen> {
  int _selectedTab = 0;

  // Mock Smart Locks state
  final List<Map<String, dynamic>> _locks = [
    {
      'room': 'Cổng Chính Dãy A',
      'isLocked': true,
      'battery': 85,
      'isOnline': true,
    },
    {'room': 'Phòng 101', 'isLocked': false, 'battery': 42, 'isOnline': true},
    {'room': 'Phòng 102', 'isLocked': true, 'battery': 98, 'isOnline': true},
    {'room': 'Phòng 201', 'isLocked': true, 'battery': 12, 'isOnline': false},
  ];

  // Mock Smart Meters state
  final List<Map<String, dynamic>> _meters = [
    {
      'room': 'Phòng 101',
      'elec': 1250.4,
      'water': 142.5,
      'elecTrend': 2.4,
      'waterTrend': 1.1,
    },
    {
      'room': 'Phòng 102',
      'elec': 890.2,
      'water': 95.0,
      'elecTrend': 1.2,
      'waterTrend': 0.8,
    },
    {
      'room': 'Phòng 201',
      'elec': 2140.8,
      'water': 210.3,
      'elecTrend': 5.8,
      'waterTrend': 3.2,
    },
  ];

  late Timer _meterSimTimer;

  @override
  void initState() {
    super.initState();
    // Simulate real-time meter reading
    _meterSimTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted) return;
      setState(() {
        for (var meter in _meters) {
          final rng = Random();
          // Increase electricity randomly by 0.01 to 0.05
          meter['elec'] = meter['elec'] + (rng.nextDouble() * 0.04 + 0.01);
          // Increase water randomly
          meter['water'] = meter['water'] + (rng.nextDouble() * 0.01);
        }
      });
    });
  }

  @override
  void dispose() {
    _meterSimTimer.cancel();
    super.dispose();
  }

  Future<void> _toggleLock(int index) async {
    final lock = _locks[index];
    if (!lock['isOnline']) {
      _showErrorDialog('Thiết bị đang offline, không thể điều khiển từ xa.');
      return;
    }

    // Simulate API call
    setState(() => lock['isLoading'] = true);
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      lock['isLocked'] = !lock['isLocked'];
      lock['isLoading'] = false;
    });
  }

  void _generateTempPin(String roomName) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Tạo mã PIN Tạm thời'),
          content: Text(
            'Hệ thống sẽ tạo mã PIN 6 số dùng một lần cho $roomName có hiệu lực trong 30 phút.',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text(
                'Hủy',
                style: TextStyle(color: CupertinoColors.systemRed),
              ),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              child: const Text('Tạo Mã'),
              onPressed: () {
                Navigator.pop(ctx);
                _showPinResult(roomName);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPinResult(String roomName) {
    final pin = (Random().nextInt(900000) + 100000).toString();
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Mã PIN Đã Tạo'),
          content: Column(
            children: [
              const SizedBox(height: 10),
              Text('Mã PIN tạm cho $roomName là:'),
              const SizedBox(height: 10),
              Text(
                pin,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: AppTheme.kAccentColor,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Sẽ hết hạn vào: ${'14:30'} hôm nay',
                style: TextStyle(
                  fontSize: 12,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Sao chép & Đóng'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Lỗi'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('Đóng'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      title: 'Thiết Bị Thông Minh',
      useScrollView: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: _selectedTab,
                children: const {
                  0: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Smart Lock',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  1: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Đồng hồ điện/nước',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                },
                onValueChanged: (val) {
                  if (val != null) setState(() => _selectedTab = val);
                },
              ),
            ),
          ),
          Expanded(
            child: _selectedTab == 0 ? _buildSmartLocks() : _buildSmartMeters(),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartLocks() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _locks.length,
      itemBuilder: (context, index) {
        final lock = _locks[index];
        // BUGFIX (data): trước đây ép `as bool`/`as int` — nếu backend trả
        // null/số/chuỗi (JSON lỗi) thì ném TypeError và cả danh sách khoá
        // thông minh không render. Coerce an toàn.
        final isLocked = lock['isLocked'] == true;
        final isOnline = lock['isOnline'] == true;
        final isLoading = lock['isLoading'] == true;
        final battery = lock['battery'] is num
            ? (lock['battery'] as num).toInt()
            : int.tryParse(lock['battery']?.toString() ?? '') ?? 0;

        final iconColor = !isOnline
            ? CupertinoColors.systemGrey
            : (isLocked
                  ? CupertinoColors.systemGreen
                  : CupertinoColors.systemRed);

        final icon = isLocked
            ? CupertinoIcons.lock_fill
            : CupertinoIcons.lock_open_fill;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: isOnline
                                ? CupertinoColors.systemGreen
                                : CupertinoColors.systemGrey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          lock['room'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          battery > 20
                              ? CupertinoIcons.battery_100
                              : CupertinoIcons.battery_25,
                          color: battery > 20
                              ? CupertinoColors.systemGreen
                              : CupertinoColors.systemRed,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$battery%',
                          style: TextStyle(
                            color: battery > 20
                                ? CupertinoColors.systemGreen
                                : CupertinoColors.systemRed,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _toggleLock(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: iconColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: isLoading
                              ? const Center(
                                  child: CupertinoActivityIndicator(),
                                )
                              : Column(
                                  children: [
                                    Icon(icon, color: iconColor, size: 32),
                                    const SizedBox(height: 8),
                                    Text(
                                      !isOnline
                                          ? 'Mất kết nối'
                                          : (isLocked ? 'Đã khóa' : 'Đang mở'),
                                      style: TextStyle(
                                        color: iconColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _generateTempPin(lock['room']),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.kAccentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.kAccentColor.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                CupertinoIcons.number_square_fill,
                                color: AppTheme.kAccentColor,
                                size: 32,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Cấp mã PIN',
                                style: TextStyle(
                                  color: AppTheme.kAccentColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSmartMeters() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _meters.length,
      itemBuilder: (context, index) {
        final meter = _meters[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GlassContainer(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      meter['room'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGreen.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            CupertinoIcons.circle_fill,
                            color: CupertinoColors.systemGreen,
                            size: 8,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Online',
                            style: TextStyle(
                              color: CupertinoColors.systemGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: CupertinoColors.systemGrey5),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMeterReading(
                        icon: CupertinoIcons.bolt_fill,
                        iconColor: CupertinoColors.systemYellow,
                        label: 'Chỉ số điện',
                        value: meter['elec'],
                        unit: 'kWh',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: CupertinoColors.systemGrey5,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: _buildMeterReading(
                          icon: CupertinoIcons.drop_fill,
                          iconColor: CupertinoColors.systemBlue,
                          label: 'Chỉ số nước',
                          value: meter['water'],
                          unit: 'm³',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMeterReading({
    required IconData icon,
    required Color iconColor,
    required String label,
    required double value,
    required String unit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                fontFamily: 'Monospace',
              ),
            ),
            const SizedBox(width: 4),
            Text(
              unit,
              style: const TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
