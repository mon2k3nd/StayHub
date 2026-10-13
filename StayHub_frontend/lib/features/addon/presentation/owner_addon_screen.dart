import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/components/liquid_glass_scaffold.dart';
import '../../../core/components/glass_container.dart';
import '../../../core/theme/liquid_glass_colors.dart';
import '../application/owner_addon_notifier.dart';
import '../../../core/components/app_error_widget.dart';
import 'dart:async' show unawaited;

class OwnerAddonScreen extends ConsumerStatefulWidget {
  const OwnerAddonScreen({super.key});

  @override
  ConsumerState<OwnerAddonScreen> createState() => _OwnerAddonScreenState();
}

class _OwnerAddonScreenState extends ConsumerState<OwnerAddonScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlassScaffold(
      title: 'Dịch vụ & Tiện ích',
      backgroundColors: AppTheme.kBackgroundLight,
      trailing: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: _showCreateModal,
        child: const Icon(
          CupertinoIcons.add_circled_solid,
          color: LiquidGlassColors.ownerAccent,
        ),
      ),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: () async {
              ref.invalidate(ownerAddonsProvider);
              await ref.read(ownerAddonsProvider.future);
            },
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHeader(),
                const SizedBox(height: 32),
                _buildAddonsList(),
                const SizedBox(height: 48),
                _buildAffiliateServices(),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAffiliateServices() {
    final affiliates = [
      {
        'name': 'JupViec.vn',
        'desc': 'Dọn dẹp nhà cửa theo giờ',
        'icon': CupertinoIcons.sparkles,
        'color': CupertinoColors.systemGreen,
      },
      {
        'name': 'bTaskee',
        'desc': 'Giúp việc nhà & Tổng vệ sinh',
        'icon': CupertinoIcons.house_fill,
        'color': CupertinoColors.systemOrange,
      },
      {
        'name': 'Thợ Tốt',
        'desc': 'Sửa chữa điện nước, máy lạnh',
        'icon': CupertinoIcons.wrench_fill,
        'color': CupertinoColors.systemBlue,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dịch vụ Liên kết',
          style: TextStyle(
            color: CupertinoColors.black,
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Gợi ý các dịch vụ tiện ích từ đối tác cho khách thuê của bạn.',
          style: TextStyle(
            color: CupertinoColors.black.withValues(alpha: 0.6),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: affiliates.map((a) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (a['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        a['icon'] as IconData,
                        color: a['color'] as Color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            // BUGFIX (data): tránh `as String` ném TypeError
                            // khi name/desc null.
                            (a['name'] ?? '').toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (a['desc'] ?? '').toString(),
                            style: const TextStyle(
                              color: CupertinoColors.systemGrey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text(
                        'Kích hoạt',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      onPressed: () {
                        // Kích hoạt dịch vụ liên kết (Mock)
                      },
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Danh mục dịch vụ',
          style: TextStyle(
            color: CupertinoColors.black,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tạo các dịch vụ (bán nước, dọn dẹp) để cung cấp cho khách thuê.',
          style: TextStyle(
            color: CupertinoColors.black.withValues(alpha: 0.6),
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAddonsList() {
    final addonsAsync = ref.watch(ownerAddonsProvider);

    return addonsAsync.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (e, _) => AppErrorWidget(error: e),
      data: (addons) {
        if (addons.isEmpty) {
          return const Center(
            child: Text(
              'Bạn chưa tạo dịch vụ nào.',
              style: TextStyle(color: CupertinoColors.systemGrey),
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: addons.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 16),
          itemBuilder: (ctx, i) {
            final addon = addons[i];
            return GlassContainer(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: LiquidGlassColors.ownerAccent.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      CupertinoIcons.cube_box_fill,
                      color: LiquidGlassColors.ownerAccent,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          addon.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatAmount(addon.price)}đ',
                          style: const TextStyle(
                            color: Color(0xFF298FFF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(
                      CupertinoIcons.trash_circle_fill,
                      color: CupertinoColors.systemRed,
                    ),
                    onPressed: () {
                      _showDeleteConfirm(addon.id, addon.name);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
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

  void _showCreateModal() {
    _nameController.clear();
    _priceController.clear();

    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Thêm Dịch Vụ Mới'),
          content: Column(
            children: [
              const SizedBox(height: 16),
              CupertinoTextField(
                controller: _nameController,
                placeholder: 'Tên dịch vụ (VD: Bình nước 20L)',
                padding: const EdgeInsets.all(12),
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: _priceController,
                placeholder: 'Giá tiền (VD: 15000)',
                keyboardType: TextInputType.number,
                padding: const EdgeInsets.all(12),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                final name = _nameController.text.trim();
                final price =
                    double.tryParse(_priceController.text.trim()) ?? 0;
                if (name.isNotEmpty && price > 0) {
                  unawaited(
                    ref
                        .read(ownerAddonProvider.notifier)
                        .createAddon(context, name, price),
                  );
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(int id, String name) {
    unawaited(
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text(
            'Bạn có chắc chắn muốn ngừng cung cấp dịch vụ "$name" không? Các đơn hàng cũ vẫn được giữ nguyên.',
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(ctx);
                unawaited(
                  ref
                      .read(ownerAddonProvider.notifier)
                      .deleteAddon(context, id),
                );
              },
              child: const Text('Xóa'),
            ),
          ],
        ),
      ),
    );
  }
}
