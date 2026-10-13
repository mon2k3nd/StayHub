import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../application/thread_message_provider.dart';

class ThreadRoomCardBubble extends StatelessWidget {
  final ThreadMessage message;

  const ThreadRoomCardBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final metadata = message.metadata ?? {};
    final roomName = metadata['roomName'] ?? 'Phòng trống';
    final price = double.tryParse(metadata['price']?.toString() ?? '0') ?? 0;
    final image = metadata['image']?.toString() ?? '';
    final fmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    // BUGFIX (Bug 41): chuẩn hoá về giờ local trước khi format (đồng bộ với
    // Bug 39 ở bubble text). `createdAt` có thể là UTC → hiển thị sai giờ.
    final localTime = message.createdAt.toLocal();
    final timeStr =
        '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';

    // BUGFIX (Bug 33): trước đây thẻ phòng cố định width 250 → tràn màn hình
    // trên thiết bị nhỏ (< 300px khả dụng). Giới hạn theo bề rộng màn hình.
    final cardWidth = (MediaQuery.of(context).size.width * 0.7).clamp(
      180.0,
      250.0,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: message.isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            width: cardWidth,
            decoration: BoxDecoration(
              color: message.isMe
                  ? AppTheme.kAccentColor.withValues(alpha: 0.1)
                  : CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: message.isMe
                    ? AppTheme.kAccentColor.withValues(alpha: 0.3)
                    : CupertinoColors.systemGrey4,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (image.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.network(
                      image,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        color: CupertinoColors.systemGrey5,
                        child: const Icon(
                          CupertinoIcons.photo,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quan tâm phòng',
                        style: TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        roomName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fmt.format(price),
                        style: const TextStyle(
                          color: AppTheme.kAccentColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            timeStr,
            style: const TextStyle(
              color: CupertinoColors.systemGrey,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
