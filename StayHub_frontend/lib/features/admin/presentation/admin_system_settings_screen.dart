import 'package:flutter/cupertino.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/glass_button.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/theme/app_theme.dart';
import 'dart:async' show unawaited;

class AdminSystemSettingsScreen extends StatefulWidget {
  const AdminSystemSettingsScreen({super.key});

  @override
  State<AdminSystemSettingsScreen> createState() =>
      _AdminSystemSettingsScreenState();
}

class _AdminSystemSettingsScreenState extends State<AdminSystemSettingsScreen> {
  bool _isMaintenanceMode = false;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.kBackgroundLightGray,
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Bảo Trì & Sao Lưu',
          style: TextStyle(color: CupertinoColors.black),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: CupertinoColors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CHẾ ĐỘ BẢO TRÌ (MAINTENANCE MODE)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 12),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: CupertinoColors.destructiveRed.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            CupertinoIcons.exclamationmark_triangle_fill,
                            color: CupertinoColors.destructiveRed,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chặn truy cập hệ thống',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: CupertinoColors.black,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Hiển thị màn hình bảo trì cho toàn bộ user.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CupertinoSwitch(
                          value: _isMaintenanceMode,
                          activeTrackColor: CupertinoColors.destructiveRed,
                          onChanged: (v) {
                            setState(() => _isMaintenanceMode = v);
                          },
                        ),
                      ],
                    ),
                    if (_isMaintenanceMode) ...[
                      const SizedBox(height: 16),
                      const CupertinoTextField(
                        placeholder: 'Nội dung thông báo bảo trì (Tùy chọn)',
                        padding: EdgeInsets.all(12),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'SAO LƯU DỮ LIỆU (DATABASE BACKUP)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 12),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: CupertinoColors.activeGreen.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            CupertinoIcons.cloud_download_fill,
                            color: CupertinoColors.activeGreen,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tải bản sao lưu hiện tại',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: CupertinoColors.black,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Bản sao lưu gần nhất: Hôm nay lúc 02:00',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: CupertinoColors.systemGrey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GlassButton(
                      text: 'Tạo Backup Mới (One-click)',
                      icon: CupertinoIcons.arrow_down_doc_fill,
                      color: CupertinoColors.activeGreen,
                      onPressed: () {
                        unawaited(
                          showCupertinoDialog(
                            context: context,
                            builder: (c) => const Center(
                              child: CupertinoActivityIndicator(),
                            ),
                          ),
                        );
                        Future.delayed(const Duration(seconds: 2), () {
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          unawaited(
                            showCupertinoDialog(
                              context: context,
                              builder: (c) => CupertinoAlertDialog(
                                title: const Text('Hoàn tất'),
                                content: const Text(
                                  'File dump.sql đã được lưu vào máy tính của bạn.',
                                ),
                                actions: [
                                  CupertinoDialogAction(
                                    child: const Text('OK'),
                                    onPressed: () => Navigator.pop(c),
                                  ),
                                ],
                              ),
                            ),
                          );
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
