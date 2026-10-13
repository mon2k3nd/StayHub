import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/bounce_click.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/utils/toast_utils.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/direct_message_provider.dart';
import 'package:intl/intl.dart';
import 'widgets/negotiation_chat_bubble.dart';
import 'widgets/room_card_chat_bubble.dart';
import 'dart:async' show unawaited;

class DirectMessageScreen extends ConsumerStatefulWidget {
  final int roomId;
  final String roomName;
  final String otherPersonName;
  final bool showNegotiation;

  const DirectMessageScreen({
    super.key,
    required this.roomId,
    required this.roomName,
    required this.otherPersonName,
    this.showNegotiation = false,
  });

  @override
  ConsumerState<DirectMessageScreen> createState() =>
      _DirectMessageScreenState();
}

class _DirectMessageScreenState extends ConsumerState<DirectMessageScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  // BUGFIX (Bug 54): theo dõi số lượng tin nhắn để chỉ auto-scroll khi có tin mới,
  // tránh cuộn đè lên thao tác người dùng ở mỗi lần rebuild.
  int _lastMessageCount = 0;
  // BUGFIX (Bug 82): cờ chống gửi trùng khi bấm nhanh nhiều lần.
  bool _isSending = false;
  // UI: theo dõi nội dung input để bật/tắt trạng thái nút gửi (micro-animation).
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(_onInputChanged);
    if (widget.showNegotiation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showNegotiationSheet();
      });
    }
  }

  void _onInputChanged() {
    final hasText = _inputController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    _inputController.removeListener(_onInputChanged);
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showNegotiationSheet() {
    // BUGFIX (Bug 52): dispose priceCtrl khi sheet đóng để tránh rò rỉ.
    final priceCtrl = TextEditingController();
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: AppTheme.kSurface1Light,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: PremiumGradients.skyBrand,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.kBrand.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            CupertinoIcons.money_dollar_circle_fill,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'Trả giá phòng',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 19,
                            color: AppTheme.kTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Mức giá mong muốn của bạn (VND)',
                      style: TextStyle(
                        color: AppTheme.kTextMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.kSurfaceBlue,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD3E4F4)),
                      ),
                      child: CupertinoTextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        placeholder: 'VD: 3000000',
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.kTextPrimary,
                        ),
                        decoration: const BoxDecoration(),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        color: AppTheme.kAccentColor,
                        borderRadius: BorderRadius.circular(50),
                        // BUGFIX (Bug 52): await kết quả gửi, chỉ đóng sheet khi
                        // thành công và báo lỗi thay vì thất bại âm thầm.
                        onPressed: () async {
                          final price =
                              double.tryParse(priceCtrl.text.trim()) ?? 0;
                          if (price <= 0) return;
                          final ok = await ref
                              .read(
                                directMessageProvider(widget.roomId).notifier,
                              )
                              .sendMessage(
                                'Tôi muốn đề xuất mức giá ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(price)}',
                                messageType: 'NEGOTIATION',
                                metadata: {
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
                        },
                        child: const Text(
                          'Gửi đề xuất',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      unawaited(
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        ),
      );
    }
  }

  Future<void> _sendMessage() async {
    // BUGFIX (Bug 82): chặn gửi trùng khi đang gửi.
    if (_isSending) return;
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      // BUGFIX (Bug 82): await kết quả gửi TRƯỚC khi clear input; chỉ clear khi
      // thành công và báo toast lỗi khi thất bại (trước đây clear ngay nên mất
      // nội dung khi gửi lỗi, và thất bại âm thầm).
      final ok = await ref
          .read(directMessageProvider(widget.roomId).notifier)
          .sendMessage(text);
      if (!mounted) return;
      if (ok) {
        _inputController.clear();
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _scrollToBottom();
        });
      } else {
        ToastUtils.show(
          context,
          'Không gửi được tin nhắn. Vui lòng thử lại.',
          isError: true,
        );
      }
    } catch (e) {
      // BUGFIX (Bug 117): bọc try/catch — trước đây chỉ có try/finally nên nếu
      // sendMessage ném exception (lỗi mạng/parse) thì lỗi lan ra ngoài thành
      // unhandled exception. Giữ nguyên nội dung đã gõ để người dùng thử lại.
      debugPrint('DirectMessage send error: $e');
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

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(directMessageProvider(widget.roomId));
    final messages = chatState.messages;
    final authUser = ref.watch(authProvider).value;
    final isKycApproved = authUser?.kycStatus == 'APPROVED';

    bool showWarning = false;
    if (!isKycApproved) {
      for (final m in messages) {
        final lower = m.content.toLowerCase();
        if (lower.contains('cọc') || lower.contains('chuyển khoản')) {
          showWarning = true;
          break;
        }
      }
    }

    // BUGFIX (Bug 54): chỉ auto-scroll khi số tin nhắn thực sự tăng, không
    // cuộn lại ở mỗi rebuild (trước đây đè lên thao tác cuộn của người dùng).
    // BUGFIX (Bug 83): không mutate `_lastMessageCount` trực tiếp trong build
    // (side-effect trong build). Chuyển việc cập nhật vào post-frame callback.
    if (messages.length != _lastMessageCount) {
      final newCount = messages.length;
      final shouldScroll = messages.isNotEmpty;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _lastMessageCount = newCount;
        if (shouldScroll) _scrollToBottom();
      });
    }

    return LiquidGlassScaffold(
      title: widget.otherPersonName,
      backgroundColors: AppTheme.kBackgroundLight,
      useScrollView: false,
      child: Column(
        children: [
          _buildHeader(),
          if (showWarning) _buildWarningBanner(),

          // Messages
          Expanded(
            child: chatState.isLoading
                ? _buildLoadingShimmer()
                : messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    itemCount: messages.length,
                    itemBuilder: (ctx, i) => _buildMessageBubble(messages[i]),
                  ),
          ),

          _buildInputBar(),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kBrand.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: PremiumGradients.skyBrand,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.kBrand.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(widget.otherPersonName),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
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
                  widget.otherPersonName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppTheme.kTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppTheme.kSuccess,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Nhắn tin trực tiếp',
                      style: TextStyle(
                        color: AppTheme.kTextMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.kSurfaceBlue,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: const Color(0xFFD3E4F4)),
            ),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.house_fill,
                  size: 12,
                  color: AppTheme.kBrandDeep,
                ),
                const SizedBox(width: 5),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 90),
                  child: Text(
                    widget.roomName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.kBrandDeep,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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

  // ── AI Warning Banner ───────────────────────────────────────────────────────
  Widget _buildWarningBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFEF2F2),
            const Color(0xFFFFF1F2).withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFECACA)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kError.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.kError.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              color: AppTheme.kError,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cảnh báo từ StayHub AI',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF991B1B),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Tài khoản của bạn chưa xác thực CCCD. Hãy cảnh giác với các yêu cầu "chuyển khoản" hoặc "đặt cọc" để tránh rủi ro lừa đảo.',
                  style: TextStyle(
                    color: Color(0xFF991B1B),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => context.push('/ekyc-verification'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.kError,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Xác thực ngay',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          CupertinoIcons.arrow_right,
                          color: Colors.white,
                          size: 12,
                        ),
                      ],
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

  // ── Empty state ─────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.kBrand.withValues(alpha: 0.18),
                  AppTheme.kBrand.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.chat_bubble_2_fill,
              size: 42,
              color: AppTheme.kBrand,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Chưa có tin nhắn nào',
            style: TextStyle(
              color: AppTheme.kTextPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Hãy gửi lời chào để bắt đầu cuộc trò chuyện!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.kTextMuted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Input bar ───────────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: 10 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        border: const Border(top: BorderSide(color: Color(0xFFEAF2FB))),
        boxShadow: [
          BoxShadow(
            color: AppTheme.kBrand.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Negotiation trigger
            BounceClick(
              onPressed: _showNegotiationSheet,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.kSurfaceBlue,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD3E4F4)),
                ),
                child: const Icon(
                  CupertinoIcons.money_dollar_circle,
                  color: AppTheme.kBrandDeep,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F6FA),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE3EDF7)),
                ),
                child: CupertinoTextField(
                  controller: _inputController,
                  placeholder: 'Nhắn tin...',
                  placeholderStyle: const TextStyle(
                    color: AppTheme.kTextMuted,
                    fontSize: 15,
                  ),
                  style: const TextStyle(
                    color: AppTheme.kTextPrimary,
                    fontSize: 15,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  maxLines: 4,
                  minLines: 1,
                  decoration: const BoxDecoration(),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Send button — animated enable/disable
            BounceClick(
              onPressed: _hasText && !_isSending ? _sendMessage : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: _hasText
                      ? PremiumGradients.skyBrand
                      : const LinearGradient(
                          colors: [Color(0xFFE2E8F0), Color(0xFFE2E8F0)],
                        ),
                  shape: BoxShape.circle,
                  boxShadow: _hasText
                      ? [
                          BoxShadow(
                            color: AppTheme.kBrand.withValues(alpha: 0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: _isSending
                    ? const Padding(
                        padding: EdgeInsets.all(13),
                        child: CupertinoActivityIndicator(
                          color: Colors.white,
                          radius: 9,
                        ),
                      )
                    : Icon(
                        CupertinoIcons.arrow_up,
                        color: _hasText
                            ? Colors.white
                            : const Color(0xFF94A3B8),
                        size: 20,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(DirectMessage msg) {
    // BUGFIX (Bug 53): chuẩn hoá về giờ local trước khi format.
    final localTime = msg.createdAt.toLocal();
    final timeStr =
        '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';

    if (msg.messageType == 'NEGOTIATION') {
      return NegotiationChatBubble(message: msg, roomId: widget.roomId);
    }

    if (msg.messageType == 'ROOM_CARD') {
      return RoomCardChatBubble(message: msg);
    }

    if (msg.messageType == 'BILL_CARD') {
      // BUGFIX (Bug 118): metadata có thể chứa amount dạng chuỗi (backend
      // serialize BigDecimal thành String) → `(billAmount as num)` ném
      // TypeError. Ép kiểu an toàn sang num.
      final rawAmount = msg.metadata?['amount'];
      final billAmount = rawAmount is num
          ? rawAmount
          : num.tryParse(rawAmount?.toString() ?? '') ?? 0;
      final billMonth = msg.metadata?['month'] ?? 1;
      final billYear = msg.metadata?['year'] ?? 2024;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.95),
                Colors.white.withValues(alpha: 0.75),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.kBrand.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: PremiumGradients.skyBrand,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.kBrand.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  CupertinoIcons.doc_text_fill,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Hóa Đơn Tháng $billMonth/$billYear',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppTheme.kTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                msg.content,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.kTextSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.kSurfaceBlue,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFD3E4F4)),
                ),
                child: Text(
                  '${billAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r"\\B(?=(\\d{3})+(?!\\d))"), (match) => ",")} VNĐ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: AppTheme.kBrandDeep,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: CupertinoButton(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  color: AppTheme.kAccentColor,
                  borderRadius: BorderRadius.circular(50),
                  onPressed: () {
                    // Navigate to Bill detail
                    unawaited(context.push('/bills'));
                  },
                  child: const Text(
                    'Thanh Toán Ngay',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                timeStr,
                style: const TextStyle(
                  color: AppTheme.kTextMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isMe = msg.isMe;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.kBrand.withValues(alpha: 0.2),
                    AppTheme.kBrand.withValues(alpha: 0.08),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.kBrand.withValues(alpha: 0.25),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                _initials(widget.otherPersonName),
                style: const TextStyle(
                  color: AppTheme.kBrandDeep,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.68,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    gradient: isMe ? PremiumGradients.skyBrand : null,
                    color: isMe ? null : Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 6),
                      bottomRight: Radius.circular(isMe ? 6 : 20),
                    ),
                    border: isMe
                        ? null
                        : Border.all(color: const Color(0xFFEAF2FB)),
                    boxShadow: [
                      BoxShadow(
                        color: isMe
                            ? AppTheme.kBrand.withValues(alpha: 0.28)
                            : Colors.black.withValues(alpha: 0.04),
                        blurRadius: isMe ? 14 : 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : AppTheme.kTextPrimary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    timeStr,
                    style: const TextStyle(
                      color: AppTheme.kTextMuted,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                gradient: PremiumGradients.skyBrand,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.kBrand.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.person_fill,
                size: 15,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: 6,
      itemBuilder: (ctx, i) {
        final isMe = i % 2 == 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.5,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}
