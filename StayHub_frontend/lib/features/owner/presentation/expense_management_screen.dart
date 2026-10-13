import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Material;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/theme/app_theme.dart';
import '../application/expense_notifier.dart';
import 'dart:async' show unawaited;

class ExpenseManagementScreen extends ConsumerStatefulWidget {
  const ExpenseManagementScreen({super.key});

  @override
  ConsumerState<ExpenseManagementScreen> createState() =>
      _ExpenseManagementScreenState();
}

class _ExpenseManagementScreenState
    extends ConsumerState<ExpenseManagementScreen> {
  final _currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final _dateFmt = DateFormat('dd/MM/yyyy');

  void _showAddExpenseDialog() {
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (context) => const _AddExpenseSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expenseProvider);
    final totalExpense = ref.watch(totalExpenseProvider);

    return LiquidGlassScaffold(
      title: 'Quản Lý Chi Phí',
      backgroundColors: AppTheme.kBackgroundLight,
      useScrollView: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            GlassContainer(
              padding: const EdgeInsets.all(24),
              color: CupertinoColors.systemRed.withValues(alpha: 0.1),
              border: Border.all(
                color: CupertinoColors.systemRed.withValues(alpha: 0.2),
              ),
              child: Column(
                children: [
                  const Text(
                    'TỔNG CHI PHÍ THÁNG NÀY',
                    style: TextStyle(
                      color: CupertinoColors.systemRed,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currencyFmt.format(totalExpense),
                    style: const TextStyle(
                      color: CupertinoColors.systemRed,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'LỊCH SỬ GIAO DỊCH',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemGrey,
                    fontSize: 13,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _showAddExpenseDialog,
                  minimumSize: const Size(0, 0),
                  child: const Row(
                    children: [
                      Icon(CupertinoIcons.add_circled_solid, size: 20),
                      SizedBox(width: 4),
                      Text(
                        'Thêm',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            expensesAsync.when(
              loading: () => const Center(child: CupertinoActivityIndicator()),
              error: (err, stack) => Text(
                'Lỗi: $err',
                style: const TextStyle(color: CupertinoColors.systemRed),
              ),
              data: (expenses) {
                if (expenses.isEmpty) {
                  return const Center(child: Text('Chưa có khoản chi nào.'));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final item = expenses[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: CupertinoColors.systemGrey6,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.doc_text_fill,
                                color: CupertinoColors.systemGrey,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: CupertinoColors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${item.category} • ${_dateFmt.format(item.date)}',
                                    style: const TextStyle(
                                      color: CupertinoColors.systemGrey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '-${_currencyFmt.format(item.amount)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: CupertinoColors.systemRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

class _AddExpenseSheet extends ConsumerStatefulWidget {
  const _AddExpenseSheet();

  @override
  ConsumerState<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<_AddExpenseSheet> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _selectedCategory = 'Bảo trì';
  final List<String> _categories = [
    'Bảo trì',
    'Điện nước',
    'Lương thưởng',
    'Khác',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 8),
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey4,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const SizedBox(width: 24),
                const Expanded(
                  child: Text(
                    'Thêm Khoản Chi',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: CupertinoColors.black,
                    ),
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Icon(
                    CupertinoIcons.clear_circled_solid,
                    color: CupertinoColors.systemGrey,
                    size: 28,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Container(
              height: 1,
              color: CupertinoColors.systemGrey4,
              margin: const EdgeInsets.symmetric(vertical: 8),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'Nội dung chi',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _titleCtrl,
                    placeholder: 'Ví dụ: Sửa ống nước phòng 201',
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Số tiền (VNĐ)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: _amountCtrl,
                    placeholder: '1,500,000',
                    keyboardType: TextInputType.number,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Danh mục',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((c) {
                      final isSelected = _selectedCategory == c;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = c),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? CupertinoColors.activeBlue
                                : CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            c,
                            style: TextStyle(
                              color: isSelected
                                  ? CupertinoColors.white
                                  : CupertinoColors.black,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: Consumer(
                      builder: (context, ref, child) {
                        final isSubmitting = ref
                            .watch(expenseProvider)
                            .isLoading;
                        return CupertinoButton.filled(
                          borderRadius: BorderRadius.circular(16),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final title = _titleCtrl.text.trim();
                                  final amountStr = _amountCtrl.text
                                      .trim()
                                      .replaceAll(',', '')
                                      .replaceAll('.', '');
                                  final amount =
                                      double.tryParse(amountStr) ?? 0.0;
                                  if (title.isEmpty || amount <= 0) return;

                                  await ref
                                      .read(expenseProvider.notifier)
                                      .addExpense(
                                        title,
                                        amount,
                                        _selectedCategory,
                                      );
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                          child: isSubmitting
                              ? const CupertinoActivityIndicator(
                                  color: CupertinoColors.white,
                                )
                              : const Text(
                                  'Lưu Khoản Chi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        );
                      },
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
