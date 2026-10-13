import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/premium_empty_state_widget.dart';
import '../../../core/components/bounce_click.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../../auth/application/auth_notifier.dart';
import '../application/contract_notifier.dart';
import '../data/models/contract_model.dart';
import 'dart:async' show unawaited;

final _currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
final _dateFmt = DateFormat('dd/MM/yyyy');

class ContractScreen extends ConsumerStatefulWidget {
  const ContractScreen({super.key});

  @override
  ConsumerState<ContractScreen> createState() => _ContractScreenState();
}

class _ContractScreenState extends ConsumerState<ContractScreen> {
  String _filter = 'ALL';

  static const _filters = [
    ('ALL', 'Tất cả'),
    ('ACTIVE', 'Hiệu lực'),
    ('PENDING', 'Chờ Kích Hoạt'),
    ('EXPIRED', 'Hết hạn'),
    ('TERMINATED', 'Đã hủy'),
  ];

  static const _statusLabel = {
    'ACTIVE': 'Đang hiệu lực',
    'PENDING': 'Chờ ký kết',
    'EXPIRED': 'Đã hết hạn',
    'TERMINATED': 'Đã hủy bỏ',
    'LIQUIDATED': 'Đã thanh lý',
  };

  static const _statusColor = {
    'ACTIVE': Color(0xFF2ECC71),
    'PENDING': Color(0xFF3498DB),
    'EXPIRED': Color(0xFFE74C3C),
    'TERMINATED': Color(0xFF95A5A6),
    'LIQUIDATED': Color(0xFFE67E22),
  };

  void _showContractDetail(ContractModel c, bool isOwner) {
    unawaited(context.push('/contract-preview', extra: {'contractId': c.id}));
  }

  double _contractProgress(ContractModel c) {
    final total = c.endDate.difference(c.startDate).inDays;
    if (total <= 0) return 1.0;
    final elapsed = DateTime.now().difference(c.startDate).inDays;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  void _showRenewDialog(ContractModel c) {
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: const Text(
            'Gia hạn hợp đồng',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          message: Text('Hợp đồng #${c.id} – Chọn thời gian gia hạn'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                unawaited(_doRenew(c.id, 3));
              },
              child: const Text('Gia hạn thêm 3 tháng'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                unawaited(_doRenew(c.id, 6));
              },
              child: const Text('Gia hạn thêm 6 tháng'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                unawaited(_doRenew(c.id, 12));
              },
              child: const Text('Gia hạn thêm 12 tháng'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
        ),
      ),
    );
  }

