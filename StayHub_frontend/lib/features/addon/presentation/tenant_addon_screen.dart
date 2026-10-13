import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../application/tenant_addon_notifier.dart';
import '../../../core/components/app_error_widget.dart';
import 'dart:async' show unawaited;

class TenantAddonScreen extends ConsumerStatefulWidget {
  final int roomId;
  const TenantAddonScreen({super.key, required this.roomId});

  @override
  ConsumerState<TenantAddonScreen> createState() => _TenantAddonScreenState();
}

class _TenantAddonScreenState extends ConsumerState<TenantAddonScreen> {
  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      title: 'Tiện Ích & Dịch Vụ',
      backgroundColors: AppTheme.kBackgroundLight,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              ref.invalidate(availableAddonsProvider(widget.roomId));
              ref.invalidate(myAddonRequestsProvider);
              await ref.read(availableAddonsProvider(widget.roomId).future);
            },
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHeader(),
                const SizedBox(height: 32),
                _buildAvailableAddons(),
                const SizedBox(height: 32),
                _buildOrderHistory(),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dịch vụ cộng thêm',
          style: TextStyle(
            color: CupertinoColors.black,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Đặt nước, dọn dẹp, giặt ủi và chi phí sẽ được tính vào hóa đơn cuối tháng.',
          style: TextStyle(
            color: CupertinoColors.black.withValues(alpha: 0.6),
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableAddons() {
    final addonsAsync = ref.watch(availableAddonsProvider(widget.roomId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CÓ SẴN',
          style: TextStyle(
            color: Color(0xFF4B5563),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        addonsAsync.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e, _) => AppErrorWidget(error: e),
          data: (addons) {
            if (addons.isEmpty) {
              return const Center(
                child: Text(
                  'Chủ nhà chưa cung cấp dịch vụ nào.',
                  style: TextStyle(color: CupertinoColors.systemGrey),
                ),
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: addons.length,
              itemBuilder: (ctx, i) {
                final addon = addons[i];
                return GestureDetector(
                  onTap: () => _showOrderModal(addon),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: LiquidGlassColors.tenantAccent.withValues(
                              alpha: 0.1,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.cube_box_fill,
                            color: LiquidGlassColors.tenantAccent,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          addon.name,
                          style: const TextStyle(
                            color: CupertinoColors.black,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatAmount(addon.price)}đ',
                          style: const TextStyle(
                            color: Color(0xFF1A6FD4),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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
      ],
    );
  }

  Widget _buildOrderHistory() {
    final historyAsync = ref.watch(myAddonRequestsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ĐÃ ĐẶT',
          style: TextStyle(
            color: Color(0xFF4B5563),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        historyAsync.when(
          loading: () => const Center(child: CupertinoActivityIndicator()),
          error: (e, _) => AppErrorWidget(error: e),
          data: (requests) {
            if (requests.isEmpty) {
              return const Center(
                child: Text(
                  'Bạn chưa đặt dịch vụ nào.',
                  style: TextStyle(color: CupertinoColors.systemGrey),
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final req = requests[i];
                return GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey5,
                          borderRadius: BorderRadius.circular(16),
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
                              '${req.addonService.name} (x${req.quantity})',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatAmount(req.addonService.price * req.quantity)}đ',
                              style: const TextStyle(
                                color: Color(0xFF1A6FD4),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(req.status),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'APPROVED':
        color = CupertinoColors.systemGreen;
        label = 'Đã duyệt';
        break;
      case 'REJECTED':
        color = CupertinoColors.systemRed;
        label = 'Từ chối';
        break;
      default:
        color = CupertinoColors.systemOrange;
        label = 'Chờ duyệt';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  void _showOrderModal(dynamic addon) {
    int quantity = 1;
    unawaited(
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) => CupertinoActionSheet(
            title: const Text(
              'Đặt dịch vụ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.black,
              ),
            ),
            message: Column(
              children: [
                const SizedBox(height: 12),
                Text(
                  addon.name,
                  style: const TextStyle(
                    fontSize: 20,
                    color: LiquidGlassColors.tenantAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_formatAmount(addon.price)}đ / đơn vị',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(
                        CupertinoIcons.minus_circle_fill,
                        size: 32,
                        color: CupertinoColors.systemGrey,
                      ),
                      onPressed: () {
                        if (quantity > 1) setState(() => quantity--);
                      },
                    ),
                    const SizedBox(width: 24),
                    Text(
                      '$quantity',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.black,
                      ),
                    ),
                    const SizedBox(width: 24),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Icon(
                        CupertinoIcons.plus_circle_fill,
                        size: 32,
                        color: LiquidGlassColors.tenantAccent,
                      ),
                      onPressed: () {
                        if (quantity < 10) setState(() => quantity++);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Tổng: ${_formatAmount(addon.price * quantity)}đ',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemRed,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
            actions: [
              CupertinoActionSheetAction(
                isDefaultAction: true,
                onPressed: () {
                  Navigator.pop(ctx);
                  unawaited(
                    ref
                        .read(tenantAddonProvider.notifier)
                        .orderAddon(context, widget.roomId, addon.id, quantity),
                  );
                },
                child: const Text(
                  'Xác nhận đặt hàng',
                  style: TextStyle(color: LiquidGlassColors.tenantAccent),
                ),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
          ),
        ),
      ),
    );
  }
}
