import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../contract/application/contract_notifier.dart';
import '../application/checkout_provider.dart';
import '../data/models/checkout_request_model.dart';
import 'owner_checkout_detail_screen.dart';
import 'dart:async' show unawaited;

class OwnerCheckoutListScreen extends ConsumerStatefulWidget {
  const OwnerCheckoutListScreen({super.key});

  @override
  ConsumerState<OwnerCheckoutListScreen> createState() =>
      _OwnerCheckoutListScreenState();
}

class _OwnerCheckoutListScreenState
    extends ConsumerState<OwnerCheckoutListScreen> {
  int _selectedSegment = 0;

  static const _statusLabel = {
    'PENDING': 'Chờ xét duyệt',
    'PAYMENT_PENDING': 'Chờ quyết toán',
    'DISPUTED': 'Đang tranh chấp',
    'COMPLETED': 'Đã hoàn tất',
    'REJECTED': 'Đã từ chối',
  };

  static const _statusColor = {
    'PENDING': CupertinoColors.systemOrange,
    'PAYMENT_PENDING': CupertinoColors.systemBlue,
    'DISPUTED': CupertinoColors.systemRed,
    'COMPLETED': CupertinoColors.systemGreen,
    'REJECTED': CupertinoColors.systemGrey,
  };

  @override
  Widget build(BuildContext context) {
    final asyncRequests = ref.watch(ownerCheckoutRequestsProvider);

    return LiquidGlassScaffold(
      title: 'Quản lý Trả Phòng',
      backgroundColors: AppTheme.kBackgroundLight,
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        child: const Icon(
          CupertinoIcons.refresh_circled_solid,
          color: LiquidGlassColors.tenantAccent,
          size: 28,
        ),
        onPressed: () => ref.invalidate(ownerCheckoutRequestsProvider),
      ),
      child: asyncRequests.when(
        data: (requests) {
          if (requests.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 100),
                child: Column(
                  children: [
                    Icon(
                      CupertinoIcons.arrow_right_circle_fill,
                      color: Colors.white24,
                      size: 80,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Chưa có yêu cầu trả phòng nào.',
                      style: TextStyle(
                        color: Color(0xFF4B5563),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final pending = requests.where((r) => r.status == 'PENDING').toList();
          final paymentPending = requests
              .where(
                (r) => r.status == 'PAYMENT_PENDING' || r.status == 'DISPUTED',
              )
              .toList();
          final completed = requests
              .where((r) => r.status == 'COMPLETED' || r.status == 'REJECTED')
              .toList();

          final tabs = [pending, paymentPending, completed];
          final currentList = tabs[_selectedSegment];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // Segment Control
                SizedBox(
                  width: double.infinity,
                  child: CupertinoSegmentedControl<int>(
                    groupValue: _selectedSegment,
                    selectedColor: AppTheme.kAccentColor,
                    unselectedColor: CupertinoColors.white,
                    borderColor: CupertinoColors.white,
                    children: {
                      0: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'Mới (${pending.length})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      1: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'Quyết toán (${paymentPending.length})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      2: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'Xong (${completed.length})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    },
                    onValueChanged: (val) =>
                        setState(() => _selectedSegment = val),
                  ),
                ),
                const SizedBox(height: 20),

                if (currentList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 80),
                    child: Column(
                      children: [
                        Icon(
                          _selectedSegment == 0
                              ? CupertinoIcons.tray
                              : CupertinoIcons.checkmark_seal_fill,
                          color: Colors.white24,
                          size: 60,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedSegment == 0
                              ? 'Không có yêu cầu mới.'
                              : 'Không có mục nào.',
                          style: const TextStyle(
                            color: Color(0xFF4B5563),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: currentList.length,
                    itemBuilder: (ctx, index) {
                      final req = currentList[index];
                      return _buildRequestCard(req);
                    },
                  ),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.only(top: 150),
            child: CupertinoActivityIndicator(
              radius: 16,
              color: CupertinoColors.black,
            ),
          ),
        ),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 150),
            child: Text(
              'Lỗi: $e',
              style: const TextStyle(color: CupertinoColors.systemRed),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(CheckoutRequestModel req) {
    final statusColor = _statusColor[req.status] ?? CupertinoColors.systemGrey;
    final statusText = _statusLabel[req.status] ?? req.status;
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => _openDetail(req),
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Phòng ${req.roomId} • HĐ #${req.contractId}',
                    style: const TextStyle(
                      color: CupertinoColors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.4),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    CupertinoIcons.calendar,
                    size: 14,
                    color: Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Ngày dọn dự kiến: ${dateFmt.format(req.targetCheckoutDate)}',
                    style: const TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (req.tenantNote.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      CupertinoIcons.chat_bubble,
                      size: 14,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        req.tenantNote,
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    req.status == 'PENDING'
                        ? 'Nhấn để xét duyệt →'
                        : 'Nhấn để xem chi tiết →',
                    style: const TextStyle(
                      color: AppTheme.kAccentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDetail(CheckoutRequestModel req) async {
    // Tìm contract từ danh sách đã load
    try {
      final contracts = await ref.read(contractProvider.future);
      final contract = contracts
          .where((c) => c.id == req.contractId)
          .firstOrNull;

      if (!mounted) return;

      if (contract == null) {
        // Nếu không tìm thấy contract, unawaited(vẫn mở nhưng hiện thông báo)
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Không tìm thấy Hợp đồng'),
              content: const Text(
                'Không thể tải chi tiết hợp đồng. Vui lòng thử lại sau.',
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

      unawaited(
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) =>
                OwnerCheckoutDetailScreen(request: req, contract: contract),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        unawaited(
          showCupertinoDialog(
            context: context,
            builder: (ctx) => CupertinoAlertDialog(
              title: const Text('Lỗi'),
              content: Text('Không thể tải dữ liệu: $e'),
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
    }
  }
}
