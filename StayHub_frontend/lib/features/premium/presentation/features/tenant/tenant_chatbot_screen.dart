import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show CircleAvatar;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../chat/application/chat_notifier.dart';
import 'dart:async' show unawaited;

class TenantChatbotScreen extends ConsumerStatefulWidget {
  const TenantChatbotScreen({super.key});

  @override
  ConsumerState<TenantChatbotScreen> createState() =>
      _TenantChatbotScreenState();
}

class _TenantChatbotScreenState extends ConsumerState<TenantChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    unawaited(HapticFeedback.lightImpact());
    unawaited(ref.read(chatProvider.notifier).sendMessage(text));
    _messageController.clear();

    _scrollToBottom();
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
    final messages = ref.watch(chatProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFFF9FAFB).withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
          ),
        ),
        middle: const Text(
          'Trợ lý ảo AI',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? const Center(
                      child: Text(
                        'Xin chào! Tôi có thể giúp gì cho bạn?',
                        style: TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 24,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.senderType == 'USER';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            mainAxisAlignment: isMe
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (!isMe)
                                const Padding(
                                  padding: EdgeInsets.only(right: 12.0),
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Color(0xFF298FFF),
                                    child: Icon(
                                      CupertinoIcons.sparkles,
                                      size: 18,
                                      color: CupertinoColors.white,
                                    ),
                                  ),
                                ),
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? const Color(0xFF298FFF)
                                        : CupertinoColors.white,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(24),
                                      topRight: const Radius.circular(24),
                                      bottomLeft: Radius.circular(
                                        isMe ? 24 : 6,
                                      ),
                                      bottomRight: Radius.circular(
                                        isMe ? 6 : 24,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: CupertinoColors.black.withValues(
                                          alpha: 0.04,
                                        ),
                                        blurRadius: 15,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      msg.status == 'LOADING' &&
                                              msg.content.isEmpty
                                          ? const Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 4,
                                              ),
                                              child:
                                                  CupertinoActivityIndicator(),
                                            )
                                          : isMe
                                          ? Text(
                                              msg.content,
                                              style: const TextStyle(
                                                color: CupertinoColors.white,
                                                fontSize: 16,
                                                height: 1.3,
                                              ),
                                            )
                                          : MarkdownBody(
                                              data: msg.content,
                                              styleSheet: MarkdownStyleSheet(
                                                p: const TextStyle(
                                                  color: Color(0xFF1C1C1E),
                                                  fontSize: 16,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${msg.createdAt.hour}:${msg.createdAt.minute.toString().padLeft(2, '0')}',
                                        style: TextStyle(
                                          color: isMe
                                              ? CupertinoColors.white
                                                    .withValues(alpha: 0.7)
                                              : const Color(0xFF9CA3AF),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      controller: _messageController,
                      placeholder: 'Hỏi trợ lý AI...',
                      placeholderStyle: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 16,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      style: const TextStyle(fontSize: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: CupertinoColors.transparent),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF298FFF),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x40298FFF),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        CupertinoIcons.arrow_up,
                        color: CupertinoColors.white,
                        size: 22,
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
