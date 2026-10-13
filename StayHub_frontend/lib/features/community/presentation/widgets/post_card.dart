import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/components/glass_container.dart';
import '../../../../core/components/bounce_click.dart';
import '../../../../core/utils/time_utils.dart';
import '../../data/models/post_model.dart';
import 'dart:async' show unawaited;

// ── Widget ───────────────────────────────────────────────────────────────────
class PostCard extends ConsumerStatefulWidget {
  final PostModel post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onMore;

  const PostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onMore,
  });

  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard>
    with SingleTickerProviderStateMixin {
  late bool _isLiked;
  late int _likesCount;
  bool _isExpanded = false;

  late AnimationController _heartCtrl;
  late Animation<double> _heartScale;
  late Animation<double> _heartBounce;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLikedByMe;
    _likesCount = widget.post.likes;

    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250), // Fast
    );
    // Spring Dynamics (mô phỏng)
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.5,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.5,
          end: 0.85,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.85,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
    ]).animate(_heartCtrl);
    _heartBounce = _heartScale;
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    super.dispose();
  }

  void _toggleLike() {
    unawaited(HapticFeedback.lightImpact());
    unawaited(_heartCtrl.forward(from: 0));
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });
    widget.onLike?.call();
  }

  // ── Avatar color from initials
  List<Color> _avatarGradient(String name) {
    final palettes = [
      [const Color(0xFF298FFF), const Color(0xFF5FAEFF)],
      [const Color(0xFF7C3AED), const Color(0xFFDB2777)],
      [AppTheme.kSuccess, const Color(0xFF059669)],
      [AppTheme.kWarning, AppTheme.kError],
      [const Color(0xFF06B6D4), const Color(0xFF3B82F6)],
    ];
    final idx = name.isNotEmpty ? name.codeUnitAt(0) % palettes.length : 0;
    return palettes[idx];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeProvider);
    final colors = _avatarGradient(widget.post.authorName);
    final textPrimary = isDark
        ? AppTheme.kTextPrimaryDark
        : AppTheme.kTextPrimary;
    final textSecondary = isDark
        ? AppTheme.kTextSecondaryDark
        : AppTheme.kTextSecondary;

    final content = widget.post.content;
    final isLong = content.length > 180;
    final displayText = isLong && !_isExpanded
        ? '${content.substring(0, 180)}…'
        : content;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassContainer(
        blur: 18,
        borderRadius: 22,
        border: Border.all(
          color: widget.post.isOwnerPost
              ? AppTheme.kWarning.withValues(alpha: 0.35)
              : (isDark ? const Color(0x22FFFFFF) : const Color(0x55FFFFFF)),
          width: 1.2,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: widget.post.isOwnerPost
                            ? [AppTheme.kWarning, AppTheme.kError]
                            : colors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (widget.post.isOwnerPost
                                      ? AppTheme.kWarning
                                      : colors[0])
                                  .withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.post.authorName.isNotEmpty
                            ? widget.post.authorName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name + role + time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.post.authorName,
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            if (widget.post.isOwnerPost) ...[
                              const SizedBox(width: 6),
                              _RoleBadge(),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${widget.post.authorRoleLabel} · ${TimeUtils.formatTimeAgo(widget.post.createdAt ?? DateTime.now())}',
                          style: TextStyle(color: textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  // More button
                  BounceClick(
                    onPressed: widget.onMore ?? () {},
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0x22FFFFFF)
                            : const Color(0x0A000000),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        CupertinoIcons.ellipsis,
                        color: textSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Content ───────────────────────────────
              Text(
                displayText,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 14.5,
                  height: 1.55,
                ),
              ),
              if (isLong)
                GestureDetector(
                  onTap: () => setState(() => _isExpanded = !_isExpanded),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _isExpanded ? 'Thu gọn' : 'Xem thêm',
                      style: const TextStyle(
                        color: Color(0xFF298FFF),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 14),

              // ── Divider ───────────────────────────────
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0x00FFFFFF),
                            const Color(0x22FFFFFF),
                            const Color(0x00FFFFFF),
                          ]
                        : [
                            const Color(0x00000000),
                            const Color(0x0F000000),
                            const Color(0x00000000),
                          ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Actions ───────────────────────────────
              Row(
                children: [
                  // Like
                  BounceClick(
                    onPressed: _toggleLike,
                    child: Row(
                      children: [
                        AnimatedBuilder(
                          animation: _heartBounce,
                          builder: (_, child) => Transform.scale(
                            scale: _heartScale.value,
                            child: child,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _isLiked
                                  ? const Color(
                                      0xFFFF2D55,
                                    ).withValues(alpha: 0.12)
                                  : CupertinoColors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _isLiked
                                  ? CupertinoIcons.heart_fill
                                  : CupertinoIcons.heart,
                              color: _isLiked
                                  ? const Color(0xFFFF2D55)
                                  : textSecondary,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, anim) => SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, -0.5),
                              end: Offset.zero,
                            ).animate(anim),
                            child: FadeTransition(opacity: anim, child: child),
                          ),
                          child: Text(
                            _likesCount > 0 ? '$_likesCount' : '',
                            key: ValueKey(_likesCount),
                            style: TextStyle(
                              color: _isLiked
                                  ? const Color(0xFFFF2D55)
                                  : textSecondary,
                              fontWeight: _isLiked
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Comment
                  BounceClick(
                    onPressed: widget.onComment ?? () {},
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: CupertinoColors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            CupertinoIcons.chat_bubble,
                            color: textSecondary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (widget.post.comments > 0)
                          Text(
                            '${widget.post.comments}',
                            style: TextStyle(
                              color: textSecondary,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Share
                  BounceClick(
                    onPressed:
                        widget.onShare ??
                        () {
                          unawaited(HapticFeedback.lightImpact());
                        },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0x18FFFFFF)
                            : const Color(0x08000000),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: isDark
                              ? const Color(0x22FFFFFF)
                              : const Color(0x15000000),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            CupertinoIcons.share,
                            color: textSecondary,
                            size: 15,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Chia sẻ',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: use_key_in_widget_constructors
class _RoleBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.kWarning, AppTheme.kError],
        ),
        borderRadius: BorderRadius.circular(100),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33F59E0B),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.star_fill, color: CupertinoColors.white, size: 9),
          SizedBox(width: 3),
          Text(
            'Quản lý',
            style: TextStyle(
              color: CupertinoColors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
