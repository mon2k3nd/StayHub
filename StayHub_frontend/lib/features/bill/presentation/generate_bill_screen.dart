import 'package:flutter/cupertino.dart';

import '../../../core/theme/app_theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_button.dart';
import '../../branch/application/branch_notifier.dart';
import '../../../core/providers/core_providers.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/app_error_widget.dart';
import 'dart:async' show unawaited;

class GenerateBillScreen extends ConsumerStatefulWidget {
  const GenerateBillScreen({super.key});

  @override
  ConsumerState<GenerateBillScreen> createState() => _GenerateBillScreenState();
}

class _GenerateBillScreenState extends ConsumerState<GenerateBillScreen> {
  int? _selectedBranchId;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  bool _isGenerating = false;
  // Pool warning state — true khi có Pool chưa nhập số tiền tháng này
  final bool _hasUnsetPools = false;
  final int _unsetPoolCount = 0;

  Future<void> _generateBills() async {
    if (_selectedBranchId == null) return;

    setState(() => _isGenerating = true);
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post(
        '/v1/bills/branch/$_selectedBranchId/generate',
        queryParameters: {'month': _selectedMonth, 'year': _selectedYear},
      );

      final data = res.data;
      if (mounted) {
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Thành công'),
              content: Text(
                data['message'] ?? 'Đã xuất hóa đơn nháp thành công!',
              ),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Đóng'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.pop();
                  },
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Lỗi'),
              content: Text('Không thể tạo hóa đơn: $e'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('Đóng'),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final branchesState = ref.watch(branchProvider);

    return LiquidGlassScaffold(
      title: 'Tạo Hóa Đơn Nháp',
      child: branchesState.when(
        loading: () => const SizedBox(
          height: 300,
          child: Center(child: CupertinoActivityIndicator()),
        ),
        error: (err, _) => AppErrorWidget(error: err),
        data: (branches) {
          if (branches.isEmpty) {
            return const Center(child: Text('Bạn chưa có dãy trọ nào.'));
          }
          if (_selectedBranchId == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() => _selectedBranchId = branches.first.id);
            });
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tính tiền & Xuất hóa đơn',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tạo hóa đơn nháp cho tất cả các phòng đang thuê trong dãy. Sau khi tạo, bạn có thể "Chốt số điện nước" để hoàn tất hóa đơn.',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 32),

                const Text(
                  'CHỌN DÃY TRỌ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showBranchPicker(branches),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedBranchId != null
                              ? branches
                                    .firstWhere(
                                      (b) => b.id == _selectedBranchId,
                                    )
                                    .branchName
                              : 'Chọn dãy trọ',
                        ),
                        const Icon(
                          CupertinoIcons.chevron_down,
                          color: AppTheme.kTextSecondary,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                const Text(
                  'THỜI GIAN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _showMonthYearPicker,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tháng $_selectedMonth năm $_selectedYear'),
                        const Icon(
                          CupertinoIcons.calendar,
                          color: AppTheme.kTextSecondary,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Pool Warning Banner ──────────────────────────────────
                if (_selectedBranchId != null) ...[
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      final selectedBranch = branches.firstWhere(
                        (b) => b.id == _selectedBranchId,
                      );
                      unawaited(
                        context.push(
                          '/owner/branch/$_selectedBranchId/pools',
                          extra: {'branchName': selectedBranch.branchName},
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _hasUnsetPools
                            ? const Color(0xFFFF9500).withValues(alpha: 0.1)
                            : AppTheme.kSuccess.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _hasUnsetPools
                              ? const Color(0xFFFF9500).withValues(alpha: 0.4)
                              : AppTheme.kSuccess.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _hasUnsetPools ? '⚠️' : '✅',
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _hasUnsetPools
                                      ? '$_unsetPoolCount Nhóm Dịch Vụ chưa nhập số tiền'
                                      : 'Tất cả Nhóm Dịch Vụ đã sẵn sàng',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: _hasUnsetPools
                                        ? const Color(0xFFFF9500)
                                        : AppTheme.kSuccess,
                                  ),
                                ),
                                Text(
                                  _hasUnsetPools
                                      ? 'Nhấn để vào Quản lý Nhóm Dịch Vụ →'
                                      : 'Hóa đơn sẽ được tính chính xác.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _hasUnsetPools
                                        ? const Color(0xFFFF9500)
                                        : AppTheme.kSuccess,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            CupertinoIcons.chevron_right,
                            size: 16,
                            color: _hasUnsetPools
                                ? const Color(0xFFFF9500)
                                : AppTheme.kSuccess,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                if (_isGenerating)
                  const Center(child: CupertinoActivityIndicator())
                else
                  Column(
                    children: [
                      if (_hasUnsetPools)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            '⚠️ Nhập đủ số tiền các Nhóm Dịch Vụ trước khi tạo hóa đơn.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFFF9500),
                            ),
                          ),
                        ),
                      GlassButton(
                        text: _hasUnsetPools
                            ? '⚠️ Tạo Hóa Đơn (Pool chưa đủ)'
                            : 'Tạo Hóa Đơn Nháp',
                        icon: CupertinoIcons.doc_text_fill,
                        color: _hasUnsetPools
                            ? const Color(0xFFFF9500)
                            : AppTheme.kBrand,
                        onPressed: _selectedBranchId == null
                            ? null
                            : _generateBills,
                      ),
                    ],
                  ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showBranchPicker(List<dynamic> branches) {
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (_) => Container(
          height: 250,
          color: CupertinoColors.white,
          child: Column(
            children: [
              SizedBox(
                height: 190,
                child: CupertinoPicker(
                  itemExtent: 40,
                  scrollController: FixedExtentScrollController(
                    initialItem: branches.indexWhere(
                      (b) => b.id == _selectedBranchId,
                    ),
                  ),
                  onSelectedItemChanged: (idx) =>
                      setState(() => _selectedBranchId = branches[idx].id),
                  children: branches
                      .map((b) => Center(child: Text(b.branchName)))
                      .toList(),
                ),
              ),
              CupertinoButton(
                child: const Text('Xong'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMonthYearPicker() {
    int tempMonth = _selectedMonth;
    int tempYear = _selectedYear;
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (_) => Container(
          height: 250,
          color: CupertinoColors.white,
          child: Column(
            children: [
              SizedBox(
                height: 190,
                child: Row(
                  children: [
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 40,
                        scrollController: FixedExtentScrollController(
                          initialItem: tempMonth - 1,
                        ),
                        onSelectedItemChanged: (idx) => tempMonth = idx + 1,
                        children: List.generate(
                          12,
                          (i) => Center(child: Text('Tháng ${i + 1}')),
                        ),
                      ),
                    ),
                    Expanded(
                      child: CupertinoPicker(
                        itemExtent: 40,
                        scrollController: FixedExtentScrollController(
                          initialItem: tempYear - 2024,
                        ),
                        onSelectedItemChanged: (idx) => tempYear = idx + 2024,
                        children: List.generate(
                          10,
                          (i) => Center(child: Text('${i + 2024}')),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoButton(
                child: const Text('Xong'),
                onPressed: () {
                  setState(() {
                    _selectedMonth = tempMonth;
                    _selectedYear = tempYear;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
