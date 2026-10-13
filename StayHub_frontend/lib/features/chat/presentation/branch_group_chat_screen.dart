import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/utils/toast_utils.dart';
import '../application/branch_group_chat_notifier.dart';
import 'widgets/voice_message_player.dart';
import '../../../core/components/responsive_file_image.dart';
import 'dart:ui' show ImageFilter;
import '../../../core/theme/app_theme.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import 'dart:async' show unawaited;

class BranchGroupChatScreen extends ConsumerStatefulWidget {
  final String branchId;
  final String branchName;
  final String coverUrl;
  final bool isReadOnly;

  const BranchGroupChatScreen({
    super.key,
    required this.branchId,
    required this.branchName,
    required this.coverUrl,
    this.isReadOnly = false,
  });

  @override
  ConsumerState<BranchGroupChatScreen> createState() =>
      _BranchGroupChatScreenState();
}

class _BranchGroupChatScreenState extends ConsumerState<BranchGroupChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  // BUGFIX (Bug 57): theo dõi số lượng tin nhắn để chỉ tự cuộn khi có tin MỚI,
  // thay vì cuộn ở mọi lần rebuild (đang gõ, provider tick...) → cướp thao tác
  // cuộn của người dùng.
  int _lastMessageCount = 0;
  // BUGFIX (Bug 86): cờ chống gửi trùng khi bấm nhanh nhiều lần.
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // No initial dummy messages, use provider
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      unawaited(HapticFeedback.mediumImpact());
      // BUGFIX (Bug 59): await kết quả gửi và báo lỗi khi thất bại. Trước đây
      // dùng `unawaited` nên nếu upload ảnh lỗi người dùng không hề biết.
      final ok = await ref
          .read(branchGroupChatStateProvider(widget.branchId).notifier)
          .sendMessage('', filePath: picked.path, messageType: 'IMAGE');
      if (!mounted) return;
      if (ok) {
        _scrollToBottom();
      } else {
        ToastUtils.show(
          context,
          'Không gửi được ảnh. Vui lòng thử lại.',
          isError: true,
        );
      }
    }
  }

  Future<void> _toggleRecording() async {
    // BUGFIX (Bug 102): bọc toàn bộ trong try/catch — các lời gọi recorder
    // (stop/start/hasPermission) và getApplicationDocumentsDirectory có thể
    // ném lỗi (quyền bị từ chối, thiết bị không hỗ trợ) → trước đây lỗi thoát
    // ra ngoài, UI kẹt ở trạng thái "đang ghi" và không có phản hồi.
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        if (!mounted) return;
        setState(() => _isRecording = false);
        if (path != null) {
          unawaited(HapticFeedback.heavyImpact());
          // BUGFIX (Bug 59): await kết quả gửi và báo lỗi khi thất bại.
          final ok = await ref
              .read(branchGroupChatStateProvider(widget.branchId).notifier)
              .sendMessage('', filePath: path, messageType: 'VOICE');
          if (!mounted) return;
          if (ok) {
            _scrollToBottom();
          } else {
            ToastUtils.show(
              context,
              'Không gửi được tin nhắn thoại. Vui lòng thử lại.',
              isError: true,
            );
          }
        }
      } else {
        if (await _audioRecorder.hasPermission()) {
          final dir = await getApplicationDocumentsDirectory();
          final path =
              '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
          await _audioRecorder.start(const RecordConfig(), path: path);
          if (!mounted) return;
          setState(() => _isRecording = true);
          unawaited(HapticFeedback.lightImpact());
        } else {
          if (!mounted) return;
          ToastUtils.show(
            context,
            'Cần quyền truy cập micro để ghi âm.',
            isError: true,
          );
        }
      }
    } catch (e) {
      debugPrint('Toggle recording error: $e');
      if (!mounted) return;
      if (_isRecording) setState(() => _isRecording = false);
      ToastUtils.show(
        context,
        'Không thể ghi âm. Vui lòng thử lại.',
        isError: true,
      );
    }
  }

  Future<void> _sendMessage() async {
    // BUGFIX (Bug 86): chặn gửi trùng khi đang gửi (double-tap / Enter + tap).
    if (_isSending) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    unawaited(HapticFeedback.lightImpact());
    setState(() => _isSending = true);
    try {
      // BUGFIX (Bug 58): await kết quả gửi TRƯỚC khi clear input. Trước đây
      // clear ngay nên nếu gửi lỗi người dùng mất nội dung vừa nhập mà không
      // biết vì sao. Chỉ clear khi thành công, ngược lại báo toast lỗi.
      final ok = await ref
          .read(branchGroupChatStateProvider(widget.branchId).notifier)
          .sendMessage(text);
      if (!mounted) return;
      if (ok) {
        _messageController.clear();
        _scrollToBottom();
      } else {
        ToastUtils.show(
          context,
          'Không gửi được tin nhắn. Vui lòng thử lại.',
          isError: true,
        );
      }
    } catch (e) {
      // BUGFIX (Bug 120): bọc try/catch — trước đây chỉ có try/finally nên nếu
      // sendMessage ném exception (mất mạng, parse lỗi) thì lỗi lan ra ngoài,
      // không có phản hồi cho người dùng. Giờ bắt lỗi và báo toast.
      debugPrint('BranchGroupChat send error: $e');
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

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        unawaited(
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    unawaited(_audioRecorder.dispose());
    super.dispose();
  }

  Widget _buildSystemMessage(Map<String, dynamic> msg) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey5.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          // BUGFIX (Bug 121): tránh cast cứng `as String` — payload có thể null
          // hoặc không phải String, gây crash khi render tin nhắn hệ thống.
          msg['text']?.toString() ?? '',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: CupertinoColors.systemGrey,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildUserMessage(Map<String, dynamic> msg, bool isMe) {
    final senderRole = msg['senderRole'] as String?;
    final roomNumber = msg['roomNumber'] as String?;
    final senderName = msg['senderName'] as String?;
    final msgType = msg['messageType'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    senderName ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.systemGrey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: senderRole == 'OWNER'
                          ? CupertinoColors.systemBlue.withValues(alpha: 0.1)
                          : CupertinoColors.systemOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: senderRole == 'OWNER'
                            ? CupertinoColors.systemBlue.withValues(alpha: 0.3)
                            : CupertinoColors.systemOrange.withValues(
                                alpha: 0.3,
                              ),
                      ),
                    ),
                    child: Text(
                      senderRole == 'OWNER'
                          ? 'Chủ nhà'
                          : (roomNumber ?? 'Khách thuê'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: senderRole == 'OWNER'
                            ? CupertinoColors.systemBlue
                            : CupertinoColors.systemOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            mainAxisAlignment: isMe
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe)
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: senderRole == 'OWNER'
                        ? CupertinoColors.systemBlue
                        : CupertinoColors.systemOrange,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    senderRole == 'OWNER' ? 'C' : 'K',
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: isMe
                        ? const LinearGradient(
                            colors: [Color(0xFFFF8C00), Color(0xFFE65100)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isMe ? null : CupertinoColors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 20),
                    ),
                    boxShadow: [
                      if (isMe)
                        BoxShadow(
                          color: const Color(0xFFFF8C00).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      else
                        BoxShadow(
                          color: CupertinoColors.systemGrey.withValues(
                            alpha: 0.1,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: msgType == 'IMAGE'
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          // BUGFIX (Bug 122): tránh cast cứng `as String` cho
                          // text/url ảnh — dùng chuỗi an toàn để không crash.
                          child:
                              (msg['text']?.toString() ?? '').startsWith('http')
                              ? Image.network(
                                  msg['text']?.toString() ?? '',
                                  width: 200,
                                  fit: BoxFit.cover,
                                )
                              : ResponsiveFileImage(
                                  File(msg['text']?.toString() ?? ''),
                                  width: 200,
                                  fit: BoxFit.cover,
                                ),
                        )
                      : msgType == 'VOICE'
                      ? VoiceMessagePlayer(
                          url: msg['text']?.toString() ?? '',
                          isMe: isMe,
                        )
                      : Text(
                          msg['text']?.toString() ?? '',
                          style: TextStyle(
                            color: isMe
                                ? CupertinoColors.white
                                : CupertinoColors.black,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
              if (isMe) const SizedBox(width: 32),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(branchGroupChatStateProvider(widget.branchId));

    if (messages.length != _lastMessageCount) {
      final newCount = messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _lastMessageCount = newCount;
        if (!_scrollController.hasClients) return;
        unawaited(
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          ),
        );
      });
    }

    return LiquidGlassScaffold(
      title: null,
      backgroundColors: AppTheme.kBackgroundLight,
      useScrollView: false,
      child: Column(
        children: [
          // Premium Header
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
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: NetworkImage(widget.coverUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.branchName,
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
                            'Nhóm dãy trọ',
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

          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isSystem = msg['isSystem'] == true;

                if (isSystem) {
                  return _buildSystemMessage(msg);
                } else {
                  final isMe = msg['isMe'] == true;
                  return _buildUserMessage(msg, isMe);
                }
              },
            ),
          ),

          // Chat Input
          if (widget.isReadOnly)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppTheme.kSurface1Light,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Bạn không thể gửi tin nhắn vào nhóm này vì hợp đồng đã kết thúc.',
                style: TextStyle(
                  color: AppTheme.kTextSecondary,
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
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
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: const Icon(
                              CupertinoIcons.camera_fill,
                              color: AppTheme.kBrand,
                              size: 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: GestureDetector(
                            onTap: _toggleRecording,
                            child: Icon(
                              _isRecording
                                  ? CupertinoIcons.stop_circle_fill
                                  : CupertinoIcons.mic_fill,
                              color: _isRecording
                                  ? CupertinoColors.destructiveRed
                                  : AppTheme.kBrand,
                              size: _isRecording ? 32 : 28,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CupertinoTextField(
                            controller: _messageController,
                            placeholder: 'Nhập tin nhắn...',
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
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _isSending ? null : _sendMessage,
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
                                    CupertinoIcons.paperplane_fill,
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
    );
  }
}
