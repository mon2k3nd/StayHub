import 'package:flutter/cupertino.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/theme/app_theme.dart';

class AdminLegalBlueprintsScreen extends StatelessWidget {
  const AdminLegalBlueprintsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> templates = [
      {
        'title': 'Hợp đồng Thuê Phòng Trọ (Chuẩn 2026)',
        'version': 'v3.2',
        'date': '20/06/2026',
        'is_active': true,
      },
      {
        'title': 'Nội Quy Khu Trọ (Mẫu Chung)',
        'version': 'v1.5',
        'date': '15/01/2025',
        'is_active': true,
      },
      {
        'title': 'Phụ Lục Tiền Cọc & Cam Kết',
        'version': 'v2.0',
        'date': '05/03/2026',
        'is_active': false,
      },
      {
        'title': 'Chính sách Bảo Mật (Quy định nhà nước)',
        'version': 'v4.1',
        'date': '12/06/2026',
        'is_active': true,
      },
    ];

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.kBackgroundLightGray,
      navigationBar: CupertinoNavigationBar(
        middle: const Text(
          'Kho Pháp Lý & Biểu Mẫu',
          style: TextStyle(color: CupertinoColors.black),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: CupertinoColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(
            CupertinoIcons.add_circled_solid,
            color: CupertinoColors.activeBlue,
          ),
          onPressed: () {},
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: CupertinoColors.activeBlue.withValues(alpha: 0.1),
              child: const Row(
                children: [
                  Icon(
                    CupertinoIcons.info_circle_fill,
                    color: CupertinoColors.activeBlue,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tất cả Chủ trọ trên nền tảng sẽ dùng chung các biểu mẫu đang "Kích hoạt" tại đây để ký e-Signature.',
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.activeBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final item = templates[index];
                  // BUGFIX (data): tránh `as bool` ném TypeError khi
                  // `is_active` là null/kiểu khác.
                  final isActive = item['is_active'] is bool
                      ? item['is_active'] as bool
                      : false;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemPurple
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  CupertinoIcons.doc_text_fill,
                                  color: CupertinoColors.systemPurple,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: CupertinoColors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Phiên bản: ${item['version']} • Cập nhật: ${item['date']}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: CupertinoColors.systemGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? CupertinoColors.activeGreen.withValues(
                                          alpha: 0.1,
                                        )
                                      : CupertinoColors.systemGrey.withValues(
                                          alpha: 0.1,
                                        ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isActive
                                          ? CupertinoIcons.checkmark_seal_fill
                                          : CupertinoIcons.nosign,
                                      size: 14,
                                      color: isActive
                                          ? CupertinoColors.activeGreen
                                          : CupertinoColors.systemGrey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isActive ? 'ĐANG KÍCH HOẠT' : 'ĐÃ ẨN',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isActive
                                            ? CupertinoColors.activeGreen
                                            : CupertinoColors.systemGrey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                color: CupertinoColors.white,
                                borderRadius: BorderRadius.circular(8),
                                child: const Text(
                                  'Xem nội dung',
                                  style: TextStyle(
                                    color: CupertinoColors.systemPurple,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
