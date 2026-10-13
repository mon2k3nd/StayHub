import 'dart:ui';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/components/safe_network_image.dart';
import '../../../../core/components/bounce_click.dart';
import '../../../../core/widgets/guest_masked_text.dart';

/// Thẻ phòng cao cấp cho Guest Mode — iOS 26 Liquid Glass.
///
/// - Bo góc 28px, bóng lan tỏa ám xanh.
/// - Ảnh lớn với gradient overlay + badge giá dạng pill kính mờ.
/// - Nút tim kính mờ, pill tiện ích Sky Blue.
/// - Địa chỉ được mask số nhà chi tiết (bảo mật Guest Mode).
class GuestPropertyCard extends StatelessWidget {
  final Map<String, dynamic> property;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? margin;
  final double imageHeight;
  final bool isWishlisted;
  final VoidCallback? onToggleWishlist;

  const GuestPropertyCard({
    super.key,
    required this.property,
    required this.onTap,
    this.margin,
    this.imageHeight = 185,
    this.isWishlisted = false,
    this.onToggleWishlist,
  });

  @override
  Widget build(BuildContext context) {
    // ── Null-safe parsing với fallback ───────────────────────────────────────
    final String title =
        (property['title'] ?? property['postTitle'])?.toString() ??
        ((property['branchName'] != null && property['roomName'] != null)
            ? '${property['branchName']} - Phòng ${property['roomName']}'
            : property['roomName']?.toString()) ??
        'Phòng chưa có tên';

    final String address =
        (property['addressOld'] ?? property['address'])?.toString() ??
        'Chưa cập nhật vị trí';
    final double price = _asDouble(property['price']);
    // API có thể trả số dạng String -> ép kiểu an toàn, tránh crash.
    final int bedrooms = _asInt(property['bedrooms'], fallback: 1);
    final int bathrooms = _asInt(property['bathrooms'], fallback: 1);
    final int floor = _asInt(property['floor'], fallback: 1);

    String imageUrl = '';
    if (property['coverImageUrl'] != null &&
        property['coverImageUrl'].toString().isNotEmpty) {
      imageUrl = property['coverImageUrl'].toString();
    } else if (property['roomImages'] != null &&
        property['roomImages'].toString().isNotEmpty) {
      try {
        final imgStr = property['roomImages'].toString();
        if (imgStr.startsWith('[')) {
          // jsonDecode requires dart:convert which should be at the top of the file.
          // Since we can't easily add it to the top without a new tool call, we can use a workaround or just add it to the top.
          final List<dynamic> images = jsonDecode(imgStr);
          if (images.isNotEmpty) imageUrl = images.first.toString();
        } else {
          final images = imgStr.split(',');
          if (images.isNotEmpty) imageUrl = images.first.trim();
        }
      } catch (_) {}
    }

    return BounceClick(
      onPressed: onTap,
      child: Container(
        margin: margin ?? const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: AppTheme.kSurface1Light,
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppTheme.kPremiumShadowLight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Ảnh + overlay ──
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              child: Stack(
                children: [
                  SafeNetworkImage(
                    url: imageUrl,
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  // Nút tim (Heart) — Pure Liquid Glass chuẩn Apple/Airbnb
                  Positioned(
                    top: 12,
                    right: 12,
                    child: BounceClick(
                      onPressed: onToggleWishlist,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOutCubic,
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              // Kính trắng mờ trong suốt cao cấp, không ám màu đục
                              color: isWishlisted
                                  ? Colors.white.withValues(alpha: 0.95)
                                  : Colors.black.withValues(alpha: 0.32),
                              border: Border.all(
                                color: isWishlisted
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.28),
                                width: 1,
                              ),
                              boxShadow: [
                                if (isWishlisted) ...[
                                  BoxShadow(
                                    color: const Color(0xFFFF3366).withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 4),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ] else ...[
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ],
                            ),
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 320),
                                transitionBuilder: (child, anim) => ScaleTransition(
                                  scale: CurvedAnimation(
                                    parent: anim,
                                    curve: Curves.elasticOut,
                                  ),
                                  child: child,
                                ),
                                child: Icon(
                                  isWishlisted
                                      ? CupertinoIcons.heart_fill
                                      : CupertinoIcons.heart,
                                  key: ValueKey(isWishlisted),
                                  color: isWishlisted
                                      ? const Color(0xFFFF2D55) // Đỏ hồng neon Apple rực rỡ
                                      : Colors.white,
                                  size: isWishlisted ? 20 : 19,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Badge giá — Sky Blue Pill, không cần gradient nền ảnh
                  Positioned(
                    left: 14,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.kBrand, AppTheme.kBrandDeep],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.kBrand.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_formatPrice(price)} ₫',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '/tháng',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Chi tiết ──
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.kTextPrimary,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // Địa chỉ — mask số nhà chi tiết ở Guest Mode
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: AppTheme.kBrand,
                        size: 16,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: GuestMaskedText(
                          isLoggedIn: false,
                          value: address,
                          maskType: GuestMaskType.address,
                          style: const TextStyle(
                            color: AppTheme.kTextMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Pill tiện ích
                  Row(
                    children: [
                      _buildFeaturePill(Icons.bed_outlined, '$bedrooms PN'),
                      const SizedBox(width: 8),
                      _buildFeaturePill(
                        Icons.bathtub_outlined,
                        '$bathrooms WC',
                      ),
                      const SizedBox(width: 8),
                      _buildFeaturePill(Icons.layers_outlined, 'Tầng $floor'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ép giá trị bất kỳ (num/String/null) về double an toàn.
  static double _asDouble(dynamic raw, {double fallback = 0.0}) {
    if (raw == null) return fallback;
    if (raw is num) {
      final v = raw.toDouble();
      return v.isFinite ? v : fallback;
    }
    final parsed = double.tryParse(raw.toString());
    if (parsed == null || !parsed.isFinite) return fallback;
    return parsed;
  }

  /// Ép giá trị bất kỳ (num/String/null) về int an toàn.
  static int _asInt(dynamic raw, {int fallback = 0}) {
    if (raw == null) return fallback;
    if (raw is num) return raw.toInt();
    final parsed = double.tryParse(raw.toString());
    if (parsed == null || !parsed.isFinite) return fallback;
    return parsed.toInt();
  }

  static String _formatPrice(double value) {
    if (!value.isFinite || value <= 0) return '---';
    final s = value.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  Widget _buildFeaturePill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.kSurfaceBlue,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.kBrand),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.kTextPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
