import 'package:flutter/cupertino.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/components/glass_container.dart';
import '../../../core/components/liquid_background.dart';
import 'dart:async' show unawaited;

class OwnerAiCallCampaignScreen extends ConsumerStatefulWidget {
  const OwnerAiCallCampaignScreen({super.key});

  @override
  ConsumerState<OwnerAiCallCampaignScreen> createState() =>
      _OwnerAiCallCampaignScreenState();
}

class _OwnerAiCallCampaignScreenState
    extends ConsumerState<OwnerAiCallCampaignScreen> {
  int _selectedVoiceIndex = 0;
  final List<Map<String, String>> _voices = [
    {'name': 'Ngọc Mai (Nữ - Miền Nam)', 'type': 'Nhẹ nhàng, tình cảm'},
    {'name': 'Thanh Hằng (Nữ - Miền Bắc)', 'type': 'Rõ ràng, chuyên nghiệp'},
    {'name': 'Hoàng Bách (Nam - Miền Bắc)', 'type': 'Nghiêm túc, dứt khoát'},
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('AI Call Campaign'),
        previousPageTitle: 'Back',
      ),
      child: LiquidBackground(
        colors: AppTheme.kBackgroundLight,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildVoiceSelection(),
              const SizedBox(height: 24),
              _buildScriptPreview(),
              const SizedBox(height: 24),
              _buildTargetList(),
              const SizedBox(height: 32),
              _buildStartButton(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chiến Dịch Nhắc Nợ Tự Động',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: CupertinoColors.black,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Thiết lập AI tự động gọi điện cho các khách thuê đang quá hạn thanh toán.',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.kTextSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceSelection() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(CupertinoIcons.mic_fill, color: AppTheme.kAccentColor),
                SizedBox(width: 8),
                Text(
                  '1. Chọn Giọng Trợ Lý AI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(_voices.length, (index) {
              final voice = _voices[index];
              final isSelected = _selectedVoiceIndex == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedVoiceIndex = index),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.kAccentColor.withValues(alpha: 0.1)
                        : CupertinoColors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.kAccentColor
                          : CupertinoColors.white,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.kAccentColor
                              : AppTheme.kBorderColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.person_alt,
                          color: isSelected
                              ? CupertinoColors.white
                              : AppTheme.kTextSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              voice['name']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              voice['type']!,
                              style: const TextStyle(
                                color: AppTheme.kTextSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isSelected
                            ? CupertinoIcons.checkmark_circle_fill
                            : CupertinoIcons.circle,
                        color: isSelected
                            ? AppTheme.kAccentColor
                            : AppTheme.kTextMuted,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildScriptPreview() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(CupertinoIcons.text_quote, color: AppTheme.kAccentColor),
                SizedBox(width: 8),
                Text(
                  '2. Kịch Bản Khởi Tạo (Tự Động)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Kịch bản: "Chào bạn [Tên Khách Thuê], tôi là trợ lý AI gọi từ hệ thống quản lý nhà trọ. '
                'Hiện tại phòng [Số Phòng] đang có hóa đơn [Số Tiền] chưa thanh toán. '
                'Bạn có thể cho biết dự kiến thanh toán vào ngày nào không ạ?"',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                  color: CupertinoColors.darkBackgroundGray,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetList() {
    return GlassContainer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  CupertinoIcons.group_solid,
                  color: CupertinoColors.systemRed,
                ),
                SizedBox(width: 8),
                Text(
                  '3. Danh Sách Gọi (Quá Hạn)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.black,
                  ),
                ),
                Spacer(),
                Text(
                  '3 Khách',
                  style: TextStyle(
                    color: CupertinoColors.systemRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTargetItem(
              'Trần Văn A',
              'Phòng 101',
              '4,500,000đ',
              'Quá hạn 5 ngày',
            ),
            _buildTargetItem(
              'Lê Thị B',
              'Phòng 205',
              '3,200,000đ',
              'Quá hạn 3 ngày',
            ),
            _buildTargetItem(
              'Nguyễn Văn C',
              'Phòng 304',
              '5,100,000đ',
              'Quá hạn 7 ngày',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetItem(
    String name,
    String room,
    String amount,
    String status,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: CupertinoColors.systemRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              CupertinoIcons.money_dollar,
              color: CupertinoColors.systemRed,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name ($room)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: const TextStyle(
                    color: CupertinoColors.systemRed,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: CupertinoColors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        unawaited(context.push('/ai-call-simulation'));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.kBrand, AppTheme.kBrand],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.kBrand.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.phone_arrow_right,
              color: CupertinoColors.white,
            ),
            SizedBox(width: 8),
            Text(
              'KHỞI ĐỘNG AI CALL CAMPAIGN',
              style: TextStyle(
                color: CupertinoColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
