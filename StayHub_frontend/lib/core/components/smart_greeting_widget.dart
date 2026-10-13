import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../../features/auth/application/auth_notifier.dart';

class SmartGreetingWidget extends ConsumerWidget {
  const SmartGreetingWidget({super.key});

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 11) {
      return '☀️ Chào buổi sáng,';
    } else if (hour < 14) {
      return '🌤️ Buổi trưa vui vẻ,';
    } else if (hour < 18) {
      return '🌅 Chiều đầy năng lượng,';
    } else {
      return '🌙 Buổi tối an lành,';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authProvider);
    final user = authAsync.value;
    final isDark = ref.watch(themeProvider);
    final greeting = _getGreetingMessage();

    // While auth is loading (e.g. web page refresh), show shimmer placeholder
    // so we never flash "Bạn" while waiting for the real name.
    if (authAsync.isLoading) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 13,
            width: 130,
            decoration: BoxDecoration(
              color: isDark ? Colors.white12 : Colors.black12,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 22,
            width: 100,
            decoration: BoxDecoration(
              color: isDark ? Colors.white12 : Colors.black12,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      );
    }

    final name = (user?.fullName.isNotEmpty == true) ? user!.fullName : 'Bạn';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(-10 * (1 - value), 0),
        child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: TextStyle(
              color: isDark ? const Color(0xFFA0A0A0) : const Color(0xFF666666),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            name,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1C1C1E),
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
