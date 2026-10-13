import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/theme/app_theme.dart';
import 'dart:async' show unawaited;

class OwnerAiAssistantScreen extends StatefulWidget {
  const OwnerAiAssistantScreen({super.key});

  @override
  State<OwnerAiAssistantScreen> createState() => _OwnerAiAssistantScreenState();
}

class _OwnerAiAssistantScreenState extends State<OwnerAiAssistantScreen> {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  static const String _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  late final GenerativeModel _model;
  late final ChatSession _chat;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: _apiKey);
    _chat = _model.startChat(
      history: [
        Content.text(
          '''Bạn là AI Giám Đốc Vận Hành của StayHub, được thiết kế riêng để phục vụ Chủ nhà (chủ trọ/chủ chung cư mini).
Dữ liệu hiện tại của hệ thống (giả lập):
- Tổng số phòng: 50. Đang thuê: 45. Trống: 5 (Phòng 102, 105, 201, 303, 405).
- Doanh thu dự kiến tháng này: 185,000,000 VNĐ.
- Đã thu: 140,000,000 VNĐ.
- Còn nợ: 45,000,000 VNĐ.
- Khách đang nợ: Nguyễn Văn A (Phòng 203) nợ 5tr, Trần Thị B (Phòng 301) nợ 4tr.
Nhiệm vụ của bạn: Trả lời ngắn gọn, chuyên nghiệp, súc tích bằng tiếng Việt như một người trợ lý đắc lực. Nếu Chủ nhà hỏi thông tin nằm ngoài dữ liệu, hãy khéo léo nói rằng hệ thống đang cập nhật hoặc chưa có dữ liệu đó. Không cần định dạng quá cầu kỳ, hãy trả lời tự nhiên.''',
        ),
      ],
    );

    _messages.add({
      'role': 'ai',
      'text':
          '👋 Xin chào Sếp! Tôi là trợ lý AI giám đốc vận hành của StayHub. Sếp cần xem báo cáo dòng tiền, công nợ hay tình hình phòng trống hôm nay ạ?',
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _textCtrl.clear();

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await _chat.sendMessage(Content.text(text));
      final reply =
          response.text ??
          'Xin lỗi Sếp, hệ thống vừa gặp sự cố nhỏ. Sếp hỏi lại giúp tôi nhé!';

      if (mounted) {
        setState(() {
          _messages.add({'role': 'ai', 'text': reply});
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'ai',
            'text':
                'Xin lỗi Sếp, kết nối AI đang bị gián đoạn. Vui lòng thử lại sau.',
          });
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        unawaited(
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
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
      title: 'Trợ Lý AI',
      useScrollView: false,
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => context.pop(),
        child: const Icon(
          CupertinoIcons.clear_circled_solid,
          color: CupertinoColors.black,
          size: 28,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isAi = msg['role'] == 'ai';
                return _buildChatBubble(msg['text']!, isAi);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CupertinoActivityIndicator(),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(String text, bool isAi) {
    return Align(
      alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isAi ? CupertinoColors.white : AppTheme.kAccentColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isAi ? 4 : 20),
            bottomRight: Radius.circular(isAi ? 20 : 4),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.kTextSecondary.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          text,
          style: TextStyle(
            color: isAi ? CupertinoColors.black : CupertinoColors.white,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: CupertinoColors.white,
        border: Border(top: BorderSide(color: AppTheme.kBorderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GlassContainer(
              blur: 5,
              borderRadius: 24,
              border: Border.all(color: AppTheme.kBorderColor),
              child: CupertinoTextField(
                controller: _textCtrl,
                placeholder: 'Hỏi AI về doanh thu, công nợ...',
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: CupertinoColors.transparent,
                ),
                onSubmitted: (_) => _sendMessage(),
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),
          const SizedBox(width: 12),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _isLoading ? null : _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppTheme.kAccentColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x330EA5E9),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.paperplane_fill,
                color: CupertinoColors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
