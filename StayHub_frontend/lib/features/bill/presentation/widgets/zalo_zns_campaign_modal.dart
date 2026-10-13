import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/liquid_glass_colors.dart';
import '../../data/models/bill_model.dart';

class ZaloZnsCampaignModal extends StatefulWidget {
  final List<BillModel> unpaidBills;

  const ZaloZnsCampaignModal({super.key, required this.unpaidBills});

  static Future<void> show(BuildContext context, List<BillModel> unpaidBills) {
    return showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => ZaloZnsCampaignModal(unpaidBills: unpaidBills),
    );
  }

  @override
  State<ZaloZnsCampaignModal> createState() => _ZaloZnsCampaignModalState();
}

class _ZaloZnsCampaignModalState extends State<ZaloZnsCampaignModal> {
  int _currentIndex = 0;
  bool _isFinished = false;
  Timer? _timer;
  final _currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _startCampaign();
  }

  void _startCampaign() {
    _timer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (_currentIndex < widget.unpaidBills.length - 1) {
        setState(() => _currentIndex++);
        unawaited(HapticFeedback.lightImpact());
      } else {
        setState(() => _isFinished = true);
        unawaited(HapticFeedback.heavyImpact());
        _timer?.cancel();
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
    final double progress = widget.unpaidBills.isEmpty
        ? 1.0
        : (_currentIndex + (_isFinished ? 1 : 0)) / widget.unpaidBills.length;
    final total = widget.unpaidBills.length;
    final currentRoom = widget.unpaidBills.isNotEmpty
        ? widget.unpaidBills[_currentIndex].roomId.toString()
        : 'N/A';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemGroupedBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chiến dịch Zalo ZNS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.black,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Icon(
                      CupertinoIcons.clear_circled_solid,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Zalo ZNS Mockup
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0068FF).withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0068FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                CupertinoIcons.chat_bubble_fill,
                                color: CupertinoColors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Zalo ZNS',
                                  style: TextStyle(
                                    color: CupertinoColors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'StayHub Official Account',
                                  style: TextStyle(
                                    color: CupertinoColors.systemGrey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(color: Color(0xFFE5E7EB), height: 1),
                        ),
                        const Text(
                          'THÔNG BÁO CƯỚC STAYHUB',
                          style: TextStyle(
                            color: Color(0xFF0068FF),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: CupertinoColors.black,
                              fontSize: 15,
                              height: 1.5,
                            ),
                            children: [
                              const TextSpan(
                                text: 'Xin chào khách thuê phòng ',
                              ),
                              TextSpan(
                                text: currentRoom,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const TextSpan(
                                text:
                                    '.\nStayHub xin thông báo tiền phòng và dịch vụ tháng này của bạn là ',
                              ),
                              TextSpan(
                                text: widget.unpaidBills.isNotEmpty
                                    ? _currencyFmt.format(
                                        widget
                                                .unpaidBills[_currentIndex]
                                                .totalAmount ??
                                            0,
                                      )
                                    : '0đ',
                                style: const TextStyle(
                                  color: CupertinoColors.systemRed,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const TextSpan(
                                text:
                                    '.\nVui lòng thanh toán trước ngày 05/08 để không bị gián đoạn dịch vụ.\nCảm ơn bạn!',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF0068FF,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'Mở App Thanh Toán',
                            style: TextStyle(
                              color: Color(0xFF0068FF),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Progress Section
                  Text(
                    _isFinished
                        ? 'Đã hoàn thành!'
                        : 'Đang tiến hành gửi ZNS...',
                    style: TextStyle(
                      color: _isFinished
                          ? CupertinoColors.systemGreen
                          : AppTheme.kAccentColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Custom Progress Bar
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isFinished
                              ? CupertinoColors.systemGreen
                              : const Color(0xFF0068FF),
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (_isFinished
                                          ? CupertinoColors.systemGreen
                                          : const Color(0xFF0068FF))
                                      .withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_currentIndex + (_isFinished ? 1 : 0))} / $total tin nhắn',
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),
                  if (_isFinished)
                    CupertinoButton(
                      color: CupertinoColors.systemGreen,
                      borderRadius: BorderRadius.circular(12),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Hoàn tất',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
