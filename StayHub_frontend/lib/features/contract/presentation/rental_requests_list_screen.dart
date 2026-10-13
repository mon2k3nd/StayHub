import 'dart:async' show unawaited;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors, Divider;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/liquid_background.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../../core/components/global_loading.dart';
import '../../auth/application/auth_notifier.dart';
import '../../dashboard/application/rental_request_notifier.dart';

class RentalRequestsListScreen extends ConsumerStatefulWidget {
  const RentalRequestsListScreen({super.key});

  @override
  ConsumerState<RentalRequestsListScreen> createState() =>
      _RentalRequestsListScreenState();
}

class _RentalRequestsListScreenState
    extends ConsumerState<RentalRequestsListScreen> {
  final _dateFmt = DateFormat('dd/MM/yyyy');

  Future<void> _handleAction(int id, bool approve, String name) async {
    if (!approve) {
      unawaited(
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Từ Chối Yêu Cầu?'),
            content: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('Xác nhận từ chối yêu cầu thuê của $name?'),
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Hủy'),
                onPressed: () => Navigator.pop(ctx),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: const Text(
                  'Từ chối',
                  style: TextStyle(color: CupertinoColors.systemRed),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  unawaited(_executeAction(id, false, name, null));
                },
              ),
            ],
          ),
        ),
      );
      return;
    }

    final user = ref.read(authProvider).value;
    if (user != null && (user.signature == null || user.signature!.isEmpty)) {
      unawaited(
        showCupertinoDialog(
          context: context,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Thiếu Chữ Ký'),
            content: const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                'Bạn cần thiết lập chữ ký điện tử trước khi phê duyệt yêu cầu thuê. Vui lòng vào Cài Đặt -> Thiết lập Chữ ký điện tử.',
              ),
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Đóng'),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // Modal chọn thời hạn và điều khoản
    int selectedYears = 0;
    int selectedMonths = 6;
    final termsCtrl = TextEditingController();

    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 480,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: const Text(
                            'Hủy',
                            style: TextStyle(color: CupertinoColors.systemRed),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                        const Text(
                          'Duyệt Yêu Cầu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.black,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: const Text(
                            'Duyệt',
                            style: TextStyle(
                              color: AppTheme.kAccentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            int totalMonths =
                                (selectedYears * 12) + selectedMonths;
                            unawaited(
                              _executeAction(
                                id,
                                true,
                                name,
                                totalMonths,
                                termsCtrl.text.trim(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Thời hạn thuê:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.black,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 120,
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 40,
                            scrollController: FixedExtentScrollController(
                              initialItem: selectedYears,
                            ),
                            onSelectedItemChanged: (idx) =>
                                setModalState(() => selectedYears = idx),
                            children: List.generate(
                              6,
                              (i) => Center(
                                child: Text(
                                  '$i Năm',
                                  style: const TextStyle(
                                    color: CupertinoColors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            itemExtent: 40,
                            scrollController: FixedExtentScrollController(
                              initialItem: selectedMonths - 1,
                            ),
                            onSelectedItemChanged: (idx) =>
                                setModalState(() => selectedMonths = idx + 1),
                            children: List.generate(
                              11,
                              (i) => Center(
                                child: Text(
                                  '${i + 1} Tháng',
                                  style: const TextStyle(
                                    color: CupertinoColors.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Điều khoản bổ sung:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.black,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CupertinoTextField(
                      controller: termsCtrl,
                      placeholder: 'Nhập điều khoản bổ sung (nếu có)...',
                      maxLines: 4,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey6,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _executeAction(
    int id,
    bool approve,
    String name,
    int? durationMonths, [
    String? terms,
  ]) async {
    GlobalLoading.show(context);
    try {
      final notifier = ref.read(pendingRequestsProvider.notifier);
      final success = await notifier.respondToRequest(
        id,
        approve,
        durationMonths: durationMonths,
        terms: terms,
      );

      GlobalLoading.hide();
      if (success) {
        _showSuccessDialog(
          approve
              ? 'Đã duyệt yêu cầu của $name. Hệ thống sẽ tự động tạo hợp đồng nháp.'
              : 'Đã từ chối yêu cầu thuê của $name.',
        );
      } else {
        _showSuccessDialog('Lỗi hệ thống: Không thể xử lý yêu cầu lúc này.');
      }
    } catch (e) {
      GlobalLoading.hide();
      _showSuccessDialog('Lỗi hệ thống: Không thể xử lý yêu cầu lúc này.');
    }
  }

  void _showSuccessDialog(String message) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Thành Công'),
          content: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(message),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Đồng ý'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(pendingRequestsProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black.withValues(alpha: 0.5),
        middle: const Text(
          'Yêu Cầu Thuê Phòng',
          style: TextStyle(color: CupertinoColors.black),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: CupertinoColors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: LiquidBackground(
        colors: AppTheme.kBackgroundLight,
        child: Container(
          child: requests.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.mail_solid,
                        color: Colors.white24,
                        size: 80,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Không có yêu cầu thuê nào.',
                        style: TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  itemCount: requests.length,
                  itemBuilder: (ctx, idx) {
                    final r = requests[idx];
                    // BUGFIX (data): trước đây ép `r['id'] as int` — nếu id
                    // là String/null thì ném TypeError và cả danh sách yêu
                    // cầu thuê không render. Coerce an toàn.
                    final rawId = r['id'];
                    final id = rawId is num
                        ? rawId.toInt()
                        : int.tryParse(rawId?.toString() ?? '') ?? 0;
                    final name = r['tenantName'] as String? ?? 'Khách thuê';
                    final phone = r['phone'] as String? ?? 'Chưa cập nhật';
                    final room =
                        r['roomName'] as String? ?? 'Phòng ${r['roomId']}';
                    final branch = r['branchName'] as String? ?? '';
                    final dateStr = r['moveInDate'] as String? ?? '';
                    final note = r['note'] as String? ?? 'Không có ghi chú';
                    final date = dateStr.isNotEmpty
                        ? (DateTime.tryParse(dateStr) ?? DateTime.now())
                        : DateTime.now();

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    color: CupertinoColors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  phone,
                                  style: const TextStyle(
                                    color: AppTheme.kAccentColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$room • $branch',
                              style: const TextStyle(
                                color: Color(0xFF4B5563),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _infoRow(
                              CupertinoIcons.calendar,
                              'Ngày dọn vào dự kiến: ${_dateFmt.format(date)}',
                            ),
                            const SizedBox(height: 8),
                            _infoRow(
                              CupertinoIcons.chat_bubble_fill,
                              'Lời nhắn: "$note"',
                            ),
                            const SizedBox(height: 14),
                            const Divider(
                              color: CupertinoColors.separator,
                              height: 1,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  color: CupertinoColors.systemRed.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  onPressed: () =>
                                      _handleAction(id, false, name),
                                  child: const Text(
                                    'Từ chối',
                                    style: TextStyle(
                                      color: CupertinoColors.systemRed,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                CupertinoButton(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  color: AppTheme.kAccentColor.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  onPressed: () =>
                                      _handleAction(id, true, name),
                                  child: const Text(
                                    'Phê duyệt',
                                    style: TextStyle(
                                      color: AppTheme.kAccentColor,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
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
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.white38, size: 15),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
