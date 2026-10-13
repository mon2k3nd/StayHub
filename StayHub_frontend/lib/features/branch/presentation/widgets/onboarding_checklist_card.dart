import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/components/glass_container.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/branch_model.dart';
import '../../../room/data/models/room_model.dart';
import 'dart:async' show unawaited;

class OnboardingChecklistCard extends StatelessWidget {
  final BranchModel branch;
  final List<RoomModel> rooms;

  const OnboardingChecklistCard({
    super.key,
    required this.branch,
    required this.rooms,
  });

  @override
  Widget build(BuildContext context) {
    // Determine conditions
    // 1. Photos and Prices
    bool hasPhotosAndPrices = false;
    if (rooms.isNotEmpty) {
      hasPhotosAndPrices = rooms.every((r) {
        final hasPhoto =
            r.roomImages != null &&
            r.roomImages.toString().trim().isNotEmpty &&
            r.roomImages.toString().trim() != '[]';
        final hasPrice = (r.price ?? 0) > 0;
        return hasPhoto && hasPrice;
      });
    }

    // 2. Amenities configured
    bool hasAmenities = false;
    if (branch.electricityPrice != null && branch.waterPrice != null) {
      hasAmenities = true;
    }

    // 3. Has published post
    bool hasPublishedPost = false;
    if (rooms.isNotEmpty) {
      hasPublishedPost = rooms.any((r) => r.status != 'TRONG');
    }

    int completedSteps = [
      hasPhotosAndPrices,
      hasAmenities,
      hasPublishedPost,
    ].where((e) => e).length;

    if (completedSteps == 3) {
      return const SizedBox.shrink(); // Hide if completed
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: GlassContainer(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        border: Border.all(
          color: AppTheme.kBrandLight.withValues(alpha: 0.3),
          width: 1.5,
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.kBrandLight.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    CupertinoIcons.rocket_fill,
                    color: AppTheme.kBrand,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tòa nhà đã sẵn sàng!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hoàn thiện $completedSteps/3 bước để bắt đầu cho thuê.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: completedSteps / 3,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.kBrand,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 20),
            _buildChecklistItem(
              title: 'Cập nhật giá và ảnh phòng',
              isCompleted: hasPhotosAndPrices,
              onTap: () {
                unawaited(context.push('/branch/${branch.id}'));
              },
            ),
            const SizedBox(height: 12),
            _buildChecklistItem(
              title: 'Khai báo dịch vụ, tiện ích chung',
              isCompleted: hasAmenities,
              onTap: () {
                unawaited(context.push('/branch-config', extra: branch));
              },
            ),
            const SizedBox(height: 12),
            _buildChecklistItem(
              title: 'Đăng phòng trống lên Chợ trọ',
              isCompleted: hasPublishedPost,
              onTap: () {
                unawaited(context.push('/owner-marketplace'));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem({
    required String title,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: isCompleted ? null : onTap,
      child: Row(
        children: [
          Icon(
            isCompleted
                ? CupertinoIcons.check_mark_circled_solid
                : CupertinoIcons.circle,
            color: isCompleted ? AppTheme.kSuccess : const Color(0xFFCBD5E1),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isCompleted ? FontWeight.normal : FontWeight.w600,
                color: isCompleted
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF1E293B),
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (!isCompleted)
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: Color(0xFF94A3B8),
            ),
        ],
      ),
    );
  }
}
