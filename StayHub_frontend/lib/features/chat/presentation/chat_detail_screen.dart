import 'package:flutter/material.dart' show CircleAvatar;
import 'package:flutter/cupertino.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/toast_utils.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/direct_chat_provider.dart';
import 'dart:async' show unawaited;

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String chatName;
  final String avatarUrl;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.avatarUrl,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  int get _partnerId =>
      int.tryParse(widget.chatId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 2;

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    unawaited(HapticFeedback.lightImpact());
    final partnerId = _partnerId;

    // BUGFIX (Bug 74b): giữ nguyên nội dung cho tới khi gửi thành công; chỉ
    // xoá ô nhập sau khi repository xác nhận để tránh mất tin nhắn khi lỗi.
    setState(() => _isSending = true);
    try {
      await ref.read(directChatProvider(partnerId).notifier).sendMessage(text);
      if (!mounted) return;
      _messageController.clear();
    } catch (_) {
      if (!mounted) return;
      ToastUtils.show(
        context,
        'Không gửi được tin nhắn. Vui lòng thử lại.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }

    // BUGFIX (Bug 56): hoãn cuộn tới sau frame để tin nhắn optimistic đã render
    // (trước đây cuộn ngay lập tức nên chưa tới đáy).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      unawaited(
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final partnerId = _partnerId;
    final chatState = ref.watch(directChatProvider(partnerId));

    // BUGFIX (Bug 73): chỉ auto-scroll khi số lượng tin nhắn thay đổi, tránh
    // đăng ký post-frame callback trên mọi lần rebuild.
    ref.listen<int>(
      directChatProvider(
        partnerId,
      ).select((async) => async.hasValue ? async.value!.length : 0),
      (prev, next) {
        if (prev != next) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _scrollToBottom();
          });
        }
      },
    );

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Surface color per rule
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppTheme.kSurface1Light.withValues(alpha: 0.8),
        middle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundImage: NetworkImage(widget.avatarUrl),
            ),
            const SizedBox(width: 8),
            Text(widget.chatName),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: chatState.when(
                loading: () =>
                    const Center(child: CupertinoActivityIndicator()),
                // BUGFIX (Bug 72): thông báo lỗi thân thiện kèm nút thử lại
                // thay vì hiển thị nguyên văn exception.
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          CupertinoIcons.exclamationmark_bubble,
                          size: 40,
                          color: AppTheme.kTextSecondary,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Không tải được cuộc trò chuyện',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.kTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Vui lòng kiểm tra kết nối và thử lại.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.kTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CupertinoButton(
                          color: const Color(0xFF298FFF),
                          borderRadius: BorderRadius.circular(20),
                          onPressed: () =>
                              ref.invalidate(directChatProvider(partnerId)),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (messages) {
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      // BUGFIX (Bug 74): so khớp với partnerId thay vì hardcode
                      // userId = 1, tránh hiển thị sai phía bong bóng chat.
                      final isMe = msg.senderId != partnerId;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          mainAxisAlignment: isMe
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            if (!isMe)
                              CircleAvatar(
                                radius: 14,
                                backgroundImage: NetworkImage(widget.avatarUrl),
                              ),
                            if (!isMe) const SizedBox(width: 8),
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? const Color(0xFF298FFF) // Brand Primary
                                      : AppTheme.kSurface1Light,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(20),
                                    topRight: const Radius.circular(20),
                                    bottomLeft: Radius.circular(isMe ? 20 : 4),
                                    bottomRight: Radius.circular(isMe ? 4 : 20),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.kTextPrimary.withValues(
                                        alpha: 0.05,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: isMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg.content,
                                      style: TextStyle(
                                        color: isMe
                                            ? AppTheme.kSurface1Light
                                            : AppTheme.kTextPrimary,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          // BUGFIX (Bug 55): chuẩn hoá về giờ local.
                                          msg.createdAt != null
                                              ? () {
                                                  final t = msg.createdAt!
                                                      .toLocal();
                                                  return '${t.hour}:${t.minute.toString().padLeft(2, '0')}';
                                                }()
                                              : 'Vừa xong',
                                          style: TextStyle(
                                            color: isMe
                                                ? AppTheme.kSurface1Light
                                                      .withValues(alpha: 0.7)
                                                : AppTheme.kTextSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                        if (isMe) ...[
                                          const SizedBox(width: 4),
                                          Icon(
                                            msg.hasError
                                                ? CupertinoIcons
                                                      .exclamationmark_circle
                                                : CupertinoIcons.checkmark_alt,
                                            size: 12,
                                            color: msg.hasError
                                                ? CupertinoColors.destructiveRed
                                                : AppTheme.kSurface1Light
                                                      .withValues(alpha: 0.7),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: AppTheme.kSurface1Light,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.kTextPrimary.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    // BUGFIX (Bug 101): nút đính kèm trước đây onPressed rỗng
                    // (UI chết). Thông báo cho người dùng thay vì im lặng.
                    onPressed: () {
                      ToastUtils.show(
                        context,
                        'Tính năng đính kèm đang phát triển.',
                      );
                    },
                    child: const Icon(
                      CupertinoIcons.paperclip,
                      color: AppTheme.kTextSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CupertinoTextField(
                      controller: _messageController,
                      placeholder: 'Nhập tin nhắn...',
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppTheme.kTextSecondary.withValues(alpha: 0.2),
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF298FFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.arrow_up,
                        color: AppTheme.kSurface1Light,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
