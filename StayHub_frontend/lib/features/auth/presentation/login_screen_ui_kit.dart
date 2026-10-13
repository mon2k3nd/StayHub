part of 'login_screen.dart';

/// Bộ UI kit dùng chung cho màn Đăng nhập / Đăng ký.
///
/// Gom các builder thuần tuý (không phụ thuộc state của `_AuthScreenState`)
/// để `login_screen_state.dart` chỉ còn tập trung vào logic nghiệp vụ.
/// Tất cả token màu (`_kBrand`, `_kGlass`, ...) được chia sẻ qua `part`.
class _AuthUiKit {
  const _AuthUiKit._();

  /// Khung kính mờ (glass card) bao ngoài form đăng nhập / đăng ký.
  ///
  /// Thiết kế lại theo chuẩn Liquid Glass: panel trắng gần đặc (độ tương phản
  /// cao, chữ rõ ràng trên nền trời sáng), viền gradient mảnh, lớp sheen chéo
  /// phía trên và bóng đổ mềm màu Sky Blue để tạo chiều sâu — thay cho panel
  /// 25% trắng cũ trông nhạt nhoà và "cũ".
  static Widget glassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          // Soft ambient shadow tinted with the brand colour.
          BoxShadow(
            color: _kBrand.withValues(alpha: 0.18),
            blurRadius: 32,
            spreadRadius: -4,
            offset: const Offset(0, 16),
          ),
          // Tight contact shadow for crispness.
          BoxShadow(
            color: const Color(0xFF0F2A4A).withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _kGlass,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: _kGlassB, width: 1.2),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.98),
                  Colors.white.withValues(alpha: 0.90),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Ô nhập liệu bọc sẵn [PremiumTextField].
  ///
  /// Dùng nền xám rất nhạt để tách khỏi panel trắng gần đặc của glass card —
  /// nếu để trắng trên trắng, các ô nhập sẽ "chìm" và trông phẳng, cũ.
  static Widget darkTextField({
    required TextEditingController controller,
    required String placeholder,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    String? errorText,
  }) {
    return PremiumTextField(
      key: ValueKey(placeholder),
      controller: controller,
      placeholder: placeholder,
      prefixIcon: prefixIcon,
      keyboardType: keyboardType,
      isPassword: isPassword,
      errorText: errorText,
      fillColor: const Color(0xFFF1F5F9), // slate-100
    );
  }

  /// Avatar tròn, tự sinh ảnh mặc định từ tên nếu chưa có URL.
  static Widget avatar({
    String? avatarUrl,
    required String name,
    required double size,
  }) {
    final url = (avatarUrl != null && avatarUrl.isNotEmpty)
        ? avatarUrl
        : 'https://ui-avatars.com/api/?name=${Uri.encodeComponent(name)}&background=298FFF&color=fff&size=150&bold=true';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _kBrand.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  /// Nút mạng xã hội dạng "glass pill" (icon + nhãn nằm cùng hàng).
  ///
  /// Thay cho kiểu icon trần 44px + nhãn 11px cũ (trông như app 2015):
  /// mỗi nút là một viên thuốc kính trắng, có viền mảnh, bóng mềm và phản hồi
  /// nhấn scale — đồng bộ với ngôn ngữ Liquid Glass của toàn app.
  static Widget socialButton({
    String? label,
    String? imageUrl,
    IconData? iconData,
    Color? iconColor,
    required VoidCallback onPressed,
  }) {
    return _SocialPill(
      label: label,
      imageUrl: imageUrl,
      iconData: iconData,
      iconColor: iconColor,
      onPressed: onPressed,
    );
  }

  /// Chấm tròn đánh dấu bước hiện tại trong luồng đăng ký.
  static Widget stepDot(int step, bool active) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: active
            ? const LinearGradient(
                colors: [_kBrand, _kBrand2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: active ? null : _kGlass,
        shape: BoxShape.circle,
        border: active ? null : Border.all(color: _kGlassB, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        '$step',
        style: TextStyle(
          color: active ? Colors.white : _kTextSub,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Viên thuốc kính cho nút đăng nhập mạng xã hội.
///
/// Gồm icon (ảnh mạng hoặc [IconData]) + nhãn nằm cùng hàng, nền trắng mờ,
/// viền mảnh và hiệu ứng nhấn scale nhẹ — thay thế kiểu icon trần cũ.
class _SocialPill extends StatefulWidget {
  final String? label;
  final String? imageUrl;
  final IconData? iconData;
  final Color? iconColor;
  final VoidCallback onPressed;

  const _SocialPill({
    this.label,
    this.imageUrl,
    this.iconData,
    this.iconColor,
    required this.onPressed,
  });

  @override
  State<_SocialPill> createState() => _SocialPillState();
}

class _SocialPillState extends State<_SocialPill> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        unawaited(HapticFeedback.lightImpact());
        widget.onPressed();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: _kGlassSoftB, width: 1),
            boxShadow: [
              BoxShadow(
                color: _kBrand.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: widget.imageUrl != null
                    ? Image.network(
                        widget.imageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, _, __) => const Icon(
                          CupertinoIcons.globe,
                          color: CupertinoColors.systemGrey,
                          size: 20,
                        ),
                      )
                    : Icon(
                        widget.iconData,
                        color: widget.iconColor ?? _kText,
                        size: 20,
                      ),
              ),
              if (widget.label != null) ...[
                const SizedBox(width: 8),
                Text(
                  widget.label!,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: _kText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
