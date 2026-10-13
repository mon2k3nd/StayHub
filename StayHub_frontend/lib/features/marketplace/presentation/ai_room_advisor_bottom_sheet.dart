import 'package:flutter/cupertino.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:async' show unawaited;
import '../../../core/theme/app_theme.dart';

class AiRoomAdvisorBottomSheet extends StatefulWidget {
  final void Function(Map<String, dynamic> filters) onFiltersRecommended;

  const AiRoomAdvisorBottomSheet({
    super.key,
    required this.onFiltersRecommended,
  });

  @override
  State<AiRoomAdvisorBottomSheet> createState() =>
      _AiRoomAdvisorBottomSheetState();
}

class _AiRoomAdvisorBottomSheetState extends State<AiRoomAdvisorBottomSheet> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  // BUGFIX (security): trước đây hardcode API key Gemini trong source →
  // bị lộ khi commit/publish. Nay chỉ đọc từ --dart-define, KHÔNG có default.
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  late final GenerativeModel _model;
  late final ChatSession _chat;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: _apiKey);
    _chat = _model.startChat(
      history: [
        Content.text(
          '''Bạn là trợ lý tư vấn phòng trọ thông minh của ứng dụng StayHub tại Việt Nam.
Nhiệm vụ của bạn:
1. Hỏi người dùng về nhu cầu tìm phòng (khu vực, ngân sách, diện tích, số người ở, tiện ích).
2. Sau khi hiểu đủ thông tin, trả lời tự nhiên bằng tiếng Việt và đưa ra gợi ý cụ thể.
3. Nếu người dùng đã đủ thông tin, tóm tắt kết quả lọc theo format JSON ở cuối:
   FILTERS: {"maxPrice": 3500000, "minArea": 20, "region": "Cầu Giấy"}
Hãy thân thiện, ngắn gọn và hữu ích. Chỉ hỏi tối đa 2-3 câu mỗi lần.''',
        ),
      ],
    );
    _messages.add({
      'role': 'ai',
      'text':
          '👋 Xin chào! Tôi là trợ lý AI của StayHub.\n\nBạn đang tìm phòng trọ ở khu vực nào? Ngân sách dự kiến bao nhiêu mỗi tháng?',
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    // BUGFIX (logic): nếu thiếu API key (chưa cấu hình --dart-define), báo lỗi
    // rõ ràng thay vì gọi API và nhận exception khó hiểu.
    if (_apiKey.isEmpty) {
      setState(() {
        _messages.add({
          'role': 'ai',
          'text':
              '⚠️ Trợ lý AI chưa được cấu hình (thiếu GEMINI_API_KEY). Vui lòng liên hệ quản trị viên.',
        });
      });
      return;
    }
    _ctrl.clear();

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await _chat.sendMessage(Content.text(text));
      final reply =
          response.text ?? 'Xin lỗi, tôi không hiểu. Bạn thử hỏi lại nhé!';

      if (reply.contains('FILTERS:')) {
        final jsonStr = RegExp(
          r'FILTERS:\s*(\{.*?\})',
          dotAll: true,
        ).firstMatch(reply)?.group(1);
        if (jsonStr != null) {
          try {
            final clean = jsonStr.replaceAll("'", '"');
            final maxPrice = RegExp(
              r'"maxPrice":\s*(\d+)',
            ).firstMatch(clean)?.group(1);
            final minArea = RegExp(
              r'"minArea":\s*(\d+)',
            ).firstMatch(clean)?.group(1);
            final region = RegExp(
              r'"region":\s*"([^"]+)"',
            ).firstMatch(clean)?.group(1);
            widget.onFiltersRecommended({
              if (maxPrice != null) 'maxPrice': double.parse(maxPrice),
              if (minArea != null) 'minArea': double.parse(minArea),
              if (region != null) 'region': region,
            });
            // Tự động đóng bottom sheet sau khi lọc
            if (mounted) Navigator.pop(context);
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'ai',
            'text': reply
                .replaceAll(RegExp(r'FILTERS:\s*\{.*?\}', dotAll: true), '')
                .trim(),
          });
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'ai',
            'text': 'Có lỗi xảy ra. Vui lòng thử lại!',
          });
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      // BUGFIX (UI): thiếu kiểm tra mounted → nếu bottom sheet đóng trong 100ms
      // chờ, _scroll đã bị dispose → truy cập gây lỗi.
      if (!mounted) return;
      if (_scroll.hasClients) {
        unawaited(
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD1D5DB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: CupertinoColors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    CupertinoIcons.sparkles,
                    color: CupertinoColors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Tư Vấn Phòng Trọ',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: CupertinoColors.white,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Powered by Gemini 2.0',
                        style: TextStyle(
                          color: CupertinoColors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: const Icon(
                    CupertinoIcons.xmark_circle_fill,
                    color: CupertinoColors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _messages.length) {
                  return _buildTypingIndicator();
                }
                final msg = _messages[i];
                final isAi = msg['role'] == 'ai';
                return Align(
                  alignment: isAi
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isAi
                          ? CupertinoColors.white
                          : const Color(0xFF2563EB),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isAi ? 4 : 18),
                        bottomRight: Radius.circular(isAi ? 18 : 4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (isAi
                                      ? const Color(0xFF000000)
                                      : const Color(0xFF2563EB))
                                  .withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      msg['text'] ?? '',
                      style: TextStyle(
                        color: isAi
                            ? AppTheme.kTextPrimary
                            : CupertinoColors.white,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Input
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              12,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              border: const Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF000000).withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoTextField(
                    controller: _ctrl,
                    placeholder: 'Nhập yêu cầu của bạn...',
                    placeholderStyle: const TextStyle(
                      color: Color(0xFFADB5BD),
                      fontSize: 14,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.kTextPrimary,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                      border: Border.fromBorderSide(
                        BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF2563EB,
                          ).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.arrow_up,
                      color: CupertinoColors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF000000).withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 5),
            _buildDot(150),
            const SizedBox(width: 5),
            _buildDot(300),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int delayMs) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (_, v, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB).withValues(alpha: v),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
