import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../application/direct_message_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NegotiationChatBubble extends ConsumerWidget {
  final DirectMessage message;
  final int roomId;

  const NegotiationChatBubble({
    super.key,
    required this.message,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = message.metadata ?? {};
    // BUGFIX (Bug 110): trước đây `double.tryParse(...) ?? 0` khiến giá không
    // hợp lệ/thiếu hiển thị nhầm "0đ" như một đề xuất giá thật. Phân biệt rõ
    // trường hợp thiếu/không hợp lệ để hiển thị "—" thay vì 0đ gây hiểu nhầm.
    final rawPrice = meta['offeredPrice'];
    final parsedPrice = rawPrice != null
        ? double.tryParse(rawPrice.toString())
        : null;
    final hasValidPrice = parsedPrice != null && parsedPrice > 0;
    final offeredPrice = parsedPrice ?? 0.0;
    final status = meta['status']?.toString() ?? 'PENDING';
    final isMe = message.isMe;

    final fmt = hasValidPrice
        ? NumberFormat.currency(
            locale: 'vi_VN',
            symbol: 'đ',
          ).format(offeredPrice)
        : '—';

    // BUGFIX (Bug 45): bong bóng cố định 75% bề rộng màn hình → quá rộng trên
    // tablet/desktop. Giới hạn thêm maxWidth để giữ tỉ lệ đọc hợp lý.
    final bubbleWidth = (MediaQuery.of(context).size.width * 0.75).clamp(
      220.0,
      340.0,
    );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        width: bubbleWidth,
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  CupertinoIcons.money_dollar_circle_fill,
                  color: AppTheme.kAccentColor,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Đề xuất thương lượng',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mức giá:',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                  Text(
                    fmt,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.kAccentColor,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            if (message.content.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                message.content,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF334155),
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (status == 'PENDING') ...[
              if (isMe)
                const Center(
                  child: Text(
                    'Đang chờ phản hồi...',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        // BUGFIX (Bug 46): await kết quả gửi và báo lỗi thay vì
                        // thất bại âm thầm (đồng bộ với Bug 29/35).
                        onPressed: () async {
                          // BUGFIX (Bug 127): bọc try/catch — nếu sendMessage
                          // ném exception thì lỗi lan ra ngoài, không có phản
                          // hồi cho người dùng. Giờ bắt lỗi và báo toast.
                          try {
                            final ok = await ref
                                .read(directMessageProvider(roomId).notifier)
                                .sendMessage(
                                  'Tôi từ chối đề xuất giá $fmt.',
                                  messageType: 'NEGOTIATION_RESPONSE',
                                  metadata: {
                                    'originalMessageId': message.senderId,
                                    'status': 'REJECTED',
                                  },
                                );
                            if (!ok && context.mounted) {
                              ToastUtils.show(
                                context,
                                'Không gửi được phản hồi. Vui lòng thử lại.',
                                isError: true,
                              );
                            }
                          } catch (e) {
                            debugPrint('Negotiation reject error: $e');
                            if (context.mounted) {
                              ToastUtils.show(
                                context,
                                'Không gửi được phản hồi. Vui lòng thử lại.',
                                isError: true,
                              );
                            }
                          }
                        },
                        child: const Text(
                          'Từ chối',
                          style: TextStyle(
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        color: AppTheme.kAccentColor,
                        borderRadius: BorderRadius.circular(8),
                        // BUGFIX (Bug 46): await kết quả gửi và báo lỗi thay vì
                        // thất bại âm thầm (đồng bộ với Bug 29/35).
                        onPressed: () async {
                          // BUGFIX (Bug 127): bọc try/catch — nếu sendMessage
                          // ném exception thì lỗi lan ra ngoài, không có phản
                          // hồi cho người dùng. Giờ bắt lỗi và báo toast.
                          try {
                            final ok = await ref
                                .read(directMessageProvider(roomId).notifier)
                                .sendMessage(
                                  'Tôi chấp nhận đề xuất giá $fmt của bạn. Vui lòng tiến hành đặt lịch thuê.',
                                  messageType: 'NEGOTIATION_RESPONSE',
                                  metadata: {
                                    'originalMessageId': message.senderId,
                                    'status': 'ACCEPTED',
                                  },
                                );
                            if (!ok && context.mounted) {
                              ToastUtils.show(
                                context,
                                'Không gửi được phản hồi. Vui lòng thử lại.',
                                isError: true,
                              );
                            }
                          } catch (e) {
                            debugPrint('Negotiation accept error: $e');
                            if (context.mounted) {
                              ToastUtils.show(
                                context,
                                'Không gửi được phản hồi. Vui lòng thử lại.',
                                isError: true,
                              );
                            }
                          }
                        },
                        child: const Text(
                          'Chấp nhận',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ] else ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: status == 'ACCEPTED'
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status == 'ACCEPTED' ? 'ĐÃ CHẤP NHẬN' : 'ĐÃ TỪ CHỐI',
                    style: TextStyle(
                      color: status == 'ACCEPTED'
                          ? const Color(0xFF166534)
                          : const Color(0xFF991B1B),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
