import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/components/glass_container.dart';
import '../../../branch/data/models/branch_model.dart';
import '../../../../core/components/app_error_widget.dart';

class OwnerBranchList extends StatelessWidget {
  final AsyncValue<List<BranchModel>> branchesAsync;

  const OwnerBranchList({super.key, required this.branchesAsync});

  @override
  Widget build(BuildContext context) {
    return branchesAsync.when(
      data: (branches) {
        if (branches.isEmpty) {
          return const Center(child: Text('Bạn chưa có dãy trọ nào.'));
        }
        return Column(
          children: branches.map((b) {
            const color = AppTheme.kAccentColor;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => context.push('/branch'),
                child: GlassContainer(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          CupertinoIcons.building_2_fill,
                          color: CupertinoColors.systemBlue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.branchName,
                              style: const TextStyle(
                                color: CupertinoColors.black,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${b.totalRooms} phòng • ${b.address}',
                              style: const TextStyle(
                                color: Color(0xFF4B5563),
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${b.totalRooms}',
                            style: const TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const Text(
                            'phòng',
                            style: TextStyle(
                              color: Color(0xFF4B5563),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, _) => AppErrorWidget(error: e),
    );
  }
}
