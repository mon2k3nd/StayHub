import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/time_utils.dart';
import '../../community/application/post_notifier.dart';
import 'dart:async' show unawaited;

class TenantCommunityBoard extends ConsumerWidget {
  const TenantCommunityBoard({super.key});

  void _showCreatePostDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Đăng bài viết mới'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: CupertinoTextField(
              controller: ctrl,
              placeholder: 'Bạn đang nghĩ gì?',
              maxLines: 4,
              autofocus: true,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text(
                'Hủy',
                style: TextStyle(color: AppTheme.kTextSecondary),
              ),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              child: const Text(
                'Đăng bài',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: () {
                final text = ctrl.text.trim();
                if (text.isNotEmpty) {
                  unawaited(ref.read(postProvider.notifier).createPost(text));
                  Navigator.pop(ctx);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postProvider);

    return LiquidGlassScaffold(
      title: 'Bảng Tin Khu Trọ',
      backgroundColors: AppTheme.kBackgroundLight,
      useScrollView: false,
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _showCreatePostDialog(context, ref),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: PremiumGradients.oceanBlue,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppTheme.kBrandDeep.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            CupertinoIcons.pencil,
            color: CupertinoColors.white,
            size: 18,
          ),
        ),
      ),
      child: postsAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Lỗi: $err',
            style: const TextStyle(color: CupertinoColors.systemRed),
          ),
        ),
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.kBrandDeep.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.news,
                      size: 48,
                      color: AppTheme.kBrandDeep,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Chưa có bài viết nào',
                    style: TextStyle(
                      color: Color(0xFF374151),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hãy là người đầu tiên đăng bài!',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final p = posts[index];
              final isOwner = p.authorRole == 'OWNER';

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Avatar with gradient
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: isOwner
                                  ? PremiumGradients.fireOrange
                                  : PremiumGradients.oceanBlue,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (isOwner
                                              ? const Color(0xFFEA580C)
                                              : AppTheme.kBrandDeep)
                                          .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              isOwner
                                  ? CupertinoIcons.star_fill
                                  : CupertinoIcons.person_fill,
                              color: CupertinoColors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      p.authorName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: isOwner
                                            ? const Color(0xFFEA580C)
                                            : const Color(0xFF111827),
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (isOwner) ...[
                                      const SizedBox(width: 4),
                                      const Icon(
                                        CupertinoIcons.checkmark_seal_fill,
                                        color: AppTheme.kBrandDeep,
                                        size: 14,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  TimeUtils.formatTimeAgo(
                                    p.createdAt ?? DateTime.now(),
                                  ),
                                  style: const TextStyle(
                                    color: Color(0xFF9CA3AF),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {},
                            minimumSize: const Size(0, 0),
                            child: const Icon(
                              CupertinoIcons.ellipsis,
                              color: Color(0xFF9CA3AF),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        p.content,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(height: 0.5, color: const Color(0xFFE5E7EB)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildActionButton(
                            icon: p.isLikedByMe
                                ? CupertinoIcons.heart_fill
                                : CupertinoIcons.heart,
                            label: '${p.likes}',
                            color: p.isLikedByMe
                                ? AppTheme.kError
                                : const Color(0xFF9CA3AF),
                            onTap: () => ref
                                .read(postProvider.notifier)
                                .toggleLike(p.id),
                          ),
                          const SizedBox(width: 24),
                          _buildActionButton(
                            icon: CupertinoIcons.chat_bubble,
                            label: '${p.comments}',
                            color: const Color(0xFF9CA3AF),
                            onTap: () {},
                          ),
                          const Spacer(),
                          const Icon(
                            CupertinoIcons.share,
                            color: Color(0xFF9CA3AF),
                            size: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
