import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../utils/image_url_helper.dart';

/// Widget ảnh mạng an toàn – tự động:
/// 1. Ghép baseUrl nếu là đường dẫn tương đối (/uploads/...)
/// 2. Cache ảnh ra đĩa (tránh tải lại, tiết kiệm RAM)
/// 3. Giới hạn bộ nhớ giải mã (memCacheWidth) để tránh OOM/crash
/// 4. Hiển thị placeholder và error widget thân thiện
class SafeNetworkImage extends StatelessWidget {
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final BorderRadius? borderRadius;

  const SafeNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.memCacheWidth,
    this.memCacheHeight,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = ImageUrlHelper.buildUrl(url);

    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      return _buildError();
    }

    Widget image = CachedNetworkImage(
      imageUrl: resolvedUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth ?? _inferCacheWidth(),
      memCacheHeight: memCacheHeight,
      placeholder: (_, __) =>
          placeholder ??
          SizedBox(
            width: width,
            height: height,
            child: const Center(child: CupertinoActivityIndicator(radius: 10)),
          ),
      errorWidget: (_, __, ___) => _buildError(),
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    return image;
  }

  Widget _buildError() {
    return errorWidget ??
        Container(
          width: width,
          height: height,
          color: const Color(0xFFF3F4F6),
          child: const Icon(
            Icons.broken_image_outlined,
            color: Color(0xFFD1D5DB),
          ),
        );
  }

  /// Tự động giới hạn cache width dựa trên kích thước hiển thị
  int? _inferCacheWidth() {
    if (width != null && width! > 0 && width!.isFinite) {
      return (width! * 2).toInt().clamp(100, 800); // 2x cho màn hình Retina
    }
    return 400; // Default cap cho ảnh không rõ kích thước
  }
}
