import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/liquid_glass_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../branch/application/branch_notifier.dart';
import '../../bill/application/meter_reading_notifier.dart';
import 'widgets/smart_ocr_scanner_sheet.dart';
import 'dart:async' show unawaited;

class OwnerElectricMeterScreen extends ConsumerStatefulWidget {
  const OwnerElectricMeterScreen({super.key});
  @override
  ConsumerState<OwnerElectricMeterScreen> createState() =>
      _OwnerElectricMeterScreenState();
}

class _OwnerElectricMeterScreenState
    extends ConsumerState<OwnerElectricMeterScreen> {
  final int _selectedMonth = DateTime.now().month;
  final int _selectedYear = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final branchAsync = ref.watch(branchProvider);

    return LiquidGlassScaffold(
      title: 'Chốt Số Điện Nước',
      backgroundColors: AppTheme.kBackgroundLight,
      child: branchAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, st) => Center(child: Text('Lỗi: $e')),
        data: (branches) {
          if (branches.isEmpty) {
            return const Center(child: Text('Bạn chưa có khu trọ nào.'));
          }

          final branchId = branches.first.id;
          final metersAsync = ref.watch(
            meterReadingProvider(branchId, _selectedMonth, _selectedYear),
          );

          return metersAsync.when(
            loading: () => const Center(child: CupertinoActivityIndicator()),
            error: (e, st) => Center(child: Text('Lỗi: $e')),
            data: (meters) {
              if (meters.isEmpty) {
                return const Center(
                  child: Text(
                    'Chưa có thông tin điện nước.',
                    style: TextStyle(color: AppTheme.kTextSecondary),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: meters.length,
                itemBuilder: (context, index) {
                  final m = meters[index];
                  final hasCurrent =
                      (m.electricCurrent ?? 0) > 0 || (m.waterCurrent ?? 0) > 0;
                  final meterMap = {
                    'room': m.roomName,
                    'branch': branches.first.branchName,
                    'electricReading':
                        m.electricCurrent?.toStringAsFixed(0) ?? '---',
                    'waterReading': m.waterCurrent?.toStringAsFixed(0) ?? '---',
                    'lastUpdated': 'Tháng $_selectedMonth/$_selectedYear',
                    'status': hasCurrent ? 'Đã chốt' : 'Chưa chốt',
                    'roomId': m.roomId,
                  };
                  return _buildMeterCard(meterMap);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMeterCard(Map<String, dynamic> meter) {
    Color statusColor = meter['status'] == 'Đã chốt'
        ? CupertinoColors.systemGreen
        : CupertinoColors.systemOrange;

    // Controllers for matrix input
    final elecController = TextEditingController(
      text: meter['electricReading'] != '---' ? meter['electricReading'] : '',
    );
    final waterController = TextEditingController(
      text: meter['waterReading'] != '---' ? meter['waterReading'] : '',
    );

    // Mock config logic (In real app, fetch from DTO)
    final bool isWaterPerPerson =
        meter['roomId'] == 2; // Mock condition to lock water input

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${meter['room']} • ${meter['branch']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        meter['status'],
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        CupertinoIcons.clock,
                        size: 14,
                        color: AppTheme.kTextSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        meter['lastUpdated'],
                        style: const TextStyle(
                          color: AppTheme.kTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(
                  CupertinoIcons.camera_viewfinder,
                  color: LiquidGlassColors.ownerAccent,
                ),
                onPressed: () {
                  unawaited(
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => SmartOcrScannerSheet(
                        onScanComplete: (elec, water) {
                          elecController.text = elec.toString();
                          if (!isWaterPerPerson) {
                            waterController.text = water.toString();
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Matrix Input
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚡ Điện (Mới)',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.kTextSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    CupertinoTextField(
                      controller: elecController,
                      keyboardType: TextInputType.number,
                      placeholder: 'Số mới',
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(
                          CupertinoIcons.bolt_fill,
                          size: 16,
                          color: CupertinoColors.systemYellow,
                        ),
                      ),
                      onChanged: (val) {
                        final newNum = double.tryParse(val) ?? 0;
                        final oldNum = meter['electricPrevious'] ?? 0;
                        if (newNum < oldNum) {
                          // Show inline warning or toast
                        }
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cũ: ${meter['electricPrevious'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💧 Nước (Mới)',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.kTextSecondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    CupertinoTextField(
                      controller: waterController,
                      keyboardType: TextInputType.number,
                      placeholder: isWaterPerPerson ? 'Theo người' : 'Số mới',
                      readOnly: isWaterPerPerson,
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(
                          CupertinoIcons.drop_fill,
                          size: 16,
                          color: CupertinoColors.systemBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isWaterPerPerson
                          ? 'Thu khoán /người'
                          : 'Cũ: ${meter['waterPrevious'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: LiquidGlassColors.ownerAccent,
              borderRadius: BorderRadius.circular(12),
              child: const Text(
                'Lưu Chỉ Số',
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                final newElec = double.tryParse(elecController.text) ?? 0;
                final oldElec = meter['electricPrevious'] ?? 0;
                if (newElec < oldElec) {
                  unawaited(
                    showCupertinoDialog(
                      context: context,
                      builder: (c) => CupertinoAlertDialog(
                        title: const Text('Chỉ số bất thường!'),
                        content: const Text(
                          'Số điện mới không được nhỏ hơn số cũ. Vui lòng kiểm tra lại.',
                        ),
                        actions: [
                          CupertinoDialogAction(
                            child: const Text('Sửa lại'),
                            onPressed: () => Navigator.pop(c),
                          ),
                        ],
                      ),
                    ),
                  );
                  return;
                }
                // Call API updateUtilitiesByRoom
              },
            ),
          ),
        ],
      ),
    );
  }
}
