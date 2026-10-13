import 'package:flutter/cupertino.dart';

import '../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/providers/core_providers.dart';
import '../../room/application/room_notifier.dart';

final smartLocksProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final rooms = await ref.watch(allOwnerRoomsProvider.future);
      final apiClient = ref.watch(apiClientProvider);
      final List<Map<String, dynamic>> allLocks = [];

      final limitRooms = rooms.take(15).toList();
      for (final room in limitRooms) {
        try {
          final res = await apiClient.dio.get('/api/v1/iot/room/${room.id}');
          final List devices = res.data ?? [];
          for (final d in devices) {
            if (d['isLocked'] != null || d['deviceType'] == 1) {
              // 1 might be smart lock
              allLocks.add({
                'roomId': room.id,
                'deviceId': d['deviceId'],
                'room': room.roomName,
                'branch': 'Khu trọ',
                'battery': (d['lastRecordedValue'] ?? 100).toInt(),
                'isLocked': d['isLocked'] ?? false,
                'status': d['statusMessage'] ?? 'Online',
              });
            }
          }
        } catch (_) {}
      }
      return allLocks;
    });

class OwnerSmartLockScreen extends ConsumerStatefulWidget {
  const OwnerSmartLockScreen({super.key});

  @override
  ConsumerState<OwnerSmartLockScreen> createState() =>
      _OwnerSmartLockScreenState();
}

class _OwnerSmartLockScreenState extends ConsumerState<OwnerSmartLockScreen> {
  // We keep a local state of toggling so we can update UI instantly
  final Map<int, bool> _togglingState = {};

  @override
  Widget build(BuildContext context) {
    final locksAsync = ref.watch(smartLocksProvider);

    return LiquidGlassScaffold(
      title: 'Quản Lý Khóa Thông Minh',
      backgroundColors: AppTheme.kBackgroundLight,
      child: locksAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, st) => Center(child: Text('Lỗi: $e')),
        data: (locks) {
          if (locks.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có thiết bị khóa thông minh nào.',
                style: TextStyle(color: AppTheme.kTextSecondary),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: locks.length,
            itemBuilder: (context, index) {
              final lock = locks[index];
              return _buildLockCard(lock, index);
            },
          );
        },
      ),
    );
  }

  Widget _buildLockCard(Map<String, dynamic> lock, int index) {
    Color statusColor = CupertinoColors.systemGreen;
    if (lock['status'] == 'Offline') statusColor = AppTheme.kTextSecondary;
    if (lock['status'] == 'Low Battery') {
      statusColor = CupertinoColors.systemRed;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${lock['room']} • ${lock['branch']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        lock['status'],
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        CupertinoIcons.battery_25,
                        size: 14,
                        color: AppTheme.kTextSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${lock['battery']}%',
                        style: TextStyle(
                          color: lock['battery'] < 20
                              ? CupertinoColors.systemRed
                              : AppTheme.kTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              _togglingState[index] == true
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CupertinoActivityIndicator(),
                    )
                  : CupertinoSwitch(
                      value: lock['isLocked'],
                      activeTrackColor: LiquidGlassColors.ownerAccent,
                      onChanged: (val) async {
                        setState(() => _togglingState[index] = true);
                        try {
                          final apiClient = ref.read(apiClientProvider);
                          await apiClient.post(
                            '/api/v1/iot/smart-lock/toggle',
                            data: {
                              'deviceId': lock['deviceId'],
                              'roomId': lock['roomId'],
                              'lock': val,
                            },
                          );
                          ref.invalidate(smartLocksProvider);
                        } catch (e) {
                          // Handle error silently or show a toast
                        } finally {
                          if (mounted) {
                            setState(() => _togglingState[index] = false);
                          }
                        }
                      },
                    ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                  child: const Text(
                    'Đổi mật khẩu',
                    style: TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () {
                    // Logic to change lock password
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  color: const Color(0xFFFCE7F3),
                  borderRadius: BorderRadius.circular(8),
                  child: const Text(
                    'Cấp mã tạm thời',
                    style: TextStyle(
                      color: Color(0xFFEC4899),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () {
                    // Logic to issue temporary code
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
