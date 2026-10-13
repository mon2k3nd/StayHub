import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/components/bounce_click.dart';
import 'dart:async' show unawaited;
import '../../../core/utils/toast_utils.dart';

class MockContractModel {
  final String id;
  final String title;
  final String tenantName;
  final String roomName;
  final String status; // 'ACTIVE', 'PENDING_SIGNATURE', 'EXPIRED'
  final DateTime startDate;
  final DateTime endDate;
  final double depositAmount;

  MockContractModel({
    required this.id,
    required this.title,
    required this.tenantName,
    required this.roomName,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.depositAmount,
  });
}

class ContractListScreen extends StatefulWidget {
  const ContractListScreen({super.key});

  @override
  State<ContractListScreen> createState() => _ContractListScreenState();
}

class _ContractListScreenState extends State<ContractListScreen> {
  int _selectedSegment = 0;

  final List<MockContractModel> mockContracts = [
    MockContractModel(
      id: 'C-2026-001',
      title: 'Hợp Đồng Thuê Phòng',
      tenantName: 'Nguyễn Văn A',
      roomName: 'P.101 - Chi nhánh Quận 1',
      status: 'PENDING_SIGNATURE',
      startDate: DateTime(2026, 7, 1),
      endDate: DateTime(2027, 7, 1),
      depositAmount: 5000000,
    ),
    MockContractModel(
      id: 'C-2025-089',
      title: 'Hợp Đồng Thuê Phòng',
      tenantName: 'Trần Thị B',
      roomName: 'P.202 - Chi nhánh Quận 3',
      status: 'ACTIVE',
      startDate: DateTime(2025, 12, 1),
      endDate: DateTime(2026, 12, 1),
      depositAmount: 4500000,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredContracts = mockContracts.where((c) {
      if (_selectedSegment == 0) return c.status == 'PENDING_SIGNATURE';
      if (_selectedSegment == 1) return c.status == 'ACTIVE';
      return c.status == 'EXPIRED';
    }).toList();

    return LiquidGlassScaffold(
      title: 'Hợp Đồng Điện Tử',
      backgroundColors: AppTheme.kBackgroundLight,
      useScrollView: false,
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        child: const Icon(
          CupertinoIcons.doc_append,
          color: AppTheme.kAccentColor,
          size: 26,
        ),
        onPressed: () {
          ToastUtils.show(context, 'Tạo hợp đồng đang phát triển');
        },
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<int>(
                groupValue: _selectedSegment,
                children: const {
                  0: Text(
                    'Chờ Ký',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  1: Text(
                    'Đang Thuê',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  2: Text(
                    'Đã Hết Hạn',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                },
                onValueChanged: (val) {
                  if (val != null) setState(() => _selectedSegment = val);
                },
              ),
            ),
          ),
          Expanded(
            child: AnimationLimiter(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredContracts.length,
                itemBuilder: (context, index) {
                  final c = filteredContracts[index];
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 375),
                    child: SlideAnimation(
                      verticalOffset: 40,
                      child: FadeInAnimation(
                        child: BounceClick(
                          onPressed: () {
                            unawaited(context.push('/contract/detail/${c.id}'));
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildContractCard(c),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractCard(MockContractModel c) {
    final isPending = c.status == 'PENDING_SIGNATURE';
    final cardColor = isPending
        ? CupertinoColors.systemOrange
        : CupertinoColors.systemGreen;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            CupertinoColors.white.withValues(alpha: 0.95),
            CupertinoColors.systemGrey6.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: cardColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          // Folder Tab Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border(
                bottom: BorderSide(color: cardColor.withValues(alpha: 0.2)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isPending
                          ? CupertinoIcons.signature
                          : CupertinoIcons.checkmark_seal_fill,
                      color: cardColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      c.id,
                      style: TextStyle(
                        color: cardColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isPending ? 'Chờ chữ ký' : 'Đang hiệu lực',
                    style: TextStyle(
                      color: cardColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: CupertinoColors.black,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow(
                  CupertinoIcons.person_fill,
                  'Bên Thuê:',
                  c.tenantName,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(CupertinoIcons.house_fill, 'Phòng:', c.roomName),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.kBackgroundLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hiệu lực',
                              style: TextStyle(
                                fontSize: 12,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${c.startDate.day}/${c.startDate.month}/${c.startDate.year}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.kBackgroundLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hết hạn',
                              style: TextStyle(
                                fontSize: 12,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${c.endDate.day}/${c.endDate.month}/${c.endDate.year}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: CupertinoColors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: CupertinoColors.systemGrey),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.black,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
