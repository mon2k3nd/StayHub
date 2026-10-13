import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/liquid_background.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/providers/core_providers.dart';

final staffBranchRoomsProvider = FutureProvider.family<List<dynamic>, int>((
  ref,
  branchId,
) async {
  final api = ref.read(apiClientProvider);
  final response = await api.get('/v1/rooms/branch/$branchId');
  return response['data'] ?? [];
});

class StaffBranchRoomScreen extends ConsumerStatefulWidget {
  final int branchId;
  final String branchName;

  const StaffBranchRoomScreen({
    super.key,
    required this.branchId,
    required this.branchName,
  });

  @override
  ConsumerState<StaffBranchRoomScreen> createState() =>
      _StaffBranchRoomScreenState();
}

class _StaffBranchRoomScreenState extends ConsumerState<StaffBranchRoomScreen> {
  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(staffBranchRoomsProvider(widget.branchId));

    return CupertinoPageScaffold(
      child: LiquidBackground(
        colors: AppTheme.kBackgroundLight,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: Text(
                widget.branchName,
                style: const TextStyle(color: CupertinoColors.black),
              ),
              backgroundColor: const Color(0x00000000),
              border: null,
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              sliver: roomsAsync.when(
                data: (rooms) {
                  if (rooms.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'Không có phòng nào trong dãy trọ này.',
                          style: TextStyle(color: Color(0xFF4B5563)),
                        ),
                      ),
                    );
                  }

                  return SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.2,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final room = rooms[index];
                      final roomName = room['roomName'] ?? '';
                      final status = room['status'] ?? '';

                      Color statusColor = CupertinoColors.systemGrey;
                      String statusText = 'Trống';
                      IconData statusIcon = CupertinoIcons.house;

                      if (status == 'DA_THUE') {
                        statusColor = CupertinoColors.systemGreen;
                        statusText = 'Đã thuê';
                        statusIcon = CupertinoIcons.person_2_fill;
                      } else if (status == 'CHO_DUYET') {
                        statusColor = CupertinoColors.systemOrange;
                        statusText = 'Chờ duyệt';
                        statusIcon = CupertinoIcons.hourglass;
                      }

                      return GlassContainer(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  roomName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                Icon(statusIcon, color: statusColor, size: 18),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }, childCount: rooms.length),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(child: CupertinoActivityIndicator()),
                ),
                error: (e, st) => const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Lỗi tải danh sách phòng',
                      style: TextStyle(color: CupertinoColors.systemRed),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
