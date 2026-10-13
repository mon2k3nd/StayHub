import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async' show unawaited;

import '../theme/app_theme.dart';
import 'stayhub_logo_icon.dart';
import '../../features/auth/application/auth_notifier.dart';
import '../../features/notification/data/unread_notifications_count_provider.dart';

class StayHubMainHeader extends ConsumerWidget {
  final List<Widget>? rightActions;

  /// Optional leading widget next to the logo
  final Widget? leading;

  /// Optional padding. By default it has no padding to allow the parent to pad it,
  /// but if you want default padding, pass EdgeInsets here.
  final EdgeInsetsGeometry padding;

  const StayHubMainHeader({
    super.key,
    this.rightActions,
    this.leading,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 8)],
          // Logo + tên thương hiệu: chạm vào đều đưa về màn hình Khám phá
          // (tab 0 của GuestMainScaffold, route '/guest').
          InkWell(
            onTap: () => context.go('/guest'),
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StayHubLogoIcon(size: 36, color: AppTheme.kBrand),
                  SizedBox(width: 8),
                  Text(
                    'StayHub',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.kBrandDeep,
                      letterSpacing: -1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          // 4: Default right actions if none provided
          Row(
            mainAxisSize: MainAxisSize.min,
            children: rightActions != null && rightActions!.isNotEmpty
                ? rightActions!
                : _buildDefaultActions(context, ref),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDefaultActions(BuildContext context, WidgetRef ref) {
    return [
      IconButton(
        onPressed: () {
          final user = ref.read(authProvider).value;
          if (user == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Tính năng quét QR chỉ dành cho người dùng đã đăng nhập.',
                ),
              ),
            );
          } else {
            unawaited(context.push('/qr-scanner'));
          }
        },
        icon: const Icon(
          CupertinoIcons.qrcode_viewfinder,
          size: 24,
          color: Color(0xFF1E293B),
        ),
        splashRadius: 24,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
      const SizedBox(width: 8),
      // Tin nhắn — mở danh sách hội thoại (chat list).
      // Luôn điều hướng: ChatListScreen tự xử lý trạng thái khách chưa
      // đăng nhập (userRole = 'GUEST') và hiển thị empty-state phù hợp.
      // Trước đây chặn khách bằng SnackBar → trông như "bấm không có gì".
      IconButton(
        onPressed: () => unawaited(context.push('/chat-list')),
        icon: const Icon(
          CupertinoIcons.chat_bubble_2_fill,
          size: 24,
          color: Color(0xFF1E293B),
        ),
        splashRadius: 24,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
      const SizedBox(width: 8),
      IconButton(
        onPressed: () {
          unawaited(context.push('/notifications'));
        },
        icon: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            const Icon(
              CupertinoIcons.bell_fill,
              size: 24,
              color: Color(0xFF1E293B),
            ),
            Consumer(
              builder: (context, ref, child) {
                final unreadCount =
                    ref.watch(unreadNotificationsCountProvider).value ?? 0;
                if (unreadCount <= 0) return const SizedBox.shrink();
                return Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.kError,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        splashRadius: 24,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    ];
  }
}
