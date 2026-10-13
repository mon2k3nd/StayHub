import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ScaffoldMessenger, SnackBar;
import '../../../../../core/components/glass_container.dart';
import '../../../../../core/components/liquid_background.dart';
import '../../../../../core/theme/app_theme.dart';

class TenantUtilitiesDashboardScreen extends StatelessWidget {
  const TenantUtilitiesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Bảng Điện Nước'),
        backgroundColor: Color(0x00000000),
        border: null,
      ),
      child: LiquidBackground(
        colors: AppTheme.kBackgroundLight,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                const Icon(
                  CupertinoIcons.drop,
                  size: 80,
                  color: AppTheme.kAccentColor,
                ),
                const SizedBox(height: 24),
                GlassContainer(
                  borderRadius: 24,
                  blur: 20,
                  color: AppTheme.kGlassColorLight,
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Text(
                        'Bảng Điện Nước',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.kTextPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tính năng Bảng Điện Nước thuộc bộ 50 tiện ích cao cấp dành riêng cho Người Thuê. Hệ thống đang giả lập giao diện bằng Liquid Glass.',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.kTextSecondary,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      CupertinoButton.filled(
                        borderRadius: BorderRadius.circular(16),
                        child: const Text('Bắt đầu Trải nghiệm'),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng đang phát triển')));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
