import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../components/bounce_click.dart';

/// Bottom sheet chia sẻ phòng dạng Liquid Glass.
///
/// Hỗ trợ: sao chép liên kết, chia sẻ qua Zalo / Facebook / SMS / Email.
/// Không phụ thuộc package `share_plus` — dùng `url_launcher` + Clipboard.
class ShareRoomSheet extends StatelessWidget {
  final String title;
  final String priceText;
  final String? imageUrl;
  final String shareUrl;

  const ShareRoomSheet({
    super.key,
    required this.title,
    required this.priceText,
    required this.shareUrl,
    this.imageUrl,
  });

  /// Hiển thị bottom sheet chia sẻ.
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String priceText,
    required String shareUrl,
    String? imageUrl,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ShareRoomSheet(
        title: title,
        priceText: priceText,
        shareUrl: shareUrl,
        imageUrl: imageUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final message = 'Xem phòng "$title" ($priceText) trên StayHub:\n$shareUrl';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: AppTheme.kSurface1Light,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: AppTheme.kPremiumShadowLight,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grabber
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.kBorderColor,
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Chia sẻ phòng này',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppTheme.kTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: AppTheme.kTextMuted),
            ),
            const SizedBox(height: 20),

            // Hàng icon chia sẻ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ShareTarget(
                  icon: Icons.link_rounded,
                  label: 'Sao chép',
                  color: AppTheme.kBrand,
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: shareUrl));
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      _toast(context, 'Đã sao chép liên kết');
                    }
                  },
                ),
                _ShareTarget(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Zalo',
                  color: const Color(0xFF0068FF),
                  onTap: () => _launch(
                    context,
                    Uri.parse(
                      'https://zalo.me/share?u=${Uri.encodeComponent(shareUrl)}',
                    ),
                    fallbackMessage: message,
                  ),
                ),
                _ShareTarget(
                  icon: Icons.facebook_rounded,
                  label: 'Facebook',
                  color: const Color(0xFF1877F2),
                  onTap: () => _launch(
                    context,
                    Uri.parse(
                      'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(shareUrl)}',
                    ),
                    fallbackMessage: message,
                  ),
                ),
                _ShareTarget(
                  icon: Icons.sms_rounded,
                  label: 'Tin nhắn',
                  color: const Color(0xFF34C759),
                  onTap: () => _launch(
                    context,
                    Uri.parse('sms:?body=${Uri.encodeComponent(message)}'),
                    fallbackMessage: message,
                  ),
                ),
                _ShareTarget(
                  icon: Icons.mail_rounded,
                  label: 'Email',
                  color: const Color(0xFFFF9500),
                  onTap: () => _launch(
                    context,
                    Uri(
                      scheme: 'mailto',
                      query:
                          'subject=${Uri.encodeComponent('Phòng trên StayHub')}'
                          '&body=${Uri.encodeComponent(message)}',
                    ),
                    fallbackMessage: message,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Ô hiển thị link + copy
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.kSurfaceBlue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.public_rounded,
                    size: 18,
                    color: AppTheme.kBrand,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      shareUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.kTextSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  BounceClick(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: shareUrl));
                      if (context.mounted) {
                        _toast(context, 'Đã sao chép liên kết');
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.kBrand,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Text(
                        'Sao chép',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launch(
    BuildContext context,
    Uri uri, {
    required String fallbackMessage,
  }) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) throw Exception('cannot launch');
      if (context.mounted) Navigator.of(context).pop();
    } catch (_) {
      // Fallback: copy nội dung để người dùng tự dán.
      await Clipboard.setData(ClipboardData(text: fallbackMessage));
      if (context.mounted) {
        Navigator.of(context).pop();
        _toast(context, 'Đã sao chép nội dung chia sẻ');
      }
    }
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.kBrand,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _ShareTarget extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareTarget({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BounceClick(
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.kTextSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
