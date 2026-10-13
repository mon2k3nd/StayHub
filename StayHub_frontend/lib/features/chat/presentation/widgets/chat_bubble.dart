import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import '../../data/models/chat_models.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.senderType == 'USER';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.smart_toy, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser ? Colors.blueAccent : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isUser)
                    Text(
                      message.content,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    )
                  else
                    MarkdownBody(
                      data:
                          message.content.isEmpty && message.status == 'LOADING'
                          ? 'Thinking...'
                          : message.content,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(fontSize: 16, color: Colors.black87),
                        code: const TextStyle(
                          backgroundColor: Colors.black12,
                          fontFamily: 'monospace',
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      builders: {'code': CodeBlockBuilder(context)},
                    ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }
}

// Custom builder for code blocks to add a copy button
class CodeBlockBuilder extends MarkdownElementBuilder {
  // BUGFIX (Bug 92): cần BuildContext để hiển thị SnackBar khi sao chép.
  // BUGFIX (Bug 114): dùng WeakReference để tránh giữ context đã bị dispose.
  // Builder được tạo mỗi lần build và có thể tồn tại lâu hơn widget; giữ
  // tham chiếu mạnh tới context cũ sẽ gây lỗi "Looking up a deactivated
  // widget's ancestor" khi bấm Copy sau khi bubble đã bị rebuild/huỷ.
  final WeakReference<BuildContext> _contextRef;

  CodeBlockBuilder(BuildContext context) : _contextRef = WeakReference(context);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final textContent = element.textContent;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Code',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                // BUGFIX (Bug 92): nút "Copy" trước đây có `onTap: () {}` —
                // UI chết, bấm không làm gì. Giờ sao chép nội dung code vào
                // clipboard và phản hồi bằng SnackBar.
                InkWell(
                  onTap: () async {
                    // BUGFIX (Bug 114): await Clipboard.setData và lấy context
                    // an toàn từ WeakReference; bỏ qua nếu context đã bị huỷ.
                    await Clipboard.setData(ClipboardData(text: textContent));
                    final ctx = _contextRef.target;
                    if (ctx == null || !ctx.mounted) return;
                    ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(
                      const SnackBar(
                        content: Text('Đã sao chép mã'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.copy, size: 14, color: Colors.white70),
                      SizedBox(width: 4),
                      Text(
                        'Copy',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            child: Text(
              textContent,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
