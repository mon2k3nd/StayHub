import 'package:flutter/material.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSend;
  final bool isLoading;

  const ChatInput({super.key, required this.onSend, this.isLoading = false});

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // BUGFIX (Bug 87): cờ chống gửi trùng (double-tap / Enter + tap) ở tầng
  // widget. Trước đây chỉ dựa vào `widget.isLoading` do cha truyền xuống —
  // nếu cha không cập nhật kịp (hoặc không truyền) thì người dùng có thể gửi
  // 2 lần cùng một nội dung.
  bool _isSending = false;

  Future<void> _handleSend() async {
    if (_isSending) return;
    final text = _controller.text.trim();
    if (text.isEmpty || widget.isLoading) return;

    setState(() => _isSending = true);
    try {
      // BUGFIX (Bug 87): giữ nguyên nội dung cho tới khi gửi xong. Trước đây
      // `_controller.clear()` chạy ngay sau `onSend` (không await) → nếu gửi
      // thất bại, người dùng mất nội dung đã gõ mà không có phản hồi lỗi.
      await widget.onSend(text);
      if (!mounted) return;
      _controller.clear();
      _focusNode.requestFocus();
    } catch (e) {
      // BUGFIX (Bug 113): bọc `onSend` trong try/catch. Trước đây chỉ có
      // try/finally nên nếu callback gửi ném exception, lỗi sẽ lan ra ngoài
      // và trở thành unhandled exception (crash zone trên web). Giữ nguyên
      // nội dung đã gõ để người dùng có thể thử lại.
      debugPrint('ChatInput send error: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: 5,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                  decoration: const InputDecoration(
                    hintText: 'Message StayHub AI...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent,
              ),
              child: IconButton(
                icon: widget.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                // BUGFIX (Bug 50): vô hiệu hoá nút gửi khi đang tải để tránh
                // gửi trùng (double-tap / Enter + tap).
                onPressed: widget.isLoading ? null : _handleSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
