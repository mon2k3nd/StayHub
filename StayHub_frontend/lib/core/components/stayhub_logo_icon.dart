import 'package:flutter/material.dart';

class StayHubLogoIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final bool useWhite;

  const StayHubLogoIcon({
    super.key,
    this.size = 24,
    this.color,
    this.useWhite = false,
  });

  @override
  Widget build(BuildContext context) {
    // ALWAYS use the true transparent logo (has_alpha=True).
    // The 'trang-khong-nen.png' is broken (RGB no alpha) and will render a solid background box!
    const imagePath = 'assets/images/logo/logo-stayhub-khong-nen.png';

    return Image.asset(
      imagePath,
      height: size,
      fit: BoxFit.contain,
      color:
          color, // Restore tinting! Since the base image is transparent, this perfectly colorizes it to white/black.
    );
  }
}
