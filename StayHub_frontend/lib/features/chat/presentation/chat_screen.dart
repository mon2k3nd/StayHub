import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/chat_notifier.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_input.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/theme/app_theme.dart';
import 'dart:async' show unawaited;

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  // BUGFIX (Bug 70): cập nhật _autoScroll qua setState để nút "Cuộn xuống"
  // hiện/ẩn đúng khi người dùng cuộn lên/xuống.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final atBottom = position.pixels >= position.maxScrollExtent - 50;
    if (atBottom != _autoScroll) {
      setState(() => _autoScroll = atBottom);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_autoScroll && _scrollController.hasClients) {
      unawaited(
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    // BUGFIX (Bug 71): chỉ coi là đang tải khi tin nhắn AI cuối cùng ở trạng
    // thái LOADING (thay vì phụ thuộc vị trí tin nhắn cuối bất kỳ).
    final isLoading = messages.any(
      (m) => m.senderType == 'AI' && m.status == 'LOADING',
    );

    // BUGFIX (Bug 69): chỉ auto-scroll khi số lượng tin nhắn thay đổi, tránh
    // đăng ký post-frame callback trên mọi lần rebuild (gây cuộn liên tục).
    ref.listen<int>(chatProvider.select((list) => list.length), (prev, next) {
      if (prev != next) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _scrollToBottom();
        });
      }
    });

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.kBackgroundLight,
      navigationBar: CupertinoNavigationBar(
        border: null,
        backgroundColor: const Color(0xFF1A6FD4).withValues(alpha: 0.92),
        middle: const Text(
          'StayHub AI Assistant',
          style: TextStyle(
            color: CupertinoColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: CupertinoColors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            CupertinoIcons.sparkles,
            color: CupertinoColors.white,
            size: 16,
          ),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEFF6FF), AppTheme.kBackgroundLight],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              gradient: PremiumGradients.oceanBlue,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF1A6FD4,
                                  ).withValues(alpha: 0.35),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              CupertinoIcons.wand_stars,
                              size: 48,
                              color: CupertinoColors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Trợ lý AI StayHub',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Hỏi bất cứ điều gì về phòng trọ,\nhợp đồng, tiện ích...',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF6B7280),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 20, top: 20),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return ChatBubble(message: messages[index]);
                      },
                    ),
            ),
          ),
          ChatInput(
            isLoading: isLoading,
            onSend: (prompt) {
              _autoScroll = true;
              // BUGFIX (Bug 130): bọc try/catch — trước đây dùng `unawaited`
              // nên nếu sendMessage ném exception thì lỗi lan ra ngoài không
              // được xử lý (unhandled async error). Bắt và ghi log an toàn.
              unawaited(
                ref.read(chatProvider.notifier).sendMessage(prompt).catchError((
                  Object e,
                ) {
                  debugPrint('ChatScreen send error: $e');
                }),
              );
            },
          ),
          if (!_autoScroll)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                color: const Color(0xFF1A6FD4),
                borderRadius: BorderRadius.circular(24),
                onPressed: () {
                  _autoScroll = true;
                  _scrollToBottom();
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.arrow_down,
                      color: CupertinoColors.white,
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Cuộn xuống',
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
