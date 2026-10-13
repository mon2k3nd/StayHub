import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../data/notification_model.dart';
import '../data/notification_provider.dart';
import '../data/unread_notifications_count_provider.dart';
import 'widgets/notification_card.dart';
import 'widgets/notification_skeleton.dart';
import 'notification_detail_screen.dart';
import 'broadcast_screen.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/components/bounce_click.dart';
import '../../auth/application/auth_notifier.dart';
import '../../../core/utils/toast_utils.dart';
import 'dart:async' show unawaited;

/// Filter model — keeps label + predicate together so the chip row and the
/// filtering logic can never drift out of sync (Bug: previously the pull-down
/// menu and the `where()` clauses were duplicated and could diverge).
class _NotifFilter {
  final String label;
  final IconData icon;
  final bool Function(dynamic notif) test;

  const _NotifFilter({
    required this.label,
    required this.icon,
    required this.test,
  });
}

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen>
    with SingleTickerProviderStateMixin {
  static const List<_NotifFilter> _filters = [
    _NotifFilter(
      label: 'Tất cả',
      icon: CupertinoIcons.tray_full,
      test: _alwaysTrue,
    ),
    _NotifFilter(
      label: 'Chưa đọc',
      icon: CupertinoIcons.circle_fill,
      test: _isUnread,
    ),
    _NotifFilter(
      label: 'Sự cố',
      icon: CupertinoIcons.wrench_fill,
      test: _isIncident,
    ),
    _NotifFilter(
      label: 'Thuê/Trả phòng',
      icon: CupertinoIcons.house_fill,
      test: _isRental,
    ),
    _NotifFilter(
      label: 'Hợp đồng',
      icon: CupertinoIcons.doc_text_fill,
      test: _isContract,
    ),
    _NotifFilter(
      label: 'Hệ thống',
      icon: CupertinoIcons.speaker_2_fill,
      test: _isSystem,
    ),
  ];

  static bool _alwaysTrue(dynamic _) => true;
  static bool _isUnread(dynamic n) =>
      n is NotificationModel && n.isRead == false;
  static bool _isIncident(dynamic n) =>
      n is NotificationModel &&
      (n.type.contains('TICKET') || n.type.contains('MAINTENANCE'));
  static bool _isRental(dynamic n) =>
      n is NotificationModel &&
      (n.type.contains('ROOM_RESERVED') || n.type.contains('CHECKOUT'));
  static bool _isContract(dynamic n) =>
      n is NotificationModel && n.type.contains('CONTRACT');
  static bool _isSystem(dynamic n) =>
      n is NotificationModel && n.type.contains('SYSTEM_ALERT');

  int _selectedFilterIndex = 0;
  bool _isScrollingDown = false;
  bool _isSpeedDialOpen = false;
  bool _isMarkingAll = false;
  late AnimationController _speedDialController;
  late Animation<double> _expandAnimation;
  final _titleController = GlassLargeTitleController();

  _NotifFilter get _selectedFilter => _filters[_selectedFilterIndex];

  @override
  void initState() {
    super.initState();
    _speedDialController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _speedDialController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _speedDialController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _toggleSpeedDial() {
    unawaited(HapticFeedback.lightImpact());
    setState(() {
      _isSpeedDialOpen = !_isSpeedDialOpen;
      if (_isSpeedDialOpen) {
        unawaited(_speedDialController.forward());
      } else {
        unawaited(_speedDialController.reverse());
      }
    });
  }

  Future<void> _markAllRead(int userId) async {
    if (_isMarkingAll) return;
    setState(() => _isMarkingAll = true);
    unawaited(HapticFeedback.lightImpact());
    try {
      final ok = await ref
          .read(notificationActionProvider)
          .markAllAsRead(userId);
      if (ok) {
        ref.invalidate(notificationsProvider);
        ref.invalidate(unreadNotificationsCountProvider);
        if (mounted) {
          ToastUtils.show(context, 'Đã đánh dấu tất cả là đã đọc');
        }
      } else if (mounted) {
        ToastUtils.show(context, 'Không thể đánh dấu đã đọc');
      }
    } finally {
      if (mounted) setState(() => _isMarkingAll = false);
    }
  }

  /// Opens the owner broadcast composer (send a notification to all tenants).
  void _openBroadcastComposer() {
    unawaited(
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BroadcastScreen()),
      ),
    );
  }

  /// Scrolls the notification list back to the top.
  void _scrollToTop() {
    final controller = _titleController.scrollController;
    if (controller.hasClients) {
      unawaited(
        controller.animateTo(
          0,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
        ),
      );
    }
  }

  /// Confirms and deletes every notification currently visible to the user.
  Future<void> _confirmClearAll() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Xóa tất cả thông báo?'),
        content: const Text(
          'Toàn bộ thông báo sẽ bị xóa vĩnh viễn. Hành động này không thể hoàn tác.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa tất cả'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final notifications = ref.read(notificationsProvider).value ?? const [];
    // Only real (server-backed) notifications can be deleted; guest mock
    // notifications have negative ids and are skipped by the service.
    final deletable = notifications.where((n) => n.id > 0).toList();
    if (deletable.isEmpty) {
      if (mounted) ToastUtils.show(context, 'Không có thông báo để xóa');
      return;
    }

    final service = ref.read(notificationActionProvider);
    var deletedAny = false;
    for (final n in deletable) {
      final ok = await service.deleteNotification(n.id);
      if (ok) deletedAny = true;
    }

    if (!mounted) return;
    if (deletedAny) {
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadNotificationsCountProvider);
      ToastUtils.show(context, 'Đã xóa tất cả thông báo');
    } else {
      ToastUtils.show(context, 'Không thể xóa thông báo');
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final authState = ref.watch(authProvider);
    final user = authState.value;
    final isOwner = user?.role == 'OWNER';
    final unreadCount = ref.watch(unreadNotificationsCountProvider).value ?? 0;

    return NotificationListener<UserScrollNotification>(
      onNotification: (notification) {
        if (notification.direction == ScrollDirection.forward) {
          if (_isScrollingDown) setState(() => _isScrollingDown = false);
        } else if (notification.direction == ScrollDirection.reverse) {
          if (!_isScrollingDown) setState(() => _isScrollingDown = true);
        }
        return false;
      },
      child: GlassScaffold(
        // 1. Wallpaper background
        backgroundColor: AppTheme.kBackgroundLight,
        background: Container(color: AppTheme.kBackgroundLight),
        contentAwareBrightness: true,

        // 2. Navigation Bar
        appBar: GlassAppBar(
          title: const Text('Thông báo'),
          largeTitleController: _titleController,
          leading: Navigator.canPop(context)
              ? GlassButton(
                  icon: const Icon(CupertinoIcons.back),
                  onTap: () => Navigator.pop(context),
                )
              : null,
          actions: [
            if (unreadCount > 0 && user != null)
              GlassButton(
                icon: _isMarkingAll
                    ? const CupertinoActivityIndicator(radius: 8)
                    : const Icon(CupertinoIcons.checkmark_alt),
                onTap: () {
                  if (!_isMarkingAll) _markAllRead(user.id);
                },
              ),
            GlassPullDownButton(
              icon: const Icon(
                CupertinoIcons.ellipsis_circle,
                color: CupertinoColors.activeBlue,
              ),
              items: [
                for (var i = 0; i < _filters.length; i++)
                  GlassMenuItem(
                    title: _filters[i].label,
                    subtitle: i == 0 ? 'Lọc theo' : null,
                    onTap: () => setState(() => _selectedFilterIndex = i),
                    trailing: _selectedFilterIndex == i
                        ? const Icon(CupertinoIcons.checkmark, size: 16)
                        : null,
                  ),
              ],
            ),
          ],
        ),

        body: CustomScrollView(
          controller: _titleController.scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.paddingOf(context).top + 64),
            ),
            GlassLargeTitle(text: 'Thông báo', controller: _titleController),
            SliverToBoxAdapter(child: _buildFilterChips()),
            notificationsAsync.when(
              data: (notifications) {
                final filteredNotifications = notifications
                    .where(_selectedFilter.test)
                    .toList();

                if (filteredNotifications.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.only(bottom: 120, top: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final notif = filteredNotifications[index];
                      return Dismissible(
                        key: ValueKey('dismiss_${notif.id}'),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          unawaited(HapticFeedback.mediumImpact());
                          // Optimistically drop the row from the local list so
                          // the Dismissible is removed from the tree in the
                          // same frame it is dismissed (avoids the
                          // "dismissed Dismissible still part of the tree"
                          // assertion while the network call is in flight).
                          setState(() {
                            notifications.remove(notif);
                          });
                          unawaited(() async {
                            final success = await ref
                                .read(notificationActionProvider)
                                .deleteNotification(notif.id);
                            if (success) {
                              if (!notif.isRead) {
                                ref
                                    .read(
                                      unreadNotificationsCountProvider.notifier,
                                    )
                                    .decrement();
                              }
                              ref.invalidate(notificationsProvider);
                            } else {
                              // Roll back the optimistic removal on failure.
                              ref.invalidate(notificationsProvider);
                            }
                          }());
                        },
                        background: _buildSwipeBackground(),
                        child: NotificationCard(
                          key: ValueKey(notif.id),
                          notification: notif,
                          onTap: () => _handleTap(notif),
                        ),
                      );
                    }, childCount: filteredNotifications.length),
                  ),
                );
              },
              loading: () => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const NotificationSkeleton(),
                  childCount: 6,
                ),
              ),
              error: (err, stack) => SliverFillRemaining(
                hasScrollBody: false,
                child: _buildErrorState(err),
              ),
            ),
          ],
        ),

        bodyOverlays: [
          // 2. Backdrop Blur and Overlay
          if (isOwner)
            AnimatedBuilder(
              animation: _speedDialController,
              builder: (context, child) {
                if (_speedDialController.value == 0.0) {
                  return const SizedBox.shrink();
                }
                return Positioned.fill(
                  child: GestureDetector(
                    onTap: _toggleSpeedDial,
                    behavior: HitTestBehavior.opaque,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 2.0 * _speedDialController.value,
                        sigmaY: 2.0 * _speedDialController.value,
                      ),
                      child: Container(
                        color: Colors.black.withValues(
                          alpha: 0.1 * _speedDialController.value,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

          // 3. Speed Dial Items — notification-specific actions (owner only)
          if (isOwner)
            Positioned(
              bottom: 88,
              right: 20,
              child: AnimatedBuilder(
                animation: _expandAnimation,
                builder: (context, child) {
                  if (_speedDialController.value == 0.0) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildAnimatedSpeedDialItem(
                        icon: CupertinoIcons.paperplane,
                        title: 'Gửi thông báo',
                        index: 3,
                        onTap: () {
                          _toggleSpeedDial();
                          _openBroadcastComposer();
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildAnimatedSpeedDialItem(
                        icon: CupertinoIcons.checkmark_seal,
                        title: 'Đánh dấu đã đọc',
                        index: 2,
                        onTap: () {
                          _toggleSpeedDial();
                          if (user != null) _markAllRead(user.id);
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildAnimatedSpeedDialItem(
                        icon: CupertinoIcons.arrow_down_circle,
                        title: 'Về đầu danh sách',
                        index: 1,
                        onTap: () {
                          _toggleSpeedDial();
                          _scrollToTop();
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildAnimatedSpeedDialItem(
                        icon: CupertinoIcons.trash,
                        title: 'Xóa tất cả',
                        isDestructive: true,
                        index: 0,
                        onTap: () {
                          _toggleSpeedDial();
                          _confirmClearAll();
                        },
                      ),
                    ],
                  );
                },
              ),
            ),

          // 4. Main FAB
          if (isOwner)
            Positioned(
              bottom: 16,
              right: 16,
              child: AnimatedOpacity(
                opacity: (_isScrollingDown && !_isSpeedDialOpen) ? 0.5 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: AnimatedScale(
                  scale: (_isScrollingDown && !_isSpeedDialOpen) ? 0.9 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: FloatingActionButton(
                    onPressed: _toggleSpeedDial,
                    backgroundColor: _isSpeedDialOpen
                        ? Colors.white
                        : AppTheme.kBrand,
                    elevation: 8,
                    shape: const CircleBorder(),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return RotationTransition(
                              turns: child.key == const ValueKey('close')
                                  ? Tween<double>(
                                      begin: -0.25,
                                      end: 0.0,
                                    ).animate(animation)
                                  : Tween<double>(
                                      begin: 0.25,
                                      end: 0.0,
                                    ).animate(animation),
                              child: ScaleTransition(
                                scale: animation,
                                child: child,
                              ),
                            );
                          },
                      child: _isSpeedDialOpen
                          ? const Icon(
                              CupertinoIcons.clear,
                              key: ValueKey('close'),
                              color: AppTheme.kBrand,
                              size: 28,
                            )
                          : const Icon(
                              CupertinoIcons.paperplane_fill,
                              key: ValueKey('open'),
                              color: Colors.white,
                              size: 24,
                            ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Filter chips ─────────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final filter = _filters[i];
          final isSelected = _selectedFilterIndex == i;
          return BounceClick(
            onPressed: () {
              unawaited(HapticFeedback.selectionClick());
              setState(() => _selectedFilterIndex = i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? PremiumGradients.skyBrand : null,
                color: isSelected ? null : Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.7),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppTheme.kBrand.withValues(alpha: 0.35)
                        : AppTheme.kBrand.withValues(alpha: 0.06),
                    blurRadius: isSelected ? 16 : 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter.icon,
                    size: 15,
                    color: isSelected ? Colors.white : AppTheme.kTextMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    filter.label,
                    style: TextStyle(
                      fontFamily: AppTheme.kFontFamily,
                      fontSize: 13.5,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : AppTheme.kTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Swipe background ─────────────────────────────────────────────────────
  Widget _buildSwipeBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF87171), Color(0xFFEF4444)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kError.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Icon(
        CupertinoIcons.delete_solid,
        color: Colors.white,
        size: 26,
      ),
    );
  }

  // ─── Empty state ──────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.kBrand.withValues(alpha: 0.18),
                    AppTheme.kBrand.withValues(alpha: 0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                CupertinoIcons.bell_slash,
                size: 44,
                color: AppTheme.kBrand,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Không có thông báo nào',
              style: TextStyle(
                fontFamily: AppTheme.kFontFamily,
                color: AppTheme.kTextPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mọi cập nhật về phòng, hợp đồng và sự cố sẽ xuất hiện tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.kFontFamily,
                color: AppTheme.kTextMuted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Error state ──────────────────────────────────────────────────────────
  Widget _buildErrorState(Object err) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.kError.withValues(alpha: 0.1),
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                size: 40,
                color: AppTheme.kError,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Đã có lỗi xảy ra',
              style: TextStyle(
                fontFamily: AppTheme.kFontFamily,
                color: AppTheme.kTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$err',
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: AppTheme.kFontFamily,
                color: AppTheme.kTextMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            BounceClick(
              onPressed: () => ref.invalidate(notificationsProvider),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  gradient: PremiumGradients.skyBrand,
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.kBrand.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Text(
                  'Thử lại',
                  style: TextStyle(
                    fontFamily: AppTheme.kFontFamily,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tap handling ─────────────────────────────────────────────────────────
  Future<void> _handleTap(NotificationModel notif) async {
    if (!notif.isRead) {
      await ref.read(notificationActionProvider).markAsRead(notif.id);
      ref.read(unreadNotificationsCountProvider.notifier).decrement();
      ref.invalidate(notificationsProvider);
    }
    if (!mounted) return;

    // Resolve an optional deep-link path from actionMetadata. The metadata is
    // a JSON string that may be null, malformed, or hold a non-String `path`,
    // so every step is guarded to avoid a runtime cast error.
    String? deepLink;
    try {
      final raw = notif.actionMetadata;
      if (raw is String && raw.isNotEmpty) {
        final decoded = json.decode(raw);
        if (decoded is Map) {
          final candidate = decoded['path'];
          if (candidate is String && candidate.isNotEmpty) {
            deepLink = candidate;
          }
        }
      }
    } catch (e, st) {
      debugPrint('NotificationCenter: bad actionMetadata → $e\n$st');
    }

    if (deepLink != null) {
      var path = deepLink;
      if (path.startsWith('/ticket-detail/')) {
        path = path.replaceFirst('/ticket-detail/', '/ticket/ticket-detail/');
      } else if (path.startsWith('/staff-ticket-detail/')) {
        path = path.replaceFirst(
          '/staff-ticket-detail/',
          '/ticket/ticket-detail/',
        );
      }
      if (!mounted) return;
      unawaited(context.push(path));
      return;
    }

    if (!mounted) return;
    unawaited(
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NotificationDetailScreen(notification: notif),
        ),
      ),
    );
  }

  Widget _buildAnimatedSpeedDialItem({
    required IconData icon,
    required String title,
    required int index,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final delay = index * 0.1;
    final itemAnimation = CurvedAnimation(
      parent: _speedDialController,
      curve: Interval(delay, 1.0, curve: Curves.easeOutBack),
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(itemAnimation),
      child: ScaleTransition(
        scale: itemAnimation,
        alignment: Alignment.bottomRight,
        child: FadeTransition(
          opacity: itemAnimation,
          child: _buildSpeedDialItem(
            icon: icon,
            title: title,
            isDestructive: isDestructive,
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedDialItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final primaryColor = isDestructive
        ? CupertinoColors.destructiveRed
        : AppTheme.kBrand;

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AdaptiveGlass(
            shape: const LiquidOval(),
            settings: const LiquidGlassSettings(blur: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Text(
                title,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          AdaptiveGlass(
            shape: const LiquidOval(),
            settings: const LiquidGlassSettings(blur: 12),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.65),
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, color: primaryColor, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
