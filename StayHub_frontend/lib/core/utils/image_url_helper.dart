import '../network/api_client.dart';

/// Helper để xử lý URL ảnh từ backend.
/// Backend có thể trả về:
///   - Đường dẫn tương đối: "/uploads/tickets/abc.jpg"
///   - URL đầy đủ: "https://example.com/image.jpg"
/// Hàm này đảm bảo luôn trả về URL đầy đủ có thể load được.
class ImageUrlHelper {
  static String get _baseUrl => ApiClient.baseUrl;

  /// Chuyển đổi URL ảnh thành URL đầy đủ.
  /// Nếu [url] là null hoặc rỗng, trả về null.
  static String? buildUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    if (url.startsWith('base64:')) {
      return url;
    }
    // Check if it's likely a base64 string (starts with data:image, /9j/, iVBO, or is very long without file extensions)
    if (url.startsWith('data:image') ||
        url.startsWith('/9j/') ||
        url.startsWith('iVBO') ||
        (url.length > 200 && !url.contains('.'))) {
      return url.startsWith('data:image') ? url : 'base64:$url';
    }
    // Đường dẫn tương đối - ghép base URL
    final path = url.startsWith('/') ? url : '/$url';
    return '$_baseUrl$path';
  }

  /// Chuyển đổi URL ảnh thành URL đầy đủ.
  /// Nếu [url] là null hoặc rỗng, trả về [fallback].
  static String buildUrlOrFallback(String? url, String fallback) {
    return buildUrl(url) ?? fallback;
  }

  /// Tạo URL avatar mặc định từ tên người dùng.
  static String defaultAvatarUrl(String name) {
    return 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=0EA5E9&color=fff&size=150';
  }
}
