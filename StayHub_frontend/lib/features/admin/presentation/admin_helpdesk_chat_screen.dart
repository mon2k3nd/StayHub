import 'dart:async';
import 'package:flutter/cupertino.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/theme/app_theme.dart';

class AdminHelpdeskChatScreen extends StatefulWidget {
  final String ownerName;
  final String issue;

  const AdminHelpdeskChatScreen({
    super.key,
    required this.ownerName,
    required this.issue,
  });

  @override
  State<AdminHelpdeskChatScreen> createState() =>
      _AdminHelpdeskChatScreenState();
}

class _AdminHelpdeskChatScreenState extends State<AdminHelpdeskChatScreen> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // System initial message
    _messages.add({
      'isMe': false,
      'text':
          'Khách hàng ${widget.ownerName} đã gửi yêu cầu: "${widget.issue}"',
      'isSystem': true,
    });
  }

  void _sendMessage() {
    if (_textCtrl.text.trim().isEmpty) return;

    final text = _textCtrl.text;
    setState(() {
      _messages.add({'isMe': true, 'text': text, 'isSystem': false});
      _textCtrl.clear();
      _isTyping = true;
    });
    _scrollToBottom();

    // Simulate reply after 1.5 seconds
    Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add({
          'isMe': false,
          'text':
              'Cảm ơn bộ phận CSKH. Mình đã hiểu rồi ạ. Để mình thử thao tác lại xem sao nhé!',
          'isSystem': false,
        });
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        unawaited(
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent + 100,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      title: 'Ticket: ${widget.ownerName}',
      backgroundColors: AppTheme.kBackgroundLight,
      useScrollView: false,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                if (msg['isSystem'] == true) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey5,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          msg['text'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                      ),
                    ),
                  );
                }

                final isMe = msg['isMe'] == true;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: isMe
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isMe)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(
                            CupertinoIcons.person_crop_circle_fill,
                            size: 24,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isMe
                                ? CupertinoColors.activeBlue
                                : CupertinoColors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(isMe ? 20 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.black.withValues(
                                  alpha: 0.05,
                                ),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            msg['text'],
                            style: TextStyle(
                              color: isMe
                                  ? CupertinoColors.white
                                  : CupertinoColors.black,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.only(left: 48, bottom: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Khách hàng đang soạn tin...',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: CupertinoColors.white.withValues(alpha: 0.9),
              border: const Border(
                top: BorderSide(color: CupertinoColors.systemGrey5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoTextField(
                    controller: _textCtrl,
                    placeholder: 'Nhập nội dung phản hồi...',
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 12),
                CupertinoButton(
                  padding: const EdgeInsets.all(12),
                  color: CupertinoColors.activeBlue,
                  borderRadius: BorderRadius.circular(24),
                  onPressed: _sendMessage,
                  child: const Icon(CupertinoIcons.paperplane_fill, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
