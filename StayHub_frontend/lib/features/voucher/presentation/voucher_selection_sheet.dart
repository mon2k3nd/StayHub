import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import '../../../core/theme/app_theme.dart';

class VoucherSelectionSheet extends StatefulWidget {
  final List<dynamic> vouchers;
  final int? initialVoucherId;
  final Function(int?) onVoucherSelected;

  const VoucherSelectionSheet({
    super.key,
    required this.vouchers,
    this.initialVoucherId,
    required this.onVoucherSelected,
  });

  @override
  State<VoucherSelectionSheet> createState() => _VoucherSelectionSheetState();
}

class _VoucherSelectionSheetState extends State<VoucherSelectionSheet> {
  int? _selectedVoucherId;

  @override
  void initState() {
    super.initState();
    _selectedVoucherId = widget.initialVoucherId;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemGroupedBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Chọn mã giảm giá',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.black,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(
                  CupertinoIcons.clear_circled_solid,
                  color: CupertinoColors.systemGrey,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: widget.vouchers.isEmpty
                ? const Center(
                    child: Text(
                      'Không có mã giảm giá nào khả dụng',
                      style: TextStyle(color: CupertinoColors.systemGrey),
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.vouchers.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedVoucherId = null);
                              widget.onVoucherSelected(null);
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _selectedVoucherId == null
                                    ? AppTheme.kAccentColor.withValues(
                                        alpha: 0.1,
                                      )
                                    : CupertinoColors.systemBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedVoucherId == null
                                      ? AppTheme.kAccentColor
                                      : Colors.transparent,
                                ),
                              ),
                              child: const Text(
                                'Không dùng mã giảm giá',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: CupertinoColors.black,
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      final v = widget.vouchers[index - 1];
                      final isSelected = _selectedVoucherId == v.id;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedVoucherId = v.id);
                            widget.onVoucherSelected(v.id);
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.kAccentColor.withValues(alpha: 0.1)
                                  : CupertinoColors.systemBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.kAccentColor
                                    : CupertinoColors.systemGrey4,
                              ),
                              boxShadow: isSelected
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: CupertinoColors.systemGrey4
                                            .withValues(alpha: 0.5),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.kAccentColor.withValues(
                                      alpha: 0.2,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    CupertinoIcons.ticket,
                                    color: AppTheme.kAccentColor,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        v.code,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: CupertinoColors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Giảm ${v.discountType == 'FIXED_AMOUNT' ? '${v.discountAmount}đ' : '${v.discountPercent}%'}',
                                        style: const TextStyle(
                                          color: CupertinoColors.systemGrey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    CupertinoIcons.checkmark_alt_circle_fill,
                                    color: AppTheme.kAccentColor,
                                    size: 28,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
