import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../core/utils/image_picker_utils.dart';
import '../../../core/utils/toast_utils.dart';
import '../../../core/components/bounce_click.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../application/thread_message_provider.dart';
import 'dart:ui' show ImageFilter;
import 'widgets/thread_room_card_bubble.dart';
import 'package:stayhub_frontend/core/components/stayhub_logo_icon.dart';
import 'dart:async' show unawaited;

class ThreadMessageScreen extends ConsumerStatefulWidget {
  final int threadId;
  final String title;
  final bool isReadOnly;
  final bool showNegotiation;
  final Map<String, dynamic>? initialRoomAttachment;

  const ThreadMessageScreen({
    super.key,
    required this.threadId,
    required this.title,
    this.isReadOnly = false,
    this.showNegotiation = false,
    this.initialRoomAttachment,
  });

  @override
  ConsumerState<ThreadMessageScreen> createState() =>
      _ThreadMessageScreenState();
}

class _ThreadMessageScreenState extends ConsumerState<ThreadMessageScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  Map<String, dynamic>? _roomAttachment;
  int _lastMessageCount = 0;
  bool _showNewMessageBadge = false;
  bool _isAtBottom = true;
  // BUGFIX (Bug 38): cờ chống gửi trùng. Trước đây bấm nút gửi nhanh nhiều
  // lần (hoặc vừa bấm nút vừa nhấn Enter) sẽ gửi trùng cùng một tin nhắn vì
  // `_sendMessage` là async và không có khoá.
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _roomAttachment = widget.initialRoomAttachment;
    if (widget.showNegotiation && !widget.isReadOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // BUGFIX (Bug 31): guard `mounted` — nếu widget bị dispose trước khi
        // callback chạy (điều hướng nhanh ra ngoài), `showCupertinoModalPopup`
        // sẽ dùng context không còn hợp lệ → crash.
        if (!mounted) return;
        _showNegotiationSheet();
      });
    }
    _scrollController.addListener(() {
      // BUGFIX (Bug 26): guard `mounted` + `hasClients` trước khi đọc
      // position và gọi setState. Listener có thể bắn trong lúc widget đang
      // bị dispose (điều hướng ra) → "setState() called after dispose".
      if (!mounted || !_scrollController.hasClients) return;
      final isAtBottom =
          _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 80;
      if (isAtBottom && _showNewMessageBadge) {
        setState(() => _showNewMessageBadge = false);
      }
      if (_isAtBottom != isAtBottom) {
        setState(() => _isAtBottom = isAtBottom);
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showNegotiationSheet() {
    // BUGFIX (Bug 27): `priceCtrl` được tạo trong builder nhưng chưa bao giờ
    // được dispose → rò rỉ TextEditingController mỗi lần mở sheet. Dispose
    // controller khi popup đóng bằng `whenComplete`.
    final priceCtrl = TextEditingController();
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            color: AppTheme.kBackgroundLight,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Trả giá phòng',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Mức giá mong muốn của bạn (VND)',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      placeholder: 'VD: 3000000',
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        color: AppTheme.kAccentColor,
                        borderRadius: BorderRadius.circular(12),
                        onPressed: () async {
                          final priceText = priceCtrl.text
                              .trim()
                              .replaceAll(',', '')
                              .replaceAll('.', '');
                          final price = double.tryParse(priceText) ?? 0;
                          if (price <= 0) return;
                          // BUGFIX (Bug 35): await kết quả gửi đề xuất giá.
                          // Trước đây dùng `unawaited` nên nếu gửi thất bại
                          // người dùng không hề biết (sheet vẫn đóng như thành
                          // công). Chỉ đóng sheet khi gửi thành công, ngược lại
                          // hiển thị toast lỗi và giữ sheet để thử lại.
                          try {
                            final ok = await ref
                                .read(
                                  threadMessageProvider(
                                    widget.threadId,
                                  ).notifier,
                                )
                                .sendMessage(
                                  'Tôi muốn đề xuất mức giá ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price)}',
                                  type: 'NEGOTIATION',
                                  meta: {
                                    'offeredPrice': price,
                                    'status': 'PENDING',
                                  },
                                );
                            if (!ctx.mounted) return;
                            if (ok) {
                              Navigator.pop(ctx);
                            } else {
                              ToastUtils.show(
                                ctx,
                                'Không gửi được đề xuất. Vui lòng thử lại.',
                                isError: true,
                              );
                            }
                          } catch (e) {
                            // BUGFIX (Bug 126): bọc try/catch — nếu sendMessage
                            // ném exception thì lỗi lan ra ngoài và sheet kẹt
                            // không phản hồi. Giờ bắt lỗi và báo toast.
                            debugPrint('Negotiation send error: $e');
                            if (!ctx.mounted) return;
                            ToastUtils.show(
                              ctx,
                              'Không gửi được đề xuất. Vui lòng thử lại.',
                              isError: true,
                            );
                          }
                        },
                        child: const Text(
                          'Gửi đề xuất',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ).whenComplete(priceCtrl.dispose),
    );
  }

  String _getInitials(String name) {
    // BUGFIX (Bug 12): trim trước khi kiểm tra rỗng. Tên chỉ chứa khoảng
    // trắng ("   ") khiến `parts` rỗng → `parts.first` ném RangeError.
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '??';
    final parts = trimmed.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '??';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      unawaited(
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        ),
      );
    }
  }

  Future<void> _sendMessage() async {
    // BUGFIX (Bug 38): chặn gửi trùng khi đang gửi (double-tap / Enter + tap).
    if (_isSending) return;
    final text = _inputController.text.trim();
    if (text.isEmpty && _roomAttachment == null) return;

    setState(() => _isSending = true);
    try {
      await _doSend(text);
    } catch (e) {
      // BUGFIX (Bug 123): bọc try/catch — trước đây chỉ có try/finally nên nếu
      // _doSend ném exception (mất mạng, parse lỗi) thì lỗi lan ra ngoài, không
      // có phản hồi cho người dùng. Giờ bắt lỗi và báo toast.
      debugPrint('ThreadMessage send error: $e');
      if (mounted) {
        ToastUtils.show(
          context,
          'Không gửi được tin nhắn. Vui lòng thử lại.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _doSend(String text) async {
    if (_roomAttachment != null) {
      final meta = {
        'roomName':
            _roomAttachment!['title'] ??
            _roomAttachment!['roomName'] ??
            'Phòng trống',
        'price': _roomAttachment!['price']?.toString() ?? '0',
        // BUGFIX (Bug 124): tránh index cứng `['images'][0]` — nếu `images`
        // không phải List (ví dụ String/Map) thì `.isNotEmpty`/`[0]` sẽ ném
        // NoSuchMethodError. Kiểm tra kiểu List trước khi truy cập phần tử.
        'image':
            (_roomAttachment!['images'] is List &&
                (_roomAttachment!['images'] as List).isNotEmpty)
            ? (_roomAttachment!['images'] as List).first
            : '',
      };
      final msgContent = text.isNotEmpty ? text : 'Tôi quan tâm đến phòng này';
      // BUGFIX (Bug 28): await kết quả gửi TRƯỚC khi clear input & xóa đính
      // kèm. Trước đây clear ngay (Bug 25 regression) nên nếu gửi lỗi người
      // dùng mất cả nội dung lẫn thẻ phòng đã chọn.
      final ok = await ref
          .read(threadMessageProvider(widget.threadId).notifier)
          .sendMessage(msgContent, type: 'ROOM_CARD', meta: meta);
      if (!mounted) return;
      if (ok) {
        _inputController.clear();
        setState(() {
          _roomAttachment = null;
        });
        _scheduleScrollToBottom();
      } else {
        // BUGFIX (Bug 29): báo lỗi thay vì thất bại âm thầm.
        ToastUtils.show(
          context,
          'Không gửi được tin nhắn. Vui lòng thử lại.',
          isError: true,
        );
      }
      return;
    }

    // BUGFIX (Bug 28/29): await kết quả; chỉ clear khi gửi thành công và báo
    // lỗi khi thất bại.
    final ok = await ref
        .read(threadMessageProvider(widget.threadId).notifier)
        .sendMessage(text);
    if (!mounted) return;
    if (ok) {
      _inputController.clear();
      _scheduleScrollToBottom();
    } else {
      ToastUtils.show(
        context,
        'Không gửi được tin nhắn. Vui lòng thử lại.',
        isError: true,
      );
    }
  }

  /// BUGFIX (Bug 30): trì hoãn cuộn xuống nhưng kiểm tra `mounted` trước khi
  /// chạm vào ScrollController — tránh dùng controller sau khi dispose.
  void _scheduleScrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _scrollToBottom();
    });
  }

  Widget _buildAttachmentPopup() {
    final title =
        _roomAttachment!['title'] ?? _roomAttachment!['roomName'] ?? 'Phòng';
    final price = _roomAttachment!['price']?.toString() ?? '0';
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final formattedPrice = fmt.format(double.tryParse(price) ?? 0);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.kSurface1Light,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kBrand.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border.all(color: AppTheme.kAccentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.kAccentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const StayHubLogoIcon(color: AppTheme.kAccentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đính kèm thông tin phòng:',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.kTextSecondary,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  formattedPrice,
                  style: const TextStyle(
                    color: AppTheme.kAccentColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => setState(() => _roomAttachment = null),
            child: const Icon(
              CupertinoIcons.clear_thick_circled,
              color: AppTheme.kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didUpdateWidget(covariant ThreadMessageScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // BUGFIX (Bug 15): reset bộ đếm khi đổi thread để logic "tin nhắn mới"
    // không so sánh nhầm với số lượng của hội thoại trước đó.
    if (oldWidget.threadId != widget.threadId) {
      _lastMessageCount = 0;
      _showNewMessageBadge = false;
      _isAtBottom = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(threadMessageProvider(widget.threadId));
    final messages = chatState.messages;

    // Only scroll to bottom when NEW messages arrive
    if (messages.length > _lastMessageCount) {
      final hasNewMessages = _lastMessageCount > 0; // not first load
      // BUGFIX (Bug 23): không mutate `_lastMessageCount` trực tiếp trong
      // build (side-effect trong build gây logic badge bị stale và vi phạm
      // nguyên tắc build thuần khiết). Chuyển việc cập nhật vào post-frame
      // callback, nơi setState được phép gọi.
      final newCount = messages.length;
      final shouldShowBadge = !_isAtBottom && hasNewMessages;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _lastMessageCount = newCount;
        if (shouldShowBadge) {
          setState(() => _showNewMessageBadge = true);
        } else {
          _scrollToBottom();
        }
      });
    }

    return LiquidGlassScaffold(
      title: null, // Custom header
      backgroundColors: AppTheme.kBackgroundLight,
      useScrollView: false,
      child: Column(
        children: [
          // Custom Premium Header
          ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.only(
                  left: 8,
                  right: 20,
                  top: 8,
                  bottom: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.kSurface1Light.withValues(alpha: 0.7),
                  border: const Border(
                    bottom: BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                ),
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        CupertinoIcons.back,
                        color: AppTheme.kTextPrimary,
                        size: 28,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.kBrand.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _getInitials(widget.title),
                        style: const TextStyle(
                          color: AppTheme.kBrand,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: AppTheme.kTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Nhắn tin trực tiếp',
                            style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Messages
          Expanded(
            child: chatState.isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.kBrand.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.chat_bubble_2_fill,
                            size: 48,
                            color: AppTheme.kBrand,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Chưa có tin nhắn nào.\nHãy bắt đầu cuộc trò chuyện!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (ctx, i) =>
                            _buildMessageBubble(messages[i]),
                      ),
                      // New Messages Badge
                      // BUGFIX (Bug 24): trước đây badge bị bọc trong
                      // `if (_showNewMessageBadge)` nên AnimatedOpacity luôn
                      // có opacity = 1.0 → hiệu ứng fade không bao giờ chạy.
                      // Bỏ `if` ngoài, để AnimatedOpacity tự xử lý fade và
                      // dùng IgnorePointer để badge ẩn không chặn tap.
                      Positioned(
                        bottom: 12,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          ignoring: !_showNewMessageBadge,
                          child: Center(
                            child: GestureDetector(
                              onTap: () {
                                _scrollToBottom();
                                setState(() => _showNewMessageBadge = false);
                              },
                              child: AnimatedOpacity(
                                opacity: _showNewMessageBadge ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.kBrand,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.kBrand.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
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
                                        'Tin nhắn mới',
                                        style: TextStyle(
                                          color: CupertinoColors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          // Premium Input Bar
          if (widget.isReadOnly)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.kSurface1Light,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Bạn không thể gửi tin nhắn vì hợp đồng đã kết thúc.',
                style: TextStyle(
                  color: AppTheme.kTextSecondary,
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_roomAttachment != null) _buildAttachmentPopup(),
                ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.only(
                        left: 12,
                        right: 16,
                        top: 10,
                        bottom: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.kSurface1Light.withValues(alpha: 0.85),
                        border: const Border(
                          top: BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          children: [
                            CupertinoButton(
                              padding: const EdgeInsets.all(8),
                              child: const Icon(
                                CupertinoIcons.photo_on_rectangle,
                                color: AppTheme.kBrand,
                                size: 26,
                              ),
                              onPressed: () {
                                unawaited(
                                  ImagePickerUtils.showPicker(
                                    context: context,
                                    limit: 1,
                                    onPicked: (files) {
                                      if (files.isNotEmpty) {
                                        unawaited(HapticFeedback.lightImpact());
                                        ToastUtils.show(
                                          context,
                                          'Ảnh đã chọn. Tính năng gửi ảnh đang phát triển.',
                                        );
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                            Expanded(
                              child: CupertinoTextField(
                                controller: _inputController,
                                placeholder: 'Nhắn tin...',
                                placeholderStyle: const TextStyle(
                                  color: Color(0xFF9CA3AF),
                                  fontWeight: FontWeight.w500,
                                ),
                                style: const TextStyle(
                                  color: AppTheme.kTextPrimary,
                                  fontSize: 15,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: const Color(0xFFE5E7EB),
                                  ),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            BounceClick(
                              // BUGFIX (Bug 38): vô hiệu hoá nút khi đang gửi
                              // để tránh gửi trùng.
                              onPressed: _isSending ? null : _sendMessage,
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: PremiumGradients.skyBrand,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.kBrandDeep.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: _isSending
                                    ? const Padding(
                                        padding: EdgeInsets.all(12),
                                        child: CupertinoActivityIndicator(
                                          color: AppTheme.kSurface1Light,
                                        ),
                                      )
                                    : const Icon(
                                        CupertinoIcons.arrow_up,
                                        color: AppTheme.kSurface1Light,
                                        size: 20,
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ThreadMessage msg) {
    // BUGFIX (Bug 39): chuẩn hoá về giờ local trước khi format. `createdAt`
    // có thể là UTC (backend trả ISO không kèm offset) → hiển thị sai giờ.
    final localTime = msg.createdAt.toLocal();
    final timeStr =
        '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: msg.isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isMe) ...[
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: AppTheme.kBrand.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.person_fill,
                size: 16,
                color: AppTheme.kBrand,
              ),
            ),
          ],
          if (msg.messageType == 'ROOM_CARD')
            ThreadRoomCardBubble(message: msg)
          else if (msg.messageType == 'NEGOTIATION')
            // BUGFIX (Bug 36): tin nhắn NEGOTIATION trước đây rơi vào nhánh
            // text thường nên chỉ hiện chuỗi "Tôi muốn đề xuất mức giá ..."
            // mà không có thẻ trực quan (giá, trạng thái). Render riêng.
            _buildNegotiationBubble(msg)
          else
            Flexible(
              child: Column(
                crossAxisAlignment: msg.isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: msg.isMe ? PremiumGradients.skyBrand : null,
                      color: msg.isMe ? null : AppTheme.kSurface1Light,
                      boxShadow: msg.isMe
                          ? [
                              BoxShadow(
                                color: AppTheme.kBrandDeep.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: AppTheme.kTextPrimary.withValues(
                                  alpha: 0.04,
                                ),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(msg.isMe ? 20 : 6),
                        bottomRight: Radius.circular(msg.isMe ? 6 : 20),
                      ),
                      border: msg.isMe
                          ? null
                          : Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Text(
                      msg.content,
                      style: TextStyle(
                        color: msg.isMe
                            ? AppTheme.kSurface1Light
                            : const Color(0xFF1F2937),
                        fontSize: 15,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: EdgeInsets.only(
                      left: msg.isMe ? 0 : 4,
                      right: msg.isMe ? 4 : 0,
                    ),
                    child: Text(
                      timeStr,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
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

  /// BUGFIX (Bug 36): thẻ hiển thị tin nhắn trả giá (NEGOTIATION) với giá đề
  /// xuất và trạng thái, thay vì chỉ hiện chuỗi text thô.
  Widget _buildNegotiationBubble(ThreadMessage msg) {
    final meta = msg.metadata ?? const <String, dynamic>{};
    final rawPrice = meta['offeredPrice'];
    final price = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '') ?? 0;
    final status = (meta['status'] ?? 'PENDING').toString().toUpperCase();
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    late final String statusLabel;
    late final Color statusColor;
    switch (status) {
      case 'ACCEPTED':
        statusLabel = 'Đã chấp nhận';
        statusColor = const Color(0xFF16A34A);
        break;
      case 'REJECTED':
        statusLabel = 'Đã từ chối';
        statusColor = const Color(0xFFDC2626);
        break;
      default:
        statusLabel = 'Đang chờ';
        statusColor = const Color(0xFFF59E0B);
    }

    return Flexible(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.kSurface1Light,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.kAccentColor.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.kBrand.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.tag_fill,
                  size: 14,
                  color: AppTheme.kAccentColor,
                ),
                SizedBox(width: 6),
                Text(
                  'Đề xuất giá',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.kAccentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              fmt.format(price),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.kTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
