import 'dart:async';
import 'package:flutter/cupertino.dart';
import '../../../../core/theme/app_theme.dart';

class AnimatedPropertyIcons extends StatefulWidget {
  final double size;
  final ValueChanged<int>? onIndexChanged;

  const AnimatedPropertyIcons({super.key, this.size = 80, this.onIndexChanged});

  @override
  State<AnimatedPropertyIcons> createState() => _AnimatedPropertyIconsState();
}

class _AnimatedPropertyIconsState extends State<AnimatedPropertyIcons> {
  int _currentIndex = 0;
  Timer? _timer;

  // Danh sách 5 loại hình — ảnh 3D isometric nền trong suốt (PNG).
  final List<String> _images = [
    'assets/images/categories/luu_tru_v11.png', // Đa dạng loại hình lưu trú
    'assets/images/categories/nha_o_v11.png', // Nhà nguyên căn tiện nghi
    'assets/images/categories/o_ghep_v11.png', // Studio phong cách hiện đại
    'assets/images/categories/phong_tro_v11.png', // Phòng trọ giá tốt, an ninh
    'assets/images/categories/can_ho_v11.png', // Chung cư cao cấp sang trọng
  ];

  final List<IconData> _fallbackIcons = [
    CupertinoIcons.building_2_fill,
    CupertinoIcons.house_fill,
    CupertinoIcons.macwindow,
    CupertinoIcons.bed_double_fill,
    CupertinoIcons.building_2_fill,
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _images.length;
        });
        if (widget.onIndexChanged != null) {
          widget.onIndexChanged!(_currentIndex);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ── Icon 3D PNG trần ──
    // KHÔNG nền, KHÔNG khung, KHÔNG bo góc — chỉ bản thân icon.
    // PNG đã có nền trong suốt nên icon "nổi" trực tiếp trên nền app.
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: Image.asset(
          _images[_currentIndex],
          key: ValueKey<int>(_currentIndex),
          fit: BoxFit.contain,
          width: widget.size,
          height: widget.size,
          errorBuilder: (context, error, stackTrace) {
            // Fallback an toàn nếu ảnh chưa load được hoặc chưa render xong
            return Icon(
              _fallbackIcons[_currentIndex],
              key: ValueKey<int>(_currentIndex),
              color: AppTheme.kBrand,
              size: widget.size * 0.7,
            );
          },
        ),
      ),
    );
  }
}