  Future<void> _doRenew(int contractId, int months) async {
    final success = await ref
        .read(contractProvider.notifier)
        .renewContract(contractId, months);
    if (!mounted) return;
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(success ? '✅ Gia hạn thành công' : '❌ Thất bại'),
          content: Text(
            success
                ? 'Đã gia hạn thêm $months tháng.'
                : 'Có lỗi xảy ra. Vui lòng thử lại.',
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
  }

  void _showTerminateDialog(ContractModel c) {
    final reasonCtrl = TextEditingController();
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Chấm dứt hợp đồng'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: CupertinoTextField(
              controller: reasonCtrl,
              placeholder: 'Nhập lý do chấm dứt...',
              maxLines: 3,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: false,
              child: const Text('Hủy'),
              onPressed: () => Navigator.pop(ctx),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Xác nhận chấm dứt'),
              onPressed: () async {
                final reason = reasonCtrl.text.trim();
                if (reason.isEmpty) return;
                Navigator.pop(ctx);
                final success = await ref
                    .read(contractProvider.notifier)
                    .terminateContract(c.id, reason);
                if (!mounted) return;
                unawaited(
                  showCupertinoDialog(
                    context: context,
                    builder: (ctx2) => CupertinoAlertDialog(
                      title: Text(success ? '✅ Thành công' : '❌ Thất bại'),
                      content: Text(
                        success ? 'Hợp đồng đã bị chấm dứt.' : 'Có lỗi xảy ra.',
                      ),
                      actions: [
                        CupertinoDialogAction(
                          child: const Text('Đóng'),
                          onPressed: () => Navigator.pop(ctx2),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewBanner(List<ContractModel> contracts) {
    final activeCount = contracts.where((c) => c.status == 'ACTIVE').length;
    final expiringSoonCount = contracts
        .where((c) => c.status == 'ACTIVE' && c.daysRemaining <= 30)
        .length;
    final pendingCount = contracts.where((c) => c.status == 'PENDING').length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A6FD4), Color(0xFF298FFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A6FD4).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatChip(
            'Hiệu lực',
            '$activeCount',
            CupertinoColors.white,
            CupertinoIcons.checkmark_seal_fill,
          ),
          Container(
            width: 1,
            height: 40,
            color: CupertinoColors.white.withValues(alpha: 0.3),
          ),
          _buildStatChip(
            'Sắp hết hạn',
            '$expiringSoonCount',
            const Color(0xFFFFD700),
            CupertinoIcons.clock_fill,
          ),
          Container(
            width: 1,
            height: 40,
            color: CupertinoColors.white.withValues(alpha: 0.3),
          ),
          _buildStatChip(
            'Chờ ký',
            '$pendingCount',
            const Color(0xFF9CCBFF),
            CupertinoIcons.pencil_circle_fill,
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: CupertinoColors.white.withValues(alpha: 0.8),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contractProvider);
    final authUser = ref.watch(authProvider).value;
    final isOwner = authUser?.role == 'OWNER';

    return LiquidGlassScaffold(
      title: 'Hợp Đồng Thuê',
      backgroundColors: isOwner
          ? AppTheme.kBackgroundLight
          : AppTheme.kBackgroundLight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview banner (chỉ hiển thị khi đã có data)
            state.when(
              data: (contracts) => contracts.isNotEmpty
                  ? Column(
                      children: [
                        _buildOverviewBanner(contracts),
                        const SizedBox(height: 20),
                      ],
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            // Thanh lọc trạng thái
            _buildFilterBar(),
            const SizedBox(height: 20),

            state.when(
              data: (contracts) {
                final filtered = contracts
                    .where((c) => _filter == 'ALL' || c.status == _filter)
                    .toList();

                if (filtered.isEmpty) {
                  return const PremiumEmptyStateWidget(
                    title: 'Chưa có hợp đồng',
                    message:
                        'Không tìm thấy hợp đồng nào theo trạng thái được chọn.',
                    icon: CupertinoIcons.doc_text_fill,
                  );
                }

                return AnimationLimiter(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, idx) {
                      final c = filtered[idx];
                      final progress = _contractProgress(c);
                      final statusColor =
                          _statusColor[c.status] ?? const Color(0xFF4B5563);
                      final isPending = c.status == 'PENDING';

                      return AnimationConfiguration.staggeredList(
                        position: idx,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 40,
                          child: FadeInAnimation(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: BounceClick(
                                onPressed: () =>
                                    _showContractDetail(c, isOwner),
                                child: GlassContainer(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Hợp đồng #${c.id}',
                                            style: const TextStyle(
                                              color: CupertinoColors.black,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: statusColor.withValues(
                                                  alpha: 0.5,
                                                ),
                                                width: 1.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: statusColor.withValues(
                                                    alpha: 0.3,
                                                  ),
                                                  blurRadius: 8,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              isPending
                                                  ? 'Chờ Kích Hoạt'
                                                  : (_statusLabel[c.status] ??
                                                        c.status),
                                              style: TextStyle(
                                                color: statusColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      _infoRow(
                                        CupertinoIcons.calendar_today,
                                        '${_dateFmt.format(c.startDate)} ➢ ${_dateFmt.format(c.endDate)}',
                                        const Color(0xFF4B5563),
                                      ),
                                      const SizedBox(height: 6),
                                      _infoRow(
                                        CupertinoIcons.money_dollar_circle_fill,
                                        'Giá thuê: ${_currencyFmt.format(c.monthlyRent)} / tháng',
                                        const Color(0xFF2ECC71),
                                      ),
                                      if (c.depositAmount != null) ...[
                                        const SizedBox(height: 6),
                                        _infoRow(
                                          CupertinoIcons.shield_fill,
                                          'Tiền cọ: ${_currencyFmt.format(c.depositAmount)}',
                                          const Color(0xFFE67E22),
                                        ),
                                      ],
                                      if (c.isActive) ...[
                                        const SizedBox(height: 16),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Tiến độ hợp đồng',
                                                  style: TextStyle(
                                                    color: CupertinoColors
                                                        .systemGrey
                                                        .withValues(alpha: 0.8),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                Text(
                                                  '${(progress * 100).toInt()}%',
                                                  style: TextStyle(
                                                    color: statusColor,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Container(
                                              height: 6,
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color:
                                                    CupertinoColors.systemGrey5,
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                                boxShadow: const [
                                                  BoxShadow(
                                                    color:
                                                        CupertinoColors.black,
                                                    blurRadius: 2,
                                                    offset: Offset(0, 1),
                                                    blurStyle: BlurStyle.inner,
                                                  ),
                                                ],
                                              ),
                                              child: FractionallySizedBox(
                                                alignment: Alignment.centerLeft,
                                                widthFactor: progress,
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: statusColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          3,
                                                        ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: statusColor
                                                            .withValues(
                                                              alpha: 0.5,
                                                            ),
                                                        blurRadius: 6,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Còn ${c.daysRemaining} ngày hiệu lực',
                                              style: TextStyle(
                                                color: statusColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      // Cảnh báo sắp hết hạn
                                      if (c.isActive &&
                                          c.daysRemaining <= 30 &&
                                          c.daysRemaining > 0) ...[
                                        const SizedBox(height: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: CupertinoColors.systemOrange
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: CupertinoColors
                                                  .systemOrange
                                                  .withValues(alpha: 0.4),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                CupertinoIcons
                                                    .exclamationmark_circle_fill,
                                                color: CupertinoColors
                                                    .systemOrange,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '⚠️ Còn ${c.daysRemaining} ngày – Hãy gia hạn sớm',
                                                style: const TextStyle(
                                                  color: CupertinoColors
                                                      .systemOrange,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      // Nút hành động cho Owner
                                      if (c.isActive && isOwner) ...[
                                        const SizedBox(height: 14),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: CupertinoButton(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                    ),
                                                color: CupertinoColors
                                                    .systemBlue
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                onPressed: () =>
                                                    _showRenewDialog(c),
                                                child: const Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      CupertinoIcons
                                                          .refresh_circled_solid,
                                                      color: CupertinoColors
                                                          .systemBlue,
                                                      size: 16,
                                                    ),
                                                    SizedBox(width: 6),
                                                    Text(
                                                      'Gia hạn',
                                                      style: TextStyle(
                                                        color: CupertinoColors
                                                            .systemBlue,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: CupertinoButton(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 10,
                                                    ),
                                                color: CupertinoColors.systemRed
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                onPressed: () =>
                                                    _showTerminateDialog(c),
                                                child: const Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      CupertinoIcons
                                                          .xmark_circle_fill,
                                                      color: CupertinoColors
                                                          .systemRed,
                                                      size: 16,
                                                    ),
                                                    SizedBox(width: 6),
                                                    Text(
                                                      'Chấm dứt',
                                                      style: TextStyle(
                                                        color: CupertinoColors
                                                            .systemRed,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (isPending && isOwner) ...[
                                        const SizedBox(height: 14),
                                        SizedBox(
                                          width: double.infinity,
                                          child: CupertinoButton(
                                            padding: EdgeInsets.zero,
                                            onPressed: () {
                                              unawaited(
                                                context.push(
                                                  '/offline-contract-verify',
                                                  extra: {
                                                    'contractId': c.id,
                                                    'roomId': c.roomId,
                                                  },
                                                ),
                                              );
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: CupertinoColors
                                                    .systemOrange
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: CupertinoColors
                                                      .systemOrange
                                                      .withValues(alpha: 0.4),
                                                ),
                                              ),
                                              child: const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    CupertinoIcons.bolt_fill,
                                                    color: CupertinoColors
                                                        .systemOrange,
                                                    size: 16,
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Kích Hoạt Hợp Đồng',
                                                    style: TextStyle(
                                                      color: CupertinoColors
                                                          .systemOrange,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: CupertinoActivityIndicator(
                    radius: 16,
                    color: CupertinoColors.black,
                  ),
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 100),
                  child: Text(
                    'Lỗi: $err',
                    style: const TextStyle(color: CupertinoColors.systemRed),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color.withValues(alpha: 0.8), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: _filters.map((f) {
          final isSelected = _filter == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => setState(() => _filter = f.$1),
              child: GlassContainer(
                borderRadius: 20,
                color: isSelected
                    ? AppTheme.kAccentColor.withValues(alpha: 0.3)
                    : CupertinoColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                hasBorder: true,
                child: Text(
                  f.$2,
                  style: TextStyle(
                    color: isSelected
                        ? AppTheme.kAccentColor
                        : CupertinoColors.black.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ContractImagesViewerScreen extends StatefulWidget {
  final List<String> images;
  final int contractId;
  const ContractImagesViewerScreen({
    super.key,
    required this.images,
    required this.contractId,
  });

  @override
  State<ContractImagesViewerScreen> createState() =>
      _ContractImagesViewerScreenState();
}

class _ContractImagesViewerScreenState
    extends State<ContractImagesViewerScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black.withValues(alpha: 0.8),
        middle: Text(
          'Hợp đồng #${widget.contractId} - Trang ${_currentPage + 1}/${widget.images.length}',
          style: const TextStyle(color: CupertinoColors.white),
        ),
        previousPageTitle: 'Đóng',
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.images.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (ctx, index) {
                  return InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(
                      widget.images[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CupertinoActivityIndicator(
                            color: CupertinoColors.white,
                          ),
                        );
                      },
                      errorBuilder: (ctx, err, stack) => const Center(
                        child: Icon(
                          CupertinoIcons.exclamationmark_triangle,
                          color: CupertinoColors.white,
                          size: 48,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            if (widget.images.length > 1)
              SmoothPageIndicator(
                controller: _pageController,
                count: widget.images.length,
                effect: const ScrollingDotsEffect(
                  activeDotColor: Color(0xFF298FFF),
                  dotColor: CupertinoColors.systemGrey,
                  dotHeight: 8,
                  dotWidth: 8,
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class InspectionLogViewerScreen extends StatelessWidget {
  final Map<String, dynamic> logData;
  final int contractId;
  const InspectionLogViewerScreen({
    super.key,
    required this.logData,
    required this.contractId,
  });

  @override
  Widget build(BuildContext context) {
    // Parse data
    List<String> inspectionImgs = [];
    if (logData['inspectionImages'] != null) {
      try {
        inspectionImgs = List<String>.from(
          jsonDecode(logData['inspectionImages']),
        );
      } catch (_) {}
    }

    List<Map<String, dynamic>> furnitureImgs = [];
    if (logData['furnitureImages'] != null) {
      try {
        furnitureImgs = List<Map<String, dynamic>>.from(
          jsonDecode(logData['furnitureImages']),
        );
      } catch (_) {}
    }

    final elecF = logData['electricityMeterImage'];
    final waterF = logData['waterMeterImage'];

    // Parse date
    String dateStr = 'N/A';
    if (logData['createdAt'] != null) {
      try {
        final d = DateTime.parse(logData['createdAt']);
        dateStr = DateFormat('HH:mm dd/MM/yyyy').format(d);
      } catch (_) {}
    }

    return LiquidGlassScaffold(
      title: 'BB Nghiệm thu #$contractId',
      backgroundColors: AppTheme.kBackgroundLight,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20).copyWith(bottom: 120),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.checkmark_seal_fill,
                    color: Color(0xFF2ECC71),
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Biên bản đã chốt',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Thời gian: $dateStr',
                          style: const TextStyle(
                            color: Color(0xFF4B5563),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (elecF != null || waterF != null) ...[
              const Text(
                '1. Đồng hồ điện / nước',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (elecF != null)
                    Expanded(
                      child: _buildImageCard(
                        elecF,
                        'Đồng hồ Điện',
                        CupertinoIcons.bolt_fill,
                        context,
                      ),
                    ),
                  if (elecF != null && waterF != null)
                    const SizedBox(width: 12),
                  if (waterF != null)
                    Expanded(
                      child: _buildImageCard(
                        waterF,
                        'Đồng hồ Nước',
                        CupertinoIcons.drop_fill,
                        context,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            if (inspectionImgs.isNotEmpty) ...[
              const Text(
                '2. Hiện trạng Phòng trọ',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: inspectionImgs.length,
                itemBuilder: (ctx, i) {
                  return GestureDetector(
                    onTap: () => _viewImageFull(context, inspectionImgs[i]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        inspectionImgs[i],
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            if (furnitureImgs.isNotEmpty) ...[
              const Text(
                '3. Nội thất bàn giao',
                style: TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: furnitureImgs.length,
                itemBuilder: (ctx, i) {
                  final url = furnitureImgs[i]['url'] ?? '';
                  final note = furnitureImgs[i]['note'] ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassContainer(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => _viewImageFull(context, url),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                url,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ghi chú tình trạng:',
                                  style: TextStyle(
                                    color: Color(0xFF4B5563),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  note.toString().isEmpty
                                      ? 'Không có ghi chú'
                                      : note.toString(),
                                  style: const TextStyle(
                                    color: CupertinoColors.black,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(
    String url,
    String label,
    IconData icon,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () => _viewImageFull(context, url),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                url,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: const Color(0xFF4B5563), size: 14),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  void _viewImageFull(BuildContext context, String url) {
    unawaited(
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (context) =>
              ContractImagesViewerScreen(images: [url], contractId: contractId),
        ),
      ),
    );
  }
}
